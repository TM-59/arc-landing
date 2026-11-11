using Test, ArcLanding
@testset "REQ-flight analytic range" begin
    @test flight(10, 45).range ≈ 100 / 9.81
    @test flight(20, 30).range ≈ flight(20, 60).range
    @test flight(10, 45).height ≈ 25 / 9.81
end
@testset "REQ-input finite bounded parameters" begin
    for bad in (NaN, Inf, -1, 0, 31)
        @test_throws ArgumentError flight(bad, 45)
    end
    @test_throws ArgumentError flight(10, 90)
end
@testset "REQ-finish win, miss, freeze and input recovery" begin
    g = shoot(ArcLanding.Game(), 16.5, 45)
    @test g.won
    @test shoot(g, 1, 1) === g
    lost = foldl((g, _) -> shoot(g, 1, 1), 1:3; init=ArcLanding.Game())
    @test occursin("LOST", screen(lost))
    @test play(IOBuffer("NaN 45\nwrong\n16.5 45\n"), IOBuffer()).attempts == 1
    @test play(IOBuffer(""), IOBuffer()).attempts == 0
end

@testset "REQ-wind numeric integration and convergence" begin
    for speed in (1, 5, 10, 17, 30), angle in (15, 45, 80)
        exact = flight(speed, angle)
        f = trajectory(speed, angle; wind=0)
        @test abs(f.range-exact.range) < 0.04
        @test abs(f.time-exact.time) < 0.002
        @test abs(f.height-exact.height) < 0.001
    end
    for wind in (-2.0, 0.0, 2.0)
        exact = flight(17, 45)
        expected = exact.range + wind*exact.time^2/2
        errors = [abs(trajectory(17, 45; wind, dt).range-expected) for dt in (0.2, 0.1, 0.05)]
        @test errors[3] < errors[2] < errors[1]
        @test errors[3] < 0.01
    end
    @test trajectory(17, 45; wind=-2).range < trajectory(17, 45; wind=0).range < trajectory(17, 45; wind=2).range
end
@testset "REQ-input trajectory bounds and target boundaries" begin
    for kwargs in ((wind=NaN,), (wind=Inf,), (wind=4,), (dt=0,), (dt=Inf,), (dt=0.3,))
        @test_throws ArgumentError trajectory(10, 45; kwargs...)
    end
    @test ArcLanding.hit(28)
    @test ArcLanding.hit(32)
    @test !ArcLanding.hit(prevfloat(28.0))
    @test !ArcLanding.hit(nextfloat(32.0))
    @test !ArcLanding.hit(NaN)
    f = trajectory(30, 89)
    @test last(f.points)[2] == 0
    @test all(p -> p[2] >= 0, f.points)
    g = shoot(ArcLanding.Game(), 16.5, 45)
    @test occursin("Wind: +1.2", screen(g))
    @test occursin("*", screen(g))
    @test occursin("T", screen(g))
    @test play(IOBuffer("31 45\n0 45\nNaN 45\n16.5 45\n"), IOBuffer()).attempts == 1
end

"Bisection on the speed of a 45 degree throw until it lands on the centre; nothing beyond the game's own trajectory."
function aim(level; angle=45)
    low, high = 1.0, 30.0
    for _ in 1:60
        middle = (low + high) / 2
        trajectory(middle, angle; wind=level.wind).range < level.centre ? (low = middle) : (high = middle)
    end
    (low + high) / 2
