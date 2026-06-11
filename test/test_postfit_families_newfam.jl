using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# Post-fit predict/fitted + getLV for the three newest non-Gaussian fit types covered
# by src/postfit_families_newfam.jl: ZIBinomFit, GenPoissonFit, CMPoissonFit. Mirrors
# the per-family testsets in test/test_postfit_families.jl (shape + finiteness +
# family-domain of the predictions, the link↔response relationship, and
# fitted == predict(:response)). simulate / fitter calls follow the existing sister
# tests (test_zibinom.jl, test_genpoisson.jl, test_compoisson.jl).

if !isdefined(GLLVM, :getLoadings)
    include(joinpath(@__DIR__, "..", "src", "postfit.jl"))
end

@testset "post-fit new families (predict/fitted/getLV)" begin

    @testset "zero-inflated Binomial fit" begin
        Random.seed!(1305)
        p, K, n = 6, 2, 1000
        β_true = [0.5, -0.3, 1.0, -0.8, 0.2, 0.6]
        Λ_true = 0.5 .* randn(p, K)
        π_true = 0.3
        Nmat = fill(15, p, n)
        Y = simulate(GLLVM.ZIBinom(π_true), β_true, Λ_true, n;
                     dispersion = π_true, N = Nmat, seed = 13051)
        Yint = round.(Int, Y)
        @test count(==(0), Yint) > 0                       # ZIBinom produces zeros
        fit = fit_zibinom_gllvm(Yint; K = K, N = Nmat)

        Z = GLLVM.getLV(fit, Yint; N = Nmat, rotate = false)
        @test size(Z) == (n, K)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Yint, :, s), view(Nmat, :, s),
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Yint; N = Nmat, rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Yint; type = :link, N = Nmat)
        μ_hat = GLLVM.predict(fit, Yint; type = :response, N = Nmat)
        @test size(η_hat) == (p, n)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .≥ 0)                              # marginal expected count non-negative
        # marginal mean count (1−π)·N·p, deflated below the binomial expected count N·p.
        pr = inv.(1 .+ exp.(-η_hat))
        @test μ_hat ≈ (1 - fit.π) .* Nmat .* pr
        @test all(μ_hat .≤ Nmat .* pr .+ 1e-9)            # zero-inflation deflates N·p
        @test all(μ_hat .≤ Nmat .+ 1e-9)                  # never exceeds the trial count
        @test GLLVM.fitted(fit, Yint; N = Nmat) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Yint; type = :bogus, N = Nmat)
    end

    @testset "Generalized Poisson (GP-1) fit" begin
        Random.seed!(1315)
        p, K, n = 6, 2, 1500
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        α_true = 0.2
        Y = simulate(GLLVM.GenPoisson(α_true), β_true, Λ_true, n;
                     dispersion = α_true, seed = 13151)
        Yint = round.(Int, Y)
        fit = fit_genpoisson_gllvm(Yint; K = K)

        Z = GLLVM.getLV(fit, Yint; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Yint, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Yint; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Yint; type = :link)
        μ_hat = GLLVM.predict(fit, Yint; type = :response)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .≥ 0)                              # counts: non-negative mean
        @test μ_hat ≈ exp.(η_hat)                          # GP-1 mean E[y] = μ = exp(η), log link
        @test GLLVM.fitted(fit, Yint) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Yint; type = :bogus)
    end

    @testset "Conway–Maxwell–Poisson fit" begin
        Random.seed!(1325)
        p, K, n = 6, 2, 1000
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        ν_true = 1.5                                       # mild under-dispersion (light tail)
        Y = simulate(GLLVM.CMPoisson(ν_true), β_true, Λ_true, n;
                     dispersion = ν_true, seed = 13251)
        Yint = round.(Int, Y)
        fit = fit_compoisson_gllvm(Yint; K = K)

        Z = GLLVM.getLV(fit, Yint; rotate = false)
        @test size(Z) == (n, K)
        ones_p = ones(Int, p)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(GLLVM._fit_family(fit), view(Yint, :, s), ones_p,
                                    fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        @test size(GLLVM.getLoadings(fit)) == (p, K)
        Zr = GLLVM.getLV(fit, Yint; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7

        η_hat = GLLVM.predict(fit, Yint; type = :link)
        μ_hat = GLLVM.predict(fit, Yint; type = :response)
        @test size(η_hat) == (p, n)
        @test size(μ_hat) == (p, n)
        @test all(isfinite, η_hat) && all(isfinite, μ_hat)
        @test all(μ_hat .≥ 0)                              # COM-Poisson mean non-negative
        # :response is the COM-Poisson MEAN E[y], NOT the rate λ = exp(η). It is computed
        # per cell from the same truncated normaliser sum the family score uses.
        λ_hat = exp.(η_hat)
        Eref = similar(μ_hat)
        for j in 1:n, t in 1:p
            J = GLLVM._compois_jmax(λ_hat[t, j], fit.ν, 0)
            _, Ey, _ = GLLVM._compois_logZ_moments(λ_hat[t, j], fit.ν, J)
            Eref[t, j] = Ey
        end
        @test μ_hat ≈ Eref
        # The mean is NOT the rate: under-dispersion (ν > 1) pulls E[y] off λ, so the two
        # differ (this is the whole point of returning E[y], not λ, for :response).
        @test !(μ_hat ≈ λ_hat)
        @test GLLVM.fitted(fit, Yint) ≈ μ_hat
        @test_throws ArgumentError GLLVM.predict(fit, Yint; type = :bogus)
    end
end
