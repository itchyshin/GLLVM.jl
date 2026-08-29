# test_delta_gamma_parity.jl — delta-gamma GLLVM logLik vs gllvmTMB (twin fid 13)
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
#
# Identity lock: docs/dev-log/decisions/2026-08-28-delta-shared-predictor-identity.md
# (ACCEPTED). Pairs ONLY with `fit_delta_gamma_gllvm(...; predictor = :shared)` — the
# twin's `delta_gamma()` shares ONE linear predictor for both the occurrence
# Bernoulli and the positive Gamma part (`gllvmTMB.cpp:2831-2844`); Julia's
# `predictor = :separate` default is NOT a same-model comparison for this cell.
#
# KNOWN, IRREDUCIBLE parameterisation mismatches (checked BEFORE any Δ is judged a
# failure — see `fit_gllvmtmb_parity_delta` docstring in parity_helpers.jl):
#   · Dispersion count: the twin's `phi_gamma_delta` is PER-TRAIT (`n_traits`-length
#     TMB parameter vector, `src/gllvmTMB.cpp:1196`; no shared/pinned mode is exposed
#     through the family constructor or `gllvmTMB()` — `R/dispersion-trait-map.R`).
#     Julia's `fit_delta_gamma_gllvm` estimates a single SHARED scalar `α` (shape).
#     Under a shared-dispersion DGP the twin has `p−1` more free parameters, so its
#     maximised log-likelihood is generically >= Julia's even with a correct fit on
#     both sides.
#   · Dispersion PARAMETERISATION: the twin's `phi_gamma_delta` is the **CV** of the
#     positive part (`shape_g = 1/phi^2`, `scale_g = mu/shape_g`,
#     `gllvmTMB.cpp:2836-2841`), NOT the shape. Julia's `α` field IS the shape
#     (`Distributions.Gamma(α, μ/α)`, `Var = μ²/α`). Map before comparing:
#     `α ≈ 1/phi^2` (equivalently `phi ≈ 1/sqrt(α)`) — this file converts both ways.
#   · Hessian: DeltaGamma is the ONE two-part family with a specialised OBSERVED
#     count-part weight (`_tp_observed_Wc`), so `hessian = :observed` (the default on
#     both call sites here) is genuinely a different objective from `:fisher` for
#     this family — verified to differ by `test_delta_shared_predictor.jl` item 5.
#     Both R and Julia use TMB's / Julia's respective observed joint Hessian by
#     default, so this is like-for-like, not a candidate mismatch.
#
# Twin Δ rule: no number is quoted unless this cell runs live under
# GLLVM_PARITY_TESTS=1 against a real gllvmTMB. Never invent, never carry over.

using GLLVM, RCall, Test, Random
import Distributions

# parity_helpers.jl is included once by runparity.jl

# Seed pre-registered BEFORE any run (42–49, 52–58, 61, 420–431 already taken).
const _DG_SEED = 62

@testset "delta_gamma GLLVM parity: GLLVM.jl vs gllvmTMB (twin fid 13, shared predictor)" begin

    Random.seed!(_DG_SEED)
    p, K, n = 5, 1, 130
    β_true = [0.2, -0.1, 0.3, 0.0, -0.2]
    Λ_true = 0.5 .* parity_loadings_p5k2()[:, 1:K]
    α_true = 4.0                       # shape; twin CV phi_true = 1/sqrt(4) = 0.5

    Z = randn(K, n)
    η = β_true .+ Λ_true * Z          # p×n, ONE shared predictor
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        π = 1 / (1 + exp(-η[t, s]))
        if rand() < π
            μ = exp(η[t, s])
            Y[t, s] = rand(Distributions.Gamma(α_true, μ / α_true))
        end
    end

    @testset "DGP sanity: every trait has both zero and positive cells" begin
        for t in 1:p
            @test any(==(0.0), view(Y, t, :))
            @test any(>(0.0), view(Y, t, :))
        end
    end

    jl_fit = fit_delta_gamma_gllvm(Y; K = K, predictor = :shared)
    @test jl_fit.converged
    @test isfinite(jl_fit.loglik)
    @test jl_fit.predictor === :shared
    @test jl_fit.βz == jl_fit.βc   # the tie is real
    jl_logL = jl_fit.loglik

    r = fit_gllvmtmb_parity_delta(Y, K; family = :delta_gamma)
    @test r.converged
    @test isfinite(r.logLik)

    print_parity_loglik(
        "delta_gamma logLik oracle (seed=$(_DG_SEED), p=$p, K=$K, n=$n, " *
        "shared predictor; twin fid 13)";
        jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
    )

    r_shape_vec = 1.0 ./ (r.disp_vec .^ 2)   # twin CV -> shape, for like-for-like print
    println("  Julia β  (shared, single α=$(round(jl_fit.α; sigdigits=4))) = ",
            round.(jl_fit.βc; sigdigits = 5))
    println("  gllvmTMB b_fix (per-trait shape) = ", round.(r.b_fix; sigdigits = 5))
    println("  gllvmTMB per-trait CV phi        = ", round.(r.disp_vec; sigdigits = 5))
    println("  gllvmTMB per-trait shape (1/phi²)= ", round.(r_shape_vec; sigdigits = 5))
    println("  spread of twin per-trait shape (max−min) = ",
            round(maximum(r_shape_vec) - minimum(r_shape_vec); sigdigits = 4))
    println()

    @testset "log-likelihood agreement (rtol=1e-6; irreducible per-trait-vs-shared-α Δ expected)" begin
        # NOT asserted at rtol=1e-6 — see file header. The twin's extra p−1 free
        # dispersion parameters generically make r.logLik >= jl_logL under a
        # shared-dispersion DGP; report the actual numbers instead of a pass/fail
        # gate here.
        @test r.logLik >= jl_logL - 1e-6   # twin should never do WORSE than Julia
        @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
    end
end
