# Ultra Plan — Ordinal+X light RCall Arc 2 (Phases 0–2 · G0)

Meta: 2026-08-03 · PLATFORM = **Cursor** · AUTHOR = Ada · execute only after
Shinichi **approve** → `/goal` (do **not** Phase-3 in this planning chat).

```
🎯 GOAL
PLATFORM = Cursor (solo). Deliverable = one light gllvmTMB Ordinal+X logLik
cell green at rtol 1e-6 (or honest scaffold + live-oracle OWED if R absent),
using fit_ordinal_gllvm_pertrait_cov + shared site-X γ / per-trait cutpoints.
HEADLINE = extend fit_gllvmtmb_parity_loglik_x for :ordinal / ordinal_probit
and one @testset in the shared-X cohort. IN PARALLEL (cheap): (1) confirm
twin ordinal_probit + X_fix*b_fix cites; (2) confirm Julia fitter export +
link (Logit vs Probit) before DGP. DEFER/FENCE: engine redesign; ADEMP;
coverage; Phylo Model A; silent shared-cutpoint Option B; Dropbox protected
writes; git add -A; push without ask; “full family parity”; force-merge red
CI. DISCIPLINE: verify = paste Δ from live GLLVM_PARITY_TESTS=1 log (or OWED);
compute = laptop RCall (ask Totoro only if grid expands); closure = after-task
+ check-log + STOP. After G0: /goal in a FRESH chat.
```

**ARC PROGRAM:** size-mode · recommended **90–150 min** · Arc 0 = light cell ·
closeout 20 min · under-run → optional README polish only (no second family).

## Phase 0.25 — Sweep receipt

| Surface | Evidence | Finding | Call |
|---|---|---|---|
| **repo** | `fix/ordinal-x-pertrait-cov-20260803` @ `233a310c`; PR **#180** open; identity #179 MERGED @ `0630f8e4` | Engine Arc 1 LOCAL DONE; land #180 then branch Arc 2 from `main` | resume engine tip / post-merge main |
| **twin** | gllvmTMB `ordinal_probit` fid 14; τ₁=0 / K−2; `X_fix*b_fix` (decision cites) | Oracle shape known | co-opt |
| **brain** | prior Gamma/NB2 Arc 2 after-tasks + this identity decision | Pattern reuse | reuse |
| **greps** | `fit_gllvmtmb_parity_loglik_x` has G/Bin/Pois/Gamma/NB/Beta — **no :ordinal yet** | Gap = helper widen + cell | **build-the-gap** |

**Verdict:** reuse engine + identity; **build** Ordinal X-helper + one light cell.

## Phase 0.4 — Locked defaults (unless Shinichi overrides)

| Q | Ada default |
|---|---|
| Base tip | Prefer **post-#180 `main`**; if CI slow and approved, start from engine tip then rebase |
| Link | Match twin **`ordinal_probit`** (probit) even if Julia default Logit under Ordinal — diagnose packing/link before rtol change |
| Live R | Require `GLLVM_PARITY_TESTS=1` when R+gllvmTMB present; else scaffold + OWED |

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Hopper — twin ordinal_probit + shared X_fix · cell must call same formula shape as G/Bin/Pois X helper · use ordinal_probit() in R switch · default if judgment: probit family object
  Fisher — DGP under cutpoints+X is Heywood-prone · budget seed/K=1/mild loadings · never widen rtol
  Rose   — claim = light Ordinal+X logLik only · ≠ full family parity · ≠ engine redesign
  Ada    — one cell, mirror Gamma Arc 2; STOP after after-task
```

## SLICE TABLE

| Slice | Member | Model / Bar | Time | Detail | Dep |
|---|---|---|---|---|---|
| S0 Gate | Ada | Cursor Models | 5m | #180 green → merge (or explicit tip exception) | — |
| S1 Recon | Hopper/scout | Cursor Models | 15m | Twin cites + Julia link/cutpoint packing | S0 |
| S2 Helper | Gauss/build | Cursor Models | 35–45m | `:ordinal` in `fit_gllvmtmb_parity_loglik_x` | S1 |
| S3 Cell | Curie/build | Cursor Models | 25–30m | `@testset` Ordinal+X; live RCall | S2 |
| S4 Repair | Fisher | Other Models if stuck | ≤35m | DGP/link only | S3 if red |
| S5 Close | Rose | Cursor Models | 20m | after-task, check-log, capability note, commit | S3/S4 |
| VERIFY | Rose | Other Models | 10m | Δ paste + fence phrases | S5 |
| RECONCILE | Melissa | N/A — small | — | N/A — single arc | — |

**PARALLEL:** S1 can start while #180 CI finishes if working on engine tip.  
**SEQUENTIAL:** S2→S3→S5.  
**LUNA SUITABILITY:** yes — S1 recon.  
**FAN-OUT BUDGET:** ≤3 children · no Sol/Opus required.

## REVIEW (plan)
Rose: receipt present; fence holds; G0 required before `/goal`. OK to proceed to
approval.

## VERIFY / CONSOLIDATE
- Live logLik Δ ≤ 1e-6 rtol (or OWED)
- No `src/` engine redesign beyond bugfix for the cell
- After-task + Rose fence in check-log

## DECISIONS LOCKED
- Use `fit_ordinal_gllvm_pertrait_cov` only
- rtol 1e-6 unchanged
- No push until ask after `/goal`

## QUESTIONS STILL OPEN
None blocking — Shinichi G0 is the gate.

---

## Paste-ready approval → `/goal`

```text
/goal

Ultra-plan G0 approved. Run Ordinal+X light RCall Arc 2 to completion via LOOP/.

LANE: ordinal-x-arc2-20260803
REPO: /Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/<new-or-engine-wt>
PLAN: docs/dev-log/plans/2026-08-03-ordinal-x-arc2-ultra-plan.md

READ FIRST: the approved plan → repo AGENTS.md →
  docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md →
  docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md.
SCAFFOLD: LOOP/GOAL.md, arcs.md, checkpoint.md, ultra-plan.md; commit.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code; pause at
OPEN GATE; overwrite checkpoint each arc.
START ARC: S2 helper + S3 cell (after #180 on main if not already).
NEXT GATE: push/PR only when Shinichi asks.
FENCE: no ADEMP; no full family parity; no Dropbox protected checkout; never git add -A.
```
