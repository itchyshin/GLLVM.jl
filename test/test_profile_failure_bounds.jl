using Test
@testset "GE profile failure bounds" begin
    @test isnan(GLLVM._profile_bisect_side(x->NaN,0.,1.,3.84))
    @test isnan(GLLVM._profile_bisect_side(x->abs(x)<1 ? x^2 : NaN,0.,.5,3.84))
    @test GLLVM._profile_bisect_side(x->abs(x)<3 ? x^2 : NaN,0.,5.,3.84) ≈ sqrt(3.84) atol=1e-3
    @test GLLVM._profile_bisect_side(x->x^2,0.,1.,3.84) ≈ sqrt(3.84) atol=1e-3
end
