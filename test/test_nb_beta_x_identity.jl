# Identity: per-trait NB2/Beta + shared site-X vs shared-φ fit_gllvm_cov.
# Contract (decision 2026-08-02): G=1 + hessian=:fisher matches shared cov;
# constant rvec/φvec + X offset matches shared cov marginal to ~1e-10.
# No silent tolerance widen (same band spirit as #172).

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

@testset "NB2/Beta + X identity (API B under X)" begin

    @testset "constant rvec + X offset == shared NB cov marginal" begin
        Random.seed!(8101)
        p, n, K, q = 4, 30, 1, 1
        β = 0.2 .* randn(p) .+ 1.0
        γ = [0.4]
        Λ = 0.3 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ)
        Z = randn(K, n)
        η = β .+ O .+ Λ * Z
        Y = Matrix{Int}(undef, p, n)
        r = 6.0
        for t in 1:p, s in 1:n
            μ = exp(η[t, s])
            Y[t, s] = rand(NegativeBinomial(r, r / (r + μ)))
        end
        rvec = fill(r, p)
        ll_g = GLLVM.nb_grouped_marginal_loglik_laplace(Y, Λ, β, rvec;
                                                       offset = O, hessian = :fisher)
        fam = NegativeBinomial(r, 0.5)
        N = ones(Int, p, n)
        ll_s = GLLVM._marginal_loglik_offset(fam, Float64.(Y), N, Λ, β, O, LogLink())
        @test isapprox(ll_g, ll_s; atol = 1e-10, rtol = 0)
    end

    @testset "constant φvec + X offset == shared Beta cov marginal" begin
        Random.seed!(8102)
        p, n, K, q = 4, 30, 1, 1
        β = 0.2 .* randn(p)
        γ = [0.35]
        Λ = 0.25 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ)
        Z = randn(K, n)
        η = β .+ O .+ Λ * Z
        φ = 12.0
        Y = Matrix{Float64}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = clamp(1 / (1 + exp(-η[t, s])), 1e-6, 1 - 1e-6)
            Y[t, s] = clamp(rand(Beta(μ * φ, (1 - μ) * φ)), 1e-6, 1 - 1e-6)
        end
        φvec = fill(φ, p)
        ll_g = GLLVM.beta_grouped_marginal_loglik_laplace(Y, Λ, β, φvec;
                                                         offset = O, hessian = :fisher)
        fam = Beta(φ, 1.0)
        N = ones(Int, p, n)
        ll_s = GLLVM._marginal_loglik_offset(fam, Y, N, Λ, β, O, LogitLink())
        @test isapprox(ll_g, ll_s; atol = 1e-10, rtol = 0)
    end

    @testset "fit_nb_gllvm_grouped_cov G=1+fisher ≈ fit_gllvm_cov" begin
        Random.seed!(8103)
        p, n, K, q = 5, 120, 1, 1
        β_true = 0.25 .* randn(p) .+ 1.1
        γ_true = [0.55]
        Λ_true = 0.35 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ_true)
        Z = randn(K, n)
        η = β_true .+ O .+ Λ_true * Z
        r_true = 5.0
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(η[t, s])
            Y[t, s] = rand(NegativeBinomial(r_true, r_true / (r_true + μ)))
        end
        fg = fit_nb_gllvm_grouped_cov(Y; X = X, K = K, group = ones(Int, p),
                                      hessian = :fisher, iterations = 200)
        @test fg isa NBGroupedCovFit
        @test length(fg.r_group) == 1
        @test length(fg.γ) == q
        @test isfinite(fg.loglik)
        fs = fit_gllvm_cov(Y; family = NegativeBinomial(), X = X, K = K,
                           iterations = 200)
        @test isapprox(fg.loglik, fs.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fg.r_group[1], fs.dispersion; rtol = 0.15)
    end

    @testset "fit_beta_gllvm_grouped_cov G=1+fisher ≈ fit_gllvm_cov" begin
        Random.seed!(8104)
        p, n, K, q = 5, 120, 1, 1
        β_true = 0.2 .* randn(p)
        γ_true = [0.45]
        Λ_true = 0.3 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ_true)
        Z = randn(K, n)
        η = β_true .+ O .+ Λ_true * Z
        φ_true = 10.0
        Y = Matrix{Float64}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = clamp(1 / (1 + exp(-η[t, s])), 1e-6, 1 - 1e-6)
            Y[t, s] = clamp(rand(Beta(μ * φ_true, (1 - μ) * φ_true)), 1e-6, 1 - 1e-6)
        end
        fg = fit_beta_gllvm_grouped_cov(Y; X = X, K = K, group = ones(Int, p),
                                        hessian = :fisher, iterations = 200)
        @test fg isa BetaGroupedCovFit
        @test length(fg.φ) == 1
        @test length(fg.γ) == q
        @test isfinite(fg.loglik)
        fs = fit_gllvm_cov(Y; family = Beta(), X = X, K = K, iterations = 200)
        @test isapprox(fg.loglik, fs.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fg.φ[1], fs.dispersion; rtol = 0.15)
    end
end
