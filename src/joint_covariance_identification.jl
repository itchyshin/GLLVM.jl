# Fixed-parameter covariance-component identification for the joint
# phylogenetic-plus-ordinary Gaussian kernel. This is diagnostic only: it does
# not change the well-defined marginal likelihood at a supplied parameter.

function _jci_invalid(labels; zero_tangent_labels=String[],
        nonfinite_tangent_labels=String[], message="invalid covariance tangent")
    return (reason=:invalid, valid=false, rank=0, labels=labels,
        aliases=NamedTuple[], null_directions=zeros(Float64, length(labels), 0),
        eigenvalues=Float64[], threshold=NaN, condition_number=Inf,
        zero_tangent_labels=zero_tangent_labels,
        nonfinite_tangent_labels=nonfinite_tangent_labels, message=message)
end

function _jci_precision_factor(phy::PrecisionPhy)
    all(isfinite, phy.Q.nzval) || return nothing
    try
        return cholesky(Symmetric(phy.Q))
    catch error
        error isa InterruptException && rethrow()
        (error isa PosDefException || error isa ArgumentError) || rethrow()
        return nothing
    end
end

function _jci_trace_phylo_kernel(factor, mapped::Vector{Int}, n_aug::Int)
    rhs = zeros(Float64, n_aug)
    value = 0.0
    for node in mapped
        rhs[node] = 1.0
        solved = factor \ rhs
        value += solved[node]
        rhs[node] = 0.0
    end
    return value
end

function _jci_phylo_kernel_frobenius2(factor, mapped::Vector{Int}, n_aug::Int)
    # Column-wise solves retain O(n_aug) work storage. Repeated observations at
    # one tip intentionally repeat both the solve contribution and the selected
    # entries, exactly as S*Q^{-1}*S' requires.
    rhs = zeros(Float64, n_aug)
    value = 0.0
    for node in mapped
        rhs[node] = 1.0
        solved = factor \ rhs
        for selected in mapped
            value += abs2(solved[selected])
        end
        rhs[node] = 0.0
    end
    return value
end

function _jci_phylo_kernel_cross_incidence(factor, mapped::Vector{Int},
        incidence::SparseMatrixCSC{Float64,Int}, n_aug::Int)
    rhs = zeros(Float64, n_aug)
    value = 0.0
    for level in axes(incidence, 2)
        for pointer in nzrange(incidence, level)
            rhs[mapped[incidence.rowval[pointer]]] += incidence.nzval[pointer]
        end
        solved = factor \ rhs
        value += dot(rhs, solved)
        for pointer in nzrange(incidence, level)
            rhs[mapped[incidence.rowval[pointer]]] -= incidence.nzval[pointer]
        end
    end
    return value
end

function _jci_validate_inputs(phy::PrecisionPhy, species_id, terms, incidences,
        loading::AbstractMatrix, phylo_unique_variance)
    p, rank = size(loading)
    p > 0 && 1 <= rank <= p || throw(ArgumentError("loading must have p >= rank >= 1"))
    n = length(species_id)
    n > 0 || throw(ArgumentError("species_id must be nonempty"))
    species_id isa AbstractVector{<:Integer} || throw(ArgumentError(
        "species_id must be an integer vector"))
    mapped = collect(Int, phy.species_aug_id[species_id])
    length(terms) == length(incidences) || throw(DimensionMismatch(
        "one ordinary incidence is required per grouping term"))
    all(term -> term isa GroupingTerm && term.mode === :indep && !term.common, terms) ||
        throw(ArgumentError("joint covariance identification requires independent non-common terms"))
    names = getfield.(terms, :name)
    length(unique(names)) == length(names) || throw(ArgumentError(
        "joint covariance identification requires unique grouping term names"))
    for incidence in incidences
        incidence isa SparseMatrixCSC{Float64,Int} || throw(ArgumentError(
            "ordinary incidences must be SparseMatrixCSC{Float64,Int}"))
        size(incidence, 1) == n && size(incidence, 2) > 0 || throw(DimensionMismatch(
            "ordinary incidences must have one row per observation and a positive column count"))
        all(isfinite, incidence.nzval) || throw(ArgumentError("ordinary incidences must be finite"))
    end
    unique_variance = if phylo_unique_variance === nothing
        nothing
    else
        length(phylo_unique_variance) == p || throw(DimensionMismatch(
            "phylogenetic unique variance must have one value per trait"))
        collect(Float64, phylo_unique_variance)
    end
    return p, rank, n, mapped, unique_variance
end

function _jci_kind(left, right)
    kinds = (left.kind, right.kind)
    (:phylo in kinds && :ordinary in kinds) && return :phylo_vs_ordinary
    (:ordinary in kinds && :residual in kinds) && return :ordinary_vs_residual
    (left.kind === :ordinary && right.kind === :ordinary) && return :duplicate_ordinary
    (:phylo in kinds && :residual in kinds) && return :phylo_vs_residual
    return :within_component
end

