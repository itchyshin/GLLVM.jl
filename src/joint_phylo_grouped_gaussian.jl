# Evaluation-only joint Gaussian kernel for canonical phylogenetic precision
# fields and ordinary independent grouped effects.

using LinearAlgebra
using SparseArrays

_joint_phylo_grouped_gate(ok::Bool, tag::AbstractString, message::AbstractString) =
    ok || throw(ArgumentError("GJL-GATE-JOINT-PHYLO-$(tag): $(message)"))

function _joint_phylo_grouped_phy_gate(phy::PrecisionPhy, species_id, n::Integer)
    _joint_phylo_grouped_gate(phy.n_aug >= phy.n_leaves, "DIM",
        "n_aug must be at least n_leaves")
    _joint_phylo_grouped_gate(size(phy.Q) == (phy.n_aug, phy.n_aug), "DIM",
        "Q dimensions disagree with n_aug")
    _joint_phylo_grouped_gate(isfinite(phy.scale) && phy.scale > 0, "SCALE",
        "scale must be positive and finite")
    _joint_phylo_grouped_gate(isfinite(phy.log_det), "LOGDET",
        "shipped log_det must be finite")
    _joint_phylo_grouped_gate(all(isfinite, nonzeros(phy.Q)), "NONFINITE",
        "Q entries must be finite")
    _joint_phylo_grouped_gate(length(phy.species_aug_id) == phy.n_leaves, "MAP",
        "species_aug_id length must equal n_leaves")
    _joint_phylo_grouped_gate(all(i -> 1 <= i <= phy.n_aug, phy.species_aug_id) &&
        length(unique(phy.species_aug_id)) == phy.n_leaves, "MAP",
        "species_aug_id must be unique valid augmented-node indices")
    _joint_phylo_grouped_gate(length(species_id) == n, "DIM",
        "species_id length must equal observations")
    _joint_phylo_grouped_gate(all(i -> 1 <= i <= phy.n_leaves, species_id), "MAP",
        "species_id must index observed species")
    return nothing
end

function _joint_phylo_grouped_phy_design(n::Integer, p::Integer, phy::PrecisionPhy,
        species_id::AbstractVector{<:Integer}, factor::AbstractMatrix{<:Real})
    n_fields = size(factor, 2)
    row = Int[]; col = Int[]; value = Float64[]
    sizehint!(row, n * p * n_fields)
    sizehint!(col, n * p * n_fields)
    sizehint!(value, n * p * n_fields)
    mapped_nodes = phy.species_aug_id[species_id]
    @inbounds for field in 1:n_fields, observation in 1:n, trait in 1:p
        coefficient = Float64(factor[trait, field])
        coefficient == 0.0 && continue
        push!(row, (observation - 1) * p + trait)
        push!(col, (field - 1) * phy.n_aug + mapped_nodes[observation])
        push!(value, coefficient)
    end
    return sparse(row, col, value, n * p, n_fields * phy.n_aug)
end

function _joint_phylo_grouped_prior(phy::PrecisionPhy, n_fields::Integer,
        grouped_dimension::Integer)
    phy_prior = kron(spdiagm(0 => ones(Float64, n_fields)), phy.Q)
    grouped_dimension == 0 && return phy_prior
    group_prior = spdiagm(0 => ones(Float64, grouped_dimension))
    return [phy_prior spzeros(Float64, size(phy_prior, 1), grouped_dimension);
            spzeros(Float64, grouped_dimension, size(phy_prior, 2)) group_prior]
end

function _joint_phylo_grouped_ordinary_design(n::Integer, p::Integer,
        ordinary_incidences::AbstractVector, ordinary_trait_variances::AbstractVector)
    length(ordinary_incidences) == length(ordinary_trait_variances) ||
        throw(DimensionMismatch("ordinary incidences and trait variances require one entry per source"))
    designs = SparseMatrixCSC{Float64,Int}[]
    for source in eachindex(ordinary_incidences)
        incidence = ordinary_incidences[source]
        variance = ordinary_trait_variances[source]
        incidence isa AbstractMatrix || throw(ArgumentError(
            "GJL-GATE-JOINT-PHYLO-GROUP: ordinary incidence must be a matrix"))
        variance isa AbstractVector || throw(ArgumentError(
            "GJL-GATE-JOINT-PHYLO-GROUP: ordinary trait variance must be a vector"))
        size(incidence, 1) == n || throw(DimensionMismatch(
            "ordinary incidence rows must equal observations"))
        size(incidence, 2) > 0 || throw(DimensionMismatch(
            "ordinary incidence must have at least one group column"))
        length(variance) == p || throw(DimensionMismatch(
            "ordinary trait variances must have one entry per trait"))
        incidence64 = try
            sparse(Float64.(incidence))
        catch
            throw(ArgumentError("GJL-GATE-JOINT-PHYLO-GROUP: ordinary incidence must convert to Float64"))
        end
        variance64 = try
            Vector{Float64}(variance)
        catch
            throw(ArgumentError("GJL-GATE-JOINT-PHYLO-GROUP: ordinary trait variances must convert to Float64"))
        end
        all(isfinite, incidence64) || throw(ArgumentError(
            "GJL-GATE-JOINT-PHYLO-GROUP: Float64 ordinary incidence must be finite"))
        all(isfinite, variance64) && all(>(0), variance64) || throw(ArgumentError(
            "GJL-GATE-JOINT-PHYLO-GROUP: Float64 ordinary trait variances must be positive and finite"))
        factor = Matrix(Diagonal(sqrt.(variance64)))
        push!(designs, grouped_trait_design(incidence64, factor))
    end
    return designs
end

