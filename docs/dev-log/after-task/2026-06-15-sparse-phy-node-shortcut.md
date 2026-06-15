# 2026-06-15 - Sparse Phylo Node-Gradient Shortcut

## Goal

Wire the existing node-frame O(p) sparse-phylo gradient into the production
`sparse_phy_grad` route only where it is already verified: phylo-unique states
with one augmented column, no `Λ_phy`, and per-trait `σ_phy`.

## Files Changed

- `src/sparse_phy_grad.jl`
  - Added a guarded dispatcher to route verified phylo-unique states to
    `node_grad(st)`.
  - Kept `_sparse_phy_grad_leafblock(st)` as the exact fallback/reference for
    `Λ_phy`, mixed augmented states, and all unverified shapes.
  - Updated scaling comments so the O(p) claim is restricted to the node route.
- `src/node_gradient.jl`
  - Uses `takahashi_diag(st.chol_Q_eff)` for the same-leaf diagonal extraction.
- `test/test_sparse_phy_grad.jl`
  - Added direct shortcut-vs-leaf-block reference tests on balanced and
    caterpillar trees, including `want_σ²_eps=false`.
- `test/test_node_gradient.jl`
  - Changed the node equality gate to compare against the preserved leaf-block
    reference rather than the public wrapper.
- `bench/sparse_phy_grad_bench.jl`
  - Reworked the benchmark to time the public shortcut against the internal
    leaf-block reference without self-including source files.
- `docs/dev-log/check-log.md`
  - Banked the test and benchmark evidence.

## Validation

```sh
~/.juliaup/bin/julia --project=. test/test_node_gradient.jl
```

Result: 58/58 passed in 9.7s.

```sh
~/.juliaup/bin/julia --project=. test/test_sparse_phy_grad.jl
```

Result: 101/101 passed in 7m12.1s.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.2s.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m36.2s.

## Benchmark

```sh
~/.juliaup/bin/julia --project=. bench/sparse_phy_grad_bench.jl
```

| p | shortcut ms | leafblock ms | speedup | dense-FD ms | max rel err |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 100 | 0.344 | 1.027 | 2.99x | 198.884 | 8.76e-15 |
| 300 | 1.117 | 3.670 | 3.29x | skipped | 2.28e-14 |
| 600 | 1.114 | 24.030 | 21.58x | skipped | 7.11e-15 |

## R Parity Verdict

Not applicable in this slice. No R bridge surface changed; the route is an
internal Julia sparse-phylo gradient dispatch.

## JET / Aqua / Allocs

`Pkg.test()` passed, including the package quality battery available in this
environment. Dedicated Allocs hot-loop evidence was not added in this slice.

## Rose Audit Verdict

Covered for phylo-unique sparse-phylo states only. Partial for the broader
Takahashi roadmap: `Λ_phy` and mixed augmented states remain on the exact O(p²)
leaf-block reference path. The test suite still emits existing duplicate
include/helper overwrite warnings; those should be cleaned separately.

## Next Command

```sh
git diff --check
```
