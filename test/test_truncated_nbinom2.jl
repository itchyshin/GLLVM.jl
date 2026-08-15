using GLLVM, Test, Random, Distributions, ForwardDiff

# Draw zero-truncated NB2(μ, r): reject zeros.
function _rtruncnb2(μ, r)
    d = NegativeBinomial(r, r / (r + μ))
    while true
        y = rand(d)
        y ≥ 1 && return y
    end
end

@testset "truncated_nbinom2 family" begin

    @testset "Λ=0 exact reduction vs independent truncated NB2" begin
        Random.seed!(50)
        p, K, n = 4, 2, 50
        β = log.([2.0, 3.5, 1.5, 4.0])
        r = 5.0
        Y = [_rtruncnb2(exp(β[t]), r) for t in 1:p, s in 1:n]
        ll = GLLVM.truncated_nbinom2_marginal_loglik_laplace(Y, zeros(p, K), β, r)
        ll_indep = sum(begin
            μ = exp(β[t])
            p0 = (r / (r + μ))^r
            logpdf(NegativeBinomial(r, r / (r + μ)), Y[t, s]) - log1p(-p0)
        end for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "score/weight at log link match HurdleNB positive-block formulas" begin
        μ, y, r = 2.5, 3, 4.0
        me = μ  # LogLink
        f = TruncatedNegBin2(r)
        s = GLLVM._glm_score(f, μ, 1, me, y)
        W = GLLVM._glm_weight(f, μ, 1, me)
        p0 = (r / (r + μ))^r
        μtr = μ / (1 - p0)
        V = μ + μ^2 / r
        Wc = (V + μ^2) / (1 - p0) - μtr^2
        @test s ≈ y - μtr atol = 1e-12
        @test W ≈ Wc atol = 1e-12
    end

    @testset "rejects y=0" begin
        Y = [1 2; 0 3]
        @test_throws ArgumentError fit_truncated_nbinom2_gllvm(Y; K = 1, iterations = 5)
    end

    @testset "smoke fit converges" begin
        Random.seed!(51)
        p, n, K = 4, 40, 1
        β = randn(p) .* 0.3 .+ 1.0
        Λ = reshape(0.5 .* randn(p), p, K)
        r = 6.0
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = _rtruncnb2(exp(β[t] + (Λ * z)[t]), r)
            end
        end
        fit = fit_truncated_nbinom2_gllvm(Y; K = K, iterations = 80)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test fit.r > 0
        @test size(fit.Λ) == (p, K)
        fit2 = fit_gllvm(Y; family = TruncatedNegBin2(), K = K, iterations = 80)
        @test fit2 isa TruncatedNegBin2Fit
        @test isfinite(fit2.loglik)
    end

    @testset "packed NLL FD vs ForwardDiff ≤ 1e-6" begin
        Random.seed!(52)
        p, n, K = 3, 30, 1
        β = randn(p) .* 0.2 .+ 0.8
        r = 5.0
        Y = [_rtruncnb2(exp(β[t]), r) for t in 1:p, s in 1:n]
        rr = GLLVM.rr_theta_len(p, K)
        θ = vcat(β, GLLVM.pack_lambda(0.3 .* randn(p, K)), log(r))
        N1 = ones(Int, size(Y))
        nll = θv -> begin
            βv = θv[1:p]
            Λv = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            rv = exp(θv[p + rr + 1])
            -GLLVM.marginal_loglik_laplace(TruncatedNegBin2(rv), Y, N1, Λv, βv, LogLink())
        end
        g_ad = ForwardDiff.gradient(nll, θ)
        h = 1e-6
        g_fd = similar(θ)
        @inbounds for i in eachindex(θ)
            θp = copy(θ); θp[i] += h
            θm = copy(θ); θm[i] -= h
            g_fd[i] = (nll(θp) - nll(θm)) / (2h)
        end
        @test maximum(abs, g_ad .- g_fd) ≤ 1e-6
    end
end
