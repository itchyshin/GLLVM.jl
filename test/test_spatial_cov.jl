using GLLVM
using Test
using Random
using LinearAlgebra
using Statistics
using Distributions
using SpecialFunctions: besselk, gamma

@testset "Structured Spatial Covariance Engine & Analytical Gradients" begin

    # -------------------------------------------------------------------------
    # 1. Kernel Formulations & Mathematical Invariants
    # -------------------------------------------------------------------------
    @testset "Kernel mathematical identities & bounds" begin
        Random.seed!(42)
        p = 8
        coords = randn(p, 2)

        # Basic properties across kernels
        for k in (:exponential, :gaussian, :matern)
            C = spatial_cov(coords; kernel = k, range = 1.5, sill = 2.0, nugget = 1e-5)
            @test C isa Symmetric
            @test size(C) == (p, p)
            @test isposdef(Matrix(C))
            # Diagonal equals sill + nugget
            for i in 1:p
                @test C[i, i] ≈ 2.0 + 1e-5 atol = 1e-10
            end
            # Off-diagonals bounded strictly by sill + nugget
            for j in 1:p, i in 1:p
                if i != j
                    @test C[i, j] < 2.0 + 1e-5
                    @test C[i, j] > 0.0
                end
            end
        end

        # Identity: Matérn(ν = 0.5) ≡ Exponential
        C_exp = spatial_cov(coords; kernel = :exponential, range = 1.2, sill = 1.5, nugget = 0.0)
        C_mat05 = spatial_cov(coords; kernel = :matern, smoothness = 0.5, range = 1.2, sill = 1.5, nugget = 0.0)
        @test Matrix(C_exp) ≈ Matrix(C_mat05) atol = 1e-12

        # Identity: Matérn(ν = 1.5) closed-form formula
        # C(d) = sill * (1 + √3 d / ρ) * exp(-√3 d / ρ)
        C_mat15 = spatial_cov(coords; kernel = :matern, smoothness = 1.5, range = 1.4, sill = 1.0, nugget = 0.0)
        C_mat15_exact = zeros(p, p)
        for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            C_mat15_exact[i, j] = (1.0 + sqrt(3.0) * d / 1.4) * exp(-sqrt(3.0) * d / 1.4)
        end
        @test Matrix(C_mat15) ≈ C_mat15_exact atol = 1e-12

        # Identity: Matérn(ν = 2.5) closed-form formula
        # C(d) = sill * (1 + √5 d / ρ + 5 d² / (3 ρ²)) * exp(-√5 d / ρ)
        C_mat25 = spatial_cov(coords; kernel = :matern, smoothness = 2.5, range = 1.8, sill = 1.0, nugget = 0.0)
        C_mat25_exact = zeros(p, p)
        for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            arg = sqrt(5.0) * d / 1.8
            C_mat25_exact[i, j] = (1.0 + arg + 5.0 * d^2 / (3.0 * 1.8^2)) * exp(-arg)
        end
        @test Matrix(C_mat25) ≈ C_mat25_exact atol = 1e-12
    end

    # -------------------------------------------------------------------------
    # 2. Analytical Gradient Cross-Checks vs Central Finite Differences
    # -------------------------------------------------------------------------
    @testset "Analytical gradients w.r.t range, sill, nugget, and coords" begin
        Random.seed!(123)
        p = 5
        coords = [0.0 0.0;
                  0.5 0.8;
                  1.2 0.3;
                  -0.4 1.1;
                  0.9 -0.6]

        range_val = 1.3
        sill_val  = 2.2
        nugget_val = 0.05
        h = 1e-6

        # --- A. Exponential Kernel ---
        # ∂C_ij/∂ρ = sill * (d_ij / ρ²) * exp(-d_ij / ρ)
        dC_drange_analytical_exp = zeros(p, p)
        for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            dC_drange_analytical_exp[i, j] = sill_val * (d / range_val^2) * exp(-d / range_val)
        end

        C_plus  = Matrix(spatial_cov(coords; kernel = :exponential, range = range_val + h, sill = sill_val, nugget = nugget_val))
        C_minus = Matrix(spatial_cov(coords; kernel = :exponential, range = range_val - h, sill = sill_val, nugget = nugget_val))
        dC_drange_num_exp = (C_plus - C_minus) ./ (2 * h)
        @test dC_drange_analytical_exp ≈ dC_drange_num_exp atol = 1e-6

        # ∂C_ij/∂sill = exp(-d_ij / ρ)
        dC_dsill_analytical_exp = zeros(p, p)
        for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            dC_dsill_analytical_exp[i, j] = exp(-d / range_val)
        end
        C_splus  = Matrix(spatial_cov(coords; kernel = :exponential, range = range_val, sill = sill_val + h, nugget = nugget_val))
        C_sminus = Matrix(spatial_cov(coords; kernel = :exponential, range = range_val, sill = sill_val - h, nugget = nugget_val))
        dC_dsill_num_exp = (C_splus - C_sminus) ./ (2 * h)
        @test dC_dsill_analytical_exp ≈ dC_dsill_num_exp atol = 1e-6

        # ∂C_ij/∂x_{i,k} coordinate gradient for exponential:
        # For i ≠ j: -sill/ρ * exp(-d/ρ) * (x_{i,k} - x_{j,k}) / d
        for k_dim in 1:2
            dC_dcoord_analytical = zeros(p, p)
            for j in 1:p, i in 1:p
                if i != j
                    diff_k = coords[i, k_dim] - coords[j, k_dim]
                    d = norm(coords[i, :] - coords[j, :])
                    dC_dcoord_analytical[i, j] = -sill_val / range_val * exp(-d / range_val) * (diff_k / d)
                end
            end
            coords_plus = copy(coords)
            coords_plus[1, k_dim] += h
            coords_minus = copy(coords)
            coords_minus[1, k_dim] -= h
            C_cplus  = Matrix(spatial_cov(coords_plus; kernel = :exponential, range = range_val, sill = sill_val, nugget = nugget_val))
            C_cminus = Matrix(spatial_cov(coords_minus; kernel = :exponential, range = range_val, sill = sill_val, nugget = nugget_val))
            dC_dcoord_num = (C_cplus - C_cminus) ./ (2 * h)
            @test dC_dcoord_analytical[1, :] ≈ dC_dcoord_num[1, :] atol = 1e-6
        end

        # --- B. Gaussian Kernel ---
        # ∂C_ij/∂ρ = 2 * sill * (d_ij² / ρ³) * exp(-(d_ij / ρ)²)
        dC_drange_analytical_gauss = zeros(p, p)
        for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            dC_drange_analytical_gauss[i, j] = 2 * sill_val * (d^2 / range_val^3) * exp(-(d / range_val)^2)
        end
        C_gplus  = Matrix(spatial_cov(coords; kernel = :gaussian, range = range_val + h, sill = sill_val, nugget = nugget_val))
        C_gminus = Matrix(spatial_cov(coords; kernel = :gaussian, range = range_val - h, sill = sill_val, nugget = nugget_val))
        dC_drange_num_gauss = (C_gplus - C_gminus) ./ (2 * h)
        @test dC_drange_analytical_gauss ≈ dC_drange_num_gauss atol = 1e-6

        # --- C. Matérn Kernel (ν = 1.5) ---
        # ∂C_ij/∂ρ = 3 * sill * (d_ij² / ρ³) * exp(-√3 d_ij / ρ)
        dC_drange_analytical_matern = zeros(p, p)
        for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            dC_drange_analytical_matern[i, j] = 3.0 * sill_val * (d^2 / range_val^3) * exp(-sqrt(3.0) * d / range_val)
        end
        C_mplus  = Matrix(spatial_cov(coords; kernel = :matern, smoothness = 1.5, range = range_val + h, sill = sill_val, nugget = nugget_val))
        C_mminus = Matrix(spatial_cov(coords; kernel = :matern, smoothness = 1.5, range = range_val - h, sill = sill_val, nugget = nugget_val))
        dC_drange_num_matern = (C_mplus - C_mminus) ./ (2 * h)
        @test dC_drange_analytical_matern ≈ dC_drange_num_matern atol = 1e-6
    end

    # -------------------------------------------------------------------------
    # 3. Out-of-Sample Prediction Stability on Simulated Spatial Community Matrices
    # -------------------------------------------------------------------------
    @testset "Out-of-sample prediction stability on spatial community matrices" begin
        Random.seed!(456)
        p, K, n = 6, 2, 60
        coords = 2.0 .* rand(p, 2)

        # Build true spatial covariance matrix for species
        Σ_spatial = spatial_cov(coords; kernel = :matern, smoothness = 1.5, range = 1.2, sill = 1.0, nugget = 1e-4)

        # Simulate Gaussian community responses with spatial relatedness
        Λ_true = 0.6 .* randn(p, K)
        σ_eps_true = 0.4
        φ = rand(MvNormal(zeros(p), Symmetric(Matrix(Σ_spatial))))  # spatial random effect draw
        Y = Λ_true * randn(K, n) .+ 0.5 .* φ .+ σ_eps_true .* randn(p, n)

        # 1. Fit Gaussian GLLVM with structured spatial covariance
        fit_spatial = fit_gaussian_gllvm(Y; K = K, has_phy_unique = true, Σ_phy = Σ_spatial)
        @test fit_spatial.converged
        @test isfinite(fit_spatial.logLik)

        # In-sample predictions and residuals
        μ_pred = predict(fit_spatial, Y; type = :response)
        @test size(μ_pred) == (p, n)
        @test all(isfinite, μ_pred)

        res_ds = residuals(fit_spatial, Y; type = :dunnsmyth)
        @test size(res_ds) == (p, n)
        @test all(isfinite, res_ds)
        @test abs(mean(res_ds)) < 0.25
        @test 0.7 < std(res_ds) < 1.3

        # 2. Cross-Validation on spatial community matrix
        cv_rand = cv_gllvm(Y; k_folds = 4, split = :random, family = Normal(), K = K, rng = Random.MersenneTwister(10))
        @test cv_rand.k_folds == 4
        @test cv_rand.split === :random
        @test isfinite(cv_rand.loglik)
        @test isfinite(cv_rand.mse)
        @test cv_rand.mse > 0.0
        @test cv_rand.mse < 1.0 # Should be well below naive variance
        @test all(isfinite, cv_rand.predictions)
        @test all(isfinite, cv_rand.residuals)

        # Site-level block CV
        cv_site = cv_gllvm(Y; k_folds = 3, split = :site, family = Normal(), K = K, rng = Random.MersenneTwister(20))
        @test cv_site.k_folds == 3
        @test cv_site.split === :site
        @test isfinite(cv_site.loglik)
        @test isfinite(cv_site.mse)
        @test all(isfinite, cv_site.predictions)

        # Species-level block CV
        cv_spec = cv_gllvm(Y; k_folds = 3, split = :species, family = Normal(), K = K, rng = Random.MersenneTwister(30))
        @test cv_spec.k_folds == 3
        @test cv_spec.split === :species
        @test isfinite(cv_spec.loglik)
        @test isfinite(cv_spec.mse)
        @test all(isfinite, cv_spec.predictions)
    end

    # -------------------------------------------------------------------------
    # 4. Input Validation & Error Handling
    # -------------------------------------------------------------------------
    @testset "Input validation errors" begin
        coords = randn(4, 2)
        @test_throws ArgumentError spatial_cov(coords; kernel = :unknown, range = 1.0)
        @test_throws ArgumentError spatial_cov(coords; kernel = :exponential, range = -0.5)
        @test_throws ArgumentError spatial_cov(coords; kernel = :exponential, range = 1.0, sill = -1.0)
        @test_throws ArgumentError spatial_cov(coords; kernel = :exponential, range = 1.0, nugget = -0.1)
        @test_throws ArgumentError spatial_cov(coords; kernel = :matern, range = 1.0, smoothness = -0.5)
    end

end
