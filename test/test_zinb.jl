using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff

# Central finite-difference gradient (matches test/test_zip.jl). The FD step is in
# θ's Float64 precision to hit the ≤1e-6 target.
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

# Closed-form ZINB logpdf reference: π·δ₀ + (1−π)·NB2(μ, r), p = r/(r+μ).
function _zinb_logpdf(r, π, μ, k)
    g = (r / (r + μ))^r
    if k == 0
        return log(π + (1 - π) * g)
    else
        return log1p(-π) + logpdf(NegativeBinomial(r, r / (r + μ)), k)
    end
end

# Draw one ZINB(r, π, μ) (reference DGP for tests).
_rand_zinb(rng, r, π, μ) = rand(rng) < π ? 0 : rand(rng, NegativeBinomial(r, r / (r + μ)))

@testset "Zero-inflated negative binomial (ZINB)" begin

    # ---------------------------------------------------------------------
    # Family pieces: score / weight / logpdf sanity against the spec.
    # ---------------------------------------------------------------------
    @testset "score, weight, logpdf match the ZINB spec" begin
        for r in (2.0, 8.0, 25.0), π in (0.1, 0.3, 0.5), μ in (0.5, 1.0, 3.0, 7.0)
            fam = GLLVM.ZINB(r, π)
            g = (r / (r + μ))^r
            p0 = π + (1 - π) * g
            V = μ + μ^2 / r
            # logpdf: y=0 mixes both parts; y>0 is log(1−π)+NB2 logpdf.
            @test GLLVM._glm_logpdf(fam, μ, 1, 0.0) ≈ log(p0)
            @test GLLVM._glm_logpdf(fam, μ, 1, 4.0) ≈
                  log1p(-π) + logpdf(NegativeBinomial(r, r / (r + μ)), 4)
            # logpdf is a normalised pmf over k = 0,1,2,…
            @test sum(exp(_zinb_logpdf(r, π, μ, k)) for k in 0:2000) ≈ 1.0 atol = 1e-7
            # score: y>0 is the NB2 score r(y−μ)/(r+μ) (π-free); y=0 the zero cell.
            @test GLLVM._glm_score(fam, μ, 1, μ, 5.0) ≈ (5.0 - μ) * r / (r + μ)
            @test GLLVM._glm_score(fam, μ, 1, μ, 0.0) ≈ -(1 - π) * g * r * μ / ((r + μ) * p0)
            # weight = expected Fisher information E[s²] ≥ 0.
            zero_term  = (1 - π)^2 * g^2 * r^2 * μ^2 / ((r + μ)^2 * p0)
            count_term = (1 - π) * (μ^2 / V) * (1 - g * μ^2 / V)
            @test GLLVM._glm_weight(fam, μ, 1, μ) ≈ zero_term + count_term
            @test GLLVM._glm_weight(fam, μ, 1, μ) > 0
        end
    end

    # ---------------------------------------------------------------------
    # π → 0 reduces every family piece to the NB2 (the un-inflated parent).
    # ---------------------------------------------------------------------
    @testset "π = 0 reduces to NB2 pieces" begin
        for r in (2.0, 10.0), μ in (0.5, 2.0, 6.0)
            zfam = GLLVM.ZINB(r, 0.0)
            nfam = NegativeBinomial(r, 0.5)   # codebase NB2 marker (only r used)
            @test GLLVM._glm_score(zfam, μ, 1, μ, 0.0) ≈ GLLVM._glm_score(nfam, μ, 1, μ, 0.0)
            @test GLLVM._glm_score(zfam, μ, 1, μ, 4.0) ≈ GLLVM._glm_score(nfam, μ, 1, μ, 4.0)
            @test GLLVM._glm_weight(zfam, μ, 1, μ) ≈ GLLVM._glm_weight(nfam, μ, 1, μ)
            @test GLLVM._glm_logpdf(zfam, μ, 1, 3.0) ≈ GLLVM._glm_logpdf(nfam, μ, 1, 3.0)
        end
    end

    # ---------------------------------------------------------------------
    # r → ∞ reduces logpdf to the ZIP (the no-overdispersion parent).
    # ---------------------------------------------------------------------
    @testset "r → ∞ reduces logpdf to ZIP" begin
        for π in (0.1, 0.3), μ in (0.5, 2.0, 6.0)
            zinbfam = GLLVM.ZINB(1e8, π)
            zipfam = GLLVM.ZIP(π)
            @test GLLVM._glm_logpdf(zinbfam, μ, 1, 0.0) ≈ GLLVM._glm_logpdf(zipfam, μ, 1, 0.0) rtol = 1e-5
            @test GLLVM._glm_logpdf(zinbfam, μ, 1, 3.0) ≈ GLLVM._glm_logpdf(zipfam, μ, 1, 3.0) rtol = 1e-5
        end
    end

    # ---------------------------------------------------------------------
    # Λ = 0 reduces to the independent ZINB-regression loglik (exact).
    # ---------------------------------------------------------------------
    @testset "Λ = 0 reduces to independent ZINB-regression loglik (exact)" begin
        Random.seed!(1102)
        p, K, n = 4, 2, 50
        β = log.([2.0, 3.0, 1.5, 2.5])
        μ = exp.(β)
        r, π = 6.0, 0.3
        rng = MersenneTwister(11021)
        Y = [_rand_zinb(rng, r, π, μ[t]) for t in 1:p, s in 1:n]
        ll = GLLVM.zinb_marginal_loglik_laplace(Y, zeros(p, K), β, r, π)
        ll_indep = sum(_zinb_logpdf(r, π, μ[t], Y[t, s]) for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # Marginal → NB2 marginal as π → 0; → ZIP marginal as r → ∞.
    # ---------------------------------------------------------------------
    @testset "marginal reduces to NB2 (π→0) and ZIP (r→∞)" begin
        Random.seed!(1101)
        p, K, n = 5, 2, 30
        β = log.([4.0, 6.0, 3.0, 5.0, 4.0])
        Λ = 0.3 .* randn(p, K)
        Y = [rand(NegativeBinomial(8.0, 8.0 / (8.0 + exp(β[t])))) for t in 1:p, s in 1:n]
        ll_zinb = GLLVM.zinb_marginal_loglik_laplace(Y, Λ, β, 8.0, 1e-8)
        ll_nb   = GLLVM.nb_marginal_loglik_laplace(Y, Λ, β, 8.0)
        @test ll_zinb ≈ ll_nb atol = 1e-3
        ll_zinb2 = GLLVM.zinb_marginal_loglik_laplace(Y, Λ, β, 1e8, 0.2)
        ll_zip   = GLLVM.zip_marginal_loglik_laplace(Y, Λ, β, 0.2)
        @test ll_zinb2 ≈ ll_zip rtol = 1e-4
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (ForwardDiff vs central differences) ≤ 1e-6.
    # Packed θ = [β; vec(Λ); log r; logit π]; r, π enter via the marker.
    # ---------------------------------------------------------------------
    @testset "marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(1103)
        p, n, K = 4, 8, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        r_true, π_true = 7.0, 0.35
        rng = MersenneTwister(11031)
        Y = [_rand_zinb(rng, r_true, π_true, 3.0) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(r_true), log(π_true / (1 - π_true)))
        f = θ -> -GLLVM.zinb_marginal_loglik_laplace(
            Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            GLLVM._positive_from_log(θ[p + rr + 1]), GLLVM._prob_from_logit(θ[p + rr + 2]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gad, gfd)
        @info "ZINB marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # The implicit value+gradient the fitter actually optimises vs FD ≤ 1e-6.
    # ---------------------------------------------------------------------
    @testset "implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(1104)
        p, n, K = 4, 10, 1
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(log(3.0), p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        r_true, π_true = 6.0, 0.3
        rng = MersenneTwister(11041)
        Y = [_rand_zinb(rng, r_true, π_true, 3.0) for t in 1:p, s in 1:n]
        N = ones(Int, p, n)
        θ0 = vcat(β0, Λ0, log(r_true), log(π_true / (1 - π_true)))
        family_fromθ = θ -> GLLVM.ZINB(GLLVM._positive_from_log(θ[end - 1]),
                                       GLLVM._prob_from_logit(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _central_fd_gradient(f, θ0)
        relerr = _max_rel_err(gimp, gfd)
        @info "ZINB implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover (β, ΛΛ' structure, π). Convergence flag and r̂ are
    # INFORMATIONAL — structure recovery is asserted, not tight MC on the
    # dispersion (r and π both act on zeros, so each is identifiable-but-noisy).
    # ---------------------------------------------------------------------
    @testset "simulate → fit → recover (β, ΛΛ', π)" begin
        Random.seed!(1105)
        p, K, n = 6, 2, 1200
        β_true = log.([4.0, 6.0, 3.0, 5.0, 4.0, 7.0])
        Λ_true = 0.5 .* randn(p, K)
        r_true, π_true = 6.0, 0.3
        Y = simulate(GLLVM.ZINB(r_true, π_true), β_true, Λ_true, n; seed = 11051)
        Yint = round.(Int, Y)
        @test count(==(0), Yint) > 0                # ZINB produces zeros
        fit = fit_zinb_gllvm(Yint; K = K)
        @info "ZINB fit" converged=fit.converged r̂=fit.r π̂=fit.π loglik=fit.loglik
        @test size(fit.Λ) == (p, K)
        @test maximum(abs.(fit.β .- β_true)) < 0.6
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.5
        @test 0 < fit.π < 1
        @test isfinite(fit.r) && fit.r > 0
        @test fit.π ≈ π_true rtol = 0.6            # noisy but identifiable
    end

    # ---------------------------------------------------------------------
    # link_residual: ZINB-adjusted formula, finite & positive, and reduces to the
    # ZIP form (r→∞) and the NB2 delta residual log1p(1/μ̂+1/r) (π→0).
    # ---------------------------------------------------------------------
    @testset "link_residual: ZINB-adjusted formula, finite & positive" begin
        Random.seed!(1106)
        p, K, n = 4, 1, 500
        β_true = log.([4.0, 6.0, 3.0, 5.0])
        Λ_true = 0.4 .* randn(p, K)
        r_true, π_true = 6.0, 0.3
        Y = round.(Int, simulate(GLLVM.ZINB(r_true, π_true), β_true, Λ_true, n; seed = 11061))
        fit = fit_zinb_gllvm(Y; K = K)
        σ2d = link_residual(fit, Y)
        @test length(σ2d) == p
        @test all(isfinite, σ2d) && all(>(0), σ2d)
        # Scalar formula: σ²_d = log1p((1/μ + 1/r + 1)/(1−π) − 1) (r, π from the marker).
        μ = 5.0; r = 8.0; π = 0.3
        @test link_residual(GLLVM.ZINB(r, π), LogLink(), μ, nothing) ≈
              log1p((1 / μ + 1 / r + 1) / (1 - π) - 1)
        # π → 0 ⇒ NB2 delta residual log1p(1/μ + 1/r).
        @test link_residual(GLLVM.ZINB(r, 0.0), LogLink(), μ, nothing) ≈ log1p(1 / μ + 1 / r)
        # r → ∞ ⇒ ZIP residual log1p((1+πμ)/((1−π)μ)).
        @test link_residual(GLLVM.ZINB(1e8, π), LogLink(), μ, nothing) ≈
              log1p((1 + π * μ) / ((1 - π) * μ)) rtol = 1e-4
    end
end
