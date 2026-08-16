using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

# zero-truncated Poisson draw
function _rztpois(μ)
    k = rand(Poisson(μ))
    while k == 0
        k = rand(Poisson(μ))
    end
    return k
end

@testset "Hurdle-Poisson" begin
    @testset "Λ = 0 ⇒ exact independent hurdle-Poisson loglik" begin
        Random.seed!(160)
        p, K, n = 6, 2, 50
        βz = 0.4 .* randn(p) .+ 0.3
        βc = log.(2 .+ abs.(randn(p)))
        π = inv.(1 .+ exp.(-βz)); μ = exp.(βc)
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = _rztpois(μ[t]))
        end
        ll = GLLVM.hurdle_poisson_marginal_loglik_laplace(Y, zeros(p, K), βz, βc)
        ref = 0.0
        for t in 1:p, s in 1:n
            if Y[t, s] > 0
                ref += log(π[t]) + logpdf(Poisson(μ[t]), Y[t, s]) - log1p(-exp(-μ[t]))
            else
                ref += log(1 - π[t])
            end
        end
        @test ll ≈ ref atol = 1e-8
    end

    @testset "fit recovers βz, βc, ΛΛ'" begin
        Random.seed!(161)
        p, K, n = 8, 2, 400
        βz = 0.5 .* randn(p) .+ 0.5
        βc = log.(3 .+ abs.(randn(p)))
        Λc = 0.4 .* randn(p, K)
        Z = randn(K, n); ηc = βc .+ Λc * Z; π = inv.(1 .+ exp.(-βz))
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = _rztpois(exp(ηc[t, s])))
        end
        fit = fit_hurdle_poisson_gllvm(Y; K = K)
        @test fit isa HurdlePoissonFit
        @test fit.converged
        @test cor(fit.βz, βz) > 0.8
        @test cor(fit.βc, βc) > 0.7
        @test cor(vec(fit.Λc * fit.Λc'), vec(Λc * Λc')) > 0.6
    end

    @testset "post-fit" begin
        Random.seed!(162)
        p, K, n = 6, 2, 150
        βz = 0.4 .* randn(p) .+ 0.5; βc = log.(3 .+ abs.(randn(p))); Λc = 0.4 .* randn(p, K)
        Z = randn(K, n); ηc = βc .+ Λc * Z; π = inv.(1 .+ exp.(-βz))
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = _rztpois(exp(ηc[t, s])))
        end
        fit = fit_hurdle_poisson_gllvm(Y; K = K)
        Zh = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Zh) == (n, K)
        for s in 1:n
            ẑ = GLLVM._twopart_mode(GLLVM.HurdlePoisson(), view(Y, :, s),
                                    zeros(p, K), fit.Λc, fit.βz, fit.βc)
            @test Zh[s, :] ≈ ẑ atol = 1e-7
        end
        @test GLLVM.rotation(fit)' * GLLVM.rotation(fit) ≈ I(K) atol = 1e-10
        @test all(GLLVM.predict(fit, Y; type = :response) .≥ 0)
        @test all(0 .< GLLVM.predict(fit, Y; type = :occurrence) .< 1)
        @test all(GLLVM.predict(fit, Y; type = :positive) .≥ 1)   # truncated mean ≥ 1
        @test GLLVM.fitted(fit, Y) == GLLVM.predict(fit, Y; type = :response)
        r = GLLVM.residuals(fit, Y; rng = MersenneTwister(2))
        @test all(isfinite, r)
        k = 2p + (p * K - div(K * (K - 1), 2))
        @test GLLVM._nparams(fit) == k
        @test GLLVM.aic(fit) ≈ 2k - 2 * fit.loglik
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("Hurdle-Poisson", s)
    end

    @testset "fit_gllvm reaches no-X Hurdle-Poisson via the HurdlePoisson() marker" begin
        Random.seed!(1608)
        p, K, n = 4, 1, 60
        βz_true = fill(-0.2, p)
        βc_true = log.(2 .+ abs.(randn(p)))
        Λc_true = 0.4 .* randn(p, K)
        π = inv.(1 .+ exp.(-βz_true))
        Z = randn(K, n)
        ηc = βc_true .+ Λc_true * Z
        Y = zeros(Int, p, n)
        for t in 1:p, s in 1:n
            rand() < π[t] && (Y[t, s] = _rztpois(exp(ηc[t, s])))
        end

        fit = fit_gllvm(Y; family = HurdlePoisson(), K = K, iterations = 40)
        @test fit isa HurdlePoissonFit
        @test isfinite(fit.loglik)
        direct = fit_hurdle_poisson_gllvm(Y; K = K, iterations = 40)
        @test fit.loglik ≈ direct.loglik atol = 1e-8

        # No-X `@formula` inherits the arm via the q == 0 fall-through.
        ff = gllvm(@formula(y ~ 1), Y, (; temp = randn(n));
                   family = HurdlePoisson(), K = K, iterations = 40)
        @test ff isa HurdlePoissonFit
        @test ff.loglik ≈ direct.loglik atol = 1e-8
    end
end
