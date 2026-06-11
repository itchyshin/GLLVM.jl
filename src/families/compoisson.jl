# Conway–Maxwell–Poisson (COM-Poisson) family pieces for the generic Laplace core
# (src/families/laplace.jl). Flexible-dispersion counts y_t ∈ {0,1,2,…}:
#
#   P(y; λ, ν) = λ^y / ((y!)^ν · Z(λ, ν)),   Z(λ, ν) = Σ_{j≥0} λ^j / (j!)^ν,
#
# with the RATE-parameterisation log link λ = exp(η), η = β_t + (Λ z)_t, and the
# Conway–Maxwell dispersion ν > 0 a single shared scalar auxiliary on the log
# scale (aux = log ν). ν = 1 is Poisson; ν > 1 under-dispersion; ν < 1
# over-dispersion. (Conway & Maxwell 1962, J. Ind. Eng. 13, 132–136; Shmueli et
# al. 2005, JRSS-C 54, 127–142.)
#
# PARAMETERISATION (v1): the RATE form λ = exp(η) is used, NOT Huang's (2017,
# Stat. Modelling 17, 359–380) mean-parameterised COM-Poisson. The rate form is
# simpler — no inner solve for λ given a target mean μ(λ, ν) — and is the
# acceptable v1 choice flagged in the task. The trade-off: β is interpretable on
# the LOG-RATE scale, not the log-MEAN scale (the COM-Poisson mean E[y] is only
# ≈ λ^{1/ν} − (ν−1)/(2ν), so log E[y] ≠ η unless ν = 1). This is documented here
# and in the docstring; switching to the Huang mean form is a follow-up.
#
# NORMALISER Z (the delicate part): Z is an INFINITE sum with no closed form
# (except ν = 1 ⇒ Z = e^λ, ν = 0 ⇒ Z = 1/(1−λ) for λ < 1, ν → ∞ ⇒ Bernoulli).
# It is computed by a TRUNCATED log-sum-exp over j = 0 … J:
#   logZ = logsumexp_{j=0}^{J} ( j·log λ − ν·loggamma(j+1) ).
# The truncation cap J is chosen from the PRIMAL (Float64) values of λ and ν only,
# so it is a plain loop bound (an Int), never a differentiated quantity — this is
# what keeps logZ AD-clean: ForwardDiff Duals in λ (via η) and ν flow through the
# log/exp/loggamma arithmetic of the summed terms, while the number of terms is
# fixed by the primal. See `_compois_jmax` for the cap (mode-centred, generous
# upper margin for the heavy over-dispersed tail, plus a hard cap).
#
# The COM-Poisson is a two-parameter exponential family with natural parameters
# (log λ, −ν) and sufficient statistics (y, log y!). Hence the η-moments come from
# logZ derivatives wrt log λ = η:
#   ∂logZ/∂η = E[y],   ∂²logZ/∂η² = Var[y].
# We compute E[y] and E[y²] DIRECTLY from the same truncated pmf (closed form in
# the truncated sum, so AD-clean and consistent with logZ's truncation), giving:
#   ℓ = y·log λ − ν·loggamma(y+1) − logZ                       (closed form)
#   s = ∂ℓ/∂η = y − E[y]                                       (sets the Laplace mode)
#   W = E[s²] = Var[y] = E[y²] − E[y]²  ≥ 0                     (expected Fisher info)
# At ν → 1 these reduce EXACTLY to the Poisson (logZ → λ, ℓ → Poisson logpdf,
# E[y] → λ, Var[y] → λ ⇒ s → y − λ, W → λ) — used as a test oracle.
#
# `_glm_logpdf`/`_glm_score`/`_glm_weight` are CLOSED FORM (no Distributions
# object — there is none for COM-Poisson), so ForwardDiff Duals flow cleanly
# through η (via λ) and the aux (via ν). This keeps the GENERIC implicit
# dense-Laplace gradient (`marginal_loglik_laplace_implicit_value_grad`) AD-clean
# for COM-Poisson (the ZIP/ZINB scalar-auxiliary pattern; no hand-coded kernel).

