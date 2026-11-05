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
