# Identity: per-trait beta-binomial φ (+ optional shared site-X offset) vs the
# shared-φ marginal / fitter. Contract (decision 2026-08-05): constant φvec +
# X offset matches the shared marginal to ~1e-10; G=1 grouped (no X) matches
# fit_beta_binomial_gllvm. No engine for shared-φ + X yet (BB has no
# fit_gllvm_cov analogue), so the grouped_cov check is converged/finite plus a
# G=1 self-consistency check against the shared marginal. No silent tolerance
# widen.

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

@testset "BetaBinomial + X identity (API B under X)" begin

    @testset "constant φvec + offset == shared BB marginal" begin
        Random.seed!(9301)
        p, n, K, q = 4, 40, 1, 1
        β = 0.2 .* randn(p) .+ 0.3
        γ = [0.35]
        Λ = 0.25 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ)
        Z = randn(K, n)
        η = β .+ O .+ Λ * Z
        φ = 8.0
        N = fill(10, p, n)
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = GLLVM.linkinv(GLLVM.LogitLink(), η[t, s])
            a = μ * φ
            b = (1 - μ) * φ
            psucc = clamp(rand(Beta(a, b)), 1e-6, 1 - 1e-6)
            Y[t, s] = rand(Binomial(N[t, s], psucc))
        end
        φvec = fill(φ, p)
        ll_g = GLLVM.betabinomial_grouped_marginal_loglik_laplace(Y, N, Λ, β, φvec; offset = O)
        ll_s = GLLVM.betabinomial_marginal_loglik_laplace(Y, N, Λ, β, φ; offset = O)
        @test isapprox(ll_g, ll_s; atol = 1e-10, rtol = 0)
    end

    @testset "fit_beta_binomial_gllvm_grouped G=1 ≈ fit_beta_binomial_gllvm" begin
        Random.seed!(9302)
        p, n, K = 5, 140, 1
        β_true = 0.2 .* randn(p) .+ 0.3
        Λ_true = 0.3 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        φ_true = 10.0
        N = fill(8, p, n)
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = GLLVM.linkinv(GLLVM.LogitLink(), η[t, s])
            a = μ * φ_true
            b = (1 - μ) * φ_true
            psucc = clamp(rand(Beta(a, b)), 1e-6, 1 - 1e-6)
            Y[t, s] = rand(Binomial(N[t, s], psucc))
        end
        fg = fit_beta_binomial_gllvm_grouped(Y; K = K, N = N, group = ones(Int, p),
                                             iterations = 200)
        @test fg isa BetaBinomialGroupedFit
        @test length(fg.φ) == 1
        @test isfinite(fg.loglik)
        fs = fit_beta_binomial_gllvm(Y; K = K, N = N, iterations = 200)
        @test isapprox(fg.loglik, fs.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fg.φ[1], fs.φ; rtol = 0.20)
    end

    @testset "fit_beta_binomial_gllvm_grouped_cov converges + self-consistent" begin
        Random.seed!(9303)
        p, n, K, q = 5, 160, 1, 1
        β_true = 0.2 .* randn(p) .+ 0.3
        γ_true = [0.4]
        Λ_true = 0.3 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ_true)
        Z = randn(K, n)
        η = β_true .+ O .+ Λ_true * Z
        φ_true = 10.0
        N = fill(8, p, n)
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = GLLVM.linkinv(GLLVM.LogitLink(), η[t, s])
            a = μ * φ_true
            b = (1 - μ) * φ_true
            psucc = clamp(rand(Beta(a, b)), 1e-6, 1 - 1e-6)
            Y[t, s] = rand(Binomial(N[t, s], psucc))
        end
        fg = fit_beta_binomial_gllvm_grouped_cov(Y; X = X, K = K, N = N,
                                                  group = ones(Int, p), iterations = 200)
        @test fg isa BetaBinomialGroupedCovFit
        @test fg.converged
        @test length(fg.φ) == 1
        @test length(fg.γ) == q
        @test isfinite(fg.loglik)

        # G=1 self-consistency: the grouped_cov objective at the fitted params
        # must equal the shared marginal evaluated at the same (β, Λ, φ, offset).
        O̅ = GLLVM._build_offset(X, fg.γ)
        ll_check = betabinomial_marginal_loglik_laplace(Y, N, fg.Λ, fg.β, fg.φ[1]; offset = O̅)
        @test isapprox(ll_check, fg.loglik; atol = 1e-8, rtol = 0)
    end
end
