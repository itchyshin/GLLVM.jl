# test_nox_dispersion_parity.jl — no-X light logLik oracles for the three families
# that previously had twin Δ evidence ONLY through the +X cohort:
#   Gamma (twin fid 4) · NB1 (twin fid 15) · BetaBinomial (twin fid 8)
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
#
# Why these three together: each is a per-trait-dispersion family whose R default
# estimates one dispersion PER TRAIT. The Julia side must therefore pair with the
# GROUPED fitter (`group = collect(1:p)`), never the shared-dispersion default — the
# same pairing already proven under X in `test_x_covariate_parity.jl`. Getting this
# wrong does not error; it silently compares two different models, so the pairing is
# named explicitly in every testset below.
#
# Dispersion identities (already ACCEPTED — no new decision needed for these cells):
#   Gamma        docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md
#   NB1          docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md
#   BetaBinomial docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md
# Those docs lock the granularity under X; the no-X arm is the same twin default with
# the γ term removed, so they carry over. Nothing here promotes a ledger row.
#
# BetaBinomial trials: threaded to R as `weights` (twin API B — gllvmTMB reads a
# numeric weights vector of length nrow(data) as the per-row trial count), matching
# the +X cohort exactly.
#
# Comparability: Laplace on both sides for all three.
#
# Twin Δ rule: no number is quoted unless this file runs live under
# GLLVM_PARITY_TESTS=1 against a real gllvmTMB. Never invent, never carry over.

using GLLVM, RCall, Test, Random, LinearAlgebra
import Distributions

# parity_helpers.jl is included once by runparity.jl

# Seeds pre-registered BEFORE any run. 42–49 and 420–431 are taken by existing cells;
# 52/53 by the lognormal / truncated_poisson cells added the same day.
const _NOXD_SEED_GAMMA = 54
const _NOXD_SEED_NB1   = 55
const _NOXD_SEED_BB    = 56

