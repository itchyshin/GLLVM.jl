# Structured covariance builders for non-tree random effects.
#
# The Gaussian GLLVM marginal likelihood (likelihood.jl) accepts any p × p
# positive-definite species covariance Σ_phy via the keyword argument of the
# same name. The functions here build Σ_phy from coordinates (spatial) or a
# precomputed relatedness / genomic-relationship matrix (animal model); both
# produce a Symmetric{Float64, Matrix{Float64}} that can be passed directly
# to fit_gaussian_gllvm as Σ_phy.
#
# References:
#   - Cressie 1993 (spatial covariance functions)
#   - Stein 1999 (Matérn class; interpolation of spatial data)
#   - Henderson 1984; Lynch & Walsh 1998 (animal model / GRM)
#   - Hadfield & Nakagawa 2010 JEB appendix (the Σ_phy entry point in this pkg)

using LinearAlgebra
using SpecialFunctions: besselk

"""
    spatial_cov(coords::AbstractMatrix;
                kernel   = :exponential,
                range,
                smoothness = 1.5,
                sill   = 1.0,
                nugget = 1e-6) -> Symmetric{Float64, Matrix{Float64}}

Build a p × p positive-definite spatial covariance matrix from `coords`
(p × d, each row is one location in d-dimensional space).

Supported `kernel` values:

- `:exponential` — `sill * exp(−d / range)`. Equivalent to Matérn with ν = 0.5.
- `:gaussian`    — `sill * exp(−(d / range)²)`. Infinitely differentiable, often
  over-smooth in practice.
- `:matern`      — Matérn covariance with smoothness parameter `smoothness` (ν).
  Uses the standard form via `besselk` (SpecialFunctions.jl):
      C(d) = sill * 2^{1−ν} / Γ(ν) * (√2ν · d / range)^ν · K_ν(√2ν · d / range)
  For ν = 0.5 this reduces to the exponential kernel exactly (verified in tests).
  Common practical choices: ν = 0.5 (exponential), 1.5, 2.5, ∞ (→ Gaussian).

`nugget` is added to every diagonal entry to ensure strict positive-definiteness.

Returns a `Symmetric{Float64}` suitable for passing as `Σ_phy` to
`fit_gaussian_gllvm`.
"""
function spatial_cov(coords::AbstractMatrix;
                     kernel    = :exponential,
                     range::Real,
                     smoothness::Real = 1.5,
                     sill::Real       = 1.0,
                     nugget::Real     = 1e-6)
    p = size(coords, 1)
    range > 0 || throw(ArgumentError("range must be positive; got $range"))
    sill  > 0 || throw(ArgumentError("sill must be positive; got $sill"))
    nugget ≥ 0 || throw(ArgumentError("nugget must be non-negative; got $nugget"))

    C = Matrix{Float64}(undef, p, p)

    if kernel === :exponential
        @inbounds for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            C[i, j] = sill * exp(-d / range)
        end
    elseif kernel === :gaussian
        @inbounds for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            C[i, j] = sill * exp(-(d / range)^2)
        end
    elseif kernel === :matern
        ν = Float64(smoothness)
        ν > 0 || throw(ArgumentError("Matérn smoothness ν must be positive; got $ν"))
        @inbounds for j in 1:p, i in 1:p
            d = norm(coords[i, :] - coords[j, :])
            if d == 0.0
                C[i, j] = sill
            else
                x = sqrt(2ν) * d / range
                # Standard Matérn: C(d) = sill * 2^{1-ν}/Γ(ν) * x^ν * K_ν(x)
                C[i, j] = sill * (2.0^(1.0 - ν) / gamma(ν)) * x^ν * besselk(ν, x)
            end
        end
    else
        throw(ArgumentError(
            "Unknown kernel :$kernel. Supported: :exponential, :gaussian, :matern"))
    end

    # Add nugget to diagonal for SPD.
    @inbounds for i in 1:p
        C[i, i] += nugget
    end

    return Symmetric(C)
end

"""
    relatedness_cov(A::AbstractMatrix; jitter = 1e-6) -> Symmetric{Float64, Matrix{Float64}}

Validate and return a p × p relatedness / genomic-relationship matrix (GRM) as
a `Symmetric{Float64}` suitable for passing as `Σ_phy` to `fit_gaussian_gllvm`.

The animal model uses the same covariance structure as the phylogenetic GLLVM —
the only difference is that Σ_phy is a relatedness matrix rather than a
phylogenetic variance-covariance matrix. `A` must be a precomputed square,
(approximately) symmetric positive-semidefinite matrix. Typical sources:

- Pedigree-based numerator relationship matrix (NRM) from pedigree tools such
  as R packages `kinship2`, `nadiv`, or `MCMCglmm`.
- Genomic relationship matrix (GRM) from marker-based estimation (e.g.
  `rrBLUP::A.mat`, `AGHmatrix`, PLINK `--make-grm`).

This function does NOT parse a pedigree or compute a GRM from raw markers —
supply a precomputed matrix.

Steps applied:
1. Check square.
2. Symmetrize: `A_sym = (A + A') / 2`.
3. Add `jitter` to the diagonal for strict positive-definiteness (tolerates
   near-PSD GRMs that fail `cholesky` due to floating-point rounding).

A `jitter = 1e-6` is sufficient for typical NRM/GRM matrices whose diagonal
entries are ~1–2. Increase if `fit_gaussian_gllvm` reports a Cholesky failure.
"""
function relatedness_cov(A::AbstractMatrix; jitter::Real = 1e-6)
    m, n = size(A)
    m == n || throw(ArgumentError(
        "Relatedness matrix must be square; got $(m) × $(n)"))
    jitter ≥ 0 || throw(ArgumentError("jitter must be non-negative; got $jitter"))

    # Symmetrize to neutralise floating-point asymmetry from pedigree tools.
    A_sym = (A + A') ./ 2

    # Add jitter for strict PD.
    @inbounds for i in 1:m
        A_sym[i, i] += jitter
    end

    return Symmetric(A_sym)
end
