using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

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

@testset "post-fit AIC/BIC + show" begin
    @testset "param count + AIC/BIC (Gaussian J1)" begin
        Random.seed!(21)
        p, K, n = 5, 2, 200
        Λt = 0.8 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)
        k = p * K - div(K * (K - 1), 2) + 1          # loadings + σ_eps (no intercepts, X=nothing)
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.logLik
        @test GLLVM.bic(fit, n) ≈ k * log(n) - 2 * fit.logLik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Gaussian", s) && occursin("logLik", s) && occursin("AIC", s)
    end

    @testset "param count + AIC/BIC (Binomial)" begin
        Random.seed!(22)
        p, K, n = 6, 2, 120
        η0 = 0.3 .* randn(p) .+ (0.9 .* randn(p, K)) * randn(K, n)
        Y  = Int.(rand(p, n) .< inv.(1 .+ exp.(-η0)))
        fit = fit_binomial_gllvm(Y; K = K)
        k = p + (p * K - div(K * (K - 1), 2))        # intercepts + loadings
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        @test GLLVM.bic(fit, n) ≈ k * log(n) - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Binomial", s) && occursin("AIC", s)
    end
end

@testset "post-fit Poisson fits" begin
    Random.seed!(50)
    p, K, n = 6, 2, 150
    β = log.(fill(5.0, p))
    Λt = 0.4 .* randn(p, K)
    η = β .+ Λt * randn(K, n)
    Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
    fit = fit_gllvm(Y; family = Poisson(), K = K)

    @testset "getLV / getLoadings / rotation" begin
        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(Poisson(), view(Y, :, s), ones(Int, p), fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        R = GLLVM.rotation(fit)
        @test R' * R ≈ I(K) atol = 1e-10
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7
    end

    @testset "predict (rates) + residuals + AIC/BIC + show" begin
        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(μ_hat .≥ 0)
        @test μ_hat ≈ exp.(η_hat)                          # log link

        r1 = GLLVM.residuals(fit, Y; rng = MersenneTwister(2))
        r2 = GLLVM.residuals(fit, Y; rng = MersenneTwister(2))
        @test r1 == r2 && all(isfinite, r1)
        rp = GLLVM.residuals(fit, Y; type = :pearson)
        @test rp ≈ (Y .- μ_hat) ./ sqrt.(μ_hat) atol = 1e-10

        k = p + (p * K - div(K * (K - 1), 2))
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        @test GLLVM.bic(fit, n) ≈ k * log(n) - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Poisson", s) && occursin("AIC", s)
    end
end

@testset "post-fit NB fits" begin
    Random.seed!(80)
    p, K, n = 6, 2, 150
    β = log.(fill(5.0, p))
    Λt = 0.4 .* randn(p, K)
    r_true = 6.0
    μ = exp.(β .+ Λt * randn(K, n))
    Y = [rand(NegativeBinomial(r_true, r_true / (r_true + μ[t, s]))) for t in 1:p, s in 1:n]
    fit = fit_gllvm(Y; family = NegativeBinomial(), K = K)

    @testset "getLV / getLoadings / rotation" begin
        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(NegativeBinomial(fit.r, 0.5), view(Y, :, s),
                                    ones(Int, p), fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        @test GLLVM.rotation(fit)' * GLLVM.rotation(fit) ≈ I(K) atol = 1e-10
    end

    @testset "predict (means) + residuals + AIC/BIC + show" begin
        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test all(μ_hat .≥ 0)
        @test μ_hat ≈ exp.(η_hat)
        r1 = GLLVM.residuals(fit, Y; rng = MersenneTwister(3))
        r2 = GLLVM.residuals(fit, Y; rng = MersenneTwister(3))
        @test r1 == r2 && all(isfinite, r1)
        rp = GLLVM.residuals(fit, Y; type = :pearson)
        @test rp ≈ (Y .- μ_hat) ./ sqrt.(μ_hat .+ μ_hat .^ 2 ./ fit.r) atol = 1e-9
        k = p + (p * K - div(K * (K - 1), 2)) + 1            # + dispersion r
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Negative-binomial", s) && occursin("AIC", s)
    end
end

@testset "post-fit Beta fits" begin
    Random.seed!(110)
    p, K, n = 6, 2, 200
    β = zeros(p)
    Λt = 0.5 .* randn(p, K)
    φ_true = 12.0
    μ = inv.(1 .+ exp.(-(β .+ Λt * randn(K, n))))
    Y = [rand(Beta(μ[t, s] * φ_true, (1 - μ[t, s]) * φ_true)) for t in 1:p, s in 1:n]
    fit = fit_gllvm(Y; family = Beta(), K = K)

    @testset "getLV / getLoadings / rotation" begin
        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(Beta(fit.φ, 1.0), view(Y, :, s),
                                    ones(Int, p), fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        @test GLLVM.rotation(fit)' * GLLVM.rotation(fit) ≈ I(K) atol = 1e-10
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7
    end

    @testset "predict (proportions) + residuals + AIC/BIC + show" begin
        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(0 .< μ_hat .< 1)
        @test μ_hat ≈ inv.(1 .+ exp.(-η_hat))                # logit link
        # Continuous CDF ⇒ Dunn–Smyth residual is deterministic (no rng arg).
        rDS = GLLVM.residuals(fit, Y; type = :dunnsmyth)
        @test size(rDS) == (p, n)
        @test all(isfinite, rDS)
        rp = GLLVM.residuals(fit, Y; type = :pearson)
        @test rp ≈ (Y .- μ_hat) ./ sqrt.(μ_hat .* (1 .- μ_hat) ./ (1 + fit.φ)) atol = 1e-9
        @test_throws ArgumentError GLLVM.residuals(fit, Y; type = :bogus)
        k = p + (p * K - div(K * (K - 1), 2)) + 1            # + precision φ
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        @test GLLVM.bic(fit, n) ≈ k * log(n) - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Beta", s) && occursin("AIC", s)
    end
end
