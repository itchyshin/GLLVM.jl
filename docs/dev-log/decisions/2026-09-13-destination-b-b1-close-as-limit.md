# Destination B B1 — close-as-limit (not redesign)

**Date:** 2026-09-13
**Worktree:** `/private/tmp/destination-b-b1-integration-20260910`
**Branch:** `codex/destination-b-b1-integration-20260910`
**Authority:** Shinichi's explicit "run DestB all the way to finish, use the
recommended path" instruction, decision point 1: "B1 → close-as-limit (not
redesign). Document both HOLD (`obj$he`) and new receipt (`MakeADFun`
map-length) as confirmed interface limits for frozen-0.7.0. No retry. No
capture redesign in this run."
**Frozen R oracle:** `gllvmTMB` 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86`.

## What was decided

Destination B's B1 marginal-curvature line (`B1-JOINT-STATIONARY` →
`B1-JOINT-PAIR` in `.unlazy/destination-b-programme/GATES.md`) is **closed
as an interface limit for frozen-0.7.0**, not qualified and not left open
for a third attempt in this or any future session without a fresh, separate
maintainer decision naming a genuinely different reconstruction strategy.

This is a **closure decision**, not a pass. Neither B1 curvature attempt
produced a stationary Hessian, a gradient, or any interval evidence. Both
attempts are retained as honest FAILED receipts. "Close-as-limit" means:
stop spending further sessions retrying the same `obj$he()` / bare
`MakeADFun()` reconstruction approach against the frozen 0.7.0 TMB/DLL
binding, and record the two failures as the load-bearing evidence for why
that binding does not support out-of-pipeline curvature evaluation — not as
evidence about GLLVM.jl's own curvature, singularity, or identifiability.

## The two confirmed interface limits

### 1. `fixed_coordinate` — `obj$he()` HOLD (2026-09-10)

**Receipt:**
`docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`
(untracked, protected; still the only pre-existing untracked file in this
worktree as of this session).

**What happened:** a bare `TMB::MakeADFun(...)` reconstruction of a captured
fixed-coordinate object was built successfully, but the direct-Hessian call
`obj$he(theta_star)` failed. The reconstructed `ADFun` object does not carry
whatever internal state the live `gllvmTMB::gllvmTMB()` fitting pipeline
holds at the point `obj$he()` is normally called from inside that pipeline.

**Disposition:** interface/reconstruction limitation of an out-of-pipeline
`MakeADFun` rebuild against the frozen 0.7.0 binding — not a curvature or
singularity verdict about the fitted model.

### 2. `fixed_point_marginal` — `MakeADFun` map-length HOLD (2026-09-13)

**Receipt:**
`docs/dev-log/core070/destination-b-b1/fixed-point-marginal-curvature-diagnostic-20260913.json`
(newly PROTECTED this session; see the 2026-09-13 G2 after-task for full
capture-materialization provenance).

**What happened:** the same class of bare `TMB::MakeADFun(data=,
parameters=, DLL=, random=, map=)` reconstruction — this time from a
properly materialized capture (real hashes, zero optimizer calls, trace-
intercepted before any `gllvmTMB` optimizer dispatch) — failed one step
**earlier** than the first HOLD: the reconstruction itself throws `"A map
factor length must equal parameter length"` inside
`reconstruct_frozen_object()`, before `obj$fn()` or `TMB::sdreport()` is ever
reached.

**Disposition:** the captured `map` (a list of TMB `factor()` objects built
implicitly inside `gllvmTMB::gllvmTMB()`'s own construction path) does not
survive reconstruction through an independent, out-of-pipeline
`MakeADFun()` call. This is a genuine reconstruction/interface finding, not
a bug in the evaluator to patch and rerun.

## Why both count as the same class of limit

Both receipts fail at the TMB reconstruction boundary — one after
`MakeADFun` succeeds but before `obj$he()` returns, the other during
`MakeADFun` itself — when a frozen R capture is rebuilt **outside**
`gllvmTMB::gllvmTMB()`'s own fitting call graph. Neither receipt reached
`obj$fn()` or `TMB::sdreport()`. Together they are read as confirming that
the frozen 0.7.0 TMB/DLL binding's `map`/`parameters` contract is coupled to
`gllvmTMB`'s own internal builder in a way that a bare, independent
`MakeADFun()` reconstruction cannot currently satisfy — for two different,
independently-materialized captures, on two different dates, by two
different (but structurally similar) reconstruction attempts.

## What this closes and what it does not close

**Closes:**
- Any further attempt at B1 marginal-curvature evaluation via bare
  `MakeADFun` reconstruction against the frozen 0.7.0 binding, without a
  fresh maintainer decision naming a **different** reconstruction strategy
  (e.g. capturing `obj$env$last.par`/`parList()` structure alongside the
  map, or reconstructing via `gllvmTMB`'s own internal builder rather than
  an independent `MakeADFun` call — both floated as possibilities in the
  2026-09-13 G2 after-task, neither authorised or attempted here).
- The `B1-JOINT-STATIONARY` and `B1-JOINT-PAIR` ledger gates for this
  programme, as **CLOSED — INTERFACE LIMIT**, not qualified, not pending.

**Does NOT close:**
- `B1-RECOVERY` — never reached; stays OWED/NOT AUTHORIZED regardless (it
  was always downstream of the two gates just closed).
- Any claim about GLLVM.jl's own Wald/curvature machinery, which is
  untouched by this finding — the failure is specifically in reconstructing
  a **frozen R TMB object** outside its own pipeline, not in any Julia code.
- `S3B-CONSUMER` or `S4-PUBLIC-FORMULA` — separate lines, addressed
  separately (see the companion G2 closeout note and the S3b ledger update
  in this same commit).
- Destination B as a programme — 30 of the reconciled 32 rows are untouched
  by this decision.

## No retry, no redesign, in this run

Per the explicit instruction, this session performs **no third B1 attempt**
and **no capture-redesign implementation** — this document is a closure
record, not a new protocol. A redesigned reconstruction strategy remains a
live option for a **future**, separately-authorised session, should the
maintainer judge it worth the effort against the two confirmed limits above.

## Protected artifacts (unchanged by this decision)

- `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`
- `docs/dev-log/core070/destination-b-b1/fixed-point-marginal-curvature-diagnostic-20260913.json`
- `docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds`

None of these three files were staged, edited, deleted, or regenerated by
this decision. This document only records the disposition; it does not
touch the receipts themselves.
