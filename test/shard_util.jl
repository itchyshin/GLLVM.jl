# Pure-logic helpers for deterministic Julia-suite sharding
# (GLLVM_TEST_SHARD="k/N"). No package `using` needed — plain Base only.
# Included by runtests.jl, and standalone by test_shard_selection.jl.

"""
    _parse_shard_spec(spec::AbstractString) -> (k::Int, N::Int)

Parse a `"k/N"` shard spec (1-based `k` of `N` total shards). Throws
`ArgumentError` for a malformed spec, a non-positive `N`, or `k` outside
`1:N`.
"""
function _parse_shard_spec(spec::AbstractString)
    parts = split(spec, '/')
    length(parts) == 2 ||
        throw(ArgumentError("malformed GLLVM_TEST_SHARD spec $(repr(spec)); expected \"k/N\""))
    k = tryparse(Int, parts[1])
    N = tryparse(Int, parts[2])
    (k === nothing || N === nothing) &&
        throw(ArgumentError("malformed GLLVM_TEST_SHARD spec $(repr(spec)); k and N must be integers"))
    N >= 1 ||
        throw(ArgumentError("GLLVM_TEST_SHARD spec $(repr(spec)): N must be >= 1, got N=$N"))
    1 <= k <= N ||
        throw(ArgumentError("GLLVM_TEST_SHARD spec $(repr(spec)): k must satisfy 1 <= k <= N, got k=$k, N=$N"))
    return k, N
end

"""
    _shard_indices(n::Integer, k::Integer, N::Integer) -> Vector{Int}

1-based indices into `1:n` assigned to shard `k` of `N`, by
`(i - 1) % N == k - 1`. The `N` shards partition `1:n` exactly: every index
in `1:n` falls in exactly one shard's result.
"""
function _shard_indices(n::Integer, k::Integer, N::Integer)
    n >= 0 || throw(ArgumentError("n must be >= 0, got n=$n"))
    N >= 1 || throw(ArgumentError("N must be >= 1, got N=$N"))
    1 <= k <= N || throw(ArgumentError("k must satisfy 1 <= k <= N, got k=$k, N=$N"))
    return [i for i in 1:n if (i - 1) % N == k - 1]
end
