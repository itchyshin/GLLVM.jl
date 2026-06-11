using GLLVM, Test, Random, LinearAlgebra, Distributions

# Wald confint coverage for the extended one-part families (NB1, Beta-Binomial,
# Student-t, zero-truncated Poisson/NB, zero-inflated Poisson/NB). Each method
# reassembles the packed MLE exactly as its fitter optimised it and calls the shared
# _nongaussian_wald_ci core; here we check the NamedTuple shape, that the dispersion
# term(s) are present and back-transform to the fit's own value (the packing/scale
# contract), and — when the observed-information Hessian is PD — that bounds are
# finite, ordered, and respect each parameter's domain. pd_hessian is informational.

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
    # β/Λ entries are the linear front block; they must round-trip to the fit's θ̂.
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

@testset "Wald confint for the extended families" begin

    @testset "NB1 (phi, :log_sd)" begin
        Random.seed!(3101)
        p, K, n = 5, 1, 400
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.NB1(8.0), β, Λ, n; dispersion = 8.0, seed = 31011))
        fit = fit_nb1_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)
        @info "NB1 confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["phi"])
        i = _check_disp(ci, "phi", fit.φ)
        ci.pd_hessian && @test ci.lower[i] > 0          # log_sd ⇒ positive bounds
    end

    @testset "Beta-Binomial (phi, :log_sd; needs N)" begin
        Random.seed!(3102)
        p, K, n = 5, 1, 400
        Ntr = 12
        β = [-0.4, 0.6, 0.0, 0.3, -0.2]; Λ = 0.4 .* randn(p, K)
        N = fill(Ntr, p, n)
        Y = round.(Int, simulate(GLLVM._betabinomial_marker(6.0), β, Λ, n;
                                 dispersion = 6.0, N = N, seed = 31021))
        fit = fit_betabinomial_gllvm(Y; K = K, N = N)
        ci = confint(fit; Y = Y, N = N)
        @info "BetaBinomial confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["phi"])
        i = _check_disp(ci, "phi", fit.φ)
        ci.pd_hessian && @test ci.lower[i] > 0
    end

    @testset "Student-t (sigma, :log_sd; nu fixed)" begin
        Random.seed!(3103)
        p, K, n = 5, 1, 400
        ν = 5.0
        β = [1.0, 2.0, -1.0, 0.5, 0.0]; Λ = 0.5 .* randn(p, K)
        Y = simulate(GLLVM.StudentTFamily(ν, 0.8), β, Λ, n; dispersion = 0.8, seed = 31031)
        fit = fit_studentt_gllvm(Y; K = K, nu = ν)
        ci = confint(fit; Y = Y)
        @info "StudentT confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["sigma"])
        i = _check_disp(ci, "sigma", fit.σ)
        ci.pd_hessian && @test ci.lower[i] > 0
    end

    @testset "Zero-truncated Poisson (beta, Lambda only)" begin
        Random.seed!(3104)
        p, K, n = 5, 1, 400
        β = log.([3.0, 4.0, 2.5, 3.5, 3.0]); Λ = 0.3 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.ZeroTruncatedPoisson(), β, Λ, n; seed = 31041))
        fit = fit_truncpoisson_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)
        @info "TruncPoisson confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K)                          # no dispersion term
        @test !("r" in ci.term) && !("phi" in ci.term)
    end

    @testset "Zero-truncated NB2 (r, :log_sd)" begin
        Random.seed!(3105)
        p, K, n = 5, 1, 400
        β = log.([3.0, 4.0, 2.5, 3.5, 3.0]); Λ = 0.3 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.TruncNB(6.0), β, Λ, n; dispersion = 6.0, seed = 31051))
        fit = fit_truncnb_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)
        @info "TruncNB confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["r"])
        i = _check_disp(ci, "r", fit.r)
        ci.pd_hessian && @test ci.lower[i] > 0
    end

    @testset "Zero-inflated Poisson (pi, :logit)" begin
        Random.seed!(3106)
        p, K, n = 5, 1, 600
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.ZIP(0.3), β, Λ, n; dispersion = 0.3, seed = 31061))
        fit = fit_zip_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)
        @info "ZIP confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["pi"])
        i = _check_disp(ci, "pi", fit.π)
        if ci.pd_hessian                                   # logit ⇒ bounds in (0,1)
            @test 0 < ci.lower[i] < ci.upper[i] < 1
        end
    end

    @testset "Zero-inflated NB2 (r :log_sd, pi :logit)" begin
        Random.seed!(3107)
        p, K, n = 5, 1, 800
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.ZINB(6.0, 0.3), β, Λ, n; seed = 31071))
        fit = fit_zinb_gllvm(Y; K = K)
        ci = confint(fit; Y = Y)
        @info "ZINB confint" pd=ci.pd_hessian
        _check_ci_shape(ci, p, K; extra_terms = ["r", "pi"])
        ir = _check_disp(ci, "r", fit.r)
        ip = _check_disp(ci, "pi", fit.π)
        if ci.pd_hessian
            @test ci.lower[ir] > 0
            @test 0 < ci.lower[ip] < ci.upper[ip] < 1
        end
    end

    @testset "missing Y errors uniformly" begin
        Random.seed!(3108)
        Y = round.(Int, simulate(GLLVM.ZIP(0.3), log.([3.0, 4.0, 3.0]), 0.3 .* randn(3, 1), 50;
                                 dispersion = 0.3, seed = 31081))
        fit = fit_zip_gllvm(Y; K = 1)
        @test_throws ArgumentError confint(fit)            # Y is required
    end
end
