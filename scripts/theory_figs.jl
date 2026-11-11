# Regenerates every plotted figure of docs/theory and the table of measured values
# (docs/theory/figures/values.md). Run with `make theory-figs`. Each figure is produced by the
# functions of src/ArcLanding.jl themselves; nothing here changes them. No packages are needed.
using ArcLanding
using Printf

const DIR = length(ARGS) > 0 ? ARGS[1] : "docs/theory/figures"
const G = 9.81
const ROWS = String[]

"One row of the measured-values table: id | what | measured | theory | error (relative; absolute when theory is 0)."
function value(id, what, measured, theory)
    err = theory != 0 ? abs(measured / theory - 1) : abs(measured - theory)
    push!(ROWS, @sprintf("| `%s` | %s | %.8g | %.8g | %.2e |", id, what, measured, theory, err))
end

"A self-contained line chart: series = [(name, colour, xs, ys, dots)]."
function plot(name, title, xlabel, ylabel, series)
    W, H, ML, MR, MT, MB = 720, 400, 70, 20, 44, 56
    xs = reduce(vcat, [s[3] for s in series]); ys = reduce(vcat, [s[4] for s in series])
    x0, x1, y0, y1 = minimum(xs), maximum(xs), minimum(ys), maximum(ys)
    x1 <= x0 && (x1 = x0 + 1); y1 <= y0 && (y0 -= 0.5; y1 += 0.5)
    pad = 0.05 * (y1 - y0); y0 -= pad; y1 += pad
    pw, ph = W - ML - MR, H - MT - MB
    px(x) = ML + (x - x0) / (x1 - x0) * pw
    py(y) = MT + ph - (y - y0) / (y1 - y0) * ph
    io = IOBuffer()
    @printf(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 %d %d\" width=\"%d\" height=\"%d\" font-family=\"sans-serif\" font-size=\"12\">\n", W, H, W, H)
    @printf(io, "<rect width=\"%d\" height=\"%d\" fill=\"#ffffff\"/>\n<text x=\"%d\" y=\"26\" font-size=\"16\" font-weight=\"bold\" fill=\"#222\">%s</text>\n", W, H, ML, title)
    for k in 0:5
        f = k / 5
        @printf(io, "<line x1=\"%.1f\" y1=\"%d\" x2=\"%.1f\" y2=\"%d\" stroke=\"#e3e3e3\"/>\n", ML + f * pw, MT, ML + f * pw, MT + ph)
        @printf(io, "<line x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\" stroke=\"#e3e3e3\"/>\n", ML, MT + ph - f * ph, ML + pw, MT + ph - f * ph)
        @printf(io, "<text x=\"%.1f\" y=\"%d\" text-anchor=\"middle\" fill=\"#444\">%.3g</text>\n", ML + f * pw, MT + ph + 18, x0 + f * (x1 - x0))
        @printf(io, "<text x=\"%d\" y=\"%.1f\" text-anchor=\"end\" fill=\"#444\">%.3g</text>\n", ML - 8, MT + ph - f * ph + 4, y0 + f * (y1 - y0))
    end
    @printf(io, "<rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" fill=\"none\" stroke=\"#888\"/>\n", ML, MT, pw, ph)
    @printf(io, "<text x=\"%.0f\" y=\"%d\" text-anchor=\"middle\" fill=\"#222\">%s</text>\n", ML + pw / 2, H - 12, xlabel)
    @printf(io, "<text transform=\"translate(16 %.0f) rotate(-90)\" text-anchor=\"middle\" fill=\"#222\">%s</text>\n", MT + ph / 2, ylabel)
    for (i, (label, colour, sx, sy, dots)) in enumerate(series)
        if dots
            for (x, y) in zip(sx, sy)
                @printf(io, "<circle cx=\"%.1f\" cy=\"%.1f\" r=\"3\" fill=\"%s\"/>\n", px(x), py(y), colour)
            end
        else
            print(io, "<polyline fill=\"none\" stroke=\"", colour, "\" stroke-width=\"2\" points=\"")
            for (x, y) in zip(sx, sy)
                @printf(io, "%.1f,%.1f ", px(x), py(y))
            end
            print(io, "\"/>\n")
        end
        @printf(io, "<rect x=\"%d\" y=\"%d\" width=\"12\" height=\"12\" fill=\"%s\"/><text x=\"%d\" y=\"%d\" fill=\"#222\">%s</text>\n",
                ML + 8 + (i - 1) * 160, MT + 8, colour, ML + 26 + (i - 1) * 160, MT + 19, label)
    end
    print(io, "</svg>\n")
    write(joinpath(DIR, name), take!(io))
