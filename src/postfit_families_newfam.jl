# Post-fit predict/fitted + getLV for the three newest non-Gaussian fit types that
# postfit.jl / postfit_families.jl do not yet cover: ZIBinomFit, GenPoissonFit,
# CMPoissonFit.
#
# This mirrors the PoissonFit / NBFit / BinomialFit methods in postfit.jl and the
# ZIPFit / ZINBFit / NB1Fit methods in postfit_families.jl EXACTLY: for each family
# the per-site conditional latent score is the Laplace mode `ẑₛ`, found by the SAME
# inner Fisher-scoring solver every other family uses (`_laplace_mode`,
# families/laplace.jl). The only per-type wrinkle is the family marker passed to that
# solver, taken from the already-defined `_fit_family(fit)` accessor (link_residual.jl,
# loaded before this file) so each family's score/weight pieces dispatch correctly —
# exactly as `getLV(::ZIPFit)` / `getLV(::PoissonFit)` pass `ZIP(fit.π)` / `Poisson()`.
#
# `predict(...; type=:link)` returns the linear predictor `η = β + Λ ẑ`;
# `type=:response` applies the family's response-scale mean (see each docstring):
#   * GenPoisson : `exp(η)` — the GP-1 mean E[y] = μ (the mean-parameterised log link)
#   * ZIBinom    : the marginal mean `(1 − π)·N·logistic(η)` (the structural zero
#                  DEFLATES the binomial expected COUNT N·p; needs the trial counts N,
#                  exactly like the Binomial / Beta-Binomial predict)
#   * CMPoisson  : the COM-Poisson MEAN E[y] (NOT the rate λ = exp(η)), reusing the
#                  family moment machinery `_compois_logZ_moments` / `_compois_jmax`
#                  from families/compoisson.jl (the same truncated sum that defines the
#                  score s = y − E[y]); `:link` returns the rate λ = exp(η).
# `fitted` reuses the shared `fitted(fit, data; kwargs...)` generic in postfit.jl.
#
# ADDITIVE: this file defines new `getLV` / `predict` methods and the three
# `_loadings` accessors only (the generics, `getLoadings`/`rotation`, and the
# `fitted` wrapper already exist in postfit.jl). It does NOT define residuals for
# these families (no existing per-family `_pit` hook to mirror, matching
# postfit_families.jl's residual-omission choice).

# Loadings accessors — each of these fit structs stores the p×K loadings in the `.Λ`
# field (exactly like PoissonFit/NBFit/ZIPFit/…), so `_loadings(fit) = fit.Λ`. This is
# what the shared `getLoadings`/`rotation` (postfit.jl) and `check_fit` (diagnostics.jl)
# dispatch on, and what my `getLV`/`predict` rotations stay consistent with. (Mirrors
# the per-family `_loadings(fit::ZIPFit) = fit.Λ` lines in postfit_families.jl; additive
# new methods on the existing internal generic. These are NOT defined in postfit.jl or
# postfit_families.jl for these three types.)
_loadings(fit::ZIBinomFit)    = fit.Λ
_loadings(fit::GenPoissonFit) = fit.Λ
_loadings(fit::CMPoissonFit)  = fit.Λ

# ---------------------------------------------------------------------------
# Zero-inflated Binomial post-fit (counts y ∈ {0,…,N}; logit link, success
# probability p = logistic(η), zero-inflation π). Parallel to BinomialFit /
# BetaBinomialFit: the trial counts `N` enter the per-site Laplace mode, and the
# RESPONSE-scale (marginal) mean is the DEFLATED expected COUNT (1 − π)·N·p, the
# binomial analogue of the ZIP marginal mean (1 − π)·μ.
# ---------------------------------------------------------------------------

