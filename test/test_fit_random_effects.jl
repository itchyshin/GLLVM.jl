using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff
using Distributions: Poisson, Binomial, NegativeBinomial

# SP1.1: Gaussian per-site random ROW effect via the augmented-constant-column trick
# (Σ_y += σ_row²·1ₚ1ₚᵀ), reusing the closed-form marginal unchanged.

@testset "Gaussian random row effect fit (SP1.1)" begin

    @testset "recovery of σ_row, σ_eps, ΛΛ'" begin
        Random.seed!(11001)
        p, K, n = 6, 2, 800
        Λtrue = 0.6 .* randn(p, K)
        σ_eps, σ_row = 0.5, 0.8
        Y = Λtrue * randn(K, n) .+ (σ_row .* randn(n))' .+ σ_eps .* randn(p, n)  # zero-mean
        fit = fit_gaussian_row_re(Y; K = K)
        @test fit.converged
        @test isapprox(fit.σ_row, σ_row; atol = 0.2)
        @test isapprox(fit.σ_eps, σ_eps; atol = 0.1)
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λtrue * Λtrue')) > 0.9   # ΛΛ' (rotation-invariant)
    end

    @testset "no row effect ⇒ σ_row shrinks toward 0" begin
        Random.seed!(11002)
        p, K, n = 5, 1, 600
        Λtrue = 0.7 .* randn(p, K)
        Y = Λtrue * randn(K, n) .+ 0.5 .* randn(p, n)               # NO row effect
        fit = fit_gaussian_row_re(Y; K = K, σ_row_init = 0.3)
        @test fit.σ_row < 0.2
    end

    @testset "augmented column reduces to plain marginal as σ_row→0" begin
        Random.seed!(11003)
        p, K, n = 4, 1, 200
        Λ = 0.6 .* randn(p, K); σ = 0.5
        Y = Λ * randn(K, n) .+ σ .* randn(p, n)
        ll_aug   = GLLVM.gaussian_marginal_loglik(Y, hcat(Λ, 1e-8 .* ones(p)), σ)
        ll_plain = GLLVM.gaussian_marginal_loglik(Y, Λ, σ)
        @test isapprox(ll_aug, ll_plain; rtol = 1e-6)
    end

    @testset "FD-gradient of the row-effect nll ≤ 1e-6" begin
        Random.seed!(11004)
        p, K, n = 5, 2, 150
        Λ0 = 0.5 .* randn(p, K); σ = 0.6
        Y = Λ0 * randn(K, n) .+ 0.4 .* randn(p, n) .+ (0.5 .* randn(n))'
        rr = GLLVM.rr_theta_len(p, K)
        ones_p = ones(p)
        nll = θ -> -GLLVM.gaussian_marginal_loglik(Y,
            hcat(GLLVM.unpack_lambda(θ[1:rr], p, K), exp(θ[rr + 2]) .* ones_p),
            exp(θ[rr + 1]))
        θ = vcat(GLLVM.pack_lambda(Λ0), log(σ), log(0.5))
        gad = ForwardDiff.gradient(nll, θ)
        h = 1e-6
        gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i]))
            tp = copy(θ); tp[i] += s
            tm = copy(θ); tm[i] -= s
            gfd[i] = (nll(tp) - nll(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end

@testset "Poisson random row effect fit (SP1.1 non-Gaussian)" begin

    @testset "recovery (σ_row, β, ΛΛ')" begin
        Random.seed!(12001)
        p, K, n = 5, 1, 800
        βt = log.([4.0, 5.0, 3.0, 6.0, 4.0]); Λt = 0.4 .* randn(p, K)
        σ_row = 0.5
        η = βt .+ Λt * randn(K, n) .+ (σ_row .* randn(n))'
        Y = [rand(Poisson(exp(clamp(η[t, i], -10, 10)))) for t in 1:p, i in 1:n]
        fit = fit_poisson_row_re(Y; K = K)
        @test fit.converged
        @test isapprox(fit.σ_row, σ_row; atol = 0.2)
        @test maximum(abs.(fit.β .- βt)) < 0.35
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λt * Λt')) > 0.6
    end

    @testset "no row effect ⇒ σ_row shrinks" begin
        Random.seed!(12002)
        p, K, n = 4, 1, 600
        βt = log.([4.0, 5.0, 3.0, 4.0]); Λt = 0.4 .* randn(p, K)
        η = βt .+ Λt * randn(K, n)
        Y = [rand(Poisson(exp(clamp(η[t, i], -10, 10)))) for t in 1:p, i in 1:n]
        fit = fit_poisson_row_re(Y; K = K, σ_row_init = 0.3)
        @test fit.σ_row < 0.25
    end

    @testset "FD-gradient of the row-effect nll ≤ 1e-6" begin
        Random.seed!(12003)
        p, K, n = 4, 1, 80
        βt = log.([4.0, 4.0, 3.0, 5.0]); Λt = 0.3 .* randn(p, K)
        η = βt .+ Λt * randn(K, n) .+ (0.5 .* randn(n))'
        Y = [rand(Poisson(exp(clamp(η[t, i], -10, 10)))) for t in 1:p, i in 1:n]
        rr = GLLVM.rr_theta_len(p, K)
        ones_p = ones(p)
        nll = θ -> -GLLVM.poisson_marginal_loglik_laplace(Y,
            hcat(GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), exp(θ[p + rr + 1]) .* ones_p),
            θ[1:p])
        θ = vcat(βt, GLLVM.pack_lambda(Λt), log(0.5))
        gad = ForwardDiff.gradient(nll, θ)
        h = 1e-6
        gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i]))
            tp = copy(θ); tp[i] += s
            tm = copy(θ); tm[i] -= s
            gfd[i] = (nll(tp) - nll(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end

@testset "Binomial random row effect fit (SP1.1)" begin
    @testset "recovery (σ_row, ΛΛ')" begin
        Random.seed!(13001)
        p, K, n, Ntri = 5, 1, 800, 12
        βt = [0.2, -0.5, 0.4, -0.3, 0.1]; Λt = 0.6 .* randn(p, K); σ_row = 0.6
        η = βt .+ Λt * randn(K, n) .+ (σ_row .* randn(n))'
        Nm = fill(Ntri, p, n)
        Y = [rand(Binomial(Ntri, 1 / (1 + exp(-clamp(η[t, i], -15, 15))))) for t in 1:p, i in 1:n]
        fit = fit_binomial_row_re(Y; K = K, N = Nm)
        @test fit.converged
        @test isapprox(fit.σ_row, σ_row; atol = 0.25)
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λt * Λt')) > 0.5
    end
    @testset "FD-gradient ≤ 1e-6" begin
        Random.seed!(13002)
        p, K, n, Ntri = 4, 1, 80, 10
        βt = [0.2, -0.3, 0.1, 0.0]; Λt = 0.5 .* randn(p, K)
        η = βt .+ Λt * randn(K, n) .+ (0.5 .* randn(n))'
        Nm = fill(Ntri, p, n)
        Y = [rand(Binomial(Ntri, 1 / (1 + exp(-clamp(η[t, i], -15, 15))))) for t in 1:p, i in 1:n]
        rr = GLLVM.rr_theta_len(p, K); ones_p = ones(p)
        nll = θ -> -GLLVM.binomial_marginal_loglik_laplace(Y, Nm,
            hcat(GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), exp(θ[p + rr + 1]) .* ones_p),
            θ[1:p], GLLVM.LogitLink())
        θ = vcat(βt, GLLVM.pack_lambda(Λt), log(0.5))
        gad = ForwardDiff.gradient(nll, θ); h = 1e-6; gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gfd[i] = (nll(tp) - nll(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end

@testset "NB random row effect fit (SP1.1)" begin
    @testset "recovery (σ_row, r, ΛΛ')" begin
        Random.seed!(14001)
        p, K, n = 5, 1, 800; rtrue = 8.0; σ_row = 0.5
        βt = log.([4.0, 5.0, 3.0, 6.0, 4.0]); Λt = 0.4 .* randn(p, K)
        η = βt .+ Λt * randn(K, n) .+ (σ_row .* randn(n))'
        Y = [rand(NegativeBinomial(rtrue, rtrue / (rtrue + exp(clamp(η[t, i], -10, 10))))) for t in 1:p, i in 1:n]
        fit = fit_nb_row_re(Y; K = K)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test isapprox(fit.σ_row, σ_row; atol = 0.3)
        @test 1.0 < fit.r < 100.0
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λt * Λt')) > 0.4
    end
    @testset "FD-gradient ≤ 1e-6" begin
        Random.seed!(14002)
        p, K, n = 4, 1, 80; rtrue = 8.0
        βt = log.([4.0, 4.0, 3.0, 5.0]); Λt = 0.3 .* randn(p, K)
        η = βt .+ Λt * randn(K, n) .+ (0.5 .* randn(n))'
        Y = [rand(NegativeBinomial(rtrue, rtrue / (rtrue + exp(clamp(η[t, i], -10, 10))))) for t in 1:p, i in 1:n]
        rr = GLLVM.rr_theta_len(p, K); ones_p = ones(p)
        nll = θ -> -GLLVM.nb_marginal_loglik_laplace(Y,
            hcat(GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), exp(θ[p + rr + 2]) .* ones_p),
            θ[1:p], exp(θ[p + rr + 1]))
        θ = vcat(βt, GLLVM.pack_lambda(Λt), log(8.0), log(0.5))
        gad = ForwardDiff.gradient(nll, θ); h = 1e-6; gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gfd[i] = (nll(tp) - nll(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end
