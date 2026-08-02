# test_x_covariate_parity.jl — shared site-X light logLik vs gllvmTMB
#
# Included by runparity.jl AFTER no-X cells. NEVER included by runtests.jl.
# Cohort 1: Gaussian / Binomial / Poisson with q=1 shared site covariate.
# Fence: NB2/Beta+X, Gamma, Ordinal+X (see LOOP/GOAL.md).

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
end
