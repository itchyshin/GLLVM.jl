using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff

# REML for the Gaussian GLLVM. The load-bearing check is that gaussian_reml_loglik
# equals the standard REML formula computed independently from a DENSE Σ_y.

@testset "Gaussian REML" begin

    @testset "criterion matches hand-rolled REML (rtol 1e-8)" begin
        Random.seed!(31001)
        p, K, n, q = 5, 1, 60, 2
        Λ = 0.6 .* randn(p, K); σ = 0.5; βtrue = [1.0, -0.5]
        X = randn(p, n, q)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            Y[:, s] = [sum(X[t, s, k] * βtrue[k] for k in 1:q) for t in 1:p] .+ Λ * randn(K) .+ σ .* randn(p)
        end
        # independent dense REML
        Σ = Symmetric(Matrix(Λ * Λ' + σ^2 * I(p)))
        cΣ = cholesky(Σ)
        M = zeros(q, q); v = zeros(q)
        for s in 1:n
            Xs = X[:, s, :]
            M += Xs' * (cΣ \ Xs); v += Xs' * (cΣ \ Y[:, s])
        end
        β̂ = M \ v
        quad = 0.0
        for s in 1:n
            r = Y[:, s] .- X[:, s, :] * β̂; quad += dot(r, cΣ \ r)
        end
        ll_ml = -0.5 * (n * p * log(2π) + n * logdet(cΣ) + quad)
        ll_ref = ll_ml + (q / 2) * log(2π) - 0.5 * logdet(M)
        @test isapprox(GLLVM.gaussian_reml_loglik(Y, X, Λ, σ), ll_ref; rtol = 1e-8)
    end

    @testset "REML = ML-at-β̂ + adjustment (helper consistency)" begin
        Random.seed!(31004)
        p, K, n, q = 4, 1, 40, 2
        Λ = 0.5 .* randn(p, K); σ = 0.6; X = randn(p, n, q); Y = randn(p, n)
        β̂, logdetM = GLLVM._gaussian_gls(Y, X, Λ, σ)
        ll_ml = GLLVM.gaussian_marginal_loglik(Y, Λ, σ; X = X, β = β̂)
        @test isapprox(GLLVM.gaussian_reml_loglik(Y, X, Λ, σ),
                       ll_ml + (q / 2) * log(2π) - 0.5 * logdetM; rtol = 1e-10)
    end

    @testset "FD-gradient of the REML criterion ≤ 1e-6" begin
        Random.seed!(31002)
        p, K, n, q = 4, 1, 50, 2
        Λ0 = 0.5 .* randn(p, K); σ = 0.6; X = randn(p, n, q); Y = randn(p, n)
        rr = GLLVM.rr_theta_len(p, K)
        f = θ -> -GLLVM.gaussian_reml_loglik(Y, X, GLLVM.unpack_lambda(θ[1:rr], p, K), exp(θ[rr + 1]))
        θ = vcat(GLLVM.pack_lambda(Λ0), log(σ))
        gad = ForwardDiff.gradient(f, θ); h = 1e-6; gfd = similar(θ)
        for i in eachindex(θ)
            s = h * max(1.0, abs(θ[i])); tp = copy(θ); tp[i] += s; tm = copy(θ); tm[i] -= s
            gfd[i] = (f(tp) - f(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end

    @testset "fit_gaussian_reml recovers (β, σ_eps, ΛΛ')" begin
        Random.seed!(31003)
        p, K, n, q = 6, 2, 120, 3
        Λt = 0.6 .* randn(p, K); σt = 0.5; βt = randn(q)
        X = randn(p, n, q)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            Y[:, s] = [sum(X[t, s, k] * βt[k] for k in 1:q) for t in 1:p] .+ Λt * randn(K) .+ σt .* randn(p)
        end
        rfit = fit_gaussian_reml(Y, X; K = K)
        @test rfit.converged
        @test isapprox(rfit.σ_eps, σt; atol = 0.15)
        @test maximum(abs.(rfit.β .- βt)) < 0.3
        @test cor(vec(rfit.Λ * rfit.Λ'), vec(Λt * Λt')) > 0.8
    end
end
