using GLLVM, Test, Random, Distributions

@testset "anova / lrt (nested likelihood-ratio tests)" begin

    # The new _loglik/_nparams accessors make aic/bic + lrt work for the extended
    # families. Free-param convention: p + (pK − K(K−1)/2) + #scalar nuisances.
    @testset "_nparams / _loglik + aic/bic for extended families" begin
        Random.seed!(4101)
        p, K, n = 5, 1, 300
        rr = p * K - div(K * (K - 1), 2)
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)

        Ynb1 = round.(Int, simulate(GLLVM.NB1(8.0), β, Λ, n; dispersion = 8.0, seed = 41011))
        f1 = fit_nb1_gllvm(Ynb1; K = K)
        @test GLLVM._nparams(f1) == p + rr + 1        # + φ
        @test GLLVM._loglik(f1) == f1.loglik
        @test isfinite(aic(f1)) && isfinite(bic(f1, n))

        Ytp = round.(Int, simulate(GLLVM.ZeroTruncatedPoisson(), β, Λ, n; seed = 41012))
        f2 = fit_truncpoisson_gllvm(Ytp; K = K)
        @test GLLVM._nparams(f2) == p + rr            # no dispersion

        Yzinb = round.(Int, simulate(GLLVM.ZINB(6.0, 0.3), β, Λ, n; seed = 41013))
        f3 = fit_zinb_gllvm(Yzinb; K = K)
        @test GLLVM._nparams(f3) == p + rr + 2        # + r, π
        @test isfinite(aic(f3))
    end

    @testset "lrt: nested Poisson K=1 ⊂ K=2" begin
        Random.seed!(4102)
        p, n = 6, 500
        Λtrue = 0.6 .* randn(p, 2)
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Y = round.(Int, simulate(Poisson(), β, Λtrue, n; seed = 41021))
        m1 = fit_poisson_gllvm(Y; K = 1)
        m2 = fit_poisson_gllvm(Y; K = 2)
        res = lrt(m1, m2)
        @test res.df == GLLVM._nparams(m2) - GLLVM._nparams(m1)
        @test res.df == (p - 1)                       # (3p−1) − 2p
        @test res.statistic ≈ 2 * (m2.loglik - m1.loglik)
        @test res.loglik_reduced == m1.loglik && res.loglik_full == m2.loglik
        @test 0.0 ≤ res.pvalue ≤ 1.0
        @test m2.loglik ≥ m1.loglik - 1e-6            # richer model fits ≥ as well
    end

    @testset "lrt: Poisson ⊂ NB2 (df = 1, the dispersion)" begin
        Random.seed!(4103)
        p, K, n = 5, 1, 500
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0]); Λ = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(GLLVM.NB1(3.0), β, Λ, n; dispersion = 3.0, seed = 41031))  # overdispersed
        mp  = fit_poisson_gllvm(Y; K = K)
        mnb = fit_nb_gllvm(Y; K = K)
        res = lrt(mp, mnb)
        @test res.df == 1                             # NB2 adds the dispersion r
        @test res.statistic ≈ 2 * (mnb.loglik - mp.loglik)
        @test 0.0 ≤ res.pvalue ≤ 1.0
    end

    @testset "anova sequential table (K = 1,2,3)" begin
        Random.seed!(4104)
        p, n = 6, 500
        Λtrue = 0.6 .* randn(p, 2)
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Y = round.(Int, simulate(Poisson(), β, Λtrue, n; seed = 41041))
        tbl = anova(fit_poisson_gllvm(Y; K = 1),
                    fit_poisson_gllvm(Y; K = 2),
                    fit_poisson_gllvm(Y; K = 3))
        @test length(tbl.model) == 3
        @test isnan(tbl.df[1]) && isnan(tbl.pvalue[1])     # first row: nothing before it
        @test tbl.df[2] > 0 && tbl.df[3] > 0
        @test all(tbl.npar[i] ≤ tbl.npar[i + 1] for i in 1:2)
        @test all(isfinite, tbl.loglik)
        @test all(0.0 .≤ filter(isfinite, tbl.pvalue) .≤ 1.0)
    end

    @testset "anova requires ≥ 2 models" begin
        Random.seed!(4105)
        Y = round.(Int, simulate(Poisson(), log.([3.0, 4.0, 3.0]), 0.3 .* randn(3, 1), 50; seed = 41051))
        @test_throws ArgumentError anova(fit_poisson_gllvm(Y; K = 1))
    end
end
