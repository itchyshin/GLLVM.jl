# Random-effects blocks for GLLVM.jl (plan SP1).
#
# A random-effects (RE) block is a latent block U (nlevels × q) on a grouping
# factor, integrated out by the SAME marginal engines as the ordination latent
# variables. This file lays the SP1.0 FOUNDATION: the block descriptor, the
# variance-component packing (the ONLY parameters that enter the packed θ — the
# per-level coefficients/BLUPs are integrated out, exactly like the LV scores z),
# and the design/expansion helpers. The engine wiring (closed-form Σ_y + the dense
# Laplace marginal) is SP1.1.
#
# SCOPE (SP1.0): SITE-level RE blocks — a per-site grouping factor whose per-level
# coefficient contributes to η[t,i] for ALL traits t at site i (the gllvm "row
# effect" `(1|site)` and site-level random slopes `(x|site)`):
#
#     η[t,i] = β_t + (Λ z_i)_t + Z[i,:] · U[g(i), :]          (same RE term ∀ t)
#
# with U[ℓ, :] ~ N(0, Σ) iid across levels ℓ. For a random INTERCEPT, Z = ones
# (q = 1) and U is a per-level scalar. Trait-level random effects (per-trait random
# slopes / fourth-corner, b_t ~ N(0, Σ_b)) are a DIFFERENT block kind and arrive in
# a later slice — they contribute per trait, not shared across traits.
#
# Covariance structures: `:iid` (independent components ⇒ diagonal Σ from q log-SDs)
# in SP1.0; `:unstructured` (full q×q Σ via log-Cholesky) is reserved for correlated
# slopes (SP1.2) and is rejected here so the foundation stays honest.

"""
    REBlock

Descriptor for one SITE-level random-effects term. Fields:

- `label::Symbol` — the term's name (e.g. `:site`, `:region`).
- `grouping::Vector{Int}` — length `n` (one per site/column of `Y`); each entry is a
  level in `1:nlevels`.
- `nlevels::Int` — number of grouping levels `L`.
- `Z::Matrix{Float64}` — the `n × q` site design (`q = 1`, all-ones, for a random
  intercept; extra columns are site-level covariates for random slopes).
- `q::Int` — design width (`size(Z, 2)`).
- `cov::Symbol` — covariance of the per-level coefficients: `:iid` (q independent
  variances) in SP1.0.

The per-level coefficient array `U` is `nlevels × q`, with `U[ℓ, :] ~ N(0, Σ)` iid
across levels; its η-contribution at site `i` is `Z[i, :] · U[grouping[i], :]`,
added to every trait (see [`re_expand`](@ref)).
"""
struct REBlock
    label::Symbol
    grouping::Vector{Int}
    nlevels::Int
    Z::Matrix{Float64}
    q::Int
    cov::Symbol
end

# Map an arbitrary grouping column (any element type) to integer codes 1:L, returning
# (codes, levels) where levels[codes[i]] == values[i]. Stable order of first
# appearance, so the coding is deterministic and reproducible.
function _code_grouping(values::AbstractVector)
    levels = Vector{eltype(values)}()
    index = Dict{eltype(values), Int}()
    codes = Vector{Int}(undef, length(values))
    @inbounds for (i, v) in enumerate(values)
        c = get(index, v, 0)
        if c == 0
            push!(levels, v)
            c = length(levels)
            index[v] = c
        end
        codes[i] = c
    end
    return codes, levels
end

"""
    re_intercept(label, grouping) -> REBlock

Build a random-INTERCEPT block (`q = 1`, all-ones design) from a `grouping` column.
`grouping` may be integer codes (`1:L`) or any categorical vector (coded internally
via first-appearance order). The per-level scalar is shared across all traits.
"""
function re_intercept(label::Symbol, grouping::AbstractVector)
    codes, levels = grouping isa AbstractVector{<:Integer} && minimum(grouping) ≥ 1 ?
        (collect(Int, grouping), nothing) : _code_grouping(grouping)
    n = length(codes)
    L = isnothing(levels) ? maximum(codes) : length(levels)
    return REBlock(label, codes, L, ones(Float64, n, 1), 1, :iid)
end

