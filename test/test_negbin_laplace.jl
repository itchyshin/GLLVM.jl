using GLLVM, Test, Random, Distributions

@testset "Negative-binomial Laplace marginal" begin
    @testset "Λ = 0 reduces to independent-NB loglik (exact)" begin
        Random.seed!(60)
        p, K, n = 5, 2, 40
        β = log.([3.0, 5.0, 2.0, 8.0, 4.0])
        r = 4.0
        Y = [rand(NegativeBinomial(r, r / (r + exp(β[t])))) for t in 1:p, s in 1:n]
        ll = GLLVM.nb_marginal_loglik_laplace(Y, zeros(p, K), β, r)
        ll_indep = sum(logpdf(NegativeBinomial(r, r / (r + exp(β[t]))), Y[t, s])
                       for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "large r → matches the Poisson marginal" begin
        Random.seed!(61)
        p, K, n = 5, 1, 30
        β = log.(fill(5.0, p))
        Λ = reshape(0.4 .* randn(p), p, 1)
        Y = [rand(Poisson(exp(β[t] + Λ[t, 1] * randn()))) for t in 1:p, s in 1:n]
        ll_nb   = GLLVM.nb_marginal_loglik_laplace(Y, Λ, β, 1e6)     # r → ∞ ⇒ Poisson
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_nb ≈ ll_pois rtol = 1e-3
    end
end
