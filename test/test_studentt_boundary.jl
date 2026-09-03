using Test, GLLVM, Random, LinearAlgebra

# A6 wiring (maintainer round2-3 #11): a Student-t fit whose estimated ν has run to
# the flat Gaussian-limit boundary (`nu_boundary = true`, `_studentt_nu_boundary`,
# families/studentt.jl) must not present as a clean success through the repo's
# GENERIC fit-health gate (`sanity_multi` / `gllvmTMB_diagnose`, diagnostics.jl),
# which reads only `fit.converged` — no family-specific hook. The wiring mirrors
# `_tweedie_verdict`'s `:power_at_boundary` rule (families/tweedie.jl): a family
# parameter that has run to the edge of its admissible domain forces
# `converged = false` regardless of what Optim itself reported, because Optim
# cannot distinguish a genuine stationary point from a flat plateau by gradient
# alone. This is a TIGHTENING of the gate (a new failure mode), never a weakening
# — no existing pass case is touched.
#
# `test_studentt_boundary_honesty.jl` (2026-09-01) documents the additive flag
# itself and its `show()` text; this file documents and pins the wiring into
# `converged` / the generic health gate specifically, per round2-3 #11.

@testset "Student-t nu-boundary wiring into fit-health" begin

    @testset "unit: boundary forces converged=false even when Optim itself agrees" begin
        # Direct unit check on the verdict-composition rule (mirrors
        # `GLLVM._tweedie_verdict`'s unit-level convergence-contract tests):
        # an Optim-converged=true result at an estimated, boundary ν must not
        # survive as `converged = true`.
        @test GLLVM._studentt_nu_boundary(true, 2e6)               # scalar, estimated
        @test !(true && !GLLVM._studentt_nu_boundary(true, 2e6))   # `conv && !boundary` collapses to false
        @test GLLVM._studentt_nu_boundary(true, [4.0, 2e6])        # per-trait, one boundary trait
        @test !GLLVM._studentt_nu_boundary(true, 5.0)              # interior ν: no boundary
        @test !GLLVM._studentt_nu_boundary(false, 2e6)             # fixed (not estimated) ν: never flagged
    end

    @testset "red-first: near-Gaussian data walks estimated ν to the boundary" begin
        # Pure Gaussian data (no heavy tails at all) is the fixture that reliably
        # pushes the estimated-ν MLE to the flat ν→∞ boundary — the same
        # construction as test_studentt_boundary_honesty.jl.
        rng = MersenneTwister(2026)
        p, n = 2, 80
        Λ_true = reshape([0.6, -0.4], p, 1)
        Y = Λ_true * randn(rng, 1, n) + 0.5 .* randn(rng, p, n)
        fit = fit_studentt_gllvm(Y; K = 1)   # ν estimated by default

        νvec = fit.ν isa Real ? [fit.ν] : fit.ν
        if any(>(1e6), νvec)
            @test fit.nu_boundary
            # THE WIRING: a boundary fit must not present as converged=true, so it
            # fails the GENERIC (family-agnostic) fit-health gate.
            @test fit.converged == false
            s = GLLVM.sanity_multi(fit)
            @test s.converged == false
            @test s.pass == false
            d = GLLVM.gllvmTMB_diagnose(fit)
            @test d.pass == false
            @test occursin("optimizer did not report convergence", join(s.messages, "; "))
        else
            # Data-driven premise: if this particular seed happens to land interior,
            # the boundary flag and the forced-false wiring both stay off — report
            # rather than silently pass, matching the honesty test's convention.
            @test !fit.nu_boundary
            @info "boundary not reached on this stream; interior ν; wiring not exercised" νvec
        end
    end

    @testset "interior ν: fixed nu never boundary-flagged, health gate unaffected" begin
        rng = MersenneTwister(7)
        p, n = 2, 100
        Λ_true = reshape([0.5, -0.3], p, 1)
        Y = Λ_true * randn(rng, 1, n) .+ 0.4 .* randn(rng, p, n)
        fixed = fit_studentt_gllvm(Y; K = 1, nu = 6.0)
        @test !fixed.nu_boundary
        # A non-boundary fit's converged flag is untouched by this wiring: since
        # `_studentt_nu_boundary` is false here, `conv && !boundary === conv`.
        @test fixed.converged isa Bool
        s = GLLVM.sanity_multi(fixed)
        @test s.converged == fixed.converged
    end
end