@testset "no-X per-trait-dispersion light logLik: GLLVM.jl vs gllvmTMB" begin

    # ── Gamma (twin fid 4), per-trait shape α ────────────────────────────────
    @testset "Gamma no-X (twin fid 4, per-trait α)" begin
        Random.seed!(_NOXD_SEED_GAMMA)
        p, K, n = 5, 1, 120
        β = log.([2.0, 2.5, 1.8, 2.2, 2.1])
        α_true = 2.5
        Λ = 0.2 .* parity_loadings_p5k2()[:, 1:K]
        Z = randn(K, n)
        η = β .+ Λ * Z
        Y = [
            begin
                μ = exp(clamp(η[t, s], -4.0, 4.0))
                rand(Distributions.Gamma(α_true, μ / α_true)) + 1e-6
            end
            for t in 1:p, s in 1:n
        ]

        # Per-trait α — pair with the GROUPED fitter, not fit_gamma_gllvm.
        jl_fit = fit_gamma_gllvm_grouped(Y; K = K, group = collect(1:p))
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test length(jl_fit.α) == p          # genuinely per-trait, not shared
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik(Y, K; family = :gamma)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "Gamma no-X logLik oracle (seed=$(_NOXD_SEED_GAMMA), p=$p, K=$K, n=$n, per-trait α; twin fid 4)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end

    # ── NB1 (twin fid 15), per-trait linear-variance φ ───────────────────────
    @testset "NB1 no-X (twin fid 15, per-trait φ)" begin
        Random.seed!(_NOXD_SEED_NB1)
        p, K, n = 5, 1, 120
        β = log.([1.8, 2.2, 1.6, 2.0, 1.9])
        φ_true = 0.85
        Λ = 0.2 .* parity_loadings_p5k2()[:, 1:K]
        Z = randn(K, n)
        η = β .+ Λ * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(clamp(η[t, s], -3.5, 3.5))
            Y[t, s] = rand(Distributions.NegativeBinomial(μ / φ_true, 1 / (1 + φ_true)))
        end

        jl_fit = fit_nb1_gllvm_grouped(Y; K = K, group = collect(1:p))
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test length(jl_fit.φ) == p
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik(Float64.(Y), K; family = :nb1)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "NB1 no-X logLik oracle (seed=$(_NOXD_SEED_NB1), p=$p, K=$K, n=$n, per-trait φ; twin fid 15)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        # ── KNOWN ENGINE DEFECT — do NOT widen this tolerance ────────────────
        # `fit_nb1_gllvm_grouped` (the no-X grouped route) converges STABLY to a
        # log-likelihood ≈0.115 WORSE than the twin, i.e. ~1.0e-4 relative — 100×
        # the locked rtol. Isolated 2026-08-24; it is a defect in this route, not a
        # tolerance problem, not an identity mismatch, and not the twin being wrong:
        #
        #   fit_nb1_gllvm_grouped(Y; K, group)                 -> -1129.7817843739615
        #   fit_nb1_gllvm_grouped_cov(Y; X = zeros(p,n,1), …)  -> -1129.6667320237116
        #   gllvmTMB (twin fid 15)                             -> -1129.6667320371555
        #
        # An all-zero X contributes nothing, so the `_cov` route fits the SAME model
        # and matches the twin to 1.3e-8. The no-X route does not. Ruled out as
        # causes: outer convergence (loglik invariant for g_tol 1e-5 → 1e-10, always
        # `converged = true`) and inner Laplace mode accuracy (invariant for
        # newton_tol 1e-9 → 1e-12, newton_maxiter 100 → 500).
        #
        # Marked broken rather than deleted so the suite ALERTS when the engine is
        # fixed (`@test_broken` fails loudly once it starts passing). Fixing it is a
        # `src/` change and therefore a separate arc carrying a full `Pkg.test()`.
        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test_broken jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end

        # The twin-vs-`_cov`-route agreement IS assertable today, and pins the defect
        # to the no-X route specifically. This is the live evidence for the claim
        # above, so it runs as a real test rather than sitting in a comment.
        @testset "zero-X `_cov` route DOES match the twin (isolates the defect)" begin
            Xz = zeros(Float64, p, n, 1)
            f_cov = fit_nb1_gllvm_grouped_cov(Y; X = Xz, K = K, group = collect(1:p))
            @test f_cov.converged
            @test f_cov.loglik ≈ r.logLik rtol = 1e-6
            @test f_cov.loglik > jl_logL          # the no-X route is strictly worse
        end
    end

    # ── BetaBinomial (twin fid 8), per-trait φ, trials N via API-B weights ───
    @testset "BetaBinomial no-X (twin fid 8, per-trait φ, N=8)" begin
        Random.seed!(_NOXD_SEED_BB)
        p, K, n = 5, 1, 120
        β = [0.30, -0.20, 0.25, -0.15, 0.05]
        φ_true = 8.0
        N = fill(8, p, n)
        Λ = 0.2 .* parity_loadings_p5k2()[:, 1:K]
        Z = randn(K, n)
        η = β .+ Λ * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = clamp(1 / (1 + exp(-η[t, s])), 1e-4, 1 - 1e-4)
            psucc = clamp(rand(Distributions.Beta(μ * φ_true, (1 - μ) * φ_true)),
                          1e-6, 1 - 1e-6)
            Y[t, s] = rand(Distributions.Binomial(N[t, s], psucc))
        end
        @test all(0 .<= Y .<= N)

        jl_fit = fit_beta_binomial_gllvm_grouped(Y; K = K, N = N,
                                                 group = collect(1:p))
        @test jl_fit.converged
        @test isfinite(jl_fit.loglik)
        @test length(jl_fit.φ) == p
        jl_logL = jl_fit.loglik

        r = fit_gllvmtmb_parity_loglik(Float64.(Y), K; family = :betabinomial, N = N)
        @test r.converged
        @test isfinite(r.logLik)

        print_parity_loglik(
            "BetaBinomial no-X logLik oracle (seed=$(_NOXD_SEED_BB), p=$p, K=$K, n=$n, per-trait φ, N=8; twin fid 8)";
            jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
        )

        @testset "log-likelihood agreement (rtol=1e-6)" begin
            @test jl_logL ≈ r.logLik rtol = 1e-6
            @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
        end
    end
end
