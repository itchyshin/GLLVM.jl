using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# Tests for parametric bootstrap CIs on the one-part non-Gaussian fitters
# (src/confint_bootstrap_families.jl). For one or two representative families
# (Poisson and ZIP) we simulate a modest dataset, fit, run the bootstrap with a
# small `nboot` and a fixed seed, and check:
#   1. the NamedTuple shape (right fields, right lengths);
#   2. finite, ordered bounds for the converged-rich major parameters;
#   3. each parameter's point estimate lies within [lower, upper];
#   4. determinism (same seed ⇒ identical replicates).
# Kept fast: small p / n / nboot.
#
# Self-runnable when the source file is NOT yet wired into the module (the
# "new files only" slice constraint): include it directly into the current
# scope, mirroring test/test_confint_bootstrap.jl's guard.
#
#   julia --project=. -e 'using GLLVM, Test;
#                          include("src/confint_bootstrap_families.jl");
#                          include("test/test_confint_bootstrap_families.jl")'
#
# When loaded that way `bootstrap_ci_families` lives in `Main`; the tests below
# call it unqualified for that reason.
if !isdefined(@__MODULE__, :bootstrap_ci_families)
    include(joinpath(@__DIR__, "..", "src", "confint_bootstrap_families.jl"))
end

# Structural checks on a bootstrap_ci_families NamedTuple with `npar` rows over
# `nboot` replicates.
function _check_boot_shape(ci, npar::Integer, nboot::Integer)
    @test ci isa NamedTuple
    @test propertynames(ci) ==
          (:term, :estimate, :lower, :upper, :se, :n_converged, :n_valid, :replicates)
    @test length(ci.term) == npar
    @test length(ci.estimate) == npar
    @test length(ci.lower) == npar
    @test length(ci.upper) == npar
    @test length(ci.se) == npar
    @test ci.n_converged isa Int
    @test ci.n_valid isa Int
    @test size(ci.replicates) == (nboot, npar)
end

