# Exact multivariate Gaussian marginal from a canonical augmented phylogenetic
# precision.  This is deliberately a kernel only: no optimiser, parameter
# packing, bridge admission, or public fit route belongs here.

using LinearAlgebra
using SparseArrays

"""
    multivariate_phylo_precision_loglik(y, phy, loading, psi;
                                        sigma2_phy = 1.0,
                                        phylo_unique_variance = nothing,
                                        species_id = collect(1:phy.n_leaves))

Evaluate the exact zero-mean multivariate Gaussian log likelihood for a
low-rank phylogenetic trait factor, optional diagonal **phylogenetic** trait
variance, and a positive independent Gaussian observation residual.
`phy::PrecisionPhy` must be an already-admitted canonical sparse precision:
its `Q` already carries its recorded `scale`, which this function never
applies again.

`y` is the already residualized, zero-mean `n_obs x n_traits` response
matrix; this kernel does not fit or remove means. Repeated observations may
share an augmented phylogenetic factor row through the 1-based `species_id`
map. `loading` is `n_traits x rank`; `phylo_unique_variance`, when supplied,
is the nonnegative diagonal `U_phy` companion that shares the same augmented
precision; and `psi` contains strictly positive independent observation
residual variances. Each latent field has prior precision `phy.Q /
sigma2_phy`. Every augmented node, including unobserved ancestors, is
retained in the sparse precision and integrated out by the Cholesky solve.

This is an evaluation-only kernel.  It intentionally does not materialise a
dense `n_obs * n_traits` response covariance; the dense equivalent is used
only by the tiny independent test oracle.  It is not an optimiser route or a
claim of `phylo_rr` fit parity.
"""
function multivariate_phylo_precision_loglik(
        y::AbstractMatrix, phy::PrecisionPhy, loading::AbstractMatrix,
        psi::AbstractVector; sigma2_phy::Real = 1.0,
        phylo_unique_variance::Union{Nothing,AbstractVector} = nothing,
        species_id::AbstractVector{<:Integer} = collect(1:phy.n_leaves))
    n_obs, n_traits = size(y)
    n_traits > 0 || throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: y must have at least one trait"))
    size(loading, 1) == n_traits ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: loading rows must equal y columns"))
    rank = size(loading, 2)
    rank > 0 || throw(ArgumentError("GJL-GATE-PHYLO-MV-RANK: loading must have at least one factor"))
    length(psi) == n_traits ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: psi length must equal y columns"))
    length(species_id) == n_obs ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: species_id length must equal y rows"))
    phy.n_aug >= phy.n_leaves ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: n_aug must be at least n_leaves"))
    size(phy.Q) == (phy.n_aug, phy.n_aug) ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: Q dimensions disagree with n_aug"))
    isfinite(phy.scale) && phy.scale > 0 ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-SCALE: scale must be positive and finite"))
    isfinite(phy.log_det) ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-LOGDET: shipped log_det must be finite"))
    isfinite(sigma2_phy) && sigma2_phy > 0 ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-SIGMA2: sigma2_phy must be positive and finite"))
    all(isfinite, psi) && all(>(0), psi) ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-RESIDUAL: psi must be positive and finite"))
    all(isfinite, y) && all(isfinite, loading) ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-NONFINITE: y and loading must be finite"))
    phylo_unique_variance === nothing || length(phylo_unique_variance) == n_traits ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-DIM: phylo_unique_variance length must equal y columns"))
    phylo_unique_variance === nothing ||
        (all(isfinite, phylo_unique_variance) && all(>=(0), phylo_unique_variance)) ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-UNIQUE: phylo_unique_variance must be nonnegative and finite"))
    length(phy.species_aug_id) == phy.n_leaves ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-MAP: species_aug_id length must equal n_leaves"))
    all(i -> 1 <= i <= phy.n_aug, phy.species_aug_id) &&
        length(unique(phy.species_aug_id)) == phy.n_leaves ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-MAP: species_aug_id must be unique valid augmented-node indices"))
    all(i -> 1 <= i <= phy.n_leaves, species_id) ||
        throw(ArgumentError("GJL-GATE-PHYLO-MV-MAP: species_id must index observed species"))

    # Float64 is intentional: SparseArrays/CHOLMOD factorisation is this
    # kernel's numerical backend, so AD-compatible fitting remains outside
    # the scope of this first precision consumer.
    y64 = Matrix{Float64}(y)
    l64 = Matrix{Float64}(loading)
    psi64 = Vector{Float64}(psi)
    unique64 = phylo_unique_variance === nothing ? zeros(Float64, n_traits) :
        Vector{Float64}(phylo_unique_variance)
    sigma2 = Float64(sigma2_phy)
    n_aug = phy.n_aug

    # The R `phylo_diag` companion is a separate set of trait-specific
    # augmented fields. It shares Q with the low-rank fields and is therefore
    # not folded into the independent observation residual psi. Exactly-zero
    # U entries deliberately create no latent field: they have no likelihood
    # contribution and must not alter the stored-logdet multiplier.
    active_unique = findall(>(0), unique64)
    n_unique = length(active_unique)
    n_fields = rank + n_unique

    # P = I_fields kron (Q / sigma2). At a leaf with mapped node h, the
    # Gaussian observation adds F' Diagonal(psi)^-1 F to the h,h block,
    # with conceptual F = [loading Diagonal(sqrt(U_active))]. Assemble that
    # matrix in structured sparse blocks, not as a dense d x (rank + n_unique)
    # factor or a dense F' Diagonal(psi)^-1 F product.
    unit_fields = spdiagm(0 => ones(Float64, n_fields))
    prior_precision = kron(unit_fields, phy.Q / sigma2)
    lowrank_information = l64' * (l64 ./ reshape(psi64, :, 1))
    info_i = Int[]
    info_j = Int[]
    info_v = Float64[]
    sizehint!(info_i, rank * rank + 2 * rank * n_unique + n_unique)
    sizehint!(info_j, rank * rank + 2 * rank * n_unique + n_unique)
    sizehint!(info_v, rank * rank + 2 * rank * n_unique + n_unique)
    @inbounds for col in 1:rank, row in 1:rank
        value = lowrank_information[row, col]
        value == 0.0 && continue
        push!(info_i, row); push!(info_j, col); push!(info_v, value)
    end
    @inbounds for unique_field in 1:n_unique
        trait = active_unique[unique_field]
        field = rank + unique_field
        sqrt_unique = sqrt(unique64[trait])
        for lowrank_field in 1:rank
            value = sqrt_unique * l64[trait, lowrank_field] / psi64[trait]
            value == 0.0 && continue
            push!(info_i, field); push!(info_j, lowrank_field); push!(info_v, value)
            push!(info_i, lowrank_field); push!(info_j, field); push!(info_v, value)
        end
        push!(info_i, field); push!(info_j, field); push!(info_v, unique64[trait] / psi64[trait])
    end
    leaf_information = sparse(info_i, info_j, info_v, n_fields, n_fields)
    mapped_nodes = phy.species_aug_id[species_id]
    selector_diag = sparse(mapped_nodes, mapped_nodes, ones(Float64, n_obs),
                           n_aug, n_aug)
    joint_precision = prior_precision + kron(sparse(leaf_information), selector_diag)
    joint_chol = cholesky(Symmetric(joint_precision))

    # b = A' R^-1 vec(y), accumulated at each observed augmented node.  The
    # trait-major block layout agrees with vec(y)'s column-major ordering.
    b = zeros(Float64, n_fields * n_aug)
    @inbounds for obs in 1:n_obs
        weighted_y = view(y64, obs, :) ./ psi64
        node = mapped_nodes[obs]
        lowrank_score = l64' * weighted_y
        for factor in 1:rank
            b[(factor - 1) * n_aug + node] += lowrank_score[factor]
        end
        for unique_field in 1:n_unique
            trait = active_unique[unique_field]
            factor = rank + unique_field
            b[(factor - 1) * n_aug + node] += sqrt(unique64[trait]) * weighted_y[trait]
        end
    end

    logdet_prior = n_fields * (phy.log_det - n_aug * log(sigma2))
    logdet_joint = logdet(joint_chol)
    # Algebraically, y'R^-1y - b'J^-1b equals the posterior-mode residual
    # precision quadratic plus the mode's prior precision quadratic. The
    # latter form avoids catastrophic subtraction when psi is tiny relative
    # to a large phylogenetic signal.
    posterior_mode = joint_chol \ b
    integrated_quadratic = dot(posterior_mode, prior_precision * posterior_mode)
    @inbounds for obs in 1:n_obs
        node = mapped_nodes[obs]
        for trait in 1:n_traits
            fitted = 0.0
            for factor in 1:rank
                fitted += l64[trait, factor] * posterior_mode[(factor - 1) * n_aug + node]
            end
            for unique_field in 1:n_unique
                unique_trait = active_unique[unique_field]
                unique_trait == trait || continue
                factor = rank + unique_field
                fitted += sqrt(unique64[trait]) * posterior_mode[(factor - 1) * n_aug + node]
            end
            residual = y64[obs, trait] - fitted
            integrated_quadratic += residual^2 / psi64[trait]
        end
    end
    normalizer = n_obs * n_traits * log(2pi) + n_obs * sum(log, psi64)
    return -0.5 * (normalizer - logdet_prior + logdet_joint + integrated_quadratic)
end
