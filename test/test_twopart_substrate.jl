using GLLVM, Test, Random, Distributions

@testset "Two-part substrate (Delta-lognormal)" begin
    @testset "Λ = 0 reduces to independent two-part loglik (exact)" begin
        Random.seed!(130)
        p, K, n = 6, 2, 50
        βz = 0.4 .* randn(p)                      # occurrence logits
        βc = 0.5 .* randn(p)                      # positive meanlog
        σ = 0.7
        π = inv.(1 .+ exp.(-βz))
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            if rand() < π[t]
                Y[t, s] = exp(βc[t] + σ * randn())
            end                                    # else stays 0 (absence)
        end

        ll = GLLVM.delta_lognormal_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, σ)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += Y[t, s] > 0 ? (log(π[t]) + logpdf(LogNormal(βc[t], σ), Y[t, s])) :
                                 log(1 - π[t])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "K = 1 single site ≈ quadrature (Laplace exact for Δ-lognormal)" begin
        Random.seed!(131)
        p, K = 6, 1
        βz = 0.3 .* randn(p)
        βc = 0.5 .* randn(p)
        σ = 0.6
        Λc = reshape(0.4 .* randn(p), p, 1)
        ztrue = randn()
        π = inv.(1 .+ exp.(-βz))
        y = zeros(p)
        for t in 1:p
            if rand() < π[t]
                y[t] = exp(βc[t] + Λc[t, 1] * ztrue + σ * randn())
            end
        end
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.delta_lognormal_marginal_loglik_laplace(Y, Λc, βz, βc, σ)

        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                πt = inv(1 + exp(-βz[t]))
                lp += y[t] > 0 ? (log(πt) + logpdf(LogNormal(βc[t] + Λc[t, 1] * z, σ), y[t])) :
                                 log(1 - πt)
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        # the positive part is Gaussian in log y ⇒ the Laplace is exact; only
        # quadrature grid error separates them.
        @test ll_lap ≈ ll_quad atol = 1e-3
    end
end
