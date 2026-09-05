# TRUE PARITY — ultra-plan (Phase 0–2, STOP AT G0)

**Authored:** 2026-09-05 · Ada · Cursor one-lane (D-220)  
**Worktrees:** JL `~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904` · R `~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904` (read-only; no engine surgery)  
**Oracle (current):** frozen gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`  
**Main @ sweep:** `a2e641de` (Option D + parity-next 3-day package merged)  
**Status:** **MAP CLEARANCE CLOSED 2026-09-05 (M0-1…M0-10)** — G0 locked; Rose OK-with-owner-signoffs; first build arc awaits owner pick + gate-tier sign-off

---

```
🎯 GOAL
Solo platform: Cursor (one orchestrator lane, both twins in workspace — D-220)
Deliverable: TRUE PARITY programme plan + cleared decision map + wayfinder ladder — Phase 1 build waits on map clearance and owner G0
HEADLINE: Months-long journey — lock destination (oracle vs surface, bridge width, must-have rows) before any true-parity claim or bulk port
IN PARALLEL: After G0 — decision tickets only (decide / research / prototype); no production code in map-clearance arc
DEFER: Full 122-surface catch-up · traits/iSDM/spatial/column_coef engines · matched-coords implementation · multi-seed Totoro campaigns · gllvmTMB engine edits · true-parity public claim
DISCIPLINE: verify=unlazy gates on map leaves · compute=Totoro/DRAC after D-139 estimate (campaigns never in Cursor chat) · closure=map cleared + owner sign-off on destination, then `/goal` for first build arc
```

**Lane taken:** `cursor/true-parity-ultra-plan-20260905` — **docs + decision map only**.  
**Do not touch:** 14 other live lanes on GLLVM.jl (parity-next, Option D, direct-to-main); gllvmTMB engine (#1236 and siblings) — read-only reference.

**Companion artifacts:**

| Artifact | Path |
|---|---|
| Programme decision map (extends 2026-09-02 map) | `docs/dev-log/core070/true-parity-programme-decision-map-2026-09-05.md` |
| Wayfinder-compatible milestone ladder | `docs/dev-log/plans/2026-09-05-true-parity-wayfinder.md` |
| Map-clearance acceptance ledger | `.unlazy/true-parity-programme/GATES.md` (gitignored run state) |
| Prior true-parity map — Julia (cited, not replaced) | `docs/dev-log/core070/true-parity-decision-map.md` |
| Prior true-parity map — R twin (read-only) | `docs/dev-log/2026-09-02-true-parity-decision-map-gllvmtmb.md` |
| Wayfinder scout brief (no standalone skill) | `~/local-scratch/true-parity-wayfinder-brief-20260905.md` |
| Prior 3-day plan (DONE — do not replan) | `docs/dev-log/plans/2026-09-05-parity-next-ultra-plan.md` |

---

## SIZE & FEASIBILITY (honest)

True parity is **months**, not weeks. The 3-day parity-next package (trust fences + thin ACC scout) was **harness honesty**, not true parity.

| Milestone | Calendar band | Agent-days (low–high) | What it means |
|---|---|---:|---|
| **M0 — destination lock** | ~2–4 weeks | 3–8 | Owner answers: oracle pin, bridge width, must-have ledger rows, compute envelope |
| **M1 — map clearance** | ~1 month (includes M0) | 8–15 | All programme tickets decided or dispositioned; no fog without a ticket |
| **M2 — second-order programme** | ~2–3 months | 25–45 | Contract signed; toy + realistic-size receipts; θ-map for matched tier |
| **M3 — surface catch-up** | ~4–8 months | 60–120 | ~122 `BLOCKED_NEEDS_JULIA_SURFACE` rows + grouping levels + phylo transport |
| **M4 — real-data workflows** | ~1–2 months | 15–30 | Four Ayumi repos end-to-end through `engine = "julia"` |
| **M5 — v0.true-parity sign-off** | ~2–4 weeks | 8–15 | Rose audit + maintainer sentence; **not** a CRAN/Julia General release |

**Combined honest envelope:** **~9–18 calendar months**, **~120–230 agent-days**, with 2–4 parallel workers and Totoro/DRAC for campaigns (D-50, D-139, D-220).

**Intermediate milestones (not "done"):**

| Tag | Meaning |
|---|---|
| `v0.harness-parity` | Toy fixtures + ledger accounting (largely done; FREE=0 ≠ true parity) |
| `v0.second-order-pilot` | Each-own-optimum + partial matched batch (3/5 pilot — done, not programme §7) |
| `v0.bridge-thin` | One ACC real-data scout (urbanisation_map — done in parity-next wedge A) |
| `v0.true-parity` | All seven destination clauses in `true-parity-decision-map.md` + signed dispositions |

**Possible?** **Yes — with destination lock first**, frozen-oracle discipline, no gllvmTMB engine surgery from this lane, and campaigns on Totoro/DRAC rather than in Cursor.

---

## Phase 0 receipts

### 0.2 Lane preflight

```
─── LANE PRE-FLIGHT · GLLVM.jl · last 12h ───
 ME              : cursor   (foreign = claude codex · a 2nd cursor lane counts too)
 ON BRANCH       : claude/jl-bridge-capabilities-20260619
 origin/main     : 11 commit(s) in last 12h — **direct-to-main LIVE LANE**
 LANE CENSUS     : ** 14 LANES LIVE ** (incl. cursor/parity-next-*, cursor/option-d-*)
 COORD BOARD     : docs/dev-log/coordination-board.md — COMMITTED ✅
 VERDICT         : ** FOREIGN LANE ACTIVE (direct-to-main) **
                   AND 12 live cursor lane(s) besides you
 STATE THIS LINE : PLATFORM: cursor | ON BRANCH: cursor/true-parity-ultra-plan-20260905 | LANE: true-parity-programme-plan
                   OTHER LANES: 14x cursor + direct-to-main
