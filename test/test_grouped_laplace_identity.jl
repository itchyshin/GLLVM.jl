# test/test_grouped_laplace_identity.jl — leaf-S7b identity gate (G7b.1).
#
# Written BEFORE the CHOLMOD symbolic-reuse change lands in the grouped
# Laplace kernel (`joint_grouped_laplace_loglik`, src/grouped_laplace.jl —
# NOTE: the leaf-S7b ledger and lane arcs.md both name this file as
# `src/families/grouped_laplace.jl`; that path does not exist in this repo,
# the real file is `src/grouped_laplace.jl` (`include`d at
# src/GLLVModels.jl:114) — flagged, not silently corrected).
#
# TDD contract: the IDENTITY assertions below pin baseline numbers captured
# from the UNMODIFIED code (origin/main 69a69b0a0, before ANY change in this
# arc) and must hold both BEFORE and AFTER the reuse change — a pure
# performance optimisation must not move the fitted answer by more than
# floating-point noise. The COUNTER assertions read
# `GLLVModels._grouped_chol_stats()` (added by the change) and are EXPECTED
# TO FAIL on the unmodified baseline (the accessor does not exist yet) and
# PASS once the reuse lands. If this test ever needs a baseline number
# changed, the cause must be a genuine numerical fix, never drift introduced
# by the reuse change — re-derive on origin/main by hand, never copy the
# post-fix value back in.
#
# Runnable two ways:
#   - `include`d from test/runtests.jl as a normal @testset
#   - `julia --project=. test/test_grouped_laplace_identity.jl --gate identity`
#     (prints "GATE G7b.1 PASS" / "GATE G7b.1 FAIL <reason>", exit 0/1)

using Test, GLLVModels, DelimitedFiles, SparseArrays, LinearAlgebra
using Distributions: Poisson

const _RESULTS = Bool[]
const _REASONS = String[]

function _check!(ok::Bool, msg::AbstractString)
    push!(_RESULTS, ok)
    ok || push!(_REASONS, msg)
    @test ok
    return ok
end

# ---------------------------------------------------------------------------
# Baseline constants — captured 2026-09-19 on origin/main 69a69b0a0 (before
# any change in this arc), via exactly the calls in `fixture_a`/`fixture_b`
# below. See bench/results/grouped_glmm_d56bccea4.tsv (leaf-S4) for the
# obj_calls / inner_newton_iters_sum / fresh_cholmod_analyses provenance.
# ---------------------------------------------------------------------------

# --- fixture A: the Latte 200x5 GLMM (bench/fixtures/glmm_200x5.csv), fitted
# exactly as bench/profile_grouped_glmm.jl / f3_ours_glmm.jl does. ---
const BASELINE_A_CONVERGED = true
const BASELINE_A_ITERATIONS = 3               # outer Optim iterations
const BASELINE_A_LOGLIK = -2025.469254255527403
const BASELINE_A_PARAMETERS = [0.9211786339273272, -0.3668330777412767]
# calls/fresh below are measured DIRECTLY on the real joint_grouped_laplace_
# loglik call path (via the _GROUPED_CHOL_STATS counter added by this arc,
# with the reuse branch temporarily forced off to reproduce pre-fix
# behaviour) -- NOT the S4 shadow-replica's counts (103 calls / 1345 fresh),
# which turned out to under-count slightly: the shadow driver in
# bench/profile_grouped_glmm.jl reaches the identical converged loglik but is
# not a bit-for-bit reimplementation of fit_grouped_nongaussian's optimiser
# calls, so its call count is a good order-of-magnitude estimate, not a
# pinnable identity. 118/1540 are the true, verified pre-fix numbers.
const BASELINE_A_OBJ_CALLS = 118              # true inner Laplace-fit call count
const BASELINE_A_INNER_ITERS_SUM = 711        # = (1540 - 118) / 2
const BASELINE_A_FRESH_CHOLESKY = 1540        # true pre-fix fresh cholesky() call count

# --- fixture B: "crossed incidence" (test/test_grouped_laplace.jl), a direct
# joint_grouped_laplace_loglik call with m=2 unknowns (Newton actually
# iterates, unlike the m<=1 cases in that file). ---
const BASELINE_B_STATUS = :ok
const BASELINE_B_CONVERGED = true
const BASELINE_B_ITERATIONS = 4
const BASELINE_B_LOGLIK = -6.419975970680682
const BASELINE_B_MODE = [0.5103459578769107, -0.0535798048824418]
const BASELINE_B_LOGDET = 3.56577252913429

function fixture_a()
    path = joinpath(@__DIR__, "..", "bench", "fixtures", "glmm_200x5.csv")
    isfile(path) || error("fixture missing: $path")
    M = readdlm(path, ',', Int)
    y = M[:, 1]; group = M[:, 2]
    Y1 = reshape(Float64.(y), 1, :)
    terms = [GLLVModels.GroupingTerm(:unit; mode = :indep)]
    return Y1, terms, group
end

function fixture_b()
    A = sparse([1.0 1.0; 1.0 0.0; 0.0 1.0])
    W = GLLVModels.grouped_trait_design(A, ones(1, 1))
    return Poisson(), [3.0, 4.0, 2.0], ones(3), ones(3, 1), [log(2.0)], W
end