"""
    CMPoisson(ν)

Conway–Maxwell–Poisson family marker: flexible-dispersion counts `y ∈ {0,1,2,…}`
with pmf `P(y; λ, ν) = λ^y / ((y!)^ν · Z(λ, ν))` and RATE-parameterised log link
`λ = exp η`. The latent variable enters only the rate `λ`; `ν > 0` is the
(shared, constant in v1) Conway–Maxwell dispersion, estimated on the log scale via
the scalar auxiliary of the generic Laplace core. `ν = 1` is the [`Poisson`](@ref)
family (exact reduction); `ν > 1` is under-dispersion; `ν < 1` over-dispersion.

Note: `β` is on the log-RATE scale (`λ = exp η`), not the log-mean scale — the
COM-Poisson mean is not `λ` unless `ν = 1`. The normaliser `Z` is an infinite sum
computed by a truncated log-sum-exp (see `compoisson.jl`).
"""
struct CMPoisson{T<:Real}
    ν::T
end

default_link(::CMPoisson) = LogLink()

_clamp_mu(::CMPoisson, μ) = max(μ, 1e-12)

# ---------------------------------------------------------------------------
# Truncation cap for the normaliser / moment sums.
#
# Chosen from the PRIMAL Float64 values of λ and ν ONLY, so the returned J is a
# plain Int (a loop bound), never carrying a Dual — this is what makes the summed
# logZ / E[y] / E[y²] AD-clean. `ForwardDiff.value` is applied recursively to
# strip any nested Dual down to its Float64 primal.
#
# The COM-Poisson mode sits near λ^{1/ν}. We centre the cap on
# max(observed y, λ^{1/ν}) and add a GENEROUS upper margin so the heavy
# over-dispersed (ν < 1) tail is captured: a multiplicative factor plus a large
# additive pad, then a hard cap to bound cost. For ν ≥ 1 (Poisson / under-
# dispersion) the tail decays at least as fast as Poisson, so the pad is ample.
# ---------------------------------------------------------------------------
@inline _primal(x::Real) = x
@inline _primal(x::ForwardDiff.Dual) = _primal(ForwardDiff.value(x))

const _COMPOIS_JHARD = 100_000   # hard cap on the number of summed terms

function _compois_jmax(λ, ν, y)
    λp = float(_primal(λ))
    νp = float(_primal(ν))
    yp = float(_primal(y))
    (isfinite(λp) && isfinite(νp) && λp > 0 && νp > 0) || return _COMPOIS_JHARD
    # Approximate mode and a spread proxy. λ^{1/ν} = exp(log λ / ν); the spread of
    # the over-dispersed tail grows as ν shrinks, so 1/ν also scales the margin.
    mode = exp(clamp(log(λp) / νp, -30.0, 30.0))
    centre = max(yp, mode)
    margin = 200.0 + 50.0 / min(νp, 1.0)        # heavier pad for ν < 1
    j = ceil(Int, centre * (1.0 + 4.0 / min(νp, 1.0)) + margin)
    return clamp(j, 50, _COMPOIS_JHARD)
end

# ---------------------------------------------------------------------------
# Core truncated sums. `logZ` is the log-sum-exp of the unnormalised log-terms
# t_j = j·log λ − ν·loggamma(j+1); the moment sums reuse the SAME terms and cap so
# E[y], E[y²] are consistent with logZ (i.e. exactly the moments of the truncated
# law). Hand-rolled streaming log-sum-exp (running max) keeps it AD-clean — no
# allocation of a Dual vector, no `maximum` over Duals.
# ---------------------------------------------------------------------------

