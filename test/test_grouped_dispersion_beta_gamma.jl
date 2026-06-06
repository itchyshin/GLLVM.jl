using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra

# Grouped / species-specific dispersion for Beta (precision φ) and Gamma (shape α),
# mirroring the NB disp.group path. Anchors:
#   1. EXACT REDUCTION: a constant per-species dispersion equals the shared-dispersion
#      scalar marginal to machine precision — the grouped path reduces exactly;
#   2. a one-group fit runs, is finite, and its single dispersion ≈ the scalar fit's;
#   3. a per-species (group = 1:p) smoke fit runs and returns a positive length-G vector.

@testset "Grouped / species-specific Beta & Gamma dispersion (disp.group)" begin

    @testset "Beta: constant φvec == shared-φ marginal (exact)" begin
        Random.seed!(601)
        p, K, n = 5, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        φ = 8.0
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            μ = 1 ./ (1 .+ exp.(-η))
            for t in 1:p
                Y[t, s] = rand(Beta(μ[t] * φ, (1 - μ[t]) * φ))
            end
        end
        ll_shared  = GLLVM.beta_marginal_loglik_laplace(Y, Λ, β, φ)
        ll_grouped = GLLVM.beta_grouped_marginal_loglik_laplace(Y, Λ, β, fill(φ, p))
        @test ll_grouped ≈ ll_shared atol = 1e-10
        # mixed per-species precision also evaluates finitely.
        @test isfinite(GLLVM.beta_grouped_marginal_loglik_laplace(Y, Λ, β, [4.0, 8.0, 12.0, 20.0, 30.0]))
    end

    @testset "Gamma: constant αvec == shared-α marginal (exact)" begin
        Random.seed!(602)
        p, K, n = 5, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        α = 3.0
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(K)
            μ = exp.(η)
            for t in 1:p
                Y[t, s] = rand(Gamma(α, μ[t] / α))
            end
        end
        ll_shared  = GLLVM.gamma_marginal_loglik_laplace(Y, Λ, β, α)
        ll_grouped = GLLVM.gamma_grouped_marginal_loglik_laplace(Y, Λ, β, fill(α, p))
        @test ll_grouped ≈ ll_shared atol = 1e-10
        # mixed per-species shape also evaluates finitely.
        @test isfinite(GLLVM.gamma_grouped_marginal_loglik_laplace(Y, Λ, β, [1.5, 3.0, 5.0, 8.0, 12.0]))
    end

    @testset "fit_beta_gllvm_grouped: one group ≈ fit_beta_gllvm" begin
        Random.seed!(603)
        p, K, n = 5, 1, 80
        βtrue = 0.4 .* randn(p)
        Λtrue = 0.4 .* randn(p, K)
        φtrue = 12.0
        Z = randn(K, n)
        η = βtrue .+ Λtrue * Z
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Beta(μ[t, i] * φtrue, (1 - μ[t, i]) * φtrue)) for t in 1:p, i in 1:n]

        fg = fit_beta_gllvm_grouped(Y; K = K, group = ones(Int, p), iterations = 40)
        @test fg isa GLLVM.BetaGroupedFit
        @test length(fg.φ) == 1
        @test all(fg.φ .> 0)
        @test isfinite(fg.loglik)
        fs = fit_beta_gllvm(Y; K = K, iterations = 40)
        # one shared group ⇒ same precision to within ~20%.
        @test isapprox(fg.φ[1], fs.φ; rtol = 0.2)
    end

    @testset "fit_gamma_gllvm_grouped: one group ≈ fit_gamma_gllvm" begin
        Random.seed!(604)
        p, K, n = 5, 1, 80
        βtrue = 0.4 .* randn(p)
        Λtrue = 0.4 .* randn(p, K)
        αtrue = 4.0
        Z = randn(K, n)
        η = βtrue .+ Λtrue * Z
        μ = exp.(η)
        Y = [rand(Gamma(αtrue, μ[t, i] / αtrue)) for t in 1:p, i in 1:n]

        fg = fit_gamma_gllvm_grouped(Y; K = K, group = ones(Int, p), iterations = 40)
        @test fg isa GLLVM.GammaGroupedFit
        @test length(fg.α) == 1
        @test all(fg.α .> 0)
        @test isfinite(fg.loglik)
        fs = fit_gamma_gllvm(Y; K = K, iterations = 40)
        # one shared group ⇒ same shape to within ~20%.
        @test isapprox(fg.α[1], fs.α; rtol = 0.2)
    end

    @testset "fit_beta_gllvm_grouped: per-species smoke (group = 1:p)" begin
        Random.seed!(605)
        p, K, n = 4, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        Z = randn(K, n)
        η = β .+ Λ * Z
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Beta(μ[t, i] * 10.0, (1 - μ[t, i]) * 10.0)) for t in 1:p, i in 1:n]

        fg = fit_beta_gllvm_grouped(Y; K = K, iterations = 40)  # default group = 1:p
        @test fg isa GLLVM.BetaGroupedFit
        @test length(fg.φ) == p
        @test all(fg.φ .> 0)
        @test isfinite(fg.loglik)
        @test fg.group == collect(1:p)
    end

    @testset "fit_gamma_gllvm_grouped: per-species smoke (group = 1:p)" begin
        Random.seed!(606)
        p, K, n = 4, 1, 60
        β = 0.3 .* randn(p)
        Λ = 0.4 .* randn(p, K)
        Z = randn(K, n)
        η = β .+ Λ * Z
        μ = exp.(η)
        Y = [rand(Gamma(3.0, μ[t, i] / 3.0)) for t in 1:p, i in 1:n]

        fg = fit_gamma_gllvm_grouped(Y; K = K, iterations = 40)  # default group = 1:p
        @test fg isa GLLVM.GammaGroupedFit
        @test length(fg.α) == p
        @test all(fg.α .> 0)
        @test isfinite(fg.loglik)
        @test fg.group == collect(1:p)
    end
end