function run_identity_checks()
    empty!(_RESULTS); empty!(_REASONS)

    # ---- fixture A: full grouped fit, identity vs baseline ----
    Y1, terms, group = fixture_a()
    fit = GLLVModels.fit_gllvm(Y1; family = Poisson(), grouping = terms, unit = group)
    _check!(fit.converged == BASELINE_A_CONVERGED, "fixture A: converged mismatch")
    _check!(fit.iterations == BASELINE_A_ITERATIONS,
            "fixture A: outer iterations mismatch ($(fit.iterations) vs $(BASELINE_A_ITERATIONS))")
    _check!(isapprox(fit.loglik, BASELINE_A_LOGLIK; rtol = 1e-8),
            "fixture A: loglik mismatch ($(fit.loglik) vs $(BASELINE_A_LOGLIK))")
    _check!(isapprox(fit.parameters, BASELINE_A_PARAMETERS; rtol = 1e-8),
            "fixture A: parameters mismatch ($(fit.parameters) vs $(BASELINE_A_PARAMETERS))")

    # ---- fixture B: direct joint_grouped_laplace_loglik call, identity vs baseline ----
    r = GLLVModels.joint_grouped_laplace_loglik(fixture_b()...; link = GLLVModels.LogLink())
    _check!(r.status === BASELINE_B_STATUS, "fixture B: status mismatch ($(r.status))")
    _check!(r.converged == BASELINE_B_CONVERGED, "fixture B: converged mismatch")
    _check!(r.iterations == BASELINE_B_ITERATIONS,
            "fixture B: iterations mismatch ($(r.iterations) vs $(BASELINE_B_ITERATIONS))")
    _check!(isapprox(r.loglik, BASELINE_B_LOGLIK; rtol = 1e-8), "fixture B: loglik mismatch")
    _check!(isapprox(r.mode, BASELINE_B_MODE; rtol = 1e-8), "fixture B: mode mismatch")
    _check!(isapprox(r.logdet_precision, BASELINE_B_LOGDET; rtol = 1e-8), "fixture B: logdet mismatch")

    # ---- NEW counter assertions: fresh CHOLMOD symbolic analyses 2 -> 0
    # after the first, per inner Laplace-fit call. Not present pre-fix. ----
    has_stats = isdefined(GLLVModels, :_grouped_chol_stats_reset!) &&
                isdefined(GLLVModels, :_grouped_chol_stats)
    if !has_stats
        _check!(false, "GLLVModels._grouped_chol_stats[_reset!] not defined — " *
                       "the CHOLMOD symbolic-reuse change has not landed yet")
    else
        GLLVModels._grouped_chol_stats_reset!()
        GLLVModels.fit_gllvm(Y1; family = Poisson(), grouping = terms, unit = group)
        stats = GLLVModels._grouped_chol_stats()
        _check!(stats.calls == BASELINE_A_OBJ_CALLS,
                "fixture A: inner Laplace-fit call count changed ($(stats.calls) vs $(BASELINE_A_OBJ_CALLS)) — the reuse must not change the optimiser's path")
        _check!(stats.fallback == 0,
                "fixture A: $(stats.fallback) fresh-cholesky fallbacks (pattern mismatch), expected 0")
        _check!(stats.fresh == 2 * stats.calls,
                "fixture A: fresh=$(stats.fresh) != 2*calls=$(2 * stats.calls) — expected exactly 2 fresh symbolic analyses (Fisher + observed) per inner Laplace-fit call, 0 thereafter")
        _check!(stats.fresh < BASELINE_A_FRESH_CHOLESKY,
                "fixture A: fresh=$(stats.fresh) not below the pre-fix baseline $(BASELINE_A_FRESH_CHOLESKY)")

        GLLVModels._grouped_chol_stats_reset!()
        GLLVModels.joint_grouped_laplace_loglik(fixture_b()...; link = GLLVModels.LogLink())
        statsb = GLLVModels._grouped_chol_stats()
        _check!(statsb.calls == 1, "fixture B: call count mismatch ($(statsb.calls))")
        _check!(statsb.fallback == 0,
                "fixture B: $(statsb.fallback) fresh-cholesky fallbacks, expected 0")
        _check!(statsb.fresh == 2 * statsb.calls,
                "fixture B: fresh=$(statsb.fresh) != 2*calls=$(2 * statsb.calls)")
    end

    return all(_RESULTS), copy(_REASONS)
end

_GATE_OK = false
_GATE_REASONS = String[]

if abspath(PROGRAM_FILE) == @__FILE__
    # Standalone script mode: `@testset` throws at its `end` if any `@test`
    # inside failed (expected pre-fix — see the file header). Catch that so
    # the GATE line below still prints with the correct PASS/FAIL + reasons
    # and exit code; `run_identity_checks()` itself already ran to
    # completion by the time the testset finishes; nothing here is silently
    # swallowed for the runtests.jl path (that branch, below, does not catch).
    try
        @testset "grouped Laplace CHOLMOD reuse identity (S7b)" begin
            global _GATE_OK, _GATE_REASONS = run_identity_checks()
        end
    catch e
        @info "testset reported failures (expected pre-fix); continuing to the GATE line" exception = e
    end
    if _GATE_OK
        println("GATE G7b.1 PASS")
        exit(0)
    else
        println("GATE G7b.1 FAIL ", join(_GATE_REASONS, "; "))
        exit(1)
    end
else
    # Included from test/runtests.jl: let a genuine failure propagate
    # normally so the overall suite correctly reports it.
    @testset "grouped Laplace CHOLMOD reuse identity (S7b)" begin
        global _GATE_OK, _GATE_REASONS = run_identity_checks()
    end
end
