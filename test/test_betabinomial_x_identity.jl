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

    # No-X public surfaces for BetaBinom (Identity 2026-08-16, C1–C4). Both
    # `fit_gllvm` and `@formula` with no covariates must reach the SAME per-trait
    # engine the bridge and the `+ X` route already use — via the coerce, not a bare
    # shared-φ arm — and both must require the p×n trial counts.
    @testset "BetaBinom no-X public surfaces: fit_gllvm and @formula" begin
        Random.seed!(9304)
        p, n, K = 4, 50, 1
        β_true = 0.2 .* randn(p) .+ 0.3
        Λ_true = 0.3 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        φ_true = 10.0
        # A genuine p×n trial matrix (not a constant), all ≥ 5 so φ is identified.
        N = [5 + ((t + i) % 4) for t in 1:p, i in 1:n]
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = GLLVM.linkinv(GLLVM.LogitLink(), η[t, s])
            psucc = clamp(rand(Beta(μ * φ_true, (1 - μ) * φ_true)), 1e-6, 1 - 1e-6)
            Y[t, s] = rand(Binomial(N[t, s], psucc))
        end

        # C2: the per-trait coerce, identical to calling the grouped fitter directly.
        fu = fit_gllvm(Y; family = BetaBinom(), K = K, N = N, iterations = 40)
        direct = fit_beta_binomial_gllvm_grouped(Y; K = K, N = N, group = collect(1:p),
                                                 iterations = 40)
        @test fu isa BetaBinomialGroupedFit
        @test length(fu.φ) == p && all(fu.φ .> 0)
        @test fu.group == collect(1:p)
        @test fu.loglik ≈ direct.loglik atol = 1e-8

        # C1: the marker's φ is a tag payload — never read, never an init.
        @test fit_gllvm(Y; family = BetaBinom(7.5), K = K, N = N,
                        iterations = 40).loglik ≈ fu.loglik atol = 1e-8
        @test BetaBinom().φ == 1.0

        # C3: `N` is required at this boundary and is not broadcast from a scalar,
        # because φ is unidentifiable at N = 1 (the named fitter's all-ones default).
        @test_throws ArgumentError fit_gllvm(Y; family = BetaBinom(), K = K, iterations = 5)
        @test_throws ArgumentError fit_gllvm(Y; family = BetaBinom(), K = K, N = 8,
                                            iterations = 5)

        # An explicit group vector routes the same way; :species is the default.
        @test fit_gllvm(Y; family = BetaBinom(), K = K, N = N, disp_group = :species,
                        iterations = 40).loglik ≈ fu.loglik atol = 1e-8

        # C2: shared φ stays reachable only through the named fitter, and is distinct.
        shared = fit_beta_binomial_gllvm(Y; K = K, N = N, iterations = 40)
        @test shared isa BetaBinomialFit
        @test shared.φ isa Real

        # The `@formula` no-X surface opens by fall-through to `fit_gllvm`.
        ff = gllvm(@formula(y ~ 1), Y, (; temp = randn(n)); family = BetaBinom(), K = K,
                   N = N, iterations = 40)
        @test ff isa BetaBinomialGroupedFit
        @test ff.loglik ≈ fu.loglik atol = 1e-8
        @test_throws ArgumentError gllvm(@formula(y ~ 1), Y, (; temp = randn(n));
                                         family = BetaBinom(), K = K, iterations = 5)
    end
end
