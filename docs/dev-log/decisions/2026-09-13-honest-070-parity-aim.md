# Decision — honest 0.7.0 parity aim (GLLVM.jl versioning vs frozen gllvmTMB 0.7.0)

**Date:** 2026-09-13  
**Status:** ACCEPTED (maintainer instruction while away: do not bump to 0.7 yet; earn parity first)  
**Scope:** Programme framing only — no `Project.toml` edit, no public capability promotion.

## Question

When may `GLLVM.jl`'s package version move from `0.3.0` toward `0.7.0`, and what does that number mean relative to the R twin?

## Decision

1. **Aim:** Reach *honest* parity with **frozen** `gllvmTMB` **0.7.0** (oracle `b4d5fee6…`) before any Julia version communicates `0.7.x`. `0.7.1` re-freeze waits on the second-order programme (see `docs/dev-log/core070/true-parity-decision-map.md` T2).
2. **Version semantics:** Adopt the GLLVM.jl↔gllvmTMB convention already recorded in vault **D-183** (cited by DRM.jl): the Julia `version` field signals **parity level earned by evidence**, not calendar alignment with R releases.
3. **Hard fence for this programme:** Do **not** edit `Project.toml` `version` until a separate maintainer-gated arc produces a joint decision note listing every gate (DestB numerical ledger, covariance-grid dispositions, open T-items) with receipts or signed dispositions.
4. **S4 public-formula probe:** Remains **NOT AUTHORIZED** without fresh maintainer sign-off **and** fetchable recorder object `97214679c…` (documented on `main` after PR #320; still unpushed in sibling gllvmTMB).
5. **Execution home:** Ranked arcs live in `LOOP/arcs.md` and `LOOP/ultra-plan.md` on branch `cursor/gllvm-07-parity-programme-20260913` (draft PR). DestB numerical fixes stay on PR #318's branch — not edited from the parity programme lane.

## Evidence pointers

- `docs/src/gllvmtmb-parity.md` — harness vs true parity; one-directional claim.
- `docs/dev-log/core070/true-parity-decision-map.md` — destination definition T1–T15.
- PR #318 — DestB G1/G2 closeout (docs; CI owned by fix agent).
- `docs/dev-log/core070/destination-b-s4-recorder-rehydrate.md` — S4 recorder location (#320).

## Out of scope

- Julia General registration, tagging, README headline changes implying 0.7 shipped.
- Twin engine edits in `gllvmTMB`.
