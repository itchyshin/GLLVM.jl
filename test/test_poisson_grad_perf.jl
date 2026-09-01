# Workflow Q gate for the Poisson perf repair (core070, poisson-perf-repair-notes.md).
#
# (a) FD-vs-analytic gradient check on a seeded p=10, n=100, K=2 fixture (≤1e-6).
# (b) Fitted logLik on a seeded p=20, n=500 fixture must match the PRE-REPAIR
#     baseline to ≤1e-8 — see provenance comment below.
# (c)/(d) full-suite green and honest before/after timing are recorded in
#     docs/dev-log/core070/poisson-perf-repair-notes.md, not asserted here (wall
#     time is not a reproducible CI assertion).

using GLLVM, Test, Random, LinearAlgebra
using Distributions: Poisson as _PoissonDist

@testset "Poisson perf repair — gradient + logLik gates (core070)" begin
    @testset "FD gradient check, p=10, n=100, K=2" begin
        Random.seed!(20260901)
        p, K, n = 10, 2, 100
        β = randn(p) .* 0.3
        Λ = randn(p, K) .* 0.4
        Y = rand(0:8, p, n)

        rr = GLLVM.rr_theta_len(p, K)
        θ = vcat(β, GLLVM.pack_lambda(Λ))

        f = function (θv)
            b = θv[1:p]
            L = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            return GLLVM.poisson_marginal_loglik_laplace(Y, L, b, LogLink();
                                                         maxiter = 200, tol = 1e-12)
        end

        m = length(θ)
        g_fd = similar(θ)
        h = 1e-5
        for i in 1:m
            θp = copy(θ); θp[i] += h
            θm = copy(θ); θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end

        g_an = GLLVM.poisson_laplace_grad(Y, Λ, β)

        @test length(g_an) == m
        @test all(isfinite, g_an)
        maxrel = maximum(abs.(g_an .- g_fd) ./ max.(abs.(g_fd), 1.0))
        @test maxrel <= 1e-6
    end

    @testset "Fitted logLik regression, p=20, n=500, K=2" begin
        # PROVENANCE: baseline captured on the pre-repair commit (before R2/R3/R4),
        # using this exact fixture (MersenneTwister(20260901), Poisson via
        # Distributions.jl), via `fit_poisson_gllvm(Y; K=2)` with default settings
        # (no optimizer tolerance changes made anywhere in the repair). Captured
        # 2026-09-01, GLLVM.jl branch codex/core070-aghq-20260830, commit b1e704e4.
        # If this test ever needs to change, the cause must be a genuine numerical
        # fix, never a repair-induced drift — re-derive the number by hand, do not
        # copy the post-repair value back in.
        BASELINE_LOGLIK = -14604.017303313138

        rng = Random.MersenneTwister(20260901)
        p, K, n = 20, 2, 500
        Λ = randn(rng, p, K) .* 0.5
        β = randn(rng, p) .* 0.3
        Z = randn(rng, K, n)
        η = β .+ Λ * Z
        μ = exp.(clamp.(η, -5, 5))
        Y = [rand(rng, _PoissonDist(μ[t, s])) for t in 1:p, s in 1:n]

        fit = GLLVM.fit_poisson_gllvm(Y; K = 2)
        @test fit.converged
        @test isapprox(fit.loglik, BASELINE_LOGLIK; atol = 1e-8, rtol = 0)
    end
end
