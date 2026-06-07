using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Direct (latent-free) CMP loglik over all (t,s): the Λ=0 reference.
_indep_compoisson_loglik(Y, β, ν) = sum(
    GLLVM.compoisson_logpdf(Y[t, s], β[t], ν)
    for t in axes(Y, 1), s in axes(Y, 2))

@testset "Conway-Maxwell-Poisson family" begin

    @testset "ν=1 ⇒ Poisson marginal (KEY ANCHOR)" begin
        Random.seed!(21)
        p, n, K = 4, 60, 1
        β = randn(p) .* 0.5 .+ 1.0          # log-rates around exp(1) ≈ 2.7
        Λ = reshape(0.6 .* randn(p), p, K)  # Λ ≠ 0
        # plausible Poisson-ish counts at η = β
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]

        cmp = GLLVM.compoisson_marginal_loglik_laplace(Y, Λ, β, 1.0)
        pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test isfinite(cmp)
        @test abs(cmp - pois) ≤ 1e-6
    end

    @testset "Λ=0 exact reduction (machine precision)" begin
        Random.seed!(22)
        p, n, K = 4, 60, 2
        β = randn(p) .* 0.4 .+ 0.8
        Λ0 = zeros(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        for ν in (0.7, 1.0, 1.5)
            lap = GLLVM.compoisson_marginal_loglik_laplace(Y, Λ0, β, ν)
            direct = _indep_compoisson_loglik(Y, β, ν)
            @test lap ≈ direct atol = 1e-8
        end
    end

    @testset "scalar logpdf: ν=1 matches Poisson; logZ=λ" begin
        for (y, η) in ((0, 0.5), (3, 1.2), (7, 2.0))
            λ = exp(η)
            @test GLLVM.compoisson_logpdf(y, η, 1.0) ≈ logpdf(Poisson(λ), y) atol = 1e-10
            @test GLLVM.compoisson_logz(η, 1.0) ≈ λ atol = 1e-8   # Z = e^λ at ν=1
        end
    end

    @testset "underdispersion smoke fit" begin
        Random.seed!(23)
        p, n, K = 4, 60, 1
        β = randn(p) .* 0.4 .+ 1.0
        Λtrue = reshape(0.7 .* randn(p), p, K)
        # CMP draws are hard; fit Poisson-generated data and check it runs and
        # ν̂ lands near 1 within a factor (these counts are exactly equidispersed).
        Z = randn(K, n)
        Y = [rand(Poisson(exp(β[t] + dot(Λtrue[t, :], Z[:, s])))) for t in 1:p, s in 1:n]

        fit = GLLVM.fit_compoisson_gllvm(Y; K = K, iterations = 40)
        @test isfinite(fit.loglik)
        @test fit.ν > 0
        @test 0.2 ≤ fit.ν ≤ 5.0                       # near 1 within a factor
        # loadings recovered up to sign/rotation: Gram correlation > 0.3
        g_true = vec(Λtrue * Λtrue')
        g_hat  = vec(fit.Λ * fit.Λ')
        @test abs(cor(g_true, g_hat)) > 0.3
    end
end
