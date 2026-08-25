using GLLVM, Test, Random, Distributions, ForwardDiff

# Draw zero-truncated Poisson(μ): reject zeros.
function _rtruncpois(μ)
    while true
        y = rand(Poisson(μ))
        y ≥ 1 && return y
    end
end

@testset "truncated_poisson family" begin

    @testset "Λ=0 exact reduction vs independent truncated Poisson" begin
        Random.seed!(40)
        p, K, n = 4, 2, 50
        β = log.([2.0, 3.5, 1.5, 4.0])
        Y = [_rtruncpois(exp(β[t])) for t in 1:p, s in 1:n]
        ll = GLLVM.truncated_poisson_marginal_loglik_laplace(Y, zeros(p, K), β)
        ll_indep = sum(
            logpdf(Poisson(exp(β[t])), Y[t, s]) - log1p(-exp(-exp(β[t])))
            for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-8
    end

    @testset "score/weight at log link match hurdle positive-block formulas" begin
        μ, y = 2.5, 3
        me = μ  # LogLink
        s = GLLVM._glm_score(TruncatedPoisson(), μ, 1, me, y)
        W = GLLVM._glm_weight(TruncatedPoisson(), μ, 1, me)
        p0 = exp(-μ)
        μtr = μ / (1 - p0)
        @test s ≈ y - μtr atol = 1e-12
        @test W ≈ μtr * (1 + μ - μtr) atol = 1e-12
    end

    @testset "rejects y=0" begin
        Y = [1 2; 0 3]
        @test_throws ArgumentError fit_truncated_poisson_gllvm(Y; K = 1, iterations = 5)

        # The message must name the offending VALUE and CELL. Regression guard:
        # it previously read "y=$Yc[t,s]", which interpolates the whole count
        # matrix and then prints a literal "[t,s]" — so the reported value and
        # index were not what the message promised, and the text grew with the
        # size of the data rather than staying constant.
        err = try
            fit_truncated_poisson_gllvm(Y; K = 1, iterations = 5)
            nothing
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("found y=0 at (2,1)", err.msg)
        @test !occursin("[1, 2]", err.msg)      # no spliced matrix
        @test length(err.msg) < 120             # constant-size message
    end

    @testset "smoke fit converges" begin
        Random.seed!(41)
        p, n, K = 4, 40, 1
        β = randn(p) .* 0.3 .+ 1.0
        Λ = reshape(0.5 .* randn(p), p, K)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            z = randn(K)
            for t in 1:p
                Y[t, s] = _rtruncpois(exp(β[t] + (Λ * z)[t]))
            end
        end
        fit = fit_truncated_poisson_gllvm(Y; K = K, iterations = 80)
        @test fit.converged
        @test isfinite(fit.loglik)
        @test size(fit.Λ) == (p, K)
        fit2 = fit_gllvm(Y; family = TruncatedPoisson(), K = K, iterations = 80)
        @test fit2 isa TruncatedPoissonFit
        @test isfinite(fit2.loglik)
    end

    @testset "packed NLL FD vs ForwardDiff ≤ 1e-6" begin
        Random.seed!(42)
        p, n, K = 3, 30, 1
        β = randn(p) .* 0.2 .+ 0.8
        Y = [_rtruncpois(exp(β[t])) for t in 1:p, s in 1:n]
        rr = GLLVM.rr_theta_len(p, K)
        θ = vcat(β, GLLVM.pack_lambda(0.3 .* randn(p, K)))
        N1 = ones(Int, size(Y))
        nll = θv -> begin
            βv = θv[1:p]
            Λv = GLLVM.unpack_lambda(θv[(p + 1):(p + rr)], p, K)
            -GLLVM.marginal_loglik_laplace(TruncatedPoisson(), Y, N1, Λv, βv, LogLink())
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