"""
    _joint_covariance_identification(phy, species_id, terms, incidences, loading;
        phylo_unique_variance=nothing)

Diagnose local covariance-component aliases from the normalized Frobenius Gram
matrix of the *actual* joint-model covariance tangents. The result is a
fixed-parameter diagnostic only: `reason=:nonidentifiable` does not invalidate
the joint marginal likelihood, but means component interpretation/inference
must not claim separate identification.
"""
function _joint_covariance_identification(phy::PrecisionPhy, species_id,
        terms, incidences, loading::AbstractMatrix; phylo_unique_variance=nothing)
    p, rank, n, mapped, unique = _jci_validate_inputs(phy, species_id, terms,
        incidences, loading, phylo_unique_variance)
    factor = _jci_precision_factor(phy)
    factor === nothing && return _jci_invalid(String[]; message="phylogenetic precision is not finite positive definite")
    L = try
        Matrix{Float64}(loading)
    catch error
        error isa InterruptException && rethrow()
        return _jci_invalid(String[]; message="loading cannot convert to Float64")
    end
    kernel_identity = Float64(n)
    kernel_ordinary = [norm(left' * right)^2 for left in incidences, right in incidences]
    kernel_residual_ordinary = [norm(incidence)^2 for incidence in incidences]
    kernel_phylo = _jci_phylo_kernel_frobenius2(factor, mapped, phy.n_aug)
    kernel_phylo_residual = _jci_trace_phylo_kernel(factor, mapped, phy.n_aug)
    kernel_phylo_ordinary = [_jci_phylo_kernel_cross_incidence(factor, mapped,
        incidence, phy.n_aug) for incidence in incidences]
    all(isfinite, (kernel_phylo, kernel_phylo_residual)) && all(isfinite, kernel_phylo_ordinary) ||
        return _jci_invalid(String[]; message="phylogenetic kernel products are nonfinite")

    candidates = NamedTuple[]
    for column in 1:rank, row in column:p
        coordinate = row == column ? column : _lower_index(p, rank, row, column)
        dL = zeros(Float64, p, rank)
        dL[row, column] = 1.0
        push!(candidates, (label="phylo.loading[$coordinate]", kind=:phylo,
            source=0, trait=dL * L' + L * dL'))
    end
    if unique !== nothing
        for trait in 1:p
            derivative = zeros(Float64, p, p)
            derivative[trait, trait] = 2 * unique[trait]
            push!(candidates, (label="phylo.unique_variance[$trait]", kind=:phylo,
                source=0, trait=derivative))
        end
    end
    for source in eachindex(terms), trait in 1:p
        derivative = zeros(Float64, p, p)
        derivative[trait, trait] = 1.0
        push!(candidates, (label="$(terms[source].name).variance[$trait]", kind=:ordinary,
            source=source, trait=derivative))
    end
    for trait in 1:p
        derivative = zeros(Float64, p, p)
        derivative[trait, trait] = 1.0
        push!(candidates, (label="residual.variance[$trait]", kind=:residual,
            source=0, trait=derivative))
    end
    labels = String[candidate.label for candidate in candidates]
    dimension = length(candidates)
    observation_inner(left, right) = if left.kind === :phylo && right.kind === :phylo
        kernel_phylo
    elseif left.kind === :residual && right.kind === :residual
        kernel_identity
    elseif left.kind === :ordinary && right.kind === :ordinary
        kernel_ordinary[left.source, right.source]
    elseif left.kind === :phylo && right.kind === :ordinary
        kernel_phylo_ordinary[right.source]
    elseif left.kind === :ordinary && right.kind === :phylo
        kernel_phylo_ordinary[left.source]
    elseif left.kind === :phylo || right.kind === :phylo
        kernel_phylo_residual
    elseif left.kind === :ordinary
        kernel_residual_ordinary[left.source]
    else
        kernel_residual_ordinary[right.source]
    end
    diagonal = [observation_inner(candidate, candidate) * sum(abs2, candidate.trait)
        for candidate in candidates]
    zero = String[labels[index] for index in eachindex(labels) if diagonal[index] == 0.0]
    nonfinite = String[labels[index] for index in eachindex(labels) if !isfinite(diagonal[index])]
    isempty(zero) && isempty(nonfinite) || return _jci_invalid(labels;
        zero_tangent_labels=zero, nonfinite_tangent_labels=nonfinite,
        message="a covariance tangent has zero or nonfinite Frobenius norm")
    gram = zeros(Float64, dimension, dimension)
    for column in 1:dimension, row in 1:dimension
        gram[row, column] = observation_inner(candidates[row], candidates[column]) *
            dot(candidates[row].trait, candidates[column].trait)
    end
    normalized = gram ./ sqrt.(diagonal * diagonal')
    normalized = (normalized + normalized') ./ 2
    spectrum = eigen(Symmetric(normalized))
    scale = isempty(spectrum.values) ? 0.0 : maximum(abs, spectrum.values)
    threshold = dimension * _GROUPED_PROFILE_RANK_EPS * scale
    invalid_negative = any(value -> value < -threshold, spectrum.values)
    numerical_rank = count(value -> value > threshold, spectrum.values)
    aliases = NamedTuple[]
    alias_tolerance = 128 * eps(Float64)
    for column in 2:dimension, row in 1:(column - 1)
        abs(abs(normalized[row, column]) - 1.0) <= alias_tolerance || continue
        push!(aliases, (left=labels[row], right=labels[column],
            kind=_jci_kind(candidates[row], candidates[column]),
            correlation=normalized[row, column]))
    end
    null_indices = findall(value -> value <= threshold, spectrum.values)
    null_directions = isempty(null_indices) ? zeros(Float64, dimension, 0) :
        Matrix(spectrum.vectors[:, null_indices])
    reason = invalid_negative ? :invalid : numerical_rank == dimension ? :identified : :nonidentifiable
    condition = reason === :identified ? maximum(spectrum.values) / minimum(spectrum.values) : Inf
    return (reason=reason, valid=reason === :identified, rank=numerical_rank,
        labels=labels, aliases=aliases, null_directions=null_directions,
        eigenvalues=spectrum.values, threshold=threshold, condition_number=condition,
        zero_tangent_labels=String[], nonfinite_tangent_labels=String[],
        gram=gram, normalized_gram=normalized,
        message=reason === :identified ? "all actual covariance tangents are independent" :
            "at least one actual covariance tangent is aliased")
end
