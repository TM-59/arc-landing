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
    g = shoot(ArcLanding.Game(), 17, 45)
    @test g.won
    @test shoot(g, 1, 1) === g
    lost = foldl((g, _) -> shoot(g, 1, 1), 1:3; init=ArcLanding.Game())
    @test occursin("LOST", screen(lost))
    @test play(IOBuffer("NaN 45\nwrong\n17 45\n"), IOBuffer()).attempts == 1
    @test play(IOBuffer(""), IOBuffer()).attempts == 0
end
