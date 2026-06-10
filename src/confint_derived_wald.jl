# Transformed-scale Wald confidence intervals for *derived bounded
# quantities* of a fitted Gaussian GLLVM.
#
# Motivation
# ----------
# src/confint_derived.jl gives two CI methods for derived scalars g(θ)
# (cross-trait correlation ρ ∈ [−1, 1], communality c² ∈ [0, 1], ICC ∈
# [0, 1], phylogenetic signal H² ∈ [0, 1]): the parametric bootstrap and
# the constrained-refit profile. Both are expensive — each needs many
# refits. The per-parameter Wald machinery in src/confint.jl is cheap (one
# Hessian) and, crucially, already gets ~nominal coverage for the SD
# parameters by building the interval on the *log* scale and
# back-transforming: `exp(log σ̂ ± z·SE_log)`. The back-transform keeps the
# bound positive, and the symmetric-on-the-log-scale interval matches the
# sampling geometry far better than a raw-scale `σ̂ ± z·SE`.
#
# This file applies the same idea to the *derived* bounded quantities. For
# a derived scalar g(θ) with a natural bound we pick a link h that maps the
# bounded range to the whole real line, build the Wald interval there, and
# map back:
#
#   correlation ρ ∈ [−1, 1]:   h = Fisher-z = atanh,  back = tanh
#   c² / ICC / H² ∈ [0, 1]:    h = logit,             back = logistic
#
# Delta-method SE on the transformed scale:
#   SE_h = sqrt( ∇θ(h∘g)' · Σ · ∇θ(h∘g) ),   Σ = inv(observed information),
# with ∇θ(h∘g) obtained by ForwardDiff on the *dense marginal* packed-θ
# closure (the derived functions in confint_derived.jl are AD-friendly:
# ForwardDiff Duals flow through unpack_lambda, exp, division). The CI is
#   back( h(g(θ̂)) ± z·SE_h ),
# which is guaranteed to lie inside the natural range because `back` maps
# ℝ → (−1, 1) (resp. (0, 1)).
#
# The observed information H = ForwardDiff.hessian(nll, θ̂) and Σ = inv(H)
# are exactly the objects src/confint.jl already builds; we reuse its
# _confint_reconstruct_nll helper so the Hessian convention is identical.
#
# This file is additive: it does NOT modify confint.jl or
# confint_derived.jl. It defines packed-θ closures for the derived
# quantities that did not yet have one (correlation, phylo signal); the
# communality/ICC closure already exists as _communality_packed.

using Distributions: Normal, quantile
using LinearAlgebra: diag

# ---------------------------------------------------------------------------
# Link functions (transformed scale ↔ natural scale).
# Written generically so ForwardDiff Duals pass through h∘g unchanged.
# ---------------------------------------------------------------------------

# Fisher-z for correlations on [−1, 1].
_tw_fisher_z(ρ)     = atanh(ρ)
_tw_fisher_z_inv(z) = tanh(z)

# logit / logistic for quantities on [0, 1].
_tw_logit(x)        = log(x / (1 - x))
_tw_logistic(z)     = 1 / (1 + exp(-z))

# Map a transform symbol to (forward link, inverse link, natural bounds).
function _tw_link(transform::Symbol)
    if transform === :fisher_z
        return (_tw_fisher_z, _tw_fisher_z_inv, (-1.0, 1.0))
    elseif transform === :logit
        return (_tw_logit, _tw_logistic, (0.0, 1.0))
    else
        throw(ArgumentError(
            "transform must be :fisher_z (correlations, [−1,1]) or " *
            ":logit (communality/ICC/H², [0,1]); got $(transform)"))
    end
end

# ---------------------------------------------------------------------------
# Packed-θ derived-quantity closures.
#
# _communality_packed already lives in confint_derived.jl (loaded before
# this file). We add the two that did not have a packed form: the
# cross-trait correlation and the phylogenetic signal. Both reconstruct the
# per-site covariance via _sigma_y_site_from_unpacked, exactly as the
# GllvmFit-consuming versions in confint_derived.jl, so the packed value at
# θ̂ equals the public `correlation(fit)` / `phylo_signal(fit)` entry.
# ---------------------------------------------------------------------------

