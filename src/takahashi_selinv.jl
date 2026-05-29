# Takahashi selected inverse for sparse positive-definite matrices.
#
# WHY THIS FILE EXISTS
# --------------------
# `src/sparse_phy_grad.jl`'s analytic gradient and `src/em_phylo.jl`'s E-step
# both need entries of `Q⁻¹` for a SPARSE precision `Q`. Computed via dense
# linear algebra these cost O(p²) or O(p³); the Takahashi (1973) /
# Erisman–Tinney (1975) recursion gives the entries of `Q⁻¹` at the sparsity
# pattern of `L + Lᵀ` (the Cholesky factor's symmetric union) in `O(nnz(L))`
# operations. For a tree-structured precision the elimination tree has
# constant-bounded below-diagonal degree, so `nnz(L) = O(p)` and the selected
# inverse is genuinely linear.
#
# IMPORTANT CAVEAT (read before using)
# ------------------------------------
# The selected inverse is EXACT only at entries in the `L + Lᵀ` sparsity
# pattern. Entries of `Q⁻¹` outside that pattern are NOT zero in general and
# are NOT computed. In particular, on a tree precision `Q_cond`, the pattern
# of `L + Lᵀ` is the elimination tree (parent–child edges only) — leaf-to-leaf
# entries of `Q_cond⁻¹` (the dense covariance among leaves) are NOT in pattern.
# The phylo gradient's `Cleaf` and `Σ_phy_leaf` are dense p×p objects; those
# REMAIN O(p²) and the Takahashi swap cannot make them linear.
#
# Where Takahashi helps in this package:
# * `tr_Msad_DtDinvD` accumulator (`sparse_phy_grad.jl`): only same-leaf
#   axis-pair entries, all in the K_aug × K_aug dense leaf coupling, hence in
#   the `L + Lᵀ` pattern. O(K_aug²·p) entries → Takahashi delivers them in
#   `O(K_aug·p)`.
# * `diag(V_φ)` in the EM E-step (`em_phylo.jl`): exactly the diagonal of the
#   selected inverse — `O(p)` instead of `O(p³)`.
# * Identifying the leaf marginal variances anywhere else.
#
# Where Takahashi does NOT help:
# * Dense leaf-leaf blocks (`leaf_block_inv`, `_Cinv_leaf_block`, etc.). Those
#   cover entries outside the `L + Lᵀ` pattern and stay on the batched solve.
#
# THE MATH (column-oriented recursion)
# ------------------------------------
# Let `P Q Pᵀ = L Lᵀ` (Julia CHOLMOD convention: `Q[ch.p, ch.p] == L * Lᵀ`).
# We compute `Z = (P Q Pᵀ)⁻¹` at the symmetric `L + Lᵀ` pattern; `Q⁻¹` itself
# is then recovered by `Z[invperm(ch.p), invperm(ch.p)]` (or equivalently
# `Pᵀ Z P`). The recursion comes from `Lᵀ Z = L⁻¹`. With `(L⁻¹)[r, c] = 0`
# for `r < c` and `= 1 / L[c, c]` for `r = c`, the row-`j` equation at column
# `r > j` gives
#
#   Σ_k L[k, j] · Z[k, r] = 0
#   ⟹ Z[j, r] = -1/L[j, j] · Σ_{k > j, L[k, j] ≠ 0} L[k, j] · Z[k, r]
#   (and by symmetry Z[r, j] = Z[j, r])
#
# and the diagonal
#
#   Z[j, j] = 1/L[j, j]² - 1/L[j, j] · Σ_{k > j, L[k, j] ≠ 0} L[k, j] · Z[k, j].
#
# IMPLEMENTATION
# --------------
# We process columns from `j = n` down to `j = 1`. Within column `j`, we
# walk its `L`-pattern rows from highest down to `r = j`. For each
# off-diagonal `(r, j)` we need `Z[k, r]` for every `k > j` in column `j` of
# `L`. By the Cholesky closure of the sparsity pattern, every such `k` lies
# in the `L`-pattern of either column `r` (if `k > r`) or column `k` (if
# `r > k`), AND `r` lies in the pattern in the symmetric direction — so the
# requested `Z[max(k,r), min(k,r)]` was computed in an earlier (larger-`j`)
# iteration. Lookup is by linear scan of the small destination column.
#
# Output: a `SparseMatrixCSC` storing `Q⁻¹` (in the ORIGINAL ordering, not
# permuted) at the union sparsity of `Pᵀ (L + Lᵀ) P`.

