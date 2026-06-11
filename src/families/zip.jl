# Zero-inflated Poisson (ZIP) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ {0,1,2,…}: a mixture of a structural-zero point
# mass and a Poisson count,
#
#   y ~ π·δ₀ + (1−π)·Poisson(μ),   μ = exp(η)  (log link),
#
# where the shared latent enters ONLY the count rate μ (η = β_t + (Λ z)_t) and the
# zero-inflation probability π ∈ (0, 1) is a single scalar auxiliary on the logit
# scale (aux = log(π/(1−π)), π = logistic(aux)). For v1 π is one constant shared
# across traits (the NB2/Beta scalar-aux convention); modelling π on the latent is
# a follow-up. (Lambert 1992, Technometrics 34, 1–14.)
#
# Conditional log-density (let p₀ = π + (1−π)e^{−μ} be the marginal zero mass):
#   y = 0:  log p₀ = log(π + (1−π)e^{−μ})
#   y > 0:  log(1−π) + logpdf(Poisson(μ), y)
#
# Score wrt η (log link, dμ/dη = me = μ), θ = η. The y>0 count score is the plain
# Poisson score (it does NOT involve π); the zero cell mixes π and the Poisson zero:
#   y > 0:  s = (y/μ − 1)·μ = y − μ
#   y = 0:  s = (∂/∂μ log p₀)·μ = −μ(1−π)e^{−μ} / p₀
#
# Weight wrt η = the EXPECTED (Fisher) information I(η) = E[s²] under the model at η
# (a positive working weight, so Λ'WΛ + I stays SPD — the same expected-information
# convention used by Poisson/NB/Student-t in this codebase). With Poisson variance μ,
#   E[s²] = p₀·s₀² + Σ_{y≥1}(1−π)Pois(y;μ)(y−μ)²
#         = (1−π)²μ²e^{−2μ}/p₀ + (1−π)μ − (1−π)e^{−μ}μ²   ≥ 0.
# This is a variance (E[s²]), hence ≥ 0 by construction; at π → 0 (p₀ → e^{−μ}) it
# reduces to the plain-Poisson weight μ, and the score reduces to (y − μ).
#
# `_glm_logpdf`/`_glm_score`/`_glm_weight` are CLOSED FORM (no Distributions mixture
# object beyond `logpdf(Poisson(μ), y)` for the count cell), so ForwardDiff Duals
# flow cleanly through both η (via μ) and the aux (via π). This keeps the GENERIC
# implicit dense-Laplace gradient path in laplace.jl AD-clean for ZIP (the NB1
# pattern: `marginal_loglik_laplace_implicit_value_grad`, no hand-coded kernel).

"""
    ZIP(π)

Zero-inflated Poisson family marker: counts `y ∈ {0,1,2,…}` from the mixture
`π·δ₀ + (1−π)·Poisson(μ)` with log link (`μ = exp η`). The latent variable enters
only the count rate `μ`; `π ∈ (0,1)` is the (shared, constant in v1)
zero-inflation probability, estimated on the logit scale via the scalar auxiliary
of the generic Laplace core. As `π → 0` this reduces to the `Poisson()` family.
"""
struct ZIP{T<:Real}
    π::T
end

default_link(::ZIP) = LogLink()

_clamp_mu(::ZIP, μ) = max(μ, 1e-12)

# Marginal zero mass p₀ = π + (1−π)e^{−μ} (μ-clamped upstream; π ∈ (0,1)).
@inline _zip_p0(π, μ) = π + (one(π) - π) * exp(-μ)

function _glm_score(f::ZIP, μ, n, me, y)
    π = f.π
    if y > 0
        return (y - μ)                                     # Poisson count score (log link)
    else
        emμ = exp(-μ)
        p0 = π + (one(π) - π) * emμ
        return -μ * (one(π) - π) * emμ / p0                # zero-cell score wrt η
    end
end

function _glm_weight(f::ZIP, μ, n, me)
    π = f.π
    emμ = exp(-μ)
    p0 = π + (one(π) - π) * emμ
    return (one(π) - π)^2 * μ^2 * emμ^2 / p0 +
           (one(π) - π) * μ - (one(π) - π) * emμ * μ^2     # E[s²] ≥ 0 (Fisher info)
end

function _glm_logpdf(f::ZIP, μ, n, y)
    π = f.π
    if y > 0
        return log1p(-π) + logpdf(Poisson(μ), Int(y))      # log(1−π) + Poisson logpdf
    else
        return log(π + (one(π) - π) * exp(-μ))             # log p₀
    end
end