# ρ[i, j] from the packed θ. AD-friendly.
function _correlation_packed(θ::AbstractVector, spec::NamedTuple,
                             i::Integer, j::Integer)
    u = _derived_unpack(θ, spec)
    Σ = _sigma_y_site_from_unpacked(u, spec)
    return Σ[i, j] / sqrt(Σ[i, i] * Σ[j, j])
end

function _make_correlation_closure(spec::NamedTuple, i::Integer, j::Integer)
    return θ -> _correlation_packed(θ, spec, i, j)
end

# H²[t] from the packed θ, mirroring phylo_signal(fit). Σ_phy enters only
# through its diagonal (standardised convention → ones). AD-friendly.
function _phylo_signal_packed(θ::AbstractVector, spec::NamedTuple, t::Integer;
                              diag_Σphy::Union{Nothing, AbstractVector} = nothing)
    u = _derived_unpack(θ, spec)
    p = spec.p
    Λ_phy = u.Λ_phy
    σ_phy = u.σ_phy
    Λ_phy_aug = if Λ_phy !== nothing && σ_phy !== nothing
        hcat(Λ_phy, reshape(σ_phy, p, 1))
    elseif Λ_phy !== nothing
        Λ_phy
    elseif σ_phy !== nothing
        reshape(σ_phy, p, 1)
    else
        throw(ArgumentError("fit has no phylogenetic block; H² is undefined"))
    end
    Σ = _sigma_y_site_from_unpacked(u, spec)
    ΛΛt_tt = zero(eltype(Λ_phy_aug))
    @inbounds for k in 1:size(Λ_phy_aug, 2)
        ΛΛt_tt += Λ_phy_aug[t, k]^2
    end
    d = diag_Σphy === nothing ? one(eltype(Λ_phy_aug)) : diag_Σphy[t]
    return ΛΛt_tt * d / Σ[t, t]
end

function _make_phylo_signal_closure(spec::NamedTuple, t::Integer;
                                    diag_Σphy::Union{Nothing, AbstractVector} = nothing)
    return θ -> _phylo_signal_packed(θ, spec, t; diag_Σphy = diag_Σphy)
end

