# Tests for the boundary-inference exports: chibar2_pvalue, variance_lrt,
# profile_ci_variance (src/boundary_inference.jl).
#
# WHY THIS FILE EXISTS. All three are EXPORTED and had zero tests. They return
# p-values and confidence intervals — the outputs a user is most likely to put
# in a paper — so "untested" is the least acceptable place for it.
#
# Every assertion below is against an INDEPENDENTLY DERIVED value, not against
# the implementation's own output:
#   * the chi-bar-squared mixture is written out longhand from Self & Liang
#     (1987) / Stram & Lee (1994) and compared term by term;
#   * the profile CI is exercised on an exact QUADRATIC profile, where the
#     interval has a closed form: 2(ℓmax − ℓ(v)) = (v−v̂)²/s² = χ²₁(level)
#     gives v̂ ± s·√(χ²₁(level)). Nothing here can be satisfied by tuning.

using GLLVM, Test, Distributions

@testset "Boundary inference" begin

    @testset "chibar2_pvalue: q = 1 is exactly half the naive χ²₁ p-value" begin
        for L in (0.5, 1.0, 2.7055, 3.8415, 10.0)
            @test chibar2_pvalue(L, 1) ≈ 0.5 * ccdf(Chisq(1), L) rtol = 1e-12
        end
        # The canonical worked value: LRT = 2.7055 is the 0.05 boundary point for
        # q = 1, because ½·P(χ²₁ ≥ 2.7055) ≈ 0.05.
        @test chibar2_pvalue(2.705543454095404, 1) ≈ 0.05 atol = 1e-6
    end

    @testset "chibar2_pvalue: q = 2 matches the mixture written longhand" begin
        for L in (0.5, 2.0, 5.99, 12.0)
            expected = 0.50 * ccdf(Chisq(1), L) + 0.25 * ccdf(Chisq(2), L)
            @test chibar2_pvalue(L, 2) ≈ expected rtol = 1e-12
        end
    end

    @testset "chibar2_pvalue: q = 3 matches the mixture written longhand" begin
        for L in (1.0, 4.0, 9.0)
            expected = (3 / 8) * ccdf(Chisq(1), L) +
                       (3 / 8) * ccdf(Chisq(2), L) +
                       (1 / 8) * ccdf(Chisq(3), L)
            @test chibar2_pvalue(L, 3) ≈ expected rtol = 1e-12
        end
    end

    @testset "boundary correction is ANTI-conservative vs the naive χ²_q" begin
        # This is the entire point of the correction: treating a boundary
        # parameter with a naive χ²_q reference OVERSTATES the p-value, i.e.
        # understates the evidence. The corrected p must be strictly smaller.
        for q in 1:3, L in (1.5, 4.0, 9.0)
            @test chibar2_pvalue(L, q) < ccdf(Chisq(q), L)
        end
    end

    @testset "edges and failure modes" begin
        @test chibar2_pvalue(0.0, 1) == 1.0        # no evidence
        @test chibar2_pvalue(-3.0, 1) == 1.0       # ℓ_reduced above ℓ_full
        @test_throws ArgumentError chibar2_pvalue(1.0, 0)
        @test_throws ArgumentError chibar2_pvalue(1.0, -1)
        # p-value is a probability, and decreasing in the statistic
        for q in 1:3
            ps = [chibar2_pvalue(L, q) for L in (0.5, 1.0, 2.0, 4.0, 8.0)]
            @test all(0 .≤ ps .≤ 1)
            @test issorted(ps; rev = true)
        end
    end

    @testset "variance_lrt: the algebra it claims" begin
        r = variance_lrt(-100.0, -102.5)
        @test r.LRT ≈ 5.0 rtol = 1e-12                 # 2(ℓ_full − ℓ_reduced)
        @test r.n_boundary == 1
        @test r.pvalue ≈ chibar2_pvalue(5.0, 1) rtol = 1e-12
        @test r.pvalue ≈ 0.5 * ccdf(Chisq(1), 5.0) rtol = 1e-12

        r2 = variance_lrt(-100.0, -103.0; n_boundary = 2)
        @test r2.LRT ≈ 6.0 rtol = 1e-12
        @test r2.pvalue ≈ 0.50 * ccdf(Chisq(1), 6.0) + 0.25 * ccdf(Chisq(2), 6.0) rtol = 1e-12

        # A reduced model fitting BETTER than the full one is degenerate; the
        # statistic goes negative and the p-value must saturate at 1.
        @test variance_lrt(-105.0, -100.0).pvalue == 1.0
    end

    @testset "profile_ci_variance: exact quadratic profile has a closed form" begin
        # ℓ(v) = ℓmax − (v−v̂)²/(2s²)  ⇒  the (1−α) interval is v̂ ± s·√(χ²₁(level)).
        v̂, s, ℓmax, lvl = 4.0, 1.0, -50.0, 0.95
        refit = v -> ℓmax - (v - v̂)^2 / (2 * s^2)
        half = s * sqrt(quantile(Chisq(1), lvl))
        ci = profile_ci_variance(refit, v̂, ℓmax; level = lvl, tol = 1e-8, maxit = 200)

        @test ci.level == lvl
        @test ci.at_boundary == false
        @test ci.lower ≈ v̂ - half atol = 1e-4
        @test ci.upper ≈ v̂ + half atol = 1e-4
        @test ci.lower < v̂ < ci.upper
    end

    @testset "profile_ci_variance: a wider profile gives a wider interval" begin
        ℓmax, lvl = -50.0, 0.95
        widths = Float64[]
        for s in (0.5, 1.0, 2.0)
            refit = v -> ℓmax - (v - 6.0)^2 / (2 * s^2)
            ci = profile_ci_variance(refit, 6.0, ℓmax; level = lvl, tol = 1e-8, maxit = 200)
            push!(widths, ci.upper - ci.lower)
            @test ci.upper - ci.lower ≈ 2 * s * sqrt(quantile(Chisq(1), lvl)) atol = 1e-3
        end
        @test issorted(widths)
    end

    @testset "profile_ci_variance: the boundary clamp is the headline behaviour" begin
        # v̂ close to 0 with a wide profile: the analytic lower edge is negative,
        # so the CI lower bound must be clamped to 0 and flagged. That flag is
        # the honest "this variance is consistent with 0" result.
        ℓmax, lvl = -20.0, 0.95
        v̂, s = 0.3, 1.0
        refit = v -> ℓmax - (v - v̂)^2 / (2 * s^2)
        ci = profile_ci_variance(refit, v̂, ℓmax; level = lvl, tol = 1e-8, maxit = 200)

        @test v̂ - s * sqrt(quantile(Chisq(1), lvl)) < 0     # the unclamped edge IS negative
        @test ci.lower == 0.0
        @test ci.at_boundary == true
        @test ci.upper ≈ v̂ + s * sqrt(quantile(Chisq(1), lvl)) atol = 1e-4
    end

    @testset "profile_ci_variance: a 99% interval contains the 95% one" begin
        ℓmax = -50.0
        refit = v -> ℓmax - (v - 5.0)^2 / 2
        c95 = profile_ci_variance(refit, 5.0, ℓmax; level = 0.95, tol = 1e-8, maxit = 200)
        c99 = profile_ci_variance(refit, 5.0, ℓmax; level = 0.99, tol = 1e-8, maxit = 200)
        @test c99.lower < c95.lower
        @test c99.upper > c95.upper
    end
end