"""
    getLV(fit::ZIBinomFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a zero-inflated Binomial fit: the per-site
Laplace mode `ẑₛ` (computed at the fitted zero-inflation `π`). `Y` is the p×n integer
response matrix; `N` the trial counts (default all-ones, i.e. zero-inflated Bernoulli).
`rotate=true` applies the canonical [`rotation`](@ref).
"""
function getLV(fit::ZIBinomFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::ZIBinomFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the marginal mean expected COUNT `(1 − π)·N·logistic(η)` (the mixture
`π·δ₀ + (1 − π)·Binomial(N, p)` has mean `(1 − π)·N·p`), the binomial analogue of the
ZIP marginal mean — the structural-zero component deflates the binomial expected count.
`N` is the trial counts used for the per-site mode solve and the expected count (default
all-ones, where `:response` is the marginal SUCCESS PROBABILITY `(1 − π)·p`).
"""
function predict(fit::ZIBinomFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    pr = linkinv.(Ref(fit.link), η)                  # success probability p = logistic(η)
    return (1 - fit.π) .* Nm .* pr                   # marginal mean count (1 − π)·N·p
end

# ---------------------------------------------------------------------------
# Generalized Poisson post-fit (GP-1, Famoye mean-parameterised; counts y ≥ 0; log
# link, mean μ = exp(η), dispersion α). Parallel to PoissonFit / NBFit: the
# mean-parameterised log link makes the RESPONSE-scale mean exactly the rate
# E[y] = μ = exp(η) (the GP-1 mean IS μ, unlike COM-Poisson), so `:response` is
# `linkinv(link, η) = exp(η)`.
# ---------------------------------------------------------------------------

"""
    getLV(fit::GenPoissonFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a Generalized Poisson (GP-1) fit: the per-site
Laplace mode `ẑₛ` (computed at the fitted dispersion `α`). `Y` is the p×n integer count
matrix; `rotate=true` applies the canonical [`rotation`](@ref). (`N` is accepted for
signature symmetry and ignored.)
"""
function getLV(fit::GenPoissonFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::GenPoissonFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns `η = β + Λ ẑ`;
`type=:response` the GP-1 fitted mean `linkinv(link, η) = exp(η)` — the GP-1 is
mean-parameterised, so `E[y] = μ = exp(η)` exactly (the dispersion `α` enters only the
variance `Var = μ(1+αμ)²`, not the mean). (`N` is accepted for signature symmetry and
ignored.)
"""
function predict(fit::GenPoissonFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    return linkinv.(Ref(fit.link), η)                # GP-1 mean E[y] = μ = exp(η)
end

# ---------------------------------------------------------------------------
# Conway–Maxwell–Poisson post-fit (counts y ≥ 0; RATE-parameterised log link, rate
# λ = exp(η), Conway–Maxwell dispersion ν). Parallel to PoissonFit, but the RESPONSE-
# scale mean is the COM-Poisson MEAN E[y] (NOT the rate λ): the rate parameterisation
# means `log E[y] ≠ η` unless ν = 1, so `:response` evaluates E[y] from the SAME
# truncated normaliser sum that defines the family score (s = y − E[y]) via
# `_compois_logZ_moments` / `_compois_jmax` (families/compoisson.jl). `:link` returns
# the rate λ = exp(η).
# ---------------------------------------------------------------------------

"""
    getLV(fit::CMPoissonFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores for a Conway–Maxwell–Poisson (COM-Poisson) fit: the
per-site Laplace mode `ẑₛ` (computed at the fitted Conway–Maxwell dispersion `ν`). `Y`
is the p×n integer count matrix; `rotate=true` applies the canonical [`rotation`](@ref).
(`N` is accepted for signature symmetry and ignored.)
"""
function getLV(fit::CMPoissonFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    fam = _fit_family(fit)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(fam, view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end

"""
    predict(fit::CMPoissonFit, Y; type=:response, N=nothing) -> p×n matrix

In-sample fitted values at the Laplace mode: `type=:link` returns the RATE linear
predictor `η = β + Λ ẑ` (so `linkinv(link, η) = exp(η)` is the COM-Poisson rate `λ`,
NOT its mean); `type=:response` the COM-Poisson MEAN `E[y]`. Because the family is
RATE-parameterised (`λ = exp η`), the mean is not `λ` unless `ν = 1`; `E[y]` is computed
per cell from the same truncated normaliser sum that defines the family score (the
`_compois_logZ_moments` / `_compois_jmax` machinery in `compoisson.jl`), so `:response`
is consistent with the fitted likelihood. (`N` is accepted for signature symmetry and
ignored.)
"""
function predict(fit::CMPoissonFit, Y::AbstractMatrix{<:Integer};
                 type::Symbol = :response,
                 N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing)
    type in (:link, :response) ||
        throw(ArgumentError("type must be :link or :response; got :$type"))
    Z = getLV(fit, Y; N = N, rotate = false)
    η = fit.β .+ fit.Λ * Z'
    type === :link && return η
    ν = fit.ν
    p, n = size(η)
    μ = Matrix{Float64}(undef, p, n)                 # COM-Poisson mean E[y] per cell
    @inbounds for j in 1:n, t in 1:p
        λ = exp(η[t, j])                             # rate λ = exp(η)
        J = _compois_jmax(λ, ν, 0)
        _, Ey, _ = _compois_logZ_moments(λ, ν, J)    # E[y] from the truncated sum
        μ[t, j] = Ey
    end
    return μ
end
