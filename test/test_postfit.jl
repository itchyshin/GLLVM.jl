using GLLVM, Test, Random, LinearAlgebra, Statistics

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

    @testset "getLV (Binomial) matches per-site Laplace mode" begin
        Random.seed!(3)
        p, K, n = 6, 2, 80
        Λt = 0.9 .* randn(p, K)
        β  = 0.3 .* randn(p)
        η  = β .+ Λt * randn(K, n)
        μ  = inv.(1 .+ exp.(-η))
        Y  = Int.(rand(p, n) .< μ)
        fit = fit_binomial_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        # Each row equals the per-site Laplace mode.
        N = ones(Int, p, n)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(view(Y, :, s), view(N, :, s), fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        # Rotation consistency.
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7
    end
end

@testset "post-fit predict/fitted" begin
    @testset "predict (Gaussian): link == response, η = Λẑ" begin
        Random.seed!(2)
        p, K, n = 5, 2, 120
        Λt = 0.8 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        η = GLLVM.predict(fit, y; type = :link)
        μ = GLLVM.predict(fit, y; type = :response)
        @test size(η) == (p, n)
        @test η ≈ μ                                   # identity link
        Z = GLLVM.getLV(fit, y; rotate = false)
        @test η ≈ fit.pars.Λ * Z' atol = 1e-10        # no fixed-effect mean
        @test GLLVM.fitted(fit, y) ≈ μ
        @test_throws ArgumentError GLLVM.predict(fit, y; type = :bogus)
    end

    @testset "predict (Binomial): probabilities in [0,1], logit-consistent" begin
        Random.seed!(4)
        p, K, n = 6, 2, 80
        η0 = 0.3 .* randn(p) .+ (0.9 .* randn(p, K)) * randn(K, n)
        Y  = Int.(rand(p, n) .< inv.(1 .+ exp.(-η0)))
        fit = fit_binomial_gllvm(Y; K = K)

        ηp = GLLVM.predict(fit, Y; type = :link)
        pr = GLLVM.predict(fit, Y; type = :response)
        @test size(pr) == (p, n)
        @test all(0 .≤ pr .≤ 1)
        @test pr ≈ inv.(1 .+ exp.(-ηp))               # logit link
        @test GLLVM.fitted(fit, Y) ≈ pr
    end
end

@testset "post-fit residuals" begin
    @testset "residuals (Gaussian): standardized, DS == Pearson" begin
        Random.seed!(11)
        p, K, n = 5, 2, 300
        Λt = 0.8 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        rDS = GLLVM.residuals(fit, y; type = :dunnsmyth)
        rP  = GLLVM.residuals(fit, y; type = :pearson)
        @test size(rDS) == (p, n)
        @test rDS ≈ rP                                   # continuous CDF
        μ = GLLVM.predict(fit, y; type = :response)
        @test rDS ≈ (y .- μ) ./ fit.pars.σ_eps atol = 1e-10
        @test_throws ArgumentError GLLVM.residuals(fit, y; type = :bogus)
    end

    @testset "residuals (Binomial): DS reproducible + finite, Pearson formula" begin
        Random.seed!(13)
        p, K, n = 12, 1, 200
        η0 = 0.2 .* randn(p) .+ (0.9 .* randn(p, K)) * randn(K, n)
        Y  = Int.(rand(p, n) .< inv.(1 .+ exp.(-η0)))
        fit = fit_binomial_gllvm(Y; K = K)
        r1 = GLLVM.residuals(fit, Y; type = :dunnsmyth, rng = MersenneTwister(1))
        r2 = GLLVM.residuals(fit, Y; type = :dunnsmyth, rng = MersenneTwister(1))
        @test size(r1) == (p, n)
        @test r1 == r2                                    # reproducible with fixed rng
        @test all(isfinite, r1)
        # Loose sanity: roughly centered with real spread.
        @test abs(mean(r1)) < 0.3
        @test 0.3 < std(r1) < 2.0
        # Pearson formula (N = 1).
        μ = GLLVM.predict(fit, Y; type = :response)
        rP = GLLVM.residuals(fit, Y; type = :pearson)
        @test rP ≈ (Y .- μ) ./ sqrt.(μ .* (1 .- μ)) atol = 1e-10
    end
end
