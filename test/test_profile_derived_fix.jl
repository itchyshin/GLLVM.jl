# Regression tests for the profile_ci_derived bracket / penalty fix.
#
# Background
# ----------
# A coverage simulation found `profile_ci_derived` collapsing to
# near-zero-width intervals in phylogenetically-active cells (ρ coverage
# 0.00, c² coverage 0.17). Two interacting causes:
#
#   1. A fixed `penalty_weight = 1e6` instantly inflates the quadratic
#      penalty term at the warm-start θ̂ whenever c ≠ g(θ̂), driving
#      LBFGS into bad regions of θ-space from which it cannot recover.
#   2. As c moves away from g(θ̂) the constrained per-site Σ can drift
#      non-PD, where `gaussian_nll_packed` throws `PosDefException`
#      from its internal Cholesky. The optimiser then fails on the very
#      first expansion candidate, and the old bisection logic silently
#      collapsed to `(lo + hi)/2 ≈ x0`, producing a degenerate bound.
#
# Fix in src/confint_derived.jl
# -----------------------------
#   * `_derived_safe_nll` wrapper converts `PosDefException` / non-finite
#     NLL into a finite barrier.
#   * `_derived_refit_with_fixed` sweeps penalty weight w through an
#     escalating schedule (1e2 → … → `penalty_weight`), warm-starting
#     each stage from the previous minimiser.
#   * `_derived_bisect_side` rejects the "bracket on the first refit
#     failure with zero successful inner advances" case, returning NaN
#     so callers see this as a failure rather than a degenerate
#     near-x0 interval.
#
# This file verifies the fix on the same phylo cell that exposed the bug:
#   - The constrained refit at c slightly off g(θ̂) succeeds (no
#     PosDef-induced failure right next to x0).
#   - `profile_ci_derived` returns a NON-degenerate CI (width > 0.02)
#     for c²[t] and ρ[i,j] on a fitted phylo-block model.
#   - The CI contains the truth on the held-out replicate used here
#     (single-rep sanity — full coverage is checked separately in
#     bench/coverage_derived.jl).

using Test
using GLLVM
using Random
using LinearAlgebra

# `_make_correlation_closure` lives in confint_derived_wald.jl which is
# additive (not in the GLLVM precompiled module). Inject it once.
if !isdefined(GLLVM, :_make_correlation_closure)
    Base.include(GLLVM, joinpath(@__DIR__, "..", "src", "confint_derived_wald.jl"))
end

# Build the same fixture as bench/coverage_derived.jl phylo cell.
function _build_phylo_fixture()
    p, n, K = 6, 200, 1
    σ_eps = 0.5
    σ_phy = 0.8
    branch_length = 0.5

    rng0 = MersenneTwister(7_000 + p)
    Λ_B = reshape(0.4 .+ 0.4 .* abs.(randn(rng0, p)), p, K)
    Λ_B[2:2:end] .*= -1.0

    phy = GLLVM.random_balanced_tree(p; branch_length = branch_length)
    Σ_phy_raw = GLLVM.sigma_phy_dense(phy; σ²_phy = 1.0)
    Σ_phy = Matrix(Symmetric((Σ_phy_raw .+ Σ_phy_raw) ./ 2))
    L_phy = cholesky(Symmetric(Σ_phy)).L

    rng = MersenneTwister(500_002 * 2 + 6_000 + 1)
    y = Λ_B * randn(rng, K, n)
    φ = σ_phy .* (L_phy * randn(rng, p))
    for s in 1:n, t in 1:p
        y[t, s] += φ[t]
    end
    y .+= σ_eps .* randn(rng, p, n)

    Σ = Λ_B * Λ_B' + σ_eps^2 * I

    # Pick a correlation pair (i, j) with |ρ_true| interior — same as in
    # bench/coverage_derived.jl.
    ΛΛt = Λ_B * Λ_B'
    best_pair = (1, 2); best_ρ = 0.0
    for j in 1:p, i in 1:(j - 1)
        ρ = ΛΛt[i, j] / sqrt(Σ[i, i] * Σ[j, j])
        if 0.15 < abs(ρ) < 0.85 && abs(ρ) > abs(best_ρ)
            best_pair = (i, j); best_ρ = ρ
        end
    end
    i_ρ, j_ρ = best_pair
    ρ_true = ΛΛt[i_ρ, j_ρ] / sqrt(Σ[i_ρ, i_ρ] * Σ[j_ρ, j_ρ])

    # Pick a communality trait whose c²_true is closest to 0.5.
    c2 = [ΛΛt[t, t] / Σ[t, t] for t in 1:p]
    t_c2 = argmin(abs.(c2 .- 0.5))
    c2_true = c2[t_c2]

    return (; y, Σ_phy, Λ_B, σ_eps, σ_phy, K,
            i_ρ, j_ρ, ρ_true,
            t_c2, c2_true)
