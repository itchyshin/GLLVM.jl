using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions

function _high_rate_poisson_fixture()
    Random.seed!(7002)
    p, K, n = 6, 2, 600
    β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
    Λ_true = 0.5 .* randn(p, K)
    rng = MersenneTwister(70021)
    Z = randn(rng, K, n)
    Y = [rand(rng, Poisson(exp(β_true[t] + dot(view(Λ_true, t, :), view(Z, :, s)))))
         for t in 1:p, s in 1:n]
    return Y
end

function _poisson_warm_start(Y, K)
    p, n = size(Y)
    Zemp = [log(max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    β0 = vec(sum(Zemp; dims = 2)) ./ n
    Zc = Zemp .- β0
    F = svd(Zc)
    Λ0 = zeros(p, K)
    kk = min(K, length(F.S))
    @inbounds for j in 1:kk
        Λ0[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
    end
    return β0, Λ0
end

@testset "fit_poisson_gllvm — recovery" begin
    @testset "recovers loading structure + intercepts" begin
        Random.seed!(40)
        p, K, n = 6, 2, 400
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        η = β_true .+ Λ_true * randn(K, n)
        Y = [rand(Poisson(exp(η[t, s]))) for t in 1:p, s in 1:n]

        fit = fit_poisson_gllvm(Y; K = K)
        @test fit.converged
        @test size(fit.Λ) == (p, K)
        @test length(fit.β) == p
        @test maximum(abs.(fit.β .- β_true)) < 0.4
        # loadings are identified only up to rotation ⇒ compare ΛΛ' structure
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.7
    end

    @testset "fit_gllvm(family = Poisson()) dispatches to PoissonFit" begin
        Random.seed!(41)
        p, K, n = 5, 1, 200
        Y = [rand(Poisson(exp(1.5 + 0.4 * randn()))) for t in 1:p, s in 1:n]
        fit = fit_gllvm(Y; family = Poisson(), K = K)
        @test fit isa PoissonFit
        @test fit.converged
    end

    @testset "high-rate K=2 fit keeps intercepts on the empirical scale" begin
        Y = _high_rate_poisson_fixture()
        β0, _ = _poisson_warm_start(Y, 2)

        fit = fit_poisson_gllvm(Y; K = 2)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test maximum(abs.(fit.β .- β0)) < 0.25
        @test abs(fit.β[6]) < 5
    end

    @testset "high-rate Poisson analytic gradient matches finite difference" begin
        Y = _high_rate_poisson_fixture()
        p, K = size(Y, 1), 2
        β0, Λ0 = _poisson_warm_start(Y, K)
        rr = GLLVM.rr_theta_len(p, K)
        θ0 = vcat(β0, GLLVM.pack_lambda(Λ0))
        N = ones(Int, size(Y))

        function marginal(θ)
            β = θ[1:p]
            Λ = GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K)
            return GLLVM.marginal_loglik_laplace(Poisson(), Y, N, Λ, β, LogLink())
        end

        g_analytic = GLLVM.poisson_laplace_grad(Y, Λ0, β0)
        g_fd = similar(θ0)
        h = 1e-5
        @inbounds for i in eachindex(θ0)
            θp = copy(θ0)
            θm = copy(θ0)
            θp[i] += h
            θm[i] -= h
            g_fd[i] = (marginal(θp) - marginal(θm)) / (2h)
        end

        @test maximum(abs.(g_analytic .- g_fd)) < 1e-4
    end
end
