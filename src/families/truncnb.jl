# Zero-truncated negative-binomial (NB2) family pieces for the generic Laplace
# core (src/families/laplace.jl). y_t ∈ {1,2,…} (NO zeros): y ~ NB2(μ, r)
# conditioned on y ≥ 1, μ = exp(η) (log link), dispersion r > 0 with untruncated
# variance Var = μ + μ²/r (quadratic; the NB2 / families/negbin.jl parameterisation).
#
# Conditional law (Johnson, Kemp & Kotz 2005, Univariate Discrete Distributions,
# §5.8.3, zero-truncated negative binomial; Cohen 1960):
#   P(y = k | y ≥ 1) = NB2(k; μ, r) / (1 − P₀)     for k = 1, 2, …,
#   P₀ = P(y = 0) = (r/(r+μ))^r,
#   ⇒ logpdf = logpdf(NB2(μ, r), k) − log(1 − P₀).
# Untruncated moments: E[y] = μ, E[y²] = μ + μ²/r + μ²; truncating the y = 0 atom
# rescales by 1/(1−P₀) (k = 0 contributes nothing to either moment), so
#   E[y | y ≥ 1] = μ_tr = μ / (1 − P₀),
#   Var[y | y ≥ 1] = (μ + μ²/r + μ²)/(1 − P₀) − μ_tr².
#
# Score / weight wrt η (log link, dμ/dη = μ), θ = η. The UNTRUNCATED NB2 log-link
# score is r(y − μ)/(r + μ) (families/negbin.jl: (y−μ)/(μ+μ²/r)·μ). The truncation
# normaliser −log(1 − P₀) adds +(1/(1−P₀))·∂P₀/∂η; with ∂P₀/∂η = −P₀·rμ/(r+μ):
#   s = r(y − μ)/(r + μ) − (P₀/(1−P₀))·rμ/(r+μ)
#     = r/(r+μ) · (y − μ_tr)          (since μ + P₀μ/(1−P₀) = μ/(1−P₀) = μ_tr).
# Because s = r/(r+μ)·(y − μ_tr), the expected information (Fisher-scoring weight,
# always ≥ 0) is EXACTLY
#   W = E[s²] = (r/(r+μ))² · Var[y | y ≥ 1].
# As r → ∞ (P₀ → e^{-μ}, r/(r+μ) → 1) these reduce to the zero-truncated Poisson
# pieces (families/truncpoisson.jl): s → y − μ_tr, W → μ_tr(1 + μ − μ_tr).
#
# `_glm_logpdf` REUSES the NB2 conditional log-density from families/negbin.jl by
# CALLING `_glm_logpdf(NegativeBinomial(r, 0.5), …)` (which evaluates
# logpdf(NegativeBinomial(r, r/(r+μ)), Int(y))) and subtracting the stable
# truncation normaliser. `logpdf(NegativeBinomial(r, p), Int(y))` is ForwardDiff
# Dual-safe in both r and p, so the generic implicit-gradient path in laplace.jl
# (the same path NB1 / zero-truncated-Poisson use) is AD-clean: per-observation
# (η, log r) derivatives flow through this closed form.

"""
    TruncNB(r)

Zero-truncated negative-binomial (NB2) family marker: counts `y ∈ {1, 2, …}`
drawn from `NB2(μ, r)` (`Var = μ + μ²/r`) conditioned on `y ≥ 1`, with log link
(`μ = exp η`) and dispersion `r > 0`. Used as the family argument to the generic
Laplace core (the zero-truncated twin of the `NegativeBinomial(r, ·)` NB2 marker).
Only the dispersion `r` is stored.
"""
struct TruncNB{T<:Real}
    r::T
end

default_link(::TruncNB) = LogLink()

_clamp_mu(::TruncNB, μ) = max(μ, 1e-12)

# Zero-truncation atom P₀ = (r/(r+μ))^r in a Dual-safe exp/log form.
@inline _ztnb_P0(μ, r) = exp(r * (log(r) - log(r + μ)))
# Truncated mean μ_tr = μ/(1 − P₀).
@inline _ztnb_mutr(μ, r) = μ / (one(μ) - _ztnb_P0(μ, r))
# Truncated variance Var[y|y≥1] = (μ + μ²/r + μ²)/(1 − P₀) − μ_tr².
@inline function _ztnb_var(μ, r)
    omp0 = one(μ) - _ztnb_P0(μ, r)
    EY = μ / omp0
    EY2 = (μ + μ^2 / r + μ^2) / omp0
    return EY2 - EY^2
end

