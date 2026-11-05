module ArcLanding
export flight, trajectory, shoot, screen, play

function parameters(speed, angle)
    isfinite(speed) && isfinite(angle) && 1 <= speed <= 30 && 1 <= angle <= 89 ||
        throw(ArgumentError("speed 1..30 m/s; angle 1..89 degrees"))
end

"""Exact flat-ground reference; SI units, no air resistance."""
function flight(speed::Real, angle::Real)
    parameters(speed, angle)
    vx, vy = speed * cosd(angle), speed * sind(angle)
    time = 2vy / 9.81
    (range=vx * time, time=time, height=vy^2 / (2 * 9.81))
end

"""Fixed-step velocity Verlet. Wind is constant horizontal acceleration (m/s²).
The final ground crossing is linearly interpolated; error converges quadratically.
"""
function trajectory(speed::Real, angle::Real; wind::Real=1.2, dt::Real=0.02)
    parameters(speed, angle)
    isfinite(wind) && abs(wind) <= 3 && isfinite(dt) && 0.001 <= dt <= 0.2 ||
        throw(ArgumentError("wind -3..3 m/s²; dt 0.001..0.2 s"))
    x, y, t = 0.0, 0.0, 0.0
    vx, vy = speed * cosd(angle), speed * sind(angle)
    dt = min(dt, vy / 9.81)  # at least one airborne sample, even at shallow launches
    points = [(x, y)]
    while true
        nx, ny = x + vx*dt + wind*dt^2/2, y + vy*dt - 9.81*dt^2/2
        if ny <= 0
            fraction = y / (y - ny)
            x, t = x + fraction*(nx-x), t + fraction*dt
            push!(points, (x, 0.0))
            return (range=x, time=t, height=maximum(last, points), points=points)
        end
        x, y, t = nx, ny, t + dt
        vx, vy = vx + wind*dt, vy - 9.81*dt
        push!(points, (x, y))
    end
end

struct Game
    attempts::Int
    won::Bool
    last::String
    points::Vector{Tuple{Float64,Float64}}
end
Game() = Game(0, false, "Choose speed and angle to land on the target.", Tuple{Float64,Float64}[])
hit(range) = 28 <= range <= 32

function shoot(game::Game, speed::Real, angle::Real)
    (game.won || game.attempts >= 3) && return game
    f = trajectory(speed, angle)
    message = "Landed " * string(round(f.range; digits=2)) * " m | " *
        (hit(f.range) ? "ON TARGET" : f.range < 28 ? "SHORT - add speed" : "LONG - reduce speed")
    Game(game.attempts + 1, hit(f.range), message, f.points)
end

function plot(points)
    width, height = 51, 7
    xmax = max(40.0, isempty(points) ? 0.0 : maximum(first, points))
    xmin = min(0.0, isempty(points) ? 0.0 : minimum(first, points))
    ymax = max(5.0, isempty(points) ? 0.0 : maximum(last, points))
    grid = fill(' ', height, width)
    col(x) = clamp(1 + round(Int, (x-xmin)/(xmax-xmin)*(width-1)), 1, width)
    for (x, y) in points
        row = clamp(height - round(Int, y/ymax*(height-1)), 1, height)
        grid[row, col(x)] = '*'
    end
    for x in 28:0.5:32
        grid[height, col(x)] = 'T'
    end
    "height [m] (* = flight, T = target)\n" *
        join(["|" * String(grid[row, :]) for row in 1:height], "\n") *
        "\n+ range [m]: $(round(xmin; digits=1)) .. $(round(xmax; digits=1)) | peak scale $(round(ymax; digits=1)) m"
end

function screen(game::Game)
    status = game.won ? "WON" : game.attempts >= 3 ? "LOST" : "AIM"
    "ARC LANDING | $status\n" *
    "Land within 30 +/- 2 metres in 3 throws | throws $(game.attempts)/3\n" *
    "Wind: +1.2 m/s^2 to RIGHT | step: 0.02 s | gravity: 9.81 m/s^2\n" *
    plot(game.points) * "\n" * game.last *
    "\nEnter speed(m/s) angle(deg), e.g. 16.5 45 | q: quit"
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
