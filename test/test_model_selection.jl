using GLLVM, Test, Random, Distributions, Statistics

@testset "select_lv — latent-dimension selection" begin
    @testset "Poisson sweep K = 1:3" begin
        Random.seed!(2024)
        p, K, n = 5, 2, 120
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0])
        Λ_true = 0.5 .* randn(p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        sel = select_lv(Y; family = Poisson(), Kmax = 3)

        @test sel isa LVSelection
        @test length(sel.K) == 3
        @test sel.K == [1, 2, 3]

        # More latent capacity ⇒ ≥ log-likelihood (allow tiny optimizer slack).
        for k in 1:(length(sel.loglik) - 1)
            @test sel.loglik[k + 1] >= sel.loglik[k] - 1e-3
        end

        @test sel.best_k in 1:3
        @test all(isfinite, sel.aic)
        @test all(isfinite, sel.bic)
        @test all(isfinite, sel.loglik)

        # `best` is a genuine fitted model with a finite log-likelihood.
        @test isfinite(GLLVM._loglik(sel.best))
        @test sel.best isa PoissonFit

        # AIC default agrees with the BIC selection consistency: best row is the
        # argmin of the chosen criterion (default :bic).
        @test sel.best_k == sel.K[argmin(sel.bic)]
    end

    @testset ":aic criterion selects argmin AIC" begin
        Random.seed!(7)
        p, n = 5, 120
        Y = [rand(Poisson(exp(1.4 + 0.4 * randn()))) for t in 1:p, s in 1:n]
        sel = select_lv(Y; family = Poisson(), Kmax = 3, criterion = :aic)
        @test sel.best_k == sel.K[argmin(sel.aic)]
    end
end
