#!/usr/bin/env julia
# runparity.jl — developer-opt-in / CI-required runner for GLLVM.jl ↔ R gllvmTMB parity.
#
# Usage:
#   GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
#
# This file is the ONLY entry-point. It is not included by runtests.jl. CI
# invokes it in required mode; a local developer run without its opt-in variable
# is intentionally harmless and cannot satisfy the required evidence gate.

println("=" ^ 72)
println("GLLVM.jl ↔ R gllvmTMB parity suite (Phase 1.0 scaffold)")
println("=" ^ 72)

# ── Gate: optional developer mode vs fail-closed required evidence ──────────
requested = get(ENV, "GLLVM_PARITY_TESTS", "0") == "1"
required = get(ENV, "CORE070_PARITY_REQUIRED", "0") == "1"
if required && !requested
    error("CORE070_PARITY_REQUIRED=1 requires GLLVM_PARITY_TESTS=1; an optional skip cannot satisfy required evidence")
end
if !requested
    println()
    println("SKIPPED — optional developer parity was not requested.")
    println()
    println("  To run: set GLLVM_PARITY_TESTS=1 and ensure R + gllvmTMB")
    println("  are installed, then:")
    println()
    println("    GLLVM_PARITY_TESTS=1 \\")
    println("      julia --project=test/parity test/parity/runparity.jl")
    println()
    exit(0)
end

# ── Wire the local GLLVM package ─────────────────────────────────────────────
# In CI or isolated runner, develop GLLVM if not already pointing to root
using Pkg

# ── Try to load RCall — optional skip only; required mode fails ──────────────
try
    @info "Loading RCall..."
    @info "R_HOME in Julia: " * get(ENV, "R_HOME", "<unset>")
    @eval using RCall
    @info "RCall loaded successfully."
catch err
    required && error("CORE070_REQUIRED_DEPENDENCY_ERROR: RCall/R is unavailable\n" *
                      sprint(showerror, err, catch_backtrace()))
    println()
    println("SKIPPED — RCall or R not available.")
    println("  Error: ", sprint(showerror, err, catch_backtrace()))
    println()
    println("  Install R and the gllvmTMB package, then rebuild RCall:")
    println("    julia --project=test/parity -e 'using Pkg; Pkg.build(\"RCall\")'")
    println()
    exit(0)
end

