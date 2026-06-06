# Post-fit API coverage for the two newest fit types — ZIBFit (zero-inflated
# binomial) and TweedieFit — plus the freshly-unlocked aic/bic accessors. Small,
# deterministic (seeded), low-iteration fits keep this CI-fast; the assertions
# check shape, finiteness, and valid ranges rather than exact values.

using GLLVM, Test, Random, Distributions, Statistics

@testset "ZIB post-fit (zero-inflated binomial)" begin
    rng = MersenneTwister(20240606)
    p, n, K, N = 4, 60, 1, 5

    # Simulate a small zero-inflated binomial dataset: structural zeros (prob π)
    # mixed with Binomial(N, μ), μ driven by a shared latent.
    βz = fill(-0.5, p)                       # π ≈ 0.38 structural-zero prob
    βc = randn(rng, p) .* 0.3
    Λ  = randn(rng, p, K) .* 0.6
    Y  = Matrix{Int}(undef, p, n)
    for s in 1:n
        z = randn(rng, K)
        for t in 1:p
            π = 1 / (1 + exp(-βz[t]))
            if rand(rng) < π
                Y[t, s] = 0
            else
                μ = 1 / (1 + exp(-(βc[t] + (Λ * z)[t])))
                Y[t, s] = rand(rng, Binomial(N, μ))
            end
        end
    end

    fit = GLLVM.fit_zib_gllvm(Y; K = K, N = N, iterations = 40)
    @test fit isa GLLVM.ZIBFit
    @test fit.N == N

    # getLV: n×K, finite.
    Z = getLV(fit, Y)
    @test size(Z) == (n, K)
    @test all(isfinite, Z)

    # predict :response = (1−π)·N·μ ∈ [0, N]; :zeroinfl = π ∈ [0,1].
    μ = predict(fit, Y; type = :response)
    @test size(μ) == (p, n)
    @test all(isfinite, μ)
    @test all(0 .<= μ .<= N)
    zi = predict(fit, Y; type = :zeroinfl)
    @test size(zi) == (p, n)
    @test all(0 .<= zi .<= 1)
    @test all(isfinite, predict(fit, Y; type = :mean))
    @test all(isfinite, predict(fit, Y; type = :link))

    # fitted == predict(:response).
    @test fitted(fit, Y) ≈ predict(fit, Y; type = :response)

    # Dunn–Smyth residuals: p×n, finite (seeded rng for reproducibility).
    r = residuals(fit, Y; rng = MersenneTwister(1))
    @test size(r) == (p, n)
    @test all(isfinite, r)

    # getLoadings: p×K.
    @test size(getLoadings(fit)) == (p, K)

    # aic / bic finite (unlocked by _nparams/_loglik).
    @test isfinite(aic(fit))
    @test isfinite(bic(fit, n))
end

@testset "Tweedie post-fit (compound Poisson–Gamma)" begin
    rng = MersenneTwister(20240607)
    p, n, K = 4, 60, 1

    # Simulate small non-negative biomass-like data: a point mass at 0 plus a
    # positive continuous part (compound Poisson–Gamma).
    β = randn(rng, p) .* 0.2
    Λ = randn(rng, p, K) .* 0.5
    φ, pw = 1.2, 1.5
    α = (2 - pw) / (pw - 1)
    Y = Matrix{Float64}(undef, p, n)
    for s in 1:n
        z = randn(rng, K)
        for t in 1:p
            μ = exp(β[t] + (Λ * z)[t])
            λ = μ^(2 - pw) / (φ * (2 - pw))
            Nc = rand(rng, Poisson(λ))
            Y[t, s] = Nc == 0 ? 0.0 : rand(rng, Gamma(Nc * α, φ * (pw - 1) * μ^(pw - 1)))
        end
    end

    fit = GLLVM.fit_tweedie_gllvm(Y; K = K, iterations = 40)
    @test fit isa GLLVM.TweedieFit
    @test 1 < fit.p < 2
    @test fit.φ > 0

    # getLV: n×K, finite.
    Z = getLV(fit, Y)
    @test size(Z) == (n, K)
    @test all(isfinite, Z)

    # predict :response = μ = exp(η) ≥ 0.
    μ = predict(fit, Y; type = :response)
    @test size(μ) == (p, n)
    @test all(isfinite, μ)
    @test all(μ .>= 0)
    @test all(isfinite, predict(fit, Y; type = :link))

    # fitted == predict(:response).
    @test fitted(fit, Y) ≈ predict(fit, Y; type = :response)

    # Dunn–Smyth residuals (mixed CDF: atom at 0 + positive PIT): p×n, finite.
    r = residuals(fit, Y; rng = MersenneTwister(2))
    @test size(r) == (p, n)
    @test all(isfinite, r)
    rp = residuals(fit, Y; type = :pearson)
    @test size(rp) == (p, n)
    @test all(isfinite, rp)

    # getLoadings: p×K.
    @test size(getLoadings(fit)) == (p, K)

    # aic / bic finite.
    @test isfinite(aic(fit))
    @test isfinite(bic(fit, n))

    # simulate: a fresh p×n non-negative matrix.
    Ysim = simulate(fit, n; rng = MersenneTwister(3))
    @test size(Ysim) == (p, n)
    @test all(Ysim .>= 0)
    @test all(isfinite, Ysim)
end
