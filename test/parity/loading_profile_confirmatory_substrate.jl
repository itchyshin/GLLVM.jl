# Stage-0 substrate helpers for confirmatory Λ profiling (D3). Test-only —
# not part of the public GLLVM.jl API until Stage 1 + maintainer G0.

"""
    lambda_constraint_is_pinned(M_user, n_traits, K) -> BitMatrix

Match `gllvmTMB` `loading-profile.R`: user `NaN`/`missing` = free, numeric = pinned,
plus engine strict-upper-triangle pins for `i <= min(n_traits, K)` and `k > i`.
"""
function lambda_constraint_is_pinned(
    M_user::Union{Nothing,AbstractMatrix{<:Real}},
    n_traits::Int,
    K::Int,
)
    n_traits > 0 && K > 0 ||
        throw(ArgumentError("n_traits and K must be positive"))
    is_pinned = falses(n_traits, K)
    if M_user !== nothing
        size(M_user) == (n_traits, K) ||
            throw(ArgumentError("pin matrix must be $(n_traits)×$(K)"))
        for i in 1:n_traits, k in 1:K
            v = M_user[i, k]
            is_pinned[i, k] = !(v isa Real && isnan(v))
        end
    end
    for i in 1:min(n_traits, K), k in 1:K
        k > i && (is_pinned[i, k] = true)
    end
    return is_pinned
end

"""
    normalize_lambda_constraint_pin_matrix(M) -> Matrix{Float64}

Drop above-diagonal user entries in the first `min(p,K)` rows (R ignores them).
Free slots stay `NaN`; fixed slots keep their numeric value.
"""
function normalize_lambda_constraint_pin_matrix(M::AbstractMatrix{<:Real})
    p, K = size(M)
    out = Matrix{Float64}(undef, p, K)
    for i in 1:p, k in 1:K
        if i <= min(p, K) && k > i
            out[i, k] = NaN
        else
            v = M[i, k]
            out[i, k] = v isa Real && isnan(v) ? NaN : Float64(v)
        end
    end
    return out
end

"""
    enumerate_free_lambda_entries(M_user, n_traits, K; entries=nothing)

Return `Vector{Tuple{Int,Int}}` of `(trait, axis)` pairs R would profile.
If `entries` is provided, validate each pair is free and return it (order preserved).
"""
function enumerate_free_lambda_entries(
    M_user::Union{Nothing,AbstractMatrix{<:Real}},
    n_traits::Int,
    K::Int;
    entries::Union{Nothing,AbstractMatrix{<:Integer}} = nothing,
)
    is_pinned = lambda_constraint_is_pinned(M_user, n_traits, K)
    if entries === nothing
        free = Tuple{Int,Int}[]
        for i in 1:n_traits, k in 1:K
            !is_pinned[i, k] && push!(free, (i, k))
        end
        return free
    end
    size(entries, 2) >= 2 ||
        throw(ArgumentError("entries must have at least two columns (i, k)"))
    out = Tuple{Int,Int}[]
    for row in 1:size(entries, 1)
        i = Int(entries[row, 1])
        k = Int(entries[row, 2])
        (1 <= i <= n_traits && 1 <= k <= K) ||
            throw(ArgumentError("entry ($i, $k) out of range for $(n_traits)×$(K) Lambda"))
        is_pinned[i, k] &&
            throw(ArgumentError("entry ($i, $k) is pinned or structurally zero"))
        push!(out, (i, k))
    end
    return out
end

"""
    profile_refit_lambda_constraint(M_user, i, k, c) -> Matrix{Float64}

Build the pin matrix for one profile grid point: preserve other user pins, set `(i,k)` to `c`.
"""
function profile_refit_lambda_constraint(
    M_user::Union{Nothing,AbstractMatrix{<:Real}},
    n_traits::Int,
    K::Int,
    i::Integer,
    k::Integer,
    c::Real,
)
    M = if M_user === nothing
        fill(NaN, n_traits, K)
    else
        normalize_lambda_constraint_pin_matrix(M_user)
    end
    M[i, k] = Float64(c)
    return M
end
