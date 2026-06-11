# Zero-inflated Binomial (ZIBinom) family pieces for the generic Laplace core
# (src/families/laplace.jl). y_t ∈ {0,1,…,N_t}: a mixture of a structural-zero point
# mass and a Binomial count,
#
#   y ~ π·δ₀ + (1−π)·Binomial(N, p),   p = logistic(η)  (logit link),
#
# where the shared latent enters ONLY the success probability p (η = β_t + (Λ z)_t)
# and the zero-inflation probability π ∈ (0, 1) is a single scalar auxiliary on the
# logit scale (aux = log(π/(1−π)), π = logistic(aux)). For v1 π is one constant shared
# across traits (the ZIP/ZINB scalar-aux convention); modelling π on the latent is a
# follow-up. This is the BINOMIAL analogue of ZIP/ZINB and reuses the binomial
# count-cell score/weight from families/binomial.jl. As π → 0 every piece reduces to
# the plain Binomial family. (Lambert 1992, Technometrics 34, 1–14; Hall 2000,
# Biometrics 56, 1030–1039, for zero-inflated binomial.)
#
# Trial counts N are needed (a p×n matrix), exactly like binomial.jl, and are threaded
# through the marginal wrapper and the fit driver (NOT hard-coded to unit N).
#
# Conditional log-density (let g = (1−p)^N be the Binomial zero mass and
# p₀ = π + (1−π) g be the marginal zero mass):
#   y = 0:  log p₀ = log(π + (1−π)(1−p)^N)
#   y > 0:  log(1−π) + logpmf(Binomial(N, p), y)
#
# Score wrt η. The y>0 count score is the plain binomial-logit score (it does NOT
# involve π); the zero cell mixes π and the Binomial zero. With me = dp/dη
# (= p(1−p) at the logit link):
#   y > 0:  s = (y − N p)/(p(1−p)) · me         [= y − N p at the logit link]
#   y = 0:  s = (∂/∂η log p₀) = −(1−π) N (1−p)^{N−1} me / p₀
# (∂p₀/∂η = (1−π) N (1−p)^{N−1} (−me), the binomial analogue of the ZIP
# ∂/∂η of (1−π) e^{−μ}.)
#
# Weight wrt η = the EXPECTED (Fisher) information I(η) = E[s²] under the model at η
# (a positive working weight, so Λ'WΛ + I stays SPD — the same expected-information
# convention used by Poisson/NB/ZIP/ZINB in this codebase). Mirroring the ZINB
# decomposition (count_term = (1−π)[I_full − g·s_count(0)²], with g the count zero
# mass), and with the binomial Fisher info I_full = N me²/(p(1−p)) and binomial
# zero-cell count score s_count(0) = −N me/(1−p):
#   I(η) = p₀ s₀²
#        + (1−π)[ N me²/(p(1−p)) − (1−p)^N (N me/(1−p))² ]   ≥ 0,
#   where s₀ = −(1−π) N (1−p)^{N−1} me / p₀, so p₀ s₀² = (1−π)² N² (1−p)^{2N−2} me²/p₀.
# This is a variance (E[s²]), hence ≥ 0 by construction; at π → 0 (p₀ → g = (1−p)^N)
# the zero_term cancels the subtracted piece of the count_term ALGEBRAICALLY and the
# whole weight reduces to the plain-Binomial weight N me²/(p(1−p)) (an exact reduction,
# used as a test oracle, exactly as in ZINB).
#
# `_glm_logpdf`/`_glm_score`/`_glm_weight` are CLOSED FORM. The Binomial count cell
# uses the `loggamma`-based binomial log pmf (NOT a Distributions object), so the
# success-probability dependence flows through ForwardDiff Duals via BOTH η (through p)
# and the aux (through π). This keeps the GENERIC implicit dense-Laplace gradient
# (`marginal_loglik_laplace_implicit_value_grad`) AD-clean for ZIBinom (the ZIP pattern
# with trial counts; no hand-coded kernel).

