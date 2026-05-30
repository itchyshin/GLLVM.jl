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
# dev-add at runtime so GLLVM is not listed in [deps] here (which would force
# a UUID that may not match across machines / worktrees).
using Pkg
Pkg.develop(path = joinpath(@__DIR__, "..", ".."))

# ── Try to load RCall — bail gracefully if R is not set up ───────────────────
try
    using RCall
catch err
    println()
    println("SKIPPED — RCall or R not available.")
    println("  Error: ", err)
    println()
    println("  Install R and the gllvmTMB package, then rebuild RCall:")
    println("    julia --project=test/parity -e 'using Pkg; Pkg.build(\"RCall\")'")
    println()
    exit(0)
end

# ── Run the parity tests ──────────────────────────────────────────────────────
include(joinpath(@__DIR__, "test_gaussian_parity.jl"))
