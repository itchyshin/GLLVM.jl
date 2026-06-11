using GLLVM, Test, Random, LinearAlgebra, Distributions

# Wald confint coverage for two of the recently-added families: zero-inflated Binomial
# (ZIBinom, π on the logit scale; needs trial counts N) and Generalized Poisson (GP-1,
# dispersion α on the IDENTITY scale — signed). Each method reassembles the packed MLE
# exactly as its fitter optimised it and calls the shared _nongaussian_wald_ci core;
# here we check the NamedTuple shape, that the dispersion term back-transforms to the
# fit's own value (the packing/scale contract), and — when the observed-information
# Hessian is PD — that bounds are finite, ordered, and respect each parameter's domain.
# pd_hessian is informational. CMPoisson is intentionally NOT covered (its truncated-sum
# marginal makes a ForwardDiff Hessian slow/fragile; deferred follow-up).

# Shared structural checks for a confint NamedTuple.
function _check_ci_shape(ci, p, K; extra_terms = String[])
    rr = GLLVM.rr_theta_len(p, K)
    @test ci isa NamedTuple
    for k in (:term, :estimate, :lower, :upper, :se, :pd_hessian)
        @test haskey(ci, k)
    end
    n = length(ci.term)
    @test n == p + rr + length(extra_terms)
    @test length(ci.estimate) == n && length(ci.lower) == n &&
          length(ci.upper) == n && length(ci.se) == n
    for t in extra_terms
        @test t in ci.term
    end
    if ci.pd_hessian
        @test all(isfinite, ci.estimate)
        @test all(isfinite, ci.lower) && all(isfinite, ci.upper)
        @test all(ci.lower .≤ ci.estimate .≤ ci.upper)
    end
end

# Estimate of a named dispersion term back-transforms to the fit's stored value.
function _check_disp(ci, name, val; rtol = 1e-6)
    i = findfirst(==(name), ci.term)
    @test i !== nothing
    @test isapprox(ci.estimate[i], val; rtol = rtol)
    return i
end

@testset "Wald confint for the new families (ZIBinom, GenPoisson)" begin

    @testset "Zero-inflated Binomial (pi, :logit; needs N)" begin
        Random.seed!(3201)
        p, K, n = 5, 1, 600
        Ntr = 12
        β = [-0.4, 0.6, 0.0, 0.3, -0.2]; Λ = 0.4 .* randn(p, K)
        N = fill(Ntr, p, n)
        Y = round.(Int, simulate(GLLVM.ZIBinom(0.3), β, Λ, n;
                                 dispersion = 0.3, N = N, seed = 32011))
        fit = fit_zibinom_gllvm(Y; K = K, N = N)
        ci = confint(fit; Y = Y, N = N)
        @info "ZIBinom confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["pi"])
        i = _check_disp(ci, "pi", fit.π)
        if ci.pd_hessian                                   # logit ⇒ bounds in (0,1)
            @test 0 < ci.lower[i] < ci.upper[i] < 1
        end
    end

    @testset "Generalized Poisson (alpha, :linear; signed)" begin
        Random.seed!(3202)
        p, K, n = 5, 1, 600
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.GenPoisson(0.1), β, Λ, n;
                                 dispersion = 0.1, seed = 32021))
        fit = fit_genpoisson_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)
        @info "GenPoisson confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["alpha"])
        # α is on the identity scale (signed): estimate round-trips, but its bound is
        # NOT constrained to be positive (unlike a :log_sd dispersion).
        i = _check_disp(ci, "alpha", fit.α)
        ci.pd_hessian && @test ci.lower[i] ≤ fit.α ≤ ci.upper[i]
    end

    @testset "missing Y errors uniformly" begin
        Random.seed!(3203)
        Y = round.(Int, simulate(GLLVM.GenPoisson(0.1), log.([3.0, 4.0, 3.0]),
                                 0.3 .* randn(3, 1), 50; dispersion = 0.1, seed = 32031))
        fit = fit_genpoisson_gllvm(Y; K = 1)
        @test_throws ArgumentError confint(fit)            # Y is required
    end
end
