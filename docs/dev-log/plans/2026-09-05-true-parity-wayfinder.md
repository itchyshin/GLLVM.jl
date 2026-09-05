# TRUE PARITY — wayfinder-compatible milestone ladder

**Label:** wayfinder-compatible ladder (**skill absent** — `/wayfinder` folded into ultra-plan §Decision map, Phase 0.6).  
**Scout brief:** `~/local-scratch/true-parity-wayfinder-brief-20260905.md`  
**Live twin maps (update in place, do not fork a third):**
- Julia: `docs/dev-log/core070/true-parity-decision-map.md`
- R: `docs/dev-log/2026-09-02-true-parity-decision-map-gllvmtmb.md` (gllvmTMB twin, read-only)
- Programme extension: `docs/dev-log/core070/true-parity-programme-decision-map-2026-09-05.md`

**Doctrine:** destination before tickets; map before build; month bands are honest guesstimates, not commitments.  
**Parent plan:** `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`

---

## Ladder overview

```
G0 (now) ──► M0 ──► M1 ──► M2 ──► M3 ──► M4 ──► M5
 STOP        lock    map    2nd    surf   real   sign
             dest   clear  order  catch  data   off
```

---

## M0 — Destination lock

**Months from G0:** 0–1  
**Agent-days:** 3–8

**Done when:**

- Owner answers P1–P4, P12 in programme decision map
- Single signed **destination paragraph** in `true-parity-programme-decision-map-2026-09-05.md`
- No open question on oracle ref, bridge strategy, or compute envelope

**Not done:** any `src/` change; any true-parity public claim

---

## M1 — Map clearance

**Months from G0:** ~1 (includes M0)  
**Agent-days:** 8–15 cumulative

**Status: CLOSED 2026-09-05** (M0-10 Rose OK-with-owner-signoffs).

**Done when:**

- Tickets P1–P12 closed or dispositioned in programme map ✅
- Gate-tier row **list drafted** (P3) — **42 rows PROPOSED**; maintainer sign-off still owed ✅
- Rose scan: no contradiction between 2026-09-02 and 2026-09-05 maps ✅
- Ultra-plan Phase 1 map slice list complete ✅
- `.unlazy/true-parity-programme/` map-leaf gates green ✅

**Remaining before v0.true-parity claim (not M1 blockers):** signed gate-tier; θ-map research outcome; phylo Ada-default override if any.

**Hand-off:** paste-ready `/goal` for first build arc (owner picks M2 vs partial M3)

---

## M2 — Second-order programme

**Months from G0:** 2–4  
**Agent-days:** 25–45 cumulative

**Done when:**

- T3 tolerances committed in `second-order-parity-contract.md`
- Toy + **realistic-size** (p≥20, n≥500) receipts for gate-tier families
- P5 resolved: matched-coordinates tier implemented **or** explicitly demoted for v0.true-parity
- Programme §7 fence updated with evidence (not NOT DONE by default)

**Dependencies:** M1; Totoro campaigns with D-139 estimates

---

## M3 — Surface + bridge catch-up

**Months from G0:** 5–12  
**Agent-days:** 60–120 cumulative

**Done when:**

- Gate-tier Julia surfaces exist (not all ~122 rows)
- Grouping four levels (`unit`, `unit_obs`, `cluster`, `cluster2`) paired
- Bridge-eligible rows have ACC-class or native receipts
- Phylo transport Q1–Q4 implemented per owner answers (P10)
- `tools/parity_ledger.py` FORWARD count reduced for gate-tier only

**Explicitly parallelizable:** family engines disjoint by `OWNS:` globs

---

## M4 — Real-data workflows

**Months from G0:** 10–14 (overlaps late M3)  
**Agent-days:** 15–30 incremental

**Done when:**

- At least one Ayumi repo per qualified family class runs end-to-end `engine = "julia"` (or native equivalent)
- Eight acceptance classes satisfied per `real-workflow-acceptance-lessons.md`
- Failures classified with ACC codes, not silent skip

**Dependencies:** M3 bridge/native paths for chosen repos

---

## M5 — v0.true-parity sign-off

**Months from G0:** 12–18  
**Agent-days:** 8–15 incremental

**Done when:**

- All seven clauses in `true-parity-decision-map.md` evidenced
- Signed dispositions on gate-tier rows; no FREE interpretation as true parity
- `docs/src/gllvmtmb-parity.md` updated — harness vs true parity unmistakable
- Rose pre-publish audit OK
- Maintainer one-sentence sign-off recorded in check-log + after-task

**Not required:** Julia General release; gllvmTMB version bump

---

## Intermediate tags (marketing / internal)

| Tag | Approximate when | Meaning |
|---|---|---|
| `v0.harness-parity` | now | Toy fixtures, ledger FREE=0 |
| `v0.second-order-pilot` | M2 partial | Each-own-optimum + pilots |
| `v0.bridge-thin` | done (parity-next) | One ACC scout |
| `v0.true-parity` | M5 | Full programme destination |

---

## Decision-phase ladder (house M0–M5 from scout brief)

These are **gates**, not build slices. Build work lives under M3–M4 only.

| Milestone | Gate | Month band (programme view) |
|---|---|---|
| **M0** | Destination written and agreed (G0) | 0–1 |
| **M1** | All blocking decisions in "Decisions so far" (map cleared) | ~1 |
| **M2** | Phase 1 slice table + Phase 2.5 acceptance ledger written | 1–2 |
| **M3** | G0 approved → `/goal` execution begins | 2+ |
| **M4** | All leaf gates pass (`--reverify`) | varies by arc |
| **M5** | D-43 panel + Melissa reconcile + after-task | at v0.true-parity |

The **build programme** milestones (second-order, surface catch-up, real-data, sign-off) in §M2–M5 above remain the long-horizon view; they start only after M1 map clearance.

## Route doctrine (wayfinder-compatible)

1. **Never skip M0** to start porting — the drmTMB true-parity night lane showed map-first saves rebuilds.
2. **Campaigns never block the lane** — dispatch Totoro/DRAC; lane reads results (D-220).
3. **One R ref per claim** — frozen oracle discipline (P1).
4. **Map ticket ≠ build slice** — if the row says "implement X", the map ticket is "decide whether X is gate-tier".
5. **Update twin maps in place** — Julia + R maps stay authoritative; this file is a progress ladder only.
