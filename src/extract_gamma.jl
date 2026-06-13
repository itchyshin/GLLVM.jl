# Cross-lineage coevolution estimand Γ (phase C2), Julia mirror of
# gllvmTMB::extract_Gamma (R/extract-sigma.R:1332-1386).
#
# Γ is the host × partner block of the shared phylo covariance Λ_phy Λ_phyᵀ.
# It is rotation-invariant (Λ_phy is identified only up to an orthogonal
# rotation, but Λ_phy Q (Λ_phy Q)ᵀ = Λ_phy Λ_phyᵀ), so the cross block is a
# well-defined coevolution summary.
#
# Orientation note: GLLVM.jl stores phylo loadings on the *stacked entity*
# index p (the rows of Y), correlation-structured by Σ_phy = K*. So
# `row_traits`/`col_traits` are POSITIONAL integer indices into the stacked
# two-lineage response — host block 1:n_H, partner block n_H+1:p, matching the
# host-first/partner-second ordering that `make_cross_kernel` enforces. This
# differs from the name-based trait subsetting in the R twin (Julia is
# positional), and it is the species-level-loading orientation of the GLLVM.jl
# Hadamard marginal `B = (Λ_phy Λ_phyᵀ) .* Σ_phy`, not R's trait⊗species
# Kronecker form.

"""
    extract_Gamma(fit::GllvmFit; row_traits, col_traits) -> Matrix{Float64}

Cross-lineage coevolution block `Γ = (Λ_phy Λ_phyᵀ)[row_traits, col_traits]`
from a Gaussian GLLVM fit that carries a phylo-latent tier (`K_phy > 0`) with a
cross kernel `Σ_phy = K*` (see `make_cross_kernel`). `row_traits` and
`col_traits` are integer index vectors into the stacked two-lineage entity set
(host first, partner second), e.g. `row_traits = 1:n_H`,
`col_traits = (n_H+1):(n_H+n_P)`.

`Γ` is rotation-invariant in the latent axes. Mirrors `gllvmTMB::extract_Gamma`
(which slices the same shared `Λ Λᵀ` block, name-indexed); the Julia API is
positional.

Throws if the fit has no phylo loadings (`Λ_phy === nothing`, i.e. `K_phy = 0`)
or if the indices fall outside `1:p`.
"""
function extract_Gamma(fit::GllvmFit; row_traits::AbstractVector{<:Integer},
                       col_traits::AbstractVector{<:Integer})
    L = (hasproperty(fit.pars, :Λ_phy) ? fit.pars.Λ_phy : nothing)
    L === nothing && throw(ArgumentError(
        "fit has no phylogenetic loadings (Λ_phy === nothing); refit with " *
        "K_phy > 0 and Σ_phy = K* before calling `extract_Gamma`."))
    Σ = L * transpose(L)
    p = size(Σ, 1)
    (all(i -> 1 <= i <= p, row_traits) && all(j -> 1 <= j <= p, col_traits)) ||
        throw(ArgumentError(
            "`row_traits` / `col_traits` must index 1:$p (the stacked " *
            "two-lineage entities, host first then partner)."))
    Matrix(Σ[row_traits, col_traits])
end
