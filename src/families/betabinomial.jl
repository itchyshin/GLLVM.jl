# Beta-Binomial (overdispersed binomial) family pieces for the generic Laplace
# core (src/families/laplace.jl). y_t ∈ {0,1,…,N_t}; N_t trials (carried in the
# per-observation `n` slot, exactly like Binomial); mean probability
# μ = linkinv(link, η) (logit link), dispersion φ > 0. The per-observation law is
# BetaBinomial(N, a, b) with a = μφ, b = (1−μ)φ (the MEAN parameterisation:
# E[p] = a/(a+b) = μ, so E[y] = Nμ). As φ → ∞ the mixing Beta collapses to a
# point mass at μ and the law tends to Binomial(N, μ).
#
# Marker convention: reuse `Distributions.BetaBinomial` as the family marker (the
# GLM.jl convention shared with Binomial/Poisson/Beta/Gamma), with the dispersion
# φ stored in the `.α` field — the marker is built as `BetaBinomial(1, φ, 1.0)`,
# whose `.n`/`.β` fields are dummies (N varies per cell and is supplied through
# the `n` argument). This avoids defining a colliding `BetaBinomial` name. The
# per-cell `BetaBinomial(N, μφ, (1−μ)φ)` is rebuilt inside `_glm_logpdf`.
#
# Beta-Binomial log pmf (mean-parameterised) via `loggamma`:
#   a = μφ, b = (1−μ)φ  (so a + b = φ);  per observation with N trials and y ∈ 0:N
#   ℓ = log C(N,y)
#       + logΓ(φ) − logΓ(a) − logΓ(b)
#       + logΓ(y+a) + logΓ(N−y+b) − logΓ(N+φ).
# (Johnson, Kemp & Kotz 2005, Univariate Discrete Distributions, §6.2.2.) Written
# in closed form so ForwardDiff Duals flow cleanly through both η (via μ ⇒ a, b)
# and log φ (via a, b, φ) — what makes the generic implicit-gradient path in
# laplace.jl AD-clean for the Beta-Binomial.
#
# Score/weight wrt η (logit scale, me = dμ/dη):
#   ∂ℓ/∂a = ψ(φ) − ψ(a) + ψ(y+a)   − ψ(N+φ)
#   ∂ℓ/∂b = ψ(φ) − ψ(b) + ψ(N−y+b) − ψ(N+φ)
#   ∂a/∂μ = φ, ∂b/∂μ = −φ  ⇒
#   s = ∂ℓ/∂η = φ · me · [ψ(y+a) − ψ(a) − ψ(N−y+b) + ψ(b)]   (EXACT score).
# The Fisher-scoring working weight uses the Beta-Binomial variance
#   Var(y) = Nμ(1−μ)·[1 + (N−1)/(φ+1)]   (the overdispersion factor in [·]),
# so with mean Nμ and dμ/dη = me the moment working weight is
#   W = (N·me)² / Var(y) = N·me² / [ μ(1−μ) · (1 + (N−1)/(φ+1)) ]  (≥ 0).
# As φ → ∞ this reduces to the canonical binomial-logit weight N·me²/(μ(1−μ)),
# and with N = 1 the overdispersion factor is 1 (a single Bernoulli trial cannot
# be overdispersed), so it matches Binomial there.

# Build a Beta-Binomial family marker carrying dispersion φ in the `.α` slot
# (`.n`/`.β` are dummies; N is supplied per observation). AD-friendly: φ may be a
# ForwardDiff.Dual.
_betabinomial_marker(φ::T) where {T<:Real} = BetaBinomial{T}(1, φ, one(T))

default_link(::BetaBinomial) = LogitLink()

_clamp_mu(::BetaBinomial, μ) = clamp(μ, 1e-6, 1 - 1e-6)

# EXACT score wrt η (digamma form above). `n` is the trial count N; φ = f.α.
function _glm_score(f::BetaBinomial, μ, n, me, y)
    φ = f.α
    a = μ * φ
    b = (one(μ) - μ) * φ
    return φ * me * (digamma(y + a) - digamma(a) - digamma(n - y + b) + digamma(b))
end

# Moment-based Fisher-scoring working weight (positive ⇒ Λ'WΛ + I SPD). The
# overdispersion factor 1 + (N−1)/(φ+1) inflates the binomial variance.
function _glm_weight(f::BetaBinomial, μ, n, me)
    φ = f.α
    od = one(φ) + (n - one(n)) / (φ + one(φ))    # overdispersion factor ≥ 1
    return n * me^2 / (μ * (one(μ) - μ) * od)
