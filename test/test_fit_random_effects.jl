using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff

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