"""
    zip_marginal_loglik_laplace(Y, Λ, β, π; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a zero-inflated Poisson
(ZIP) GLLVM with zero-inflation probability `π` — a thin wrapper over the
family-generic `marginal_loglik_laplace` with the `ZIP(π)` marker. `Y` is the p×n
integer count matrix; `Λ` p×K; `β` length-p. As `π → 0` this tends to the Poisson
marginal. ZIP has no trial counts, so a unit `N` is supplied internally.
"""
zip_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        π::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(ZIP(π), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

# π from an unconstrained logit (clamped like _clamp_eta to keep π ∈ (0,1) at the
# extremes); the inverse of aux = log(π/(1−π)).
_prob_from_logit(x) = inv(one(x) + exp(-clamp(x, -30.0, 30.0)))

"""
    ZIPFit

Result of [`fit_zip_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated (shared, constant) zero-inflation probability `π`, the `link`, the
maximised Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct ZIPFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    π::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ZIPFit)
    p, K = size(f.Λ)
    print(io, "ZIPFit(p=", p, ", K=", K, ", π=", round(f.π; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_zip_gllvm(Y; K, link=LogLink(), π_init=nothing, …) -> ZIPFit

Fit a zero-inflated Poisson (ZIP) GLLVM by L-BFGS over `[β; vec(Λ); logit π]` on
the Laplace marginal ([`zip_marginal_loglik_laplace`](@ref)), jointly estimating
the shared zero-inflation probability `π`. `Y` is a p×n integer count matrix
(responses × sites); `K` the latent dimension. The latent variable enters only the
count rate `μ = exp(β + Λz)`; `π` is constant (v1). The L-BFGS gradient uses the
generic implicit dense-Laplace gradient
(`marginal_loglik_laplace_implicit_value_grad`): the per-site latent mode is found
once by Fisher scoring, then the gradient is taken with the implicit-function rule,
with per-observation `(η, logit π)` derivatives supplied by ForwardDiff through the
closed-form `_glm_logpdf`. Warm start = empirical log-mean count intercepts (over
the POSITIVE cells, to discount inflated zeros) + an SVD loadings init + a `π₀`
from the excess-zero fraction.
"""
function fit_zip_gllvm(Y::AbstractMatrix{<:Union{Missing, Integer}}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, π_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)
    nobs = count(!ismissing, Y)

    # warm start (NA-aware): per-trait log-mean over POSITIVE OBSERVED cells (structural
    # zeros and missing cells do not deflate the rate); SVD init on observed link
    # residuals with missing cells mean-filled for the init ONLY; π₀ from the observed
    # excess-zero fraction. The fit itself is FIML over observed cells (issue #27). On a
    # dense (non-Missing) Y the guards are statically false ⇒ identical to the old start.
    β0 = if β_init === nothing
        b = Vector{Float64}(undef, p)
        @inbounds for t in 1:p
            spos = 0.0; cpos = 0; sall = 0.0; call = 0
            for j in 1:n
                ismissing(Y[t, j]) && continue
                yj = Y[t, j]; sall += yj; call += 1
                if yj > 0
                    spos += yj; cpos += 1
                end
            end
            b[t] = cpos == 0 ? log(max(call == 0 ? 1e-4 : sall / call, 1e-4)) :
                               log(max(spos / cpos, 1e-4))
        end
        b
    else
        collect(float.(β_init))
    end
    Zemp = Matrix{Float64}(undef, p, n)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                Zemp[t, i] = linkfun(link, max(Y[t, i] + 0.5, 1e-4)); acc += Zemp[t, i]; cnt += 1
            end
        end
        m = cnt == 0 ? linkfun(link, 0.5) : acc / cnt
        for i in 1:n
            ismissing(Y[t, i]) && (Zemp[t, i] = m)
        end
    end
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
    # π₀ from the OBSERVED excess-zero fraction: observed P(y=0) minus the Poisson
    # zero mass e^{−μ̄} at the warm-start rates, clamped to a sensible interior.
    π0 = if π_init === nothing
        zfrac = count(x -> !ismissing(x) && x == 0, Y) / max(nobs, 1)
        pois0 = sum(exp(-exp(β0[t])) for t in 1:p) / p
        clamp((zfrac - pois0) / max(1 - pois0, 1e-3), 0.05, 0.6)
    else
        float(π_init)
    end
    logit_π0 = log(π0 / (1 - π0))

    θ0 = vcat(β0, pack_lambda(Λ0), logit_π0)
    family_fromθ = θ -> ZIP(_prob_from_logit(θ[end]))
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
    π̂ = _prob_from_logit(θ̂[p + rr + 1])
    return ZIPFit(β̂, Λ̂, π̂, link, -Optim.minimum(res),
                  Optim.converged(res), Optim.iterations(res))
end
