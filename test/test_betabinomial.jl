using GLLVM, Test, Random, LinearAlgebra, Statistics, Distributions, ForwardDiff
using SpecialFunctions: trigamma

# Central finite-difference gradient. Stencil uses 2*step (Float64) — NOT a "2f0"
# Float32 literal, which would silently truncate the step to Float32 precision and
# wreck the ≤1e-6 comparison.
function _bb_central_fd_gradient(f, theta; h = 1e-6)
    g = similar(theta)
    @inbounds for i in eachindex(theta)
        step = h * max(1.0, abs(theta[i]))
        tp = copy(theta); tp[i] += step
        tm = copy(theta); tm[i] -= step
        g[i] = (f(tp) - f(tm)) / (2 * step)
    end
    return g
end

_bb_max_rel_err(a, b) = maximum(abs.(a .- b) ./ max.(1.0, abs.(b)))

# GLLVM reuses `Distributions.BetaBinomial` as the family marker, with the
# dispersion φ stored in the `.α` field (dummy n=1, β=1.0). `bb_marker(φ)` builds
# that marker; the real per-cell `BetaBinomial(N, a, b)` is used for the DGP /
# reference logpdf below (qualified where needed).
bb_marker(φ) = GLLVM._betabinomial_marker(φ)

@testset "Beta-Binomial family" begin

    # ---------------------------------------------------------------------
    # Marginal: φ → ∞ collapses to Binomial; Λ = 0 reduces to independent.
    # ---------------------------------------------------------------------
    @testset "BetaBinomial marginal → Binomial as φ → ∞" begin
        Random.seed!(801)
        p, K, n = 5, 2, 30
        Ntr = 12
        β = [0.3, -0.2, 0.5, 0.1, -0.4]
        Λ = 0.3 .* randn(p, K)
        N = fill(Ntr, p, n)
        μ = [1 / (1 + exp(-β[t])) for t in 1:p]
        Y = [rand(Binomial(Ntr, μ[t])) for t in 1:p, s in 1:n]
        ll_bb = GLLVM.betabinomial_marginal_loglik_laplace(Y, N, Λ, β, 1e7)
        ll_bin = GLLVM.binomial_marginal_loglik_laplace(Y, N, Λ, β, LogitLink())
        @test ll_bb ≈ ll_bin atol = 1e-2
    end

    @testset "BetaBinomial Λ = 0 reduces to independent regression loglik (exact)" begin
        Random.seed!(802)
        p, K, n = 4, 2, 40
        Ntr = 15
        β = [0.4, -0.3, 0.6, 0.0]
        φ = 6.0
        μ = [1 / (1 + exp(-β[t])) for t in 1:p]
        N = fill(Ntr, p, n)
        Y = [rand(BetaBinomial(Ntr, μ[t] * φ, (1 - μ[t]) * φ)) for t in 1:p, s in 1:n]
        ll = GLLVM.betabinomial_marginal_loglik_laplace(Y, N, zeros(p, K), β, φ)
        ll_indep = sum(logpdf(BetaBinomial(Ntr, μ[t] * φ, (1 - μ[t]) * φ), Y[t, s])
                       for t in 1:p, s in 1:n)
        @test ll ≈ ll_indep atol = 1e-7
    end

    # ---------------------------------------------------------------------
    # _glm_logpdf matches Distributions.BetaBinomial exactly (mean-param).
    # ---------------------------------------------------------------------
    @testset "_glm_logpdf == Distributions.BetaBinomial logpdf" begin
        φ = 7.5
        for (μ, Ntr, y) in [(0.3, 10, 3), (0.7, 20, 14), (0.5, 8, 0), (0.9, 12, 12)]
            ref = logpdf(BetaBinomial(Ntr, μ * φ, (1 - μ) * φ), y)
            got = GLLVM._glm_logpdf(bb_marker(φ), μ, Ntr, y)
            @test got ≈ ref atol = 1e-10
        end
    end

    # ---------------------------------------------------------------------
    # _glm_score is the exact ∂ℓ/∂η (vs ForwardDiff of _glm_logpdf wrt η).
    # ---------------------------------------------------------------------
    @testset "_glm_score == ∂(_glm_logpdf)/∂η (logit)" begin
        φ = 9.0
        link = LogitLink()
        for (η, Ntr, y) in [(0.4, 10, 3), (-0.6, 16, 9), (1.1, 8, 7)]
            f = bb_marker(φ)
            dη = ForwardDiff.derivative(
                ηx -> GLLVM._glm_logpdf(f, GLLVM.linkinv(link, ηx), Ntr, y), η)
            μ = GLLVM.linkinv(link, η)
            me = GLLVM.mu_eta(link, η)
            s = GLLVM._glm_score(f, μ, Ntr, me, y)
            @test s ≈ dη atol = 1e-9
        end
    end

    # ---------------------------------------------------------------------
    # FD gradient of the marginal (direct ForwardDiff packed objective).
    # ---------------------------------------------------------------------
    @testset "BetaBinomial marginal gradient: FD ≤ 1e-6" begin
        Random.seed!(803)
        p, n, K = 4, 8, 1
        Ntr = 12
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(0.2, p)
        Λ0 = GLLVM.pack_lambda(0.1 .* randn(p, K))
        φ_true = 6.0
        N = fill(Ntr, p, n)
        μ = [1 / (1 + exp(-β0[t])) for t in 1:p]
        Y = [rand(BetaBinomial(Ntr, μ[t] * φ_true, (1 - μ[t]) * φ_true)) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(φ_true))
        f = θ -> -GLLVM.betabinomial_marginal_loglik_laplace(
            Y, N, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
            exp(θ[p + rr + 1]))
        gad = ForwardDiff.gradient(f, θ0)
        gfd = _bb_central_fd_gradient(f, θ0)
        relerr = _bb_max_rel_err(gad, gfd)
        @info "BetaBinomial marginal FD-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # FD gradient of the IMPLICIT value+gradient the fit driver optimises.
    # ---------------------------------------------------------------------
    @testset "BetaBinomial implicit fit gradient matches FD ≤ 1e-6" begin
        Random.seed!(804)
        p, n, K = 4, 10, 1
        Ntr = 15
        rr = GLLVM.rr_theta_len(p, K)
        β0 = fill(0.1, p)
        Λ0 = GLLVM.pack_lambda(0.15 .* randn(p, K))
        φ_true = 8.0
        N = fill(Ntr, p, n)
        μ = [1 / (1 + exp(-β0[t])) for t in 1:p]
        Y = [rand(BetaBinomial(Ntr, μ[t] * φ_true, (1 - μ[t]) * φ_true)) for t in 1:p, s in 1:n]
        θ0 = vcat(β0, Λ0, log(φ_true))
        family_fromθ = θ -> bb_marker(GLLVM._positive_from_log(θ[end]))
        vg = θ -> GLLVM.marginal_loglik_laplace_implicit_value_grad(
            family_fromθ, Y, N, θ, p, K, LogitLink())
        _, gimp = vg(θ0)
        f = θ -> vg(θ)[1]
        gfd = _bb_central_fd_gradient(f, θ0)
        relerr = _bb_max_rel_err(gimp, gfd)
        @info "BetaBinomial implicit fit-grad max rel err" relerr
        @test relerr ≤ 1e-6
    end

    # ---------------------------------------------------------------------
    # simulate → fit → recover planted (β, ΛΛ', φ). Convergence flag is
    # INFORMATIONAL — we assert RECOVERY, not fit.converged.
    # ---------------------------------------------------------------------
    @testset "BetaBinomial simulate → fit → recover (β, ΛΛ', φ)" begin
        Random.seed!(805)
        p, K, n = 6, 2, 600
        Ntr = 20
        β_true = [0.5, -0.4, 0.8, 0.2, -0.6, 0.3]
        Λ_true = 0.6 .* randn(p, K)
        φ_true = 8.0
        N = fill(Ntr, p, n)
        Y = simulate(bb_marker(φ_true), β_true, Λ_true, n;
                     dispersion = φ_true, N = N, seed = 8051)
        Yint = round.(Int, Y)
        fit = fit_betabinomial_gllvm(Yint; K = K, N = N)
        @info "BetaBinomial fit" converged=fit.converged φ̂=fit.φ
        @test fit isa BetaBinomialFit
        @test size(fit.Λ) == (p, K)
        @test cor(fit.β, β_true) > 0.8
        @test cor(vec(fit.Λ * fit.Λ'), vec(Λ_true * Λ_true')) > 0.6
        @test isfinite(fit.φ) && fit.φ > 0
        # Dispersion is identifiable-but-noisy under Laplace; generous MC band.
        @test 0.4 * φ_true < fit.φ < 2.5 * φ_true
    end

    @testset "fit_gllvm(family=BetaBinomial()) dispatches to BetaBinomialFit" begin
        Random.seed!(806)
        p, n = 5, 200
        Ntr = 15
        β = 0.3 .* randn(p); Λ = 0.5 .* randn(p, 1)
        N = fill(Ntr, p, n)
        φ = 7.0
        Y = round.(Int, simulate(bb_marker(φ), β, Λ, n;
                                 dispersion = φ, N = N, seed = 8061))
        f = fit_gllvm(Y; family = bb_marker(1.0), K = 1, N = N)
        @test f isa BetaBinomialFit
        @test f.link isa LogitLink
    end

    # ---------------------------------------------------------------------
    # link_residual: π²/3 + trigamma(μ̂φ) + trigamma((1−μ̂)φ) (extract-sigma.R fid 8).
    # ---------------------------------------------------------------------
    @testset "BetaBinomial link_residual: formula + finite, > binomial baseline" begin
        Random.seed!(807)
        p, K, n = 4, 1, 300
        Ntr = 18
        β_true = [0.5, -0.3, 0.7, 0.1]
        Λ_true = 0.4 .* randn(p, K)
        φ_true = 6.0
        N = fill(Ntr, p, n)
        Y = round.(Int, simulate(bb_marker(φ_true), β_true, Λ_true, n;
                                 dispersion = φ_true, N = N, seed = 8071))
        fit = fit_betabinomial_gllvm(Y; K = K, N = N)
        σ2d = link_residual(fit, Y; N = N)
        @test length(σ2d) == p
        @test all(isfinite, σ2d)
        # Each entry strictly exceeds the binomial-logit baseline π²/3 (overdispersion).
        @test all(σ2d .> π^2 / 3)
        # Single-arg formula matches the closed form at a representative μ̂.
        μ̂ = 0.6
        @test link_residual(bb_marker(fit.φ), LogitLink(), μ̂, fit.φ) ≈
              π^2 / 3 + trigamma(μ̂ * fit.φ) + trigamma((1 - μ̂) * fit.φ)
    end
end
