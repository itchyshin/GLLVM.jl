using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_truncpoisson.jl and
# test/test_nb1_lognormal.jl). The `2 * step` denominator uses an Int literal, not
# the Float32 `2f0` stencil — the FD step must be in θ's precision (Float64) to hit
# the ≤1e-6 target.
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

# Closed-form ZIP logpdf reference: π·δ₀ + (1−π)·Poisson(μ).
function _zip_logpdf(π, μ, k)
    if k == 0
        return log(π + (1 - π) * exp(-μ))
    else
        return log1p(-π) + logpdf(Poisson(μ), k)
    end
end

# Draw one ZIP(π, μ) (reference DGP for tests).
_rand_zip(rng, π, μ) = rand(rng) < π ? 0 : rand(rng, Poisson(μ))

@testset "Zero-inflated Poisson (ZIP)" begin

    # ---------------------------------------------------------------------
    # Family pieces: score / weight / logpdf sanity against the spec.
    # ---------------------------------------------------------------------
    @testset "score, weight, logpdf match the ZIP spec" begin
        for π in (0.1, 0.3, 0.5), μ in (0.5, 1.0, 3.0, 7.0)
            fam = GLLVM.ZIP(π)
            emμ = exp(-μ)
            p0 = π + (1 - π) * emμ
            # logpdf: y=0 mixes both parts; y>0 is log(1−π)+Poisson logpdf.
            @test GLLVM._glm_logpdf(fam, μ, 1, 0.0) ≈ log(p0)
            @test GLLVM._glm_logpdf(fam, μ, 1, 4.0) ≈ log1p(-π) + logpdf(Poisson(μ), 4)
            # logpdf is a normalised pmf over k = 0,1,2,…
            @test sum(exp(_zip_logpdf(π, μ, k)) for k in 0:300) ≈ 1.0 atol = 1e-9
            # score: y>0 is the Poisson score y−μ (π-free); y=0 is the zero-cell score.
            @test GLLVM._glm_score(fam, μ, 1, μ, 5.0) ≈ 5.0 - μ
            @test GLLVM._glm_score(fam, μ, 1, μ, 0.0) ≈ -μ * (1 - π) * emμ / p0
            # weight = expected Fisher information E[s²] ≥ 0.
            Wexp = (1 - π)^2 * μ^2 * emμ^2 / p0 + (1 - π) * μ - (1 - π) * emμ * μ^2
            @test GLLVM._glm_weight(fam, μ, 1, μ) ≈ Wexp
            @test GLLVM._glm_weight(fam, μ, 1, μ) > 0
        end
    end

    # ---------------------------------------------------------------------
    # π → 0 reduces every family piece to the plain Poisson.
    # ---------------------------------------------------------------------
    @testset "π = 0 reduces to Poisson pieces" begin
        for μ in (0.5, 2.0, 6.0)
            zfam = GLLVM.ZIP(0.0)
            pfam = Poisson()
            @test GLLVM._glm_score(zfam, μ, 1, μ, 0.0) ≈ GLLVM._glm_score(pfam, μ, 1, μ, 0.0)
            @test GLLVM._glm_score(zfam, μ, 1, μ, 4.0) ≈ GLLVM._glm_score(pfam, μ, 1, μ, 4.0)
            @test GLLVM._glm_weight(zfam, μ, 1, μ) ≈ GLLVM._glm_weight(pfam, μ, 1, μ)
            @test GLLVM._glm_logpdf(zfam, μ, 1, 3.0) ≈ GLLVM._glm_logpdf(pfam, μ, 1, 3.0)
        end
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent ZIP-regression loglik (exact).
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent ZIP-regression loglik (exact)" begin
        Random.seed!(902)
        p, K, n = 4, 2, 50
        β = log.([2.0, 3.0, 1.5, 2.5])
        μ = exp.(β)
        π = 0.3
        rng = MersenneTwister(9021)
        Y = [_rand_zip(rng, π, μ[t]) for t in 1:p, s in 1:n]
        ll = GLLVM.zip_marginal_loglik_laplace(Y, zeros(p, K), β, π)
        ll_indep = sum(_zip_logpdf(π, μ[t], Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # Marginal → Poisson marginal as π → 0.
    # ---------------------------------------------------------------------
    @testset "marginal → Poisson marginal as π → 0" begin
        Random.seed!(901)
        p, K, n = 5, 2, 30
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0])
        Λ = 0.3 .* randn(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        ll_zip  = GLLVM.zip_marginal_loglik_laplace(Y, Λ, β, 1e-8)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_zip ≈ ll_pois atol = 1e-3
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6.
    # Packed θ = [β; vec(Λ); logit π]; π enters via the marker.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(903)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        π_true = 0.35
        rng = MersenneTwister(9031)
        Y = [_rand_zip(rng, π_true, 3.0) for t in 1:p, s in 1:n]
        logit_π = log(π_true / (1 - π_true))
        θ0 = vcat(β0, Λ0, logit_π)
        f = θ -> -GLLVM.zip_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._prob_from_logit(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "ZIP marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(904)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        π_true = 0.3
        rng = MersenneTwister(9041)
        Y = [_rand_zip(rng, π_true, 3.0) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, log(π_true / (1 - π_true)))
        family_fromθ = θ -> GLLVM.ZIP(GLLVM._prob_from_logit(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "ZIP implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' structure, π) within a generous MC band.
    # Convergence flag is INFORMATIONAL — recovery is asserted, not convergence.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', π)" begin
        Random.seed!(905)
        p, K, n = 6, 2, 800
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        π_true = 0.3
        Y = simulate(GLLVM.ZIP(π_true), β_true, Λ_true, n;
                     dispersion = π_true, seed = 9051)
        Yint = round.(Int, Y)
        @test count(==(0), Yint) > 0                # ZIP produces zeros
        fit = fit_zip_gllvm(Yint; K = K)
        @info "ZIP fit" converged=fit.converged π̂=fit.π loglik=fit.loglik
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.5
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        @test 0 < fit.π < 1
        @test fit.π ≈ π_true rtol = 0.5            # zero-inflation is identifiable-but-noisy
    end

    # ---------------------------------------------------------------------
    # link_residual: matches the zero-inflation-adjusted formula, finite & positive,
    # and reduces toward the Poisson log1p(1/μ̂) as π → 0.
    # ---------------------------------------------------------------------
    @testset "link_residual: zero-inflation-adjusted formula, finite & positive" begin
        Random.seed!(906)
        p, K, n = 4, 1, 400
        β_true = log.([4.0, 6.0, 3.0, 5.0])
        Λ_true = 0.4 .* randn(p, K)
        π_true = 0.3
        Y = round.(Int, simulate(GLLVM.ZIP(π_true), β_true, Λ_true, n;
                                 dispersion = π_true, seed = 9061))
        fit = fit_zip_gllvm(Y; K = K)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(isfinite, σ2d) && all(>(0), σ2d)
        # Single-arg formula: σ²_d = log1p((1+πμ)/((1−π)μ)).
        μ = 5.0; π = 0.3
        @test link_residual(GLLVM.ZIP(π), LogLink(), μ, π) ≈
              log1p((1 + π * μ) / ((1 - π) * μ))
        # π → 0 ⇒ reduces to the plain-Poisson log1p(1/μ̂).
        @test link_residual(GLLVM.ZIP(0.0), LogLink(), μ, 0.0) ≈ log1p(1 / μ)
    end
end
