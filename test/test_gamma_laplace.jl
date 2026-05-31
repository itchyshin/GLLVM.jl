using GLLVM, Test, Random, Distributions

@testset "Gamma Laplace marginal" begin
    @testset "Λ = 0 reduces to independent Gamma-regression loglik (exact)" begin
        Random.seed!(95)
        p, K, n = 5, 2, 40
        β = log.([2.0, 5.0, 1.0, 3.0, 4.0])           # log-means
        α = 6.0                                        # shape
        μ = exp.(β)
        Y = [rand(Gamma(α, μ[t] / α)) for t in 1:p, s in 1:n]
        ll = GLLVM.gamma_marginal_loglik_laplace(Y, zeros(p, K), β, α)
        ll_indep = sum(logpdf(Gamma(α, μ[t] / α), Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "K = 1 single site ≈ numerical quadrature" begin
        Random.seed!(96)
        p = 6
        β = log.(fill(3.0, p))
        α = 10.0
        Λ = reshape(0.3 .* randn(p), p, 1)
        ztrue = randn()
        μt = exp.(β .+ Λ[:, 1] .* ztrue)
        y = [rand(Gamma(α, μt[t] / α)) for t in 1:p]
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α)
        zs = range(-8, 8; length = 4001); dz = step(zs)
        marg = 0.0
        for z in zs
            μ = exp.(β .+ Λ[:, 1] .* z)
            logp = sum(logpdf(Gamma(α, μ[t] / α), y[t]) for t in 1:p)
            marg += exp(logp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        # log link is non-canonical for Gamma ⇒ Fisher-info Laplace, loose tol.
        @test ll_lap ≈ ll_quad atol = 0.5
    end
end
