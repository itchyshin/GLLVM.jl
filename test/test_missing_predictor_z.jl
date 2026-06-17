using GLLVM, Test, LinearAlgebra, Random, Statistics

# mi() covariate-model regressors: the site-level missing predictor x can carry
# an explicit covariate model x_s ~ N(μ_x + Z_s·γ, σ_x²) (auxiliary site
# predictors Z), the design's "explicit covariate model" for the imputation —
# better than a bare intercept-only x-model. Extends fit_gaussian_mi_fiml with a
# Z keyword; Z = nothing reproduces the intercept-only model.
@testset "fit_gaussian_mi_fiml with covariate-model regressors Z" begin
    function simulate(; p = 4, n = 400, K = 1, qz = 2, a, b_x, μ_x, γ, σ_x, σ_eps, Λ, seed = 1)
        Random.seed!(seed)
        Z = randn(n, qz)
        x = (μ_x .+ Z * γ) .+ σ_x .* randn(n)
        η = randn(K, n)
        y = a .+ b_x .* x' .+ Λ * η .+ σ_eps .* randn(p, n)
        return collect(y), collect(x), Z
    end

    @testset "recovers the x-model regression coefficients γ (complete data)" begin
        p, n, K, qz = 4, 600, 1, 2
        γ = [0.7, -0.4]
        Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        y, x, Z = simulate(; p, n, K, qz, a = zeros(p), b_x = 1.0,
                           μ_x = 0.3, γ, σ_x = 0.6, σ_eps = 0.3, Λ, seed = 11)
        res = fit_gaussian_mi_fiml(y, x; K = K, Z = Z)
        @test res.converged
        @test res.γ ≈ γ atol = 0.1
        @test abs(res.b_x - 1.0) < 0.15
    end

    @testset "Z = nothing reproduces the intercept-only fit" begin
        p, n, K = 4, 300, 1
        Λ = reshape([0.7, 0.5, -0.4, 0.3], p, K)
        Random.seed!(3)
        x = 0.5 .+ 0.7 .* randn(n)
        y = (0.2 .+ 0.8 .* x') .+ Λ * randn(K, n) .+ 0.3 .* randn(p, n)
        r0 = fit_gaussian_mi_fiml(y, x; K = K)
        r1 = fit_gaussian_mi_fiml(y, x; K = K, Z = nothing)
        @test r1.b_x ≈ r0.b_x atol = 1e-8
    end

    @testset "EBLUP uses Z at missing sites" begin
        p, n, K, qz = 4, 400, 1, 2
        γ = [0.8, -0.5]
        Λ = reshape([0.6, 0.5, -0.4, 0.3], p, K)
        y, x, Z = simulate(; p, n, K, qz, a = zeros(p), b_x = 0.9,
                           μ_x = 0.3, γ, σ_x = 0.6, σ_eps = 0.3, Λ, seed = 7)
        miss = [4, 19, 88, 250, 333]
        xtrue = x[miss]
        xm = Vector{Union{Missing,Float64}}(x)
        xm[miss] .= missing
        res = fit_gaussian_mi_fiml(y, xm; K = K, Z = Z)
        @test res.converged
        @test cor(res.eblup_x[miss], xtrue) > 0.5
    end
end
