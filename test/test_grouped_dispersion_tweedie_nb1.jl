using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Grouped / species-specific dispersion for NB1 (linear-variance φ) and Tweedie
# (dispersion φ, SHARED power), completing the per-species-dispersion set. Anchors:
#   1. EXACT REDUCTION: a constant per-species dispersion equals the shared-dispersion
#      scalar marginal to machine precision — the grouped path reduces exactly. This
#      is a single cheap marginal eval (NO fit).
#   2. ONE tiny per-species smoke fit each, asserting finite loglik + a positive
#      length-G dispersion vector. Tweedie's marginal is expensive, so the Tweedie
#      smoke fit is kept very small and run ONCE only.

@testset "Grouped / species-specific NB1 & Tweedie dispersion (disp.group)" begin

    @testset "NB1: constant φvec == shared-φ marginal (exact)" begin
        Random.seed!(701)
        p, K, n = 5, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        φ = 1.5
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            μ = exp.(η)
            for t in 1:p
                # NB1: r = μ/φ, success prob = 1/(1+φ)
                Y[t, s] = rand(NegativeBinomial(μ[t] / φ, 1 / (1 + φ)))
            end
        end
        ll_shared  = GLLVM.nb1_marginal_loglik_laplace(Y, Λ, β, φ)
        ll_grouped = GLLVM.nb1_grouped_marginal_loglik_laplace(Y, Λ, β, fill(φ, p))
        @test ll_grouped ≈ ll_shared atol = 1e-10
        # mixed per-species dispersion also evaluates finitely.
        @test isfinite(GLLVM.nb1_grouped_marginal_loglik_laplace(Y, Λ, β, [0.5, 1.0, 1.5, 2.0, 3.0]))
    end

    @testset "Tweedie: constant φvec == shared-φ marginal (exact)" begin
        Random.seed!(702)
        p, K, n = 4, 1, 40
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φ = 1.2
        power = 1.5
        # Crude compound Poisson–Gamma draws ≥ 0 with a point mass at 0.
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            μ = exp.(η)
            for t in 1:p
                λ = μ[t]^(2 - power) / (φ * (2 - power))
                Npois = rand(Poisson(λ))
                if Npois == 0
                    Y[t, s] = 0.0
                else
                    shape = (2 - power) / (power - 1)
                    scale = φ * (power - 1) * μ[t]^(power - 1)
                    Y[t, s] = sum(rand(Gamma(shape, scale)) for _ in 1:Npois)
                end
            end
        end
        # Same FIXED power passed to both — the key cheap correctness check.
        ll_shared  = GLLVM.tweedie_marginal_loglik_laplace(Y, Λ, β, φ, power)
        ll_grouped = GLLVM.tweedie_grouped_marginal_loglik_laplace(Y, Λ, β, fill(φ, p), power)
        @test ll_grouped ≈ ll_shared atol = 1e-10
        # mixed per-species dispersion also evaluates finitely.
        @test isfinite(GLLVM.tweedie_grouped_marginal_loglik_laplace(Y, Λ, β, [0.8, 1.2, 1.5, 2.0], power))
    end

    @testset "fit_nb1_gllvm_grouped: per-species smoke (group = 1:p)" begin
        Random.seed!(703)
        p, K, n = 4, 1, 50
        β = 0.3 .* randn(p)
        Λ = 0.3 .* randn(p, K)
        φtrue = 1.0
        Z = randn(K, n)
        η = β .+ Λ * Z
        μ = exp.(η)
        Y = [rand(NegativeBinomial(μ[t, i] / φtrue, 1 / (1 + φtrue))) for t in 1:p, i in 1:n]

        fg = fit_nb1_gllvm_grouped(Y; K = K, iterations = 40)  # default group = 1:p
        @test fg isa GLLVM.NB1GroupedFit
        @test length(fg.φ) == p
        @test all(fg.φ .> 0)
        @test isfinite(fg.loglik)
        @test fg.group == collect(1:p)
    end

    @testset "fit_tweedie_gllvm_grouped: tiny per-species smoke (group = 1:p)" begin
        Random.seed!(704)
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

        # ONE small Tweedie fit only — keep CI cheap.
        fg = fit_tweedie_gllvm_grouped(Y; K = K, iterations = 25)  # default group = 1:p
        @test fg isa GLLVM.TweedieGroupedFit
        @test length(fg.φ) == p
        @test all(fg.φ .> 0)
        @test isfinite(fg.loglik)
        @test 1.0 ≤ fg.power ≤ 2.0
        @test fg.group == collect(1:p)
    end
end
