# Advisory R smoke — NB2, truncated NB2, Student-t (Option D)

**Date:** 2026-09-05  
**Mode:** advisory live R (`NOT_CRAN=true`, `devtools::load_all` on twin worktree) — **not** the frozen CORE070 oracle build.  
**Authority:** object-level PASS/FAIL ledger below; not CI `DONE` line counts.

## R package under test

| Field | Value |
| --- | --- |
| Worktree | `/Users/z3437171/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904` |
| Branch | `cursor/option-d-advisory-smoke-20260905` |
| `git` HEAD | `c5ddd198b` (includes merge of `origin/main` through #1269 simulate truth names) |
| `packageVersion("gllvmTMB")` | **0.7.1** (from `DESCRIPTION` via `load_all`) |
| BLAS | `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1` |

## Cells exercised (parity fixtures)

| Cell ID | Fixture | Seed | Shape |
| --- | --- | --- | --- |
| `NATIVE-06-NB2` | `test_negbin_parity.jl` DGP | 45 | p=5, K=2, n=80 |
| `NATIVE-12-TRUNCATED-NB2` | `test_truncated_nbinom2_parity.jl` DGP + BFGS continuation policy | 58 | p=5, K=1, n=120 |
| Student-t fid 9 | `test_studentt_parity.jl` DGP | 71 | p=5, K=1, n=130 (fixed ν=4 and estimated ν) |

Fixture `Y` exported with Julia (`core070_export_advisory_fixtures.jl`) to `/Users/z3437171/local-scratch/core070-advisory-fixtures/`; truncated NB2 `data_sha256` matches the locked parity hash `ecbcf9f5…`. NB2 export hash is `af68c91f…` (current DGP in `test_negbin_parity.jl`; differs from the older locked string `7abde273…` still referenced in `nb2_health.jl` — receipt-only, no promotion).

## Object-level summary

| Metric | Count |
| --- | ---: |
| **PASS** | **15** |
| **FAIL** | **3** |
| **TOTAL** | **18** |

Machine ledger: [`advisory-r-smoke-nb2-studentt-2026-09-05.json`](./advisory-r-smoke-nb2-studentt-2026-09-05.json) (same run as this note).

## Failures (R-side health gate `r_gradient_max ≤ 1e-4`)

All three failures are the same predicate class CI called out for rebuilt / live R vs retained oracle:

| Cell | Object | Measured `r_gradient_max` |
| --- | --- | ---: |
| `NATIVE-06-NB2` | `r_gradient_max_le_1e-4` | 1.348e-4 |
| `NATIVE-12-TRUNCATED-NB2` (BFGS continuation) | `bfgs_r_gradient_max_le_1e-4` | 6.466e-4 |
| `STUDENT-T-fixed-nu` | `r_gradient_max_le_1e-4` | 2.508e-4 |

## Pass highlights (still failing cells)

- NB2: `r_converged`, finite `logLik`, `nfree=19`, objective ↔ logLik consistency.
- Truncated NB2: default + BFGS `converged`, `nfree=15`, objective ↔ logLik consistency.
- Student-t estimated ν: `r_converged`, `optimizer_code=0`, finite `logLik`.

## Relation to JL #281 CI advisory smoke

Julia CI’s full frozen family smoke (`runparity.jl`, 17 cells) reported ~9 failing **test objects** across the suite; this slice intentionally runs **R-only** checks on the three holdout families named in Option D (NB2, truncated NB2, Student-t). Here **3/18** R health objects fail, all on the shared `1e-4` gradient gate — consistent with the CI reproducibility note (`ci-oracle-reproducibility-finding.md`) that live/rebuilt R can miss the retained-build gradient bar without invalidating converged fits.

## Commands (repro)

```sh
export NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
export GLLVM_TMB_ROOT="/Users/z3437171/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904"
export CORE070_FIXTURE_DIR="/Users/z3437171/local-scratch/core070-advisory-fixtures"
julia --project=/path/to/GLLVM.jl /Users/z3437171/local-scratch/core070_export_advisory_fixtures.jl
Rscript /Users/z3437171/local-scratch/core070_advisory_r_smoke_option_d.R
```

## Disposition

**Advisory only** — no register promotion, no §6 holdouts edit, no parity tolerance change.
