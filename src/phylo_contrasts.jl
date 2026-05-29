# Felsenstein's independent contrasts for Brownian-motion phylogenetic
# models. References:
#   Lande, R. (1979). Quantitative genetic analysis of multivariate
#       evolution, applied to brain:body size allometry. Evolution 33:402.
#   Felsenstein, J. (1985). Phylogenies and the comparative method.
#       Am Nat 125:1.
#   Lynch, M. (1991). Methods for the analysis of comparative data in
#       evolutionary biology. Evolution 45:1065.
#   Pagel, M. (1992). A method for the analysis of comparative data.
#       Syst Biol 41:243.
#
# For Brownian motion on a tree, the (p − 1)-dimensional contrast vector
# c has cov(c) = σ²_phy · diag(weights) — LITERALLY DIAGONAL. The
# contrast matrix U is the unique (p − 1) × p sparse linear map that
# achieves this. Concretely, at each internal node k with daughter
# clades L_k and R_k:
#
#   c_k = μ_L_k − μ_R_k
#   var(c_k) = σ²_phy · (t'_L_k + t'_R_k)
#
# where μ_L_k, μ_R_k are the inferred centroid values of the two daughter
# clades and t'_X is the "extended branch length" carrying subtree
# variance up to node k. The centroid and extended length are computed
# recursively (Felsenstein 1985 eq 1):
#
#   For a leaf v with branch length b_v to its parent:
#       μ_v = y_v,       t'_v = b_v
#   For an internal v with children L, R and own branch b_v:
#       μ_v = (μ_L t'_R + μ_R t'_L) / (t'_L + t'_R)
#       t'_v = b_v + (t'_L t'_R) / (t'_L + t'_R)
#
# Because μ_v is a linear combination of the leaves below v, the contrast
# c_k = μ_L_k − μ_R_k is also linear in the leaves: it picks up
# (+1, …) on left-clade leaves and (−1, …) on right-clade leaves with
# coefficients given by the recursive centroid weights. Stacking these
# row vectors gives U.
#
# AD-friendliness
# ---------------
# U and `weights` depend only on the tree topology and branch lengths,
# both fixed Float64 inputs in the typical workflow. Applying U to data
# is a sparse matrix multiplication; ForwardDiff.Dual element types pass
# through cleanly (Float64 × Dual → Dual). This is the crucial
# difference from the augmented-CHOLMOD sparse path
# (`likelihood_sparse_phy.jl`), which cannot be differentiated through.

using SparseArrays
using LinearAlgebra

"""
    FelsensteinContrasts

Pre-computed Felsenstein-contrast representation of a phylogenetic tree.

Fields
------
* `U::SparseMatrixCSC{Float64,Int}` – (p − 1) × p contrast matrix. Row k
  encodes one independent contrast at internal node k.
* `weights::Vector{Float64}`       – length (p − 1). Under Brownian
  motion with diffusion variance σ²_phy, `cov(U y)[k, k] = σ²_phy ·
  weights[k]` and off-diagonals are zero.
* `c_root::Vector{Float64}`        – length p. Centroid weights at the
  root: `c_root' y` is the BLUE of the root state under BM.
* `t_root::Float64`                – variance of the root centroid:
  `var(c_root' y) = σ²_phy · t_root`.
* `logabsdet_T::Float64`           – `log|det T|` where
  `T = [c_root'; U]` is the (p × p) full bijective transformation. Used
  in the contrast log-likelihood to convert back to the original-scale
  marginal log-density.
"""
struct FelsensteinContrasts
    U::SparseMatrixCSC{Float64,Int}
    weights::Vector{Float64}
    c_root::Vector{Float64}
    t_root::Float64
    logabsdet_T::Float64
end

"""
    felsenstein_contrast_matrix(tree::AugmentedPhy) -> (U, weights)

Build the (p − 1) × p Felsenstein contrast matrix U and the per-contrast
variance weights vector. `weights[k]` is the sum of extended branch
lengths into the two daughter clades meeting at internal node k.

Under Brownian motion with diffusion variance σ²_phy:
    cov(U * y) = σ²_phy · diag(weights)
i.e. literally diagonal — the maximally sparse positive-definite form.

The returned `U` has at most O(p) non-zeros per column (each leaf
appears in the contrasts of its ancestors only) and ~O(p log p) total
non-zeros for a balanced tree.

Use the higher-level `felsenstein_contrasts(tree)` if you also need the
root centroid `c_root`, `t_root`, and the determinant of the full
[c_root'; U] basis change (used inside the contrast log-likelihood).
"""
function felsenstein_contrast_matrix(tree)
    fc = felsenstein_contrasts(tree)
    return fc.U, fc.weights
