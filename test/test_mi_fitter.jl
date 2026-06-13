using GLLVM, Test, LinearAlgebra, Random, Statistics, Distributions

# User-facing fitter fit_gllvm_mi for the non-Gaussian missing predictor: wraps
# the AD-clean augmented-Laplace marginal in L-BFGS. Recovery under MAR (the
# statistical payoff: FIML uses the missing-x sites, complete-case deletion does
# not). Identifiability mirrors the Gaussian case — x must be observed at enough
# sites to anchor (b_x, μ_x, σ_x); MAR missingness on a trait keeps that.
@testset "fit_gllvm_mi (non-Gaussian missing-predictor fitter)" begin

    function sim_pois(seed)
        p, n, K = 6, 500, 1
        Random.seed!(seed)
        β = [0.3, 0.6, 0.1, 0.4, -0.2, 0.5]
        Λ = reshape([0.4, 0.3, -0.3, 0.25, 0.2, -0.2], p, K)
        b_x_true, μ_x, σ_x = 0.6, 0.3, 0.6
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x_true .* x' .+ Λ * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]
        y1 = Y[1, :]
        pmiss = 1 ./ (1 .+ exp.(-(-0.5 .+ 1.5 .* (y1 .- mean(y1)) ./ std(y1))))  # MAR on a trait
        Random.seed!(1000 + seed)
        miss = rand(n) .< pmiss
        xm = Vector{Union{Missing,Float64}}(x)
        xm[miss] .= missing
        return Y, x, xm, miss, b_x_true, μ_x, K
    end

    @testset "Poisson: recovers b_x under MAR" begin
        Y, x, xm, miss, b_x_true, μ_x, K = sim_pois(7)
        res = fit_gllvm_mi(Poisson(), Y, xm; K = K)
        @test res.converged
        @test abs(res.b_x - b_x_true) < 0.15            # FIML recovers b_x
        @test abs(res.μ_x - μ_x) < 0.1
    end

    # Heavy MC: FIML beats complete-case deletion under MAR (on average).
    if get(ENV, "GLLVM_SLOW_TESTS", "") == "1"
        @testset "FIML beats complete-case deletion under MAR (MC)" begin
            bf = Float64[]
            bc = Float64[]
            for s in 1:12
                Y, x, xm, miss, b_x_true, _, K = sim_pois(s)
                push!(bf, fit_gllvm_mi(Poisson(), Y, xm; K = K).b_x)
                push!(bc, fit_gllvm_mi(Poisson(), Y[:, .!miss], x[.!miss]; K = K).b_x)
            end
            @test abs(mean(bf) - 0.6) < 0.03                     # FIML ~unbiased
            @test mean(abs.(bc .- 0.6)) > mean(abs.(bf .- 0.6))  # complete-case more biased
        end
    end

    @testset "Binomial: fits and recovers b_x (complete data)" begin
        Random.seed!(8)
        p, n, K = 5, 400, 1
        Ntri = 12
        β = [0.2, -0.3, 0.4, 0.0, 0.3]
        Λ = reshape([0.4, 0.3, -0.3, 0.25, 0.2], p, K)
        b_x_true, μ_x, σ_x = 0.7, 0.3, 0.7
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x_true .* x' .+ Λ * randn(K, n)
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Binomial(Ntri, μ[t, s])) for t in 1:p, s in 1:n]
        N = fill(Ntri, p, n)
        res = fit_gllvm_mi(Binomial(), Y, x; K = K, N = N)
        @test res.converged
        @test abs(res.b_x - b_x_true) < 0.2
    end
end
