using GLLVM, Test, Random, Distributions, Statistics

@testset "Variational (VA) marginal — Gamma" begin
    @testset "Λ=0 reduces to independent Gamma loglik (exact)" begin
        Random.seed!(310)
        p, K, n = 6, 2, 40
        α = 3.0
        β = 0.3 .* randn(p) .+ 0.5
        Y = [rand(Gamma(α, exp(β[t]) / α)) for t in 1:p, s in 1:n]
        va = GLLVM.gamma_marginal_loglik_va(Y, zeros(p, K), β, α)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += logpdf(Gamma(α, exp(β[t]) / α), Y[t, s])
        end
        @test va ≈ ref atol = 1e-8
    end

    @testset "ELBO is a lower bound on the exact marginal, and tight (K=1)" begin
        Random.seed!(311)
        p = 6
        α = 4.0
        β = 0.3 .* randn(p) .+ 0.5
        Λ = reshape(0.4 .* randn(p), p, 1)
        ztrue = randn()
        y = [rand(Gamma(α, exp(β[t] + Λ[t, 1] * ztrue) / α)) for t in 1:p]
        Y = reshape(y, p, 1)
        va = GLLVM.gamma_marginal_loglik_va(Y, Λ, β, α)

        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                μ = exp(β[t] + Λ[t, 1] * z)
                lp += logpdf(Gamma(α, μ / α), y[t])
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        quad = log(marg)

        @test va ≤ quad + 1e-4                  # ELBO ≤ log-marginal (Jensen / KL ≥ 0)
        @test isapprox(va, quad; atol = 0.3)    # and tight
    end
end