end

function felsenstein_contrast_matrix(newick::AbstractString)
    return felsenstein_contrast_matrix(augmented_phy(newick))
end

"""
    felsenstein_contrasts(tree::AugmentedPhy) -> FelsensteinContrasts

Compute the full Felsenstein contrast structure: U, weights, root
centroid weights, root centroid variance, and `log|det T|` where
`T = [c_root'; U]`.

Walks the augmented tree in post-order, accumulating, for each node v:
* the row vector `μ_w[v, :]` (length p) of centroid weights — i.e.
  the linear combination of leaf values that equals the BLUE of the
  ancestral state at v under BM;
* the extended branch length `t'[v]` from v up to its parent.

At each internal node v with children L, R: emit the contrast row
`μ_w[L, :] − μ_w[R, :]` with weight `t'[L] + t'[R]`. The root itself
contributes (c_root, t_root) — the centroid at the root and the
"variance to root" (the harmonic-mean-style scalar).

`log|det T|` is computed from the recursion as a side-effect: under the
post-order construction it equals the sum over internal nodes v of
`log(t'[L_v] + t'[R_v]) − log(t'[L_v]) − log(t'[R_v])` — see the
implementation comment for the derivation.
"""
function felsenstein_contrasts(tree)
    p = tree.n_leaves
    n_total = tree.n_total

    p >= 2 || error("Felsenstein contrasts require ≥ 2 leaves; got p = $p")

    # Build undirected adjacency from Q_topology. The augmented sparse
    # precision has a -1/b entry at every parent-child pair (Q is
    # symmetric, so each edge appears twice). We do not know the
    # parent / child orientation from Q alone — that information comes
    # from the known root index via a DFS below.
    parent_of = fill(0, n_total)
    children = [Int[] for _ in 1:n_total]
    branch_to_parent = fill(0.0, n_total)

    rows = rowvals(tree.Q_topology)
    vals = nonzeros(tree.Q_topology)
    adj = [Tuple{Int,Float64}[] for _ in 1:n_total]
    for j in 1:n_total
        for idx in nzrange(tree.Q_topology, j)
            i = rows[idx]
            (i == j) && continue
            v = vals[idx]
            (v >= 0) && continue
            # Off-diagonal entry v = -1/b corresponds to a tree edge with
            # length b. Each undirected edge contributes two entries
            # (i,j) and (j,i); record once with i < j.
            (i < j) || continue
            b = -1.0 / v
            push!(adj[i], (j, b))
            push!(adj[j], (i, b))
        end
    end

    # Iterative DFS from the root: orients each edge, captures branch
    # length to parent, and builds a post-order traversal.
    visited = falses(n_total)
    root = tree.root_index
    visited[root] = true
    order_postvisit = Int[]
    work = Tuple{Int,Bool}[(root, false)]
    while !isempty(work)
        v, done = pop!(work)
        if done
            push!(order_postvisit, v)
            continue
        end
        push!(work, (v, true))
        for (nb, b) in adj[v]
            if !visited[nb]
                visited[nb] = true
                parent_of[nb] = v
                branch_to_parent[nb] = b
                push!(children[v], nb)
                push!(work, (nb, false))
            end
        end
    end
    # Sanity check: tree is connected.
    all(visited) || error("tree is disconnected; cannot build contrasts")

    # Verify binary topology: every internal node has 2 children; every
    # leaf has 0. (The Newick parser already guarantees this, but the
    # contrast recursion requires it.)
    for v in 1:n_total
        if isempty(children[v])
            # leaf
        else
            length(children[v]) == 2 ||
                error("contrast recursion requires a strictly bifurcating " *
                      "tree; node $v has $(length(children[v])) children")
        end
    end

    # Step 2: Felsenstein post-order recursion. For each node we
    # accumulate a SPARSE column representation of μ_w[v, :] (length-p
    # weight vector telling us the BLUE of v as a linear combination of
    # leaves) and the extended branch length t'_v.
    #
    # We avoid storing each μ_w[v, :] densely (would be O(p²)). Instead
    # we accumulate contrast rows into COO (I_U, J_U, V_U) directly.
    # Each leaf l in the subtree under v contributes to μ_w[v, l] with a
    # weight w_lv ∈ (0, 1]. We track for each node v the SET of
    # (leaf, weight) pairs that make up μ_w[v, :].
    mu_w = Vector{Dict{Int,Float64}}(undef, n_total)
    t_ext = fill(0.0, n_total)

    # Storage for U: COO with one row per internal node. We'll number
    # rows 1:(p-1) in the order we visit internal nodes during the
    # post-order. Root produces the LAST contrast row.
    n_contrasts = p - 1
    Ucol = Int[]
    Urow = Int[]
    Uval = Float64[]
    weights_out = Vector{Float64}(undef, n_contrasts)
    next_contrast_row = 0

    # log|det T| where T = [c_root'; U] (p × p). At each internal node v
    # the recursion replaces (μ_L, μ_R) with (μ_v, c_v) via
    #     μ_v = (μ_L t'_R + μ_R t'_L) / (t'_L + t'_R)
    #     c_v =  μ_L − μ_R
    # The 2 × 2 Jacobian is
    #     [ t'_R/(t'_L + t'_R)   t'_L/(t'_L + t'_R)
    #       1                   -1                  ]
    # with determinant −(t'_R + t'_L)/(t'_L + t'_R) = −1, hence |det| = 1
    # at every internal node. Composing the p − 1 internal-node steps
    # gives the full transformation T and |det T| = 1, so
    # log|det T| = 0 exactly. The contrast log-likelihood therefore has
    # no Jacobian correction term.
    logabsdet_T = 0.0

    # Initialise leaves.
    for l in 1:p
        leaf_node = tree.leaf_indices[l]
        mu_w[leaf_node] = Dict{Int,Float64}(l => 1.0)
        t_ext[leaf_node] = branch_to_parent[leaf_node]
    end

    # Post-order: process leaves, then internals (root last).
    for v in order_postvisit
        if !isempty(children[v])
            L, R = children[v][1], children[v][2]
            tL, tR = t_ext[L], t_ext[R]
            tsum = tL + tR
            tsum > 0 || error("zero-length subtree branches at node $v")

            # Emit contrast row for this internal node: c_v = μ_L − μ_R
            next_contrast_row += 1
            row = next_contrast_row
            weights_out[row] = tsum

            # Subtract: U[row, l] = μ_w[L, l] - μ_w[R, l].
            # μ_w stored as sparse Dicts.
            dL = mu_w[L]
            dR = mu_w[R]
            # Use the smaller dict to drive the iteration where possible.
            for (l, w) in dL
                push!(Urow, row); push!(Ucol, l); push!(Uval, w)
            end
            for (l, w) in dR
                push!(Urow, row); push!(Ucol, l); push!(Uval, -w)
            end
            # SparseArrays.sparse will sum duplicates when leaves appear
            # in both clades — but for a binary tree the clades are
            # disjoint by construction, so there are no duplicates.

            # Build μ_w[v] = (tR μ_w[L] + tL μ_w[R]) / tsum.
            mw = Dict{Int,Float64}()
            inv_tsum = 1.0 / tsum
            for (l, w) in dL
                mw[l] = tR * w * inv_tsum
            end
            for (l, w) in dR
                mw[l] = tL * w * inv_tsum
            end
            mu_w[v] = mw

            # Extended branch length at v: own branch + harmonic add.
            t_ext[v] = branch_to_parent[v] + (tL * tR) * inv_tsum
        end
    end

    next_contrast_row == n_contrasts ||
        error("internal indexing error: built $next_contrast_row contrasts," *
              " expected $n_contrasts")

    # Build U as a sparse matrix.
    U = sparse(Urow, Ucol, Uval, n_contrasts, p)

    # c_root and t_root: centroid weights at the root and the variance
    # scaling. (The root itself has no parent branch.)
    root_mu = mu_w[root]
    c_root = zeros(Float64, p)
    for (l, w) in root_mu
        c_root[l] = w
    end
    # Variance of root centroid: harmonic add of the two root children.
    Lr, Rr = children[root][1], children[root][2]
    tLr, tRr = t_ext[Lr], t_ext[Rr]
    t_root = (tLr * tRr) / (tLr + tRr)

    return FelsensteinContrasts(U, weights_out, c_root, t_root, logabsdet_T)
end

function felsenstein_contrasts(newick::AbstractString)
    return felsenstein_contrasts(augmented_phy(newick))
end

"""
    contrast_transform(y::AbstractMatrix, U::SparseMatrixCSC) -> Matrix

Apply the Felsenstein contrast transformation. `y` is the (p × n)
species-by-site data matrix; `U` is the (p − 1) × p sparse contrast
matrix from `felsenstein_contrast_matrix`. Returns the (p − 1) × n
contrast matrix `U * y`.

This is just `*` and is provided as an explicit named function only to
mirror the rest of the public API and to keep AD callers honest:
ForwardDiff.Dual element types in `y` pass through cleanly.
"""
contrast_transform(y::AbstractMatrix, U::SparseMatrixCSC) = U * y
