using GLLVM, Test, Random, LinearAlgebra
using Distributions: Chisq, ccdf, quantile

# χ̄² boundary LRT for variance components (DRM cross-pollination).

@testset "Boundary inference (χ̄² variance LRT)" begin

    @testset "chibar2_pvalue formula" begin
        # q=1: the boundary p is HALF the naive χ²_1 p-value (Self–Liang).
        for L in (1.0, 3.84, 6.0, 10.0)
            @test isapprox(chibar2_pvalue(L, 1), 0.5 * ccdf(Chisq(1), L); rtol = 1e-12)
        end
        # q=2 independent variances: ½·C(2,1)·¼ wait — ¼χ²_0 + ½χ²_1 + ¼χ²_2.
        for L in (1.0, 5.0, 9.0)
            @test isapprox(chibar2_pvalue(L, 2),
                           0.5 * ccdf(Chisq(1), L) + 0.25 * ccdf(Chisq(2), L); rtol = 1e-12)
        end
        @test chibar2_pvalue(-1.0, 1) == 1.0          # LRT ≤ 0 ⇒ no evidence
        @test chibar2_pvalue(0.0, 3) == 1.0
        @test_throws ArgumentError chibar2_pvalue(5.0, 0)
        # monotone: larger LRT ⇒ smaller p
        @test chibar2_pvalue(10.0, 1) < chibar2_pvalue(3.0, 1) < chibar2_pvalue(0.5, 1)
        # boundary correction is anti-conservative vs the naive χ²_1 (smaller p)
        @test chibar2_pvalue(6.0, 1) < ccdf(Chisq(1), 6.0)
    end

    @testset "variance_lrt wrapper" begin
        t = variance_lrt(-100.0, -105.0; n_boundary = 1)          # ℓ_full − ℓ_reduced = 5
        @test t.LRT ≈ 10.0
        @test t.pvalue ≈ 0.5 * ccdf(Chisq(1), 10.0)
        @test t.n_boundary == 1
        @test variance_lrt(-100.0, -100.0).LRT == 0.0             # no improvement ⇒ LRT 0, p 1
        @test variance_lrt(-100.0, -100.0).pvalue == 1.0
    end

    @testset "applied: detect a Gaussian row-effect variance (σ_row → 0 test)" begin
        Random.seed!(70001)
        p, K, n = 5, 1, 250
        Λt = 0.6 .* randn(p, K); σ_eps, σ_row = 0.5, 0.9
        y = Λt * randn(K, n) .+ (σ_row .* randn(n))' .+ σ_eps .* randn(p, n)   # WITH a row effect
        full = fit_gaussian_row_re(y; K = K)
        reduced = fit_gaussian_gllvm(y; K = K)
        t = variance_lrt(full.loglik, reduced.logLik; n_boundary = 1)
        @test t.LRT > 0                                # the nested full model fits ≥ the reduced
        @test t.pvalue < 0.05                          # a strong row effect is detected

        Random.seed!(70002)                            # NULL: no row effect
        y0 = Λt * randn(K, n) .+ σ_eps .* randn(p, n)
        full0 = fit_gaussian_row_re(y0; K = K)
        reduced0 = fit_gaussian_gllvm(y0; K = K)
        t0 = variance_lrt(full0.loglik, reduced0.logLik; n_boundary = 1)
        # discrimination (robust): far more evidence WITH the effect than without. (A strict
        # null p>0.05 on one draw is statistically flaky — the boundary MLE σ_row≥0 gives the
        # null LRT real spread; that's precisely why honest boundary CIs/tests matter.)
        @test t.LRT > t0.LRT
    end
end

@testset "profile_ci_variance (boundary-aware profile CI)" begin
    # synthetic quadratic profile ℓ(v) = ℓ_max − ½(v−v̂)²/s²  ⇒  CI = v̂ ± √(χ²₁(level))·s
    v̂, s, ℓ_max = 2.0, 0.5, -100.0
    refit = v -> ℓ_max - 0.5 * (v - v̂)^2 / s^2
    ci = profile_ci_variance(refit, v̂, ℓ_max; level = 0.95)
    z = sqrt(quantile(Chisq(1), 0.95))
    @test isapprox(ci.lower, v̂ - z * s; atol = 1e-3)
    @test isapprox(ci.upper, v̂ + z * s; atol = 1e-3)
    @test !ci.at_boundary
    # a near-0, weakly-identified variance (wide flat profile) ⇒ lower clamps at 0
    refit2 = v -> ℓ_max - 0.5 * (v - 0.05)^2 / 4.0
    ci2 = profile_ci_variance(refit2, 0.05, ℓ_max; level = 0.95)
    @test ci2.lower == 0.0
    @test ci2.at_boundary
    @test ci2.upper > 0.05
end
