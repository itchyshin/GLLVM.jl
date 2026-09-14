# OWED — advisory Frozen R 0.7.0 family smoke (NB2 + Student-t)

**Status:** **OWED** (tracked debt; non-blocking CI)  
**Last verified:** 2026-09-14 @ `main` `6c46873a` / `1125eafb`  
**Prior disposition:** [`advisory-smoke-fail-disposition-2026-09-05.md`](../core070/advisory-smoke-fail-disposition-2026-09-05.md) (#284)

## What CI does

Workflow job **Frozen R 0.7.0 family smoke (advisory; rebuilt oracle)** runs with
`continue-on-error: true`. Julia shard + Documenter gates remain blocking.

## Known red cells (oracle / gradient health)

| Cell | Predicate | Measured (2026-09-05 live R) | Notes |
|---|---|---:|---|
| NB2 | `r_gradient_max ≤ 1e-4` | 1.348e-4 | Native smoke |
| Truncated NB2 (BFGS) | `bfgs_r_gradient_max ≤ 1e-4` | 6.466e-4 | Continuation arm |
| Student-t (fixed ν) | `r_gradient_max ≤ 1e-4` | 2.508e-4 | Native smoke |

These are **R-side gradient health** on rebuilt/live oracle paths, not Julia
engine defects. They must not be silently ignored when reading CI: check the
advisory job conclusion separately from Julia 8/8 + Documenter.

## Owed work (not scheduled in honest-0.7 Arc 0)

1. Maintainer decision: keep advisory non-gating vs triage before any claim that
   frozen-R smoke is green.
2. Optional: refresh measured `r_gradient_max` on post-#318 `main` and append
   to the JSON receipt (`advisory-r-smoke-nb2-studentt-2026-09-05.json`).
3. Do **not** widen Julia parity tolerances to absorb these failures.

## Handoff (DestB G7, 2026-09-14)

Codex/Totoro execution pack (commands, oracle pin, success criteria, D-139 estimate):

[`docs/dev-log/after-task/2026-09-14-destb-g7-frozen-r-smoke-handoff.md`](../after-task/2026-09-14-destb-g7-frozen-r-smoke-handoff.md)

## Tracking

- GitHub issue: **#323** (opened 2026-09-14 from this note)
- `LOOP/checkpoint.md` — advisory line on merge CI receipts
