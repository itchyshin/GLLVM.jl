# Helpers for zero-constrained fixed-effect coefficients.
#
# Julia-side fitters see only the already-built design array X[p, n, q], not
# formula column names. The R bridge therefore translates named R-side
# Xcoef_fixed values into a positional mask before calling Julia.

function _fixed_zero_mask(fixed, q::Integer, label::AbstractString)
    q >= 0 || throw(ArgumentError("$label: q must be non-negative"))
    mask = falses(q)
    fixed === nothing && return mask

    if fixed isa AbstractVector{Bool}
        length(fixed) == q || throw(ArgumentError(
            "$label must have length q = $q; got $(length(fixed))"))
        mask .= fixed
        return mask
    elseif fixed isa AbstractVector{<:Integer}
        for raw in fixed
            i = Int(raw)
            1 <= i <= q || throw(ArgumentError(
                "$label index $i is outside 1:$q"))
            mask[i] = true
        end
        return mask
    elseif fixed isa AbstractVector{<:Real}
        vals = collect(fixed)
        if length(vals) == q && all(v -> v == 0 || v == 1, vals)
            mask .= vals .!= 0
            return mask
        elseif all(v -> isinteger(v), vals)
            for raw in vals
                i = Int(raw)
                1 <= i <= q || throw(ArgumentError(
                    "$label index $i is outside 1:$q"))
                mask[i] = true
            end
            return mask
        end
        throw(ArgumentError(
            "$label numeric vectors must be a 0/1 mask of length q or integer indices"))
    elseif fixed isa AbstractDict
        for (raw, value) in fixed
            i = raw isa Integer ? Int(raw) : parse(Int, String(raw))
            1 <= i <= q || throw(ArgumentError(
                "$label index $i is outside 1:$q"))
            value == 0 || value == 0.0 || throw(ArgumentError(
                "$label only supports zero constraints; index $i has value $value"))
            mask[i] = true
        end
        return mask
    else
        throw(ArgumentError(
            "$label must be nothing, a Bool vector of length q, an integer " *
            "index vector, or a Dict index=>0; got $(typeof(fixed))"))
    end
end

_free_coeff_indices(mask::AbstractVector{Bool}) = findall(!, mask)

function _slice_fixed_X(X::AbstractArray{<:Real, 3}, fixed_mask::AbstractVector{Bool})
    q = size(X, 3)
    length(fixed_mask) == q || throw(ArgumentError(
        "fixed mask length $(length(fixed_mask)) must equal size(X, 3) = $q"))
    free = _free_coeff_indices(fixed_mask)
    return Array{Float64,3}(X[:, :, free]), free
end

function _expand_fixed_zero(free_values::AbstractVector, fixed_mask::AbstractVector{Bool})
    free = _free_coeff_indices(fixed_mask)
    length(free_values) == length(free) || throw(ArgumentError(
        "free coefficient vector has length $(length(free_values)); expected $(length(free))"))
    T = eltype(free_values)
    out = zeros(T, length(fixed_mask))
    @inbounds for (j, i) in enumerate(free)
        out[i] = free_values[j]
    end
    return out
end

function _fixed_status(fixed_mask::AbstractVector{Bool})
    return [fixed ? "fixed" : "estimated" for fixed in fixed_mask]
end

function _pars_fixed_mask(pars::NamedTuple, key::Symbol, q::Integer)
    if haskey(pars, key)
        mask = collect(Bool, pars[key])
        length(mask) == q || throw(ArgumentError(
            "$key length ($(length(mask))) must equal coefficient length $q"))
        return mask
    end
    return falses(q)
end

function _fixed_init_free(init, fixed_mask::AbstractVector{Bool}, label::AbstractString)
    init === nothing && return nothing
    length(init) == length(fixed_mask) || throw(ArgumentError(
        "$label length ($(length(init))) must equal q = $(length(fixed_mask))"))
    free = _free_coeff_indices(fixed_mask)
    return collect(Float64, init[free])
end
