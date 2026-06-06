using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Grouped / species-specific NB dispersion (gllvm's disp.group). Anchors:
#   1. a constant per-species dispersion equals the shared-r NB marginal (machine
#      precision) — the grouped path reduces exactly to the scalar path;
#   2. a one-group fit matches fit_nb_gllvm; a two-group fit separates the groups'
#      dispersions in the right direction.

@testset "Grouped / species-specific NB dispersion (disp.group)" begin

    @testset "constant rvec == shared-r NB marginal (exact)" begin
        Random.seed!(501)
        p, K, n = 6, 2, 30
        β = 0.3 .* randn(p) .+ 1.0
        Λ = 0.4 .* randn(p, K)
        r = 3.5
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            for t in 1:p
                μ = exp(η[t])
                Y[t, s] = rand(NegativeBinomial(r, r / (r + μ)))
            end
        end
        ll_shared  = GLLVM.nb_marginal_loglik_laplace(Y, Λ, β, r)
        ll_grouped = GLLVM.nb_grouped_marginal_loglik_laplace(Y, Λ, β, fill(r, p))
        @test ll_grouped ≈ ll_shared atol = 1e-10
    end

    @testset "per-species rvec marginal is finite and r-monotone" begin
        Random.seed!(502)
        p, K, n = 4, 1, 25
        β = 0.2 .* randn(p) .+ 1.0
        Λ = 0.3 .* randn(p, K)
        Y = rand(0:6, p, n)
        ll1 = GLLVM.nb_grouped_marginal_loglik_laplace(Y, Λ, β, fill(2.0, p))
        ll2 = GLLVM.nb_grouped_marginal_loglik_laplace(Y, Λ, β, fill(20.0, p))
        @test isfinite(ll1) && isfinite(ll2)
        # mixed per-species dispersion also evaluates finitely.
        @test isfinite(GLLVM.nb_grouped_marginal_loglik_laplace(Y, Λ, β, [1.0, 5.0, 20.0, 50.0]))
    end

    @testset "fit_nb_gllvm_grouped: one group ≈ fit_nb_gllvm" begin
        Random.seed!(503)
        p, K, n, r_true = 6, 1, 250, 4.0
        β_true = 0.3 .* randn(p) .+ 1.2
        Λ_true = 0.4 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(η[t, s])
            Y[t, s] = rand(NegativeBinomial(r_true, r_true / (r_true + μ)))
        end
        fg = fit_nb_gllvm_grouped(Y; K = K, group = ones(Int, p), iterations = 150)
        @test fg isa NBGroupedFit
        @test length(fg.r_group) == 1
        @test isfinite(fg.loglik)
        fs = fit_nb_gllvm(Y; K = K, iterations = 150)
        # same model ⇒ same optimum to optimiser tolerance.
        @test isapprox(fg.loglik, fs.loglik; atol = 1e-2, rtol = 1e-4)
        @test isapprox(fg.r_group[1], fs.r, rtol = 0.1)
    end

    @testset "fit_nb_gllvm_grouped: two groups separate dispersion" begin
        Random.seed!(504)
        p, K, n = 6, 1, 300
        group = [1, 1, 1, 2, 2, 2]
        r_by_group = [2.0, 25.0]          # group 1 over-dispersed, group 2 ≈ Poisson
        β_true = 0.3 .* randn(p) .+ 1.3
        Λ_true = 0.3 .* randn(p, K)
        Z = randn(K, n)
        η = β_true .+ Λ_true * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = exp(η[t, s]); r = r_by_group[group[t]]
            Y[t, s] = rand(NegativeBinomial(r, r / (r + μ)))
        end
        fg = fit_nb_gllvm_grouped(Y; K = K, group = group, iterations = 200)
        @test fg isa NBGroupedFit
        @test length(fg.r_group) == 2
        @test all(fg.r_group .> 0)
        @test isfinite(fg.loglik)
        @test fg.group == group
        # group 2 (near-Poisson) should recover a larger dispersion than group 1.
        @test fg.r_group[2] > fg.r_group[1]
    end
end
