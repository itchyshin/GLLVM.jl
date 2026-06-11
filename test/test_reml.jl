using GLLVM, Test, Random, LinearAlgebra, Statistics, ForwardDiff
using Distributions: MvNormal

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

    @testset "fit_gaussian_gllvm(reml=true) profile engine matches the standalone oracle" begin
        Random.seed!(31005)
        p, K, n, q = 5, 1, 90, 2
        Λt = 0.6 .* randn(p, K); σt = 0.5; βt = randn(q)
        X = randn(p, n, q)
        Y = Matrix{Float64}(undef, p, n)
        for s in 1:n
            Y[:, s] = [sum(X[t, s, k] * βt[k] for k in 1:q) for t in 1:p] .+ Λt * randn(K) .+ σt .* randn(p)
        end
        f1 = fit_gaussian_gllvm(Y; K = K, X = X, reml = true)   # fast profile-engine REML → GllvmFit
        f2 = fit_gaussian_reml(Y, X; K = K)                      # verified standalone REML (oracle)
        @test f1 isa GllvmFit
        @test isapprox(f1.pars.σ_eps, f2.σ_eps; rtol = 1e-4)
        @test isapprox(f1.logLik, f2.reml_loglik; rtol = 1e-4)   # same REML criterion (proven identical)
        @test maximum(abs.(f1.pars.β .- f2.β)) < 1e-3
        @test cor(vec(f1.pars.Λ * f1.pars.Λ'), vec(f2.Λ * f2.Λ')) > 0.999
        # no fixed effects ⇒ clear error
        @test_throws ArgumentError fit_gaussian_gllvm(Y; K = K, reml = true)
        # structured non-phylo (between/within diagonal) is now supported under REML
        fd = fit_gaussian_gllvm(Y; K = K, X = X, reml = true, has_diag = true)
        @test fd isa GllvmFit
        @test isfinite(fd.logLik)
    end

    @testset "Phylo REML (fast rotation-trick GLS) matches a dense phylo REML oracle" begin
        Random.seed!(32001)
        p, K_B, K_phy, n, q = 5, 1, 1, 70, 2
        Λ_B = reshape([0.6, 0.5, 0.4, -0.3, 0.2], p, K_B)
        Λ_phy = reshape([0.4, 0.3, 0.2, -0.1, 0.1], p, K_phy)
        σ_eps = 0.5; βt = [0.8, -0.5]
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        X = randn(p, n, q)
        # simulate phylo Gaussian with fixed effects Xβ
        A = Λ_B * Λ_B' + σ_eps^2 * I
        B = (Λ_phy * Λ_phy') .* Σ_phy
        Σ_full = kron(I(n), A) + kron(ones(n, n), B)
        μ = [sum(X[t, s, k] * βt[k] for k in 1:q) for t in 1:p, s in 1:n]
        y = reshape(rand(MvNormal(vec(μ), Symmetric(Matrix(Σ_full)))), p, n)

        fit = fit_gaussian_gllvm(y; K = K_B, K_phy = K_phy, Σ_phy = Σ_phy, X = X, reml = true)
        @test fit isa GllvmFit
        @test isfinite(fit.logLik)

        # dense phylo REML oracle at the fitted params (same REML constant as the
        # verified non-phylo standalone): −½[(np−q)log2π + log|Σ| + log|X'Σ⁻¹X| + r'Σ⁻¹r]
        Af = fit.pars.Λ * fit.pars.Λ' + fit.pars.σ_eps^2 * I
        Bf = (fit.pars.Λ_phy * fit.pars.Λ_phy') .* Σ_phy
        Σf = kron(I(n), Af) + kron(ones(n, n), Bf)
        cΣ = cholesky(Symmetric(Matrix(Σf)))
        Xs = zeros(p * n, q)
        for s in 1:n, t in 1:p
            Xs[(s - 1) * p + t, :] = X[t, s, :]
        end
        yv = vec(y)
        Md = Xs' * (cΣ \ Xs)
        βd = Md \ (Xs' * (cΣ \ yv))
        r = yv - Xs * βd
        quad = dot(r, cΣ \ r)
        ll_dense = -0.5 * ((p * n - q) * log(2π) + logdet(cΣ) + logdet(Md) + quad)
        @test isapprox(fit.logLik, ll_dense; rtol = 1e-5)
        @test maximum(abs.(fit.pars.β .- βd)) < 1e-4
    end

    @testset "Phylo REML runs + ML phylo unchanged" begin
        Random.seed!(32002)
        p, K_B, K_phy, n, q = 4, 1, 1, 120, 2
        Λ_B = reshape([0.6, 0.5, -0.3, 0.2], p, K_B)
        Λ_phy = reshape([0.4, 0.2, -0.1, 0.1], p, K_phy)
        σ_eps = 0.5; βt = [0.5, -0.4]
        T_phy = randn(p, p); Σ_phy = T_phy * T_phy' + 0.5 * I
        X = randn(p, n, q)
        A = Λ_B * Λ_B' + σ_eps^2 * I; B = (Λ_phy * Λ_phy') .* Σ_phy
        Σ_full = kron(I(n), A) + kron(ones(n, n), B)
        μ = [sum(X[t, s, k] * βt[k] for k in 1:q) for t in 1:p, s in 1:n]
        y = reshape(rand(MvNormal(vec(μ), Symmetric(Matrix(Σ_full)))), p, n)
        rfit = fit_gaussian_gllvm(y; K = K_B, K_phy = K_phy, Σ_phy = Σ_phy, X = X, reml = true)
        mfit = fit_gaussian_gllvm(y; K = K_B, K_phy = K_phy, Σ_phy = Σ_phy, X = X)  # ML, β in params
        @test rfit.converged
        @test isapprox(rfit.pars.σ_eps, σ_eps; atol = 0.2)
        @test maximum(abs.(rfit.pars.β .- βt)) < 0.4
        @test mfit.converged && isfinite(mfit.logLik)   # ML phylo+X path still works
    end

    @testset "phylo REML profile-NLL gradient is AD-clean (FD ≤ 1e-6)" begin
        Random.seed!(32003)
        p, K_B, K_phy, n, q = 4, 1, 1, 40, 2
        Λ_B = 0.6 .* randn(p, K_B); Λ_phy = 0.3 .* randn(p, K_phy); σ_eps = 0.5; βt = randn(q)
        T = randn(p, p); Σ_phy = T * T' + 0.5I
        X = randn(p, n, q)
        A = Λ_B * Λ_B' + σ_eps^2 * I; B = (Λ_phy * Λ_phy') .* Σ_phy
        Σf = kron(I(n), A) + kron(ones(n, n), B)
        μ = [sum(X[t, s, k] * βt[k] for k in 1:q) for t in 1:p, s in 1:n]
        y = reshape(rand(MvNormal(vec(μ), Symmetric(Matrix(Σf)))), p, n)
        spec = (p = p, q = q, K_B = K_B, K_W = 0, has_diag = false,
                K_phy = K_phy, has_phy_unique = false)
        f = par -> GLLVM.gaussian_profile_nll(par, y; spec = spec, X = X,
                                              Σ_phy = Σ_phy, profile_beta = true, reml = true)
        par0 = vcat(GLLVM.pack_lambda(Λ_B ./ σ_eps), GLLVM.pack_lambda(Λ_phy ./ σ_eps))
        gad = ForwardDiff.gradient(f, par0); h = 1e-6; gfd = similar(par0)
        for i in eachindex(par0)
            s = h * max(1.0, abs(par0[i])); tp = copy(par0); tp[i] += s; tm = copy(par0); tm[i] -= s
            gfd[i] = (f(tp) - f(tm)) / (2s)
        end
        @test all(isfinite, gad)
        @test maximum(abs.(gad .- gfd)) ≤ 1e-6
    end
end
