using Test
using GLLVM
using Random
using Statistics
using Distributions
using LinearAlgebra

# Wald CIs for the predictor-informed latent-score trait effects B_lv = Λ·α'
# (confint_lv_effects). Generative model is correctly specified (unit innovation,
# the same z_s ~ N(0,1) the estimator assumes).
@testset "X_lv Wald CIs — confint_lv_effects" begin
    p, n, K, q_lv = 5, 200, 1, 1
    X_lv  = reshape(collect(range(-1.2, 1.2; length = n)), n, q_lv)
    Λ     = reshape([0.6, -0.45, 0.35, 0.25, -0.2], p, K)
    alpha = reshape([0.7], q_lv, K)
    B_true = vec(Λ * alpha')

    function ztot(rng)
        vec(X_lv * alpha) .+ randn(rng, n)
    end

    # Contract assertions shared by every family.
    function _check(ci, fit)
        @test ci.term == ["B_lv[$t,1]" for t in 1:p]
        @test ci.level == 0.95
        @test ci.method == :wald
        @test ci.pd_hessian
        @test ci.estimate ≈ vec(extract_lv_effects(fit)) atol = 1e-10
        @test all(isfinite, ci.se) && all(>(0), ci.se)
        @test all(ci.lower .< ci.estimate .< ci.upper)
        # 95% Wald CI half-widths ≈ 1.96·se
        @test ci.upper .- ci.estimate ≈ 1.959963984540054 .* ci.se rtol = 1e-6
        # point estimate recovers truth to within a few SEs (sanity, not coverage)
        @test maximum(abs.(ci.estimate .- B_true) ./ ci.se) < 6
    end

    @testset "Poisson" begin
        Random.seed!(4101)
        β = log.([6.0, 4.0, 8.0, 5.0, 7.0])
        η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K, X_lv = X_lv, β_init = β, Λ_init = Λ,
                                alpha_lv_init = alpha, iterations = 200, g_tol = 1e-6)
        _check(confint_lv_effects(fit, Y, X_lv), fit)
    end

    @testset "Binomial logit and probit" begin
        for (link, N0) in ((LogitLink(), 40), (ProbitLink(), 40))
            Random.seed!(4202)
            β = [-0.6, -0.25, 0.05, 0.35, 0.65]
            η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
            μ = clamp.(GLLVM.linkinv.(Ref(link), η), 1e-4, 1 - 1e-4)
            N = fill(N0, p, n)
            Y = [rand(Binomial(N[t, s], μ[t, s])) for t in 1:p, s in 1:n]
            fit = fit_binomial_gllvm(Y; K = K, N = N, link = link, X_lv = X_lv,
                                     β_init = β, Λ_init = Λ, alpha_lv_init = alpha,
                                     iterations = 150, g_tol = 1e-6)
            _check(confint_lv_effects(fit, Y, X_lv; N = N), fit)
        end
    end

    @testset "NB2" begin
        Random.seed!(4303)
        β = log.([6.0, 4.0, 8.0, 5.0, 7.0]); r = 10.0
        η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
        Y = [rand(NegativeBinomial(r, r / (r + exp(η[t, s])))) for t in 1:p, s in 1:n]
        fit = fit_nb_gllvm(Y; K = K, X_lv = X_lv, β_init = β, Λ_init = Λ,
                           alpha_lv_init = alpha, r_init = r, iterations = 200, g_tol = 1e-6)
        _check(confint_lv_effects(fit, Y, X_lv), fit)
    end

    @testset "Gamma" begin
        Random.seed!(4404)
        β = log.([2.0, 1.5, 3.0, 2.5, 1.8]); a = 6.0
        η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
        Y = [rand(Gamma(a, exp(η[t, s]) / a)) for t in 1:p, s in 1:n]
        fit = fit_gamma_gllvm(Y; K = K, X_lv = X_lv, β_init = β, Λ_init = Λ,
                              alpha_lv_init = alpha, α_init = a, iterations = 200, g_tol = 1e-6)
        _check(confint_lv_effects(fit, Y, X_lv), fit)
    end

    @testset "Beta" begin
        Random.seed!(4505)
        β = [0.3, -0.5, 0.6, -0.2, 0.4]; φ = 15.0
        η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
        μ = 1.0 ./ (1.0 .+ exp.(-η))
        Y = [rand(Beta(μ[t, s] * φ, (1 - μ[t, s]) * φ)) for t in 1:p, s in 1:n]
        fit = fit_beta_gllvm(Y; K = K, X_lv = X_lv, β_init = β, Λ_init = Λ,
                             alpha_lv_init = alpha, φ_init = φ, iterations = 200, g_tol = 1e-6)
        _check(confint_lv_effects(fit, Y, X_lv), fit)
    end

    @testset "Gaussian (closed-form, exact ForwardDiff Hessian)" begin
        Random.seed!(4606)
        zt = vec(X_lv * alpha) .+ randn(n)
        Yg = Λ * reshape(zt, 1, n) .+ 0.3 .* randn(p, n)   # centred: no β; B_lv = Λ·α
        fit = fit_gaussian_gllvm(Yg; K = K, X_lv = X_lv, iterations = 300)
        _check(confint_lv_effects(fit, Yg, X_lv), fit)
        @test_throws ArgumentError confint_lv_effects(fit_gaussian_gllvm(Yg; K = K), Yg, X_lv)
    end

    @testset "argument guards" begin
        Random.seed!(4606)
        β = log.([6.0, 4.0, 8.0, 5.0, 7.0])
        η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        xfit = fit_poisson_gllvm(Y; K = K, X_lv = X_lv, β_init = β, Λ_init = Λ,
                                 alpha_lv_init = alpha, iterations = 150, g_tol = 1e-6)
        plain = fit_poisson_gllvm(Y; K = K, iterations = 150)
        @test_throws ArgumentError confint_lv_effects(plain, Y, X_lv)            # no α_lv
        @test_throws ArgumentError confint_lv_effects(xfit, Y, X_lv; level = 1.0) # bad level
        @test_throws ArgumentError confint_lv_effects(xfit, Y, X_lv[1:(n - 1), :]) # row mismatch
    end
end