```

**Lane claim:** planning/docs only on `cursor/true-parity-ultra-plan-20260905`; no overlap with parity-next or Option D file paths.

### 0.25 Prior-work sweep receipt

| Surface | Evidence | Finding | Call |
|---|---|---|---|
| **Repo git** | `git fetch origin main`; HEAD `a2e641de`; `git worktree list` | Option D + parity-next 3-day **DONE on main** (#287–#290); twin @ `a2e641de` | **Reuse** — do not replan trust fences, §7 fence, wedge A ACC scout |
| **Twin / sister** | R twin read-only; `tools/parity_ledger.py --ref b4d5fee6` | FORWARD≈77 · REVERSE≈85; 122 Julia surfaces blocked | **Build-the-gap** scoped to programme map, not ad-hoc port |
| **Brain** | `grep true-parity memory/DECISIONS.md`; D-220, D-204 | One Cursor lane; campaigns on Totoro; capability both ways, claim one way | **Reuse** decisions; programme fog still open |
| **Deterministic grep** | `grep -in "Option D\|parity-next\|true-parity" memory/AGENT_LOG.md \| tail -20` | 2026-09-05 parity-next closeout; 2026-09-02 true-parity maintainer decisions landed | **Resume** from map, not from zero |
| **Verdict** | — | 3-day package closed; true parity = **new multi-month programme** starting with **map clearance** | **Map first, then slices** |

**Explicitly NOT replanned:** Option D twin-trust bundle; parity-next S4/S5 §7 fence; advisory smoke disposition; matched-coords 3/5 pilot; urbanisation_map ACC thin scout.

### 0.3 / 0.3b Model roster

Cursor planning surface. Two-bar: Cursor Models preferred for scouts; judgment on Auto Cost when needed; live R/Julia toolchain proof is **first build arc after map**, per D-220 caveat.

### 0.6 Route check — **DECISION MAP FIRST**

| Question | Answer |
|---|---|
| 1. Destination in one sentence? | **Partially** — seven clauses exist in `true-parity-decision-map.md`, but **oracle vs 0.7.1 surface**, **bridge width**, and **must-have row set** are still owner-fog → **extend map** |
| 2. Slice list has TBD/depends? | **Yes** — θ-map, traits, grouping levels, AGHQ bind, promotion authority all block decomposition → **map** |
| 3. Every slice has concrete file output? | **No** — build slices wait on decisions → **map tickets only in Phase 1** |

**Verdict:** Phase 1 = **decision-map clearance arc**; normal slice list follows M1.

---

## Phase 0.4 — G0 questions — **LOCKED**

**Owner answers 2026-09-05:** Shinichi locked **1–5 = yes** (Ada defaults). Record:

| # | Decision | Lock |
|---|----------|------|
| 1 | Oracle | Frozen **0.7.0** for qualification; **0.7.1+** on a separate catch-up board |
| 2 | Bridge | **Tiered** — thin JuliaCall for ACC-class; native Julia elsewhere |
| 3 | Must-have | ~**30–50** gate-tier rows for v0.true-parity (not all 497) |
| 4 | Compute | **Totoro-first**; DRAC by approval when estimate warrants |
| 5 | Matched-coords (§7) | θ-map **research first**, then owner chooses implement vs demote |

Each item below still carries Ada's recommendation for audit trail.

### Q1 — Destination oracle: frozen 0.7.0 vs live 0.7.1+ surface?

**WHY NOW:** T2 locked 0.7.0 for qualification; R `main` has moved (column_coef, traits, ordinal_logit, ZI, …). True-parity destination must name which R ref the claim runs against.

**TEAM VIEW**

- Fisher — Qualification against a **frozen build** is auditable; chasing live `main` moves the goalpost.
- Rose — Public docs already fence 0.7.1 Class-1 as change-control; mixing refs will confuse the scoreboard.
- Ada — **Recommend:** keep **0.7.0 frozen oracle for the qualification claim**; track 0.7.1+ as a **separate catch-up ledger** with explicit promotion rows. Re-freeze gate after second-order contract (T2, unchanged).

**IF YOU DO NOT MIND:** frozen 0.7.0 oracle + parallel 0.7.1 catch-up board (not merged into true-parity claim until owner promotes).

### Q2 — Bridge strategy: thin JuliaCall vs widen vs native-Julia-first?

**WHY NOW:** Bridge is `partial` (11 families, unit-tier); true parity needs real workflows (#1236 expansion is R-side, read-only here).

**TEAM VIEW**

- Hopper — One-way R→Julia bridge stays; reverse list is R lane's job (T1).
- Gauss — Widening bridge without θ-map and grouping levels repeats ACC-class failures.
- Ada — **Recommend:** **tiered bridge** — (a) keep thin bridge for ACC-class workflows; (b) native Julia surfaces for rows bridge cannot honestly carry; (c) no claim that bridge = full engine.

**IF YOU DO NOT MIND:** tiered bridge + explicit "bridge-eligible row" tag in ledger.

### Q3 — Must-have surface for v0.true-parity vs defer?

**WHY NOW:** ~122 blocked rows; all required_core in spreadsheet ≠ all user-facing must-have.

**TEAM VIEW**

- Darwin — Real-data workflows (T7) matter more than exporting every helper.
- Pat — Users need predict/summary and grouping levels before exotic families.
- Ada — **Recommend:** **three-tier ledger** — (1) **gate** rows for v0.true-parity (owner picks ~30–50); (2) **compatibility** rows dispositioned not built; (3) **beyond** Julia-forward only.

**IF YOU DO NOT MIND:** gate tier = second-order paired families + grouping four levels + one real-data repo per family class; rest dispositioned.

### Q4 — Compute budget envelope?

**WHY NOW:** Multi-seed recovery and realistic-size grids are campaign-shaped (D-50, D-139).

**TEAM VIEW**

- Grace — GitHub Actions barred for campaigns.
- Ada — **Recommend:** Totoro default; DRAC when grid > ~10k fits or GPU parity; estimate every campaign before launch; cap Cursor chat at smoke ≤30 min.

**IF YOU DO NOT MIND:** Totoro-first, DRAC by approval, no campaign artifacts on GitHub.

### Q5 — Programme §7 / matched-coordinates: implement θ-map or demote tier?

**WHY NOW:** 3/5 pilot pass; beta_logit + nb2_log θ-blocked.

**IF YOU DO NOT MIND:** decision ticket first — prototype θ-map spec (2 weeks research), then owner chooses implement vs stay each-own-optimum-only for v0.true-parity.

---

## PRE-AUTHORISED AFTER G0 (map-clearance arc only)

```
PRE-AUTHORISED AFTER G0: docs/decision-map edits on cursor/true-parity-ultra-plan-20260905;
  local git commit; parity_ledger.py read-only runs; unlazy gate checks; brain MCP reads.
