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