end

@testset "profile_ci_derived fix on phylo cell" begin
    fx = _build_phylo_fixture()
    fit = fit_gaussian_gllvm(fx.y; K = fx.K,
                             has_phy_unique = true,
                             Σ_phy = fx.Σ_phy)
    @test fit.converged

    spec = GLLVM._derived_spec(fit)

    # ---------------------------------------------------------------
    # Sub-test 1: the constrained refit at c slightly off g(θ̂) must
    # succeed and the *unpenalised* NLL must be finite (no barrier).
    # Pre-fix this is where the LBFGS run went pathological.
    # ---------------------------------------------------------------
    @testset "constrained refit near g_hat is healthy" begin
        f_c2 = GLLVM._make_communality_closure(spec, fx.t_c2)
        g_hat = f_c2(fit.pars.θ_packed)
        @test isfinite(g_hat) && 0 ≤ g_hat ≤ 1

        # Perturb by 0.05 in each direction. Both should produce a
        # finite ll_profile and g_at_min ≈ c (within the constraint tol
        # the escalating-w schedule reaches with w_final = 1e6).
        for δ in (-0.05, 0.05)
            c = g_hat + δ
            ll_c, ok, _, g_at = GLLVM._derived_refit_with_fixed(
                fit, f_c2, c, fx.y, nothing, fx.Σ_phy)
            @test ok
            @test isfinite(ll_c)
            @test isfinite(g_at)
            # Penalty schedule reaches w=1e6 → expect |g_at − c| ≲ 1e-3.
            @test abs(g_at - c) < 5e-3
        end
    end

    # ---------------------------------------------------------------
    # Sub-test 2: profile_ci_derived must return a NON-degenerate CI
    # for c²[t_c2]. Pre-fix this produced near-zero-width intervals.
    # ---------------------------------------------------------------
    @testset "c² profile CI is non-degenerate and contains truth" begin
        f_c2 = GLLVM._make_communality_closure(spec, fx.t_c2)
        ci = GLLVM.profile_ci_derived(fit, f_c2;
                                      y = fx.y, Σ_phy = fx.Σ_phy)
        @test ci.method === :profile
        @test isfinite(ci.lower) && isfinite(ci.upper)
        @test ci.lower < ci.upper
        # Pre-fix the width was ≲ 1e-3 (degenerate); the post-fix width
        # for c²[t_c2] on this phylo cell is ~0.2. Use a conservative
        # floor of 0.02 — well above the degenerate regime, well below
        # the expected width.
        @test (ci.upper - ci.lower) > 0.02
        # Single-rep sanity (the full coverage is in bench/coverage_derived.jl).
        @test ci.lower ≤ fx.c2_true ≤ ci.upper
    end

    # ---------------------------------------------------------------
    # Sub-test 3: same for the correlation. Pre-fix coverage was 0.00.
    # ---------------------------------------------------------------
    @testset "ρ profile CI is non-degenerate and contains truth" begin
        f_ρ = GLLVM._make_correlation_closure(spec, fx.i_ρ, fx.j_ρ)
        ci = GLLVM.profile_ci_derived(fit, f_ρ;
                                      y = fx.y, Σ_phy = fx.Σ_phy)
        @test ci.method === :profile
        @test isfinite(ci.lower) && isfinite(ci.upper)
        @test ci.lower < ci.upper
        @test (ci.upper - ci.lower) > 0.02
        @test ci.lower ≤ fx.ρ_true ≤ ci.upper
    end
end
