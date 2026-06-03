using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

@testset "Variational (VA) marginal — Negative Binomial" begin
    @testset "Λ=0 reduces to independent NB loglik (exact)" begin
        Random.seed!(300)
        p, K, n = 6, 2, 40
        r = 3.5
        β = 0.3 .* randn(p) .+ 1.0
        Y = [rand(NegativeBinomial(r, r / (r + exp(β[t])))) for t in 1:p, s in 1:n]
        va = GLLVM.nb_marginal_loglik_va(Y, zeros(p, K), β, r)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(NegativeBinomial(r, r / (r + exp(β[t]))), Y[t, s])
        end
        @test va ≈ ref atol = 1e-8
    end

    @testset "r→∞ NB-VA tends to the Poisson-VA marginal (K=1)" begin
        Random.seed!(301)
        p, n = 5, 20
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p), p, 1)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn()
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(β[t] + Λ[t, 1] * z)))
            end
        end
        va_nb  = GLLVM.nb_marginal_loglik_va(Y, Λ, β, 1e6)
        va_poi = GLLVM.poisson_marginal_loglik_va(Y, Λ, β)
        @test isapprox(va_nb, va_poi; atol = 1e-2)
    end

    @testset "ELBO is a lower bound on the exact marginal, and tight (K=1)" begin
        Random.seed!(302)
        p = 6
        r = 4.0
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p), p, 1)
        ztrue = randn()
        y = [rand(NegativeBinomial(r, r / (r + exp(β[t] + Λ[t, 1] * ztrue)))) for t in 1:p]
        Y = reshape(y, p, 1)
        va = GLLVM.nb_marginal_loglik_va(Y, Λ, β, r)

        # exact single-site marginal by dense quadrature
        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                μ = exp(β[t] + Λ[t, 1] * z)
                lp += logpdf(NegativeBinomial(r, r / (r + μ)), y[t])
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        quad = log(marg)

        @test va ≤ quad + 1e-4                  # ELBO ≤ log-marginal (Jensen / KL ≥ 0)
        @test isapprox(va, quad; atol = 0.3)    # and tight
    end

    @testset "analytic inner gradient matches central finite difference" begin
        Random.seed!(310)
        p, K = 5, 2
        r = 4.0
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p * K), p, K)
        Λ2 = Λ .^ 2
        y = [rand(NegativeBinomial(r, r / (r + exp(β[t])))) for t in 1:p]  # integer y
        x, w = GLLVM._gauss_hermite(20)
        f(ψ) = -GLLVM._va_site_negbin_elbo(ψ, y, Λ, Λ2, β, r, x, w)
        h = 1e-6
        for _ in 1:3
            ψ = 0.5 .* randn(2K)
            G = zeros(2K)
            GLLVM._va_site_negbin_grad!(G, ψ, y, Λ, Λ2, β, r, x, w)
            fd = zeros(2K)
            for i in 1:2K
                ψp = copy(ψ); ψp[i] += h
                ψm = copy(ψ); ψm[i] -= h
                fd[i] = (f(ψp) - f(ψm)) / (2h)
            end
            @test isapprox(G, fd; atol = 1e-5)
        end
    end

    @testset "fit_nb_gllvm_va — machinery" begin
        # Small NB2 GLLVM; assert the driver returns a well-formed fit and the
        # maximised ELBO does not sit below the no-LV bound at the fitted (β, r).
        Random.seed!(303)
        p, K, n = 5, 2, 100
        r = 4.0
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p * K), p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                μ = exp(β[t] + dot(Λ[t, :], z))
                Y[t, s] = rand(NegativeBinomial(r, r / (r + μ)))
            end
        end
        fit = GLLVM.fit_nb_gllvm_va(Y; K = K)
        @test fit isa GLLVM.NBFit
        @test isfinite(fit.loglik)
        @test fit.r > 0
        @test size(fit.Λ) == (p, K)
        @test fit.loglik ≥
              GLLVM.nb_marginal_loglik_va(Y, zeros(p, K), fit.β, fit.r) - 1e-3
    end
end
