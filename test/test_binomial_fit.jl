using GLLVM, Test, Distributions, Random, LinearAlgebra, Statistics

@testset "fit_binomial_gllvm — recovery" begin
    Random.seed!(20)
    p, n, K = 6, 400, 1
    link = LogitLink()
    Λtrue = 1.2 .* randn(p, K)
    βtrue = 0.4 .* randn(p)
    Z = randn(K, n)
    η = βtrue .+ Λtrue * Z                      # p×n linear predictor
    P = 1 ./ (1 .+ exp.(-η))
    Y = Int.(rand(p, n) .< P)                   # Bernoulli draws

    fit = fit_binomial_gllvm(Y; K = K, link = link)

    @test fit.converged
    @test isfinite(fit.loglik)
    @test size(fit.Λ) == (p, K)
    @test length(fit.β) == p

    # the latent structure is detected: the fitted K=1 model beats the Λ=0
    # (independent-binomial) marginal at the same intercepts
    ll0 = GLLVM.binomial_marginal_loglik_laplace(Y, fill(1, p, n), zeros(p, K), fit.β, link)
    @test fit.loglik > ll0

    # rotation/sign-invariant recovery of the shared structure ΛΛ' (rank-1)
    M̂ = fit.Λ * fit.Λ'
    Mt = Λtrue * Λtrue'
    @test cor(vec(M̂), vec(Mt)) > 0.7

    # intercepts recover (β is identifiable)
    @test cor(fit.β, βtrue) > 0.7

    # probit link also fits + converges
    fit_p = fit_binomial_gllvm(Y; K = K, link = ProbitLink())
    @test fit_p.converged && isfinite(fit_p.loglik)
end
