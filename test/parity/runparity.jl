#!/usr/bin/env julia
# runparity.jl — opt-in runner for the GLLVM.jl ↔ R gllvmTMB parity suite.
#
# Usage:
#   GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
#
# This file is the ONLY entry-point. It is not included by runtests.jl and
# is never invoked by the default CI pipeline. Running it without the env
# variable set is intentionally harmless (exits 0 with a skip notice).

println("=" ^ 72)
println("GLLVM.jl ↔ R gllvmTMB parity suite (Phase 1.0 scaffold)")
println("=" ^ 72)

# ── Gate: must opt in explicitly ────────────────────────────────────────────
if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
    println()
    println("SKIPPED — parity suite is opt-in.")
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
# GLLVM is declared in test/parity/Project.toml [deps]; this dev-add points the
# (gitignored) Manifest at THIS working tree — the path is what actually varies
# across machines and worktrees, not the UUID. Because the [deps] entry already
# exists, Pkg has nothing to change in Project.toml and does not rewrite it, which
# is what keeps that file's explanatory comments alive. Before 2026-08-24 the entry
# was absent, so every run rewrote Project.toml, deleted its comment block, and left
# the tracked file dirty.
using Pkg
Pkg.develop(path = normpath(joinpath(@__DIR__, "..", "..")))

# ── Try to load RCall — bail gracefully if R is not set up ───────────────────
try
    using RCall
catch err
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
include(joinpath(@__DIR__, "test_gaussian_parity.jl"))
include(joinpath(@__DIR__, "test_binomial_parity.jl"))
include(joinpath(@__DIR__, "test_poisson_parity.jl"))
include(joinpath(@__DIR__, "test_negbin_parity.jl"))
include(joinpath(@__DIR__, "test_beta_parity.jl"))
include(joinpath(@__DIR__, "test_ordinal_probit_parity.jl"))
include(joinpath(@__DIR__, "test_lognormal_parity.jl"))
include(joinpath(@__DIR__, "test_truncated_poisson_parity.jl"))
# Rung A (2026-08-24): no-X arms for the three per-trait-dispersion families that
# previously had twin Δ evidence only through the +X cohort — Gamma (fid 4),
# NB1 (fid 15), BetaBinomial (fid 8). Grouped fitters, never shared-dispersion.
include(joinpath(@__DIR__, "test_nox_dispersion_parity.jl"))
# Multinomial (twin fid 16) uses its OWN oracle helper: categorical factor response
# and no latent(...) term (Julia v1 is fixed-effects softmax only). Not a clone of the
# shared numeric-matrix shape.
include(joinpath(@__DIR__, "test_multinomial_parity.jl"))
# truncated_nbinom2 (twin fid 11): per-trait dispersion, and REQUIRES the observed
# Laplace curvature (hessian=:observed, the default since 2026-08-24) — the NB2
# curvature is y-dependent, so the Fisher weight is a different objective from TMB.
include(joinpath(@__DIR__, "test_truncated_nbinom2_parity.jl"))
include(joinpath(@__DIR__, "test_x_covariate_parity.jl"))
include(joinpath(@__DIR__, "test_species_x_parity.jl"))
# delta_lognormal / delta_gamma (twin fid 12/13): pair ONLY with Julia's
# `predictor = :shared` mode (2026-08-28 twin-identity kwarg) — the twin ties ONE
# linear predictor across occurrence and the positive part. Twin dispersion is
# PER-TRAIT (no shared/pinned mode exposed via the family constructor); Julia's
# fitters estimate a single shared scalar σ/α, an irreducible parameterisation
# mismatch reported alongside the Δ, not tolerance-widened away.
include(joinpath(@__DIR__, "test_delta_lognormal_parity.jl"))
include(joinpath(@__DIR__, "test_delta_gamma_parity.jl"))
# Student-t (twin fid 9): same per-trait-dispersion identity as the delta
# cells above. Both sides pin df = ν_true (Julia always fixes ν; the twin's
# own default is to estimate it per trait, a different model — see the file
# header). disp_group = :species (2026-08-28) closes the shared-σ mismatch.
include(joinpath(@__DIR__, "test_studentt_parity.jl"))
