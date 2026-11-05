module ArcLanding
export flight, shoot, screen, play

"""Exact flat-ground projectile range, time and height; SI units, no air resistance."""
function flight(speed::Real, angle::Real)
    isfinite(speed) && isfinite(angle) && 1 <= speed <= 30 && 1 <= angle <= 89 ||
        throw(ArgumentError("speed 1..30 m/s; angle 1..89 degrees"))
    vx, vy = speed * cosd(angle), speed * sind(angle)
    time = 2vy / 9.81
    (range=vx * time, time=time, height=vy^2 / (2 * 9.81))
end

struct Game
    attempts::Int
    won::Bool
    last::String
end
Game() = Game(0, false, "Choose speed and angle to land on the target.")

function shoot(game::Game, speed::Real, angle::Real)
    (game.won || game.attempts >= 3) && return game
    f = flight(speed, angle)
    hit = abs(f.range - 30) <= 2
    message = "Landed " * string(round(f.range; digits=2)) * " m | " *
        (hit ? "ON TARGET" : f.range < 28 ? "SHORT - add speed" : "LONG - reduce speed")
    Game(game.attempts + 1, hit, message)
end

function screen(game::Game)
    status = game.won ? "WON" : game.attempts >= 3 ? "LOST" : "AIM"
    "ARC LANDING | $status\n" *
    "Land within 30 +/- 2 metres in 3 throws | throws $(game.attempts)/3\n\n" *
    "launch ----------- [ target: 28 .. 32 m ]\n\n" * game.last *
    "\n\nEnter speed(m/s) angle(deg), e.g. 17 45 | q: quit"
end

function play(input::IO=stdin, output::IO=stdout)
    game = Game()
    while true
        println(output, "\e[2J\e[H", screen(game))
        (game.won || game.attempts >= 3 || eof(input)) && break
        print(output, "> ")
        line = strip(readline(input))
        line == "q" && break
        values = tryparse.(Float64, split(line))
        if length(values) == 2 && all(x -> x !== nothing, values)
            try
                game = shoot(game, values...)
                continue
            catch error
                error isa ArgumentError || rethrow()
            end
        end
        println(output, "Invalid input: speed 1..30, angle 1..89. No throw consumed.")
    end
    game
end
end