end

# S01: range, time of flight and apex against the launch angle.
let speed = 17.0, angles = 1:89
    r = [flight(speed, a).range for a in angles]
    h = [flight(speed, a).height for a in angles]
    t = [flight(speed, a).time * 10 for a in angles]
    plot("flight.svg", "Flat ground, no wind: launch at 17 m/s", "launch angle [deg]", "metres, seconds x 10",
         [("range [m]", "#1f77b4", collect(angles), r, false), ("apex [m]", "#d62728", collect(angles), h, false), ("time x 10 [s]", "#2ca02c", collect(angles), t, false)])
    value("range-10-45", "range at 10 m/s and 45 degrees [m] (theory v^2 / g)", flight(10, 45).range, 100 / G)
    value("apex-10-45", "apex of the same throw [m] (theory v^2 sin^2 / 2g = 25 / g)", flight(10, 45).height, 25 / G)
    value("time-10-45", "its time of flight [s] (theory 2 v sin / g)", flight(10, 45).time, 2 * 10 * sind(45) / G)
    value("complementary", "range at 20 m/s and 30 degrees over range at 60 degrees (theory 1)", flight(20, 30).range / flight(20, 60).range, 1.0)
    value("best-angle", "angle of the largest range at 17 m/s among 1..89 degrees (theory 45)", angles[argmax(r)], 45.0)
end

# S02: a constant horizontal acceleration shifts the landing point by a T^2 / 2.
let speed = 17.0, angles = 1:89
    series = []
    for (w, colour) in ((-2.0, "#d62728"), (0.0, "#888888"), (1.2, "#1f77b4"), (2.0, "#2ca02c"))
        push!(series, ("wind $(w) m/s^2", colour, collect(angles), [trajectory(speed, a; wind=w, dt=0.001).range for a in angles], false))
    end
    plot("wind.svg", "Range against angle at 17 m/s for four winds", "launch angle [deg]", "range [m]", series)
    exact = flight(17, 45)
    for w in (-2.0, 1.2, 2.0)
        value("wind-shift-$(w)", "range at 17 m/s, 45 degrees with wind $(w), minus the no-wind range, dt = 0.001 [m] (theory wind x T^2 / 2)",
              trajectory(17, 45; wind=w, dt=0.001).range - trajectory(17, 45; wind=0, dt=0.001).range, w * exact.time^2 / 2)
    end
    best = argmax([trajectory(speed, a; wind=1.2, dt=0.001).range for a in angles])
    value("best-angle-wind", "angle of the largest range at 17 m/s with the game's wind +1.2 (above 45: staying up longer pays; theory 45 + atan(wind / g) / 2)", angles[best], 45 + atand(1.2 / G) / 2)
    value("time-unchanged", "time of flight with wind 2 over the time without (theory 1: the wind is horizontal)", trajectory(17, 45; wind=2, dt=0.001).time / trajectory(17, 45; wind=0, dt=0.001).time, 1.0)
end

