using GLLVM, Test, Random, LinearAlgebra, ForwardDiff

@testset "predictor-informed latent-score mean" begin
    @testset "Gaussian C1 fit reports score components and trait effects" begin
        Random.seed!(7301)
        p, K, n, q_lv = 5, 1, 140, 1
        X_lv = reshape(collect(range(-1.5, 1.5; length = n)), n, q_lv)
        Λ_true = reshape([0.9, 0.6, -0.4, 0.3, 0.2], p, K)
        alpha_true = reshape([1.1], q_lv, K)
        Z_mean = X_lv * alpha_true
        Z_innov = 0.2 .* randn(K, n)
        y = Λ_true * (Z_mean' .+ Z_innov) .+ 0.15 .* randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K, X_lv = X_lv, iterations = 300)
        @test fit.converged
        @test fit.pars.alpha_lv !== nothing
        @test size(fit.pars.alpha_lv) == (q_lv, K)

        Zm = getLV(fit, y; X_lv = X_lv, component = :mean, rotate = false)
        Zi = getLV(fit, y; X_lv = X_lv, component = :innovation, rotate = false)
        Zt = getLV(fit, y; X_lv = X_lv, component = :total, rotate = false)
        @test Zm ≈ X_lv * fit.pars.alpha_lv atol = 1e-10
        @test Zt ≈ Zm .+ Zi atol = 1e-10

        B = extract_lv_effects(fit)
        @test size(B) == (p, q_lv)
        @test B ≈ fit.pars.Λ * fit.pars.alpha_lv' atol = 1e-10
        @test extract_lv_effects(fit; type = :axis_effect) ≈ fit.pars.alpha_lv
        @test lv_effects(fit) ≈ B

        η = predict(fit, y; X_lv = X_lv, type = :link)
        @test η ≈ fit.pars.Λ * Zt' atol = 1e-10
        @test fitted(fit, y; X_lv = X_lv) ≈ η
        @test size(residuals(fit, y; X_lv = X_lv), 1) == p
        @test GLLVM._nparams(fit) == 1 + GLLVM.rr_theta_len(p, K) + q_lv * K

        @test_throws ArgumentError getLV(fit, y)
        @test_throws ArgumentError getLV(fit, y; X_lv = X_lv, component = :bad)
        @test_throws ArgumentError extract_lv_effects(fit_gaussian_gllvm(y; K = K))
        @test_throws ArgumentError confint(fit; y = y)
        @test_throws ArgumentError profile_ci(fit, 1; y = y)
        @test_throws ArgumentError bootstrap_ci(fit; y = y, n_boot = 2)
    end

    @testset "explicit NLL is AD-friendly" begin
        Random.seed!(7302)
        p, K, n, q_lv = 4, 1, 30, 2
        y = randn(p, n)
        X_lv = randn(n, q_lv)
        θ0 = [zeros(q_lv * K); 0.0; GLLVM.init_theta_rr(p, K)]
        nll = θ -> GLLVM.gaussian_lv_nll_packed(θ, y, p, K;
                                                X_lv = X_lv, q_lv = q_lv)
        g = ForwardDiff.gradient(nll, θ0)
        @test length(g) == length(θ0)
        @test all(isfinite, g)
    end

    @testset "C1 unsupported combinations fail clearly" begin
        y = randn(4, 40)
        X_lv = randn(40, 1)
        @test_throws ArgumentError fit_gaussian_gllvm(y; K = 1, X_lv = X_lv, K_W = 1)
        @test_throws ArgumentError fit_gaussian_gllvm(y; K = 1, X_lv = X_lv, has_diag = true)
        @test_throws ArgumentError fit_gaussian_gllvm(y; K = 1, X_lv = X_lv, K_phy = 1,
                                                      Σ_phy = I(4))
    end
end
