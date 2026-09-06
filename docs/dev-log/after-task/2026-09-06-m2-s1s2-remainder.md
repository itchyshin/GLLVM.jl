# After-task — M2 remainder S1/S2 (Arc A)

**Date:** 2026-09-06  
**Branch:** `cursor/m2-s1s2-remainder-20260906`  
**Base:** `origin/main` @ `b37af6f0`  
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-m2-s1s2-remainder-20260906`  
**Lease:** `cursor-m2-s1s2-remainder-20260906`  
**G0:** Destination B signed; execute leave-able A first. Local commits only.

## Scope

Close or diagnose the leftover M2-S1 `se=TRUE` receipt schema and the M2-S2
binomial / beta / NB2 each-own-optimum smokes from #303. Write Unlazy GATES
for this remainder only.

## Out of scope (honoured)

- **No merge** of #297 / #298 / #301 / #303 / #304 or any PR
- **No push**, release, or public claim
- **No Totoro** / DRAC / T4 relaunch
- **No M2-R2** matched-coordinate implementation
- No `src/` or gllvmTMB kernel edits
- No `check-log.md` rewrite (collision with open PRs)

## Outcome

| Item | Result |
|---|---|
| Unlazy GATES | written at `.unlazy/m2-remainder-20260906/` (gitignored run ledger) |
| S1 se=TRUE schema | **PASS** 26.1 s — §5 keys + `r_has_sd_report` |
| S2 binomial EOO | **PASS** 26.5 s — A7 stays **partial** |
| S2 beta EOO | **PASS** 24.7 s — A9 stays **partial** |
| S2 NB2 EOO | **PASS-WITH-WARNINGS** 30.7 s — A11 stays **partial**; see note |
| cells.jl | added `derived_quantity` and `r_objective` (harness-only) |

NB2 printed `eoo_smoke_pass=true` on β SE/CI, but Julia did not converge,
both Hessians failed PD, groups 1 and 3 sat on the Poisson-limit boundary,
and R warned `NaNs produced` in `sqrt(diag(cv))`. Judgment: **partial**,
not covered. Tolerances were not widened.

## Checks run (log, not exit-code-only)

```
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. tools/core070_second_order/smoke_se_true_schema.jl
# SE_TRUE_SCHEMA_SMOKE PASS (26.1s)

  julia --project=. tools/core070_second_order/smoke_binomial_eoo.jl
# BINOMIAL_2SO_EOO_SMOKE PASS (26.5s)

  julia --project=. tools/core070_second_order/smoke_beta_eoo.jl
# BETA_2SO_EOO_SMOKE PASS (24.7s)

  julia --project=. tools/core070_second_order/smoke_nb2_eoo.jl
# NB2_2SO_EOO_SMOKE PASS (30.7s) + boundary / R NaN warnings
```

Live R: gllvmTMB **0.7.1** (not frozen 0.7.0). Recorded as a caveat.

Not run: full `Pkg.test()`, Totoro, Documenter, M2-R2.

## Review lenses

| Lens | Verdict |
|---|---|
| Hopper | Fixtures reuse existing `cells.jl` batch-1 DGPs — OK |
| Fisher | NB2 not promoted; cond-scale called out — OK |
| Rose | Claim boundary on every receipt; no merge/push — OK |

## What remains for Arc A

- Optional: re-verify Unlazy GATES after this commit (`--reverify`)
- Docs hygiene on `check-log.md` still **stopped** (PR ownership collision)
- M3 design/scout is **not** this slice (user asked Arc A / S1–S2 only)
- Owner still decides merge of #297/#301/#304 separately
- New G0 required before M2-R2
