# Identity: per-trait Gamma + shared site-X vs shared-α fit_gllvm_cov.
# Contract (decision 2026-08-03): G=1 matches shared cov; constant αvec + X
# offset matches shared cov marginal to ~1e-10. No silent tolerance widen
# (same band spirit as #172 / #175).

using Test
using Random
using LinearAlgebra
using Distributions
using GLLVM

@testset "Gamma + X identity (API B under X)" begin

    @testset "constant αvec + X offset == shared Gamma cov marginal" begin
        Random.seed!(8201)
        p, n, K, q = 4, 30, 1, 1
        β = 0.2 .* randn(p) .+ 0.8
        γ = [0.4]
        Λ = 0.3 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ)
        Z = randn(K, n)
        η = β .+ O .+ Λ * Z
        α = 4.0
        Y = Matrix{Float64}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(clamp(η[t, s], -4, 4))
            Y[t, s] = rand(Gamma(α, μ / α)) + 1e-6
        end
        αvec = fill(α, p)
        ll_g = GLLVM.gamma_grouped_marginal_loglik_laplace(Y, Λ, β, αvec; offset = O)
        fam = Gamma(α, 1.0)
        N = ones(Int, p, n)
        ll_s = GLLVM._marginal_loglik_offset(fam, Y, N, Λ, β, O, LogLink())
        @test isapprox(ll_g, ll_s; atol = 1e-10, rtol = 0)
    end

    @testset "fit_gamma_gllvm_grouped_cov G=1 ≈ fit_gllvm_cov" begin
        Random.seed!(8300)
        p, n, K, q = 5, 120, 1, 1
        β_true = 0.25 .* randn(p) .+ 0.9
        γ_true = [0.5]
        Λ_true = 0.35 .* randn(p, K)
        X = randn(p, n, q)
        O = GLLVM._build_offset(X, γ_true)
        Z = randn(K, n)
        η = β_true .+ O .+ Λ_true * Z
        α_true = 3.5
        Y = Matrix{Float64}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(clamp(η[t, s], -4, 4))
            Y[t, s] = rand(Gamma(α_true, μ / α_true)) + 1e-6
        end
        fg = fit_gamma_gllvm_grouped_cov(Y; X = X, K = K, group = ones(Int, p),
                                         iterations = 200)
        @test fg isa GammaGroupedCovFit
        @test length(fg.α) == 1
        @test length(fg.γ) == q
        @test isfinite(fg.loglik)
        fs = fit_gllvm_cov(Y; family = Gamma(), X = X, K = K, iterations = 200)
        @test isapprox(fg.loglik, fs.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fg.α[1], fs.dispersion; rtol = 0.15)
    end
end
