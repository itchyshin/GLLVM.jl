# Internal fixed-parameter foundation for the first grouped Gaussian variance
# profile. This file intentionally contains no optimiser, LR, root, or public
# interface layer.

const _GROUPED_PROFILE_RANK_EPS = eps(Float64)

function _grouped_indep_profile_validate_terms(terms, incidences)
    length(terms) == length(incidences) && !isempty(terms) ||
        throw(ArgumentError("profile foundation needs one or more matched grouped terms and incidences"))
    all(term -> term isa GroupingTerm && term.mode === :indep && !term.common, terms) ||
        throw(ArgumentError("profile foundation supports only GroupingTerm(...; mode=:indep, common=false)"))
    names = getfield.(terms, :name)
    length(unique(names)) == length(names) ||
        throw(ArgumentError("profile foundation requires unique grouping term names"))
    n = size(first(incidences), 1)
    n > 0 || throw(ArgumentError("profile incidences need at least one observation"))
    for incidence in incidences
        incidence isa SparseMatrixCSC{Float64,Int} ||
            throw(ArgumentError("profile incidences must be SparseMatrixCSC{Float64,Int}"))
        size(incidence, 1) == n && size(incidence, 2) > 0 ||
            throw(DimensionMismatch("every profile incidence must have n rows and at least one level"))
        all(isfinite, incidence) || throw(ArgumentError("profile incidences must be finite"))
        row_count = zeros(Int, n)
        for column in axes(incidence, 2), pointer in nzrange(incidence, column)
            incidence.nzval[pointer] == 1.0 ||
                throw(ArgumentError("profile incidences must have only stored one-hot 1.0 entries"))
            row_count[incidence.rowval[pointer]] += 1
        end
        all(==(1), row_count) ||
            throw(ArgumentError("profile incidences must have exactly one stored 1.0 entry per row"))
    end
    unit_index = findfirst(==(:unit), names)
    unit_obs_index = findfirst(==(:unit_obs), names)
    if unit_index !== nothing && unit_obs_index !== nothing
        unit_codes = zeros(Int, n)
        unit_obs_codes = zeros(Int, n)
        for (codes, incidence) in ((unit_codes, incidences[unit_index]),
                (unit_obs_codes, incidences[unit_obs_index]))
            for column in axes(incidence, 2), pointer in nzrange(incidence, column)
                codes[incidence.rowval[pointer]] = column
            end
        end
        for observation_level in unique(unit_obs_codes)
            parents = unique(unit_codes[findall(==(observation_level), unit_obs_codes)])
            length(parents) == 1 ||
                throw(ArgumentError("unit_obs incidence must be globally nested within unit incidence"))
        end
    end
    return n
end

function _grouped_indep_profile_design_svd(D::AbstractMatrix)
    size(D, 2) > 0 || throw(ArgumentError("profile mean design must have at least one column"))
    all(isfinite, D) || throw(ArgumentError("profile mean design must be finite"))
    values = svdvals(Matrix{Float64}(D))
    sigma_max = isempty(values) ? 0.0 : maximum(values)
    threshold = max(size(D)...) * _GROUPED_PROFILE_RANK_EPS * sigma_max
    numerical_rank = count(value -> value > threshold, values)
    return (singular_values=values, threshold=threshold, dimensions=size(D),
        rank=numerical_rank)
end

