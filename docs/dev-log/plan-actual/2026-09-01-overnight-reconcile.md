# Plan-vs-actual reconciliation — overnight run 2026-08-31 → 09-01

Reconciler: Melissa lens, inline (Fable session). Scope: the overnight
continuation after the optimizer-health slice (its own reconcile is
2026-08-31-core070-optimizer-health.md).

## What was planned (checkpoint NEXT + maintainer's overnight instructions)
M1-suite; A5 replay; A6 classification; A3 manifest freeze via ultracode;
M1 panel; M2 progress bridge-first; DRAC pre-run if reachable; 0.7.1 catch-up
recon; real-data engine="julia" acceptance; parity artifact refresh.

## Six-axis diff

| Axis | Planned | Actual | Class |
|---|---|---|---|
| Scope | As listed above | All delivered except: manifest FREEZE stopped honestly at DRAFT_V2 (80 rows pending maintainer decisions — correct, scope changes are gated); M1 panel not fired (no completion claim exists to panel); DRAC pre-run blocked (all sockets expired — flagged once, no Duo triggered) | adaptive |
| Evidence | Fresh receipts for every claim | attempt2 family smoke 284/286; attempt5 full harness 40/40 green (status=success), preserving tarballs 4f973ace + 33e7ebd1; A5 replay 28/28+29/29 (a2a043ce); suite 11183/10/8 run TWICE with all 10 failures reproduced at base 425cabf5 (regression exoneration); ACC-URBMAP-01 receipts incl. two retained setup failures | as planned |
| Routing | Ultracode workflow for A3; Sonnet repairs; fresh verifiers | 11 planners + 11 verifiers + 3 repairs + 3 round-2 verifiers (all Sonnet); recon agents (gap-071, bridge-matrix, realdata) Sonnet; orchestrator Fable inline for merges/scripts | as planned |
| Safety gates | No push/merge/release/DRAC-launch/contract change; lane-only writes | Held. Two destructive-command guard blocks resolved by removing the rm (never bypassed). Harness invocation errors (attempt3 receipt-dir, attempt4 baseline) retained as failures, not hidden | as planned |
| Public claims | PARTIAL over overclaim | Family-smoke abort initially mis-summarized as "full harness" in chat, self-corrected within minutes and recorded in check-log; artifact page states harness vs real-data distinction explicitly; ΛΛᵀ 2.2e-2 real-data disagreement flagged, NOT called parity | adaptive (self-caught) |
| Handoff | Checkpoint current at 5am | This document + final checkpoint + refreshed artifact + morning gates table | as planned |

## Drift routed
None unrecorded. One process note for Rose: chat-level interim summaries can
outrun receipts (the "full harness" moment); the discipline that caught it was
counting cell receipts before claiming — keep that mechanical check first.
