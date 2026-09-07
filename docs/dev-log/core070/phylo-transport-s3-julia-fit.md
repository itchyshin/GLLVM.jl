# Phylo transport S3-FIT — PrecisionPhy Gaussian fit (diagnostic only)

**status = diagnostic_only**

This receipt records a local Julia-side fit of an admitted `PrecisionPhy`
payload against the existing `AugmentedPhy` tree path. It is **not a
v0.true-parity claim**. It does not claim recovery, coverage, or
performance. NB2 A11 remains **partial**. The R `phylo_rr` gate is not
lifted.

## Pins

| Item | Value |
|---|---|
| Frozen oracle | gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86` (field meanings only) |
| Julia branch | `cursor/m3-phy-s3-fit-20260907` |
| Julia base | `origin/main` `340f3832` |
| Fixture | S3a / S1 8-tip ultrametric balanced tree, height 0.3, `correlation = false` |
| Fixture identifier | `(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);` |
| `_S3A_NEWICK` | same string as `test/test_bridge_phylo_precision.jl` |

No live 0.7.1 code, current R main, or R engine edit entered this receipt.

## Payload (admitted, then fit)

| Field | Value |
|---|---|
| `n_leaves` | 8 |
| `n_aug` | 14 (`2p − 2`) |
| sparse nonzero count | 38 |
| route | `phylo_precision_payload` → `admit_phylo_precision_payload` → `fit_phylo_gaussian(::PrecisionPhy)` |

## Fit comparison vs `AugmentedPhy` tree path

Seed `20260907`; simulate from dense Σ at `(σ²_phy, σ²_eps, μ) = (1.2, 0.45, 0.35)`.
Finite-difference L-BFGS (`autodiff = :finite`; CHOLMOD blocks AD). Both fits
converged.

This 8-tip one-replicate draw collapses the MLE `σ²_phy` near the boundary.
That is a small-sample property of the draw, **not** a recovery result. The
oracle is path agreement.

| Quantity | tree path | PrecisionPhy | abs Δ |
|---|---|---|---|
| `μ` | 0.497328296539843 | 0.497328296539843 | 0.0 |
| `σ²_phy` | 4.2935240537300833e-7 | 4.2935240537300833e-7 | 0.0 |
| `σ²_eps` | 0.607056990783008 | 0.607056990783008 | 0.0 |
| `negll` | 9.354976837596318 | 9.354976837596318 | 0.0 |

Interior matched-parameter `negll` at `(σ²_phy, σ²_eps, μ) = (1.2, 0.45, 0.35)`:

| tree path | PrecisionPhy | abs Δ |
|---|---|---|
| 10.043502473477625 | 10.043502473477625 | 0.0 |

All absolute/relative deltas ≤ 1e-8. `bridge_fit(; y, family="gaussian", phylo=payload)`
returned the same `sigma2_phy` / `negll` with `diagnostic_only = true`.

## Commands and exit status

Worktree: `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3-fit-20260907`.

```text
~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_fit_phylo.jl")'
# exit 0
# fit_phylo_gaussian — O(p) single-variance phylo | 13 / 13
# fit_phylo_gaussian — PrecisionPhy vs tree path (S3a) | 17 / 17

~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_bridge_phylo_precision.jl")'
# exit 0; 78 / 78 (S3a regression)

# Receipt-number dump: RECEIPT_NUMBERS_OK / INTERIOR_OK
```

No Totoro/DRAC run. No R engine invocation.

## Scope fence

- No R `phylo_rr` S3b, no R cpp, no M2-R2, no NB2 A11 promotion.
- status = diagnostic_only.
- not a v0.true-parity claim.
