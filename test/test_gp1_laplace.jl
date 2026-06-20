using GLLVM, Test, Random, Distributions, Statistics, LinearAlgebra, ForwardDiff

# Generalized Poisson type-1 (GP-1, Famoye mean parameterization): log link,
# E[y] = μ, Var = μ(1+αμ)², signed dispersion α (α=0 ⇒ Poisson, α>0 over-, α<0
# underdispersed). Anchors: pmf normalization + exact mean/variance; Λ=0 exact
# reduction; α→0 ⇒ Poisson; score vs ForwardDiff; exact Fisher weight W=μ/(1+αμ)²;
# profile fit recovery (the joint fit collapsed α to the bound — profiling fixes it);
# post-fit API; Wald CI.

@testset "Generalized Poisson type-1 (GP-1)" begin
    GP1 = GLLVM.GeneralizedPoisson1
    pmf(α, μ, y) = exp(GLLVM._glm_logpdf(GP1(α), μ, 1, y))
    ymax(α) = α < 0 ? floor(Int, -1 / α - 1e-9) : 2000
    function rand_gp1(α, μ)
        u = rand(); c = 0.0
        for y in 0:ymax(α)
            c += pmf(α, μ, y); c >= u && return y
        end
        return ymax(α)
    end

    @testset "pmf normalizes; exact mean and variance (overdispersion α ≥ 0)" begin
        for μ in (1.0, 3.0, 8.0), α in (0.0, 0.05, 0.2, 0.5)
            ys = 0:2000
            ps = [pmf(α, μ, y) for y in ys]
            @test sum(ps) ≈ 1 atol = 1e-9
            m = sum(y * p for (y, p) in zip(ys, ps))
            v = sum((y - m)^2 * p for (y, p) in zip(ys, ps))
            @test m ≈ μ atol = 1e-7
            @test v ≈ μ * (1 + α * μ)^2 atol = 1e-6
        end
    end

    @testset "mild underdispersion (α < 0) normalizes away from the truncation wall" begin
        # GP-1 with α<0 has finite support y < 1/|α|; mass stays ≈1 while |α|μ is small.
        for (μ, α) in [(1.0, -0.05), (3.0, -0.05), (1.0, -0.1), (3.0, -0.02)]
            ps = [pmf(α, μ, y) for y in 0:ymax(α)]
            @test sum(ps) ≈ 1 atol = 1e-3
        end
    end

    @testset "Λ=0 marginal reduces to the independent GP-1 loglik (exact)" begin
        Random.seed!(1041)
        p, K, n, α = 5, 2, 40, 0.3
        β = 0.3 .* randn(p) .+ 1.0
        μ = exp.(β)
        Y = [rand(Poisson(μ[t])) for t in 1:p, _ in 1:n]
        ll = GLLVM.gp1_marginal_loglik_laplace(Y, zeros(p, K), β, α)
        ref = sum(GLLVM._glm_logpdf(GP1(α), μ[t], 1, Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ref atol = 1e-8
    end

    @testset "α→0 tends to the Poisson marginal (Λ≠0)" begin
        Random.seed!(1042)
        p, K, n = 5, 1, 40
        β = 0.3 .* randn(p) .+ 1.0
        Λ = reshape(0.4 .* randn(p), p, 1)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λ * randn(1)
            for t in 1:p
                Y[t, s] = rand(Poisson(exp(η[t])))
            end
        end
        ll_gp1 = GLLVM.gp1_marginal_loglik_laplace(Y, Λ, β, 1e-8)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_gp1 ≈ ll_pois atol = 1e-3
    end

    @testset "score matches ForwardDiff of the GP-1 logpdf" begin
        for α in (0.2, 0.5, -0.05), (μ, y) in [(2.0, 0), (2.0, 3), (5.0, 7), (0.7, 1)]
            (1 + α * y > 0 && 1 + α * μ > 0) || continue       # respect GP-1 support
            η = log(μ); me = μ                                  # log link: dμ/dη = μ
            lp(ηv) = GLLVM._glm_logpdf(GP1(α), exp(ηv), 1, y)
            s_ad = ForwardDiff.derivative(lp, η)
            s_an = GLLVM._glm_score(GP1(α), μ, 1, me, y)
            @test s_an ≈ s_ad atol = 1e-7
        end
    end

    @testset "Fisher weight = μ/(1+αμ)² (exact); equals E[s²] away from truncation" begin
        for α in (0.0, 0.2, 0.5, -0.05), μ in (1.0, 3.0, 8.0)
            W = GLLVM._glm_weight(GP1(α), μ, 1, μ)
            @test W ≈ μ / (1 + α * μ)^2 rtol = 1e-10
            if α ≥ 0 || abs(α) * μ ≤ 0.3                        # not the underdispersion wall
                Es2 = sum(GLLVM._glm_score(GP1(α), μ, 1, μ, y)^2 * pmf(α, μ, y) for y in 0:ymax(α))
                @test W ≈ Es2 rtol = 2e-3
            end
        end
    end

    @testset "fit_gp1_gllvm profile recovers α (no latent confound)" begin
        # α is the only overdispersion source ⇒ α̂ ≈ α_true. The earlier JOINT fit
        # collapsed α to the bound here; the profile-over-α driver recovers it.
        Random.seed!(1043)
        p, K, n, αtrue = 6, 1, 250, 0.4
        β = 0.4 .* randn(p) .+ 1.2
        Y = [rand_gp1(αtrue, exp(β[t])) for t in 1:p, _ in 1:n]
        fit = GLLVM.fit_gp1_gllvm(Y; K = K, iterations = 150)
        @test fit isa GLLVM.GP1Fit
        @test isfinite(fit.loglik)
        @test isapprox(fit.α, αtrue; atol = 0.15)
        @test fit.α < 1.0                                       # NOT pegged at α_bound=2.0
        @test cor(fit.β, β) > 0.8
    end

    @testset "fit + post-fit API on data with a latent factor" begin
        # n=300: K=2 loadings recovery is power-limited at small n (the Poisson
        # baseline also only reaches Gram cor ≈0.2 at n=150 for this seed); GP-1
        # tracks the Poisson baseline (≈0.44 at n=300, ≈0.9 at n=600).
        Random.seed!(1044)
        p, K, n, αtrue = 6, 2, 300, 0.3
        β = 0.3 .* randn(p) .+ 1.2
        Λt = 0.4 .* randn(p, K)
        Z = randn(K, n)
        Y = [rand_gp1(αtrue, exp(β[t] + (Λt * Z[:, s])[t])) for t in 1:p, s in 1:n]
        fit = GLLVM.fit_gp1_gllvm(Y; K = K, iterations = 150)
        @test fit isa GLLVM.GP1Fit
        @test fit.α > 0
        @test length(fit.β) == p && size(fit.Λ) == (p, K)
        @test cor(fit.β, β) > 0.5
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λt * Λt')) > 0.3    # rotation/sign-invariant Gram
        # post-fit API (mirrors NBFit / NB1Fit)
        @test size(getLV(fit, Y)) == (n, K)
        P = predict(fit, Y; type = :response)
        @test size(P) == (p, n) && all(P .> 0)
        R = residuals(fit, Y; rng = MersenneTwister(1))
        @test size(R) == (p, n) && all(isfinite, R)
        Rp = residuals(fit, Y; type = :pearson)
        @test size(Rp) == (p, n) && all(isfinite, Rp)
        @test isfinite(aic(fit)) && isfinite(bic(fit, n))
    end

    @testset "GP-1 Wald CI via the unified confint layer" begin
        Random.seed!(1045)
        p, K, n = 3, 1, 60
        β = 0.3 .* randn(p) .+ 1.0
        Λt = reshape(0.4 .* randn(p), p, 1)
        Y = Matrix{Int}(undef, p, n)
        for s in 1:n
            η = β .+ Λt * randn(K)
            for t in 1:p
                Y[t, s] = rand_gp1(0.3, exp(η[t]))
            end
        end
        fit = GLLVM.fit_gp1_gllvm(Y; K = K, iterations = 120)
        ci = confint(fit, Y; method = :wald)
        @test length(ci.term) == p + GLLVM.rr_theta_len(p, K) + 1   # β + Λ + α
        @test any(t -> t == "alpha", ci.term)
        for i in eachindex(ci.term)
            if isfinite(ci.lower[i]) && isfinite(ci.upper[i])
                @test ci.lower[i] ≤ ci.estimate[i] ≤ ci.upper[i]
            end
        end
    end
end
