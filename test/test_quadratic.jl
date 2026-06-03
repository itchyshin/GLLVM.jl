using GLLVM, Test, Random, Distributions, Statistics

@testset "Quadratic-response GLLVM" begin
    @testset "D = 0 reduces to the linear marginal (exact)" begin
        Random.seed!(70)
        p, K, n = 5, 2, 30
        β = log.([3.0, 5.0, 2.0, 8.0, 4.0])
        Λ = reshape(0.3 .* randn(p * K), p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        ll_quad = GLLVM.quadratic_marginal_loglik_laplace(
            Poisson(), Y, ones(Int, p, n), Λ, zeros(p, K), β, LogLink())
        ll_lin = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_quad ≈ ll_lin atol = 1e-8
    end

    @testset "K = 1 single site matches numerical quadrature" begin
        Random.seed!(71)
        p = 6
        β = log.(fill(6.0, p))                      # μ ≈ 6: Laplace-accurate regime
        Λ = reshape(0.4 .* randn(p), p, 1)
        D = reshape(-0.05 .* (0.5 .+ rand(p)), p, 1) # small, negative ⇒ unimodal
        y = [rand(Poisson(exp(β[t] + Λ[t, 1] * 0.3 + D[t, 1] * 0.09))) for t in 1:p]
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.quadratic_marginal_loglik_laplace(
            Poisson(), Y, ones(Int, p, 1), Λ, D, β, LogLink())
        # ∫ ∏_t Poisson(y_t; exp(β_t + Λ_t z + D_t z²)) φ(z) dz on a fine grid
        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            logp = sum(logpdf(Poisson(exp(β[t] + Λ[t, 1] * z + D[t, 1] * z^2)), y[t]) for t in 1:p)
            marg += exp(logp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        @test ll_lap ≈ ll_quad atol = 1e-1
    end

    @testset "fit machinery (Poisson quadratic data)" begin
        Random.seed!(72)
        p, K, n = 5, 1, 60
        β = log.(fill(5.0, p))
        Λ = reshape(0.5 .* randn(p), p, K)
        D = reshape(-0.15 .* (0.5 .+ rand(p)), p, K)   # negative ⇒ unimodal responses
        Z = randn(n, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n, t in 1:p
            η = β[t] + Λ[t, 1] * Z[s, 1] + D[t, 1] * Z[s, 1]^2
            Y[t, s] = rand(Poisson(exp(η)))
        end
        fit = fit_quadratic_gllvm(Y; family = Poisson(), K = K, iterations = 200)
        @test fit isa QuadraticFit
        @test isfinite(fit.loglik)
        @test size(fit.D) == (p, K)
        @test all(isfinite, fit.D)
    end
end
