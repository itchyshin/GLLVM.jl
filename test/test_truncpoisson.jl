using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_nb1_lognormal.jl and
# test/test_family_forwarddiff_gradients.jl). NOTE: the `2 * step` denominator is
# written with an Int literal, not the Float32 `2f0` stencil — the FD step must be
# in the same precision as θ (Float64 here) to hit the ≤1e-6 target.
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

# Draw one zero-truncated Poisson(μ) by rejection (reference DGP for tests).
function _rand_ztp(rng, μ)
    y = rand(rng, Poisson(μ))
    while y < 1
        y = rand(rng, Poisson(μ))
    end
    return y
end

# Closed-form zero-truncated Poisson logpdf reference (k ≥ 1).
_ztp_logpdf(μ, k) = logpdf(Poisson(μ), k) - log1p(-exp(-μ))

@testset "Zero-truncated Poisson" begin

    # ---------------------------------------------------------------------
    # Family pieces: score / weight / logpdf sanity against the spec.
    # ---------------------------------------------------------------------
    @testset "score, weight, mean/variance match the truncated law" begin
        fam = ZeroTruncatedPoisson()
        for μ in (0.5, 1.0, 3.0, 7.0)
            μtr = μ / (1 - exp(-μ))
            # score at y wrt η is y − μtr (log link); weight is the truncated variance.
            @test GLLVM._glm_score(fam, μ, 1, μ, 4.0) ≈ 4.0 - μtr
            Wgot = GLLVM._glm_weight(fam, μ, 1, μ)
            @test Wgot ≈ μtr * (1 + μ - μtr)
            @test Wgot > 0
            # Monte-Carlo check of E[y|y≥1] = μtr and Var = μtr(1+μ−μtr).
            rng = MersenneTwister(round(Int, 1000μ))
            draws = [_rand_ztp(rng, μ) for _ in 1:200_000]
            @test mean(draws) ≈ μtr rtol = 0.02
            @test var(draws) ≈ μtr * (1 + μ - μtr) rtol = 0.05
            # logpdf matches the closed form and is normalised over k ≥ 1.
            @test GLLVM._glm_logpdf(fam, μ, 1, 3.0) ≈ _ztp_logpdf(μ, 3)
            @test sum(exp(_ztp_logpdf(μ, k)) for k in 1:200) ≈ 1.0 atol = 1e-8
        end
    end

    # ---------------------------------------------------------------------
    # Marginal reduces to the plain Poisson marginal when μ is large (the
    # truncation mass e^{-μ} → 0). Drives a big-μ data set under BOTH families.
    # ---------------------------------------------------------------------
    @testset "marginal → Poisson marginal as μ grows (truncation negligible)" begin
        Random.seed!(801)
        p, K, n = 5, 2, 30
        β = log.([20.0, 30.0, 25.0, 22.0, 28.0])   # large rates ⇒ ~no truncation
        Λ = 0.2 .* randn(p, K)
        rng = MersenneTwister(8011)
        Y = [_rand_ztp(rng, exp(β[t])) for t in 1:p, s in 1:n]
        ll_ztp  = GLLVM.truncpoisson_marginal_loglik_laplace(Y, Λ, β)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_ztp ≈ ll_pois rtol = 1e-3
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent zero-truncated-Poisson regression loglik.
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent ZTP-regression loglik (exact)" begin
        Random.seed!(802)
        p, K, n = 4, 2, 40
        β = log.([1.5, 2.0, 1.2, 1.8])
        μ = exp.(β)
        rng = MersenneTwister(8021)
        Y = [_rand_ztp(rng, μ[t]) for t in 1:p, s in 1:n]
        ll = GLLVM.truncpoisson_marginal_loglik_laplace(Y, zeros(p, K), β)
        ll_indep = sum(_ztp_logpdf(μ[t], Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(803)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        rng = MersenneTwister(8031)
        Y = [_rand_ztp(rng, 3.0) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0)
        f = θ -> -GLLVM.truncpoisson_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p])
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "ZTP marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(804)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        rng = MersenneTwister(8041)
        Y = [_rand_ztp(rng, 3.0) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0)
        family_fromθ = _ -> ZeroTruncatedPoisson()
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "ZTP implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' loading structure). ZTP has NO
    # dispersion, so the "dispersion" recovery target is the truncated mean
    # implied by β (and the no-zeros invariant of the simulator).
    # convergence flag is INFORMATIONAL — recovery is asserted, not convergence.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ')" begin
        Random.seed!(805)
        p, K, n = 6, 2, 600
        β_true = log.([3.0, 4.0, 2.5, 3.5, 3.0, 4.5])
        Λ_true = 0.5 .* randn(p, K)
        Y = simulate(ZeroTruncatedPoisson(), β_true, Λ_true, n; seed = 8051)
        @test minimum(Y) ≥ 1                       # simulator never emits a zero
        Yint = round.(Int, Y)
        fit = fit_truncpoisson_gllvm(Yint; K = K)
        @info "ZTP fit" converged=fit.converged loglik=fit.loglik
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.4
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        # Truncated-mean recovery (the response-scale analogue of "dispersion"):
        # the per-trait fitted untruncated rate exp(β̂) should track exp(β_true).
        μtr_true = exp.(β_true) ./ (1 .- exp.(-exp.(β_true)))
        μtr_hat  = exp.(fit.β)  ./ (1 .- exp.(-exp.(fit.β)))
        @test cor(μtr_true, μtr_hat) > 0.9
    end

    # ---------------------------------------------------------------------
    # link_residual: matches the truncation-adjusted formula and is finite/positive,
    # and reduces toward the Poisson log1p(1/μ̂) for large μ̂.
    # ---------------------------------------------------------------------
    @testset "link_residual: truncation-adjusted formula, finite & positive" begin
        Random.seed!(806)
        p, K, n = 4, 1, 300
        β_true = log.([3.0, 5.0, 2.5, 4.0])
        Λ_true = 0.4 .* randn(p, K)
        Y = round.(Int, simulate(ZeroTruncatedPoisson(), β_true, Λ_true, n; seed = 8061))
        fit = fit_truncpoisson_gllvm(Y; K = K)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(isfinite, σ2d) && all(>(0), σ2d)
        # Single-arg formula: σ²_d = log1p((1+μ−μtr)/μtr), μtr = μ/(1−e^{-μ}).
        μ = 5.0
        μtr = μ / (1 - exp(-μ))
        @test link_residual(ZeroTruncatedPoisson(), LogLink(), μ, nothing) ≈
              log1p((1 + μ - μtr) / μtr)
        # Large μ ⇒ reduces toward the plain-Poisson log1p(1/μ).
        @test link_residual(ZeroTruncatedPoisson(), LogLink(), 50.0, nothing) ≈
              log1p(1 / 50.0) rtol = 1e-3
    end
end