end

# Closed-form Beta-Binomial log pmf (mean-parameterised). log C(N,y) via loggamma.
function _glm_logpdf(f::BetaBinomial, μ, n, y)
    φ = f.α
    a = μ * φ
    b = (one(μ) - μ) * φ
    logbinom = loggamma(n + one(n)) - loggamma(y + one(y)) - loggamma(n - y + one(y))
    return logbinom +
           loggamma(φ) - loggamma(a) - loggamma(b) +
           loggamma(y + a) + loggamma(n - y + b) - loggamma(n + φ)
end

"""
    betabinomial_marginal_loglik_laplace(Y, N, Λ, β, φ; link=LogitLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Beta-Binomial GLLVM
with dispersion `φ` (`Var = Nμ(1−μ)[1 + (N−1)/(φ+1)]`, logit link) — a thin
wrapper over the family-generic `marginal_loglik_laplace` with a
`Distributions.BetaBinomial` marker carrying `φ` in its `.α` slot. `Y` is the p×n
integer response matrix; `N` the matching trial counts; `Λ` p×K; `β` length-p. As
`φ → ∞` this tends to the Binomial marginal.
"""
betabinomial_marginal_loglik_laplace(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, φ::Real;
        link::Link = LogitLink(), kwargs...) =
    marginal_loglik_laplace(_betabinomial_marker(float(φ)), Y, N, Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    BetaBinomialFit

Result of [`fit_betabinomial_gllvm`](@ref): intercepts `β` (length p), loadings
`Λ` (p×K), the estimated dispersion `φ` (`Var = Nμ(1−μ)[1 + (N−1)/(φ+1)]`), the
`link`, the maximised Laplace `loglik`, the optimiser `converged` flag, and
`iterations`.
"""
struct BetaBinomialFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    φ::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::BetaBinomialFit)
    p, K = size(f.Λ)
    print(io, "BetaBinomialFit(p=", p, ", K=", K, ", φ=", round(f.φ; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_betabinomial_gllvm(Y; K, N, link=LogitLink(), φ_init=nothing, …) -> BetaBinomialFit

Fit a Beta-Binomial (overdispersed binomial, `Var = Nμ(1−μ)[1 + (N−1)/(φ+1)]`)
GLLVM by L-BFGS over `[β; vec(Λ); log φ]` on the Laplace marginal
(`betabinomial_marginal_loglik_laplace`), jointly estimating the dispersion `φ`.
`Y` is a p×n integer response matrix; `N` the matching trial counts (default
all-ones ⇒ Bernoulli, where the Beta-Binomial is unidentified from Binomial — use
`N > 1`); `K` the latent dimension. The L-BFGS gradient uses the generic implicit
dense-Laplace gradient (`marginal_loglik_laplace_implicit_value_grad`): the
per-site latent mode is found once by Fisher scoring, then the gradient is taken
with the implicit-function rule, with per-observation `(η, log φ)` derivatives
supplied by ForwardDiff through the closed-form `_glm_logpdf`. Warm start =
empirical logit-mean intercepts + an SVD loadings init + a moderate `φ₀`.
"""
function fit_betabinomial_gllvm(Y::AbstractMatrix{<:Integer}; K::Integer,
        N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
        link::Link = LogitLink(),
        β_init = nothing, Λ_init = nothing, φ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)

    # warm start: empirical logit-scale intercepts + SVD (PPCA-like) loadings
    Zemp = [linkfun(link, clamp((Y[t, i] + 0.5) / (Nm[t, i] + 1), 1e-4, 1 - 1e-4))
            for t in 1:p, i in 1:n]
    β0 = β_init === nothing ? vec(sum(Zemp; dims = 2)) ./ n : collect(float.(β_init))
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
    logφ0 = φ_init === nothing ? log(10.0) : log(float(φ_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logφ0)
    family_fromθ = θ -> _betabinomial_marker(_positive_from_log(θ[end]))
    value_grad(θ) = marginal_loglik_laplace_implicit_value_grad(
        family_fromθ, Y, Nm, θ, p, K, link; maxiter = newton_maxiter, tol = newton_tol)
    negll_fg!(F, G, θ) = _penalized_negloglik_fg!(F, G, value_grad, θ)
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(Optim.only_fg!(negll_fg!), θ0, ls,
                         Optim.Options(g_tol = g_tol, iterations = iterations))
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    φ̂ = _positive_from_log(θ̂[p + rr + 1])
    return BetaBinomialFit(β̂, Λ̂, φ̂, link, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
end
