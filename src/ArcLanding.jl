module ArcLanding
export flight, trajectory, shoot, screen, play, levels, restart, next_level

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

"""One target placement: centre and half-width in metres, wind in m/s² (positive to the right)."""
struct Level
    centre::Float64
    half::Float64
    wind::Float64
end

"""splitmix64: the same sequence on every machine and Julia version, with no package."""
function mix(state::UInt64)
    z = state + 0x9e3779b97f4a7c15
    z = (z ⊻ (z >> 30)) * 0xbf58476d1ce4e5b9
    z = (z ⊻ (z >> 27)) * 0x94d049bb133111eb
    z ⊻ (z >> 31)
end

"""Five placements. The first is the M2 game (30 ± 2 m, wind +1.2); the other four follow
from the seed: centre 12..48 m, half-width 1, 1.5 or 2 m, wind -2.0..2.0 m/s² in tenths."""
function levels(seed::Integer=11)
    state = UInt64(seed)
    made = [Level(30, 2, 1.2)]
    for _ in 2:5
        state = mix(state); centre = 12 + state % 37
        state = mix(state); half = 1 + (state % 3) / 2
        state = mix(state); wind = (Int(state % 41) - 20) / 10
        push!(made, Level(centre, half, wind))
    end
    made
end
const LEVELS = levels()

struct Game
    level::Int
    attempts::Int
    won::Bool
    last::String
    points::Vector{Tuple{Float64,Float64}}
end
"""A fresh game on one level: no throw made, nothing carried over."""
function Game(level::Integer=1)
    1 <= level <= length(LEVELS) || throw(ArgumentError("level 1..$(length(LEVELS))"))
    Game(level, 0, false, "Choose speed and angle to land on the target.", Tuple{Float64,Float64}[])
end
hit(range) = 28 <= range <= 32
hit(level::Level, range) = level.centre - level.half <= range <= level.centre + level.half
finished(game::Game) = game.won || game.attempts >= 3
"""The same level again, as if never played."""
restart(game::Game) = Game(game.level)
"""The following level, fresh; after the last comes the first."""
next_level(game::Game) = Game(mod1(game.level + 1, length(LEVELS)))

metres(x) = string(round(x; digits=2))
signed(x) = (x < 0 ? "-" : "+") * metres(abs(x))
short(x) = isinteger(x) ? string(Int(x)) : string(x)

"""Why the throw ended where it did: the distance to the target, and the part the wind added."""
function reason(level::Level, range, calm)
    low, high = level.centre - level.half, level.centre + level.half
    verdict = hit(level, range) ? "ON TARGET, " * metres(abs(range - level.centre)) * " m from the centre" :
        range < low ? "SHORT by " * metres(low - range) * " m - add speed" :
        "LONG by " * metres(range - high) * " m - reduce speed"
    "Landed " * metres(range) * " m | " * verdict * "\nWind moved the landing " * signed(range - calm) *
        " m (without wind: " * metres(calm) * " m)"
end

function shoot(game::Game, speed::Real, angle::Real)
    finished(game) && return game
    level = LEVELS[game.level]
    f = trajectory(speed, angle; wind=level.wind)
    calm = trajectory(speed, angle; wind=0).range
    Game(game.level, game.attempts + 1, hit(level, f.range), reason(level, f.range, calm), f.points)
end

function plot(points, level::Level=LEVELS[1])
    width, height = 51, 7
    low, high = level.centre - level.half, level.centre + level.half
    xmax = max(40.0, high + 4, isempty(points) ? 0.0 : maximum(first, points))
    xmin = min(0.0, isempty(points) ? 0.0 : minimum(first, points))
    ymax = max(5.0, isempty(points) ? 0.0 : maximum(last, points))
    grid = fill(' ', height, width)
    col(x) = clamp(1 + round(Int, (x-xmin)/(xmax-xmin)*(width-1)), 1, width)
    for (x, y) in points
        row = clamp(height - round(Int, y/ymax*(height-1)), 1, height)
        grid[row, col(x)] = '*'
    end
    for x in low:0.5:high
        grid[height, col(x)] = 'T'
    end
    "height [m] (* = flight, T = target)\n" *
        join(["|" * String(grid[row, :]) for row in 1:height], "\n") *
        "\n+ range [m]: $(round(xmin; digits=1)) .. $(round(xmax; digits=1)) | peak scale $(round(ymax; digits=1)) m"
end

function screen(game::Game)
    status = game.won ? "WON" : game.attempts >= 3 ? "LOST" : "AIM"
    level = LEVELS[game.level]
    wind = level.wind == 0 ? "none" :
        (level.wind < 0 ? "-" : "+") * short(abs(level.wind)) * " m/s^2 to " * (level.wind < 0 ? "LEFT" : "RIGHT")
    "ARC LANDING | $status | level $(game.level)/$(length(LEVELS))\n" *
    "Land within $(short(level.centre)) +/- $(short(level.half)) metres in 3 throws | throws $(game.attempts)/3\n" *
    "Wind: $wind | step: 0.02 s | gravity: 9.81 m/s^2\n" *
    plot(game.points, level) * "\n" * game.last * "\n" *
    (finished(game) ? "" : "Enter speed(m/s) angle(deg), e.g. 16.5 45 | ") *
    "r: retry | n: next level | q: quit"
end

function play(input::IO=stdin, output::IO=stdout)
    game = Game()
    while true
        println(output, "\e[2J\e[H", screen(game))
        eof(input) && break
        print(output, "> ")
        line = strip(readline(input))
        line == "q" && break
        line == "r" && (game = restart(game); continue)
        line == "n" && (game = next_level(game); continue)
        finished(game) && continue
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