"""
    ZIBinom(π)

Zero-inflated Binomial family marker: counts `y ∈ {0,1,…,N}` from the mixture
`π·δ₀ + (1−π)·Binomial(N, p)` with logit link (`p = logistic η`). The latent
variable enters only the success probability `p`; `π ∈ (0,1)` is the (shared,
constant in v1) zero-inflation probability, estimated on the logit scale via the
scalar auxiliary of the generic Laplace core. Trial counts `N` are supplied
per-cell (a p×n matrix). As `π → 0` this reduces to the `Binomial()` family.
"""
struct ZIBinom{T<:Real}
    π::T
end

default_link(::ZIBinom) = LogitLink()

_clamp_mu(::ZIBinom, μ) = clamp(μ, 1e-12, 1 - 1e-12)

# Closed-form Binomial log pmf (mean/probability-parameterised), AD-clean via
# `loggamma` so the success-probability `p` dependence flows through ForwardDiff
# Duals: logΓ(N+1) − logΓ(y+1) − logΓ(N−y+1) + y log p + (N−y) log(1−p).
@inline function _zibinom_binom_logpdf(N, p, y)
    Nf = float(N)
    yf = float(y)
    return loggamma(Nf + one(Nf)) - loggamma(yf + one(yf)) -
           loggamma(Nf - yf + one(Nf)) +
           yf * log(p) + (Nf - yf) * log1p(-p)
end

# Marginal zero mass p₀ = π + (1−π)(1−p)^N (p-clamped upstream; π ∈ (0,1)).
@inline _zibinom_p0(π, p, N) = π + (one(π) - π) * (one(p) - p)^N

function _glm_score(f::ZIBinom, μ, n, me, y)
    π = f.π
    if y > 0
        return (y - n * μ) / (μ * (one(μ) - μ)) * me        # binomial count score (no π dependence)
    else
        g = (one(μ) - μ)^n                                   # Binomial zero mass (1−p)^N
        p0 = π + (one(π) - π) * g
        return -(one(π) - π) * n * (one(μ) - μ)^(n - 1) * me / p0   # zero-cell score wrt η
    end
end

function _glm_weight(f::ZIBinom, μ, n, me)
    π = f.π
    g = (one(μ) - μ)^n                                        # Binomial zero mass (1−p)^N
    p0 = π + (one(π) - π) * g
    Ifull = n * me^2 / (μ * (one(μ) - μ))                     # binomial Fisher info N me²/(p(1−p))
    s0count = n * me / (one(μ) - μ)                           # |binomial zero-cell count score| N me/(1−p)
    zero_term  = (one(π) - π)^2 * n^2 * (one(μ) - μ)^(2 * n - 2) * me^2 / p0
    count_term = (one(π) - π) * (Ifull - g * s0count^2)
    return zero_term + count_term                            # E[s²] ≥ 0 (Fisher info)
end

function _glm_logpdf(f::ZIBinom, μ, n, y)
    π = f.π
    if y > 0
        return log1p(-π) + _zibinom_binom_logpdf(n, μ, y)    # log(1−π) + Binomial logpmf
    else
        return log(π + (one(π) - π) * (one(μ) - μ)^n)        # log p₀
    end
end

