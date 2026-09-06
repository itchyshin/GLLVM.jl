# Phylo transport S3a — Julia precision-payload admission (diagnostic only)

**status = diagnostic_only**

This receipt records a local Julia-side admission of the already-canonical
`PrecisionPhy` bundle. It does not claim v0.true-parity, recovery, coverage,
or performance. NB2 A11 remains **partial**. The R `phylo_rr` gate is not
lifted.

## Pins

| Item | Value |
|---|---|
| Frozen oracle | gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86` |
| Julia branch | `cursor/m3-phy-s3a-20260906` |
| Julia HEAD at measurement | `8602293f71dd011ec06430737aaf4ba707175a6c` plus this slice's uncommitted/committed S3a files |
| Fixture | `_S3A_NEWICK` / S1 8-tip ultrametric balanced tree, height 0.3, `correlation = false` |
| Fixture identifier | `(((A:0.1,B:0.1):0.1,(C:0.1,D:0.1):0.1):0.1,((E:0.1,F:0.1):0.1,(G:0.1,H:0.1):0.1):0.1);` |

No live 0.7.1 code, current R main, or R engine edit entered this receipt.

## Payload (admitted)

| Field | Value |
|---|---|
| `n_leaves` | 8 |
| `n_aug` | 14 (`2p − 2`) |
| sparse nonzero count | 38 |
| `species_aug_id` (0-based wire) | `[6, 7, 8, 9, 10, 11, 12, 13]` |
| `scale` | 1.0 |
| shipped `log_det` | 32.23619130191665 |
| recomputed `log_det` | 32.23619130191664 |
| checksum \|Δ\| | 7.105427357601002e-15 (≤ 1e-8) |

Field meanings follow frozen 0.7.0: `i,j,x` are 1-based `Ainv_phy_rr`
triplets; `species_aug_id` is the 0-indexed TMB map
(`fit-multi.R:4638`, `DATA_IVECTOR` in `src/gllvmTMB.cpp:852`).

## Malformed-input diagnostics

Each case raises `ArgumentError` with the named tag:

| Case | Tag |
|---|---|
| `n_aug ≠ 2p − 2` | `GJL-GATE-PHYLO-PAYLOAD-DIM` |
| triplet index `0` | `GJL-GATE-PHYLO-PAYLOAD-INDEX` |
| tip map out of `0:n_aug-1` | `GJL-GATE-PHYLO-PAYLOAD-TIPMAP` |
| duplicate tip map | `GJL-GATE-PHYLO-PAYLOAD-TIPMAP` |
| `node_labels` length mismatch | `GJL-GATE-PHYLO-PAYLOAD-LABEL` |
| `NaN` in `x` or non-finite `scale` | `GJL-GATE-PHYLO-PAYLOAD-NONFINITE` |
| shipped log-det off by 0.25 | `GJL-GATE-PHYLO-PAYLOAD-LOGDET` |

## Matched-parameter replay vs `AugmentedPhy`

Seed `20260906`; `K_B = 2`, `n = 10`, `σ_eps = 0.4`. Both likelihoods
finite and non-empty.

| `σ²_phy` | `ll_AugmentedPhy` | `ll_payload` | abs Δ | rel Δ |
|---|---|---|---|---|
| 0.3 | -181.5821218429232 | -181.5821218429232 | 0.0 | 0.0 |
| 1.0 | -182.688583321007 | -182.688583321007 | 0.0 | 0.0 |
| 2.5 | -184.04939522531404 | -184.04939522531404 | 0.0 | 0.0 |

All absolute/relative deltas ≤ 1e-8.

## Commands and exit status

Worktree: `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3a-20260906`.

```text
~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_bridge_phylo_precision.jl")'
# exit 0; 76+ passed, 0 failed (keyword admit, empty-label, Dict, S1 wrap)

~/.juliaup/bin/julialauncher --project=. -e 'using Test, GLLVM; include("test/test_phylo_precision.jl")'
# exit 0; 22 passed, 0 failed (S1 regression)

# Receipt-number dump (same fixture and seed as the replay test): exit 0
# printed RECEIPT_NUMBERS_OK
```

No Totoro/DRAC run. No R engine invocation.

## Scope fence

- `src/bridge.jl` was not edited: live lease `cursor-d220-kernel-julia-20260906` (#307) still held that path. Admission API landed in `src/phylo_precision.jl`.
- No R `phylo_rr` gate lift, no kernel `cross_kernel_rho`, no M2-R2, no ledger-row promotion.
- NB2 A11 remains **partial**.
- status = diagnostic_only.
