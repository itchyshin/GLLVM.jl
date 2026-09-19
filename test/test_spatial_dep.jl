using GLLVModels
using Test
using Random

@testset "spatial × dep admission" begin
    Random.seed!(14)
    p, n = 4, 25
    Y = randn(p, n)
    coords = randn(p, 2)

    @testset "fail-loud (no silent fallback)" begin
        @test_throws ArgumentError fit_spatial_dep_gllvm(Y)
        @test_throws ArgumentError fit_spatial_dep_gllvm(Y, coords)
        msg = try
            fit_spatial_dep_gllvm(Y, coords)
            ""
        catch e
            sprint(showerror, e)
        end
        @test occursin("not implemented yet", msg)
        @test occursin("mesh", msg)
        @test occursin("SPDE", msg)
    end

    @testset "coords row count must match traits" begin
        @test_throws ArgumentError fit_spatial_dep_gllvm(Y, randn(p + 1, 2))
    end
end
