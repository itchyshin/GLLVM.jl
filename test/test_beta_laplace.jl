using GLLVM, Test, Random, Distributions

@testset "Beta Laplace marginal" begin
    @testset "Λ = 0 reduces to independent beta-regression loglik (exact)" begin
        Random.seed!(90)
        p, K, n = 5, 2, 40
        μ = [0.3, 0.5, 0.7, 0.4, 0.6]
        β = log.(μ ./ (1 .- μ))                       # logit
        φ = 8.0
        Y = [rand(Beta(μ[t] * φ, (1 - μ[t]) * φ)) for t in 1:p, s in 1:n]
        ll = GLLVM.beta_marginal_loglik_laplace(Y, zeros(p, K), β, φ)
        ll_indep = sum(logpdf(Beta(μ[t] * φ, (1 - μ[t]) * φ), Y[t, s])
                       for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "K = 1 single site ≈ numerical quadrature" begin
        Random.seed!(91)
        p = 6
        β = zeros(p)                                  # μ = 0.5
        φ = 12.0
        Λ = reshape(0.3 .* randn(p), p, 1)
        ztrue = randn()
        μt = inv.(1 .+ exp.(-(β .+ Λ[:, 1] .* ztrue)))
        y = [rand(Beta(μt[t] * φ, (1 - μt[t]) * φ)) for t in 1:p]
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.beta_marginal_loglik_laplace(Y, Λ, β, φ)
        zs = range(-8, 8; length = 4001); dz = step(zs)
        marg = 0.0
        for z in zs
            μ = inv.(1 .+ exp.(-(β .+ Λ[:, 1] .* z)))
            logp = sum(logpdf(Beta(μ[t] * φ, (1 - μ[t]) * φ), y[t]) for t in 1:p)
            marg += exp(logp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        # Fisher-information Laplace (logit is non-canonical for Beta) — loose tol.
        @test ll_lap ≈ ll_quad atol = 0.5
    end
end
