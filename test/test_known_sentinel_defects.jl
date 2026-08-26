# Executable records of two DEMONSTRATED, user-facing defects of the same shape:
# a failure path that returns the repo-wide `1e12` sentinel instead of failing loudly,
# so downstream code reads catastrophe as success.
#
# These are `@test_broken`, not `@test`. They document current behaviour and will ERROR
# the moment the behaviour is fixed, forcing whoever fixes it to come back here and
# promote the assertion. That is the opposite of a silent allowlist: it is a marker that
# invalidates itself.
#
# Both were reproduced on live fits in this worktree on 2026-08-26. Neither is a
# hypothetical. The correct pattern already exists in the package — `_tweedie_verdict`
# (`src/families/tweedie.jl:186-198`) names this exact mechanism and forces `-Inf` — but
# it is called at only two sites.

# NOTE ON QUALIFICATION: every GLLVM call below is written `GLLVM.f(...)` deliberately.
# Two test files (`test_confint_bootstrap.jl:19`, `test_confint_derived.jl:7,10,130`)
# `include` package sources DIRECTLY into the test module, which defines duplicate types
# alongside the package's own. An unqualified call in a later file can then bind to the
# duplicate, and `fit_phylo_gaussian(::AugmentedPhy{Float64}, ...)` fails with a
# MethodError whose candidate list shows `!Matched::GLLVM.AugmentedPhy` — two types, one
# name. This file hit exactly that: green standalone, MethodError under `Pkg.test()`.
# `test_edge_incidence.jl:157` and `test_em_louis.jl:32` already qualify for the same
# reason. See the check-log entry for 2026-08-26.

using GLLVM, Test

@testset "Known sentinel defects (documented, not fixed)" begin

    @testset "fit_phylo_gaussian reports converged=true on a degenerate response" begin
        # A constant response makes `log(var(y)/2) = -Inf`, which trips the
        # `all(isfinite, θ)` guard at src/fit_phylo.jl:121. The objective then returns
        # the flat `_PHYLO_PENALTY = 1e12` plateau, the finite-difference gradient over a
        # constant is exactly 0, and Optim declares `g_converged` at iteration 0.
        phy = GLLVM.augmented_phy("(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,(E:0.2,F:0.2):0.1);")
        f = GLLVM.fit_phylo_gaussian(phy, fill(3.0, 6))

        # Current behaviour, verified:
        @test f.negll == 1.0e12          # the failure sentinel, returned as a log-likelihood
        @test isnan(f.μ)                 # the fit contains NaN
        @test f.iterations == 0          # it never moved

        # What SHOULD hold. Fixing the cause makes these pass and the @test_broken error.
        @test_broken !f.converged

        # Why it matters downstream: a finite 1e12 flows into information criteria, and
        # `select_lv`'s guard is a try/catch (src/model_selection.jl:69-80) which cannot
        # see a failure that does not throw.
        @test isfinite(f.negll)          # ← precisely the problem
    end

    @testset "Wald SE collapses when _fd_hessian differences the sentinel" begin
        # α̂ sits ~0.05·h from the GP-1 domain edge (α is packed raw,
        # src/confint_family.jl:225; h = eps()^(1/4) ≈ 1.22e-4), so stencil arms fall
        # outside the domain and return the sentinel. Enormous apparent curvature ⇒
        # vanishing SE. The failure direction is toward FALSE CERTAINTY.
        Y = fill(600, 40, 5)
        f = GLLVM.fit_gp1_gllvm(Y; K = 1)
        ci = GLLVM.confint(f, Y; method = :wald)
        i = findfirst(t -> lowercase(string(t)) == "alpha", string.(ci.term))
        @test i !== nothing

        if i !== nothing
            # Current behaviour, verified: SE seven orders of magnitude below |α̂|.
            @test ci.se[i] < 1e-8
            @test abs(ci.estimate[i]) > 1e-4

            # What SHOULD hold: an SE cannot be ~7e-8 times its own estimate. A sane
            # SE is at least a thousandth of the point estimate for a parameter this
            # weakly identified; the reported one is seven orders below that.
            @test_broken ci.se[i] > 1e-3 * abs(ci.estimate[i])
        end
    end
end