using SparseArrays
using LinearAlgebra

# Binary search for row `i` in column `j` of a CSC sparse matrix; returns
# the nzval index if found, -1 otherwise. The CSC invariant guarantees row
# indices in `rowval[colptr[j]:colptr[j+1]-1]` are SORTED INCREASING.
@inline function _csc_rowidx(colptr::Vector{Int}, rowval::Vector{Int},
                              j::Int, i::Int)
    lo = colptr[j]; hi = colptr[j + 1] - 1
    @inbounds while lo <= hi
        m = (lo + hi) >>> 1
        rm = rowval[m]
        if rm == i
            return m
        elseif rm < i
            lo = m + 1
        else
            hi = m - 1
        end
    end
    return -1
end

"""
    takahashi_selinv(ch::SparseArrays.CHOLMOD.Factor) -> SparseMatrixCSC

Compute the Takahashi selected inverse of the matrix `Q` whose sparse
Cholesky factor is `ch` (`P · Q · Pᵀ = L · Lᵀ` with `P = I[ch.p, :]`).
Returns a `SparseMatrixCSC` holding `Q⁻¹` (in the ORIGINAL un-permuted
ordering) at the union sparsity of `Pᵀ (L + Lᵀ) P`. Entries outside that
pattern are NOT computed (and are NOT zero in general).

Cost: `O(nnz(L))` arithmetic + O(nnz(L)·log(max_col_nnz)) for the symmetric
lookups (with constant `max_col_nnz` on a tree this is `O(nnz(L))` overall).
"""
function takahashi_selinv(ch::SparseArrays.CHOLMOD.Factor{Float64})
    L = sparse(ch.L)                         # n × n lower triangular
    perm = ch.p                              # Q[perm, perm] == L * Lᵀ
    n = size(L, 1)
    colptr = L.colptr
    rowval = L.rowval
    Lvals  = L.nzval

    # Z is stored in the SAME CSC pattern as L (lower triangle of the
    # symmetric selected inverse, in the PERMUTED basis). We mirror to the
    # un-permuted full symmetric output at the end.
    Zvals = zeros(Float64, length(Lvals))

    @inbounds for j in n:-1:1
        cs = colptr[j]; ce = colptr[j + 1] - 1
        # rowval[cs] = j (diagonal); rowval[cs+1..ce] are i > j (sorted asc)
        Ljj = Lvals[cs]
        invLjj = 1.0 / Ljj

        # OFF-DIAGONAL entries Z[r, j] for r in rowval[cs+1..ce], processed
        # from HIGHEST r down to lowest. For each, the recursion sums over
        # k = rowval[cs+1..ce] (every below-diag row of column j of L).
        # Z[r, j] = -1/L[j,j] · Σ_k L[k, j] · Z_sym[k, r].
        for off_r in ce:-1:(cs + 1)
            r = rowval[off_r]
            s = 0.0
            for off_k in (cs + 1):ce
                k = rowval[off_k]
                Lkj = Lvals[off_k]
                # Z_sym[k, r] = Z[max(k, r), min(k, r)] in lower-triangle CSC.
                # We need to look up in column min(k, r) for row max(k, r).
                if k == r
                    # Z[r, r] = diagonal — computed in column r's earlier
                    # iteration; stored at L.colptr[r].
                    z_kr = Zvals[colptr[r]]
                elseif k < r
                    # Z[r, k] : column k, row r. Computed in column k's
                    # earlier iteration (k > j, processed before column j).
                    idx = _csc_rowidx(colptr, rowval, k, r)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                else  # k > r
                    # Z[k, r] : column r, row k. Computed in column r's
                    # earlier iteration (r > j, processed before column j).
                    idx = _csc_rowidx(colptr, rowval, r, k)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                end
                s += Lkj * z_kr
            end
            Zvals[off_r] = -s * invLjj
        end

        # DIAGONAL entry Z[j, j] = 1/L[j,j]² - 1/L[j,j] · Σ L[k,j] · Z[k, j].
        # Z[k, j] for k > j are now in Zvals (just computed above).
        s = 0.0
        for off_k in (cs + 1):ce
            Lkj = Lvals[off_k]
            Z_kj = Zvals[off_k]
            s += Lkj * Z_kj
        end
        Zvals[cs] = invLjj * invLjj - s * invLjj
    end

    # Build the un-permuted symmetric sparse output. Z stored at L's
    # (lower) pattern in the PERMUTED basis maps via `perm`:
    #   (Q⁻¹)[perm[r], perm[c]] = Zvals[stored at (r, c) of L].
    # Mirror to the upper triangle for the symmetric result.
    nnz_out = 2 * length(Lvals) - n          # diag once, off-diag mirrored
    I_out = Vector{Int}(undef, nnz_out)
    J_out = Vector{Int}(undef, nnz_out)
    V_out = Vector{Float64}(undef, nnz_out)
    idx = 0
    @inbounds for j in 1:n
        cs = colptr[j]; ce = colptr[j + 1] - 1
        # diagonal
        idx += 1
        I_out[idx] = perm[j]; J_out[idx] = perm[j]; V_out[idx] = Zvals[cs]
        for off in (cs + 1):ce
            r = rowval[off]
            v = Zvals[off]
            idx += 1
            I_out[idx] = perm[r]; J_out[idx] = perm[j]; V_out[idx] = v
            idx += 1
            I_out[idx] = perm[j]; J_out[idx] = perm[r]; V_out[idx] = v
        end
    end
    return sparse(I_out, J_out, V_out, n, n)