end
@testset "REQ-level fixed-seed placements, all reachable inside the input range" begin
    placed = levels()
    @test length(placed) == 5
    @test placed == levels() == ArcLanding.LEVELS  # the same seed gives the same placements
    @test levels(1) != placed && levels(1)[1] == placed[1]  # the seed moves levels 2..5 only
    @test (placed[1].centre, placed[1].half, placed[1].wind) == (30.0, 2.0, 1.2)
    @test_throws ArgumentError ArcLanding.Game(0)
    @test_throws ArgumentError ArcLanding.Game(6)
    for seed in (11, 1, 2, 3, 99), (number, level) in enumerate(levels(seed))
        @test 12 <= level.centre <= 48 && level.half in (1.0, 1.5, 2.0) && abs(level.wind) <= 2
        @test level.centre - level.half > 0
        speed = aim(level)
        @test 1.5 < speed < 29.5  # strictly inside the accepted speeds, with room to spare
        @test abs(trajectory(speed, 45; wind=level.wind).range - level.centre) < 0.01
        @test ArcLanding.hit(level, level.centre - level.half) && ArcLanding.hit(level, level.centre + level.half)
        @test !ArcLanding.hit(level, prevfloat(level.centre - level.half)) && !ArcLanding.hit(level, NaN)
        # more than one way in: a second angle also reaches it, and a rounded entry still hits
        @test abs(trajectory(aim(level; angle=30), 30; wind=level.wind).range - level.centre) < 0.01
        @test ArcLanding.hit(level, trajectory(round(speed; digits=1), 45; wind=level.wind).range)
        if seed == 11
            won = shoot(ArcLanding.Game(number), round(speed; digits=1), 45)
            @test won.won && won.level == number && occursin("ON TARGET", won.last)
        end
    end
end
@testset "REQ-reason why a throw missed, and the wind's share" begin
    for (number, level) in enumerate(levels())
        speed = aim(level)
        for (factor, word) in ((0.8, "SHORT by "), (1.2, "LONG by "))
            thrown = shoot(ArcLanding.Game(number), factor * speed, 45)
            range = trajectory(factor * speed, 45; wind=level.wind).range
            calm = trajectory(factor * speed, 45; wind=0).range
            edge = word == "SHORT by " ? level.centre - level.half - range : range - level.centre - level.half
            @test !thrown.won && edge > 0
            @test occursin(word * string(round(edge; digits=2)) * " m", thrown.last)
            sign = range - calm < 0 ? "-" : "+"
            @test occursin("Wind moved the landing " * sign * string(round(abs(range - calm); digits=2)) * " m", thrown.last)
            @test occursin("without wind: " * string(round(calm; digits=2)) * " m", thrown.last)
            @test (range > calm) == (level.wind > 0) || level.wind == 0
        end
    end
    @test occursin("to LEFT", screen(ArcLanding.Game(findfirst(l -> l.wind < 0, levels()))))
end
@testset "REQ-retry nothing of the previous attempt remains" begin
    same(a, b) = (a.level, a.attempts, a.won, a.last, a.points) == (b.level, b.attempts, b.won, b.last, b.points)
    for number in 1:5
        fresh = ArcLanding.Game(number)
        played = shoot(shoot(fresh, 5, 45), 6, 30)
        @test played.attempts == 2 && !isempty(played.points)
        @test same(restart(played), fresh) && screen(restart(played)) == screen(fresh)
        @test same(next_level(played), ArcLanding.Game(mod1(number + 1, 5)))
        rows = filter(startswith("|"), split(screen(restart(played)), "\n"))
        @test length(rows) == 7 && !any(occursin("*"), rows) && !occursin("Landed", screen(next_level(played)))
        lost = shoot(played, 5, 45)
        @test occursin("LOST", screen(lost)) && shoot(lost, 16.5, 45) === lost
        @test same(restart(lost), fresh)
    end
    @test restart(ArcLanding.Game()).points !== ArcLanding.Game().points
    # through the real loop: lose level 1, retry and win; n goes on; a throw at a finished level is ignored
    g = play(IOBuffer("1 1\n1 1\n1 1\n16.5 45\nr\n16.5 45\n"), IOBuffer())
    @test g.won && g.level == 1 && g.attempts == 1
    out = IOBuffer()
    g = play(IOBuffer("16.5 45\n10 45\nn\n10 45\nn\nn\nn\nn\n"), out)
    @test g.level == 1 && g.attempts == 0 && !g.won  # five times n comes back round to level 1
    text = String(take!(out))
    @test occursin("level 2/5", text) && occursin("level 5/5", text)
    @test count("throws 2/3", text) == 0  # the throw after the win was not counted on level 1
    @test play(IOBuffer("r\nn\nq\n16.5 45\n"), IOBuffer()).attempts == 0
end
