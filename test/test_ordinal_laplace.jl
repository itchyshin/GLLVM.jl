using GLLVM, Test, Random, Distributions

@testset "Ordinal Laplace marginal" begin
    @testset "Λ = 0 reduces to independent cumulative-logit loglik (exact)" begin
        Random.seed!(120)
        p, K, n = 5, 2, 60
        C = 4
        τ = [-1.0, 0.0, 1.2]                              # C−1 ordered cutpoints
        probs = [GLLVM._ord_prob(c, 0.0, τ) for c in 1:C]
        Y = [rand(Categorical(probs)) for t in 1:p, s in 1:n]

        ll = GLLVM.ordinal_marginal_loglik_laplace(Y, zeros(p, K), τ)
        F(x) = 1 / (1 + exp(-x))
        function logp(c)
            hi = c == C ? 1.0 : F(τ[c])
            lo = c == 1 ? 0.0 : F(τ[c - 1])
            return log(hi - lo)
        end
        ll_indep = sum(logp(Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "K = 1 single site ≈ numerical quadrature" begin
        Random.seed!(121)
        p, C = 6, 4
        τ = [-1.0, 0.2, 1.5]
        Λ = reshape(0.5 .* randn(p), p, 1)
        ztrue = randn()
        Y = Vector{Int}(undef, p)
        for t in 1:p
            pr = [GLLVM._ord_prob(c, Λ[t, 1] * ztrue, τ) for c in 1:C]
            Y[t] = rand(Categorical(pr))
        end
        Ym = reshape(Y, p, 1)
        ll_lap = GLLVM.ordinal_marginal_loglik_laplace(Ym, Λ, τ)

        zs = range(-8, 8; length = 4001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                lp += log(GLLVM._ord_prob(Y[t], Λ[t, 1] * z, τ))
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        # Fisher-information Laplace (cumulative logit) — loose tol.
        @test ll_lap ≈ ll_quad atol = 0.5
    end
end
