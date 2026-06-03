using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

logistic(x) = 1 / (1 + exp(-x))

@testset "Variational (VA) marginal — Binomial" begin
    @testset "Λ=0 reduces to independent Binomial loglik (exact)" begin
        # Bernoulli case (N ≡ 1): at Λ=0, σ²=0 ⇒ S = log(1+e^β) and the optimal
        # q is the prior (m=0, v=1, KL=0), so the ELBO equals the independent
        # Bernoulli loglik exactly.
        Random.seed!(300)
        p, K, n = 6, 2, 40
        β = 0.5 .* randn(p)
        N = ones(Int, p, n)
        Y = [rand(Bernoulli(logistic(β[t]))) ? 1 : 0 for t in 1:p, s in 1:n]
        va = GLLVM.binomial_marginal_loglik_va(Y, N, zeros(p, K), β)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Binomial(N[t, s], logistic(β[t])), Y[t, s])
        end
        @test va ≈ ref atol = 1e-8

        # Binomial case (N entries > 1): same exact reduction.
        Random.seed!(301)
        Nb = rand(3:8, p, n)
        Yb = [rand(Binomial(Nb[t, s], logistic(β[t]))) for t in 1:p, s in 1:n]
        vab = GLLVM.binomial_marginal_loglik_va(Yb, Nb, zeros(p, K), β)
        refb = 0.0
        for t in 1:p, s in 1:n
            refb += logpdf(Binomial(Nb[t, s], logistic(β[t])), Yb[t, s])
        end
        @test vab ≈ refb atol = 1e-8
    end

    @testset "ELBO is a lower bound on the exact marginal, and tight (K=1)" begin
        Random.seed!(302)
        p = 6
        β = 0.4 .* randn(p)
        Λ = reshape(0.6 .* randn(p), p, 1)
        N = rand(2:6, p)
        ztrue = randn()
        y = [rand(Binomial(N[t], logistic(β[t] + Λ[t, 1] * ztrue))) for t in 1:p]
        Y = reshape(y, p, 1)
        Nm = reshape(N, p, 1)
        va = GLLVM.binomial_marginal_loglik_va(Y, Nm, Λ, β)

        # exact single-site marginal by dense quadrature
        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                lp += logpdf(Binomial(N[t], logistic(β[t] + Λ[t, 1] * z)), y[t])
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        quad = log(marg)

        @test va ≤ quad + 1e-4               # ELBO ≤ log-marginal (Jensen / KL ≥ 0)
        @test isapprox(va, quad; atol = 0.3) # and tight
    end

    @testset "analytic inner gradient matches central finite difference" begin
        Random.seed!(310)
        p, K = 5, 2
        β = 0.4 .* randn(p)
        Λ = reshape(0.5 .* randn(p * K), p, K)
        Λ2 = Λ .^ 2
        N = rand(2:6, p)                              # N > 1 trials
        y = [rand(Binomial(N[t], logistic(β[t]))) for t in 1:p]
        xs, ws = GLLVM._gauss_hermite(20)
        f(ψ) = GLLVM._neg_elbo_site_binomial(ψ, y, N, Λ, Λ2, β, xs, ws)
        h = 1e-6
        for _ in 1:3
            ψ = 0.5 .* randn(2K)
            G = zeros(2K)
            GLLVM._va_site_binomial_grad!(G, ψ, y, N, Λ, Λ2, β, xs, ws)
            fd = zeros(2K)
            for i in 1:2K
                ψp = copy(ψ); ψp[i] += h
                ψm = copy(ψ); ψm[i] -= h
                fd[i] = (f(ψp) - f(ψm)) / (2h)
            end
            @test isapprox(G, fd; atol = 1e-5)
        end
    end

    @testset "envelope-theorem outer gradient matches finite difference" begin
        # At a warm start, the analytic outer gradient (envelope theorem, one inner
        # solve) must match a central FD of −binomial_marginal_loglik_va over θ.
        Random.seed!(320)
        p, K, n = 4, 2, 40
        β = 0.4 .* randn(p)
        Λ = reshape(0.5 .* randn(p * K), p, K)
        N = rand(2:6, p, n)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = rand(Binomial(N[t, s], logistic(β[t] + dot(Λ[t, :], z))))
            end
        end
        rr = GLLVM.rr_theta_len(p, K)
        θ = vcat(β, GLLVM.pack_lambda(Λ))
        xs, ws = GLLVM._gauss_hermite(20)

        # analytic outer gradient via one inner-solve pass
        βθ = θ[1:p]
        Λθ = GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        Λ2θ = Λθ .^ 2
        _, M, V = GLLVM._va_binomial_solve_all(Y, N, Λθ, Λ2θ, βθ, xs, ws)
        G = zeros(p + rr)
        GLLVM._va_binomial_outer_grad!(G, Y, N, Λθ, Λ2θ, βθ, M, V, xs, ws)

        # central FD of the objective −binomial_marginal_loglik_va
        f(θ) = -GLLVM.binomial_marginal_loglik_va(Y, N,
                    GLLVM.unpack_lambda(θ[(p + 1):end], p, K), θ[1:p])
        h = 1e-5
        fd = zeros(p + rr)
        for i in eachindex(θ)
            θp = copy(θ); θp[i] += h
            θm = copy(θ); θm[i] -= h
            fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test isapprox(G, fd; atol = 1e-3)
    end

    @testset "fit_binomial_gllvm_va — machinery" begin
        # Small Bernoulli GLLVM; assert the driver returns a well-formed fit and
        # the maximised ELBO does not sit below the no-LV bound at the fitted β.
        Random.seed!(303)
        p, K, n = 5, 2, 100
        β = 0.4 .* randn(p)
        Λ = reshape(0.5 .* randn(p * K), p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = rand(Bernoulli(logistic(β[t] + dot(Λ[t, :], z)))) ? 1 : 0
            end
        end
        Nm = ones(Int, p, n)
        fit = GLLVM.fit_binomial_gllvm_va(Y; K = K)
        @test fit isa GLLVM.BinomialFit
        @test isfinite(fit.loglik)
        @test size(fit.Λ) == (p, K)
        @test fit.loglik ≥
              GLLVM.binomial_marginal_loglik_va(Y, Nm, zeros(p, K), fit.β) - 1e-3
    end
end