# logZ = log Σ_{j=0}^{J} exp(t_j), t_j = j·logλ − ν·logΓ(j+1). Streaming LSE with a
# running max. Initialised from the j = 0 term t_0 = 0 (a clean constant — λ⁰/0!^ν =
# 1), so the running max starts at a finite value and NO −Inf Dual arithmetic ever
# occurs (the exp(m − tj) / exp(tj − m) shifts are always finite). This is the AD-safe
# form: ForwardDiff Duals in λ (via logλ) and ν flow through every exp/log/loggamma.
function _compois_logZ(λ, ν, J::Int)
    logλ = log(λ)
    T = promote_type(typeof(logλ), typeof(ν))
    m = zero(T)            # t_0 = 0·logλ − ν·logΓ(1) = 0
    se = one(T)            # exp(t_0 − m) = 1
    @inbounds for j in 1:J
        tj = j * logλ - ν * loggamma(oftype(logλ, j + 1))
        if tj > m
            se = se * exp(m - tj) + one(T)
            m = tj
        else
            se += exp(tj - m)
        end
    end
    return m + log(se)
end

# Return (logZ, E[y], E[y²]) from the SAME truncated terms. The expectations are
# Σ y·p(y) and Σ y²·p(y) with p(y) = exp(t_y − logZ); computed in one pass after
# logZ via the running max `m` (the LSE shift), so p(y) = exp(t_y − logZ) is
# evaluated stably. Two passes (one for logZ, one for moments) keep each numerically
# safe without storing the term vector.
function _compois_logZ_moments(λ, ν, J::Int)
    logλ = log(λ)
    T = promote_type(typeof(logλ), typeof(ν))
    logZ = _compois_logZ(λ, ν, J)
    Ey = zero(T)
    Ey2 = zero(T)
    @inbounds for j in 0:J
        tj = j * logλ - ν * loggamma(oftype(logλ, j + 1))
        pj = exp(tj - logZ)
        Ey += j * pj
        Ey2 += (j * j) * pj          # j*j exact in Int (J ≤ 1e5 ⇒ j² ≤ 1e10 < 2^63)
    end
    return logZ, Ey, Ey2
end

# ---------------------------------------------------------------------------
# Family pieces (dispatched by the generic Laplace core). λ = μ (the log-link
# inverse passed in; `_clamp_mu` keeps it > 0). me = dμ/dη = λ is unused: the
# score/weight are expressed directly in terms of the COM-Poisson moments, which
# already fold in the log link (s = y − E[y], W = Var[y]).
# ---------------------------------------------------------------------------

# s = ∂/∂η log p(y) = y − E[y]  (log link, θ₁ = log λ = η ⇒ ∂logZ/∂η = E[y]).
function _glm_score(f::CMPoisson, μ, n, me, y)
    ν = f.ν
    J = _compois_jmax(μ, ν, y)
    _, Ey, _ = _compois_logZ_moments(μ, ν, J)
    return y - Ey
end

# W = E[s²] = Var[y] = E[y²] − E[y]²  ≥ 0 (expected Fisher information wrt η).
function _glm_weight(f::CMPoisson, μ, n, me)
    ν = f.ν
    J = _compois_jmax(μ, ν, 0)
    _, Ey, Ey2 = _compois_logZ_moments(μ, ν, J)
    return max(Ey2 - Ey^2, zero(Ey))
end

# ℓ = y·logλ − ν·logΓ(y+1) − logZ  (closed form via the truncated logZ).
function _glm_logpdf(f::CMPoisson, μ, n, y)
    ν = f.ν
    J = _compois_jmax(μ, ν, y)
    logZ = _compois_logZ(μ, ν, J)
    return y * log(μ) - ν * loggamma(oftype(log(μ), y + 1)) - logZ
end

