using GLLVM, Test, Random, LinearAlgebra, SparseArrays

# Takahashi (1973) / Erisman–Tinney (1975) selected inverse — gold-standard
# correctness gate vs the dense `inv(Q)` at the entries Takahashi computes.
#
# IMPORTANT: Takahashi computes `Q⁻¹` ONLY at the symmetric union sparsity of
# `L + Lᵀ`, where `L` is the sparse Cholesky factor of `Q`. Entries of
# `Q⁻¹` OUTSIDE that pattern are NOT computed and are NOT zero in general.
# The test therefore compares Takahashi against `inv(Q)` ONLY at entries in
# the selected pattern; out-of-pattern entries are excluded by construction.
#
# Test matrices: the tree-augmented precision `Q_cond` for trees of size
# p ∈ {50, 200, 500} (after adding a small ridge to render strictly PD —
# the bare `Q_topology` is rank-deficient by one, the constant-shift direction).
# Use the package-loaded implementations directly. Self-including the source
# file into Main creates duplicate-method warnings in the full suite.

const _rbt = GLLVM.random_balanced_tree

# Helper: build a strictly-PD tree precision (the bare Q_topology has a 1-D
# null space spanned by the constant vector — the Brownian root identifiability
# gap. The phylo likelihood code drops the root row/column for the same reason.
function tree_precision(p::Integer; ridge::Real = 0.01, branch_length::Real = 0.1)
    phy = _rbt(p; branch_length = branch_length)
    keep = filter(i -> i != phy.root_index, 1:phy.n_total)
    Q = phy.Q_topology[keep, keep] + ridge * I    # strictly PD
    return Q, phy
end

@testset "Takahashi selected inverse" begin

    @testset "agrees with dense inv at L+Lᵀ pattern, p=$(p)" for p in (50, 200, 500)
        Random.seed!(p)
        Q, _ = tree_precision(p)
        ch = cholesky(Symmetric(Q))
        Z = GLLVM.takahashi_selinv(ch)
        Qdense = Matrix(Q)
        Qinv = inv(Qdense)
        # Compare every NONZERO of Z (= every entry in the L+Lᵀ pattern,
        # mirrored to upper triangle) against the dense inverse.
        err_in_pattern = 0.0
        n = size(Z, 1)
        @inbounds for j in 1:n
            for off in Z.colptr[j]:Z.colptr[j + 1] - 1
                i = Z.rowval[off]
                d = abs(Z.nzval[off] - Qinv[i, j])
                err_in_pattern = max(err_in_pattern, d)
            end
        end
        @test err_in_pattern < 1e-10
        @info "p=$p Takahashi vs dense inv (in-pattern max abs err)" err = err_in_pattern
    end

    @testset "takahashi_diag matches diag(inv(Q)), p=$(p)" for p in (50, 200, 500)
        Random.seed!(p)
        Q, _ = tree_precision(p)
        ch = cholesky(Symmetric(Q))
        d_tak = GLLVM.takahashi_diag(ch)
        d_dense = diag(inv(Matrix(Q)))
        err = maximum(abs.(d_tak .- d_dense))
        @test err < 1e-10
        @info "p=$p takahashi_diag vs diag(inv)" err = err
    end

    @testset "matches dense inv on a non-tree PD matrix (sanity)" begin
        # Generic 4x4 PD matrix — perm chosen by CHOLMOD; Takahashi should
        # still match dense inv at every in-pattern entry to machine
        # precision (no tree-specific structure assumed by the recursion).
        A = [10.0 -1.0 0.0 0.0; -1.0 5.0 -2.0 0.0; 0.0 -2.0 4.0 -1.0; 0.0 0.0 -1.0 3.0]
        S = sparse(A)
        ch = cholesky(Symmetric(S))
        Z = GLLVM.takahashi_selinv(ch)
        Ainv = inv(A)
        err = 0.0
        for j in 1:4
            for off in Z.colptr[j]:Z.colptr[j + 1] - 1
                i = Z.rowval[off]
                err = max(err, abs(Z.nzval[off] - Ainv[i, j]))
            end
        end
        @test err < 1e-12
    end

    @testset "out-of-pattern entries are NOT computed (correctness disclosure)" begin
        # Tree-augmented Q has dense leaf-to-leaf entries of Q⁻¹ that are
        # NOT in the L+Lᵀ pattern. Takahashi correctly does not produce
        # those entries — `Z[i, j] == 0` outside the pattern (a missing
        # rather than a zero value), and the corresponding `inv(Q)[i, j]`
        # is non-zero in general. We assert this disclosure so a future
        # change (e.g. trying to extract such entries from Takahashi) is
        # caught — Takahashi alone does NOT give the dense leaf-leaf block.
        Random.seed!(50)
        Q, phy = tree_precision(50)
        ch = cholesky(Symmetric(Q))
        Z = GLLVM.takahashi_selinv(ch)
        Qinv = inv(Matrix(Q))
        # Find any out-of-pattern entry with substantial value:
        worst_out_of_pattern = 0.0
        n = size(Q, 1)
        @inbounds for j in 1:n, i in 1:n
            if Z[i, j] == 0
                worst_out_of_pattern = max(worst_out_of_pattern, abs(Qinv[i, j]))
            end
        end
        @test worst_out_of_pattern > 0.01     # at least one substantial OOP entry
        @info "out-of-pattern dense |Q⁻¹| present (Takahashi correctly skips)" worst = worst_out_of_pattern
    end
end
