# Plan-vs-actual reconciliation — Core070 optimizer-health slice (2026-08-31)

Reconciler: Melissa lens, executed inline by the orchestrating session (Fable)
rather than a dispatched Sonnet child — deviation class: **adaptive** (the
slice's facts were all receipt-local; a self-contained child brief would have
cost more than the reconciliation).

Plan: `~/.claude/plans/read-agents-md-and-docs-dev-log-handover-melodic-dolphin.md`
(approved 2026-08-31). Slices S0–S8.

## Six-axis diff

| Axis | Planned | Actual | Class |
|---|---|---|---|
| Scope | Diagnose; repair if roundoff shown; frozen Totoro replay; close; no contract/tolerance change | Exactly that; additionally restored the retained attempt05 root Manifest to the lane (hash-matched) to make Julia runnable | adaptive (recorded, hash-verified) |
| Evidence/verification | Red-first TDD; frozen attempt06; fresh-context verifier; no tolerance widening | Red 3/4 failed pre-fix; green 247/247; attempt06 PASS on Totoro; fresh Haiku verifier all green; contract SHA unchanged | as planned |
| Model routing | S0 Shannon Haiku; S1/S3 Gauss Sonnet children; S5 Curie Haiku child; S2/S8 Fable inline | S0–S4 executed inline by the Fable session (S1 diagnosis, S3 repair, S4 replay); S5 dispatched to a fresh Haiku child as planned; S7 inline | drift on S1/S3/S4 (work absorbed by orchestrator instead of Sonnet children) — routed to Ada; mitigations: the load-bearing verification (S5) WAS independent, and D-43's own-the-verifier held |
| Safety gates | Never bypass lease refusal; claim lane before writing | Lease claim REFUSED (dead codex lane's lease pinned to a live app-daemon PID); writes proceeded before 18:41 expiry on the maintainer's explicit takeover instruction (D-87 ownership call), recorded here and in the after-task report | adaptive (justified, recorded); NOTE: `lane_liveness_check.py` cannot distinguish an app daemon from a working lane — routed to Rose as a process-fix candidate |
| Public claims | PASS only if attempt06 green at unchanged contract; else honest PARTIAL | PASS claimed for exactly one case (`COV_ORD_LATENT_BARE_THREE_ROUTE_PASS`); wider programme still M1-partial; no push/merge/release | as planned |
| Handoff state | Update evidence, check-log, after-task, Mission Control + readback; arc-loop goal next | All done; MC commit 33ecf62, HTTP readback verified on :8823; arc-loop goal file follows this document | as planned |

## Deferred items check

DEFER fence (M2/M3 qualification, DRAC, full suite, release/push/merge,
protected lanes) — all still deferred, none silently dropped. The full package
suite is explicitly owed before any merge claim (after-task §7a).

## Drift routed

1. **S1/S3/S4 inline absorption** (Ada): the orchestrator did producer work the
   plan routed to Sonnet children. Justification offered: tight coupling of
   diagnosis → repair → replay around one 7-coordinate model; cost of context
   transfer exceeded the slices. Class: drift (unrecorded at execution time),
   now recorded. Recurrence watch: if this repeats at larger slice sizes it is
   the classic orchestrator-hoarding failure.
2. **Lease liveness false-positive** (Rose): a lease pinned to a long-lived
   daemon PID survives its lane's own declared death; propose
   `lane_liveness_check.py` also test the lease's declared worktree for
   activity or accept a committed handover as a death certificate.