end

"""
    takahashi_diag(ch::SparseArrays.CHOLMOD.Factor) -> Vector{Float64}

Convenience: return ONLY `diag(Q⁻¹)` (a length-n vector, in the ORIGINAL
ordering) via the Takahashi recursion. Same cost as `takahashi_selinv` but
without materialising the full sparse output (a small allocation win when
only the diagonal is needed, as in the EM E-step's per-trait variance).
"""
function takahashi_diag(ch::SparseArrays.CHOLMOD.Factor{Float64})
    L = sparse(ch.L)
    perm = ch.p
    n = size(L, 1)
    colptr = L.colptr
    rowval = L.rowval
    Lvals  = L.nzval

    Zvals = zeros(Float64, length(Lvals))

    @inbounds for j in n:-1:1
        cs = colptr[j]; ce = colptr[j + 1] - 1
        Ljj = Lvals[cs]
        invLjj = 1.0 / Ljj

        for off_r in ce:-1:(cs + 1)
            r = rowval[off_r]
            s = 0.0
            for off_k in (cs + 1):ce
                k = rowval[off_k]
                Lkj = Lvals[off_k]
                if k == r
                    z_kr = Zvals[colptr[r]]
                elseif k < r
                    idx = _csc_rowidx(colptr, rowval, k, r)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                else
                    idx = _csc_rowidx(colptr, rowval, r, k)
                    z_kr = idx == -1 ? 0.0 : Zvals[idx]
                end
                s += Lkj * z_kr
            end
            Zvals[off_r] = -s * invLjj
        end

        s = 0.0
        for off_k in (cs + 1):ce
            Lkj = Lvals[off_k]
            Z_kj = Zvals[off_k]
            s += Lkj * Z_kj
        end
        Zvals[cs] = invLjj * invLjj - s * invLjj
    end

    d = Vector{Float64}(undef, n)
    @inbounds for j in 1:n
        d[perm[j]] = Zvals[colptr[j]]
    end
    return d
end
