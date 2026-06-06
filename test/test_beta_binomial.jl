using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Direct (latent-free) beta-binomial loglik over all (t,s): the Λ=0 reference.
_indep_betabinom_loglik(Y, N, β, φ, link) = sum(
    GLLVM.betabinomial_logp(Y[t, s], β[t], N[t, s], φ; link = link)
    for t in axes(Y, 1), s in axes(Y, 2))

@testset "Beta-binomial family" begin

    @testset "φ→∞ ⇒ Binomial marginal (KEY ANCHOR)" begin
        Random.seed!(11)
        p, n, K = 5, 70, 1
        β = randn(p) .* 0.6
        Λ = reshape(0.7 .* randn(p), p, K)
        N = rand(5:12, p, n)
        # draw plausible successes
        Y = [rand(0:N[t, s]) for t in 1:p, s in 1:n]

        link = LogitLink()
        # large φ ⇒ Beta collapses to a point mass ⇒ Binomial(N, μ).
        φ_big = 1e6
        bb  = GLLVM.betabinomial_marginal_loglik_laplace(Y, N, Λ, β, φ_big; link = link)
        bin = GLLVM.marginal_loglik_laplace(Binomial(), Y, N, Λ, β, link)
        @test isfinite(bb)
        @test abs(bb - bin) ≤ 1e-2
    end

    @testset "Λ=0 exact reduction (machine precision)" begin
        Random.seed!(12)
        p, n, K = 4, 60, 2
        β = randn(p) .* 0.5
        Λ0 = zeros(p, K)
        N = rand(4:10, p, n)
        Y = [rand(0:N[t, s]) for t in 1:p, s in 1:n]
        for (link, φ) in ((LogitLink(), 8.0), (ProbitLink(), 5.0), (CLogLogLink(), 12.0))
            lap = GLLVM.betabinomial_marginal_loglik_laplace(Y, N, Λ0, β, φ; link = link)
            direct = _indep_betabinom_loglik(Y, N, β, φ, link)
            @test lap ≈ direct atol = 1e-8
        end
    end

    @testset "fit smoke + loadings recovery" begin
        Random.seed!(13)
        p, n, K = 6, 80, 1
        β_true = randn(p) .* 0.5
        Λ_true = reshape(0.9 .* randn(p), p, K)
        φ_true = 12.0
        N = rand(8:15, p, n)
        z = randn(K, n)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n, t in 1:p
            η = β_true[t] + dot(Λ_true[t, :], z[:, s])
            μ = GLLVM._bb_logistic(η)
            a = clamp(μ, 1e-9, 1 - 1e-9) * φ_true
            b = (1 - clamp(μ, 1e-9, 1 - 1e-9)) * φ_true
            p_draw = rand(Beta(a, b))
            Y[t, s] = rand(Binomial(N[t, s], p_draw))
        end

        fit = GLLVM.fit_beta_binomial_gllvm(Y; K = K, N = N, iterations = 40)
        @test isfinite(fit.loglik)
        @test fit.φ > 0
        @test size(fit.Λ) == (p, K)

        # loadings-Gram correlation (rotation / sign invariant via outer product).
        Gtrue = Λ_true * Λ_true'
        Ghat  = fit.Λ * fit.Λ'
        m = [i < j for i in 1:p, j in 1:p]      # strict upper triangle
        r = cor(Gtrue[m], Ghat[m])
        @test r > 0.3
    end
end
