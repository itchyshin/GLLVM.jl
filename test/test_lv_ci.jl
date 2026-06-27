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

    @testset "K = 2 (rotation-invariant B_lv)" begin
        Random.seed!(909)
        p2, n2 = 6, 240
        X2 = reshape(collect(range(-1.2, 1.2; length = n2)), n2, 1)
        Lam2 = [0.7 0.3; -0.5 0.4; 0.4 -0.3; 0.3 0.5; -0.25 0.2; 0.2 -0.4]
        a2 = reshape([0.7, -0.5], 1, 2)
        B2 = vec(Lam2 * a2')
        beta2 = log.([6.0, 4.0, 8.0, 5.0, 7.0, 4.5])
        Z = zeros(2, n2)
        for j in 1:n2
            Z[:, j] = vec(X2[j, :] .* vec(a2)) .+ randn(2)
        end
        eta = beta2 .+ Lam2 * Z
        Y2 = [rand(Poisson(exp(eta[t, j]))) for t in 1:p2, j in 1:n2]
        fit = fit_poisson_gllvm(Y2; K = 2, X_lv = X2, iterations = 400, g_tol = 1e-6)
        ci = confint_lv_effects(fit, Y2, X2)
        @test ci.term == ["B_lv[$t,1]" for t in 1:p2]
        @test ci.pd_hessian
        @test ci.estimate ≈ vec(extract_lv_effects(fit)) atol = 1e-10
        @test all(ci.lower .< ci.estimate .< ci.upper)
        @test all(isfinite, ci.se) && all(>(0), ci.se)
        @test cor(ci.estimate, B2) > 0.9   # recovers the rotation-stable truth
    end

    @testset "bootstrap method (Poisson)" begin
        Random.seed!(5151)
        β = log.([6.0, 4.0, 8.0, 5.0, 7.0])
        η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        fit = fit_poisson_gllvm(Y; K = K, X_lv = X_lv, β_init = β, Λ_init = Λ,
                                alpha_lv_init = alpha, iterations = 150, g_tol = 1e-6)
        cb = confint_lv_effects(fit, Y, X_lv; method = :bootstrap, n_boot = 50, seed = 1)
        @test cb.method == :bootstrap
        @test cb.term == ["B_lv[$t,1]" for t in 1:p]
        @test cb.n_converged >= 35
        @test cb.estimate ≈ vec(extract_lv_effects(fit)) atol = 1e-10
        @test all(isfinite, cb.lower) && all(isfinite, cb.upper)
        @test all(cb.lower .< cb.upper)
        @test all(cb.lower .<= cb.estimate .<= cb.upper)   # point est near boot centre
        @test_throws ArgumentError confint_lv_effects(fit, Y, X_lv; method = :profile)
    end

    @testset "bootstrap covers all families (+ Gaussian K=2 guards the transpose)" begin
        # Gaussian K=2, q_lv=1: the score mean is X_lv*alpha (q_lv x K = 1 x 2). A
        # transpose (alpha') would DimensionMismatch on every replicate -> n_converged=0.
        Random.seed!(7777)
        Lam2 = [0.6 0.3; -0.45 0.35; 0.4 -0.3; 0.3 0.4; -0.25 0.2]
        a2 = reshape([0.7, -0.4], 1, 2)
        Zg = zeros(2, n)
        for j in 1:n
            Zg[:, j] = vec(X_lv[j, :] .* vec(a2)) .+ randn(2)
        end
        Yg2 = Lam2 * Zg .+ 0.3 .* randn(p, n)
        fg2 = fit_gaussian_gllvm(Yg2; K = 2, X_lv = X_lv, iterations = 300)
        cbg = confint_lv_effects(fg2, Yg2, X_lv; method = :bootstrap, n_boot = 40, seed = 3)
        @test cbg.method == :bootstrap
        @test cbg.n_converged >= 25                    # == 0 under the transpose bug
        @test all(isfinite, cbg.lower) && all(isfinite, cbg.upper)
        @test all(cbg.lower .< cbg.upper)

        boot_ok(cb) = cb.method == :bootstrap && cb.n_converged >= 10 &&
                      all(isfinite, cb.lower) && all(cb.lower .< cb.upper)
        @testset "binomial" begin
            Random.seed!(11); β = [-0.6, -0.25, 0.05, 0.35, 0.65]
            η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
            μ = clamp.(GLLVM.linkinv.(Ref(LogitLink()), η), 1e-4, 1 - 1e-4); N = fill(40, p, n)
            Y = [rand(Binomial(N[t, s], μ[t, s])) for t in 1:p, s in 1:n]
            f = fit_binomial_gllvm(Y; K = 1, N = N, link = LogitLink(), X_lv = X_lv,
                                   β_init = β, Λ_init = Λ, alpha_lv_init = alpha, iterations = 120)
            @test boot_ok(confint_lv_effects(f, Y, X_lv; N = N, method = :bootstrap, n_boot = 20, seed = 5))
        end
        @testset "nb2" begin
            Random.seed!(12); β = log.([6.0, 4, 8, 5, 7])
            η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
            Y = [rand(NegativeBinomial(10.0, 10.0 / (10.0 + exp(η[t, s])))) for t in 1:p, s in 1:n]
            f = fit_nb_gllvm(Y; K = 1, X_lv = X_lv, β_init = β, Λ_init = Λ,
                             alpha_lv_init = alpha, r_init = 10.0, iterations = 150)
            @test boot_ok(confint_lv_effects(f, Y, X_lv; method = :bootstrap, n_boot = 20, seed = 6))
        end
        @testset "gamma" begin
            Random.seed!(13); β = log.([2.0, 1.5, 3, 2.5, 1.8])
            η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
            Y = [rand(Gamma(6.0, exp(η[t, s]) / 6.0)) for t in 1:p, s in 1:n]
            f = fit_gamma_gllvm(Y; K = 1, X_lv = X_lv, β_init = β, Λ_init = Λ,
                                alpha_lv_init = alpha, α_init = 6.0, iterations = 150)
            @test boot_ok(confint_lv_effects(f, Y, X_lv; method = :bootstrap, n_boot = 20, seed = 7))
        end
        @testset "beta" begin
            Random.seed!(14); β = [0.3, -0.5, 0.6, -0.2, 0.4]
            η = β .+ Λ * reshape(ztot(Random.default_rng()), 1, n)
            μ = 1.0 ./ (1.0 .+ exp.(-η))
            Y = [rand(Beta(μ[t, s] * 15, (1 - μ[t, s]) * 15)) for t in 1:p, s in 1:n]
            f = fit_beta_gllvm(Y; K = 1, X_lv = X_lv, β_init = β, Λ_init = Λ,
                               alpha_lv_init = alpha, φ_init = 15.0, iterations = 150)
            @test boot_ok(confint_lv_effects(f, Y, X_lv; method = :bootstrap, n_boot = 20, seed = 8))
        end
    end

    @testset "q_lv = 2 (multi-predictor latent score)" begin
        Random.seed!(2468)
        p2, n2, ql = 5, 220, 2
        xa = collect(range(-1.2, 1.2; length = n2))
        xb = collect(range(-1.0, 1.0; length = n2)) .^ 2 .- 0.4   # quadratic ⟂ linear
        X2 = hcat(xa, xb)                                          # n × 2
        Λ2 = reshape([0.6, -0.45, 0.35, 0.25, -0.2], p2, 1)
        a2 = reshape([0.7, -0.4], ql, 1)                          # q_lv × K = 2 × 1
        B2 = Λ2 * a2'                                             # p × 2
        β2 = log.([6.0, 4, 8, 5, 7])
        zt2 = vec(X2 * a2) .+ randn(n2)                          # X2(n×2)·a2(2×1) = n-score mean
        η = β2 .+ Λ2 * reshape(zt2, 1, n2)
        Y2 = [rand(Poisson(exp(η[t, s]))) for t in 1:p2, s in 1:n2]
        fit = fit_poisson_gllvm(Y2; K = 1, X_lv = X2, β_init = β2, Λ_init = Λ2,
                                alpha_lv_init = a2, iterations = 200, g_tol = 1e-6)
        # Wald — 10 entries of vec(B_lv) (column-major over p×q_lv)
        ci = confint_lv_effects(fit, Y2, X2)
        @test ci.term == ["B_lv[$t,$c]" for c in 1:ql for t in 1:p2]
        @test ci.estimate ≈ vec(extract_lv_effects(fit)) atol = 1e-10
        @test ci.pd_hessian
        @test all(ci.lower .< ci.estimate .< ci.upper)
        @test cor(ci.estimate, vec(B2)) > 0.9
        # bootstrap — exercises the q_lv>1 vec→matrix paths
        cb = confint_lv_effects(fit, Y2, X2; method = :bootstrap, n_boot = 25, seed = 9)
        @test cb.term == ci.term
        @test cb.n_converged >= 12 && all(cb.lower .< cb.upper)
        # bridge round-trip: CI fields reshape to p × q_lv matching lv_effects
        br = bridge_fit(; y = Float64.(Y2), family = "poisson", d = 1, X_lv = X2,
                        options = Dict("ci_method" => "wald"))
        @test size(br.lv_effects_lower) == (p2, ql)
        @test all(br.lv_effects_lower .< br.lv_effects .< br.lv_effects_upper)
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