# ---------------------------------------------------------------------------
# Observed-information Σ = inv(H), reusing confint.jl's NLL reconstruction
# and Hessian convention. Returns (Σ, pd::Bool); Σ is `nothing` when the
# Hessian is unavailable / non-PD.
# ---------------------------------------------------------------------------
function _tw_sigma_from_hessian(fit::GllvmFit, y::AbstractMatrix,
                                X::Union{Nothing, AbstractArray{<:Real, 3}},
                                Σ_phy::Union{Nothing, AbstractMatrix})
    θ̂ = fit.pars.θ_packed
    nll = _confint_reconstruct_nll(fit, y, X, Σ_phy)
    H = try
        ForwardDiff.hessian(nll, θ̂)
    catch
        return (nothing, false)
    end
    (H === nothing || !all(isfinite, H)) && return (nothing, false)
    Σ = try
        inv((H .+ H') ./ 2)
    catch
        return (nothing, false)
    end
    return (Σ, true)
end

# ---------------------------------------------------------------------------
# Public API: transformed-scale Wald CI for a scalar derived quantity.
# ---------------------------------------------------------------------------

"""
    transformed_wald_ci_derived(fit::GllvmFit, derived_fn_packed::Function;
                                transform::Symbol,
                                level = 0.95, y = nothing,
                                X = nothing, Σ_phy = nothing)
        -> NamedTuple{(:lower, :upper, :estimate, :se_transformed,
                       :transform, :pd_hessian, :method)}

Transformed-scale Wald confidence interval for a scalar-valued *derived
bounded quantity* `g(θ) = derived_fn_packed(θ_packed)`.

`transform` selects the link `h` that maps the natural range to ℝ:
  - `:fisher_z` — `h = atanh`, `back = tanh`; for correlations ρ ∈ [−1, 1].
  - `:logit`    — `h = logit`, `back = logistic`; for c²/ICC/H² ∈ [0, 1].

The interval is built on the transformed scale and mapped back:
    `CI = back( h(g(θ̂)) ± z·SE_h )`,  `SE_h = sqrt(∇θ(h∘g)' Σ ∇θ(h∘g))`,
where `Σ = inv(H)` is the asymptotic covariance from the observed
information `H = ForwardDiff.hessian(nll, θ̂)` (the same Hessian
`confint` uses), and `∇θ(h∘g)` is obtained by ForwardDiff on the dense
packed-θ marginal. Because `back` maps ℝ into the open natural range, the
returned bounds are *guaranteed* to lie inside `(−1, 1)` (resp. `(0, 1)`).

The point `estimate` is `g(θ̂)` — the raw derived quantity, identical to
the public accessor (`correlation(fit)[i,j]`, `communality(fit)[t]`, …).

`derived_fn_packed` must accept a packed-parameter vector and return a
scalar; use the closure helpers in this file / confint_derived.jl:

```julia
spec = GLLVM._derived_spec(fit)
f_ρ  = GLLVM._make_correlation_closure(spec, 1, 2)   # ρ[1,2]
ci   = GLLVM.transformed_wald_ci_derived(fit, f_ρ;
                                         transform = :fisher_z, y = y)

f_c2 = GLLVM._make_communality_closure(spec, 1)      # c²[1]
ci2  = GLLVM.transformed_wald_ci_derived(fit, f_c2;
                                         transform = :logit, y = y)
```

Or the thin wrappers `correlation_wald_ci`, `communality_wald_ci`,
`icc_wald_ci`, `phylo_signal_wald_ci`.

Returns a NamedTuple with fields:
  - `estimate::Float64`       — `g(θ̂)` (raw derived quantity)
  - `lower::Float64`          — lower CI bound (back-transformed)
  - `upper::Float64`          — upper CI bound (back-transformed)
  - `se_transformed::Float64` — delta-method SE on the transformed scale
  - `transform::Symbol`       — `:fisher_z` or `:logit`
  - `pd_hessian::Bool`        — whether the observed information was PD
  - `method::Symbol`          — `:transformed_wald` (success) or `:failed`
                                (non-PD Hessian, non-finite SE, or the
                                point estimate on the boundary where `h`
                                is undefined → bounds `NaN`)

Boundary note: if `g(θ̂)` equals a bound exactly (ρ = ±1, c² ∈ {0, 1}),
`h(g(θ̂))` is ±∞ and the interval is undefined; this returns `NaN` bounds
with `method = :failed`. Interior estimates are the generic case.
"""
function transformed_wald_ci_derived(fit::GllvmFit, derived_fn_packed::Function;
                                     transform::Symbol,
                                     level::Real = 0.95,
                                     y::Union{Nothing, AbstractMatrix} = nothing,
                                     X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                                     Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    y === nothing && throw(ArgumentError(
        "transformed_wald_ci_derived requires the data matrix `y` " *
        "(the same matrix passed to fit_gaussian_gllvm)"))

    h, back, (lo_bound, hi_bound) = _tw_link(transform)

    θ̂ = fit.pars.θ_packed
    g_hat = Float64(derived_fn_packed(θ̂))

    failed = (; estimate = g_hat, lower = NaN, upper = NaN,
              se_transformed = NaN, transform = transform,
              pd_hessian = false, method = :failed)

    # Point estimate must be finite and strictly interior for h to be defined.
    if !isfinite(g_hat) || g_hat ≤ lo_bound || g_hat ≥ hi_bound
        return failed
    end

    Σ, pd = _tw_sigma_from_hessian(fit, y, X, Σ_phy)
    (Σ === nothing || !pd) && return merge(failed, (; pd_hessian = false))

    # ∇θ(h∘g) at θ̂ via ForwardDiff. h∘g is scalar-valued.
    hg = θ -> h(derived_fn_packed(θ))
    grad = try
        ForwardDiff.gradient(hg, θ̂)
    catch
        return merge(failed, (; pd_hessian = true))
    end
    (all(isfinite, grad)) || return merge(failed, (; pd_hessian = true))

    var_h = dot(grad, Σ * grad)
    if !isfinite(var_h) || var_h < 0
        return merge(failed, (; pd_hessian = true))
    end
    se_h = sqrt(var_h)

    z = quantile(Normal(), 0.5 + level / 2)
    h_hat = h(g_hat)
    lower = back(h_hat - z * se_h)
    upper = back(h_hat + z * se_h)

    return (; estimate = g_hat, lower = lower, upper = upper,
            se_transformed = se_h, transform = transform,
            pd_hessian = true, method = :transformed_wald)
end

# ---------------------------------------------------------------------------
# Thin convenience wrappers for the four built-in bounded quantities.
# ---------------------------------------------------------------------------

"""
    correlation_wald_ci(fit, i, j; level=0.95, y, X=nothing, Σ_phy=nothing)

Fisher-z transformed-Wald CI for the cross-trait correlation `ρ[i, j]`.
Bounds are guaranteed to lie in `[−1, 1]`. See
[`transformed_wald_ci_derived`](@ref).
"""
function correlation_wald_ci(fit::GllvmFit, i::Integer, j::Integer;
                             level::Real = 0.95,
                             y::Union{Nothing, AbstractMatrix} = nothing,
                             X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                             Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    spec = _derived_spec(fit)
    f = _make_correlation_closure(spec, i, j)
    return transformed_wald_ci_derived(fit, f; transform = :fisher_z,
                                       level = level, y = y, X = X, Σ_phy = Σ_phy)
end

"""
    communality_wald_ci(fit, t; level=0.95, y, X=nothing, Σ_phy=nothing)

Logit transformed-Wald CI for the per-trait communality `c²[t]`. Bounds
are guaranteed to lie in `[0, 1]`. See [`transformed_wald_ci_derived`](@ref).
"""
function communality_wald_ci(fit::GllvmFit, t::Integer;
                             level::Real = 0.95,
                             y::Union{Nothing, AbstractMatrix} = nothing,
                             X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                             Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    spec = _derived_spec(fit)
    f = _make_communality_closure(spec, t)
    return transformed_wald_ci_derived(fit, f; transform = :logit,
                                       level = level, y = y, X = X, Σ_phy = Σ_phy)
end

"""
    icc_wald_ci(fit, derived_fn_packed; level=0.95, y, X=nothing, Σ_phy=nothing)

Logit transformed-Wald CI for an intraclass-correlation-style proportion
in `[0, 1]` supplied as a packed-θ closure (e.g. one of the
`proportions(...)` components written in packed form). Identical to
calling [`transformed_wald_ci_derived`](@ref) with `transform = :logit`;
provided for naming symmetry.
"""
function icc_wald_ci(fit::GllvmFit, derived_fn_packed::Function;
                     level::Real = 0.95,
                     y::Union{Nothing, AbstractMatrix} = nothing,
                     X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                     Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    return transformed_wald_ci_derived(fit, derived_fn_packed; transform = :logit,
                                       level = level, y = y, X = X, Σ_phy = Σ_phy)
end

"""
    phylo_signal_wald_ci(fit, t; level=0.95, y, X=nothing, Σ_phy=nothing)

Logit transformed-Wald CI for the per-trait phylogenetic signal `H²[t]`.
Bounds are guaranteed to lie in `[0, 1]`. `Σ_phy` enters only through its
diagonal (standardised convention → unit diagonal when omitted). See
[`transformed_wald_ci_derived`](@ref).
"""
function phylo_signal_wald_ci(fit::GllvmFit, t::Integer;
                              level::Real = 0.95,
                              y::Union{Nothing, AbstractMatrix} = nothing,
                              X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
                              Σ_phy::Union{Nothing, AbstractMatrix} = nothing)
    spec = _derived_spec(fit)
    diag_Σphy = Σ_phy === nothing ? nothing : diag(Σ_phy)
    f = _make_phylo_signal_closure(spec, t; diag_Σphy = diag_Σphy)
    return transformed_wald_ci_derived(fit, f; transform = :logit,
                                       level = level, y = y, X = X, Σ_phy = Σ_phy)
end

# ===========================================================================
# Transformed-scale Wald CIs for derived bounded quantities of the NON-GAUSSIAN
# one-part fits whose link-implicit residual σ²_d is a μ̂-FREE CONSTANT, i.e.
# BinomialFit and OrdinalFit.
#
# For these families the latent-scale covariance is
#     Σ_latent(θ) = Λ(θ) Λ(θ)ᵀ + diag(c),      c[t] = σ²_d  (a constant),
# so a packed-θ reconstruction of the correlation / communality is exact and
# AD-clean: at θ̂ it equals the public `correlation(fit, Y)` / `communality(fit, Y)`
# entry (because `link_residual(::BinomialFit/::OrdinalFit, Y)` returns exactly
# that constant — see src/link_residual.jl), and ForwardDiff flows through
# `unpack_lambda`, the outer product, and the standardisation. The
# observed-information Σ = inv(H) is built from the SAME pure-value NLL the
# family's `confint(::BinomialFit/::OrdinalFit)` uses (src/confint_families.jl),
# so the Hessian convention matches.
#
# The other one-part families (Poisson, NB, Gamma, Beta) and MixedFamilyFit have
# a μ̂-DEPENDENT σ²_d (the fitted mean enters σ²_d through the Laplace mode), so a
# packed reconstruction matching the public estimate would need to differentiate
# through the inner mode solve. That transformed-Wald path is DEFERRED; use the
# parametric bootstrap (`bootstrap_ci_derived` / `correlation_boot_ci` /
# `communality_boot_ci`) for those fits.
# ===========================================================================

# Latent-scale correlation ρ[i, j] = Σ[i,j]/√(Σ[i,i]Σ[j,j]) from packed θ, with
# Σ = Λ Λᵀ + diag(c) and a μ̂-free constant residual vector c. AD-friendly.
function _latent_correlation_packed(Λ::AbstractMatrix, c::AbstractVector,
                                    i::Integer, j::Integer)
    Σ_ii = c[i]
    Σ_jj = c[j]
    Σ_ij = zero(eltype(Λ))
    @inbounds for k in 1:size(Λ, 2)
        Σ_ii += Λ[i, k]^2
        Σ_jj += Λ[j, k]^2
        Σ_ij += Λ[i, k] * Λ[j, k]
    end
    return Σ_ij / sqrt(Σ_ii * Σ_jj)
end

# Latent-scale communality c²[t] = (ΛΛᵀ)[t,t] / Σ[t,t] from packed θ. AD-friendly.
function _latent_communality_packed(Λ::AbstractMatrix, c::AbstractVector, t::Integer)
    ΛΛt = zero(eltype(Λ))
    @inbounds for k in 1:size(Λ, 2)
        ΛΛt += Λ[t, k]^2
    end
    return ΛΛt / (ΛΛt + c[t])
end

# Generic transformed-Wald core for a non-Gaussian/mixed packed objective.
# `θ̂` is the packed MLE, `nll` the pure-value NLL closure, `g` a packed
# derived-quantity closure (g(θ̂) == public estimate). Mirrors
# transformed_wald_ci_derived(::GllvmFit, …) but takes the NLL directly instead
# of reconstructing it from a GllvmFit. Same field shape.
function _transformed_wald_ci_packed(θ̂::AbstractVector, nll, g, transform::Symbol;
                                     level::Real = 0.95)
    0 < level < 1 || throw(ArgumentError("level must be in (0, 1); got $level"))
    h, back, (lo_bound, hi_bound) = _tw_link(transform)
    g_hat = Float64(g(θ̂))

    failed = (; estimate = g_hat, lower = NaN, upper = NaN,
              se_transformed = NaN, transform = transform,
              pd_hessian = false, method = :failed)
    (!isfinite(g_hat) || g_hat ≤ lo_bound || g_hat ≥ hi_bound) && return failed

    H = try
        ForwardDiff.hessian(nll, θ̂)
    catch
        return failed
    end
    (H === nothing || !all(isfinite, H)) && return failed
    Σ = try
        inv((H .+ H') ./ 2)
    catch
        return failed
    end

    hg = θ -> h(g(θ))
    grad = try
        ForwardDiff.gradient(hg, θ̂)
    catch
        return merge(failed, (; pd_hessian = true))
    end
    all(isfinite, grad) || return merge(failed, (; pd_hessian = true))

    var_h = dot(grad, Σ * grad)
    (isfinite(var_h) && var_h ≥ 0) || return merge(failed, (; pd_hessian = true))
    se_h = sqrt(var_h)

    z = quantile(Normal(), 0.5 + level / 2)
    h_hat = h(g_hat)
    return (; estimate = g_hat, lower = back(h_hat - z * se_h),
            upper = back(h_hat + z * se_h), se_transformed = se_h,
            transform = transform, pd_hessian = true, method = :transformed_wald)
end

# ---------------------------------------------------------------------------
# Binomial: packed θ = [β(1:p); pack_lambda(Λ)]; σ²_d = _binomial_link_residual(link)
# (constant). NLL reused verbatim from confint(::BinomialFit).
# ---------------------------------------------------------------------------

# (θ̂, nll, Λ-from-θ, constant residual vector c) shared by the Binomial CIs.
function _binomial_wald_pieces(fit::BinomialFit, Y::AbstractMatrix,
                               N::Union{Nothing, AbstractMatrix})
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    Nm = N === nothing ? fill(1, p, size(Y, 2)) : N
    size(Nm) == size(Y) || throw(DimensionMismatch("N must match size(Y) = $(size(Y))"))
    θ̂ = vcat(fit.β, pack_lambda(fit.Λ))
    link = fit.link
    nll = θ -> -binomial_marginal_loglik_laplace(
        Y, Nm, unpack_lambda(θ[(p + 1):(p + rr)], p, K), θ[1:p], link)
    c = fill(_binomial_link_residual(link), p)
    Λ_of = θ -> unpack_lambda(θ[(p + 1):(p + rr)], p, K)
    return θ̂, nll, Λ_of, c
end

"""
    correlation_wald_ci(fit::BinomialFit, i, j; Y, N=nothing, level=0.95)

Fisher-z transformed-Wald CI for the latent-scale cross-trait correlation
`ρ[i, j]` of a fitted Binomial GLLVM. The link-implicit residual σ²_d is a
μ̂-free constant (π²/3 logit, 1 probit, π²/6 cloglog), so the packed
reconstruction is exact and AD-clean; the observed information is the same
Hessian `confint(::BinomialFit)` uses. Bounds lie in `[−1, 1]`. `Y`/`N` are the
response matrix / trial counts the fit was computed on. See
[`transformed_wald_ci_derived`](@ref) for the field shape.
"""
function correlation_wald_ci(fit::BinomialFit, i::Integer, j::Integer;
                             Y::Union{Nothing, AbstractMatrix} = nothing,
                             N::Union{Nothing, AbstractMatrix} = nothing,
                             level::Real = 0.95)
    Y === nothing && throw(ArgumentError(
        "correlation_wald_ci(::BinomialFit) requires the data matrix `Y`"))
    θ̂, nll, Λ_of, c = _binomial_wald_pieces(fit, Y, N)
    g = θ -> _latent_correlation_packed(Λ_of(θ), c, i, j)
    return _transformed_wald_ci_packed(θ̂, nll, g, :fisher_z; level = level)
end

"""
    communality_wald_ci(fit::BinomialFit, t; Y, N=nothing, level=0.95)

Logit transformed-Wald CI for the latent-scale per-trait communality `c²[t]` of
a fitted Binomial GLLVM (μ̂-free constant residual; see
[`correlation_wald_ci`](@ref)). Bounds lie in `[0, 1]`.
"""
function communality_wald_ci(fit::BinomialFit, t::Integer;
                             Y::Union{Nothing, AbstractMatrix} = nothing,
                             N::Union{Nothing, AbstractMatrix} = nothing,
                             level::Real = 0.95)
    Y === nothing && throw(ArgumentError(
        "communality_wald_ci(::BinomialFit) requires the data matrix `Y`"))
    θ̂, nll, Λ_of, c = _binomial_wald_pieces(fit, Y, N)
    g = θ -> _latent_communality_packed(Λ_of(θ), c, t)
    return _transformed_wald_ci_packed(θ̂, nll, g, :logit; level = level)
end

# ---------------------------------------------------------------------------
# Ordinal: packed θ = [pack_lambda(Λ); ψ]; σ²_d = π²/3 (constant). NLL reused
# verbatim from confint(::OrdinalFit).
# ---------------------------------------------------------------------------

function _ordinal_wald_pieces(fit::OrdinalFit, Y::AbstractMatrix)
    p, K = size(fit.Λ)
    rr = rr_theta_len(p, K)
    C = fit.C
    τ = fit.τ
    ψ = similar(τ)
    ψ[1] = τ[1]
    @inbounds for cidx in 2:length(τ)
        ψ[cidx] = log(τ[cidx] - τ[cidx - 1])
    end
    θ̂ = vcat(pack_lambda(fit.Λ), ψ)
    nll = θ -> -ordinal_marginal_loglik_laplace(
        Y, unpack_lambda(θ[1:rr], p, K), _unpack_cutpoints(θ[(rr + 1):(rr + C - 1)]))
    c = fill(π^2 / 3, p)
    Λ_of = θ -> unpack_lambda(θ[1:rr], p, K)
    return θ̂, nll, Λ_of, c
end

"""
    correlation_wald_ci(fit::OrdinalFit, i, j; Y, level=0.95)

Fisher-z transformed-Wald CI for the latent-scale cross-trait correlation
`ρ[i, j]` of a fitted cumulative-logit ordinal GLLVM. The link-implicit residual
σ²_d = π²/3 is a constant, so the packed reconstruction is exact and AD-clean;
the observed information is the same Hessian `confint(::OrdinalFit)` uses. Bounds
lie in `[−1, 1]`. `Y` is the response matrix the fit was computed on.
"""
function correlation_wald_ci(fit::OrdinalFit, i::Integer, j::Integer;
                             Y::Union{Nothing, AbstractMatrix} = nothing,
                             level::Real = 0.95)
    Y === nothing && throw(ArgumentError(
        "correlation_wald_ci(::OrdinalFit) requires the data matrix `Y`"))
    θ̂, nll, Λ_of, c = _ordinal_wald_pieces(fit, Y)
    g = θ -> _latent_correlation_packed(Λ_of(θ), c, i, j)
    return _transformed_wald_ci_packed(θ̂, nll, g, :fisher_z; level = level)
end

"""
    communality_wald_ci(fit::OrdinalFit, t; Y, level=0.95)

Logit transformed-Wald CI for the latent-scale per-trait communality `c²[t]` of
a fitted cumulative-logit ordinal GLLVM (constant residual π²/3; see
[`correlation_wald_ci`](@ref)). Bounds lie in `[0, 1]`.
"""
function communality_wald_ci(fit::OrdinalFit, t::Integer;
                             Y::Union{Nothing, AbstractMatrix} = nothing,
                             level::Real = 0.95)
    Y === nothing && throw(ArgumentError(
        "communality_wald_ci(::OrdinalFit) requires the data matrix `Y`"))
    θ̂, nll, Λ_of, c = _ordinal_wald_pieces(fit, Y)
    g = θ -> _latent_communality_packed(Λ_of(θ), c, t)
    return _transformed_wald_ci_packed(θ̂, nll, g, :logit; level = level)
end
