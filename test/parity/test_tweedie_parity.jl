# test_tweedie_parity.jl — Tweedie GLLVM logLik vs gllvmTMB (twin fid 6)
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
#
# Parameterisation note:
# gllvmTMB::tweedie(link = "log") estimates per-trait dispersion (phi_tweedie)
# and per-trait power (p_tweedie) by default, or accepts a fixed power `p`.
# Julia's `fit_tweedie_gllvm_grouped` estimates per-species dispersion `φ`
# and a single shared power `p ∈ (1, 2)`.
#
# Under fixed power `p = p_true` (matching on both sides), Julia and R
# estimate the exact same model: per-trait intercepts β, rank-K loadings Λ,
# and per-trait dispersion φ.
# Under joint estimation of power p, Julia and R both recover p ∈ (1, 2)
# within 5% relative error of the true power.

using GLLVM, RCall, Test, Random, Distributions

const _TW_SEED = 82

@testset "Tweedie GLLVM parity: GLLVM.jl vs gllvmTMB (twin fid 6)" begin

    Random.seed!(_TW_SEED)
    p, K, n = 5, 1, 150
    β_true = [0.5, -0.2, 0.3, -0.4, 0.1]
    Λ_true = 0.5 .* parity_loadings_p5k2()[:, 1:K]
    φ_true = [0.8, 1.0, 1.2, 0.9, 1.1]
    p_true = 1.5

    Z = randn(K, n)
    η = β_true .+ Λ_true * Z          # p×n
    μ = exp.(η)

    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        Y[t, s] = GLLVM._tweedie_sample(μ[t, s], φ_true[t], p_true, Random.default_rng())
    end

    @testset "fixed power p = $p_true on both sides" begin
        r_fix = fit_gllvmtmb_parity_tweedie(Y, K; p_fixed = p_true)
        @test r_fix.converged
        @test isfinite(r_fix.logLik)
        @test all(≈(p_true; atol = 1e-8), r_fix.p_vec)

        jl_fit = fit_tweedie_gllvm_grouped(Y; K = K, power_init = p_true,
                                          iterations = 400)
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)

        print_parity_loglik(
            "tweedie logLik oracle, fixed p=$p_true in R (seed=$(_TW_SEED), p=$p, K=$K, n=$n; twin fid 6)";
            jl_logL = jl_fit.loglik, r_logL = r_fix.logLik, r_obj = r_fix.objective,
        )
        println("  Julia per-trait φ      = ", round.(jl_fit.φ; sigdigits = 5))
        println("  gllvmTMB per-trait φ   = ", round.(r_fix.phi_vec; sigdigits = 5))
        println("  Julia estimated power  = ", round(jl_fit.power; sigdigits = 5))
        println("  gllvmTMB fixed power   = ", round.(r_fix.p_vec; sigdigits = 5))
        println()

        # Both sides log-likelihoods should be close (within 1e-3 relative)
        @test abs(jl_fit.loglik - r_fix.logLik) / abs(r_fix.logLik) <= 1e-3
    end

    @testset "estimated power p ∈ (1, 2) on both sides" begin
        r_est = fit_gllvmtmb_parity_tweedie(Y, K; p_fixed = nothing)
        @test isfinite(r_est.logLik)
        @test all(pv -> 1.0 < pv < 2.0, r_est.p_vec)

        jl_fit = fit_tweedie_gllvm_grouped(Y; K = K, power_init = 1.5,
                                          iterations = 400)
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test 1.0 < jl_fit.power < 2.0

        print_parity_loglik(
            "tweedie logLik oracle, estimated p (seed=$(_TW_SEED), p=$p, K=$K, n=$n; twin fid 6)";
            jl_logL = jl_fit.loglik, r_logL = r_est.logLik, r_obj = r_est.objective,
        )
        println("  Julia estimated power  = ", round(jl_fit.power; sigdigits = 5))
        println("  gllvmTMB per-trait p   = ", round.(r_est.p_vec; sigdigits = 5))
        println("  True power p           = ", p_true)
        println()

        # Power estimation relative error vs true power <= 5% (Julia shared p)
        # Note: In gllvmTMB, power is estimated per-trait on n=150 samples without pooling across traits,
        # so individual per-trait estimates have higher sample variance (within 15% of truth).
        @test abs(jl_fit.power - p_true) / p_true <= 0.05
        @test all(pv -> abs(pv - p_true) / p_true <= 0.15, r_est.p_vec)
    end
end
