using GLLVM, Test, Random, Distributions, Statistics

# Build a (p,n,1) design carrying a single shared site covariate: X[t,s,1] = x[s].
function _site_design(x::AbstractVector, p::Integer)
    n = length(x)
    X = zeros(p, n, 1)
    @inbounds for t in 1:p, s in 1:n
        X[t, s, 1] = x[s]
    end
    return X
end

@testset "Non-Gaussian covariates (Xβ)" begin
    @testset "offset marginal Λ=0 reduces to independent GLM loglik (exact)" begin
        Random.seed!(180)
        p, K, n = 5, 2, 40
        β = 0.3 .* randn(p); γ = [0.7]
        x = randn(n); X = _site_design(x, p)
        Y = [rand(Poisson(exp(β[t] + γ[1] * x[s]))) for t in 1:p, s in 1:n]
        O = GLLVM._build_offset(X, γ)
        @test O[3, 4] ≈ γ[1] * x[4] atol = 1e-12      # offset construction
        ll = GLLVM._marginal_loglik_offset(Poisson(), Y, ones(Int, p, n),
                                           zeros(p, K), β, O, LogLink())
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Poisson(exp(β[t] + γ[1] * x[s])), Y[t, s])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "fit_gllvm_cov (Poisson) recovers γ, β, Λ" begin
        Random.seed!(181)
        p, K, n = 8, 2, 300
        β_true = 0.3 .* randn(p)
        γ_true = [0.8]
        Λ_true = 0.4 .* randn(p, K)
        x = randn(n); X = _site_design(x, p)
        Z = randn(K, n)
        η = β_true .+ γ_true[1] .* x' .+ Λ_true * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_gllvm_cov(Y; family = Poisson(), X = X, K = K)
        @test fit isa GllvmCovFit
        @test isfinite(fit.loglik)
        @test length(fit.γ) == 1
        @test isapprox(fit.γ[1], γ_true[1]; atol = 0.2)        # the headline: env coefficient
        @test cor(fit.β, β_true) > 0.7
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        @test isnan(fit.dispersion)                            # Poisson has none
    end

    @testset "fit_gllvm_cov (NB) recovers γ + dispersion" begin
        Random.seed!(182)
        p, K, n, r_true = 6, 2, 350, 8.0
        β_true = 0.3 .* randn(p) .+ 0.5
        γ_true = [-0.6]
        Λ_true = 0.4 .* randn(p, K)
        x = randn(n); X = _site_design(x, p)
        Z = randn(K, n)
        η = β_true .+ γ_true[1] .* x' .+ Λ_true * Z
        Y = [rand(NegativeBinomial(r_true, r_true / (r_true + exp(η[t, s])))) for t in 1:p, s in 1:n]

        fit = fit_gllvm_cov(Y; family = NegativeBinomial(), X = X, K = K)
        @test fit isa GllvmCovFit
        @test isfinite(fit.loglik)
        @test isapprox(fit.γ[1], γ_true[1]; atol = 0.25)
        @test 0.3 * r_true < fit.dispersion < 4 * r_true
    end

    @testset "γ ≈ 0 when the covariate carries no signal" begin
        Random.seed!(183)
        p, K, n = 6, 1, 250
        β_true = 0.2 .* randn(p)
        Λ_true = 0.4 .* randn(p, K)
        x = randn(n); X = _site_design(x, p)            # x not used in the DGP
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        fit = fit_gllvm_cov(Y; family = Poisson(), X = X, K = K)
        @test abs(fit.γ[1]) < 0.2                        # near zero: no spurious effect
    end

    @testset "covariate post-fit + confidence intervals" begin
        Random.seed!(184)
        p, K, n = 6, 1, 200
        β_true = 0.3 .* randn(p); γ_true = [0.7]; Λ_true = 0.4 .* randn(p, K)
        x = randn(n); X = _site_design(x, p)
        Z = randn(K, n)
        η = β_true .+ γ_true[1] .* x' .+ Λ_true * Z
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        fit = fit_gllvm_cov(Y; family = Poisson(), X = X, K = K)

        # post-fit surface
        @test size(getLV(fit, Y, X)) == (n, K)
        P = predict(fit, Y, X; type = :response)
        @test size(P) == (p, n) && all(P .>= 0)
        @test size(predict(fit, Y, X; type = :link)) == (p, n)
        @test isfinite(aic(fit)) && isfinite(bic(fit, n))

        # confidence intervals (needs X)
        ci = confint(fit, Y; method = :wald, X = X, parm = "gamma[1]")
        @test ci.term == ["gamma[1]"]
        @test ci.estimate[1] ≈ fit.γ[1] atol = 1e-8
        @test_throws ArgumentError confint(fit, Y; method = :wald)   # X required
    end
end