OPTIONAL REMOTE AUTHORITY: push branch; open/update draft PR for plan docs (no merge).
MUST STOP: merge to main; any src/ or test/ production code; gllvmTMB edits; true-parity public claim;
  Totoro/DRAC campaign without estimate + smoke; scope beyond map-clearance without new G0.
```

---

## Phase 1 — Map-clearance slices (post-G0; tickets not builds)

| ID | Ticket | Kind | Output path | Dep | Status |
|---|---|---|---|---|---|
| **M0-1** | Lock destination paragraph (oracle, bridge, tiers) | decide-with-Shinichi | §Destination in programme map | G0 Q1–Q3 | **CLOSED** 2026-09-05 |
| **M0-2** | Sign second-order tolerances (T3) | decide-with-Shinichi | `second-order-parity-contract.md` amendment | G0 | **CLOSED** 2026-09-05 |
| **M0-3** | Gate-tier row pick (~30–50) | decide-with-Shinichi | `docs/dev-log/core070/true-parity-gate-tier-2026-09-05.md` | M0-1 | **CLOSED** PROPOSED 2026-09-05 — sign-off pending |
| **M0-4** | θ-map disposition (implement vs demote matched tier) | decide + optional prototype | `docs/dev-log/core070/theta-map-disposition-2026-09-05.md` | M0-2 | **CLOSED** research-scheduled 2026-09-05 |
| **M0-5** | Bridge-eligible row tag | research | `bridge-eligible-row-tag-design-2026-09-05.md` (doc only) | M0-1 | **CLOSED** design note 2026-09-05 |
| **M0-6** | Phylo Q1–Q4 | decide-with-Shinichi | `phylo-transport-questions-2026-09-02.md` | — | **CLOSED** Ada-default pending override 2026-09-05 |
| **M0-7** | T9 promotion authority | decide-with-Shinichi | one paragraph in programme map | — | **CLOSED** 2026-09-05 |
| **M0-8** | AGHQ T8 bind strategy | research + decide | `t8-aghq-bind-next-slice.md` §Gate-tier disposition | — | **CLOSED** defer from gate-tier 2026-09-05 |
| **M0-9** | traits / column_coef / 0.7.1 Class-1 | decide-map-only | four-section map in programme file | M0-1 | **CLOSED** 2026-09-05 |
| **M0-10** | Rose scan of cleared map | review | after-task + PR body | M0-1..9 | **CLOSED** OK-with-owner-signoffs 2026-09-05 |

**Parallel after G0:** M0-3…M0-8 closed in parallel slices. **Sequential:** M0-1 before M0-3, M0-5, M0-9; M0-10 integrator closeout.

---

## Phase 2 — Plan metadata

```
SLICE TABLE: see Phase 1 (map tickets only)
FAN-OUT: 0–2 scouts post-G0 (ledger read, θ-map research) — no build fan-out until M1
ESTIMATE: map-clearance arc ~3–6 weeks calendar · 8–15 agent-days
PREFLIGHT: pasted above · LANE: cursor/true-parity-ultra-plan-20260905
REVIEW: Rose — plan + map consistency before merge
VERIFY: unlazy GATES.md on map leaves · Rose pre-merge
RECONCILE: Melissa after map-clearance arc closes
SCOUT SUITABILITY: yes — parity_ledger read + brain grep on Cursor Models
```

---

## Wayfinder ladder (summary)

Full ladder: `docs/dev-log/plans/2026-09-05-true-parity-wayfinder.md` (**wayfinder-compatible; skill absent**).

| Milestone | Name | Rough months from G0 |
|---|---|---|
| M0 | Destination lock | 0–1 |
| M1 | Map clearance | 1 |
| M2 | Second-order programme | 2–4 |
| M3 | Surface + bridge catch-up | 5–12 |
| M4 | Real-data workflows | 10–14 |
| M5 | v0.true-parity sign-off | 12–18 |

---

## G0 LOCKED — map-clearance arc **CLOSED 2026-09-05**

Map tickets M0-1…M0-10 closed. **Do not start Phase 3 engine work** until owner picks first build arc and (recommended) signs gate-tier list.

---

## Paste-ready `/goal` (map-clearance arc — G0 locked)

```
/goal GLLVM.jl true-parity map-clearance (NOT build)

