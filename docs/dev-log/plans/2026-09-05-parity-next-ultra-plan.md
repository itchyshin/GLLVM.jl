# Parity next — ultra-plan (Phase 0–2, STOP AT G0)

**Authored:** 2026-09-05 · Ada · post–Option D twin-trust bundle  
**Worktrees:** JL `~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904` · R `~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904` (read-only reference)  
**Vault:** D-220 one Cursor lane · frozen oracle `b4d5fee6` (gllvmTMB 0.7.0)  
**Main @ sweep refresh:** `987c293d` (#285 merged; #284–#283–#282–#281 on main)  
**Status:** **STOP AT G0 — no Phase 3 execution**

---

```
🎯 GOAL
Solo platform: Cursor (one orchestrator chat, both worktrees)
Deliverable: 3-day package — trust fences on main + ONE thin catch-up wedge (scout/decision, not full port)
HEADLINE: ~3 days with 2–4 parallel agents: close trust docs (§7 fence, smoke disposition, #286) + either bridge ACC scout OR θ-map decision OR traits decision-map — NOT full catch-up surface
IN PARALLEL: S4 §7 fence · S5 smoke disposition · #286 closeout · wedge scout (after G0-2)
DEFER: Full matched-coords tier · θ-map implementation (unless entire wedge) · 0.7.1 port · traits/iSDM/spatial/column_coef engines · true-parity §7 · #1236 · MSPL D-157
DISCIPLINE: verify=ledger re-run + Rose · compute=local; Totoro ≤30 min smoke only · closure=after-task per slice · oracle stays b4d5fee6
```

**Lane taken:** `cursor/parity-next-ultra-plan-20260905` — docs + trust closeout + one thin wedge.  
**Do not touch:** gllvmTMB engine (#1236 Claude); parallel merge agent may close #286 — this lane does not merge without G0.

---

## SIZE & FEASIBILITY (Shinichi sizing ask)

### Honest cut first

**Full (2) near-term trust + (3) real catch-up surface, as originally scoped, is too big for ~3 calendar days.** Say that plainly:

| Scope | Realistic calendar time (2–4 parallel agents) |
|---|---|
| Trust **with merges still open** (Option D #284–#286) | ~1.5–2 days |
| Trust **today** (#284/#285 already on main) | **~0.5–1 day** (docs + #286 only) |
| Catch-up wedge **thin** (scout / decision-map / one bridge attempt) | **~0.5–1.5 days** |
| Catch-up wedge **full** (θ-map code + pilot rerun, or bridge ACC pass) | **~2–4 days each** |
| **Naive full catch-up surface** (122 `BLOCKED_NEEDS_JULIA_SURFACE`, traits, iSDM, spatial, column_coef) | **~4–8 weeks** (20–40 agent-days) |

Running **everything** in (2)+(3) at “full depth” is a **multi-week programme**, not a 3-day sprint.

### 1. Wall-clock — what fits in ~3 calendar days

Assume **2–4 concurrent workers** (Cursor Grok scouts + one judgment pass + Codex for live R smoke if needed), Totoro OK for **short** smokes (≤30 min, D-139), no DRAC mega-grid.

| Day | Parallel work | Owner |
|---|---|---|
| **Day 1** | §7 + matched-coords claim fence (S4) · advisory 3-fail disposition (S5) · #286 bundle closeout or check-log (S3) · verify #284/#285 receipts on main | Cursor ×2–3 |
| **Day 2** | G0 wedge scout — **one of:** bridge ACC recon + thin `Rscript` attempt · OR θ-map **decision doc** (not full impl) · OR traits/column_coef **decision map only** | Cursor scout + Codex R if wedge A |
| **Day 3** | Wedge deliverable finish · ledger re-run (V1) · Melissa plan-actual · after-task closeout | Cursor + judgment pass |

**Buffer:** Day 3 is contingency for wedge failure classification (honest red receipt counts as done for scout-level wedge).

### 2. IN vs OUT of the 3-day envelope

**IN (concrete deliverables on main or one branch ready for review):**

1. `second-order-parity-contract.md` + `gllvmtmb-parity.md` — programme **§7 NOT DONE**; matched-coords **3/5 pilot, 2 θ-blocked, tier NOT implemented**.
2. `advisory-smoke-fail-disposition-2026-09-05.md` — three gradient fails advisory-red (NB2, trunc NB2, Student-t).
3. Option D bundle verification landed (#286 merge **or** equivalent check-log + after-task).
4. Confirm #284/#285 artifacts on main (already merged — verification only, not rebuild).
5. **One** catch-up wedge output at **thin** depth:
   - **A (recommended):** ACC recon + one documented bridge attempt on `urbanisation_map` (pass **or** classified failure with ACC class).
   - **B (alt):** θ-packing **decision doc** for beta/NB2 blockers — implementation deferred unless Shinichi makes B the *only* wedge and drops A/C.
   - **C (alt):** four-section decision map for `traits()` / column_coef — **no code**.

**OUT (must defer or decision-map-only later):**

- Full matched-coordinates tier at 1e-4 (needs θ-map **implementation** + full batch-1).
- Full θ-map implementation **and** pilot rerun **and** trust docs **and** bridge ACC pass — cannot fit 3 days.
- True-parity / programme §7 complete claim.
- Any 0.7.1 Class-1 export port (`column_coef`, `traits()`, etc.).
- iSDM, spatial SPDE, `#1236` bridge expansion, grouping-level engine surfaces.
- Multi-seed Totoro recovery campaigns.

### 3. The 3-day package (recommended)

**Package name:** `trust-fence + thin-wedge`

Still useful because:

- Merges for #284/#285 are **already done** elsewhere — this arc finishes the **honesty layer** (claims match evidence).
- Maintainers get a signed story: each-own-optimum yes; matched-coords and §7 explicitly no; smoke fails dispositioned.
- One forward step toward true-parity T7 without pretending Julia caught 0.7.1.

**Not in the 3-day box:** implementing traits parser, porting column_coef, or closing all 77 forward ledger rows.

### 4. Effort table (agent-days, low–high)

| Track | Low | High | Notes |
|---|---:|---:|---|
| **(a) Near-term trust only** | 0.5 | 1.0 | #284/#285 on main; S4+S5+S3(#286) docs |
| **(b) One catch-up wedge — thin** | 0.5 | 1.5 | Scout/decision/one bridge attempt |
| **(b) One catch-up wedge — full** | 2.0 | 4.0 | θ-map code+rerun OR guaranteed ACC pass |
| **(c) Naive full catch-up surface** | 20 | 40+ | 122 blocked rows; multi-week programme |

**Combined 3-day package (a-thin + b-thin):** **1.5–2.5 agent-days** of focused work, **~3 calendar days** with parallel agents and review gates — **not** (a)+(b-full) simultaneously.

### 5. Doable?

**Only-if-cut** — with the cut named:

| Question | Answer |
|---|---|
| Full (2)+(3) at original depth in 3 days? | **No** |
| 3-day `trust-fence + thin-wedge` package? | **Yes** — with G0 wedge pick and no scope creep |
| 3 days with wedge B **full implementation** + trust? | **No** — pick B-decision-only or extend to ~5 days |

---

## Phase 0 receipts

### 0. Lane preflight

**JL:** SECOND cursor lane active (Option D branches + twin); confirm HEAD before commit.  
**R:** FOREIGN lane active (codex/claude #1236) — read-only.

### 0b. Session + drift

PLATFORM: Cursor · plan branch `cursor/parity-next-ultra-plan-20260905` · main @ `987c293d`.

### 0c. Prior-work sweep (refreshed 2026-09-05)

| Item | Finding | Call |
|---|---|---|
| **#281–#285** | **MERGED** on main | Verify only — do not rebuild |
| **#286** | **OPEN** draft — bundle closeout | S3 — merge agent or check-log |
| **Matched-coords** | 3 pass / 2 θ-blocked on main (#285) | Signed disposition in S4 |
| **Advisory smoke** | 15/3/18 on main (#284) | S5 disposition for 3 fails |
| **True-parity map** | §7 + matched-coords **NOT DONE** | Reuse fence |
| **FORWARD=77** | Still owed | No claim this arc closes them |

### 0d. Model roster

Scouts → Cursor Models (Grok); claim/estimand → Other Models; live R smoke → Codex handoff.

### 0e. G0 questions + pre-auth

See OPEN GATES below. Pre-auth: scoped docs edits, local smokes, draft PR; **no main merge** without Shinichi OK.

---

## Phase 0.6 route check

**Verdict:** **Plan proceeds** for 3-day package. Trust route knowable (#284/#285 done). Catch-up slice S6 waits on G0-2 wedge at **thin** depth only. Full θ-map or full bridge pass → **decision map / later arc**, not this 3-day box.

---

## What's done (Option D — refreshed)

| # | Deliverable | State |
|---|---|---|
| 1–3 | #281 D1 · #282 holdouts · #283 Rose | **MERGED** |
| 4 | #284 advisory smoke | **MERGED** — 15/3/18 |
| 5 | #285 matched-coords | **MERGED** — 3/0/2/0 |
| 6 | #286 bundle closeout | **OPEN** draft |

---

## G0 wedge menu (thin depth only for 3-day box)

| Wedge | 3-day feasible depth | Full depth (defer) |
|---|---|---|
| **A — Bridge ACC** ⭐ | Recon + one `Rscript` attempt; ACC class recorded | Guaranteed end-to-end pass + extractor symmetry |
| **B — θ-map** | Decision doc: packing map spec + blocker sign-off | Implementation + pilot rerun |
| **C — traits/column_coef** | Four-section decision map; no code | Parser / export port |

---

## Phase 2 — 3-day slice table

| ID | Slice | Bar | Est. | Output | Dep |
|---|---|---|---|---|---|
| **S3** | #286 bundle closeout or check-log equivalent | Cursor | 2 h | after-task on main | — |
| **S4** | §7 + matched-coords claim fence | Other | 3 h | contract + parity page | — |
| **S5** | Advisory 3-fail disposition | Cursor | 2 h | `advisory-smoke-fail-disposition-*.md` | — |
| **S6t** | Thin wedge (G0 pick A/B/C) | mixed | 1 d | one file per wedge menu | G0-2 |
| **V1** | Ledger re-run + Rose spot-check | Cursor | 1 h | plan-actual | S3–S6t |
| **R1** | Melissa reconcile | Other | 30 m | `plan-actual/2026-09-05-parity-next.md` | V1 |

**Removed from 3-day table (already done):** S0 recon, S1 #284 merge, S2 #285 merge — verify on main instead.

**Parallel:** `{S3,S4,S5}` day 1 → `{S6t}` day 2–3 → `{V1,R1}`.

---

## Phase 2.5 — acceptance ledger (3-day package scope)

**Path:** `.unlazy/parity-next-20260905/` (gitignored run state)

Leaves scoped to **3-day package only:**

- `leaf-s3-bundle.md` — #286 or check-log
- `leaf-s4-claim-boundary.md` — §7 fence
- `leaf-s5-advisory-fails.md` — 3-fail disposition
- `leaf-s6-catchup-thin.md` — one wedge deliverable
- `leaf-v1-verify.md` — ledger + no overclaim

Legacy merge leaves (S0/S1/S2) **ABANDONed** — merges landed on main.

---

## OPEN GATES for Shinichi (G0)

| ID | Question | Recommendation |
|---|---|---|
| **G0-1** | Approve **3-day package** (`trust-fence + thin-wedge`) vs trust-only (~1 day)? | **Yes — 3-day package** |
| **G0-2** | Catch-up wedge at **thin** depth: **A** bridge scout · **B** θ-map decision · **C** traits map · **trust-only**? | **A** (bridge scout) |
| **G0-3** | Sign matched-coords wording: "batch-1 3/5; 2 θ-blocked; tier NOT implemented"? | **Yes** |
| **G0-4** | #286: merge agent closes, or this lane docs-only? | Merge agent OK |
| **G0-5** | Advisory 3-fails = advisory-red (no holdout upgrade)? | **Yes** |
| **G0-6** | Push policy: draft PR + local commits; no main merge without OK? | **Yes** (D-220) |

---

## Paste-ready `/goal` (AFTER G0)

```
/goal parity-next-3day-20260905

Platform: Cursor · 2–4 parallel workers · D-220 twin worktrees:
  JL: ~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
  R:  ~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904 (read-only; Codex for live R if wedge A)

DESTINATION: 3-day package — trust fence on main + ONE thin catch-up wedge

DONE WHEN:
- §7 NOT DONE + matched-coords honest disposition on main (S4)
- Advisory 3-fails dispositioned advisory-red (S5)
- #286 closed or check-log equivalent (S3)
- #284/#285 receipts verified on main (no rebuild)
- Thin wedge deliverable per G0-2: A=ACC scout · B=θ-map decision doc · C=traits map
- .unlazy/parity-next-20260905/ leaves PASS or ABANDON
- after-task + Melissa plan-actual

FIRST SLICE: {S3,S4,S5} in parallel (day 1)

G0 LOCKS:
- Oracle: b4d5fee64def88bc768dda1f1f77c29b295edd86
- No §7 / true-parity / 0.7.1 port claim
- Thin wedge only — no θ-map implementation unless B is sole wedge and trust deferred
- Totoro: ≤30 min smoke only; D-139 for anything longer

STOP IF: scope creep to full catch-up · estimand question · foreign lease REFUSED

PLAN: docs/dev-log/plans/2026-09-05-parity-next-ultra-plan.md
UNLAZY: .unlazy/parity-next-20260905/
```

---

## DEFER

Full matched-coords tier · θ-map implementation (in 3-day box unless wedge B sole) · 0.7.1 surface · iSDM/spatial · traits parser · #1236 · true-parity §7 · 77-row forward closure.

---

*Phase 0–2 complete. SIZE answered. STOP AT G0.*
