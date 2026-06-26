using Test
using GLLVM
using Random
using Statistics
using Distributions

@testset "bridge predictor-informed latent-score X_lv" begin
    function _binary_xlv_fixture(link)
        Random.seed!(123)
        p, n, K, q_lv = 5, 140, 1, 1
        X_lv = reshape(collect(range(-1.2, 1.2; length = n)), n, q_lv)
        β = [-0.6, -0.25, 0.05, 0.35, 0.65]
        Λ = reshape([0.85, -0.65, 0.5, 0.35, -0.25], p, K)
        alpha_lv = reshape([0.7], q_lv, K)
        z_innov = randn(n)
        z_total = vec(X_lv * alpha_lv) .+ z_innov
        η = β .+ Λ * reshape(z_total, 1, n)
        μ = clamp.(GLLVM.linkinv.(Ref(link), η), 1e-4, 1 - 1e-4)
        N = fill(40, p, n)
        Y = [rand(Binomial(N[t, s], μ[t, s])) for t in 1:p, s in 1:n]
        return Y, N, X_lv, β, Λ, alpha_lv
    end

    @testset "Gaussian X_lv bridge matches native centered oracle" begin
        Random.seed!(7311)
        p, n, K, q_lv = 4, 90, 1, 1
        X_lv = reshape(collect(range(-1.4, 1.4; length = n)), n, q_lv)
        α_trait = [0.7, -0.4, 0.2, 0.9]
        Λ_true = reshape([0.8, 0.45, -0.35, 0.25], p, K)
        alpha_lv_true = reshape([1.15], q_lv, K)
        Z_mean = X_lv * alpha_lv_true
        Z_innov = 0.25 .* randn(K, n)
        Y = α_trait .+ Λ_true * (Z_mean' .+ Z_innov) .+ 0.12 .* randn(p, n)

        br = bridge_fit(; y = Y, family = "gaussian", d = K, X_lv = X_lv)
        alpha_hat = vec(mean(Y; dims = 2))
        Yc = Y .- alpha_hat
        oracle = fit_gaussian_gllvm(Yc; K = K, X_lv = X_lv)

        @test br.model == "gaussian_xlv_rr"
        @test br.family == "gaussian"
        @test br.alpha ≈ alpha_hat atol = 0
        @test br.loadings ≈ getLoadings(oracle; rotate = true) atol = 1e-10
        @test br.scores ≈ getLV(oracle, Yc; X_lv = X_lv, component = :total,
                                rotate = true) atol = 1e-10
        @test br.scores_mean ≈ getLV(oracle, Yc; X_lv = X_lv, component = :mean,
                                     rotate = true) atol = 1e-10
        @test br.scores_innovation ≈ getLV(oracle, Yc; X_lv = X_lv,
                                           component = :innovation,
                                           rotate = true) atol = 1e-10
        @test br.lv_effects ≈ extract_lv_effects(oracle) atol = 1e-10
        @test br.alpha_lv ≈ extract_lv_effects(oracle; type = :axis_effect) atol = 1e-10
        @test br.sigma_eps ≈ oracle.pars.σ_eps atol = 0
        @test br.df == p + GLLVM._nparams(oracle)
        @test occursin("predictor-informed latent-score", br.note)
        @test occursin("Confidence intervals", br.note)
    end

    @testset "Binomial X_lv packed objective matches offset Laplace core" begin
        p, n, K, q_lv = 3, 9, 1, 1
        X_lv = reshape(collect(range(-0.8, 0.8; length = n)), n, q_lv)
        β = [-0.25, 0.15, 0.4]
        Λ = reshape([0.55, -0.35, 0.2], p, K)
        alpha_lv = reshape([0.7], q_lv, K)
        N = fill(12, p, n)
        Y = [mod(t + 2s, 8) for t in 1:p, s in 1:n]
        params = vcat(β, vec(alpha_lv), GLLVM.pack_lambda(Λ))
        for link in (LogitLink(), ProbitLink(), CLogLogLink())
            lv_offset = GLLVM._lv_mean_eta(Λ, X_lv, alpha_lv)
            nll_xlv = GLLVM.binomial_lv_nll_packed(
                params, Y, N, p, K, link; X_lv = X_lv, q_lv = q_lv)
            nll_offset = -GLLVM.binomial_marginal_loglik_laplace(
                Y, N, Λ, β, link; offset = lv_offset)
            @test nll_xlv ≈ nll_offset atol = 1e-10
        end
    end

    @testset "Binomial X_lv native and bridge routes cover logit probit cloglog" begin
        link_cases = (
            ("binomial", LogitLink()),
            ("binomial_probit", ProbitLink()),
            ("binomial_cloglog", CLogLogLink()),
        )
        for (family_key, link) in link_cases
            Y, N, X_lv, β_true, Λ_true, alpha_true = _binary_xlv_fixture(link)
            fit = fit_binomial_gllvm(
                Y; K = 1, N = N, link = link, X_lv = X_lv,
                β_init = β_true, Λ_init = Λ_true, alpha_lv_init = alpha_true,
                iterations = 80, g_tol = 1e-5)

            @test fit.converged
            @test isfinite(fit.loglik)
            @test size(fit.alpha_lv) == size(alpha_true)
            @test extract_lv_effects(fit) ≈ fit.Λ * fit.alpha_lv' atol = 1e-10
            @test extract_lv_effects(fit; type = :axis_effect) ≈ fit.alpha_lv atol = 1e-10
            @test cor(vec(extract_lv_effects(fit)), vec(Λ_true * alpha_true')) > 0.98

            Zmean = getLV(fit, Y; N = N, X_lv = X_lv, component = :mean,
                          rotate = false)
            Zinnovation = getLV(fit, Y; N = N, X_lv = X_lv,
                                component = :innovation, rotate = false)
            Ztotal = getLV(fit, Y; N = N, X_lv = X_lv, component = :total,
                           rotate = false)
            @test Zmean ≈ X_lv * fit.alpha_lv atol = 1e-10
            @test Ztotal ≈ Zmean .+ Zinnovation atol = 1e-10
            @test_throws ArgumentError getLV(fit, Y; N = N)
            @test all(isfinite, predict(fit, Y; N = N, X_lv = X_lv))
            @test_throws ArgumentError simulate(fit, size(Y, 2); N = N)
            Ysim = simulate(fit, size(Y, 2); N = N, X_lv = X_lv,
                            rng = MersenneTwister(41))
            @test size(Ysim) == size(Y)
            @test all(0 .<= Ysim .<= N)
            @test_throws ArgumentError confint(fit, Y; N = N)

            br = bridge_fit(; y = Float64.(Y), family = family_key, d = 1,
                            N = N, X_lv = X_lv)
            @test br.family == family_key
            @test br.model == "$(family_key)_xlv_rr"
            @test all(==(GLLVM._bridge_link_name(link)), br.link)
            @test size(br.lv_effects) == (size(Y, 1), size(X_lv, 2))
            @test size(br.alpha_lv) == size(alpha_true)
            @test br.scores ≈ br.scores_mean .+ br.scores_innovation atol = 1e-10
            @test occursin("binomial C1", br.note)
            @test_throws ArgumentError bridge_fit(
                ; y = Float64.(Y), family = family_key, d = 1, N = N, X_lv = X_lv,
                options = Dict("ci_method" => "wald"))
            M = trues(size(Y))
            M[1, 1] = false
            @test_throws ArgumentError bridge_fit(
                ; y = Float64.(Y), family = family_key, d = 1, N = N, X_lv = X_lv,
                mask = M)
            @test_throws ArgumentError bridge_fit(
                ; y = Float64.(Y), family = family_key, d = 1, N = N, X_lv = X_lv,
                X = randn(size(Y, 1), size(Y, 2), 1))
        end
    end

    @testset "X_lv bridge unsupported combinations fail loudly" begin
        Y = randn(4, 45)
        X_lv = randn(45, 1)
        X = randn(4, 45, 1)

        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 0,
                                              X_lv = X_lv)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 1,
                                              X_lv = X_lv, X = X)
        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 1,
                                              X_lv = X_lv,
                                              options = Dict("ci_method" => "wald"))
        @test_throws ArgumentError bridge_fit(; y = Y, family = "gaussian", d = 1,
                                              X_lv = randn(44, 1))
        @test_throws ArgumentError bridge_fit(; y = abs.(Y), family = "poisson",
                                              d = 1, X_lv = X_lv)
        @test_throws ArgumentError bridge_fit(; y = Y[1:2, :],
                                              family = ["gaussian", "poisson"],
                                              d = 1, X_lv = X_lv)
    end
end
