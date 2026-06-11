using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff
using SpecialFunctions: loggamma

# Central finite-difference gradient (matches test/test_zip.jl, test/test_zinb.jl).
# The FD step is in θ's Float64 precision to hit the ≤1e-6 target.
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

# ---------------------------------------------------------------------------
# Self-contained COM-Poisson reference (rate parameterisation): independent of
# GLLVM internals so the tests verify, not echo. logZ by a generous truncated
# log-sum-exp; logpdf, moments, and an inverse-CDF sampler built from it.
# ---------------------------------------------------------------------------
function _ref_compois_logZ(λ, ν; J = 5000)
    logλ = log(λ)
    terms = [j * logλ - ν * loggamma(j + 1.0) for j in 0:J]
    m = maximum(terms)
    return m + log(sum(exp.(terms .- m)))
end

_ref_compois_logpdf(λ, ν, y; J = 5000) =
    y * log(λ) - ν * loggamma(y + 1.0) - _ref_compois_logZ(λ, ν; J = J)

function _ref_compois_moments(λ, ν; J = 5000)
    logλ = log(λ)
    logZ = _ref_compois_logZ(λ, ν; J = J)
    Ey = 0.0; Ey2 = 0.0
    for j in 0:J
        pj = exp(j * logλ - ν * loggamma(j + 1.0) - logZ)
        Ey += j * pj
        Ey2 += j^2 * pj
    end
    return Ey, Ey2 - Ey^2
end

# Inverse-CDF COM-Poisson draw (rate λ, dispersion ν).
function _rand_compois(rng, λ, ν; J = 5000)
    logλ = log(λ)
    logZ = _ref_compois_logZ(λ, ν; J = J)
    u = rand(rng)
    acc = 0.0
    for j in 0:J
        acc += exp(j * logλ - ν * loggamma(j + 1.0) - logZ)
        u ≤ acc && return j
    end
    return J
end

@testset "Conway–Maxwell–Poisson (COM-Poisson)" begin

    # ---------------------------------------------------------------------
    # Family pieces: logpdf / score / weight against the self-contained spec.
    # ---------------------------------------------------------------------
    @testset "logpdf, score, weight match the COM-Poisson spec" begin
        for ν in (0.6, 1.0, 1.5, 2.0), λ in (0.5, 1.0, 3.0, 6.0)
            fam = GLLVM.CMPoisson(ν)
            # logpdf vs the reference closed form.
            for y in (0.0, 1.0, 3.0, 7.0)
                @test GLLVM._glm_logpdf(fam, λ, 1, y) ≈ _ref_compois_logpdf(λ, ν, y) rtol = 1e-8
            end
            # logpdf is a normalised pmf over k = 0,1,2,…
            @test sum(exp(GLLVM._glm_logpdf(fam, λ, 1, Float64(k))) for k in 0:3000) ≈ 1.0 atol = 1e-7
            # score s = y − E[y]; weight W = Var[y] ≥ 0 (expected Fisher info).
            Ey, Vy = _ref_compois_moments(λ, ν)
            @test GLLVM._glm_score(fam, λ, 1, λ, 5.0) ≈ 5.0 - Ey rtol = 1e-7
            @test GLLVM._glm_weight(fam, λ, 1, λ) ≈ Vy rtol = 1e-7
            @test GLLVM._glm_weight(fam, λ, 1, λ) > 0
        end
    end

    # ---------------------------------------------------------------------
    # ν → 1 reduces every family piece to the plain Poisson (the parent).
    # logZ → λ, logpdf → Poisson logpdf, E[y] → λ ⇒ s → y − λ, Var[y] → λ.
    # ---------------------------------------------------------------------
    @testset "ν = 1 reduces to Poisson pieces" begin
        for λ in (0.5, 2.0, 6.0)
            cfam = GLLVM.CMPoisson(1.0)
            pfam = Poisson()
            @test GLLVM._glm_logpdf(cfam, λ, 1, 0.0) ≈ GLLVM._glm_logpdf(pfam, λ, 1, 0.0) rtol = 1e-8
            @test GLLVM._glm_logpdf(cfam, λ, 1, 3.0) ≈ GLLVM._glm_logpdf(pfam, λ, 1, 3.0) rtol = 1e-8
            @test GLLVM._glm_score(cfam, λ, 1, λ, 4.0) ≈ GLLVM._glm_score(pfam, λ, 1, λ, 4.0) rtol = 1e-7
            @test GLLVM._glm_weight(cfam, λ, 1, λ) ≈ GLLVM._glm_weight(pfam, λ, 1, λ) rtol = 1e-7
        end
    end

    # ---------------------------------------------------------------------
    # Marginal → Poisson marginal as ν → 1 (the limiting reduction to a parent).
    # ---------------------------------------------------------------------
    @testset "marginal → Poisson marginal as ν → 1" begin
        Random.seed!(1201)
        p, K, n = 5, 2, 30
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0])
        Λ = 0.3 .* randn(p, K)
        Y = [rand(Poisson(exp(β[t]))) for t in 1:p, s in 1:n]
        ll_cmp  = GLLVM.compoisson_marginal_loglik_laplace(Y, Λ, β, 1.0)
        ll_pois = GLLVM.poisson_marginal_loglik_laplace(Y, Λ, β)
        @test ll_cmp ≈ ll_pois rtol = 1e-6
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent COM-Poisson-regression loglik (exact).
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent COM-Poisson-regression loglik (exact)" begin
        Random.seed!(1202)
        p, K, n = 4, 2, 50
        β = log.([2.0, 3.0, 1.5, 2.5])
        λ = exp.(β)
        ν = 1.4
        rng = MersenneTwister(12021)
        Y = [_rand_compois(rng, λ[t], ν) for t in 1:p, s in 1:n]
        ll = GLLVM.compoisson_marginal_loglik_laplace(Y, zeros(p, K), β, ν)
        ll_indep = sum(_ref_compois_logpdf(λ[t], ν, Float64(Y[t, s])) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-6
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6.
    # Packed θ = [β; vec(Λ); log ν]; ν enters via the marker. This is the load-
    # bearing AD-cleanliness check on the truncated logZ wrt η and ν.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(1203)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        ν_true = 1.5
        rng = MersenneTwister(12031)
        Y = [_rand_compois(rng, 3.0, ν_true) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(ν_true))
        f = θ -> -GLLVM.compoisson_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._positive_from_log(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "COM-Poisson marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(1204)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        ν_true = 1.4
        rng = MersenneTwister(12041)
        Y = [_rand_compois(rng, 3.0, ν_true) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, log(ν_true))
        family_fromθ = θ -> GLLVM.CMPoisson(GLLVM._positive_from_log(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "COM-Poisson implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' structure, ν). Convergence flag is
    # INFORMATIONAL — structure recovery is asserted, with a generous MC band on
    # the (identifiable-but-noisy) dispersion ν. Uses mild under-dispersion
    # (ν > 1) so the truncated sum stays light and the tail well-behaved.
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', ν)" begin
        Random.seed!(1205)
        p, K, n = 6, 2, 1000
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        ν_true = 1.5
        Y = simulate(GLLVM.CMPoisson(ν_true), β_true, Λ_true, n;
                     dispersion = ν_true, seed = 12051)
        Yint = round.(Int, Y)
        fit = fit_compoisson_gllvm(Yint; K = K)
        @info "COM-Poisson fit" converged=fit.converged ν̂=fit.ν loglik=fit.loglik
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.6
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.5
        @test isfinite(fit.ν) && fit.ν > 0
        @test fit.ν ≈ ν_true rtol = 0.5            # dispersion is identifiable-but-noisy
    end
end