# S03: every stored point lies on the exact parabola.
let speed = 16.5, angle = 45, wind = 1.2, dt = 0.2
    f = trajectory(speed, angle; wind=wind, dt=dt)
    vx, vy = speed * cosd(angle), speed * sind(angle)
    worst = 0.0
    for (k, (x, y)) in enumerate(f.points[1:end-1])
        t = (k - 1) * dt
        worst = max(worst, abs(x - (vx * t + wind * t^2 / 2)), abs(y - (vy * t - G * t^2 / 2)))
    end
    ts = range(0, 2vy / G; length=200)
    plot("points.svg", "Stored points (dt = 0.2 s) on the exact path", "x [m]", "y [m]",
         [("exact path", "#d62728", [vx * t + wind * t^2 / 2 for t in ts], [vy * t - G * t^2 / 2 for t in ts], false),
          ("stored points", "#1f77b4", first.(f.points), last.(f.points), true)])
    value("points-on-path", "largest distance component between a stored point before landing and the exact position at its time, dt = 0.2 [m] (theory 0: the update is exact for constant acceleration)", worst, 0.0)
    value("points-count", "points stored for that throw, the landing point included", length(f.points), 0.0)
    value("apex-sampled", "apex reported with dt = 0.2 over the exact apex (the largest stored height: at or below the true apex)", f.height / flight(speed, angle).height, 1.0)
end

# S04: the landing point is interpolated linearly; the error falls with the square of the step.
let speed = 17.0, angle = 45, wind = 1.2
    exact = flight(speed, angle)
    target = exact.range + wind * exact.time^2 / 2
    dts = [0.2, 0.1, 0.05, 0.025, 0.0125, 0.00625]
    # the error depends on where in a step the ground is crossed, so take the worst over nearby speeds
    worst(dt) = maximum(abs(trajectory(s, angle; wind=wind, dt=dt).range - (flight(s, angle).range + wind * flight(s, angle).time^2 / 2)) for s in 16.0:0.01:18.0)
    errs = [worst(dt) for dt in dts]
    terr = [maximum(abs(trajectory(s, angle; wind=wind, dt=dt).time - flight(s, angle).time) for s in 16.0:0.01:18.0) for dt in dts]
    plot("landing-error.svg", "Worst landing error over speeds 16..18 m/s against the step (log-log)", "log10 dt", "log10 of the error",
         [("range error [m]", "#1f77b4", log10.(dts), log10.(errs), false), ("time error [s]", "#2ca02c", log10.(dts), log10.(terr), false),
          ("slope 2", "#d62728", log10.(dts), [log10(errs[1]) + 2 * (log10(d) - log10(dts[1])) for d in dts], false)])
    value("landing-order", "slope of log(worst range error) against log(dt) between dt = 0.1 and 0.0125 (theory 2)", log(errs[2] / errs[5]) / log(8), 2.0)
    value("landing-error-game", "worst range error at the game's dt = 0.02 over speeds 16..18 m/s [m] (it stays under the bound of the next row)", worst(0.02), 0.0)
    vxl = 18 * cosd(45) + wind * flight(18, 45).time
    value("landing-bound-game", "the bound g dt^2 / 8 x (landing vx / landing vy) at 18 m/s, 45 degrees, dt = 0.02 [m]: the chord of a parabola lies at most g dt^2 / 8 below it", G * 0.02^2 / 8 * vxl / (18 * sind(45)), 0.0)
    value("landing-demo", "range of the demonstration throw 16.5 m/s at 45 degrees, as the game computes it [m] (theory v^2 / g + wind T^2 / 2)", trajectory(16.5, 45).range, flight(16.5, 45).range + 1.2 * flight(16.5, 45).time^2 / 2)
    value("landing-early", "sign of (numerical time - exact time) for that throw: the chord meets the ground before the parabola does (theory -1)", sign(trajectory(16.5, 45).time - flight(16.5, 45).time), -1.0)
end

# S05: the step is shortened so that at least one point is in the air.
let
    f = trajectory(1, 1; wind=0, dt=0.2)
    value("shallow-points", "points stored for the shallowest, slowest throw (1 m/s at 1 degree) asked with dt = 0.2 (theory 3: start, one in the air, landing)", length(f.points), 3.0)
    value("shallow-range", "its range over the exact range (theory 1: one step to the apex, one interpolated)", f.range / flight(1, 1).range, 1.0)
    value("shallow-apex", "its reported apex over the exact apex (theory 1: the shortened step lands on the apex)", f.height / flight(1, 1).height, 1.0)
    g = trajectory(30, 89)
    value("steep-ground", "height of the last stored point of the steepest, fastest throw (theory 0)", last(g.points)[2], 0.0)
    value("steep-above", "lowest stored height of that throw (theory 0: never below ground)", minimum(last, g.points), 0.0)