# Score wrt η (log link): s = r/(r+μ)·(y − μ_tr).
_glm_score(f::TruncNB, μ, n, me, y) = f.r / (f.r + μ) * (y - _ztnb_mutr(μ, f.r))
# Expected information wrt η: W = (r/(r+μ))²·Var[y|y≥1] ≥ 0.
_glm_weight(f::TruncNB, μ, n, me) = (f.r / (f.r + μ))^2 * _ztnb_var(μ, f.r)
# Conditional log-density: REUSE the NB2 logpdf (families/negbin.jl) and subtract
# the stable truncation normaliser log(1 − P₀) = log1p(−P₀).
_glm_logpdf(f::TruncNB, μ, n, y) =
    _glm_logpdf(NegativeBinomial(f.r, 0.5), μ, n, y) - log1p(-_ztnb_P0(μ, f.r))

"""
    truncnb_marginal_loglik_laplace(Y, Λ, β, r; link=LogLink(), kwargs...) -> Float64

Total Laplace log-marginal over the `n` sites (columns) of a zero-truncated
negative-binomial (NB2) GLLVM with dispersion `r` (`Var = μ + μ²/r`, counts
`y ≥ 1`) — a thin wrapper over the family-generic `marginal_loglik_laplace` with
the `TruncNB(r)` marker. `Y` is the p×n integer count matrix (all entries `≥ 1`);
`Λ` p×K; `β` length-p. As `r → ∞` this tends to the zero-truncated Poisson
marginal (`truncpoisson_marginal_loglik_laplace`).
"""
truncnb_marginal_loglik_laplace(Y::AbstractMatrix, Λ::AbstractMatrix,
        β::AbstractVector, r::Real; link::Link = LogLink(), kwargs...) =
    marginal_loglik_laplace(TruncNB(float(r)), Y, ones(Int, size(Y)), Λ, β, link; kwargs...)

# ---------------------------------------------------------------------------
# Fit driver.
# ---------------------------------------------------------------------------

"""
    TruncNBFit

Result of [`fit_truncnb_gllvm`](@ref): intercepts `β` (length p), loadings `Λ`
(p×K), the estimated dispersion `r` (untruncated `Var = μ + μ²/r`), the `link`,
the maximised Laplace `loglik`, the optimiser `converged` flag, and `iterations`.
"""
struct TruncNBFit
    β::Vector{Float64}
    Λ::Matrix{Float64}
    r::Float64
    link::Link
    loglik::Float64
    converged::Bool
    iterations::Int
end

function Base.show(io::IO, f::TruncNBFit)
    p, K = size(f.Λ)
    print(io, "TruncNBFit(p=", p, ", K=", K, ", r=", round(f.r; sigdigits = 4),
          ", link=", nameof(typeof(f.link)),
          ", loglik=", round(f.loglik; sigdigits = 7),
          f.converged ? "" : ", NOT CONVERGED", ")")
end

"""
    fit_truncnb_gllvm(Y; K, link=LogLink(), r_init=nothing, …) -> TruncNBFit

Fit a zero-truncated negative-binomial (NB2) GLLVM by L-BFGS over
`[β; vec(Λ); log r]` on the Laplace marginal (`truncnb_marginal_loglik_laplace`),
jointly estimating the dispersion `r`. `Y` is a p×n integer count matrix
(responses × sites) with every entry `≥ 1`; `K` the latent dimension. The L-BFGS
gradient uses the generic implicit dense-Laplace gradient
(`marginal_loglik_laplace_implicit_value_grad`): the per-site latent mode is found
once by Fisher scoring, then the gradient is taken with the implicit-function
rule, with per-observation `(η, log r)` derivatives supplied by ForwardDiff
through the closed-form `_glm_logpdf`. Warm start = empirical log-mean intercepts
+ an SVD (PPCA-style) loadings init + a moderate `r₀`.
"""
function fit_truncnb_gllvm(Y::AbstractMatrix{<:Union{Missing, Integer}}; K::Integer,
        link::Link = LogLink(),
        β_init = nothing, Λ_init = nothing, r_init = nothing,
        g_tol::Real = 1e-5, iterations::Integer = 500,
        newton_maxiter::Integer = 100, newton_tol::Real = 1e-9)
    p, n = size(Y)
    all(x -> ismissing(x) || x ≥ 1, Y) || throw(ArgumentError(
        "fit_truncnb_gllvm: zero-truncated NB requires all observed Y ≥ 1"))
    rr = rr_theta_len(p, K)

    # warm start: empirical log-scale intercepts + SVD (PPCA-like) loadings
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
    logr0 = r_init === nothing ? log(10.0) : log(float(r_init))

    θ0 = vcat(β0, pack_lambda(Λ0), logr0)
    family_fromθ = θ -> TruncNB(_positive_from_log(θ[end]))
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
    return TruncNBFit(β̂, Λ̂, r̂, link, -Optim.minimum(res),
                      Optim.converged(res), Optim.iterations(res))
end
