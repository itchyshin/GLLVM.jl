using GLLVM, Test, Random, Distributions, Statistics

@testset "Delta-Gamma family" begin
    @testset "Λ = 0 reduces to independent two-part loglik (exact)" begin
        Random.seed!(160)
        p, K, n = 6, 2, 50
        βz = 0.4 .* randn(p)                       # occurrence logits
        βc = 0.5 .* randn(p)                       # positive log-mean
        α = 3.0
        π = inv.(1 .+ exp.(-βz))
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            if rand() < π[t]
                μ = exp(βc[t])
                Y[t, s] = rand(Gamma(α, μ / α))
            end                                     # else stays 0 (absence)
        end

        ll = GLLVM.delta_gamma_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, α)
        ref = 0.0
        for t in 1:p, s in 1:n
            ref += Y[t, s] > 0 ? (log(π[t]) + logpdf(Gamma(α, exp(βc[t]) / α), Y[t, s])) :
                                 log(1 - π[t])
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "K = 1 single site ≈ quadrature" begin
        Random.seed!(161)
        p, K = 6, 1
        βz = 0.3 .* randn(p)
        βc = 0.5 .* randn(p)
        α = 4.0
        Λc = reshape(0.4 .* randn(p), p, 1)
        ztrue = randn()
        π = inv.(1 .+ exp.(-βz))
        y = zeros(p)
        for t in 1:p
            if rand() < π[t]
                μ = exp(βc[t] + Λc[t, 1] * ztrue)
                y[t] = rand(Gamma(α, μ / α))
            end
        end
        Y = reshape(y, p, 1)
        ll_lap = GLLVM.delta_gamma_marginal_loglik_laplace(Y, Λc, βz, βc, α)

        zs = range(-10, 10; length = 8001); dz = step(zs)
        marg = 0.0
        for z in zs
            lp = 0.0
            for t in 1:p
                πt = inv(1 + exp(-βz[t]))
                if y[t] > 0
                    μ = exp(βc[t] + Λc[t, 1] * z)
                    lp += log(πt) + logpdf(Gamma(α, μ / α), y[t])
                else
                    lp += log(1 - πt)
                end
            end
            marg += exp(lp) * pdf(Normal(), z) * dz
        end
        ll_quad = log(marg)
        # Gamma positive part is not Gaussian in η^c, so the Laplace carries an
        # O(curvature) error (here ≈0.17 nats) — loose tolerance, but it must track
        # the integral.
        @test ll_lap ≈ ll_quad atol = 0.3
    end

    @testset "fit_delta_gamma_gllvm recovers parameters" begin
        Random.seed!(162)
        p, K, n = 8, 2, 400
        βz_true = 0.5 .* randn(p) .+ 0.4          # occurrence logits (≈ 60% presence)
        βc_true = 0.5 .* randn(p)                 # positive log-mean
        Λc_true = 0.6 .* randn(p, K)
        α_true = 4.0
        Z = randn(K, n)
        ηc = βc_true .+ Λc_true * Z
        π = inv.(1 .+ exp.(-βz_true))
        Y = zeros(p, n)
        for t in 1:p, s in 1:n
            if rand() < π[t]
                μ = exp(ηc[t, s])
                Y[t, s] = rand(Gamma(α_true, μ / α_true))
            end
        end

        fit = fit_delta_gamma_gllvm(Y; K = K)
        @test fit isa DeltaGammaFit
        @test isfinite(fit.loglik)
        @test cor(fit.βz, βz_true) > 0.8                                  # occurrence recovers well
        @test cor(vec(fit.Λc * fit.Λc'), vec(Λc_true * Λc_true')) > 0.7   # loadings (Gram)
        # The positive-block intercept, and especially the Gamma shape α, are only
        # weakly recovered here: the Laplace marginal biases dispersion parameters
        # (the motivation for VA — see ROADMAP) and the method-of-moments α₀ is
        # biased low because it cannot net out the latent-variable variance. We
        # therefore check direction/sanity for these, not accuracy.
        @test cor(fit.βc, βc_true) > 0.4                                  # positive log-mean (weak)
        @test 0 < fit.α < 50                                              # shape: positive & finite

        # post-fit surface
        P = predict(fit, Y; type = :response)
        @test size(P) == (p, n)
        @test all(P .>= 0)
        occ = predict(fit, Y; type = :occurrence)
        @test all(0 .< occ .< 1)
        R = residuals(fit, Y; rng = MersenneTwister(1))
        @test size(R) == (p, n)
        @test abs(mean(R)) < 0.3                  # ≈ N(0,1) under correct model
        @test getLV(fit, Y) |> size == (n, K)
        @test isfinite(aic(fit)) && isfinite(bic(fit, n))
    end

    # VA-based Wald standard errors for the two-part Delta-Gamma (objective=:va):
    # extends the VA-SE path (previously GLM-only) to a two-part family.
    @testset "VA-based standard errors (objective=:va)" begin
        Random.seed!(808)
        p, K, n = 4, 1, 150
        βz = 0.5 .* randn(p) .+ 0.3
        βc = 0.3 .* randn(p)
        α  = 3.0
        Λc = 0.4 .* randn(p, K)
        Y = zeros(p, n)
        for s in 1:n
            ηc = βc .+ Λc * randn(K)
            for t in 1:p
                if rand() < inv(1 + exp(-βz[t]))
                    Y[t, s] = rand(Gamma(α, exp(ηc[t]) / α))
                end
            end
        end
        fit = fit_delta_gamma_gllvm(Y; K = K)

        ci_va = confint(fit, Y; method = :wald, objective = :va)
        ci_la = confint(fit, Y; method = :wald, objective = :laplace)
        nterm = 2p + (p * K - div(K * (K - 1), 2)) + 1     # βz + βc + Λc + α
        @test length(ci_va.term) == nterm
        @test ci_va.method == :wald
        for i in eachindex(ci_va.term)
            if isfinite(ci_va.lower[i]) && isfinite(ci_va.upper[i])
                @test ci_va.lower[i] ≤ ci_va.estimate[i] ≤ ci_va.upper[i]
            end
        end
        # Same point estimates as the Laplace path (both evaluated at the MLE θ).
        @test ci_va.term == ci_la.term
        @test ci_va.estimate ≈ ci_la.estimate
    end
end
