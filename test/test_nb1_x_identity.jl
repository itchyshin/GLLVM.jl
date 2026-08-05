# Identity: per-trait NB1 + shared site-X vs shared-φ fit_gllvm_cov.
# Contract (decision 2026-08-05): G=1+fisher matches shared cov; constant φvec
# + X offset matches shared cov marginal to ~1e-10. No silent tolerance widen.

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

@testset "NB1 + X identity (API B under X)" begin

    @testset "constant φvec + X offset == shared NB1 cov marginal" begin
        Random.seed!(9101)
        p, n, K, q = 4, 40, 1, 1
        β = 0.2 .* randn(p) .+ 0.5
        γ = [0.35]
        Λ = 0.25 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ)
        Z = randn(K, n)
        η = β .+ O .+ Λ * Z
        φ = 0.8
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(clamp(η[t, s], -3, 3))
            Y[t, s] = rand(NegativeBinomial(μ / φ, 1 / (1 + φ)))
        end
        φvec = fill(φ, p)
        ll_g = GLLVM.nb1_grouped_marginal_loglik_laplace(Y, Λ, β, φvec;
                                                         offset = O, hessian = :fisher)
        fam = GLLVM.NB1(φ)
        N = ones(Int, p, n)
        ll_s = GLLVM._marginal_loglik_offset(fam, Float64.(Y), N, Λ, β, O, LogLink())
        @test isapprox(ll_g, ll_s; atol = 1e-10, rtol = 0)
    end

    @testset "fit_nb1_gllvm_grouped_cov G=1+fisher ≈ fit_gllvm_cov" begin
        Random.seed!(9200)
        p, n, K, q = 5, 140, 1, 1
        β_true = 0.2 .* randn(p) .+ 0.6
        γ_true = [0.45]
        Λ_true = 0.3 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ_true)
        Z = randn(K, n)
        η = β_true .+ O .+ Λ_true * Z
        φ_true = 0.9
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(clamp(η[t, s], -3, 3))
            Y[t, s] = rand(NegativeBinomial(μ / φ_true, 1 / (1 + φ_true)))
        end
        fg = fit_nb1_gllvm_grouped_cov(Y; X = X, K = K, group = ones(Int, p),
                                       hessian = :fisher, iterations = 200)
        @test fg isa NB1GroupedCovFit
        @test length(fg.φ) == 1
        @test length(fg.γ) == q
        @test isfinite(fg.loglik)
        fs = fit_gllvm_cov(Y; family = GLLVM.NB1(1.0), X = X, K = K, iterations = 200)
        @test isapprox(fg.loglik, fs.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fg.φ[1], fs.dispersion; rtol = 0.20)
    end
end
