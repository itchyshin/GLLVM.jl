using Test
using GLLVM
using Random
using Statistics

@testset "bridge predictor-informed latent-score X_lv" begin
    @testset "Gaussian X_lv bridge matches native centered oracle" begin
        Random.seed!(7311)
        p, n, K, q_lv = 4, 90, 1, 1
        X_lv = reshape(collect(range(-1.4, 1.4; length = n)), n, q_lv)
        α_trait = [0.7, -0.4, 0.2, 0.9]
        Λ_true = reshape([0.8, 0.45, -0.35, 0.25], p, K)
        alpha_lv_true = reshape([1.15], q_lv, K)
        Z_mean = X_lv * alpha_lv_true
        Z_innov = 0.25 .* randn(K, n)
        Y = α_trait .+ Λ_true * (Z_mean' .+ Z_innov) .+ 0.12 .* randn(p, n)

        br = bridge_fit(; y = Y, family = "gaussian", d = K, X_lv = X_lv)
        alpha_hat = vec(mean(Y; dims = 2))
        Yc = Y .- alpha_hat
        oracle = fit_gaussian_gllvm(Yc; K = K, X_lv = X_lv)

        @test br.model == "gaussian_xlv_rr"
        @test br.family == "gaussian"
        @test br.alpha ≈ alpha_hat atol = 0
        @test br.loadings ≈ getLoadings(oracle; rotate = true) atol = 1e-10
        @test br.scores ≈ getLV(oracle, Yc; X_lv = X_lv, component = :total,
                                rotate = true) atol = 1e-10
        @test br.scores_mean ≈ getLV(oracle, Yc; X_lv = X_lv, component = :mean,
                                     rotate = true) atol = 1e-10
        @test br.scores_innovation ≈ getLV(oracle, Yc; X_lv = X_lv,
                                           component = :innovation,
                                           rotate = true) atol = 1e-10
        @test br.lv_effects ≈ extract_lv_effects(oracle) atol = 1e-10
        @test br.alpha_lv ≈ extract_lv_effects(oracle; type = :axis_effect) atol = 1e-10
        @test br.sigma_eps ≈ oracle.pars.σ_eps atol = 0
        @test br.df == p + GLLVM._nparams(oracle)
        @test occursin("predictor-informed latent-score", br.note)
        @test occursin("Confidence intervals", br.note)
    end

    @testset "X_lv bridge unsupported combinations fail loudly" begin
        Y = randn(4, 45)
        X_lv = randn(45, 1)
        X = randn(4, 45, 1)

        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 0,
                                              X_lv = X_lv)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 1,
                                              X_lv = X_lv, X = X)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 1,
                                              X_lv = X_lv,
                                              options = Dict("ci_method" => "wald"))
        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 1,
                                              X_lv = randn(44, 1))
        @test_throws ArgumentError bridge_fit(; y = abs.(Y), family = "poisson",
                                              d = 1, X_lv = X_lv)
        @test_throws ArgumentError bridge_fit(; y = Y[1:2, :],
                                              family = ["gaussian", "poisson"],
                                              d = 1, X_lv = X_lv)
    end
end
