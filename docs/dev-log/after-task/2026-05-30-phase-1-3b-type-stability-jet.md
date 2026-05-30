# After-task — Phase 1.3b: type-stability fixes + JET wired green

**Date:** 2026-05-30
**Phase:** 1.3b (quality battery — JET half; perf half still next)
**Branch:** `phase-1-quality` (PR #3)
**Models:** Opus (diagnosis, fix, verification); JET findings-first via Bash temp envs.

## Goal

Fix the JET-flagged type-instabilities in the O(p) phylogenetic gradient path
(deferred from 1.3a), then wire JET as an always-on, *honestly green* gate.

## Root cause

`takahashi_diag` / `takahashi_selinv` had fully-typed bodies but type-unstable
*entry*: `ch.L` and `ch.p` are `getproperty` on a `CHOLMOD.Factor` (inferred
`Any`), so the whole recursion inferred loosely. Separately, `NodePerSpecies`
stored its factors as the **abstract** `CHOLMOD.Factor{Float64}` (the `Ti`
index param unbound), so `st.cΛ̃ \ …` and `takahashi_diag(st.cΛ̃)` dispatched at
runtime.

## Fixes (all behaviour-neutral)

1. **Function barrier** in `takahashi_selinv.jl`: `takahashi_diag` /
   `takahashi_selinv` now delegate to typed kernels `_takahashi_diag` /
   `_takahashi_selinv(L::SparseMatrixCSC{Float64}, perm)`. The single dynamic
   dispatch happens once at the boundary; the O(p) recursion compiles fully
   stable. `sparse(ch.L)` is asserted `::SparseMatrixCSC{Float64}` (the L
   factor is always the lower-triangular CSC, never Symmetric).
2. **Parametric `NodePerSpecies{TF<:CHOLMOD.Factor{Float64}}`** (mirrors the
   existing `SparsePhyState{TF}`): factor fields are concrete per instance, so
   the two Woodbury solves and the `takahashi_diag` call dispatch statically.
   The two solves are also asserted `::Vector{Float64}` (CHOLMOD `\` is not
   inferred).

## JET outcome (measured, GLLVM-scoped via `target_modules=(GLLVM,)`)

| Target | Before | After |
|--------|--------|-------|
| `grad_node_perspecies` | 3 dispatches | **1** (stdlib `sparse` Union, inherited) |
| `_takahashi_diag` kernel | (was Any) | **0 — "No errors detected"** |
| `_takahashi_selinv` kernel | (was Any) | **0 — "No errors detected"** |

The one residual is irreducible: `sparse(::CHOLMOD.FactorComponent)` returns a
`Union{Symmetric, SparseMatrixCSC}` (a SparseArrays stdlib design detail), one
O(1)-per-call boundary dispatch — not GLLVM's to fix. The **perf-critical O(p)
recursion kernels are provably type-stable**, which is what the gate asserts.

## Wiring

- `test/Project.toml`: add JET.
- `test/test_quality.jl`: JET section, guarded-skip under the JET-less core run.
- `test/test_quality_jet.jl` (new): the `JET.@test_opt` macro calls, isolated
  in their own file because macros expand at lowering — an inline call
  UndefVarErrors in a JET-less env (caught by verifying the core run, not just
  Pkg.test). Gates `@test_opt target_modules=(GLLVM,)` on both kernels.

## Checks run

| Check | Result |
|-------|--------|
| `Pkg.test()` | ✅ "tests passed" — quality **12/12**, node-frame 58/58, full suite green |
| Core run `julia --project=. test/test_quality.jl` | ✅ Aqua + JET skip gracefully, exit 0 |
| JET kernels (`@test_opt`, GLLVM-scoped) | ✅ both "No errors detected" |
| Behaviour | unchanged — all pre-existing tests pass (type asserts + parametric struct are value-neutral) |
| CI (PR #3) | verified green at close |

## What did not go smoothly

- First JET wiring put `JET.@test_opt` inline behind a runtime `_HAS_JET`
  guard. Macros expand at parse time, so the JET-less core run UndefVarError'd.
  Caught only because I verified the core path too, not just Pkg.test —
  reinforces "verify every invocation, not just the happy one." Fixed by
  isolating the macros in an included file.

## Next (Phase 1.3 perf half)

- **Takahashi O(p) selected-inverse swap** into `sparse_phy_grad.jl` (currently
  O(p²)) — the real complexity win, maintainer-approved; its own careful slice.
- **BenchmarkTools O(p) sweep** at p ∈ {100, 500, 1000, 5000, 10000} →
  `docs/benchmarks.md` (Florence renders the Confidence-Eye speedup plot).
- Add an Allocs zero-alloc-inner-loop check alongside JET.
