# Zero-inflated negative-binomial (NB2) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ {0,1,2,…}: a mixture of a structural-zero point
# mass and an NB2 count,
#
#   y ~ π·δ₀ + (1−π)·NB2(μ, r),   μ = exp(η)  (log link),   Var_NB = μ + μ²/r,
#
# where the shared latent enters ONLY the count rate μ (η = β_t + (Λ z)_t). There are
# TWO scalar auxiliaries: the NB2 dispersion r on the log scale (aux₁ = log r) and the
# zero-inflation probability π ∈ (0,1) on the logit scale (aux₂ = log(π/(1−π))). Both
# are constants shared across traits (the NB2/ZIP scalar-aux convention); modelling π
# or r on the latent is a follow-up. As r → ∞ this reduces to ZIP; as π → 0 to NB2.
# (Lambert 1992, Technometrics 34, 1–14; Greene 1994, NYU EC-94-10, for ZINB.)
#
# Marginal zero mass p₀ = π + (1−π)·g, with g = (r/(r+μ))^r the NB2 zero mass q^r.
# Conditional log-density:
#   y = 0:  log p₀ = log(π + (1−π) g)
#   y > 0:  log(1−π) + logNB2(y; μ, r)
#
# Score wrt η (log link, dμ/dη = me; rpμ = r+μ, V = μ+μ²/r the NB2 variance). The
# y>0 cell is the plain NB2 score (it does NOT involve π); the zero cell mixes π and
# the NB2 zero:
#   y > 0:  s = me (y − μ)/V                 [= r(y−μ)/rpμ at the log link]
#   y = 0:  s = ∂/∂η log p₀ = −(1−π) g r me /(rpμ · p₀)
#
# Weight wrt η = the EXPECTED (Fisher) information I(η) = E[s²] under the model at η
# (a positive working weight, so Λ'WΛ + I stays SPD — the expected-information
# convention used by Poisson/NB/ZIP in this codebase). With NB2 variance V,
#   I(η) = p₀ s₀² + (1−π)(me²/V)(1 − g μ²/V)   ≥ 0.
# At π → 0 (p₀ → g) this reduces ALGEBRAICALLY to the NB2 weight me²/V; at r → ∞ it
# reduces to the ZIP weight (both reductions are exact — used as test oracles).
#
# `_glm_logpdf`/`_glm_score`/`_glm_weight` are CLOSED FORM (NB2 logpdf via `loggamma`,
# no Distributions mixture object), so ForwardDiff Duals flow cleanly through η (via μ)
# and BOTH auxiliaries (via r and π). This keeps the GENERIC implicit dense-Laplace
# gradient (`marginal_loglik_laplace_implicit_value_grad`) AD-clean for ZINB (the ZIP
# pattern with a second auxiliary; no hand-coded kernel).

"""
    ZINB(r, π)

Zero-inflated negative-binomial (NB2) family marker: counts `y ∈ {0,1,2,…}` from the
mixture `π·δ₀ + (1−π)·NB2(μ, r)` with log link (`μ = exp η`, `Var = μ + μ²/r`). The
latent variable enters only the count rate `μ`; `r > 0` is the (shared, constant) NB2
dispersion and `π ∈ (0,1)` the (shared, constant) zero-inflation probability. As
`r → ∞` this reduces to [`ZIP`](@ref); as `π → 0` to the negative-binomial family.
"""
struct ZINB{T<:Real}
    r::T
    π::T
end
ZINB(r::Real, π::Real) = ZINB(promote(r, π)...)

default_link(::ZINB) = LogLink()

_clamp_mu(::ZINB, μ) = max(μ, 1e-12)

# Closed-form NB2 log pmf (mean-parameterised), AD-clean via `loggamma` (mirrors the
# NB2 kernel in laplace.jl): logΓ(y+r) − logΓ(r) − logΓ(y+1) + r(log r − log rpμ)
# + y(log μ − log rpμ).
@inline function _zinb_nb2_logpdf(r, μ, y)
    rpμ = r + μ
    logrpμ = log(rpμ)
    return loggamma(y + r) - loggamma(r) - loggamma(y + one(r)) +
           r * (log(r) - logrpμ) + y * (log(μ) - logrpμ)
end

function _glm_score(f::ZINB, μ, n, me, y)
    r = f.r; π = f.π
    if y > 0
        return me * (y - μ) / (μ + μ^2 / r)                 # NB2 count score (no π dependence)
    else
        rpμ = r + μ
        g = (r / rpμ)^r                                     # NB2 zero mass q^r
        p0 = π + (one(π) - π) * g
        return -(one(π) - π) * g * r * me / (rpμ * p0)      # zero-cell score wrt η
    end
end

function _glm_weight(f::ZINB, μ, n, me)
    r = f.r; π = f.π
    rpμ = r + μ
    g = (r / rpμ)^r
    p0 = π + (one(π) - π) * g
    V = μ + μ^2 / r
    zero_term  = (one(π) - π)^2 * g^2 * r^2 * me^2 / (rpμ^2 * p0)
    count_term = (one(π) - π) * (me^2 / V) * (one(π) - g * μ^2 / V)
    return zero_term + count_term                           # E[s²] ≥ 0 (Fisher info)
end

