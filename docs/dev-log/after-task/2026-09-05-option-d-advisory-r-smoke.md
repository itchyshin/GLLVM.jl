# After-task — Option D advisory R smoke (2026-09-05)

## Scope

Parallel Option D slice: live local **gllvmTMB 0.7.1** advisory smoke for NB2,
truncated NB2, and Student-t cells. Receipt-only — not CI oracle, not second-order
parity, not holdout clearance.

## Outcome

| Metric | Count |
|---|---:|
| PASS | **15** |
| FAIL | **3** |
| TOTAL | **18** |

All three failures are `r_gradient_max ≤ 1e-4` on live R (`devtools::load_all` twin
worktree @ `c5ddd198b`). Convergence, finite `logLik`, and `nfree` passed on those cells.

| Cell | Failed object | Measured max gradient |
|---|---|---:|
| `NATIVE-06-NB2` | `r_gradient_max_le_1e-4` | 1.348e-4 |
| `NATIVE-12-TRUNCATED-NB2` (BFGS) | `bfgs_r_gradient_max_le_1e-4` | 6.466e-4 |
| `STUDENT-T-fixed-nu` | `r_gradient_max_le_1e-4` | 2.508e-4 |

## Checks run

```text
Rscript tools/core070_advisory_r_smoke.R (live load_all on twin worktree)
Julia fixture export: core070_export_advisory_fixtures.jl
Ledger: docs/dev-log/core070/advisory-r-smoke-nb2-studentt-2026-09-05.json
```

## Files touched

- `docs/dev-log/core070/advisory-r-smoke-nb2-studentt-2026-09-05.md` — human receipt
- `docs/dev-log/core070/advisory-r-smoke-nb2-studentt-2026-09-05.json` — machine ledger
- `docs/dev-log/check-log.md` — append entry
- `docs/dev-log/after-task/2026-09-05-option-d-advisory-r-smoke.md` — this note

## Not claiming

- CI `DONE` / frozen oracle replacement
- Second-order contract §7 closure
- NB2 / truncated NB2 / Student-t holdout upgrade
- True parity or 0.7.1 surface port

## Follow-up

- Retained pinned-build oracle remains authority (`ci-oracle-reproducibility-finding.md`)
- θ-map blockers for beta_logit / nb2_log matched tier (see matched-coordinates pilot)

Branch: `cursor/option-d-advisory-smoke-20260905`.
