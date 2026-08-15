# After-task: GLLVM.jl × gllvmTMB capability catch-up (post-#204)

**Date:** 2026-08-15  
**Lane:** `cursor/capability-catchup-20260815` @ tip (see checkpoint)  
**Base:** `origin/main` @ `2914cc18` (#204 MERGED)  
**LOOP:** `lanes/gllvmjl-capability-catchup-20260815/LOOP/`  
**Plan:** `docs/dev-log/plans/2026-08-15-gllvm-jl-gllvmtmb-capability-catchup.md`

## What landed

| Arc / Rung | Result |
|---|---|
| Arc 0 | #204 merged; WT rebased; board START HERE → catch-up |
| Rung 1 | Bare `implemented` for `zip / zinb / zib`; parentheticals → Notes |
| Rung 2 | `student` + `com_poisson` → `implemented`; REML **OWED** (code, no package test) |
| Rung 3 | truncated_poisson Identity ACCEPTED (`2026-08-15-truncated-poisson-identity.md`) |
| Rung 4 | `TruncatedPoisson` engine + tests; Status `truncated_poisson` → `implemented`; `truncated_nbinom2` stays planned |
| Rung 5 | **skipped** (contingent; Rung 4 not early enough for fill) |

## Metric movement

| | Before (post-#204 tip) | After |
|---|---|---|
| `implemented` | 49 | **52** |
| `planned` | 18 | **16** |
| `missing` | 5 | 5 |
| Non-bare Status cells | 1 (`zip/zinb/zib`) | **0** |

## Verify (log, not exit code)

- Focused `test/test_truncated_poisson.jl`: **10/10 Pass** (~6.0s) — Λ=0 exact,
  score/weight vs hurdle formulas, y=0 reject, smoke fit + `fit_gllvm` dispatch,
  packed NLL ForwardDiff vs central FD ≤ 1e-6.
- Ledger token parse: zero non-bare Status cells; `truncated_poisson` implemented;
  `truncated_nbinom2` planned; REML planned with OWED note.

## Rose fence

- ≠ invent twin light Δ for cut ZIP/ZINB  
- ≠ ADEMP / coverage campaign  
- ≠ Phylo Model A public intervals  
- ≠ silent rtol widen  
- truncated_poisson claim = Julia Laplace engine + Identity twin cite; light RCall
  Δ **not** landed this run (twin admits; optional follow-up)  
- REML not promoted without dedicated test

## MC julia_surface PROPOSE (do not apply without ask)

After #204 + this catch-up tip: next_safe = truncated_nbinom2 Identity→Engine
**or** REML `test_reml.jl` then promote **or** light RCall truncated_poisson cell.
Do **not** overwrite R MSPL primary `now.next_safe_action`.

## Not done

- Full `Pkg.test()` / Aqua/JET (focused only this close)  
- Push / PR (ask first)  
- Rung 5 truncated_nbinom2 / confint / ZIB+X  
- Twin light Δ for truncated_poisson  
- REML package test
