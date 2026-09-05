# Advisory smoke — three fail disposition (2026-09-05)

**Status:** **advisory-red** — measured on live R, dispositioned only; not promoted.

**Authority receipt:** [`advisory-r-smoke-nb2-studentt-2026-09-05.md`](./advisory-r-smoke-nb2-studentt-2026-09-05.md) and
[`advisory-r-smoke-nb2-studentt-2026-09-05.json`](./advisory-r-smoke-nb2-studentt-2026-09-05.json) (merged #284 @ `987c293d`).

## Summary

| Metric | Count |
|---|---:|
| PASS | **15** |
| FAIL | **3** |
| TOTAL | **18** |

All three failures are the same predicate class: R-side `r_gradient_max ≤ 1e-4`
on **live** `gllvmTMB` 0.7.1 (`devtools::load_all` twin worktree), not the
frozen CORE070 oracle build. Convergence, finite `logLik`, and parameter-count
checks passed on the failing cells.

## Disposition table

| Cell | Failed object | Measured `r_gradient_max` | Disposition |
|---|---|---:|---|
| `NATIVE-06-NB2` | `r_gradient_max_le_1e-4` | 1.348e-4 | **advisory-red** |
| `NATIVE-12-TRUNCATED-NB2` (BFGS continuation) | `bfgs_r_gradient_max_le_1e-4` | 6.466e-4 | **advisory-red** |
| `STUDENT-T-fixed-nu` | `r_gradient_max_le_1e-4` | 2.508e-4 | **advisory-red** |

(`STUDENT-T-estimated-nu` passed all objects in this slice.)

## What advisory-red means here

These fails are **not**:

- a CI oracle replacement or frozen-build clearance (`core070/ci-oracle-reproducibility-finding.md` still governs CI);
- a §6 holdout upgrade or register promotion;
- evidence for or against second-order contract §7 / programme completion;
- a parity tolerance change or a Julia-side defect verdict.

They **are** a signed record that live/rebuilt R can miss the retained-build
`1e-4` gradient bar while still reporting converged fits with consistent
objective ↔ logLik — consistent with the CI reproducibility note and the
Option D advisory smoke receipt on main.

## Not promoting

No change to holdout lists, validation-debt register rows, or user-facing
capability claims. Retained pinned-build oracle remains authority for CI gates.
