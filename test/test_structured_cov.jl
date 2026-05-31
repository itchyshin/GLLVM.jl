using GLLVM, Test, Random, LinearAlgebra, Distributions

@testset "structured_cov" begin

    # ---------------------------------------------------------------
    # 1. Builder return types and shapes
    # ---------------------------------------------------------------
    @testset "spatial_cov: exponential" begin
        p = 5
        coords = randn(p, 2)
        C = spatial_cov(coords; kernel = :exponential, range = 1.0)
        @test C isa Symmetric
        @test size(C) == (p, p)
        # Diagonal should be sill + nugget
        @test all(C[i, i] ≈ 1.0 + 1e-6 for i in 1:p)
        # Must be positive definite
        @test isposdef(Matrix(C))
    end

    @testset "spatial_cov: gaussian" begin
        p = 5
        coords = randn(p, 2)
        C = spatial_cov(coords; kernel = :gaussian, range = 1.0)
        @test C isa Symmetric
        @test size(C) == (p, p)
        @test isposdef(Matrix(C))
    end

    @testset "spatial_cov: matern ν=1.5" begin
        p = 5
        Random.seed!(42)
        coords = randn(p, 2)
        C = spatial_cov(coords; kernel = :matern, range = 1.0, smoothness = 1.5)
        @test C isa Symmetric
        @test size(C) == (p, p)
        @test isposdef(Matrix(C))
    end

    @testset "matern(ν=0.5) ≈ exponential (sanity check)" begin
        # ν = 0.5 reduces the Matérn formula to exp(−d/range) exactly.
        Random.seed!(7)
        p = 6
        coords = randn(p, 2)
        C_exp   = spatial_cov(coords; kernel = :exponential, range = 0.8,
                              sill = 1.0, nugget = 0.0)
        C_mat05 = spatial_cov(coords; kernel = :matern,      range = 0.8,
                              smoothness = 0.5, sill = 1.0, nugget = 0.0)
        @test Matrix(C_exp) ≈ Matrix(C_mat05) atol = 1e-10
    end

    @testset "spatial_cov: sill scaling" begin
        Random.seed!(10)
        p = 4
        coords = randn(p, 2)
        C1 = spatial_cov(coords; kernel = :exponential, range = 1.0, sill = 2.0, nugget = 0.0)
        C2 = spatial_cov(coords; kernel = :exponential, range = 1.0, sill = 1.0, nugget = 0.0)
        @test Matrix(C1) ≈ 2.0 .* Matrix(C2) atol = 1e-12
    end

    @testset "spatial_cov: unknown kernel error" begin
        p = 3
        coords = randn(p, 2)
        @test_throws ArgumentError spatial_cov(coords; kernel = :unknown, range = 1.0)
    end

    @testset "spatial_cov: bad range error" begin
        coords = randn(4, 2)
        @test_throws ArgumentError spatial_cov(coords; kernel = :exponential, range = -1.0)
    end

    @testset "relatedness_cov: square PD GRM" begin
        p = 6
        Random.seed!(20)
        # Simulate a PD relatedness-like matrix (lower triangle method)
        L = LowerTriangular(randn(p, p))
        A_raw = L * L' + 0.1 * I(p)
        C = relatedness_cov(A_raw)
        @test C isa Symmetric
        @test size(C) == (p, p)
        @test isposdef(Matrix(C))
    end

    @testset "relatedness_cov: asymmetric input is symmetrized" begin
        p = 4
        Random.seed!(21)
        L = LowerTriangular(randn(p, p))
        A = L * L' + 0.1 * I
        # Introduce slight asymmetry
        A_asym = A .+ 1e-4 * randn(p, p)
        C = relatedness_cov(A_asym; jitter = 0.0)
        # Must be exactly symmetric
        @test Matrix(C) == Matrix(C)'
    end

    @testset "relatedness_cov: non-square error" begin
        @test_throws ArgumentError relatedness_cov(randn(3, 4))
    end

    # ---------------------------------------------------------------
    # 2. fit_gaussian_gllvm accepts dense non-tree Σ_phy
    # ---------------------------------------------------------------

    @testset "fit with spatial Σ_phy (has_phy_unique=true)" begin
        # Simulate data with a known spatial random effect and verify that
        # fit_gaussian_gllvm converges and returns finite logLik.
        Random.seed!(100)
        p, K, n = 5, 1, 80

        # Spatial covariance for p "species" in 2-D
        coords = randn(p, 2)
        Σ_sp   = spatial_cov(coords; kernel = :exponential, range = 1.0)

        # True parameters
        Λ_true   = reshape([0.7, 0.5, 0.4, -0.3, 0.2], p, K)
        σ_phy_tr = [0.4, 0.3, 0.2, 0.1, 0.3]
        σ_eps    = 0.5

        # Simulate
        η_B   = randn(K, n)
        φ     = rand(MvNormal(zeros(p), Symmetric(Matrix(Σ_sp))))  # p-vector
        y     = Λ_true * η_B .+ σ_phy_tr .* φ .+ σ_eps * randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K,
                                  has_phy_unique = true,
                                  Σ_phy = Σ_sp)
        @test isfinite(fit.logLik)
        @test fit.converged
        @test fit.pars.σ_phy isa AbstractVector
        @test length(fit.pars.σ_phy) == p
    end

    @testset "fit with spatial Σ_phy (K_phy=1, has_phy_unique=true)" begin
        Random.seed!(101)
        p, K, K_phy, n = 5, 1, 1, 80

        coords = randn(p, 2)
        Σ_sp   = spatial_cov(coords; kernel = :matern, range = 1.5, smoothness = 1.5)

        Λ_true   = reshape([0.6, 0.4, 0.3, -0.2, 0.1], p, K)
        Λ_phy_tr = reshape([0.3, 0.2, 0.1, 0.05, 0.15], p, K_phy)
        σ_eps    = 0.5

        # φ_phy: p × K_phy structured random effect (one draw per axis, shared across sites)
        φ_phy = rand(MvNormal(zeros(p), Symmetric(Matrix(Σ_sp))), K_phy)  # p × K_phy
        # phy contribution: (Λ_phy_tr .* φ_phy) * 1_n'; each column of y gets the same offset
        phy_offset = Λ_phy_tr .* φ_phy  # p × K_phy element-wise (K_phy=1)
        y = Λ_true * randn(K, n) .+ sum(phy_offset, dims=2) .+ σ_eps * randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K, K_phy = K_phy,
                                  has_phy_unique = true,
                                  Σ_phy = Σ_sp)
        @test isfinite(fit.logLik)
        @test fit.converged
    end

    @testset "fit with relatedness Σ_phy (animal model, has_phy_unique=true)" begin
        Random.seed!(200)
        p, K, n = 6, 1, 100

        # Simulate a GRM-like matrix
        L = LowerTriangular(0.5 * I(p) + 0.3 * randn(p, p))
        A_raw = L * L'
        Σ_rel = relatedness_cov(A_raw)

        Λ_true   = reshape([0.7, 0.5, 0.4, -0.3, 0.2, 0.1], p, K)
        σ_phy_tr = [0.3, 0.2, 0.25, 0.1, 0.15, 0.2]
        σ_eps    = 0.5

        φ = rand(MvNormal(zeros(p), Symmetric(Matrix(Σ_rel))))
        y = Λ_true * randn(K, n) .+ σ_phy_tr .* φ .+ σ_eps * randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K,
                                  has_phy_unique = true,
                                  Σ_phy = Σ_rel)
        @test isfinite(fit.logLik)
        @test fit.converged
        @test fit.pars.σ_phy isa AbstractVector
        @test length(fit.pars.σ_phy) == p
    end

    @testset "fit with gaussian spatial Σ_phy (has_phy_unique=true)" begin
        Random.seed!(300)
        p, K, n = 4, 1, 60

        coords = randn(p, 2)
        Σ_sp   = spatial_cov(coords; kernel = :gaussian, range = 1.0)

        Λ_true = reshape([0.6, 0.5, 0.3, -0.2], p, K)
        σ_eps  = 0.5

        y = Λ_true * randn(K, n) .+ σ_eps * randn(p, n)

        fit = fit_gaussian_gllvm(y; K = K,
                                  has_phy_unique = true,
                                  Σ_phy = Σ_sp)
        @test isfinite(fit.logLik)
        @test fit.converged
    end

end
