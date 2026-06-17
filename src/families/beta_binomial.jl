# Beta-binomial family (gllvm family="beta.binomial", enum 15) for the Laplace path.
#
# Overdispersed binomial: y | N, p ~ Binomial(N, p) with p ~ Beta(a, b), so the
# trial-success probability itself is random. gllvm parameterises (see
# JenniNiku/gllvm src/gllvm.cpp:5252-5267) the Beta shapes as
#
#     a = α = μ·φ,   b = β = (1−μ)·φ,   φ = exp(lg_phi) > 0,
#
# where μ = linkinv(link, η) ∈ (0,1) is the success prob and φ = a+b is the Beta
# precision (the shape-sum). The marginal beta-binomial log-pmf is
#
#   log p(y|N,μ,φ) = lgamma(a+b) + lgamma(a+y) + lgamma(b+N−y) − lgamma(a)
#                    − lgamma(b) − lgamma(a+b+N) + lgamma(N+1) − lgamma(y+1)
#                    − lgamma(N−y+1),
#
# with E[y] = N·μ, Var[y] = N·μ(1−μ)·(1 + (N−1)·φ/(φ+1)), intraclass ρ = 1/(φ+1).
# As φ → ∞ the Beta collapses to a point mass at μ and the family → Binomial(N, μ)
# (var-inflation → 1) — the key reduction anchor.
#
# A single latent η drives μ; the family marker carries only the dispersion φ.
# This file therefore runs its OWN per-site Laplace (mirroring ordered_beta.jl):
# the per-trait score s_t = ∂log p/∂η and weight W_t = −∂²log p/∂η² are obtained
# by ForwardDiff on the scalar map η → log p (lower risk than the digamma score /
# Hessian), with W_t clamped to ≥ 1e-8 for SPD. The trial counts N are threaded
# through the marginal and the fit exactly like families/binomial.jl threads them.

"""
    BetaBinom(φ)

Beta-binomial family marker (gllvm `family="beta.binomial"`, enum 15). `φ > 0` is
the Beta precision (the shape-sum `a+b`, i.e. the species dispersion). Named to
avoid colliding with `Distributions.BetaBinomial`; used only as a tag for the
dedicated beta-binomial Laplace path.
"""
struct BetaBinom <: Distribution{Univariate, Discrete}
    φ::Float64
end

# logistic σ(x), numerically safe at large |x| (mirrors ordered_beta.jl).
_bb_logistic(x) = x ≥ 0 ? inv(one(x) + exp(-x)) : (e = exp(x); e / (one(x) + e))

const _BB_MU_LO = 1e-12
const _BB_MU_HI = 1 - 1e-12

"""
    betabinomial_logp(y, η, N, φ; link=LogitLink()) -> Float64

Scalar beta-binomial conditional log-pmf log p(y|N,η,φ) for one trait, in the
gllvm parameterisation `a = μφ`, `b = (1−μ)φ` with `μ = linkinv(link, η)` clamped
to (1e-12, 1−1e-12). Uses `loggamma` (from SpecialFunctions, imported module-wide).
"""
function betabinomial_logp(y, η, N, φ; link::Link = LogitLink())
    μ = clamp(linkinv(link, η), _BB_MU_LO, _BB_MU_HI)
    a = μ * φ
    b = (one(μ) - μ) * φ
    return loggamma(a + b) + loggamma(a + y) + loggamma(b + N - y) -
           loggamma(a) - loggamma(b) - loggamma(a + b + N) +
           loggamma(N + 1) - loggamma(y + 1) - loggamma(N - y + 1)
end

# Per-trait score s_t = ∂log p/∂η and weight W_t = −∂²log p/∂η², via ForwardDiff
# on the scalar map η → log p. W clamped to ≥ 1e-8 to keep Λ'WΛ + I SPD.
function _bb_score_weight(y, η, N, φ; link::Link = LogitLink())
    f = ηv -> betabinomial_logp(y, ηv, N, φ; link = link)
    g = ηv -> ForwardDiff.derivative(f, ηv)
    s = g(η)
    W = -ForwardDiff.derivative(g, η)
    return s, max(W, 1e-8)
end

