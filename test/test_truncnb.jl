using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_truncpoisson.jl and
# test/test_nb1_lognormal.jl). NOTE: the `2 * step` denominator is an Int literal,
# not the Float32 `2f0` stencil — the FD step stays in θ's precision (Float64) to
# hit the ≤1e-6 target.
function _central_fd_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        tp = copy(theta); tp[i] += step
        tm = copy(theta); tm[i] -= step
        g[i] = (f(tp) - f(tm)) / (2 * step)
    end
    return g
end

_max_rel_err(a, b) = maximum(abs.(a .- b) ./ max.(1.0, abs.(b)))

# Draw one zero-truncated NB2(μ, r) by rejection (reference DGP for tests).
function _rand_ztnb(rng, μ, r)
    d = NegativeBinomial(r, r / (r + μ))
    y = rand(rng, d)
    while y < 1
        y = rand(rng, d)
    end
    return y
end

# Closed-form zero-truncated NB2 logpdf reference (k ≥ 1).
_ztnb_P0(μ, r) = (r / (r + μ))^r
_ztnb_logpdf(μ, r, k) = logpdf(NegativeBinomial(r, r / (r + μ)), Int(k)) - log1p(-_ztnb_P0(μ, r))

@testset "Zero-truncated NB2" begin

    # ---------------------------------------------------------------------
    # Family pieces: score / weight / logpdf sanity against the spec.
    # ---------------------------------------------------------------------
    @testset "score, weight, mean/variance match the truncated law" begin
        for (μ, r) in ((0.8, 3.0), (2.0, 5.0), (5.0, 2.0), (1.2, 10.0))
            fam = TruncNB(r)
            P0 = _ztnb_P0(μ, r)
            μtr = μ / (1 - P0)
            EY2 = (μ + μ^2 / r + μ^2) / (1 - P0)
            V = EY2 - μtr^2
            # score wrt η (log link): r/(r+μ)·(y − μtr).
            @test GLLVM._glm_score(fam, μ, 1, μ, 4.0) ≈ r / (r + μ) * (4.0 - μtr)
            # weight = (r/(r+μ))²·Var[y|y≥1] (expected information ⇒ ≥ 0).
            Wgot = GLLVM._glm_weight(fam, μ, 1, μ)
            @test Wgot ≈ (r / (r + μ))^2 * V
            @test Wgot > 0
            # Monte-Carlo check of E[y|y≥1] = μtr and Var = V.
            rng = MersenneTwister(round(Int, 1000μ + r))
            draws = [_rand_ztnb(rng, μ, r) for _ in 1:300_000]
            @test mean(draws) ≈ μtr rtol = 0.02
            @test var(draws) ≈ V rtol = 0.05
            # logpdf matches the closed form (reuses the NB2 logpdf) and normalises.
            @test GLLVM._glm_logpdf(fam, μ, 1, 3.0) ≈ _ztnb_logpdf(μ, r, 3)
            @test sum(exp(_ztnb_logpdf(μ, r, k)) for k in 1:5000) ≈ 1.0 atol = 1e-7
        end
    end

    # ---------------------------------------------------------------------
    # Marginal reduces to the zero-truncated POISSON marginal when r is large
    # (NB2 → Poisson as r → ∞, truncation preserved).
    # ---------------------------------------------------------------------
    @testset "marginal → ZTP marginal as r grows (NB2 → Poisson)" begin
        Random.seed!(901)
        p, K, n = 5, 2, 30
        β = log.([3.0, 4.0, 2.5, 3.5, 3.0])
        Λ = 0.2 .* randn(p, K)
        r_big = 1.0e6
        rng = MersenneTwister(9011)
        Y = [_rand_ztnb(rng, exp(β[t]), r_big) for t in 1:p, s in 1:n]
        ll_ztnb = GLLVM.truncnb_marginal_loglik_laplace(Y, Λ, β, r_big)
        ll_ztp  = GLLVM.truncpoisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_ztnb ≈ ll_ztp rtol = 1e-4
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent zero-truncated-NB regression loglik.
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent ZTNB-regression loglik (exact)" begin
        Random.seed!(902)
        p, K, n = 4, 2, 40
        β = log.([1.5, 2.0, 1.2, 1.8])
        μ = exp.(β)
        r = 4.0
        rng = MersenneTwister(9021)
        Y = [_rand_ztnb(rng, μ[t], r) for t in 1:p, s in 1:n]
        ll = GLLVM.truncnb_marginal_loglik_laplace(Y, zeros(p, K), β, r)
        ll_indep = sum(_ztnb_logpdf(μ[t], r, Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6,
    # over the FULL packed vector [β; vec(Λ); log r].
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(903)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        r0 = 5.0
        rng = MersenneTwister(9031)
        Y = [_rand_ztnb(rng, 3.0, r0) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(r0))
        f = θ -> -GLLVM.truncnb_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], exp(θ[end]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "ZTNB marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # This is the generic implicit dense-Laplace gradient over (η, log r).
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(904)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        r0 = 6.0
        rng = MersenneTwister(9041)
        Y = [_rand_ztnb(rng, 3.0, r0) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, log(r0))
        family_fromθ = θ -> TruncNB(GLLVM._positive_from_log(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "ZTNB implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' loading structure, dispersion r).
    # GENEROUS MC band, fixed seeds. convergence flag is INFORMATIONAL —
    # recovery is asserted, not convergence.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', r)" begin
        Random.seed!(905)
        p, K, n = 6, 2, 800
        β_true = log.([3.0, 4.0, 2.5, 3.5, 3.0, 4.5])
        Λ_true = 0.5 .* randn(p, K)
        r_true = 6.0
        Y = simulate(TruncNB(r_true), β_true, Λ_true, n; dispersion = r_true, seed = 9051)
        @test minimum(Y) ≥ 1                       # simulator never emits a zero
        Yint = round.(Int, Y)
        fit = fit_truncnb_gllvm(Yint; K = K)
        @info "ZTNB fit" converged=fit.converged loglik=fit.loglik r=fit.r
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.5
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        # Dispersion recovery is identifiable-but-noisy (the latent absorbs some
        # overdispersion, and r is only weakly identified after zero-truncation);
        # a GENEROUS factor-of-3 band around r_true, plus finite & positive.
        @test isfinite(fit.r) && fit.r > 0
        @test r_true / 3 < fit.r < r_true * 3
    end

    # ---------------------------------------------------------------------
    # link_residual: truncation-adjusted NB delta formula; finite/positive, and
    # reduces toward the ZTP residual for large r and the NB2 delta for large μ̂.
    # ---------------------------------------------------------------------
    @testset "link_residual: truncation-adjusted NB formula, finite & positive" begin
        Random.seed!(906)
        p, K, n = 4, 1, 300
        β_true = log.([3.0, 5.0, 2.5, 4.0])
        Λ_true = 0.4 .* randn(p, K)
        r_true = 5.0
        Y = round.(Int, simulate(TruncNB(r_true), β_true, Λ_true, n;
                                 dispersion = r_true, seed = 9061))
        fit = fit_truncnb_gllvm(Y; K = K)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(isfinite, σ2d) && all(>(0), σ2d)
        # Single-arg formula: σ²_d = log1p((μ+μ²/r+μ²)(1−P₀)/μ² − 1), P₀=(r/(r+μ))^r.
        μ = 5.0; r = 5.0
        P0 = (r / (r + μ))^r
        @test link_residual(TruncNB(r), LogLink(), μ, r) ≈
              log1p((μ + μ^2 / r + μ^2) * (1 - P0) / μ^2 - 1)
        # Large r ⇒ reduces toward the zero-truncated-Poisson residual.
        μ2 = 4.0
        μtr = μ2 / (1 - exp(-μ2))
        @test link_residual(TruncNB(1.0e8), LogLink(), μ2, 1.0e8) ≈
              log1p((1 + μ2 - μtr) / μtr) rtol = 1e-4
        # Large μ ⇒ reduces toward the untruncated NB2 delta residual log1p(1/μ+1/r).
        @test link_residual(TruncNB(5.0), LogLink(), 200.0, 5.0) ≈
              log1p(1 / 200.0 + 1 / 5.0) rtol = 1e-3
    end
end
