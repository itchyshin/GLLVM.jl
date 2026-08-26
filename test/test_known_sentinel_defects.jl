# Records of DEMONSTRATED, user-facing defects of one shape:
# a failure path that returns the repo-wide `1e12` sentinel instead of failing loudly,
# so downstream code reads catastrophe as success.
#
# UPDATE 2026-08-26: the two sentinel defects are now FIXED, and this file records the
# corrected behaviour as ordinary `@test`. The mechanism worked exactly as intended — the
# `@test_broken` markers errored as "Unexpected Pass" the moment the fixes landed, which
# is what forced these assertions to be promoted rather than quietly left behind. The
# wrong-sign σ_phy defect below is NOT fixed and remains `@test_broken`.
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

using GLLVM, Test, Random, LinearAlgebra

@testset "Sentinel defects: two FIXED, one still open" begin

    @testset "signed σ_phy: dense fitter recovers a wrong-SIGN component" begin
        # Reproduced 2026-08-26. `fit_gaussian_gllvm(...; has_phy_unique = true)` reaches a
        # sign-flipped optimum on the seed-30 fixture that `test_em_phylo.jl` uses:
        #   truth      [0.9, 0.9, 0.9, 0.9, 0.9, 0.9]
        #   recovered  [-0.3231, 0.551, 0.3599, 0.3469, 0.7767, 1.6176]
        # converged = true, logLik = -2184.19. Component 1 has the wrong sign.
        #
        # WHY NOTHING CATCHES IT. The wired guard at test_signed_sigma_phy.jl:110 is
        # `@test all(abs.(σ_phy) .> 0.3)` — the ABSOLUTE value, so it structurally cannot
        # see a sign flip, and it passes here by 0.023. Its own comment (`:101-103`) claims
        # "all signs equal up to the global anchor", asserting what it does not test. The
        # anchor check inspects only the largest-magnitude entry, which is positive.
        # `test_em_phylo.jl`, which compares against EM and would have caught it, is not
        # wired into runtests.jl and never has been.
        function _sim(tree, Λ_B, σ_phy, σ_eps, n; seed)
            Random.seed!(seed)
            Σ_phy = GLLVM.sigma_phy_dense(tree; σ²_phy = 1.0)
            p, K_B = size(Λ_B)
            η_B = randn(K_B, n)
            φ = cholesky(Symmetric(Σ_phy)).L * randn(p)
            y = Λ_B * η_B .+ reshape(σ_phy .* φ, p, 1) .+ σ_eps .* randn(p, n)
            return y, Σ_phy
        end
        tree = GLLVM.augmented_phy("(((A:0.3,B:0.3):0.2,(C:0.3,D:0.3):0.2):0.2,(E:0.4,F:0.4):0.2);")
        pp = tree.n_leaves
        Λ_B = reshape([0.8, 0.6, 0.4, -0.3, 0.5, -0.2], pp, 1)
        y, Σ = _sim(tree, Λ_B, fill(0.9, pp), 0.5, 400; seed = 30)
        fit = GLLVM.fit_gaussian_gllvm(y; K = 1, has_phy_unique = true, Σ_phy = Σ)

        # Current behaviour, verified:
        @test fit.converged
        @test count(<(0), fit.pars.σ_phy) == 1       # one wrong-sign component

        # What SHOULD hold: every component shares the sign of the anchor, since the truth
        # is all-positive and only a GLOBAL sign flip is unidentified.
        anchor = sign(fit.pars.σ_phy[argmax(abs.(fit.pars.σ_phy))])
        @test_broken all(sign.(fit.pars.σ_phy) .== anchor)
    end

    @testset "fit_phylo_gaussian reports converged=true on a degenerate response" begin
        # A constant response makes `log(var(y)/2) = -Inf`, which trips the
        # `all(isfinite, θ)` guard at src/fit_phylo.jl:121. The objective then returns
        # the flat `_PHYLO_PENALTY = 1e12` plateau, the finite-difference gradient over a
        # constant is exactly 0, and Optim declares `g_converged` at iteration 0.
        phy = GLLVM.augmented_phy("(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,(E:0.2,F:0.2):0.1);")
        f = GLLVM.fit_phylo_gaussian(phy, fill(3.0, 6))

        # FIXED 2026-08-26 by `_phylo_verdict` (src/fit_phylo.jl:92), which mirrors
        # `_tweedie_verdict`: a run that ends on the penalty plateau did not converge, and
        # the sentinel is never reported as a log-likelihood.
        @test !f.converged               # was `true` — the defect
        @test f.negll == Inf             # was 1.0e12, a finite value that flowed into aic/bic
        @test !isfinite(f.negll)         # so `select_lv`'s finite-check can now see it
        @test f.iterations == 0          # unchanged: it genuinely never moved
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
            # FIXED 2026-08-26 by `_fd_failed` / `_FD_FAIL_THRESHOLD`
            # (src/confint_family.jl:1865). Stencil arms that hit a failure sentinel now
            # make the Hessian entry NaN, and `_family_wald` already reports NaN intervals
            # for a non-finite Hessian. "No interval" replaces a confidently wrong one.
            @test abs(ci.estimate[i]) > 1e-4        # the point estimate is unaffected
            @test isnan(ci.se[i])                   # was 1.22e-10 — false certainty
            @test isnan(ci.lower[i]) && isnan(ci.upper[i])
        end
    end
end
