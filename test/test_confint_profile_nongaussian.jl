using GLLVM, Test, Random, LinearAlgebra, Distributions

# Oracle for a profile-likelihood bound: the defining equation is
#   D(c*) = 2(ℓ̂ - max_{θ_{-i}} ℓ(θ_i = c*)) = χ²_{1,level} cutoff.
# We recompute the constrained profile log-lik at the returned bound (on the
# WORKING/packed scale) via the same generic refit the engine uses, and check
# the deviance lands on the cutoff to bisection precision.
function _dev_at(nll, θ̂, i, c_working, ll_full)
    warm = vcat(θ̂[1:(i - 1)], θ̂[(i + 1):end])
    ll_c, ok, _ = GLLVM._profile_refit_generic(nll, θ̂, i, c_working, warm)
    return ok ? 2.0 * (ll_full - ll_c) : NaN
end
const CUT95 = quantile(Chisq(1), 0.95)

@testset "Poisson profile CI (LRT inversion)" begin
    Random.seed!(20260620)
    p, K, n = 5, 2, 200
    Λ_true = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.3 .- 0.3
    M = Λ_true * randn(K, n) .+ β_true
    Y = [rand(Poisson(exp(clamp(M[t, s], -30, 30)))) for t in 1:p, s in 1:n]
    fit = GLLVM.fit_poisson_gllvm(Y; K = K)
    @test fit.converged

    rr = GLLVM.rr_theta_len(p, K)
    θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ))
    nll(θ) = -GLLVM.poisson_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], fit.link)

    ci = GLLVM.profile_ci(fit, "beta[1]"; y = Y)
    @test ci.method == :profile
    @test ci.lower < fit.β[1] < ci.upper
    # defining property: deviance at each bound equals the χ²₁ cutoff
    @test abs(_dev_at(nll, θ̂, 1, ci.lower, fit.loglik) - CUT95) < 0.2
    @test abs(_dev_at(nll, θ̂, 1, ci.upper, fit.loglik) - CUT95) < 0.2

    # profile interval should sit in the Wald ballpark (near-quadratic here)
    w = GLLVM.confint(fit; y = Y, parm = "beta[1]")
    ratio = (ci.upper - ci.lower) / (w.upper[1] - w.lower[1])
    @test 0.5 < ratio < 2.0

    # integer index path agrees with the name path
    ci_idx = GLLVM.profile_ci(fit, 1; y = Y)
    @test ci_idx.lower ≈ ci.lower atol = 1e-3
end

@testset "Negative Binomial profile CI (dispersion on log scale)" begin
    Random.seed!(20260621)
    p, K, n = 4, 2, 250
    Λ_true = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    β_true = randn(p) .* 0.3 .+ 1.0
    r_true = 5.0
    μ = exp.(clamp.(Λ_true * randn(K, n) .+ β_true, -30, 30))
    Y = [rand(NegativeBinomial(r_true, r_true / (r_true + μ[t, s]))) for t in 1:p, s in 1:n]
    fit = GLLVM.fit_nb_gllvm(Y; K = K)
    @test fit.converged

    rr = GLLVM.rr_theta_len(p, K)
    θ̂ = vcat(fit.β, GLLVM.pack_lambda(fit.Λ), log(fit.r))
    nll(θ) = -GLLVM.nb_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p],
        exp(θ[p + rr + 1]); link = fit.link)

    # dispersion: reported on the natural (positive) scale, profiled on log
    ci = GLLVM.profile_ci(fit, "r"; y = Y)
    @test ci.method == :profile
    @test ci.lower > 0
    @test ci.lower < fit.r < ci.upper
    idx = p + rr + 1
    @test abs(_dev_at(nll, θ̂, idx, log(ci.lower), fit.loglik) - CUT95) < 0.3
    @test abs(_dev_at(nll, θ̂, idx, log(ci.upper), fit.loglik) - CUT95) < 0.3

    # an identity-scale intercept too
    cib = GLLVM.profile_ci(fit, "beta[1]"; y = Y)
    @test cib.method == :profile
    @test cib.lower < fit.β[1] < cib.upper
end