G0 LOCKED 2026-09-05 (Shinichi 1–5 yes):
1. Oracle = frozen gllvmTMB 0.7.0 (b4d5fee6) for qualification; 0.7.1+ separate catch-up board
2. Bridge = tiered (thin JuliaCall ACC-class + native Julia elsewhere)
3. Must-have ≈ 30–50 gate-tier rows for v0.true-parity (not all 497)
4. Compute = Totoro-first; DRAC by approval (D-50 / D-139)
5. Matched-coords = θ-map research first, then owner choose implement vs demote

Read first:
- docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md
- docs/dev-log/core070/true-parity-programme-decision-map-2026-09-05.md
- docs/dev-log/core070/true-parity-decision-map.md (cite; don't contradict)
- docs/dev-log/plans/2026-09-05-true-parity-wayfinder.md
- Vault D-220, D-204, D-50, D-139

Branch: cursor/true-parity-ultra-plan-20260905 (PR #291) or fresh off origin/main after merge
Worktree: ~/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904
R twin: ~/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904 (READ-ONLY — no engine surgery)

SCOPE (map-clearance ONLY):
- Close tickets M0-1 … M0-10 in the ultra-plan
- Update programme + twin decision maps in place
- NO production code in src/ or test/
- Unlazy: .unlazy/true-parity-programme/
- Draft/update PR for docs; do not merge without Shinichi unless he says so
- After-task when arc closes

DEFER: Julia/R engine implementation, campaigns, true-parity public claim, traits parser, full 122-row port, #1236 build

DISCIPLINE: lane_preflight; stage by path; never git add -A
```
