using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff

# REML for the Gaussian GLLVM (`src/reml.jl`). The load-bearing check is that
# `gaussian_reml_loglik` equals the standard REML formula computed independently
# from a DENSE Σ_y, rather than through the Woodbury solves the source uses.
#
# Scope note: main carries the standalone REML path (`gaussian_reml_loglik`,
# `fit_gaussian_reml`) plus the `reml = true` bridge route. The
# `fit_gaussian_gllvm(reml = true)` profile engine and the phylogenetic REML
# rotation trick live on the non-Gaussian-CI feature branch; their testsets stay
# there until that engine merges.

@testset "Gaussian REML" begin

    @testset "criterion matches hand-rolled REML (rtol 1e-8)" begin
        Random.seed!(31001)
        p, K, n, q = 5, 1, 60, 2
        Λ = 0.6 .* randn(p, K); σ = 0.5; βtrue = [1.0, -0.5]
        X = randn(p, n, q)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            Y[:, s] = [sum(X[t, s, k] * βtrue[k] for k in 1:q) for t in 1:p] .+
                      Λ * randn(K) .+ σ .* randn(p)
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

        # the GLS profile itself, not just the criterion it feeds
        β_gls, logdetM = GLLVM._gaussian_gls(Y, X, Λ, σ)
        @test isapprox(β_gls, β̂; rtol = 1e-8)
        @test isapprox(logdetM, logdet(M); rtol = 1e-8)
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

    @testset "criterion is invariant to shifts inside the span of X" begin
        # The defining property of a restricted likelihood: it sees the data only
        # through error contrasts, so adding X*b must leave the criterion fixed
        # while β̂_GLS moves by exactly b.
        Random.seed!(31006)
        p, K, n, q = 5, 1, 30, 2
        Λ = 0.5 .* randn(p, K); σ = 0.5; X = randn(p, n, q); Y = randn(p, n)
        b = [2.0, -1.25]
        shift = zeros(p, n)
        for k in 1:q
            shift .+= b[k] .* X[:, :, k]
        end
        @test isapprox(GLLVM.gaussian_reml_loglik(Y .+ shift, X, Λ, σ),
                       GLLVM.gaussian_reml_loglik(Y, X, Λ, σ); rtol = 1e-9)
        β0, _ = GLLVM._gaussian_gls(Y, X, Λ, σ)
        β1, _ = GLLVM._gaussian_gls(Y .+ shift, X, Λ, σ)
        @test isapprox(β1, β0 .+ b; rtol = 1e-8)
    end

    @testset "FD-gradient of the REML criterion ≤ 1e-6" begin
        Random.seed!(31002)
        p, K, n, q = 4, 1, 50, 2
        Λ0 = 0.5 .* randn(p, K); σ = 0.6; X = randn(p, n, q); Y = randn(p, n)
        rr = GLLVM.rr_theta_len(p, K)
        f = θ -> -GLLVM.gaussian_reml_loglik(Y, X, GLLVM.unpack_lambda(θ[1:rr], p, K),
                                             exp(θ[rr + 1]))
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
            Y[:, s] = [sum(X[t, s, k] * βt[k] for k in 1:q) for t in 1:p] .+
                      Λt * randn(K) .+ σt .* randn(p)
        end
        rfit = fit_gaussian_reml(Y, X; K = K)
        @test rfit.converged
        @test isapprox(rfit.σ_eps, σt; atol = 0.15)
        @test maximum(abs.(rfit.β .- βt)) < 0.3
        @test cor(vec(rfit.Λ * rfit.Λ'), vec(Λt * Λt')) > 0.8
        # the reported criterion is the objective at the returned point
        @test isapprox(rfit.reml_loglik,
                       GLLVM.gaussian_reml_loglik(Y, X, rfit.Λ, rfit.σ_eps); rtol = 1e-8)
        @test occursin("GaussianREMLFit", sprint(show, rfit))
    end

    @testset "argument validation" begin
        Y = randn(4, 12); X = ones(4, 12, 1)
        @test_throws ArgumentError fit_gaussian_reml(Y, X; K = 0)
        @test_throws ArgumentError fit_gaussian_reml(Y, X; K = 4)
        @test_throws DimensionMismatch fit_gaussian_reml(Y, ones(3, 12, 1); K = 1)
    end

    @testset "bridge reml = true routes to the REML engine" begin
        # `engine = "julia"` transport for REML: per-trait intercepts enter as the
        # GLS design, so the bridge loglik is the REML criterion and alpha the GLS
        # trait means. Checked against the standalone fitter, not against R.
        Random.seed!(31007)
        p, K, n = 4, 1, 60
        Λt = 0.6 .* randn(p, K); σt = 0.5; αt = [1.0, -0.5, 0.25, 2.0]
        Y = Λt * randn(K, n) .+ αt .+ σt .* randn(p, n)

        br = bridge_fit(; y = Y, family = "gaussian", d = K,
                        options = Dict{String, Any}("reml" => true))
        @test br.model == "gaussian_reml_rr"
        @test br.d == K
        @test isfinite(br.loglik)

        Xrt = zeros(p, n, p)
        for t in 1:p, s in 1:n
            Xrt[t, s, t] = 1.0
        end
        oracle = fit_gaussian_reml(Y, Xrt; K = K)
        @test isapprox(br.loglik, oracle.reml_loglik; rtol = 1e-8)
        @test isapprox(br.alpha, oracle.β; rtol = 1e-8)
        @test isapprox(br.sigma_eps, oracle.σ_eps; rtol = 1e-8)
    end
end