"""
    zibinom_marginal_loglik_laplace(Y, N, Λ, β, π; link=LogitLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a zero-inflated Binomial
(ZIBinom) GLLVM with zero-inflation probability `π` — a thin wrapper over the
family-generic `marginal_loglik_laplace` with the `ZIBinom(π)` marker. `Y`, `N` are
p×n response and trial-count matrices; `Λ` p×K; `β` length-p. As `π → 0` this tends to
the Binomial marginal. Unlike ZIP/ZINB, ZIBinom needs the trial counts `N`, so they are
a required positional argument (not unit-filled internally).
"""
zibinom_marginal_loglik_laplace(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, π::Real;
        link::Link = LogitLink(), kwargs...) =
    marginal_loglik_laplace(ZIBinom(float(π)), Y, N, Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    ZIBinomFit

Result of [`fit_zibinom_gllvm`](@ref): intercepts `β` (length p), loadings `Λ` (p×K),
the estimated (shared, constant) zero-inflation probability `π`, the `link`, the
maximised Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct ZIBinomFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    π::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::ZIBinomFit)
    p, K = size(f.Λ)
    print(io, "ZIBinomFit(p=", p, ", K=", K, ", π=", round(f.π; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_zibinom_gllvm(Y; K, link=LogitLink(), N=nothing, π_init=nothing, …) -> ZIBinomFit

Fit a zero-inflated Binomial (ZIBinom) GLLVM by L-BFGS over `[β; vec(Λ); logit π]` on
the Laplace marginal ([`zibinom_marginal_loglik_laplace`](@ref)), jointly estimating
the shared zero-inflation probability `π`. `Y` is a p×n integer response matrix
(responses × sites); `N` the matching trial counts (default all-ones, i.e. zero-inflated
Bernoulli); `K` the latent dimension. The latent variable enters only the success
probability `p = logistic(β + Λz)`; `π` is constant (v1). The L-BFGS gradient uses the
generic implicit dense-Laplace gradient
(`marginal_loglik_laplace_implicit_value_grad`): the per-site latent mode is found once
by Fisher scoring, then the gradient is taken with the implicit-function rule, with
per-observation `(η, logit π)` derivatives supplied by ForwardDiff through the
closed-form `_glm_logpdf`. Warm start = empirical logit intercepts over the POSITIVE
cells (so structural zeros do not deflate the success probability) + an SVD loadings
init + a `π₀` from the excess-zero fraction.
"""
function fit_zibinom_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        link::Link = LogitLink(),
        N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
        β_init = nothing, Λ_init = nothing, π_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)

    # warm start: per-trait empirical logit over POSITIVE cells (so structural zeros
    # do not deflate the success probability); fall back to all cells if a trait is
    # all-zero. Empirical proportions are clamped away from {0,1} before the link.
    β0 = if β_init === nothing
        b = Vector{Float64}(undef, p)
        @inbounds for t in 1:p
            sprop = 0.0; c = 0
            for j in 1:n
                if Y[t, j] > 0
                    sprop += Y[t, j] / Nm[t, j]; c += 1
                end
            end
            phat = if c == 0
                clamp((sum(Y[t, j] for j in 1:n) + 0.5) /
                      (sum(Nm[t, j] for j in 1:n) + 1), 1e-4, 1 - 1e-4)
            else
                clamp(sprop / c, 1e-4, 1 - 1e-4)
            end
            b[t] = linkfun(link, phat)
        end
        b
    else
        collect(float.(β_init))
    end
    Zemp = [linkfun(link, clamp((Y[t, i] + 0.5) / (Nm[t, i] + 1), 1e-4, 1 - 1e-4))
            for t in 1:p, i in 1:n]
    Λ0 = if Λ_init === nothing
        Zc = Zemp .- β0
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
    # π₀ from the overall excess-zero fraction: observed P(y=0) minus the Binomial zero
    # mass (1−p̄)^N̄ at the warm-start probabilities, clamped to a sensible interior.
    π0 = if π_init === nothing
        zfrac = count(==(0), Y) / (p * n)
        binom0 = 0.0
        @inbounds for t in 1:p
            pbar = linkinv(link, _clamp_eta(β0[t]))
            Nbar = sum(Nm[t, j] for j in 1:n) / n
            binom0 += (1 - pbar)^Nbar
        end
        binom0 /= p
        clamp((zfrac - binom0) / max(1 - binom0, 1e-3), 0.05, 0.6)
    else
        float(π_init)
    end
    logit_π0 = log(π0 / (1 - π0))

    θ0 = vcat(β0, pack_lambda(Λ0), logit_π0)
    family_fromθ = θ -> ZIBinom(_prob_from_logit(θ[end]))
    value_grad(θ) = marginal_loglik_laplace_implicit_value_grad(
        family_fromθ, Y, Nm, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    π̂ = _prob_from_logit(θ̂[p + rr + 1])
    return ZIBinomFit(β̂, Λ̂, π̂, link, -Optim.minimum(res),
                      Optim.converged(res), Optim.iterations(res))
end
