using Test
using GLLVM
using LinearAlgebra
using Random

Random.seed!(220)

@testset "Gaussian dense-kernel bridge unique source" begin
    p = 2
    groups = [2, 1, 2, 3, 1, 3]
    K = [1.4 0.2 0.1; 0.2 1.1 0.25; 0.1 0.25 1.3]
    Y = [
        0.4  -0.2  0.8  0.1  -0.5  0.6
        -0.3  0.5  0.1  -0.7  0.2  0.4
    ]
    source = SourceCovariance(
        K;
        groups = groups,
        name = :cross,
        mode = :latent,
        rank = 1,
        unique = true,
        common = false,
    )

    @test source.unique
    @test source.mode === :latent
    @test source.projection[1, 2] == 1.0
    @test source.projection[2, 1] == 1.0
    @test source.projection[3, 2] == 1.0

    theta = [0.0, 0.0, 0.35, -0.2, log(0.4), log(0.55), log(0.5)]
    B = only(GLLVM._source_trait_covariances([source], p, theta[3:6]))
    L = GLLVM.unpack_lambda(theta[3:4], p, 1)
    @test B ≈ L * L' + Diagonal(exp.(2 .* theta[5:6])) atol = 1e-12
    @test B[1, 2] != 0.0

    payload = GLLVM.bridge_fit(
        y = Y,
        family = "gaussian",
        d = 1,
        trait_names = ["t1", "t2"],
        unit_names = ["u1", "u2", "u3", "u4", "u5", "u6"],
        sources = [Dict(
            "name" => "cross",
            "covariance" => K,
            "groups" => groups,
            "mode" => "latent",
            "rank" => 1,
            "unique" => true,
            "common" => false,
        )],
        options = Dict("g_tol" => 1e-6, "iterations" => 200),
    )
    @test payload.source_names == ["cross"]
    @test payload.source_unique == [true]
    @test size(payload.source_covariance) == (p, p)
    @test payload.source_covariance ≈ payload.Sigma - payload.sigma_eps^2 * I atol = 1e-8
    println("KERNEL_LATENT_UNIQUE_JULIA_OK")
end