# ── Run the parity tests ──────────────────────────────────────────────────────
# Order locked by catch-up arc: Gaussian → Binomial → Poisson → NB2 → Beta →
# Ordinal-probit, then the 2026-08-24 no-X catch-up cells (lognormal fid 3,
# truncated_poisson fid 10), then shared site-X cohort (G/Bin/Pois + NB2/Beta/Gamma +
# Ordinal-probit). Light logLik oracles: NB2/Beta/Gamma via grouped-cov +
# per-trait dispersion; Ordinal+X via fit_ordinal_gllvm_pertrait_cov +
# ProbitLink. X cells use shared γ only.
# lognormal is the one no-X family pairing with a SHARED-scalar σ fitter (twin ties
# sigma_eps), and its logLik carries the −Σ log y Jacobian on both sides.
# Do not narrate as “full family parity” (named shared-φ / logit ordinal differ).
include(joinpath(@__DIR__, "parity_helpers.jl"))
core070_start_run!()
include(joinpath(@__DIR__, "test_gaussian_parity.jl"))
core070_record_cell!("NATIVE-01-GAUSSIAN", "test/parity/test_gaussian_parity.jl")
include(joinpath(@__DIR__, "test_binomial_parity.jl"))
core070_record_cell!("NATIVE-02-BINOMIAL", "test/parity/test_binomial_parity.jl")
include(joinpath(@__DIR__, "test_poisson_parity.jl"))
core070_record_cell!("NATIVE-03-POISSON", "test/parity/test_poisson_parity.jl")
include(joinpath(@__DIR__, "test_negbin_parity.jl"))
core070_record_cell!("NATIVE-06-NB2", "test/parity/test_negbin_parity.jl")
include(joinpath(@__DIR__, "test_beta_parity.jl"))
core070_record_cell!("NATIVE-08-BETA", "test/parity/test_beta_parity.jl")
include(joinpath(@__DIR__, "test_ordinal_probit_parity.jl"))
core070_record_cell!("NATIVE-15-ORDINAL-PROBIT", "test/parity/test_ordinal_probit_parity.jl")
include(joinpath(@__DIR__, "test_lognormal_parity.jl"))
core070_record_cell!("NATIVE-04-LOGNORMAL", "test/parity/test_lognormal_parity.jl")
include(joinpath(@__DIR__, "test_truncated_poisson_parity.jl"))
core070_record_cell!("NATIVE-11-TRUNCATED-POISSON", "test/parity/test_truncated_poisson_parity.jl")
# Rung A (2026-08-24): no-X arms for the three per-trait-dispersion families that
# previously had twin Δ evidence only through the +X cohort — Gamma (fid 4),
# NB1 (fid 15), BetaBinomial (fid 8). Grouped fitters, never shared-dispersion.
include(joinpath(@__DIR__, "test_nox_dispersion_parity.jl"))
core070_record_cell!("NATIVE-05-GAMMA", "test/parity/test_nox_dispersion_parity.jl")
core070_record_cell!("NATIVE-16-NB1", "test/parity/test_nox_dispersion_parity.jl")
core070_record_cell!("NATIVE-09-BETABINOMIAL", "test/parity/test_nox_dispersion_parity.jl")
# Multinomial (twin fid 16) uses its OWN oracle helper: categorical factor response
# and no latent(...) term (Julia v1 is fixed-effects softmax only). Not a clone of the
# shared numeric-matrix shape.
include(joinpath(@__DIR__, "test_multinomial_parity.jl"))
core070_record_cell!("NATIVE-17-MULTINOMIAL-FIXED", "test/parity/test_multinomial_parity.jl")
# truncated_nbinom2 (twin fid 11): per-trait dispersion, and REQUIRES the observed
# Laplace curvature (hessian=:observed, the default since 2026-08-24) — the NB2
# curvature is y-dependent, so the Fisher weight is a different objective from TMB.
include(joinpath(@__DIR__, "test_truncated_nbinom2_parity.jl"))
core070_record_cell!("NATIVE-12-TRUNCATED-NB2", "test/parity/test_truncated_nbinom2_parity.jl")
include(joinpath(@__DIR__, "test_x_covariate_parity.jl"))
include(joinpath(@__DIR__, "test_species_x_parity.jl"))
# delta_lognormal / delta_gamma (twin fid 12/13): the fixture pins the shared
# predictor identity. Both Julia delta fitters now expose `disp_group`; this
# record therefore binds only the fixture's selected grouping rather than
# describing grouped-dispersion support as unavailable.
include(joinpath(@__DIR__, "test_delta_lognormal_parity.jl"))
core070_record_cell!("NATIVE-13-DELTA-LOGNORMAL", "test/parity/test_delta_lognormal_parity.jl")
include(joinpath(@__DIR__, "test_delta_gamma_parity.jl"))
core070_record_cell!("NATIVE-14-DELTA-GAMMA", "test/parity/test_delta_gamma_parity.jl")
# Student-t (twin fid 9): preserve the original estimated-ν, per-trait-scale
# target and its absolute likelihood plus both-engine health gates. The fixed-ν
# control and interior/near-Gaussian diagnostics do not replace that target.
include(joinpath(@__DIR__, "test_studentt_parity.jl"))
core070_record_cell!("NATIVE-10-STUDENT", "test/parity/test_studentt_parity.jl")
# Tweedie (twin fid 6): compound Poisson–Gamma with power p ∈ (1, 2)
# and per-trait dispersion φ.
include(joinpath(@__DIR__, "test_tweedie_parity.jl"))
core070_record_cell!("NATIVE-07-TWEEDIE", "test/parity/test_tweedie_parity.jl")
core070_finish_run!()