# Inner Laplace mode-finder for one site (Newton on the negative second
# derivative). Mirrors `_ordered_beta_mode`. `mask` (length-p Bool, or `nothing` =
# all observed) drops missing responses: a masked entry contributes zero score and
# zero Fisher weight, so it neither pulls the mode nor enters the Hessian.
function _beta_binomial_mode(y::AbstractVector, N::AbstractVector, Λ::AbstractMatrix,
        β::AbstractVector, φ::Real; link::Link = LogitLink(), mask = nothing,
        maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = zeros(K)
    for _ in 1:maxiter
        η = β .+ Λ * z
        s = Vector{Float64}(undef, p)
        W = Vector{Float64}(undef, p)
        @inbounds for t in 1:p
            if mask !== nothing && !mask[t]
                s[t] = 0.0; W[t] = 0.0           # masked ⇒ no contribution
                continue
            end
            st, Wt = _bb_score_weight(y[t], η[t], N[t], φ; link = link)
            s[t] = st
            W[t] = Wt
        end
        A = Symmetric(Λ' * (W .* Λ) + I)
        Δ = _safe_solve(A, Λ' * s .- z)
        (Δ === nothing || !all(isfinite, Δ)) && break
        z = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end

# Per-site Laplace log-marginal:
#   log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I).
# `mask` drops the masked entries from the score/weight (via `_beta_binomial_mode`)
# and from the conditional log-density sum.
function _beta_binomial_loglik_site(y::AbstractVector, N::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, φ::Real; link::Link = LogitLink(),
        mask = nothing, maxiter::Integer = 100, tol::Real = 1e-9)
    p, K = size(Λ)
    z = _beta_binomial_mode(y, N, Λ, β, φ; link = link, mask = mask, maxiter = maxiter, tol = tol)
    η = β .+ Λ * z
    ℓ = 0.0
    W = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        if mask !== nothing && !mask[t]
            W[t] = 0.0                           # masked ⇒ no Hessian weight, no logpdf
            continue
        end
        ℓ += betabinomial_logp(y[t], η[t], N[t], φ; link = link)
        _, Wt = _bb_score_weight(y[t], η[t], N[t], φ; link = link)
        W[t] = Wt
    end
    A = Symmetric(Λ' * (W .* Λ) + I)
    return ℓ - 0.5 * dot(z, z) - 0.5 * logdet(A)
end

"""
    betabinomial_marginal_loglik_laplace(Y, N, Λ, β, φ; mask=nothing, link=LogitLink(), maxiter=100, tol=1e-9) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a beta-binomial GLLVM.
`Y` is a p×n matrix of integer successes; `N` the matching p×n trial counts; `Λ`
p×K loadings; `β` length-p intercepts; `φ` the Beta precision (shape-sum). Runs
its own per-site Laplace (single latent η, gllvm parameterisation `a=μφ, b=(1−μ)φ`,
`μ = linkinv(link, η)`). At `Λ = 0` this reduces exactly to the sum of the
independent beta-binomial `logp`. As `φ → ∞` it approaches the Binomial marginal.

`mask` (p×n Bool, or `nothing`) marks observed cells — masked (missing) responses
are dropped per site from the score, the Hessian weight, and the log-density sum,
so the marginal is over the observed entries only (invariant to the masked-cell
placeholder).
"""
function betabinomial_marginal_loglik_laplace(Y::AbstractMatrix, N::AbstractMatrix,
        Λ::AbstractMatrix, β::AbstractVector, φ::Real; mask = nothing, link::Link = LogitLink(),
        maxiter::Integer = 100, tol::Real = 1e-9)
    acc = 0.0
    @inbounds for i in axes(Y, 2)
        mi = mask === nothing ? nothing : view(mask, :, i)
        acc += _beta_binomial_loglik_site(view(Y, :, i), view(N, :, i), Λ, β, φ;
                                          link = link, mask = mi, maxiter = maxiter, tol = tol)
    end
    return acc
end

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    BetaBinomialFit

Result of [`fit_beta_binomial_gllvm`](@ref): intercepts `β` (length p), loadings
`Λ` (p×K), the `link`, the Beta precision `φ`, the maximised Laplace `loglik`, the
optimiser `converged` flag, and `iterations`.
"""
struct BetaBinomialFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    link::Link
    φ::Float64
    loglik::Float64
    converged::Bool
    iterations::Int
end

# ---------------------------------------------------------------------------
# Post-fit ordination: getLV / predict. A single latent η drives μ (the family
# marker carries φ), so the per-site mode is this file's own `_beta_binomial_mode`,
# and :mean returns the success probability μ = linkinv(link, η).
# ---------------------------------------------------------------------------

_loadings(fit::BetaBinomialFit) = fit.Λ
_loglik(fit::BetaBinomialFit)   = fit.loglik

# Free params: β (p) + reduced loadings Λ + Beta precision φ.
function _nparams(fit::BetaBinomialFit)
    p, K = size(fit.Λ)
    return p + (p * K - div(K * (K - 1), 2)) + 1       # β + Λ + φ
end

"""
    getLV(fit::BetaBinomialFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a beta-binomial fit: the per-site Laplace
mode `ẑₛ` (`_beta_binomial_mode`) at the fitted `(Λ, β)`, link, and precision `φ`.
`Y` is the `p×n` matrix of integer successes; `N` the matching trial counts
(default all-ones); `rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::BetaBinomialFit, Y::AbstractMatrix{<:Real};
        N::Union{Nothing, AbstractMatrix{<:Real}} = nothing, rotate::Bool = true)
    p, n = size(Y)
    K = size(fit.Λ, 2)
    Nm = N === nothing ? fill(1, p, n) : N
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _beta_binomial_mode(view(Y, :, s), view(Nm, :, s),
                                      fit.Λ, fit.β, fit.φ; link = fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::BetaBinomialFit, Y; N=nothing, type=:mean) -> p×n matrix

In-sample fitted values at the Laplace mode `ẑ` (see [`getLV`](@ref)): `type=:link`
returns the linear predictor `η = β + Λ ẑ`; `type=:mean` returns the success
probability `μ = linkinv(link, η)` (η clamped). Note `:mean` is the per-trial
success probability, not the count mean `E[y] = N·μ`.
"""
function predict(fit::BetaBinomialFit, Y::AbstractMatrix{<:Real};
        N::Union{Nothing, AbstractMatrix{<:Real}} = nothing, type::Symbol = :mean)
    type in (:link, :mean) ||
        throw(ArgumentError("type must be :link or :mean; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)          # n×K
    η = fit.β .+ fit.Λ * Z'                            # p×n
    type === :link && return η
    return linkinv.(Ref(fit.link), _clamp_eta.(η))
end

function Base.show(io::IO, f::BetaBinomialFit)
    p, K = size(f.Λ)
    print(io, "BetaBinomialFit(p=", p, ", K=", K, ", link=", nameof(typeof(f.link)),
          ", φ=", round(f.φ; sigdigits = 4),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_beta_binomial_gllvm(Y; K, N=nothing, link=LogitLink(), φ_init=nothing, …) -> BetaBinomialFit

Fit a beta-binomial GLLVM by L-BFGS on the Laplace marginal
(`betabinomial_marginal_loglik_laplace`), jointly estimating the Beta precision
`φ` (gllvm parameterisation `a=μφ, b=(1−μ)φ`). `Y` is a p×n matrix of integer
successes; `N` the matching trial counts (default all-ones, i.e. Bernoulli-
overdispersed); `K` the latent dimension. The optimiser θ = `[β(p); pack_lambda(Λ)(rr); log φ]`.
Finite-difference gradient (the Laplace inner mode-finder is not forward-AD-friendly).
Warm start = empirical link-mean intercepts (logit of `(y+0.5)/(N+1)` row means) +
an SVD (PPCA-style) loadings init + a moderate `φ₀`, mirroring `fit_binomial_gllvm`
and `fit_ordered_beta_gllvm`.

Missing data: pass a `mask` (p×n Bool, `false` = unobserved) or simply include
`missing` entries in `Y` — either way the masked cells are dropped from the
marginal *and* from the warm start, so the fit depends only on the observed cells
(it is invariant to whatever sits in the masked positions).
"""
function fit_beta_binomial_gllvm(Y::AbstractMatrix; K::Integer,
        N::Union{Nothing, AbstractMatrix{<:Real}} = nothing,
        link::Link = LogitLink(), mask = nothing,
        β_init = nothing, Λ_init = nothing, φ_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    size(Nm) == (p, n) || throw(DimensionMismatch("N must be $(p)×$(n)"))
    rr = rr_theta_len(p, K)

    # NA handling: derive the observation mask (explicit `mask`, else from `missing`)
    # and a sanitized success matrix with a safe placeholder (0) in masked cells.
    msk = _resolve_obs_mask(mask, Y)
    Yc = Integer.(_sanitize_missing(Y, 0))

    # warm start: empirical link-scale intercepts + SVD (PPCA-like) loadings.
    Zemp = [linkfun(link, clamp((float(Yc[t, i]) + 0.5) / (float(Nm[t, i]) + 1),
                                1e-4, 1 - 1e-4)) for t in 1:p, i in 1:n]
    _mask_warmstart!(Zemp, msk)
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
    function negll(θ)
        β = θ[1:p]
        Λ = unpack_lambda(θ[(p + 1):(p + rr)], p, K)
        φ = exp(θ[p + rr + 1])
        v = try
            -betabinomial_marginal_loglik_laplace(Yc, Nm, Λ, β, φ; mask = msk, link = link,
                                                  maxiter = newton_maxiter, tol = newton_tol)
        catch
            return 1e12
        end
        return isfinite(v) ? v : 1e12
    end
    ls = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking(order = 3))
    res = Optim.optimize(negll, θ0, ls, Optim.Options(g_tol = g_tol, iterations = iterations);
                         autodiff = :finite)
    θ̂ = Optim.minimizer(res)
    β̂ = θ̂[1:p]
    Λ̂ = unpack_lambda(θ̂[(p + 1):(p + rr)], p, K)
    φ̂ = exp(θ̂[p + rr + 1])
    return BetaBinomialFit(β̂, Λ̂, link, φ̂, -Optim.minimum(res),
                           Optim.converged(res), Optim.iterations(res))
end