function _glm_logpdf(f::ZINB, μ, n, y)
    r = f.r; π = f.π
    if y > 0
        return log1p(-π) + _zinb_nb2_logpdf(r, μ, float(y))    # log(1−π) + logNB2
    else
        return log(π + (one(π) - π) * (r / (r + μ))^r)         # log p₀
    end
end

"""
    zinb_marginal_loglik_laplace(Y, Λ, β, r, π; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a zero-inflated NB2 (ZINB)
GLLVM with dispersion `r` and zero-inflation probability `π` — a thin wrapper over the
family-generic `marginal_loglik_laplace` with the `ZINB(r, π)` marker. `Y` is the p×n
integer count matrix; `Λ` p×K; `β` length-p. As `r → ∞` this tends to the ZIP
marginal; as `π → 0` to the NB2 marginal. ZINB has no trial counts, so a unit `N` is
supplied internally.
"""
zinb_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        r::Real, π::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(ZINB(float(r), float(π)), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    ZINBFit

Result of [`fit_zinb_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated NB2 dispersion `r` (Var = μ + μ²/r) and the (shared, constant)
zero-inflation probability `π`, the `link`, the maximised Laplace `loglik`, the
optimiser `converged` flag, and `iterations`.
"""
struct ZINBFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r::Float64
    π::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ZINBFit)
    p, K = size(f.Λ)
    print(io, "ZINBFit(p=", p, ", K=", K, ", r=", round(f.r; sigdigits = 4),
          ", π=", round(f.π; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_zinb_gllvm(Y; K, link=LogLink(), r_init=nothing, π_init=nothing, …) -> ZINBFit

Fit a zero-inflated NB2 (ZINB) GLLVM by L-BFGS over `[β; vec(Λ); log r; logit π]` on
the Laplace marginal ([`zinb_marginal_loglik_laplace`](@ref)), jointly estimating the
NB2 dispersion `r` and the shared zero-inflation probability `π`. `Y` is a p×n integer
count matrix (responses × sites); `K` the latent dimension. The latent variable enters
only the count rate `μ = exp(β + Λz)`; `r` and `π` are constants (v1). The L-BFGS
gradient uses the generic implicit dense-Laplace gradient
(`marginal_loglik_laplace_implicit_value_grad`): the per-site latent mode is found once
by Fisher scoring, then the gradient is taken with the implicit-function rule, with
per-observation `(η, log r, logit π)` derivatives supplied by ForwardDiff through the
closed-form `_glm_logpdf`. Warm start = empirical log-mean count intercepts (over the
POSITIVE cells, to discount inflated zeros) + an SVD loadings init + a moderate `r₀`
and a `π₀` from the excess-zero fraction.
"""
function fit_zinb_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, r_init = nothing, π_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # warm start: per-trait log-mean over POSITIVE cells (so structural zeros do not
    # deflate the rate); fall back to all cells if a trait is all-zero.
    β0 = if β_init === nothing
        b = Vector{Float64}(undef, p)
        @inbounds for t in 1:p
            s = 0.0; c = 0
            for j in 1:n
                if Y[t, j] > 0
                    s += Y[t, j]; c += 1
                end
            end
            b[t] = c == 0 ? log(max(sum(view(Y, t, :)) / n, 1e-4)) : log(max(s / c, 1e-4))
        end
        b
    else
        collect(float.(β_init))
    end
    Zemp = [linkfun(link, max(Y[t, i] + 0.5, 1e-4)) for t in 1:p, i in 1:n]
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- (sum(Zemp; dims = 2) ./ n)
        F = svd(Zc)
        kk = min(K, length(F.S))
        L = zeros(p, K)
        @inbounds for j in 1:kk
            L[:, j] = F.U[:, j] .* (F.S[j] / sqrt(n))
        end
        L
    else
        collect(float.(Λ_init))
    end
    logr0 = r_init === nothing ? log(10.0) : log(float(r_init))
    # π₀ from the overall excess-zero fraction: observed P(y=0) minus the Poisson zero
    # mass e^{−μ̄} at the warm-start rates, clamped to a sensible interior (the NB2
    # zero mass is larger, so this under-estimates π₀ slightly — the optimiser refines).
    π0 = if π_init === nothing
        zfrac = count(==(0), Y) / (p * n)
        pois0 = sum(exp(-exp(β0[t])) for t in 1:p) / p
        clamp((zfrac - pois0) / max(1 - pois0, 1e-3), 0.05, 0.6)
    else
        float(π_init)
    end
    logit_π0 = log(π0 / (1 - π0))

    θ0 = vcat(β0, pack_lambda(Λ0), logr0, logit_π0)
    family_fromθ = θ -> ZINB(_positive_from_log(θ[end - 1]), _prob_from_logit(θ[end]))
    N = ones(Int, size(Y))
    value_grad(θ) = marginal_loglik_laplace_implicit_value_grad(
        family_fromθ, Y, N, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    r̂ = _positive_from_log(θ̂[p + rr + 1])
    π̂ = _prob_from_logit(θ̂[p + rr + 2])
    return ZINBFit(β̂, Λ̂, r̂, π̂, link, -Optim.minimum(res),
                   Optim.converged(res), Optim.iterations(res))
end
