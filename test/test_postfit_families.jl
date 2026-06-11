using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# Post-fit predict/fitted + getLV for the newer one-part fit types covered by
# src/postfit_families.jl: NB1Fit, LognormalFit, BetaBinomialFit, StudentTFit,
# TruncPoissonFit, TruncNBFit, ZIPFit, ZINBFit. Mirrors the per-family testsets in
# test/test_postfit.jl (shape + finiteness + family-domain of the predictions, the
# link↔response relationship, and fitted == predict(:response)). simulate / fitter
# calls follow the existing sister tests (test_nb1_lognormal.jl, test_betabinomial.jl,
# test_studentt.jl, test_truncpoisson.jl, test_truncnb.jl, test_zip.jl, test_zinb.jl).

if !isdefined(GLLVM, :getLoadings)
    include(joinpath(@__DIR__, "..", "src", "postfit.jl"))
end

@testset "post-fit families (predict/fitted/getLV)" begin

    @testset "NB1 fit" begin
        Random.seed!(610)
        p, K, n = 6, 2, 150
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.4 .* randn(p, K)
        φ_true = 0.8
        Y = round.(Int, simulate(NB1(φ_true), β_true, Λ_true, n;
                                 dispersion = φ_true, seed = 6101))
        fit = fit_nb1_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        # Each row equals the per-site Laplace mode under the fit's family marker.
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(η_hat) == (p, n)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .≥ 0)                              # counts: non-negative mean
        @test μ_hat ≈ exp.(η_hat)                          # log link
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end

    @testset "Lognormal fit" begin
        Random.seed!(620)
        p, K, n = 6, 2, 200
        β_true = [0.5, 1.0, -0.3, 0.8, 0.2, 0.6]
        Λ_true = 0.4 .* randn(p, K)
        σ_true = 0.6
        Y = simulate(LogNormal(), β_true, Λ_true, n; dispersion = σ_true, seed = 6201)
        @test all(Y .> 0)
        fit = fit_lognormal_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        # Lognormal getLV is the Gaussian posterior mean on the log scale (Ψ = σ²I),
        # NOT a Laplace mode — mirror the Gaussian getLV reference in test_postfit.jl.
        Λ = fit.Λ
        R = log.(Y) .- fit.β
        ΨiΛ = (1 / fit.σ^2) .* Λ
        M = Symmetric(I(K) + Λ' * ΨiΛ)
        Zref = permutedims(M \ (ΨiΛ' * R))                # n×K
        @test Z ≈ Zref atol = 1e-8
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .> 0)                              # lognormal: strictly positive
        # response-scale mean is the lognormal mean exp(η + σ²/2), NOT exp(η).
        @test μ_hat ≈ exp.(η_hat .+ fit.σ^2 / 2)
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end

    @testset "Beta-Binomial fit" begin
        Random.seed!(630)
        p, K, n = 6, 2, 200
        Ntr = 18
        β_true = [0.5, -0.4, 0.8, 0.2, -0.6, 0.3]
        Λ_true = 0.5 .* randn(p, K)
        φ_true = 8.0
        N = fill(Ntr, p, n)
        Y = round.(Int, simulate(GLLVM._betabinomial_marker(φ_true), β_true, Λ_true, n;
                                 dispersion = φ_true, N = N, seed = 6301))
        fit = fit_betabinomial_gllvm(Y; K = K, N = N)

        Z = GLLVM.getLV(fit, Y; N = N, rotate = false)
        @test size(Z) == (n, K)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), view(N, :, s),
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Y; N = N, rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Y; type = :link, N = N)
        pr_hat = GLLVM.predict(fit, Y; type = :response, N = N)
        @test size(pr_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, pr_hat)
        @test all(0 .≤ pr_hat .≤ 1)                        # mean PROBABILITY in [0,1]
        @test pr_hat ≈ inv.(1 .+ exp.(-η_hat))             # logit link
        @test GLLVM.fitted(fit, Y; N = N) ≈ pr_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus, N = N)
    end

    @testset "Student-t fit" begin
        Random.seed!(640)
        p, K, n = 6, 2, 200
        ν = 4.0
        β_true = [0.5, 1.0, -0.3, 0.8, 0.2, 0.6]
        Λ_true = 0.4 .* randn(p, K)
        σ_true = 0.7
        Y = simulate(StudentTFamily(ν, σ_true), β_true, Λ_true, n;
                     dispersion = σ_true, seed = 6401)
        fit = fit_studentt_gllvm(Y; K = K, nu = ν)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test η_hat ≈ μ_hat                                # identity link ⇒ link == response
        @test μ_hat ≈ fit.β .+ fit.Λ * Z'
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end

    @testset "zero-truncated Poisson fit" begin
        Random.seed!(650)
        p, K, n = 6, 2, 150
        β_true = log.([3.0, 4.0, 2.5, 3.5, 3.0, 4.5])
        Λ_true = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(ZeroTruncatedPoisson(), β_true, Λ_true, n; seed = 6501))
        @test minimum(Y) ≥ 1
        fit = fit_truncpoisson_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        # response-scale mean is the truncated mean μ/(1−e^{−μ}) ≥ 1, not exp(η).
        μ = exp.(η_hat)
        @test μ_hat ≈ μ ./ (.-expm1.(.-μ))
        @test all(μ_hat .≥ 1)                              # positive-count mean ≥ 1
        @test all(μ_hat .≥ μ .- 1e-9)                      # truncated mean ≥ untruncated rate
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end

    @testset "zero-truncated NB2 fit" begin
        Random.seed!(660)
        p, K, n = 6, 2, 200
        β_true = log.([3.0, 4.0, 2.5, 3.5, 3.0, 4.5])
        Λ_true = 0.5 .* randn(p, K)
        r_true = 6.0
        Y = round.(Int, simulate(TruncNB(r_true), β_true, Λ_true, n;
                                 dispersion = r_true, seed = 6601))
        @test minimum(Y) ≥ 1
        fit = fit_truncnb_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        # response-scale mean is the truncated mean μ/(1−P₀), P₀=(r/(r+μ))^r.
        r = fit.r
        μ = exp.(η_hat)
        P0 = (r ./ (r .+ μ)) .^ r
        @test μ_hat ≈ μ ./ (1 .- P0)
        @test all(μ_hat .≥ 1)                              # positive-count mean ≥ 1
        @test all(μ_hat .≥ μ .- 1e-9)                      # truncated mean ≥ untruncated rate
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end

    @testset "zero-inflated Poisson fit" begin
        Random.seed!(670)
        p, K, n = 6, 2, 400
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.4 .* randn(p, K)
        π_true = 0.3
        Y = round.(Int, simulate(GLLVM.ZIP(π_true), β_true, Λ_true, n;
                                 dispersion = π_true, seed = 6701))
        @test count(==(0), Y) > 0
        fit = fit_zip_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .≥ 0)                              # marginal mean non-negative
        # marginal mean (1−π)·μ, smaller than the bare count rate exp(η).
        @test μ_hat ≈ (1 - fit.π) .* exp.(η_hat)
        @test all(μ_hat .≤ exp.(η_hat) .+ 1e-9)
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end

    @testset "zero-inflated NB2 fit" begin
        Random.seed!(680)
        p, K, n = 6, 2, 400
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.4 .* randn(p, K)
        r_true = 6.0
        π_true = 0.3
        Y = round.(Int, simulate(GLLVM.ZINB(r_true, π_true), β_true, Λ_true, n;
                                 seed = 6801))
        @test count(==(0), Y) > 0
        fit = fit_zinb_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Y, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)

        η_hat = GLLVM.predict(fit, Y; type = :link)
        μ_hat = GLLVM.predict(fit, Y; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .≥ 0)                              # marginal mean non-negative
        # marginal mean (1−π)·μ, smaller than the bare count rate exp(η).
        @test μ_hat ≈ (1 - fit.π) .* exp.(η_hat)
        @test all(μ_hat .≤ exp.(η_hat) .+ 1e-9)
        @test GLLVM.fitted(fit, Y) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Y; type = :bogus)
    end
end
