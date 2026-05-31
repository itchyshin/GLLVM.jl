using GLLVM, Test, Random, LinearAlgebra

if !isdefined(GLLVM, :getLoadings)
    include(joinpath(@__DIR__, "..", "src", "postfit.jl"))
end

@testset "post-fit ordination core" begin
    @testset "rotation + getLoadings (Gaussian)" begin
        Random.seed!(0)
        p, K, n = 5, 2, 120
        Λt = 0.8 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        R = GLLVM.rotation(fit)
        @test size(R) == (K, K)
        @test R' * R ≈ I(K) atol = 1e-10            # orthogonal

        Lr = GLLVM.getLoadings(fit; rotate = true)
        L0 = GLLVM.getLoadings(fit; rotate = false)
        @test size(Lr) == (p, K)
        @test L0 ≈ fit.pars.Λ                         # raw == stored Λ
        @test Lr ≈ L0 * R                             # rotated == Λ·R
        @test Lr * Lr' ≈ L0 * L0' atol = 1e-9         # rotation-invariant ΛΛ'
        # canonical: rotated columns ordered by decreasing norm
        nrm = [norm(@view Lr[:, k]) for k in 1:K]
        @test issorted(nrm; rev = true)
        # sign-fix: largest-magnitude entry of each rotated column is ≥ 0
        for k in 1:K
            @test Lr[argmax(abs.(@view Lr[:, k])), k] ≥ 0
        end
    end

    @testset "_laplace_mode matches the marginal's inner solve" begin
        Random.seed!(7)
        p, K, n = 4, 1, 1
        Λ = reshape([1.0, 0.8, -0.6, 0.4], p, K)
        β = [0.2, -0.1, 0.0, 0.3]
        y = reshape([1, 0, 1, 1], p, n)
        N = ones(Int, p, n)
        ẑ = GLLVM._laplace_mode(view(y, :, 1), view(N, :, 1), Λ, β, LogitLink())
        @test length(ẑ) == K
        # At the mode the penalised-score stationarity holds: Λ'(working
        # residual) − ẑ ≈ 0 (the inner Newton step is ~0).
        η = β .+ Λ * ẑ
        μ = inv.(1 .+ exp.(-η))
        me = μ .* (1 .- μ)
        s = (vec(y) .- vec(N) .* μ) ./ (μ .* (1 .- μ)) .* me
        @test maximum(abs.(Λ' * s .- ẑ)) < 1e-6
    end

    @testset "getLV (Gaussian) matches the factor-analysis posterior" begin
        Random.seed!(1)
        p, K, n = 5, 2, 150
        Λt = 0.9 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        Z = GLLVM.getLV(fit, y; rotate = false)
        @test size(Z) == (n, K)

        # Independent reference: m_s = (I + Λ'Ψ⁻¹Λ)⁻¹ Λ'Ψ⁻¹ y_s, Ψ = Σ_y − ΛΛ'.
        Λ = fit.pars.Λ
        Σ = GLLVM.sigma_y_site(fit)
        Ψ = Σ - Λ * Λ'
        ΨiΛ = Ψ \ Λ
        M = Symmetric(I(K) + Λ' * ΨiΛ)
        Zref = (M \ (ΨiΛ' * y))'              # n×K
        @test Z ≈ Zref atol = 1e-8

        # Rotation consistency: Λ_rot Z_rotᵀ == Λ Z_rawᵀ.
        Zr = GLLVM.getLV(fit, y; rotate = true)
        Lr = GLLVM.getLoadings(fit; rotate = true)
        @test Lr * Zr' ≈ Λ * Z' atol = 1e-8
    end
end
