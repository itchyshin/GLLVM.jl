using GLLVM, Test, Random, Distributions, Statistics

# Post-fit completeness: aic/bic for the recently-added fit types. The generic
# aic(fit) / bic(fit, n) (src/postfit.jl) dispatch on the internal accessors
# _loglik(fit) and _nparams(fit); a fit type only supports them once both are
# defined. This file builds a tiny fit per type, then asserts aic/bic are finite
# and _nparams matches the expected free-parameter count.
#
# Expected free-parameter counts (matching the existing families' convention,
# with the loadings df = GLLVM.rr_theta_len(p, K)):
#   grouped fits:    p + rr_theta_len(p,K) + G          (one dispersion per group)
#   Tweedie-grouped: p + rr_theta_len(p,K) + G + 1      (+ the shared power)
#   Gaussian-pervar: p + rr_theta_len(p,K) + p          (one variance per species)

@testset "aic/bic for recently-added fit types" begin

    @testset "NBGroupedFit (two groups)" begin
        Random.seed!(9001)
        p, K, n = 4, 1, 60
        group = [1, 1, 2, 2]
        β = 0.3 .* randn(p) .+ 1.0
        Λ = 0.3 .* randn(p, K)
        Z = randn(K, n)
        η = β .+ Λ * Z
        r_by_group = [2.0, 20.0]
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(η[t, s]); r = r_by_group[group[t]]
            Y[t, s] = rand(NegativeBinomial(r, r / (r + μ)))
        end
        fit = fit_nb_gllvm_grouped(Y; K = K, group = group, iterations = 30)
        G = length(fit.r_group)
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        @test GLLVM._nparams(fit) == p + GLLVM.rr_theta_len(p, K) + G
    end

    @testset "BetaGroupedFit (per-species, G = p)" begin
        Random.seed!(9002)
        p, K, n = 4, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        η = β .+ Λ * randn(K, n)
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Beta(μ[t, i] * 10.0, (1 - μ[t, i]) * 10.0)) for t in 1:p, i in 1:n]
        fit = fit_beta_gllvm_grouped(Y; K = K, iterations = 30)   # default group = 1:p
        G = length(fit.φ)
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        @test GLLVM._nparams(fit) == p + GLLVM.rr_theta_len(p, K) + G
    end

    @testset "GammaGroupedFit (per-species, G = p)" begin
        Random.seed!(9003)
        p, K, n = 4, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        η = β .+ Λ * randn(K, n)
        μ = exp.(η)
        Y = [rand(Gamma(3.0, μ[t, i] / 3.0)) for t in 1:p, i in 1:n]
        fit = fit_gamma_gllvm_grouped(Y; K = K, iterations = 30)
        G = length(fit.α)
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        @test GLLVM._nparams(fit) == p + GLLVM.rr_theta_len(p, K) + G
    end

    @testset "NB1GroupedFit (per-species, G = p)" begin
        Random.seed!(9004)
        p, K, n = 4, 1, 50
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.0
        η = β .+ Λ * randn(K, n)
        μ = exp.(η)
        Y = [rand(NegativeBinomial(μ[t, i] / φtrue, 1 / (1 + φtrue))) for t in 1:p, i in 1:n]
        fit = fit_nb1_gllvm_grouped(Y; K = K, iterations = 30)
        G = length(fit.φ)
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        @test GLLVM._nparams(fit) == p + GLLVM.rr_theta_len(p, K) + G
    end

    @testset "TweedieGroupedFit (per-species, G = p; + shared power)" begin
        Random.seed!(9005)
        p, K, n = 3, 1, 40
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.2
        power = 1.5
        Y = Matrix{Float64}(undef, p, n)
        for i in 1:n
            ηv = β .+ Λ * randn(K)
            μ = exp.(ηv)
            for t in 1:p
                λ = μ[t]^(2 - power) / (φtrue * (2 - power))
                Npois = rand(Poisson(λ))
                if Npois == 0
                    Y[t, i] = 0.0
                else
                    shape = (2 - power) / (power - 1)
                    scale = φtrue * (power - 1) * μ[t]^(power - 1)
                    Y[t, i] = sum(rand(Gamma(shape, scale)) for _ in 1:Npois)
                end
            end
        end
        fit = fit_tweedie_gllvm_grouped(Y; K = K, iterations = 20)
        G = length(fit.φ)
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        @test GLLVM._nparams(fit) == p + GLLVM.rr_theta_len(p, K) + G + 1
    end

    @testset "GaussianPerVarFit (one variance per species)" begin
        Random.seed!(9006)
        p, K, n = 4, 1, 60
        β_true = randn(p)
        Λ_true = 0.6 .* randn(p, K)
        φ²_true = collect(range(0.2, 2.0; length = p))
        z = randn(K, n)
        Y = Λ_true * z .+ reshape(β_true, p, 1)
        for t in 1:p
            Y[t, :] .+= sqrt(φ²_true[t]) .* randn(n)
        end
        fit = GLLVM.fit_gaussian_pervar_gllvm(Y; K = K, iterations = 80)
        @test isfinite(aic(fit))
        @test isfinite(bic(fit, n))
        @test GLLVM._nparams(fit) == p + GLLVM.rr_theta_len(p, K) + p
    end

end
