# Included by test_quality.jl ONLY when JET is available (the test/Project.toml
# env, e.g. under Pkg.test / CI). Kept separate because `JET.@test_opt` is a
# macro: it expands at lowering, before any runtime `_HAS_JET` guard, so an
# inline call would UndefVarError in a JET-less environment.
#
# Gates type-stability of the O(p) selected-inverse recursion kernels. The full
# CHOLMOD-facing path (`takahashi_diag` / `grad_node_perspecies`) retains ONE
# known, O(1)-per-call stdlib-boundary dispatch — `sparse(::CHOLMOD.Factor‑
# Component)` returns a `Union` — which is a SparseArrays design detail, not
# GLLVM's to fix, and is intentionally not gated.
#
# Minimal correctly-typed args (SparseMatrixCSC{Float64,Int64}, Vector{Int64});
# @test_opt does abstract interpretation on the argument types, so the values
# need not form a real Cholesky factor.
let
    L = sparse(Int64[1, 2], Int64[1, 2], [1.0, 1.0], 2, 2)
    perm = Int64[1, 2]
    JET.@test_opt target_modules = (GLLVM,) GLLVM._takahashi_diag(L, perm)
    JET.@test_opt target_modules = (GLLVM,) GLLVM._takahashi_selinv(L, perm)
end
