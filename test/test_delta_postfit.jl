using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

@testset "post-fit Delta-lognormal" begin
    Random.seed!(150)
    p, K, n = 6, 2, 200
    βz = 0.5 .* randn(p) .+ 0.4
    βc = 0.5 .* randn(p)
    Λc = 0.5 .* randn(p, K)
    σ = 0.5
    Z = randn(K, n)
    ηc = βc .+ Λc * Z
    π = inv.(1 .+ exp.(-βz))
    Y = zeros(p, n)
    for t in 1:p, s in 1:n
        rand() < π[t] && (Y[t, s] = exp(ηc[t, s] + σ * randn()))
    end
    fit = fit_delta_lognormal_gllvm(Y; K = K)

    @testset "getLV matches per-site two-part mode" begin
        Zh = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Zh) == (n, K)
        for s in 1:n
            ẑ = GLLVM._twopart_mode(GLLVM.DeltaLogNormal(fit.σ), view(Y, :, s),
                                    zeros(p, K), fit.Λc, fit.βz, fit.βc)
            @test Zh[s, :] ≈ ẑ atol = 1e-7
        end
        @test GLLVM.rotation(fit)' * GLLVM.rotation(fit) ≈ I(K) atol = 1e-10
    end

    @testset "predict / residuals / AIC / show" begin
        Em = GLLVM.predict(fit, Y; type = :response)
        @test size(Em) == (p, n) && all(Em .≥ 0)
        occ = GLLVM.predict(fit, Y; type = :occurrence)
        @test all(0 .< occ .< 1)
        @test size(GLLVM.predict(fit, Y; type = :positive)) == (p, n)
        @test size(GLLVM.predict(fit, Y; type = :link)) == (p, n)
        @test GLLVM.fitted(fit, Y) == Em
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)

        r1 = GLLVM.residuals(fit, Y; rng = MersenneTwister(1))
        r2 = GLLVM.residuals(fit, Y; rng = MersenneTwister(1))
        @test r1 == r2 && all(isfinite, r1)

        k = 2p + (p * K - div(K * (K - 1), 2)) + 1
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        @test GLLVM.bic(fit, n) ≈ k * log(n) - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Delta-lognormal", s) && occursin("AIC", s)
    end
end
