using GLLVM, Test

# Unit tests for the profile-CI root-finder (false position on √D with a bisection
# safeguard). Each D call models one constrained refit — the dominant cost — so the
# call counts here stand in for profile-CI runtime. Correctness: the located bound
# satisfies D(bound) ≈ cutoff (the LRT crossing), identical to bisection; speed:
# far fewer refits than bisection's ~log2(width/tol).

@testset "Profile CI root-finder (fast false-position)" begin
    cutoff = 3.841458820694124          # qchisq(0.95, df = 1)
    θ̂, se = 1.0, 0.5

    Dquad(c) = ((c - θ̂) / se)^2          # D ≈ (Δ/SE)²  ⇒  √D linear in c
    root_up = θ̂ + sqrt(cutoff) * se
    root_lo = θ̂ - sqrt(cutoff) * se

    # ---- Quadratic deviance: correct root in a handful of refits -----------
    n = Ref(0)
    D = c -> (n[] += 1; Dquad(c))
    step = 1.3 * sqrt(cutoff) * se        # overshooting first step (generic case)

    n[] = 0
    up = GLLVM._profile_bisect_side(D, θ̂,  step, cutoff; max_expand = 20, max_bisect = 40)
    @test isapprox(up, root_up; atol = 1e-3)
    @test n[] ≤ 8                         # vs ~15+ for pure bisection

    n[] = 0
    lo = GLLVM._profile_bisect_side(D, θ̂, -step, cutoff; max_expand = 20, max_bisect = 40)
    @test isapprox(lo, root_lo; atol = 1e-3)
    @test n[] ≤ 8

    # ---- Asymmetric, non-quadratic deviance still converges ----------------
    # D(c) = (exp(3Δ) − 1)²  (monotone increasing for c > θ̂); crossing where
    # exp(3Δ) − 1 = √cutoff.
    Dexp = c -> (exp(3 * (c - θ̂)) - 1)^2
    target = θ̂ + log(1 + sqrt(cutoff)) / 3
    up2 = GLLVM._profile_bisect_side(Dexp, θ̂, 0.1, cutoff; max_expand = 30, max_bisect = 60)
    @test isapprox(up2, target; atol = 1e-3)

    # ---- Singular outer region: a feasibility wall beyond which refits fail -
    # The method must still return a finite bound inside the feasible region.
    wall = θ̂ + 0.9
    Dwall = c -> c ≥ wall ? Inf : ((c - θ̂) / se)^2
    b = GLLVM._profile_bisect_side(Dwall, θ̂, 0.3, cutoff; max_expand = 20, max_bisect = 40)
    @test isfinite(b)
    @test θ̂ < b ≤ wall + 1e-9

    # ---- Located bound actually sits at the cutoff crossing ----------------
    @test isapprox(Dquad(up),  cutoff; atol = 1e-2)
    @test isapprox(Dquad(lo),  cutoff; atol = 1e-2)
end