@testset "parametric bootstrap CI — non-Gaussian one-part families" begin

    @testset "Poisson" begin
        Random.seed!(4201)
        p, K, n = 4, 1, 120
        β = log.([4.0, 6.0, 3.0, 5.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 42011))
        fit = fit_poisson_gllvm(Y; K = K)

        nboot = 40
        ci = bootstrap_ci_families(fit, Y; nboot = nboot, seed = 1)

        rr = GLLVM.rr_theta_len(p, K)
        _check_boot_shape(ci, p + rr, nboot)

        # The estimate block is exactly [β; pack_lambda(Λ)] on the native scale.
        @test ci.estimate == vcat(fit.β, GLLVM.pack_lambda(fit.Λ))

        # Most replicates converge for a clean Poisson fixture.
        @test ci.n_converged >= div(nboot, 2)
        @test ci.n_valid >= 10

        # With ≥ 10 valid replicates the percentile bounds are finite and ordered.
        @test all(isfinite, ci.lower)
        @test all(isfinite, ci.upper)
        @test all(ci.lower .<= ci.upper)
        @test all(isfinite, ci.se)
        @test all(ci.se .>= 0)

        # The estimate lies within its own percentile interval for the
        # well-identified intercept block (β[1..p]). (We scope the bracketing to
        # β rather than every parameter: a near-zero loading's bootstrap
        # distribution can be skewed enough to exclude the point MLE — the
        # Gaussian sister test, test_confint_bootstrap.jl, avoids that assertion
        # for the same reason.)
        for t in 1:p
            i = findfirst(==("beta[$t]"), ci.term)
            @test ci.lower[i] <= ci.estimate[i] <= ci.upper[i]
        end
    end

    @testset "Zero-inflated Poisson" begin
        Random.seed!(4202)
        p, K, n = 4, 1, 200
        β = log.([4.0, 6.0, 3.0, 5.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.ZIP(0.3), β, Λ, n; dispersion = 0.3, seed = 42021))
        fit = fit_zip_gllvm(Y; K = K)

        nboot = 40
        ci = bootstrap_ci_families(fit, Y; nboot = nboot, seed = 7)

        rr = GLLVM.rr_theta_len(p, K)
        # β/Λ block + the zero-inflation extra "pi".
        _check_boot_shape(ci, p + rr + 1, nboot)
        @test "pi" in ci.term

        ipi = findfirst(==("pi"), ci.term)
        @test ci.estimate[ipi] == fit.π                       # native (probability) scale

        @test ci.n_valid >= 10

        # Finite, ordered bounds; the pi interval stays inside [0, 1] (the
        # native-scale percentile of a (0,1) parameter is itself in [0,1]).
        @test all(isfinite, ci.lower)
        @test all(isfinite, ci.upper)
        @test all(ci.lower .<= ci.upper)
        @test 0 <= ci.lower[ipi] <= ci.upper[ipi] <= 1

        # The estimate lies within its own percentile interval for the
        # well-identified intercept block (β[1..p]); see the Poisson testset note.
        for t in 1:p
            i = findfirst(==("beta[$t]"), ci.term)
            @test ci.lower[i] <= ci.estimate[i] <= ci.upper[i]
        end
    end

    @testset "determinism + parm subset" begin
        Random.seed!(4203)
        p, K, n = 3, 1, 100
        β = log.([4.0, 5.0, 3.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 42031))
        fit = fit_poisson_gllvm(Y; K = K)

        ci1 = bootstrap_ci_families(fit, Y; nboot = 20, seed = 3)
        ci2 = bootstrap_ci_families(fit, Y; nboot = 20, seed = 3)
        # Same seed ⇒ identical replicate matrix (NaNs compare equal via isequal).
        @test isequal(ci1.replicates, ci2.replicates)
        @test ci1.term == ci2.term

        # `parm` selects a single term and the returned shape narrows to it.
        ci_sub = bootstrap_ci_families(fit, Y; nboot = 20, seed = 3, parm = "beta[1]")
        @test ci_sub.term == ["beta[1]"]
        @test length(ci_sub.estimate) == 1
        @test ci_sub.estimate[1] == fit.β[1]
        @test size(ci_sub.replicates) == (20, 1)
    end

    @testset "Beta-Binomial (N-threading smoke)" begin
        # Exercises the trial-count (N) path through both simulate and refit, which
        # the Poisson/ZIP fixtures do not cover.
        Random.seed!(4205)
        p, K, n = 3, 1, 150
        Ntr = 12
        β = [-0.3, 0.5, 0.1]; Λ = 0.4 .* randn(p, K)
        N = fill(Ntr, p, n)
        Y = round.(Int, simulate(GLLVM._betabinomial_marker(6.0), β, Λ, n;
                                 dispersion = 6.0, N = N, seed = 42051))
        fit = fit_betabinomial_gllvm(Y; K = K, N = N)
        nboot = 30
        ci = bootstrap_ci_families(fit, Y; nboot = nboot, seed = 5, N = N)
        rr = GLLVM.rr_theta_len(p, K)
        _check_boot_shape(ci, p + rr + 1, nboot)          # β/Λ + "phi"
        @test "phi" in ci.term
        @test ci.n_valid >= 10
        @test all(isfinite, ci.lower) && all(isfinite, ci.upper)
        @test all(ci.lower .<= ci.upper)
        iphi = findfirst(==("phi"), ci.term)
        @test ci.lower[iphi] > 0                            # precision φ stays positive
    end

    @testset "argument guards" begin
        Random.seed!(4204)
        p, K, n = 3, 1, 60
        β = log.([4.0, 5.0, 3.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(Poisson(), β, Λ, n; seed = 42041))
        fit = fit_poisson_gllvm(Y; K = K)
        @test_throws ArgumentError bootstrap_ci_families(fit, Y; nboot = 0)
        @test_throws ArgumentError bootstrap_ci_families(fit, Y; level = 1.0)
    end
end
