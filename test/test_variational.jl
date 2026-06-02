using GLLVM, Test, Random, Distributions, Statistics

@testset "Variational (VA) marginal — Poisson (increment 1)" begin
    @testset "Λ=0 reduces to independent Poisson loglik (exact)" begin
        Random.seed!(200)
        p, K, n = 6, 2, 50
        β = 0.3 .* randn(p) .+ 1.0
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        va = GLLVM.poisson_marginal_loglik_va(Y, zeros(p, K), β)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Poisson(exp(β[t])), Y[t, s])
        end
        @test va ≈ ref atol = 1e-8
    end

    @testset "ELBO is a lower bound on the exact marginal, and tight (K=1)" begin
        Random.seed!(201)
        p = 6
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p), p, 1)
        ztrue = randn()
        y = [rand(Poisson(exp(β[t] + Λ[t, 1] * ztrue))) for t in 1:p]
        Y = reshape(y, p, 1)
        va = GLLVM.poisson_marginal_loglik_va(Y, Λ, β)

        # exact single-site marginal by dense quadrature
        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                lp += logpdf(Poisson(exp(β[t] + Λ[t, 1] * z)), y[t])
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        quad = log(marg)

        @test va ≤ quad + 1e-4                  # ELBO ≤ log-marginal (Jensen / KL ≥ 0)
        @test isapprox(va, quad; atol = 0.3)    # and tight for Poisson counts
    end

    @testset "VA tracks the Laplace marginal (multi-site)" begin
        Random.seed!(202)
        p, K, n = 5, 1, 40
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p), p, 1)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn()
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(β[t] + Λ[t, 1] * z)))
            end
        end
        va  = GLLVM.poisson_marginal_loglik_va(Y, Λ, β)
        lap = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test isfinite(va)
        @test isapprox(va, lap; rtol = 0.05)    # both approximate the same integral
    end

    @testset "fit_poisson_gllvm_va machinery + ELBO monotonicity" begin
        Random.seed!(203)
        p, K, n = 6, 2, 120
        β = 0.3 .* randn(p) .+ 1.0
        Λ = 0.4 .* randn(p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(η[t])))
            end
        end
        fit = fit_poisson_gllvm_va(Y; K = K)
        @test fit isa PoissonFit
        @test isfinite(fit.loglik)
        @test size(getLV(fit, Y)) == (n, K)
        @test size(predict(fit, Y; type = :response)) == (p, n)
        # the latent variables do not decrease the ELBO vs the no-LV bound at fitted β
        ll0 = GLLVM.poisson_marginal_loglik_va(Y, zeros(p, K), fit.β)
        @test fit.loglik ≥ ll0 - 1e-3
    end
end
