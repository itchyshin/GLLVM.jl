# Cross-objective identity check (panel 2026-09-01, highest-value upgrade).
#
# The decisive two-evaluation test: evaluating engine A's objective at engine
# B's fitted coordinates separates "same likelihood function" from "same argmax
# value". This tool provides the Julia half: evaluate GLLVM.jl's objective at a
# set of R-fitted coordinates supplied as invariant quantities (beta, loading
# crossproduct, dispersion), reconstructing a loading factor from the
# crossproduct — valid because every objective used here depends on Λ only
# through ΛΛᵀ (latent rotation invariance; rank-1 sign invariance).
#
# Known-answer gate (must pass before any real-data use): on the frozen
# COV-ORD-LATENT-BARE case, (a) the objective at Julia's own retained fitted
# coordinates reproduces Julia's retained loglik, and (b) the objective at the
# frozen R reference's retained coordinates reproduces R's retained loglik.
# (b) is the likelihood-function identity statement itself.
using GLLVM
using LinearAlgebra

"""
    loading_factor_from_crossprod(C, K)

Return a `p × K` factor `Λ` with `ΛΛᵀ ≈ C` (symmetric PSD `C` of rank ≤ K),
via the top-K eigenpairs. Any such factor is objective-equivalent under the
latent rotation invariance.
"""
function loading_factor_from_crossprod(C::AbstractMatrix{<:Real}, K::Integer)
    S = Symmetric(Matrix{Float64}(C))
    E = eigen(S)
    idx = sortperm(E.values; rev = true)[1:K]
    vals = max.(E.values[idx], 0.0)
    return E.vectors[:, idx] .* sqrt.(vals)'
end

"""
    gaussian_sources_nll_at(Y, source; beta, crossprod, residual_variance)

Evaluate the default-mean Gaussian latent-source negative log-likelihood at
externally supplied fitted quantities (rank taken from `source.rank`).
Returns the NLL (so `-nll` is the comparable log-likelihood).
"""
function gaussian_sources_nll_at(Y::AbstractMatrix{<:Real}, source;
        beta::AbstractVector{<:Real}, crossprod::AbstractMatrix{<:Real},
        residual_variance::Real)
    p, n = size(Y)
    snap = SourceCovariance(source.covariance, source.projection; name = source.name,
        mode = source.mode, rank = source.rank, unique = source.unique,
        common = source.common)
    ss = SourceCovariance[snap]
    S = [s.projection * s.covariance * s.projection' for s in ss]
    L = loading_factor_from_crossprod(crossprod, source.rank)
    theta = vcat(Float64.(beta), GLLVM.pack_lambda(L),
                 0.5 * log(Float64(residual_variance)))
    return GLLVM._gaussian_sources_nll(Matrix{Float64}(Y), ss, theta;
        projected = S, sigma_eps_fixed = nothing, X = nothing)
end

# ---------------------------------------------------------------------------
# Family-generic cross-objective identity (panel 2026-09-01 generalization).
#
# `gaussian_sources_nll_at` above is the first, hand-written instance of the
# pattern (one family, fixed calling convention). `cross_objective_at` below
# generalizes it across families so parity fixtures for OTHER families
# (Binomial, Poisson, ...) can run the same decisive two-evaluation check
# without hand-rolling a new evaluator each time. It deliberately reuses
# `gaussian_sources_nll_at` for `:gaussian_sources` rather than duplicating
# its Λ-reconstruction, so the two paths cannot silently diverge.
# ---------------------------------------------------------------------------

"""
    _loadings_from(crossprod_or_loadings, p, K) -> Matrix{Float64}

Resolve a `p × K` loading factor from either a `p × p` loading crossproduct
(`ΛΛᵀ`, factored via [`loading_factor_from_crossprod`](@ref)) or an
already-usable `p × K` loadings matrix, distinguished by shape. When
`p == K` the input is ambiguous by shape alone and is treated as a
crossprod (matching the convention `gaussian_sources_nll_at` already uses).
"""
function _loadings_from(M::AbstractMatrix{<:Real}, p::Integer, K::Integer)
    sz = size(M)
    if sz == (p, K) && p != K
        return Matrix{Float64}(M)
    elseif sz == (p, p)
        return loading_factor_from_crossprod(M, K)
    else
        throw(ArgumentError(
            "crossprod_or_loadings must be p×p (crossprod) or p×K (loadings); " *
            "got size $(sz) for p=$p, K=$K"))
    end
end

"""
    cross_objective_at(family_kind, Y; beta, crossprod_or_loadings, rank,
                        dispersion=nothing, N=nothing, link=nothing,
                        mask=nothing, offset=nothing, source=nothing) -> Float64

Family-generic cross-objective evaluator: evaluate `family_kind`'s
log-likelihood at externally supplied fitted coordinates (beta, loadings,
dispersion), so one engine's objective can be evaluated at another engine's
fitted coordinates — the decisive two-evaluation cross-objective identity
check (panel 2026-09-01): this separates "same likelihood function" from
"same argmax value". Returns the log-likelihood (sign already flipped from
any internal NLL/objective convention).

`family_kind` (a `Symbol`) selects the family:

  - `:gaussian_sources` — requires `source` (a `SourceCovariance`) and
    `dispersion` (residual variance); `crossprod_or_loadings` must be the
    `p × p` loading crossproduct `ΛΛᵀ` (delegates to
    [`gaussian_sources_nll_at`](@ref) unchanged).
  - `:binomial` — `crossprod_or_loadings` may be the `p × p` crossprod or a
    `p × rank` loadings matrix (see [`_loadings_from`](@ref)); `N` (p×n
    trial counts) defaults to all-ones (Bernoulli cells); `link` defaults to
    `LogitLink()`. Delegates to `GLLVM.binomial_marginal_loglik_laplace`.
  - `:poisson` — same loadings convention as `:binomial`; `link` defaults to
    `LogLink()`. Delegates to `GLLVM.poisson_marginal_loglik_laplace`.
"""
function cross_objective_at(family_kind::Symbol, Y::AbstractMatrix{<:Real};
        beta::AbstractVector{<:Real}, crossprod_or_loadings::AbstractMatrix{<:Real},
        rank::Integer, dispersion = nothing, N = nothing, link = nothing,
        mask = nothing, offset = nothing, source = nothing)
    β = Float64.(beta)
    if family_kind === :gaussian_sources
        source === nothing &&
            throw(ArgumentError("family_kind = :gaussian_sources requires `source`"))
        dispersion === nothing &&
            throw(ArgumentError("family_kind = :gaussian_sources requires `dispersion`"))
        return -gaussian_sources_nll_at(Y, source; beta = β,
            crossprod = crossprod_or_loadings, residual_variance = dispersion)
    elseif family_kind === :binomial
        p = size(Y, 1)
        Λ = _loadings_from(crossprod_or_loadings, p, rank)
        Nm = N === nothing ? ones(size(Y)) : Float64.(N)
        lnk = link === nothing ? GLLVM.LogitLink() : link
        return GLLVM.binomial_marginal_loglik_laplace(Float64.(Y), Nm, Λ, β, lnk;
            mask = mask, offset = offset)
    elseif family_kind === :poisson
        p = size(Y, 1)
        Λ = _loadings_from(crossprod_or_loadings, p, rank)
        lnk = link === nothing ? GLLVM.LogLink() : link
        return GLLVM.poisson_marginal_loglik_laplace(Float64.(Y), Λ, β, lnk;
            mask = mask, offset = offset)
    else
        throw(ArgumentError(
            "unsupported family_kind: $family_kind " *
            "(supported: :gaussian_sources, :binomial, :poisson)"))
    end
end