end

# S06: which throws at 45 degrees hit the target.
let speeds = 10:0.05:20
    r = [trajectory(s, 45).range for s in speeds]
    plot("target.svg", "Landing point of a 45 degree throw, and the target", "speed [m/s]", "range [m]",
         [("range", "#1f77b4", collect(speeds), r, false), ("28 m", "#d62728", collect(speeds), fill(28.0, length(speeds)), false), ("32 m", "#d62728", collect(speeds), fill(32.0, length(speeds)), false)])
    hits = [s for (s, x) in zip(speeds, r) if ArcLanding.hit(x)]
    value("hit-speed-low", "slowest speed on a 0.05 grid that hits at 45 degrees [m/s]", minimum(hits), 0.0)
    value("hit-speed-high", "fastest such speed [m/s]", maximum(hits), 0.0)
    value("hit-28", "hit(28) (theory 1: the ends of the target count)", ArcLanding.hit(28), 1.0)
    value("hit-32", "hit(32) (theory 1)", ArcLanding.hit(32), 1.0)
    value("hit-just-outside", "hit just below 28 plus hit just above 32 (theory 0)", ArcLanding.hit(prevfloat(28.0)) + ArcLanding.hit(nextfloat(32.0)), 0.0)
    g = shoot(ArcLanding.Game(), 16.5, 45)
    value("game-won", "won after the demonstration throw (theory 1)", g.won, 1.0)
    value("game-frozen", "attempts after a further throw at a won game (theory 1: nothing more is counted)", shoot(g, 10, 45).attempts, 1.0)
    lost = foldl((g, _) -> shoot(g, 1, 1), 1:5; init=ArcLanding.Game())
    value("game-three", "attempts after five misses (theory 3: the game stops at three)", lost.attempts, 3.0)
end

# S07: input validation.
let
    rejected(f) = try f(); 0 catch e; e isa ArgumentError ? 1 : rethrow() end
    bad = [() -> flight(NaN, 45), () -> flight(Inf, 45), () -> flight(0, 45), () -> flight(31, 45), () -> flight(10, 0), () -> flight(10, 90),
           () -> trajectory(10, 45; wind=4), () -> trajectory(10, 45; wind=NaN), () -> trajectory(10, 45; dt=0), () -> trajectory(10, 45; dt=0.3)]
    value("input-rejected", "of ten out-of-range calls, how many raise ArgumentError (theory 10)", sum(rejected.(bad)), 10.0)
    good = [() -> flight(1, 1), () -> flight(30, 89), () -> trajectory(30, 89; wind=-3, dt=0.2), () -> trajectory(1, 1; wind=3, dt=0.001)]
    value("input-accepted", "of four calls on the edges of the allowed ranges, how many are rejected (theory 0)", sum(rejected.(good)), 0.0)
    value("input-no-throw", "throws consumed by three invalid lines followed by one valid throw (theory 1)", play(IOBuffer("31 45\n0 45\nNaN 45\n16.5 45\n"), IOBuffer()).attempts, 1.0)
    value("input-eof", "throws consumed when the input ends at once (theory 0)", play(IOBuffer(""), IOBuffer()).attempts, 0.0)
end

# S08: the character plot.
let
    g = shoot(ArcLanding.Game(), 16.5, 45)
    text = screen(g)
    lines = split(text, "\n")
    rows = [l for l in lines if startswith(l, "|")]
    value("screen-rows", "rows of the character plot (theory 7)", length(rows), 7.0)
    value("screen-width", "characters per row after the axis bar (theory 51)", length(rows[1]) - 1, 51.0)
    value("screen-target", "T characters on the bottom row: the target 28..32 m at 40 m per 50 columns (theory 6 columns)", count(==('T'), rows[end]), 6.0)
    value("screen-stars", "columns holding at least one star: the flight is drawn from measured points", count(c -> any(r -> r[c] == '*', rows), 2:52), 0.0)
end

