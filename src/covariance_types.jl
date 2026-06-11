# Trait-covariance taxonomy (plan SP1.5): `latent` / `dep` / `indep` + the `specific`
# knob. This is the structure of how the p TRAITS covary within a variance component
# (the ordination LVs, the residual, a cluster RE …) — a factor-analytic covariance on
# the p-dimensional response, distinct from `REBlock.cov` (which is the grouping-level
# covariance of the per-level coefficients).
#
# A component's p×p trait covariance is, in every case, `Λ Λᵀ + diag(s)`:
#   - `latent(K, specific)` — K reduced-rank factors `Λ` (p×K); `+ diag(s_t)` iff `specific`.
#   - `indep`               — diagonal only (K = 0): `diag(s_t)`.
#   - `dep`                 — full unstructured (K = p): a free SPD matrix.
# So the three "types" are points on the rank axis (K = 0 / 0<K<p / p); `specific` is a
# `latent`-only knob (it's implied for `indep`, moot for `dep`).
#
# The per-trait `specific` variance `s_t` is the ESTIMATED half of the latent-scale
# residual `ψ_t = s_t + d_t`; `d_t` (the distribution-specific half) is `link_residual.jl`.

"""
    LatentCov(kind, K, specific)

Descriptor for one trait-covariance component. `kind ∈ (:latent, :indep, :dep)`;
`K` = number of reduced-rank factors (`latent` only; 0 for `indep`; the full rank `p`
is implied for `dep`); `specific::Bool` = estimate the per-trait specific variances
`s_t` (the FA `Ψ` diagonal). Build with [`latent`](@ref) / [`indep`](@ref) /
[`dep`](@ref); realise a covariance with [`trait_cov`](@ref).
"""
struct LatentCov
    kind::Symbol
    K::Int
    specific::Bool
end

"""
    latent(K; specific=false) -> LatentCov

A reduced-rank factor component: `Λ Λᵀ` (`Λ` is p×K), plus a per-trait specific
diagonal `diag(s_t)` when `specific=true`. `specific=false` ⇒ pure `Λ Λᵀ` (NOT a
single shared σ²). Default `specific=false` (the SDM/ordination-friendly, always-
identifiable choice; turn it on for trait/heritability models).
"""
function latent(K::Integer; specific::Bool = false)
    K ≥ 1 || throw(ArgumentError("latent: K must be ≥ 1 (got $K); use indep() for K=0"))
    return LatentCov(:latent, Int(K), specific)
end

"""
    indep() -> LatentCov

An independent (diagonal) component, `diag(s_t)` — per-trait variances, no factors.
Equivalent to `latent` with K = 0; `specific` is implied (it IS all-specific).
"""
indep() = LatentCov(:indep, 0, true)

"""
    dep() -> LatentCov

A dependent (full, unstructured) component — a free p×p SPD covariance `ΛΛᵀ` with `Λ` the
full p×p (lower-triangular Cholesky) factor. Equivalent to `latent` at full rank K = p;
`specific` is moot (the full matrix already has every variance). `cov_nloadings` is
`p(p+1)/2`. Use only for small p (cost is O(p²) parameters).
"""
dep() = LatentCov(:dep, 0, false)

"""
    cov_nloadings(c::LatentCov, p) -> Int

Number of free reduced-rank loading parameters (lower-triangular `Λ` packing) the
component contributes for `p` traits: `rr_theta_len(p, K)` for `latent`, else 0.
"""
cov_nloadings(c::LatentCov, p::Integer) =
    c.kind === :latent ? rr_theta_len(p, c.K) :
    c.kind === :dep    ? rr_theta_len(p, p) : 0      # dep = full p×p lower-Cholesky

"""
    cov_nspecific(c::LatentCov, p) -> Int

Number of per-trait specific variances `s_t` the component estimates: `p` for `indep`
and for `latent` with `specific=true`; 0 otherwise (`dep` carries them in its full
parameterisation).
"""
function cov_nspecific(c::LatentCov, p::Integer)
    c.kind === :indep && return p
    c.kind === :latent && c.specific && return p
    return 0
end

"""
    trait_cov(c::LatentCov, Λ, s) -> AbstractMatrix

Realise the p×p trait covariance:
- `:latent` → `Λ Λᵀ` `+ Diagonal(s)` iff `c.specific` (else pure `Λ Λᵀ`);
- `:indep`  → `Diagonal(s)` (`Λ` ignored);
- `:dep`    → not yet (Phase 4).

`Λ` is p×K loadings; `s` the length-p specific variances (pass `s = zeros(p)` when the
component has none). AD-friendly — `eltype` of `Λ`/`s` is preserved.
"""
function trait_cov(c::LatentCov, Λ::AbstractMatrix, s::AbstractVector)
    if c.kind === :latent
        Σ = Λ * Λ'
        if c.specific
            length(s) == size(Λ, 1) || throw(DimensionMismatch(
                "trait_cov: s has length $(length(s)); expected p = $(size(Λ, 1))"))
            Σ = Σ + Diagonal(s)
        end
        return Σ
    elseif c.kind === :indep
        return Matrix(Diagonal(s))
    else # :dep — full unstructured = full-rank ΛΛᵀ (Λ is the p×p Cholesky factor; s moot)
        size(Λ, 2) == size(Λ, 1) || throw(DimensionMismatch(
            "trait_cov(:dep): Λ must be the full p×p factor (got $(size(Λ))); dep is full-rank"))
        return Λ * Λ'
    end
end