@testset "Ordinal profile CI (cutpoints, no intercept)" begin
    Random.seed!(20260622)
    p, K, n = 5, 2, 350
    C = 4
    Λ_true = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λ_true[i, k] = 0.0)
    end
    τ_true = [-1.2, 0.0, 1.2]
    M = Λ_true * randn(K, n)
    _F(x) = 1.0 / (1.0 + exp(-x))
    _draw(η, τ, u) = (for c in 1:length(τ); u <= _F(τ[c] - η) && return c; end; length(τ) + 1)
    Y = [_draw(M[t, s], τ_true, rand()) for t in 1:p, s in 1:n]
    fit = GLLVM.fit_ordinal_gllvm(Y; K = K)
    @test fit.converged

    rr = GLLVM.rr_theta_len(p, K)
    θ̂ = vcat(GLLVM.pack_lambda(fit.Λ), fit.τ)
    nll(θ) = -GLLVM.ordinal_marginal_loglik_laplace(
        Y, GLLVM.unpack_lambda(θ[1:rr], p, K), θ[(rr + 1):(rr + C - 1)])

    ci = GLLVM.profile_ci(fit, "tau[1]"; y = Y)
    @test ci.method == :profile
    @test ci.lower < fit.τ[1] < ci.upper
    @test abs(_dev_at(nll, θ̂, rr + 1, ci.lower, fit.loglik) - CUT95) < 0.3
    @test abs(_dev_at(nll, θ̂, rr + 1, ci.upper, fit.loglik) - CUT95) < 0.3
end

@testset "Binomial / Beta / Gamma profile CI (smoke + bracketing)" begin
    # Binomial (Bernoulli)
    Random.seed!(20260623)
    p, K, n = 4, 2, 250
    Λb = randn(p, K) .* 0.5
    for i in 1:K, k in 1:K
        i < k && (Λb[i, k] = 0.0)
    end
    βb = randn(p) .* 0.4
    Pr = 1.0 ./ (1.0 .+ exp.(-clamp.(Λb * randn(K, n) .+ βb, -30, 30)))
    Yb = [rand() < Pr[t, s] ? 1 : 0 for t in 1:p, s in 1:n]
    fb = GLLVM.fit_binomial_gllvm(Yb; K = K)
    @test fb.converged
    cb = GLLVM.profile_ci(fb, "beta[1]"; y = Yb)
    @test cb.method in (:profile, :partial)
    @test (isnan(cb.lower) || cb.lower < fb.β[1]) && (isnan(cb.upper) || fb.β[1] < cb.upper)

    # Beta (precision dispersion on log scale)
    Random.seed!(20260624)
    p, K, n = 4, 2, 250
    Λβ = randn(p, K) .* 0.4
    for i in 1:K, k in 1:K
        i < k && (Λβ[i, k] = 0.0)
    end
    ββ = randn(p) .* 0.3
    φ_true = 12.0
    μ = 1.0 ./ (1.0 .+ exp.(-clamp.(Λβ * randn(K, n) .+ ββ, -30, 30)))
    Yβ = [rand(Beta(μ[t, s] * φ_true, (1 - μ[t, s]) * φ_true)) for t in 1:p, s in 1:n]
    fβ = GLLVM.fit_beta_gllvm(Yβ; K = K)
    @test fβ.converged
    cβ = GLLVM.profile_ci(fβ, "phi"; y = Yβ)
    @test cβ.method in (:profile, :partial)
    @test isnan(cβ.lower) || cβ.lower > 0

    # Gamma (shape dispersion on log scale)
    Random.seed!(20260625)
    p, K, n = 4, 2, 250
    Λg = randn(p, K) .* 0.3
    for i in 1:K, k in 1:K
        i < k && (Λg[i, k] = 0.0)
    end
    βg = randn(p) .* 0.2 .+ 0.5
    α_true = 8.0
    μg = exp.(clamp.(Λg * randn(K, n) .+ βg, -30, 30))
    Yg = [rand(Gamma(α_true, μg[t, s] / α_true)) for t in 1:p, s in 1:n]
    fg = GLLVM.fit_gamma_gllvm(Yg; K = K)
    @test fg.converged
    cg = GLLVM.profile_ci(fg, "alpha"; y = Yg)
    @test cg.method in (:profile, :partial)
    @test isnan(cg.lower) || cg.lower > 0
end