# S09: the five placements, their reachability, and the clean restart.
let placed = levels()
    function aim(level; angle=45)
        low, high = 1.0, 30.0
        for _ in 1:60
            middle = (low + high) / 2
            trajectory(middle, angle; wind=level.wind).range < level.centre ? (low = middle) : (high = middle)
        end
        (low + high) / 2
    end
    speeds = [aim(l) for l in placed]
    tx = Float64[]; ty = Float64[]
    for (n, l) in enumerate(placed), x in (l.centre - l.half):0.25:(l.centre + l.half)
        push!(tx, x); push!(ty, n)
    end
    landed = [trajectory(round(s; digits=1), 45; wind=l.wind).range for (s, l) in zip(speeds, placed)]
    calm = [trajectory(round(s; digits=1), 45; wind=0).range for s in speeds]
    plot("levels.svg", "The five targets, and a 45 degree throw that hits each", "range [m]", "level",
         [("target", "#d62728", tx, ty, true), ("landing", "#1f77b4", landed, collect(1.0:5.0), true), ("same throw, no wind", "#999999", calm, collect(1.0:5.0), true)])
    value("level-count", "placements (theory 5)", length(placed), 5.0)
    value("level-first", "centre of level 1 [m] (theory 30: the M2 game)", placed[1].centre, 30.0)
    value("level-same-seed", "levels() called twice gives equal placements (theory 1)", placed == levels(), 1.0)
    value("level-other-seed", "placements 2..5 that differ under seed 1 (reported)", count(k -> levels(1)[k] != placed[k], 2:5), 0.0)
    value("level-reachable", "levels hit by a 45 degree throw at a speed rounded to 0.1 m/s (theory 5)", count(k -> ArcLanding.hit(placed[k], landed[k]), 1:5), 5.0)
    value("level-speed-low", "smallest of those five speeds [m/s] (allowed: 1..30)", minimum(speeds), 0.0)
    value("level-speed-high", "largest of those five speeds [m/s] (allowed: 1..30)", maximum(speeds), 0.0)
    value("level-wind-low", "most leftward wind of the five [m/s^2] (allowed: -3..3)", minimum(l.wind for l in placed), 0.0)
    value("level-wind-high", "most rightward wind of the five [m/s^2]", maximum(l.wind for l in placed), 0.0)
    g = shoot(ArcLanding.Game(), 16.5, 45)
    value("reason-wind", "wind share reported for the demonstration throw [m]: range with wind minus range without", trajectory(16.5, 45).range - trajectory(16.5, 45; wind=0).range, 0.0)
    value("reason-shown", "the message of that throw names the wind share (theory 1)", occursin("Wind moved the landing +3.39 m", g.last), 1.0)
    played = shoot(shoot(ArcLanding.Game(3), 5, 45), 6, 30)
    again, fresh = restart(played), ArcLanding.Game(3)
    value("restart-clean", "after two throws, restart equals a fresh game on the same level: attempts, message, points (theory 1)", (again.level, again.attempts, again.won, again.last, again.points) == (fresh.level, fresh.attempts, fresh.won, fresh.last, fresh.points), 1.0)
    value("restart-attempts", "attempts after restart (theory 0)", again.attempts, 0.0)
    value("next-level", "level after next_level from level 3 (theory 4)", next_level(played).level, 4.0)
    value("next-wraps", "level after next_level from level 5 (theory 1)", next_level(ArcLanding.Game(5)).level, 1.0)
    value("finished-ignores", "throws counted when a throw is entered after a win, in the real loop (theory 1)", play(IOBuffer("16.5 45\n10 45\n"), IOBuffer()).attempts, 1.0)
end

open(joinpath(DIR, "values.md"), "w") do io
    println(io, "# Measured values\n\nWritten by `make theory-figs` (scripts/theory_figs.jl) from the functions of src/ArcLanding.jl. Do not edit by hand.")
    println(io, "SI units; gravity 9.81 m/s^2. The last column is the relative error; where the theory column is 0 it is the absolute value.\n")
    println(io, "| id | what is measured | measured | theory | error |\n|---|---|---|---|---|")
    foreach(r -> println(io, r), ROWS)
end
