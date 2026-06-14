using GLLVM, Test, LinearAlgebra, Random, Statistics, Distributions, ForwardDiff

# Non-Gaussian missing predictor (mi() Track T2): extend the augmented-(z,x)
# Laplace from the canonical families (Poisson/log, Binomial/logit) to the
# DISPERSION families NegativeBinomial (NB2/log), Gamma (log), Beta (logit).
# Each carries its dispersion (r / α / φ) through the packed θ as log-dispersion,
# and the non-canonical implicit step uses the OBSERVED Hessian weight (the
# log-det uses the Fisher weight) exactly as in src/laplace_grad.jl. The verification
# gates mirror test_missing_predictor_poisson.jl / test_mi_fitter.jl:
#   1. AD-vs-FD ≤ 1e-6 on the packed mi() objective (with dispersion in θ).
#   2. The missing-site marginal ≈ a 2-D Gauss–Hermite quadrature of the true
#      ∫∫ p(y|z,x) N(z;0,1) N(x;μ_x,σ_x²) dz dx (Laplace tolerance).
#   3. Recovery: under MAR, fit recovers b_x near truth and beats complete-case.

# ---------------------------------------------------------------------------
# NegativeBinomial (NB2, log link)
# ---------------------------------------------------------------------------
@testset "non-Gaussian missing predictor (NegativeBinomial, augmented Laplace)" begin
    r_true = 4.0

    @testset "missing-site marginal matches 2-D Gauss–Hermite quadrature" begin
        Random.seed!(102)
        p, K = 5, 1
        β = randn(p) .* 0.3
        Λ = reshape([0.4, 0.3, -0.25, 0.3, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        y = [rand(NegativeBinomial(r_true, r_true / (r_true + 2.0))) for _ in 1:p]
        N = ones(Int, p)
        ll_lap = GLLVM.laplace_loglik_site_xs(NegativeBinomial(r_true, 0.5), y, N, Λ, β, LogLink();
                                              x_obs = nothing, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        nodes, wts = GLLVM._gauss_hermite(90)
        zz = sqrt(2) .* nodes; wz = wts ./ sqrt(π)
        xx = μ_x .+ sqrt(2) * σ_x .* nodes; wx = wts ./ sqrt(π)
        acc = 0.0
        for (zi, wzi) in zip(zz, wz), (xi, wxi) in zip(xx, wx)
            μq = exp.(β .+ b_x * xi .+ Λ[:, 1] .* zi)
            ll = sum(logpdf(NegativeBinomial(r_true, r_true / (r_true + μq[t])), y[t]) for t in 1:p)
            acc += wzi * wxi * exp(ll)
        end
        @test ll_lap ≈ log(acc) rtol = 4e-2
    end

    @testset "packed marginal is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(103)
        p, n, K = 5, 60, 1
        β0 = randn(p) .* 0.3
        Λ0 = reshape([0.4, 0.3, -0.25, 0.3, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        x = μ_x .+ σ_x .* randn(n)
        ηd = β0 .+ b_x .* x' .+ Λ0 * randn(K, n)
        μd = exp.(ηd)
        Y = [rand(NegativeBinomial(r_true, r_true / (r_true + μd[t, s]))) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        xm = Vector{Union{Missing,Float64}}(x); xm[[3, 11, 25, 40]] .= missing
        # θ = [β (p); vec(Λ) (p*K); b_x; μ_x; log σ_x²; log r]
        function f(θ)
            β = θ[1:p]
            Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
            bx = θ[p + p * K + 1]; mx = θ[p + p * K + 2]; sx2 = exp(θ[p + p * K + 3])
            r = exp(θ[p + p * K + 4])
            GLLVM.marginal_loglik_laplace_xs(NegativeBinomial(r, 0.5), Y, N, Λ, β, LogLink();
                                             x = xm, b_x = bx, μ_x = mx, σ_x2 = sx2)
        end
        θ = vcat(β0, vec(Λ0), b_x, μ_x, log(σ_x^2), log(r_true))
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6; g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θm = copy(θ); θp[i] += h; θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end

    @testset "fit recovers b_x under MAR and beats complete-case" begin
        Random.seed!(104)
        p, n, K = 6, 600, 1
        β = [0.3, 0.6, 0.1, 0.4, -0.2, 0.5]
        Λ = reshape([0.4, 0.3, -0.3, 0.25, 0.2, -0.2], p, K)
        b_x_true, μ_x, σ_x = 0.6, 0.3, 0.6
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x_true .* x' .+ Λ * randn(K, n)
        μ = exp.(η)
        Y = [rand(NegativeBinomial(r_true, r_true / (r_true + μ[t, s]))) for t in 1:p, s in 1:n]
        y1 = Float64.(Y[1, :])
        pmiss = 1 ./ (1 .+ exp.(-(-0.5 .+ 1.5 .* (y1 .- mean(y1)) ./ std(y1))))
        Random.seed!(2104)
        miss = rand(n) .< pmiss
        xm = Vector{Union{Missing,Float64}}(x); xm[miss] .= missing
        res = fit_gllvm_mi(NegativeBinomial(), Y, xm; K = K)
        @test res.converged
        @test abs(res.b_x - b_x_true) < 0.2
        res_cc = fit_gllvm_mi(NegativeBinomial(), Y[:, .!miss], x[.!miss]; K = K)
        @test abs(res.b_x - b_x_true) ≤ abs(res_cc.b_x - b_x_true) + 0.05
    end
end

# ---------------------------------------------------------------------------
# Gamma (log link)
# ---------------------------------------------------------------------------
@testset "non-Gaussian missing predictor (Gamma, augmented Laplace)" begin
    α_true = 3.0

    @testset "missing-site marginal matches 2-D Gauss–Hermite quadrature" begin
        Random.seed!(202)
        p, K = 5, 1
        β = randn(p) .* 0.3
        Λ = reshape([0.4, 0.3, -0.25, 0.3, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        μ0 = exp.(β .+ b_x * μ_x)
        y = [rand(Gamma(α_true, μ0[t] / α_true)) for t in 1:p]
        N = ones(Int, p)
        ll_lap = GLLVM.laplace_loglik_site_xs(Gamma(α_true, 1.0), y, N, Λ, β, LogLink();
                                              x_obs = nothing, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        nodes, wts = GLLVM._gauss_hermite(90)
        zz = sqrt(2) .* nodes; wz = wts ./ sqrt(π)
        xx = μ_x .+ sqrt(2) * σ_x .* nodes; wx = wts ./ sqrt(π)
        acc = 0.0
        for (zi, wzi) in zip(zz, wz), (xi, wxi) in zip(xx, wx)
            μq = exp.(β .+ b_x * xi .+ Λ[:, 1] .* zi)
            ll = sum(logpdf(Gamma(α_true, μq[t] / α_true), y[t]) for t in 1:p)
            acc += wzi * wxi * exp(ll)
        end
        @test ll_lap ≈ log(acc) rtol = 4e-2
    end

    @testset "packed marginal is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(203)
        p, n, K = 5, 60, 1
        β0 = randn(p) .* 0.3
        Λ0 = reshape([0.4, 0.3, -0.25, 0.3, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        x = μ_x .+ σ_x .* randn(n)
        ηd = β0 .+ b_x .* x' .+ Λ0 * randn(K, n)
        μd = exp.(ηd)
        Y = [rand(Gamma(α_true, μd[t, s] / α_true)) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        xm = Vector{Union{Missing,Float64}}(x); xm[[3, 11, 25, 40]] .= missing
        function f(θ)
            β = θ[1:p]
            Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
            bx = θ[p + p * K + 1]; mx = θ[p + p * K + 2]; sx2 = exp(θ[p + p * K + 3])
            α = exp(θ[p + p * K + 4])
            GLLVM.marginal_loglik_laplace_xs(Gamma(α, 1.0), Y, N, Λ, β, LogLink();
                                             x = xm, b_x = bx, μ_x = mx, σ_x2 = sx2)
        end
        θ = vcat(β0, vec(Λ0), b_x, μ_x, log(σ_x^2), log(α_true))
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6; g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θm = copy(θ); θp[i] += h; θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end

    @testset "fit recovers b_x under MAR and beats complete-case" begin
        Random.seed!(204)
        p, n, K = 6, 600, 1
        β = [0.3, 0.6, 0.1, 0.4, -0.2, 0.5]
        Λ = reshape([0.4, 0.3, -0.3, 0.25, 0.2, -0.2], p, K)
        b_x_true, μ_x, σ_x = 0.6, 0.3, 0.6
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x_true .* x' .+ Λ * randn(K, n)
        μ = exp.(η)
        Y = [rand(Gamma(α_true, μ[t, s] / α_true)) for t in 1:p, s in 1:n]
        y1 = Y[1, :]
        pmiss = 1 ./ (1 .+ exp.(-(-0.5 .+ 1.5 .* (y1 .- mean(y1)) ./ std(y1))))
        Random.seed!(2204)
        miss = rand(n) .< pmiss
        xm = Vector{Union{Missing,Float64}}(x); xm[miss] .= missing
        res = fit_gllvm_mi(Gamma(), Y, xm; K = K)
        @test res.converged
        @test abs(res.b_x - b_x_true) < 0.2
        res_cc = fit_gllvm_mi(Gamma(), Y[:, .!miss], x[.!miss]; K = K)
        @test abs(res.b_x - b_x_true) ≤ abs(res_cc.b_x - b_x_true) + 0.05
    end
end

# ---------------------------------------------------------------------------
# Beta (logit link)
# ---------------------------------------------------------------------------
@testset "non-Gaussian missing predictor (Beta, augmented Laplace)" begin
    φ_true = 8.0

    @testset "missing-site marginal matches 2-D Gauss–Hermite quadrature" begin
        Random.seed!(302)
        p, K = 5, 1
        β = randn(p) .* 0.3
        Λ = reshape([0.4, 0.3, -0.25, 0.3, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        μ0 = 1 ./ (1 .+ exp.(-(β .+ b_x * μ_x)))
        y = [rand(Beta(μ0[t] * φ_true, (1 - μ0[t]) * φ_true)) for t in 1:p]
        N = ones(Int, p)
        ll_lap = GLLVM.laplace_loglik_site_xs(Beta(φ_true, 1.0), y, N, Λ, β, LogitLink();
                                              x_obs = nothing, b_x = b_x, μ_x = μ_x, σ_x2 = σ_x^2)
        nodes, wts = GLLVM._gauss_hermite(90)
        zz = sqrt(2) .* nodes; wz = wts ./ sqrt(π)
        xx = μ_x .+ sqrt(2) * σ_x .* nodes; wx = wts ./ sqrt(π)
        acc = 0.0
        for (zi, wzi) in zip(zz, wz), (xi, wxi) in zip(xx, wx)
            μq = 1 ./ (1 .+ exp.(-(β .+ b_x * xi .+ Λ[:, 1] .* zi)))
            ll = sum(logpdf(Beta(μq[t] * φ_true, (1 - μq[t]) * φ_true), y[t]) for t in 1:p)
            acc += wzi * wxi * exp(ll)
        end
        @test ll_lap ≈ log(acc) rtol = 4e-2
    end

    @testset "packed marginal is AD-clean (ForwardDiff vs central FD ≤ 1e-6)" begin
        Random.seed!(303)
        p, n, K = 5, 60, 1
        β0 = randn(p) .* 0.3
        Λ0 = reshape([0.4, 0.3, -0.25, 0.3, 0.2], p, K)
        b_x, μ_x, σ_x = 0.5, 0.4, 0.7
        x = μ_x .+ σ_x .* randn(n)
        ηd = β0 .+ b_x .* x' .+ Λ0 * randn(K, n)
        μd = 1 ./ (1 .+ exp.(-ηd))
        Y = [rand(Beta(μd[t, s] * φ_true, (1 - μd[t, s]) * φ_true)) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        xm = Vector{Union{Missing,Float64}}(x); xm[[3, 11, 25, 40]] .= missing
        function f(θ)
            β = θ[1:p]
            Λ = reshape(θ[(p + 1):(p + p * K)], p, K)
            bx = θ[p + p * K + 1]; mx = θ[p + p * K + 2]; sx2 = exp(θ[p + p * K + 3])
            φ = exp(θ[p + p * K + 4])
            GLLVM.marginal_loglik_laplace_xs(Beta(φ, 1.0), Y, N, Λ, β, LogitLink();
                                             x = xm, b_x = bx, μ_x = mx, σ_x2 = sx2)
        end
        θ = vcat(β0, vec(Λ0), b_x, μ_x, log(σ_x^2), log(φ_true))
        g_ad = ForwardDiff.gradient(f, θ)
        h = 1e-6; g_fd = similar(θ)
        for i in eachindex(θ)
            θp = copy(θ); θm = copy(θ); θp[i] += h; θm[i] -= h
            g_fd[i] = (f(θp) - f(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) < 1e-6
    end

    @testset "fit recovers b_x under MAR and beats complete-case" begin
        Random.seed!(304)
        p, n, K = 6, 600, 1
        β = [0.3, 0.6, 0.1, 0.4, -0.2, 0.5]
        Λ = reshape([0.4, 0.3, -0.3, 0.25, 0.2, -0.2], p, K)
        b_x_true, μ_x, σ_x = 0.6, 0.3, 0.6
        x = μ_x .+ σ_x .* randn(n)
        η = β .+ b_x_true .* x' .+ Λ * randn(K, n)
        μ = 1 ./ (1 .+ exp.(-η))
        Y = [rand(Beta(μ[t, s] * φ_true, (1 - μ[t, s]) * φ_true)) for t in 1:p, s in 1:n]
        y1 = Y[1, :]
        pmiss = 1 ./ (1 .+ exp.(-(-0.5 .+ 1.5 .* (y1 .- mean(y1)) ./ std(y1))))
        Random.seed!(2304)
        miss = rand(n) .< pmiss
        xm = Vector{Union{Missing,Float64}}(x); xm[miss] .= missing
        res = fit_gllvm_mi(Beta(), Y, xm; K = K)
        @test res.converged
        @test abs(res.b_x - b_x_true) < 0.2
        res_cc = fit_gllvm_mi(Beta(), Y[:, .!miss], x[.!miss]; K = K)
        @test abs(res.b_x - b_x_true) ≤ abs(res_cc.b_x - b_x_true) + 0.05
    end
end