"""
    joint_phylo_grouped_gaussian_loglik(residualizedY, phy, L, psi;
        phylo_unique_variance=nothing, species_id=collect(1:phy.n_leaves),
        ordinary_incidences=SparseMatrixCSC{Float64,Int}[],
        ordinary_trait_variances=Vector{Float64}[])

Evaluate the exact Gaussian log likelihood for a fixed `p x n` residualized
response with jointly integrated canonical phylogenetic fields and ordinary
independent grouped effects. `L` is `p x rank`; positive entries of optional
`phylo_unique_variance` add phylogenetic fields sharing `phy.Q`; each ordinary
source supplies its `n x groups` incidence and a positive, trait-specific
variance vector. The kernel builds one sparse posterior precision
`P + A'R^-1A`, where `P = blockdiag(I_fields kron phy.Q, I_group)`.

`phy.Q` already carries its admitted scale, so this routine uses
`n_fields * phy.log_det` exactly once and never rescales it. It is evaluation
only: it does not estimate parameters, diagnose covariance-basis aliasing for
fitting, construct BLUPs, or establish an inference/coverage claim. Fixed
parameter covariance remains evaluable even when a future fitted
parameterisation would be aliased.
"""
function joint_phylo_grouped_gaussian_loglik(residualizedY::AbstractMatrix,
        phy::PrecisionPhy, L::AbstractMatrix, psi::AbstractVector;
        phylo_unique_variance::Union{Nothing,AbstractVector} = nothing,
        species_id::AbstractVector{<:Integer} = collect(1:phy.n_leaves),
        ordinary_incidences::AbstractVector = SparseMatrixCSC{Float64,Int}[],
        ordinary_trait_variances::AbstractVector = Vector{Float64}[])
    p, n = size(residualizedY)
    _joint_phylo_grouped_gate(p > 0 && n > 0, "DIM",
        "residualizedY must have positive trait and observation dimensions")
    size(L, 1) == p || throw(DimensionMismatch("L rows must equal response traits"))
    rank = size(L, 2)
    _joint_phylo_grouped_gate(rank > 0, "RANK", "L must contain at least one field")
    length(psi) == p || throw(DimensionMismatch("psi length must equal response traits"))
    y64 = try
        Matrix{Float64}(residualizedY)
    catch
        throw(ArgumentError("GJL-GATE-JOINT-PHYLO-NONFINITE: residualizedY must convert to Float64"))
    end
    L64 = try
        Matrix{Float64}(L)
    catch
        throw(ArgumentError("GJL-GATE-JOINT-PHYLO-NONFINITE: L must convert to Float64"))
    end
    psi64 = try
        Vector{Float64}(psi)
    catch
        throw(ArgumentError("GJL-GATE-JOINT-PHYLO-RESIDUAL: psi must convert to Float64"))
    end
    _joint_phylo_grouped_gate(all(isfinite, y64) && all(isfinite, L64), "NONFINITE",
        "Float64 residualizedY and L must be finite")
    _joint_phylo_grouped_gate(all(isfinite, psi64) && all(>(0), psi64), "RESIDUAL",
        "Float64 psi must be positive and finite")
    _joint_phylo_grouped_phy_gate(phy, species_id, n)

    unique = if phylo_unique_variance === nothing
        zeros(Float64, p)
    else
        try
            Vector{Float64}(phylo_unique_variance)
        catch
            throw(ArgumentError("GJL-GATE-JOINT-PHYLO-UNIQUE: phylo_unique_variance must convert to Float64"))
        end
    end
    length(unique) == p || throw(DimensionMismatch(
        "phylo_unique_variance length must equal response traits"))
    _joint_phylo_grouped_gate(all(isfinite, unique) && all(>=(0), unique), "UNIQUE",
        "phylo_unique_variance must be nonnegative and finite")
    active_unique = findall(>(0), unique)
    n_fields = rank + length(active_unique)

    # Field-major and node-within-field columns map directly into vec(Y), whose
    # rows are observation-major and trait-within-observation. No dense
    # commutation matrix or dense response covariance is materialised.
    factor = zeros(Float64, p, n_fields)
    factor[:, 1:rank] .= L64
    for (field_offset, trait) in enumerate(active_unique)
        factor[trait, rank + field_offset] = sqrt(unique[trait])
    end
    phy_design = _joint_phylo_grouped_phy_design(n, p, phy, species_id, factor)
    ordinary_designs = _joint_phylo_grouped_ordinary_design(n, p,
        ordinary_incidences, ordinary_trait_variances)
    A = isempty(ordinary_designs) ? phy_design : sparse(hcat(phy_design, ordinary_designs...))
    grouped_dimension = sum(design -> size(design, 2), ordinary_designs; init = 0)
    P = _joint_phylo_grouped_prior(phy, n_fields, grouped_dimension)

    Rinv = spdiagm(0 => repeat(1.0 ./ psi64, n))
    joint_precision = P + A' * Rinv * A
    joint_chol = try
        cholesky(Symmetric(joint_precision))
    catch error
        error isa InterruptException && rethrow()
        throw(ArgumentError("GJL-GATE-JOINT-PHYLO-PRECISION: joint precision must be positive definite"))
    end
    y = vec(y64)
    score = A' * (Rinv * y)
    posterior_mode = joint_chol \ score
    posterior_residual = y - A * posterior_mode
    integrated_quadratic = dot(posterior_mode, P * posterior_mode) +
        dot(posterior_residual, Rinv * posterior_residual)
    logdet_prior = n_fields * phy.log_det
    normalizer = n * p * log(2π) + n * sum(log, psi64)
    loglik = -0.5 * (normalizer - logdet_prior + logdet(joint_chol) + integrated_quadratic)
    isfinite(loglik) || throw(ArgumentError(
        "GJL-GATE-JOINT-PHYLO-NONFINITE: joint Gaussian log likelihood is not finite"))
    return loglik
end
