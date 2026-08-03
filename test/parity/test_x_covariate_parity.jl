# test_x_covariate_parity.jl — shared site-X light logLik vs gllvmTMB
#
# Included by runparity.jl AFTER no-X cells. NEVER included by runtests.jl.
# Cohort 1: Gaussian / Binomial / Poisson with q=1 shared site covariate (#170).
# Cohort 2 (Gamma Arc 2): Gamma with q=1 shared site-X + per-trait shape α,
# using Arc 1 fit_gamma_gllvm_grouped_cov (group=collect(1:p), default
# hessian=:observed — twin API B under X, per
# docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md).
# Fence: NB2/Beta+X (owned by #177 on other tip); Ordinal+X; X_lv.

using GLLVM, RCall, Test, Random, LinearAlgebra, Statistics

# Knuth sampler — matches test_poisson_parity.jl (no Distributions dep).
function _rand_poisson_x(λ::Float64)
    λ = clamp(λ, 0.0, 1e6)
    L = exp(-λ)
    k = 0
    prod = 1.0
    while true
        k += 1
        prod *= rand()
        prod <= L && return k - 1
    end
end

# Marsaglia–Tsang gamma sampler — matches test_negbin_parity.jl (no Distributions dep).
function _rand_gamma_shape_x(shape::Float64, scale::Float64)
    if shape < 1.0
        return _rand_gamma_shape_x(shape + 1.0, scale) * rand()^(1.0 / shape)
    end
    d = shape - 1.0 / 3.0
    c = 1.0 / sqrt(9.0 * d)
    while true
        z = randn()
        v = (1.0 + c * z)^3
        v <= 0 && continue
        u = rand()
        z2 = z * z
        u < 1.0 - 0.0331 * z2 * z2 && return d * v * scale
        logu = log(u)
        logu < 0.5 * z2 + d * (1.0 - v + log(v)) && return d * v * scale
    end
end

@testset "Shared site-X light logLik: GLLVM.jl vs gllvmTMB" begin

    @testset "Gaussian + shared X (q=1)" begin
        Random.seed!(420)
        p, K, n = 5, 2, 30
        Λ = parity_loadings_p5k2()
        γ = 0.55
        # Julia Gaussian+X has shared β only (no per-trait intercepts in Xβ).
        # Match no-X oracle: demean site x; centre Y per trait so R `0+trait`
        # intercepts do not shift the objective (J1 zero-mean alignment).
        x = randn(n)
        x .-= mean(x)
        X = parity_site_design(x, p)
        Z = randn(K, n)
        y = γ .* x' .+ Λ * Z .+ 0.7 .* randn(p, n)
        y .-= mean(y; dims = 2)

        jl_fit = fit_gaussian_gllvm(y; K = K, X = X)
        @test jl_fit.converged
        @test isfinite(jl_fit.logLik)
        jl_logL = jl_fit.logLik

        r = fit_gllvmtmb_parity_loglik_x(y, x, K; family = :gaussian)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "Gaussian+X logLik oracle (seed=420, p=$p, K=$K, n=$n, q=1 shared)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end

    @testset "Binomial + shared X (q=1, Bernoulli)" begin
        # Milder loadings + larger n than the first probe: seed=421 / n=30 hit an
        # R runaway-loading (Heywood) warning and a large ΔlogLik. Keep rtol=1e-6.
        Random.seed!(431)
        p, K, n = 5, 2, 80
        β = [-0.3, 0.0, 0.3, -0.15, 0.2]
        Λ = 0.35 .* parity_loadings_p5k2()
        γ = 0.5
        x = randn(n)
        X = parity_site_design(x, p)
        Z = randn(K, n)
        η = β .+ γ .* x' .+ Λ * Z
        Y = [rand() < 1 / (1 + exp(-η[t, s])) ? 1 : 0 for t in 1:p, s in 1:n]

        jl_fit = fit_gllvm_cov(Y; family = GLLVM.Binomial(), X = X, K = K)
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik_x(Y, x, K; family = :binomial)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "Binomial+X logLik oracle (seed=431, p=$p, K=$K, n=$n, q=1 shared)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end

    @testset "Poisson + shared X (q=1)" begin
        Random.seed!(422)
        p, K, n = 5, 2, 30
        β = log.([2.5, 4.0, 2.0, 3.5, 3.0])
        Λ = 0.4 .* parity_loadings_p5k2()
        γ = 0.6
        x = randn(n)
        X = parity_site_design(x, p)
        Z = randn(K, n)
        η = β .+ γ .* x' .+ Λ * Z
        Y = [_rand_poisson_x(exp(clamp(η[t, s], -8.0, 8.0))) for t in 1:p, s in 1:n]

        jl_fit = fit_gllvm_cov(Y; family = GLLVM.Poisson(), X = X, K = K)
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik_x(Y, x, K; family = :poisson)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "Poisson+X logLik oracle (seed=422, p=$p, K=$K, n=$n, q=1 shared)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end

    @testset "Gamma + shared X (q=1)" begin
        # Per-trait shape α (group=collect(1:p)) + shared site-X slope γ —
        # twin API B under X
        # (docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md).
        # Default hessian=:observed (NOT :fisher — that's only for Arc 1
        # identity vs shared fit_gllvm_cov). Arc 2 unblocker: grouped Gamma
        # Laplace now defaults to TMB observed curvature (W=α y/μ); Fisher-only
        # was systematically Δ≈0.2–1 vs gllvmTMB.
        # DGP follows NB2/Beta Arc 2 lesson: K=1, mild loadings, n large enough
        # that every per-trait α stays interior (no Heywood / rtol widen).
        Random.seed!(46)
        p, K, n = 5, 1, 120
        β = log.([2.0, 2.5, 1.8, 2.2, 2.1])
        α_true = 2.5
        Λ = 0.2 .* parity_loadings_p5k2()[:, 1:K]
        γ = 0.4
        x = randn(n)
        X = parity_site_design(x, p)
        Z = randn(K, n)
        η = β .+ γ .* x' .+ Λ * Z
        Y = [
            begin
                μ = exp(clamp(η[t, s], -4.0, 4.0))
                _rand_gamma_shape_x(α_true, μ / α_true) + 1e-6
            end
            for t in 1:p, s in 1:n
        ]

        jl_fit = fit_gamma_gllvm_grouped_cov(Y; X = X, K = K, group = collect(1:p))
        @test jl_fit isa GammaGroupedCovFit
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test length(jl_fit.α) == p
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik_x(Y, x, K; family = :gamma)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "Gamma+X logLik oracle (seed=46, p=$p, K=$K, n=$n, q=1 shared, per-trait α)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end
end