"""
    _grouped_indep_variance_basis_gram(D, terms, incidences)

Return numerical diagnostics for the fixed independent-variance covariance
basis. The result is diagnostic rather than a selector: callers inspect its
design and covariance-basis ranks before constructing a reduced profile
objective. The rank gates are numerical and can reject an algebraically
identifiable but ill-conditioned design.
"""
function _grouped_indep_variance_basis_gram(D::AbstractMatrix, terms, incidences)
    n = _grouped_indep_profile_validate_terms(terms, incidences)
    rows = size(D, 1)
    rows % n == 0 || throw(DimensionMismatch("profile mean design rows must be divisible by incidence rows"))
    p = rows ÷ n
    p > 0 || throw(ArgumentError("profile mean design must imply at least one trait"))
    designSVD = _grouped_indep_profile_design_svd(D)
    dimension = length(terms) * p + 1
    gram = zeros(Float64, dimension, dimension)
    labels = String[]
    for term in terms, trait in 1:p
        push!(labels, "$(term.name).variance[$trait]")
    end
    push!(labels, "residual.variance")
    for right_source in eachindex(incidences), right_trait in 1:p,
            left_source in eachindex(incidences), left_trait in 1:p
        row = (left_source - 1) * p + left_trait
        column = (right_source - 1) * p + right_trait
        if left_trait == right_trait
            gram[row, column] = norm(incidences[left_source]' * incidences[right_source])^2
        end
    end
    for source in eachindex(incidences), trait in 1:p
        index = (source - 1) * p + trait
        gram[index, end] = norm(incidences[source])^2
        gram[end, index] = gram[index, end]
    end
    gram[end, end] = n * p
    diagonal = diag(gram)
    all(isfinite, diagonal) && all(>(0.0), diagonal) ||
        throw(ArgumentError("profile covariance basis has a non-positive diagonal norm"))
    normalizedGram = gram ./ sqrt.(diagonal * diagonal')
    normalizedGram = (normalizedGram + normalizedGram') ./ 2
    eigenvalues = eigvals(Symmetric(normalizedGram))
    scale = isempty(eigenvalues) ? 0.0 : maximum(abs, eigenvalues)
    threshold = dimension * _GROUPED_PROFILE_RANK_EPS * scale
    numerical_rank = count(value -> value > threshold, eigenvalues)
    invalid_negative = any(value -> value < -threshold, eigenvalues)
    condition_number = !invalid_negative && numerical_rank == dimension ?
        maximum(eigenvalues) / minimum(eigenvalues) : Inf
    return (gram=gram, normalizedGram=normalizedGram, diagonal=diagonal,
        eigenvalues=eigenvalues, threshold=threshold, rank=numerical_rank,
        condition_number=condition_number, condition=condition_number,
        labels=labels, designSVD=designSVD,
        valid=!invalid_negative && numerical_rank == dimension &&
            designSVD.rank == size(D, 2))
end

function _grouped_indep_profile_layout(data::AbstractMatrix, D::AbstractMatrix,
        terms, incidences, selected, fixed_variance, evaluator_placeholder)
    p, n = size(data)
    size(D, 1) == p * n || throw(DimensionMismatch("profile mean design rows must equal p*n"))
    all(size(incidence, 1) == n for incidence in incidences) ||
        throw(DimensionMismatch("profile incidence rows must equal size(data, 2)"))
    selected isa Tuple && length(selected) == 2 ||
        throw(ArgumentError("selected must be a (term_index, trait_index) tuple"))
    selected_term, selected_trait = selected
    selected_term isa Integer && selected_trait isa Integer ||
        throw(ArgumentError("selected term and trait indices must be integers"))
    1 <= selected_term <= length(terms) || throw(ArgumentError("selected term index is out of range"))
    1 <= selected_trait <= p || throw(ArgumentError("selected trait index is out of range"))
    fixed_variance isa Real && isfinite(fixed_variance) && fixed_variance >= 0 ||
        throw(ArgumentError("fixed_variance must be finite and non-negative on the natural scale"))
    evaluator_placeholder isa Real && isfinite(evaluator_placeholder) ||
        throw(ArgumentError("evaluator_placeholder must be finite"))
    natural_variance = try
        Float64(fixed_variance)
    catch err
        err isa InterruptException && rethrow()
        throw(ArgumentError("fixed_variance must be representable as finite Float64"))
    end
    placeholder = try
        Float64(evaluator_placeholder)
    catch err
        err isa InterruptException && rethrow()
        throw(ArgumentError("evaluator_placeholder must be representable as finite Float64"))
    end
    isfinite(natural_variance) && natural_variance >= 0 ||
        throw(ArgumentError("fixed_variance must be representable as finite non-negative Float64"))
    fixed_variance > 0 && iszero(natural_variance) &&
        throw(ArgumentError("positive fixed_variance underflows Float64; it is not an exact-zero boundary"))
    isfinite(placeholder) || throw(ArgumentError("evaluator_placeholder must be representable as finite Float64"))
    design = try
        Matrix{Float64}(D)
    catch err
        err isa InterruptException && rethrow()
        throw(ArgumentError("profile mean design must be representable as Float64"))
    end
    all(isfinite, design) || throw(ArgumentError("profile mean design must be representable as finite Float64"))
    termcopy = GroupingTerm[terms...]
    incidencecopy = copy.(incidences)
    diagnostics = _grouped_indep_variance_basis_gram(design, termcopy, incidencecopy)
    diagnostics.designSVD.rank == size(design, 2) ||
        throw(ArgumentError("profile mean design is numerically rank deficient"))
    diagnostics.valid || throw(ArgumentError("profile covariance basis is numerically rank deficient or invalid"))
    q = size(design, 2)
    source_coordinates = length(termcopy) * p
    selected_full_index = q + (selected_term - 1) * p + selected_trait
    full_length = q + source_coordinates + 1
    coefficient_names = Union{String,Symbol}["coefficient[$j]" for j in 1:q]
    packed_labels = _grouped_parameter_labels(coefficient_names, p, termcopy)
    return (p=p, n=n, q=q, selected_term=Int(selected_term),
        selected_trait=Int(selected_trait), fixed_variance=natural_variance,
        evaluator_placeholder=placeholder, D=design, terms=termcopy,
        incidences=incidencecopy,
        selected_full_index=selected_full_index, selected_label=packed_labels[selected_full_index],
        full_length=full_length, reduced_length=full_length - 1, diagnostics=diagnostics)
end

function _grouped_indep_profile_expand(layout, reduced)
    length(reduced) == layout.reduced_length || return nothing
    all(value -> value isa Real && isfinite(value), reduced) || return nothing
    full = Vector{Float64}(undef, layout.full_length)
    try
        full[1:(layout.selected_full_index - 1)] .= reduced[1:(layout.selected_full_index - 1)]
        full[layout.selected_full_index] = layout.evaluator_placeholder
        full[(layout.selected_full_index + 1):end] .= reduced[layout.selected_full_index:end]
    catch err
        err isa InterruptException && rethrow()
        return nothing
    end
    return all(isfinite, full) ? full : nothing
end

"""
    _grouped_indep_variance_profile_objective(data, D, terms, incidences;
        selected, fixed_variance, evaluator_placeholder=0.0)

Build a reduced fixed-natural-variance Gaussian objective for the first
all-`:indep`, `common=false` profile foundation. At `fixed_variance == 0`,
the selected covariance entry is overlaid exactly as zero; no `-Inf` reaches
the ordinary packed objective or generic grouped unpacker. This is an internal
fixed-parameter adapter only: it performs neither refitting nor root finding.
"""
function _grouped_indep_variance_profile_objective(data::AbstractMatrix,
        D::AbstractMatrix, terms, incidences; selected,
        fixed_variance::Real, evaluator_placeholder::Real=0.0)
    all(value -> value isa Real && isfinite(value), data) ||
        throw(ArgumentError("profile data must be finite and real"))
    numeric_data = Matrix{Float64}(data)
    all(isfinite, numeric_data) || throw(ArgumentError("profile data exceed finite Float64 range"))
    termvec = GroupingTerm[terms...]
    layout = _grouped_indep_profile_layout(numeric_data, D, termvec, incidences,
        selected, fixed_variance, evaluator_placeholder)
    zeros_mean = zeros(Float64, layout.p)
    function objective(reduced)
        full = _grouped_indep_profile_expand(layout, reduced)
        full === nothing && return _NLL_SENTINEL
        try
            gamma = view(full, 1:layout.q)
            source = view(full, layout.q + 1:layout.q + length(layout.terms) * layout.p)
            loads, uniques, _, used = _grouped_term_unpack(source, layout.p, layout.terms)
            used == length(source) || return _NLL_SENTINEL
            uniques[layout.selected_term][layout.selected_trait] = layout.fixed_variance
            sigma_eps = exp(full[end])
            adjusted = reshape(vec(numeric_data) - layout.D * gamma, layout.p, layout.n)
            value = _grouped_gaussian_factor_nll(adjusted, zeros_mean, layout.incidences,
                loads, sigma_eps; uniques=uniques)
            return isfinite(value) ? value : _NLL_SENTINEL
        catch err
            err isa InterruptException && rethrow()
            return _NLL_SENTINEL
        end
    end
    valid_reduced = reduced -> _grouped_indep_profile_expand(layout, reduced) !== nothing
    selected_covariance = reduced -> begin
        valid_reduced(reduced) || throw(ArgumentError("reduced profile vector must be finite and have the required length"))
        layout.fixed_variance
    end
    selected_coordinate = reduced -> begin
        valid_reduced(reduced) || throw(ArgumentError("reduced profile vector must be finite and have the required length"))
        iszero(layout.fixed_variance) ? missing : log(layout.fixed_variance) / 2
    end
    return (; objective, selected_covariance, selected_coordinate,
        selected_full_index=layout.selected_full_index, selected_label=layout.selected_label,
        reduced_length=layout.reduced_length, diagnostics=layout.diagnostics,
        fixed_variance=layout.fixed_variance)
end
