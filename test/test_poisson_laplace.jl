using GLLVM, Test, Random, Distributions

@testset "Poisson Laplace marginal" begin
    @testset "Λ = 0 reduces to independent-Poisson loglik (exact)" begin
        Random.seed!(30)
        p, K, n = 5, 2, 40
        β = log.([3.0, 5.0, 2.0, 8.0, 4.0])              # μ_t = exp(β_t)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        ll = GLLVM.poisson_marginal_loglik_laplace(Y, zeros(p, K), β)
        ll_indep = sum(logpdf(Poisson(exp(β[t])), Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "K = 1 single site matches numerical quadrature" begin
        Random.seed!(31)
        p = 6
        β = log.(fill(6.0, p))                            # μ ≈ 6: Laplace-accurate regime
        Λ = reshape(0.4 .* randn(p), p, 1)
        y = [rand(Poisson(exp(β[t] + Λ[t, 1] * randn()))) for t in 1:p]
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        # ∫ ∏_t Poisson(y_t; exp(β_t + Λ_t z)) φ(z) dz on a fine grid
        zs = range(-8, 8; length = 4001); dz = step(zs)
        marg = 0.0
        for z in zs
            logp = sum(logpdf(Poisson(exp(β[t] + Λ[t, 1] * z)), y[t]) for t in 1:p)
            marg += exp(logp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        @test ll_lap ≈ ll_quad atol = 0.15
    end
end
