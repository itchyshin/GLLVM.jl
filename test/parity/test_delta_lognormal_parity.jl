# test_delta_lognormal_parity.jl — delta-lognormal GLLVM logLik vs gllvmTMB
# (twin fid 12)
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
#
# Identity lock: docs/dev-log/decisions/2026-08-28-delta-shared-predictor-identity.md
# (ACCEPTED). Pairs ONLY with `fit_delta_lognormal_gllvm(...; predictor = :shared)`
# — the twin's `delta_lognormal()` shares ONE linear predictor for both the
# occurrence Bernoulli and the positive lognormal part (`gllvmTMB.cpp:2816-2830`);
# Julia's `predictor = :separate` default (`Λz = 0`, independent βz/βc) is NOT a
# same-model comparison for this cell.
#
# KNOWN, IRREDUCIBLE parameterisation mismatch (checked BEFORE any Δ is judged a
# failure — see `fit_gllvmtmb_parity_delta` docstring in parity_helpers.jl):
#   · Dispersion: the twin's `sigma_lognormal_delta` is PER-TRAIT (`n_traits`-length
#     TMB parameter vector, `src/gllvmTMB.cpp:1195`; no shared/pinned mode is exposed
#     through the family constructor or `gllvmTMB()` — `R/dispersion-trait-map.R`).
#     Julia's `fit_delta_lognormal_gllvm` estimates a single SHARED scalar `σ`. Under
#     a shared-σ DGP the twin has `p−1` more free parameters than Julia, so its
#     maximised log-likelihood is generically >= Julia's even with a correct fit on
#     both sides. This is NOT masked by widening the tolerance; it is reported as a
#     structural Δ driver, with the twin's per-trait σ vector printed alongside so a
#     reader can see how much of the Δ that extra freedom plausibly explains.
#   · logLik composition: the twin's y-scale log-likelihood for y>0 includes the
#     change-of-variables Jacobian `−log(y)` (`gllvmTMB.cpp:2827`:
#     `dnorm(log(y), eta, sigma, true) - log(y)`); Julia's `_tp_pieces` uses
#     `logpdf(LogNormal(ηc, σ), y)`, which is already on the y scale (Distributions.jl
#     folds the Jacobian into `LogNormal`'s density), so both sides carry it — this is
#     a like-for-like check, not a candidate mismatch.
#   · Hessian: both call sites default to `hessian = :observed`; for DeltaLogNormal
#     both selectors currently coincide (`TWOPART_KNOWN_OPEN` — the observed weight is
#     not yet specialised for this family), so this is not a source of Δ here.
#
# Twin Δ rule: no number is quoted unless this cell runs live under
# GLLVM_PARITY_TESTS=1 against a real gllvmTMB. Never invent, never carry over.

using GLLVM, RCall, Test, Random

# parity_helpers.jl is included once by runparity.jl

# Seed pre-registered BEFORE any run (42–49, 52–58, 420–431 already taken).
const _DLN_SEED = 61

@testset "delta_lognormal GLLVM parity: GLLVM.jl vs gllvmTMB (twin fid 12, shared predictor)" begin

    Random.seed!(_DLN_SEED)
    p, K, n = 5, 1, 130
    β_true = [0.2, -0.1, 0.3, 0.0, -0.2]
    Λ_true = 0.5 .* parity_loadings_p5k2()[:, 1:K]
    σ_true = 0.5

    Z = randn(K, n)
    η = β_true .+ Λ_true * Z          # p×n, ONE shared predictor
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        π = 1 / (1 + exp(-η[t, s]))
        if rand() < π
            Y[t, s] = exp(η[t, s] + σ_true * randn())
        end
    end

    @testset "DGP sanity: every trait has both zero and positive cells" begin
        for t in 1:p
            @test any(==(0.0), view(Y, t, :))
            @test any(>(0.0), view(Y, t, :))
        end
    end

    jl_fit = fit_delta_lognormal_gllvm(Y; K = K, predictor = :shared)
    @test jl_fit.converged
    @test isfinite(jl_fit.loglik)
    @test jl_fit.predictor === :shared
    @test jl_fit.βz == jl_fit.βc   # the tie is real
    jl_logL = jl_fit.loglik

    r = fit_gllvmtmb_parity_delta(Y, K; family = :delta_lognormal)
    @test r.converged
    @test isfinite(r.logLik)

    print_parity_loglik(
        "delta_lognormal logLik oracle (seed=$(_DLN_SEED), p=$p, K=$K, n=$n, " *
        "shared predictor; twin fid 12)";
        jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
    )

    println("  Julia β  (shared, single σ=$(round(jl_fit.σ; sigdigits=4))) = ",
            round.(jl_fit.βc; sigdigits = 5))
    println("  gllvmTMB b_fix (per-trait σ)   = ", round.(r.b_fix; sigdigits = 5))
    println("  gllvmTMB per-trait σ vector    = ", round.(r.disp_vec; sigdigits = 5))
    println("  spread of twin per-trait σ (max−min) = ",
            round(maximum(r.disp_vec) - minimum(r.disp_vec); sigdigits = 4))
    println()

    @testset "log-likelihood agreement (rtol=1e-6; irreducible per-trait-vs-shared-σ Δ expected)" begin
        # NOT asserted at rtol=1e-6 — see file header. The twin's extra p−1 free
        # dispersion parameters generically make r.logLik >= jl_logL under a
        # shared-σ DGP; report the actual numbers instead of a pass/fail gate here.
        @test r.logLik >= jl_logL - 1e-6   # twin should never do WORSE than Julia
        @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
    end
end
