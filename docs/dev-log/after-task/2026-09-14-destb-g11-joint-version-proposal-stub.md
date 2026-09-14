# Destination B — G11 joint 0.7.0 version proposal (STUB — not a bump)

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb` · draft PR [#336](https://github.com/itchyshin/GLLVM.jl/pull/336)  
**Authority panel:** [`2026-09-14-destb-final-review-panel.md`](2026-09-14-destb-final-review-panel.md) (Rose + Fisher **PASS-WITH-CORRECTIONS**)  
**Ultra-plan:** [`docs/dev-log/plans/2026-09-14-honest-070-destination-b-ultraplan.md`](../plans/2026-09-14-honest-070-destination-b-ultraplan.md)  
**D-183:** Julia `version` signals **parity earned**, not R release calendar (`docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md`).

## Proposal (maintainer-facing stub)

**Recommend keeping `Project.toml` at `0.3.0`** after merge of programme receipt PR #336
(or successor). This stub is a **proposal to discuss** a future move toward **`0.7.0`** —
**not** an instruction to edit `Project.toml` in this branch or PR.

A formal decision note may later be promoted to
`docs/dev-log/decisions/YYYY-MM-DD-joint-070-version-proposal.md` **only** after the
blockers below are dispositioned or explicitly waived in writing.

## Evidence closed on this programme (summary)

- DestB **API-BOUNDARY** static PASS; B1 **closed-as-limit**; S3b adapter-consumer fenced.
- Honest-0.7 Arc 0 grid **#9–#15** docs promotion with Rose qualifiers.
- T13 `mi()`, T14 NB2 Wald (F1–F3), T15 knife-edge audit (document-only).
- **FINAL-REVIEW** panel PASS-WITH-CORRECTIONS on G1–G9 receipts (docs branch).

## Held / open — must stay in any bump discussion

### T14 — cross-Julia well-conditioned seed (legacy 3×70 NB2)

No single seed reproduces the **old** `_bx_sim(3,70)` shape as well-conditioned on
**both** Julia 1.10 and 1.12 (~35k search; check-log 2026-09-02). F2 uses an
**alternate** well-conditioned DGP (`n=200`, `nb_r=2`, intercept 1.5). Fixture #18
in [`2026-09-14-destb-g6-t15-knife-edge.md`](2026-09-14-destb-g6-t15-knife-edge.md)
remains **DOCUMENT open** — not a silent parity defect, not fixed by retargeting
seed-523 degenerate cells without maintainer sweep.

### S4 — public-formula probe **HELD**

Recorder **`97214679c`** is on origin; gllvmTMB draft **#1283**
([`2026-09-14-destb-g9-s4-recorder-push.md`](2026-09-14-destb-g9-s4-recorder-push.md)).
**Isolated Julia probe not run.** G0 Q2 requires a **second explicit maintainer yes**
after fetch before any probe campaign — S4 is **not** closed for DestB or version talk.

### #323 — advisory Frozen R smoke **HELD**

Codex/Totoro handoff only ([`2026-09-14-destb-g7-frozen-r-smoke-handoff.md`](2026-09-14-destb-g7-frozen-r-smoke-handoff.md)).
CI advisory job may stay **red** (R-side `r_gradient_max` on NB2 / truncated NB2 /
Student-t). **D-139** estimate required before Totoro spend. Issue **#323** open until
frozen-oracle refresh **or** written decision to keep advisory non-gating indefinitely.

### Other programme fences (unchanged)

- **B1-RECOVERY:** NOT AUTHORIZED (G0 Q1).
- **Core070 497-row ledger:** parallel track; not DestB headline completion.
- **T5 / T8 / T11 / realistic-size / T7:** blocked or out of scope — see `LOOP/arcs.md`.

## What would unlock a *later* maintainer discussion of `0.7.0` (not automatic)

1. Merge receipt branch with **8/8 Julia + Documenter green**; advisory smoke narrated separately.
2. Explicit disposition of **#323** and **S4 probe** (run + receipt **or** documented waive).
3. Rose pre-publish on any user-facing promotion tied to version semantics.
4. Maintainer sign-off on formal G11 decision markdown (this stub superseded, still **no** bump in same PR unless separately authorised).

## What would **not** alone justify a bump

Arc 0 Gaussian scaffolds; bridge smoke; advisory-red Frozen R; T14 engine fix without
scope ledger; gllvmTMB calendar 0.7.0; merging docs PR #336 without blockers dispositioned.

## Verification (this stub)

Documentation only. `Project.toml` unchanged (`0.3.0`).
