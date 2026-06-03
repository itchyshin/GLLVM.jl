using GLLVM, Test, Random, Distributions, Statistics

@testset "Variational (VA) marginal — Beta" begin
    @testset "Λ=0 reduces to independent Beta loglik (exact)" begin
        Random.seed!(400)
        p, K, n = 6, 2, 40
        φ = 8.0
        β = 0.3 .* randn(p) .+ 0.2
        μ = [1.0 / (1.0 + exp(-β[t])) for t in 1:p]
        Y = [rand(Beta(μ[t] * φ, (1 - μ[t]) * φ)) for t in 1:p, s in 1:n]
        va = GLLVM.beta_marginal_loglik_va(Y, zeros(p, K), β, φ)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Beta(μ[t] * φ, (1 - μ[t]) * φ), Y[t, s])
        end
        @test va ≈ ref atol = 1e-8
    end

    @testset "analytic inner gradient matches central finite difference" begin
        Random.seed!(410)
        p, K = 5, 2
        φ = 10.0
        β = 0.3 .* randn(p) .+ 0.2
        Λ = reshape(0.4 .* randn(p * K), p, K)
        Λ2 = Λ .^ 2
        μ = [1.0 / (1.0 + exp(-β[t])) for t in 1:p]
        y = [rand(Beta(μ[t] * φ, (1 - μ[t]) * φ)) for t in 1:p]   # y ∈ (0,1)
        x, w = GLLVM._gauss_hermite(20)
        f(ψ) = -GLLVM._va_site_beta_elbo(ψ, y, Λ, Λ2, β, φ, x, w)
        h = 1e-6
        for _ in 1:3
            ψ = 0.5 .* randn(2K)
            G = zeros(2K)
            GLLVM._va_site_beta_grad!(G, ψ, y, Λ, Λ2, β, φ, x, w)
            fd = zeros(2K)
            for i in 1:2K
                ψp = copy(ψ); ψp[i] += h
                ψm = copy(ψ); ψm[i] -= h
                fd[i] = (f(ψp) - f(ψm)) / (2h)
            end
            @test isapprox(G, fd; atol = 1e-5)
        end
    end

    @testset "ELBO is a lower bound on the exact marginal, and tight (K=1)" begin
        Random.seed!(401)
        p = 6
        φ = 10.0
        β = 0.3 .* randn(p) .+ 0.2
        Λ = reshape(0.4 .* randn(p), p, 1)
        ztrue = randn()
        y = Vector{Float64}(undef, p)
        for t in 1:p
            μt = 1.0 / (1.0 + exp(-(β[t] + Λ[t, 1] * ztrue)))
            y[t] = rand(Beta(μt * φ, (1 - μt) * φ))
        end
        Y = reshape(y, p, 1)
        va = GLLVM.beta_marginal_loglik_va(Y, Λ, β, φ)

        # exact single-site marginal by dense quadrature over the latent z ~ N(0,1)
        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                μ = 1.0 / (1.0 + exp(-(β[t] + Λ[t, 1] * z)))
                lp += logpdf(Beta(μ * φ, (1 - μ) * φ), y[t])
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        quad = log(marg)

        @test va ≤ quad + 1e-4                  # ELBO ≤ log-marginal (Jensen / KL ≥ 0)
        @test isapprox(va, quad; atol = 0.3)    # and tight
    end
end