"""
    compoisson_marginal_loglik_laplace(Y, Λ, β, ν; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a Conway–Maxwell–Poisson
(COM-Poisson) GLLVM with Conway–Maxwell dispersion `ν` — a thin wrapper over the
family-generic `marginal_loglik_laplace` with the `CMPoisson(ν)` marker. `Y` is the
p×n integer count matrix; `Λ` p×K; `β` length-p (on the log-RATE scale, `λ = exp η`).
As `ν → 1` this tends to the Poisson marginal. COM-Poisson has no trial counts, so a
unit `N` is supplied internally.
"""
compoisson_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix, β::AbstractVector,
        ν::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(CMPoisson(float(ν)), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    CMPoissonFit

Result of [`fit_compoisson_gllvm`](@ref): intercepts `β` (length p; log-RATE scale),
loadings `Λ` (p×K), the estimated Conway–Maxwell dispersion `ν` (`ν > 1`
under-dispersion, `ν < 1` over-dispersion, `ν = 1` Poisson), the `link`, the
maximised Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct CMPoissonFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    ν::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::CMPoissonFit)
    p, K = size(f.Λ)
    print(io, "CMPoissonFit(p=", p, ", K=", K, ", ν=", round(f.ν; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_compoisson_gllvm(Y; K, link=LogLink(), ν_init=nothing, …) -> CMPoissonFit

Fit a Conway–Maxwell–Poisson (COM-Poisson) GLLVM by L-BFGS over `[β; vec(Λ); log ν]`
on the Laplace marginal ([`compoisson_marginal_loglik_laplace`](@ref)), jointly
estimating the Conway–Maxwell dispersion `ν`. `Y` is a p×n integer count matrix
(responses × sites); `K` the latent dimension. The latent variable enters only the
rate `λ = exp(β + Λz)`; `ν` is constant (v1). The L-BFGS gradient uses the generic
implicit dense-Laplace gradient (`marginal_loglik_laplace_implicit_value_grad`): the
per-site latent mode is found once by Fisher scoring, then the gradient is taken with
the implicit-function rule, with per-observation `(η, log ν)` derivatives supplied by
ForwardDiff through the closed-form (truncated) `_glm_logpdf`. Warm start = empirical
log-mean count intercepts + an SVD loadings init + `ν₀ = 1` (the Poisson centre).

WARNING: the normaliser `Z` is an infinite sum (truncated log-sum-exp). This family
is numerically delicate, especially under strong over-dispersion (`ν ≪ 1`, heavy
tail) and large rates; verify the FD gradient and parameter recovery before relying
on a fit.
"""
function fit_compoisson_gllvm(Y::AbstractMatrix{<:Union{Missing, Integer}}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, ν_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    rr = rr_theta_len(p, K)

    # warm start: empirical log-scale intercepts + SVD (PPCA-like) loadings. The
    # log-RATE intercept is approximated by the log-mean count (exact at ν = 1).
    # NA-aware warm start: per-trait observed-cell log-mean intercepts; missing cells
    # mean-filled for the SVD init ONLY (FIML estimator, issue #27). Byte-equivalent on dense Y.
    Zemp = Matrix{Float64}(undef, p, n)
    β0r = Vector{Float64}(undef, p)
    @inbounds for t in 1:p
        acc = 0.0; cnt = 0
        for i in 1:n
            if !ismissing(Y[t, i])
                v = linkfun(link, max(Y[t, i] + 0.5, 1e-4)); Zemp[t, i] = v; acc += v; cnt += 1
            end
        end
        m = cnt == 0 ? linkfun(link, 0.5) : acc / cnt
        β0r[t] = m
        for i in 1:n
            ismissing(Y[t, i]) && (Zemp[t, i] = m)
        end
    end
    β0 = β_init === nothing ? β0r : collect(float.(β_init))
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
    logν0 = ν_init === nothing ? 0.0 : log(float(ν_init))   # ν₀ = 1 (Poisson centre)

    θ0 = vcat(β0, pack_lambda(Λ0), logν0)
    family_fromθ = θ -> CMPoisson(_positive_from_log(θ[end]))
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
    ν̂ = _positive_from_log(θ̂[p + rr + 1])
    return CMPoissonFit(β̂, Λ̂, ν̂, link, -Optim.minimum(res),
                        Optim.converged(res), Optim.iterations(res))
end
