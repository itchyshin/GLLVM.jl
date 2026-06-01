using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

function _rztnb(μ, r)
    nb = NegativeBinomial(r, r / (r + μ))
    k = rand(nb)
    while k == 0
        k = rand(nb)
    end
    return k
end

@testset "Hurdle-NB" begin
    @testset "Λ = 0 ⇒ exact independent hurdle-NB loglik" begin
        Random.seed!(170)
        p, K, n = 6, 2, 50
        βz = 0.4 .* randn(p) .+ 0.3; βc = log.(2 .+ abs.(randn(p))); r = 5.0
        π = inv.(1 .+ exp.(-βz)); μ = exp.(βc)
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = _rztnb(μ[t], r))
        end
        ll = GLLVM.hurdle_nb_marginal_loglik_laplace(Y, zeros(p, K), βz, βc, r)
        ref = 0.0
        for t in 1:p, s in 1:n
            if Y[t, s] > 0
                p0 = (r / (r + μ[t]))^r
                ref += log(π[t]) + logpdf(NegativeBinomial(r, r / (r + μ[t])), Y[t, s]) - log1p(-p0)
            else
                ref += log(1 - π[t])
            end
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "r → ∞ tends to the Hurdle-Poisson marginal" begin
        Random.seed!(171)
        p, K, n = 5, 1, 20
        βz = 0.4 .* randn(p); βc = log.(2 .+ abs.(randn(p))); Λc = 0.3 .* randn(p, K)
        μ = exp.(βc); π = inv.(1 .+ exp.(-βz))
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            if rand() < π[t]
                k = rand(Poisson(μ[t])); while k == 0; k = rand(Poisson(μ[t])); end
                Y[t, s] = k
            end
        end
        ll_nb = GLLVM.hurdle_nb_marginal_loglik_laplace(Y, Λc, βz, βc, 1e6)
        ll_pois = GLLVM.hurdle_poisson_marginal_loglik_laplace(Y, Λc, βz, βc)
        @test ll_nb ≈ ll_pois rtol = 1e-3
    end

    @testset "fit recovers + post-fit" begin
        Random.seed!(172)
        p, K, n = 8, 2, 400
        βz = 0.5 .* randn(p) .+ 0.5; βc = log.(3 .+ abs.(randn(p))); Λc = 0.4 .* randn(p, K)
        r_true = 6.0
        Z = randn(K, n); ηc = βc .+ Λc * Z; π = inv.(1 .+ exp.(-βz))
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = _rztnb(exp(ηc[t, s]), r_true))
        end
        fit = fit_hurdle_nb_gllvm(Y; K = K)
        @test fit isa HurdleNBFit
        @test fit.converged
        @test cor(fit.βz, βz) > 0.8
        @test cor(fit.βc, βc) > 0.7
        @test cor(vec(fit.Λc * fit.Λc'), vec(Λc * Λc')) > 0.6
        # r is only weakly identified alongside latent factors (both absorb
        # overdispersion); check a positive, finite, non-degenerate estimate.
        @test isfinite(fit.r) && fit.r > 0.5
        @test size(GLLVM.getLV(fit, Y; rotate = false)) == (n, K)
        @test all(GLLVM.predict(fit, Y; type = :response) .≥ 0)
        @test all(GLLVM.predict(fit, Y; type = :positive) .≥ 1)
        r = GLLVM.residuals(fit, Y; rng = MersenneTwister(3))
        @test all(isfinite, r)
        k = 2p + (p * K - div(K * (K - 1), 2)) + 1
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Hurdle-NB", s)
    end
end