"""
    re_block(label, grouping, Z; cov=:iid) -> REBlock

Build a general SITE-level RE block with an explicit `n × q` design `Z` (the first
column is conventionally all-ones for the intercept; further columns are site-level
covariates → random slopes). `grouping` is coded as in [`re_intercept`](@ref).
`cov = :iid` (independent components) is the only supported structure in SP1.0.
"""
function re_block(label::Symbol, grouping::AbstractVector, Z::AbstractMatrix; cov::Symbol = :iid)
    cov === :iid || throw(ArgumentError(
        "re_block: only cov=:iid is supported in SP1.0 (got :$cov); :unstructured is a later slice"))
    codes, levels = grouping isa AbstractVector{<:Integer} && minimum(grouping) ≥ 1 ?
        (collect(Int, grouping), nothing) : _code_grouping(grouping)
    n = length(codes)
    size(Z, 1) == n || throw(DimensionMismatch(
        "re_block: Z has $(size(Z,1)) rows; expected n = $n (one per site)"))
    L = isnothing(levels) ? maximum(codes) : length(levels)
    return REBlock(label, codes, L, Matrix{Float64}(Z), size(Z, 2), :iid)
end

# ---------------------------------------------------------------------------
# Variance-component packing. ONLY the variance components enter the packed θ
# (log scale); the per-level coefficients U are integrated out by the marginal.
# ---------------------------------------------------------------------------

"""
    re_nhyper(b::REBlock) -> Int

Number of variance-component parameters block `b` contributes to the packed θ.
For `:iid`, that is `q` independent log-SDs.
"""
re_nhyper(b::REBlock) = b.cov === :iid ? b.q :
    throw(ArgumentError("re_nhyper: unsupported cov :$(b.cov)"))

"""
    pack_re_hyper(b::REBlock, sds::AbstractVector) -> Vector

Pack the `q` component standard deviations `sds` to the log scale (the θ slice for
block `b`). Inverse of the SD half of [`unpack_re_cov`](@ref).
"""
function pack_re_hyper(b::REBlock, sds::AbstractVector)
    b.cov === :iid || throw(ArgumentError("pack_re_hyper: unsupported cov :$(b.cov)"))
    length(sds) == b.q || throw(DimensionMismatch(
        "pack_re_hyper: sds has length $(length(sds)); expected q = $(b.q)"))
    all(>(0), sds) || throw(ArgumentError("pack_re_hyper: standard deviations must be > 0"))
    return log.(float.(sds))
end

"""
    unpack_re_cov(b::REBlock, θslice::AbstractVector) -> Diagonal

Rebuild the `q × q` per-level covariance Σ from its θ slice. For `:iid`, the slice is
`q` log-SDs and Σ = Diagonal(exp.(2 .* θslice)). AD-friendly: `eltype(θslice)` is
preserved so ForwardDiff Duals flow through.
"""
function unpack_re_cov(b::REBlock, θslice::AbstractVector)
    b.cov === :iid || throw(ArgumentError("unpack_re_cov: unsupported cov :$(b.cov)"))
    length(θslice) == re_nhyper(b) || throw(DimensionMismatch(
        "unpack_re_cov: θslice has length $(length(θslice)); expected $(re_nhyper(b))"))
    return Diagonal(exp.(2 .* θslice))
end

# ---------------------------------------------------------------------------
# Design expansion: per-level coefficients U → per-site η-contribution.
# ---------------------------------------------------------------------------

"""
    re_expand(b::REBlock, U::AbstractMatrix) -> Vector

Given the per-level coefficient array `U` (`nlevels × q`), return the length-`n`
vector of per-site η-contributions `r` with `r[i] = Z[i, :] · U[grouping[i], :]`.
This contribution is added to η[t, i] for every trait `t`. AD-friendly.
"""
function re_expand(b::REBlock, U::AbstractMatrix)
    size(U) == (b.nlevels, b.q) || throw(DimensionMismatch(
        "re_expand: U is $(size(U)); expected (nlevels, q) = ($(b.nlevels), $(b.q))"))
    n = length(b.grouping)
    T = promote_type(eltype(b.Z), eltype(U))
    r = Vector{T}(undef, n)
    @inbounds for i in 1:n
        acc = zero(T)
        g = b.grouping[i]
        for k in 1:b.q
            acc += b.Z[i, k] * U[g, k]
        end
        r[i] = acc
    end
    return r
end
