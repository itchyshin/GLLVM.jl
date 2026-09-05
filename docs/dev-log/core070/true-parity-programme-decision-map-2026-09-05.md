# TRUE PARITY programme — decision map (2026-09-05)

**Extends** (does not replace) the live twin maps:
- Julia: `docs/dev-log/core070/true-parity-decision-map.md` (2026-09-02)
- R: `docs/dev-log/2026-09-02-true-parity-decision-map-gllvmtmb.md` (read-only reference)

**Wayfinder:** no standalone `/wayfinder` skill — rules live in `~/shinichi-brain/skills/ultra-plan/SKILL.md` §Decision map + Phase 0.6; scout brief at `~/local-scratch/true-parity-wayfinder-brief-20260905.md`.

**Purpose:** programme-level tickets for the **multi-month TRUE PARITY journey** after the 3-day parity-next package closed on main @ `a2e641de`.  
**Rule:** map tickets hold **questions**; build slices follow map clearance (ultra-plan Phase 0.6).

---

## Destination — **LOCKED 2026-09-05 (G0; M0-1)**

**Oracle:** frozen gllvmTMB **0.7.0** commit `b4d5fee64def88bc768dda1f1f77c29b295edd86` for the
qualification claim. R `0.7.1+` surfaces (`traits()`, `column_coef`, …) live on a **separate
catch-up board** — not merged into v0.true-parity until owner promotes (see §0.7.1 Class-1).

**Bridge:** **tiered** — thin JuliaCall for ACC-class real workflows; native Julia for rows the
bridge cannot honestly carry. Bridge-eligible rows require ACC-class receipts (**P2 CLOSED**;
design note `bridge-eligible-row-tag-design-2026-09-05.md`, M0-5).

**Must-have rows:** **~30–50 gate-tier** rows for v0.true-parity (not all 497). **42 rows
PROPOSED** at `true-parity-gate-tier-2026-09-05.md` — **maintainer sign-off pending** (P3
CLOSED as drafted; signed gate-tier still owed).

**Compute:** **Totoro-first**; DRAC by maintainer approval when estimate warrants (D-50 / D-139).
Cursor chat capped at smoke ≤30 min; campaigns never block the lane (D-220).

**Matched-coordinates (§7):** **θ-map research first** (2-week ticket `RESEARCH-THETA-MAP-20260905`);
owner then chooses implement vs demote matched tier (**P5 CLOSED** as research-scheduled;
`theta-map-disposition-2026-09-05.md`). Each-own-optimum remains the shipped claim tier until
research completes and owner decides.

**When this programme is done**, GLLVM.jl satisfies all seven clauses in the 2026-09-02
true-parity map **and** the owner has signed the gate-tier row list above.

Concretely, a maintainer can run representative **R workflows against frozen 0.7.0** through
Julia (native and/or bridge-eligible paths), obtain **first- and second-order** agreement at
committed tolerances (`second-order-parity-contract.md`, signed M0-2), pass realistic-size and
real-data acceptance classes, and read `docs/src/gllvmtmb-parity.md` stating what parity does
**not** mean — **without** implying harness parity, FREE=0 ledger accounting, or 3/5
matched-coordinates pilot = programme §7 complete.

**Stopping condition:** programme decision map has **no open owner tickets**; gate-tier signed;
Rose audit OK; **no** CRAN/Julia General release required.

**Not the destination:** closing all ~122 `BLOCKED_NEEDS_JULIA_SURFACE` rows unless owner
promotes them into gate-tier; 0.7.1 Class-1 formula grammar (§0.7.1 Class-1 below).

---

## Decisions so far

*(Inherited from `true-parity-decision-map.md` — full table there. Programme-relevant highlights only.)*

| Decision | Answer | Recorded |
|---|---|---|
| Programme vs harness | Fixture + real-workflow = true parity; harness alone insufficient | `true-parity-decision-map.md` §Destination |
| Qualification direction | One-way R→Julia @ 0.7.0; reverse = tool list to R lane | T1; D-204 |
| Oracle | Frozen **0.7.0** `b4d5fee6` for qualification; **0.7.1+** separate catch-up board | **G0 2026-09-05**; **P1 CLOSED** (M0-1) |
| Bridge | **Tiered** — thin JuliaCall ACC-class; native Julia elsewhere; bridge-eligible tag in ledger | **G0 2026-09-05**; **P2 CLOSED** (M0-1) |
| Gate-tier size | ~**30–50** must-have rows; **42 PROPOSED** — signed list pending owner | **G0 2026-09-05**; **P3 CLOSED** drafted (M0-3); `true-parity-gate-tier-2026-09-05.md` |
| Compute | **Totoro-first**; DRAC by approval (D-50 / D-139) | **G0 2026-09-05**; **P12 CLOSED** (M0-1) |
| Matched-coords (§7) | θ-map **research first**; then owner choose implement vs demote | **G0 2026-09-05**; **P5 CLOSED** research-scheduled (M0-4); `theta-map-disposition-2026-09-05.md` |
| Bridge-eligible tag | Tiered bridge + proposed `bridge_eligible` ledger field | **P2 CLOSED** design (M0-5); `bridge-eligible-row-tag-design-2026-09-05.md` |
| Realistic-size grid (T4) | Gaussian, Poisson, NB2; p∈{20,50}, n∈{500,2000}; Totoro | **P6 CLOSED** Ada-default (M0-10); D-139 pre-run before campaigns |
| Real-data order (T7) | `urbanisation_map` first, then `avian_trait_scales` | **P7 CLOSED** Ada-default (M0-10) |
| AGHQ bind (T8) | Defer AGHQ from v0.true-parity gate-tier unless owner promotes | **P8 CLOSED** (M0-8); `t8-aghq-bind-next-slice.md` §Gate-tier disposition |
| Phylo transport Q1–Q4 | Ada defaults recorded; pending owner override | **P10 CLOSED** Ada-default (M0-6); `phylo-transport-questions-2026-09-02.md` |
| Second-order tolerances | Adopt draft rtol/abs; **conditioning recorded, not gated** | **SIGNED 2026-09-05**; **P4 CLOSED** (M0-2); `second-order-parity-contract.md` |
| Promotion authority (T9) | **Draft PR + Rose scan = proposal**; **maintainer merge = sign-off** | **2026-09-05**; **P9 CLOSED** (M0-7) |
| 0.7.1 Class-1 surfaces | **Change-control** — not in 0.7.0 true-parity claim | **2026-09-05**; **P11 CLOSED map-only** (M0-9); §0.7.1 below |
| Second-order scope | SE + fixed-effect vcov + Wald endpoints; not fitted/predict/residuals | T3 |
| Grouping levels | Four names required on both sides; Julia surfaces mostly owed | T12; D6 |
| One Cursor lane | D-220; campaigns on Totoro/DRAC, not in chat | vault D-220 |
| 3-day package DONE | Trust fences, §7 NOT DONE fence, ACC thin scout — **not true parity** | `2026-09-05-parity-next-ultra-plan.md`; main @ `a2e641de` |
| Ledger snapshot | FORWARD≈77 · REVERSE≈85 @ `b4d5fee6` | `gllvmtmb-parity.md`; check-log 2026-09-05 |

---

## Promotion authority (T9 / P9) — **CLOSED 2026-09-05 (M0-7)**

A row disposition flip or gate-tier promotion requires:

1. **Proposal:** a **draft PR** with evidence paths cited; **Rose pre-publish scan** = proposal
   (consistency of claim vs receipt, no overclaim on user-facing surfaces).
2. **Sign-off:** **maintainer merge** of that PR = owner sign-off. No separate sentence required
   per row when the PR body enumerates rows and Rose verdict.

Ad-hoc chat approval does **not** flip ledger dispositions. Emergency revert remains maintainer
authority outside this rule.

---

## 0.7.1 Class-1 — change-control sub-map (M0-9 / P11)

**Verdict:** R `0.7.1+` Class-1 exports are **not in the 0.7.0 true-parity claim.** They live on
a **separate catch-up board** until owner promotes rows into gate-tier. Detail:
`docs/dev-log/core070/gllvmtmb-071-gap-sheet.md`.

### §1 — Scope boundary

| In v0.true-parity (0.7.0 oracle) | On 0.7.1 catch-up board only |
|---|---|
| Long-format `gllvmTMB()` grammar GLLVM.jl already pairs | `traits()` wide-data LHS |
| Frozen 0.7.0 export surface @ `b4d5fee6` | `column_coef()`, `*_coef`, `slope`, `*_slope` family |
| Matrix / explicit long-format Julia entry points | `gllvmTMB(..., column_data = NULL)` path |
| Existing bridge families (6 receipted + extensions per gate-tier) | iSDM / spatial / column-coefficient TMB gates |

### §2 — Disposition default (until catch-up arc)

| Surface class | Default disposition | Julia action |
|---|---|---|
| `traits()` wide grammar | **R-only compatibility** | No port in true-parity programme; optional later formula arc |
| Response-column coefficient family (`column_coef`, `phylo_coef`, …) | **R-only compatibility** | No Julia `@formula` counterpart; track on catch-up board |
| `column_data` argument | **Untracked / compatibility** | Not in frozen oracle call shapes |
| Class-2 interval claim rewrite (0.7.1) | **Docs hygiene only** | Check GLLVM.jl cites of old R coverage wording |

### §3 — Promotion path

Owner may promote individual Class-1 rows into gate-tier via T9 rule (draft PR + Rose + merge).
Re-freeze oracle only after second-order contract + explicit owner call (T2 unchanged).

### §4 — Cross-reference

Programme map P1 (0.7.0-only claim) and this section are **consistent**: qualification runs
against `b4d5fee6`; 0.7.1 surfaces are explicitly fenced.

---

## Closed programme tickets (map-clearance arc 2026-09-05)

**Spine (M0-1/2/7/9):** P1, P2 (bridge width), P4, P9, P11, P12 — see Decisions so far.

**Parallel leaves (M0-3…M0-8):**

| Ticket | Status | Leaf file |
|---|---|---|
| **P3** Gate-tier row list | **CLOSED — PROPOSED** (42 rows); **maintainer sign-off pending** for *signed* gate-tier | `true-parity-gate-tier-2026-09-05.md` |
| **P5** Matched-coordinates (§7) | **CLOSED — research-scheduled**; implement vs demote deferred to end of `RESEARCH-THETA-MAP-20260905` | `theta-map-disposition-2026-09-05.md` |
| **P6** Realistic-size grid (T4) | **CLOSED — Ada-default** | this file §P6 below |
| **P7** Real-data repos (T7) | **CLOSED — Ada-default** | this file §P7 below |
| **P8** AGHQ bind (T8) | **CLOSED — defer from gate-tier** | `t8-aghq-bind-next-slice.md` §Gate-tier disposition |
| **P10** Phylo transport Q1–Q4 | **CLOSED — Ada-default pending override** | `phylo-transport-questions-2026-09-02.md` |
| **P2** Bridge-eligible tag (design) | **CLOSED — design note** | `bridge-eligible-row-tag-design-2026-09-05.md` |

### P6 — Realistic-size grid (T4) — **CLOSED Ada-default**

- **Answer:** Gaussian, Poisson, NB2 at **p ∈ {20, 50}**, **n ∈ {500, 2000}** on **Totoro**; one
  pre-run cell per family first (D-139 estimate before full grid).
- **Blocks:** M2 campaigns only — not map clearance.

### P7 — Real-data repos (T7) — **CLOSED Ada-default**

- **Answer:** **`urbanisation_map` first** (thin ACC scout receipt exists), then
  **`avian_trait_scales`**, then `nest_morpho_gllvm`, then `BIRDBASE_pcm` per gate-tier table C1–C4.
- **Blocks:** M4 — not map clearance.

---

## Open programme tickets

Default = Ada recommendation if Shinichi says "use your judgment".

### P13 — Mechanical guard for one-lane twin (D-220 caveat)

- **Question:** `--r-ref` defaulting to `origin/main` for parity tools — implement when?
- **Who:** task (small tool patch) after map clearance
- **Default:** before first build arc that reads R working tree
- **Blocks:** honest CLOSURE lines in one-lane workspace

### Fog without a ticket yet

- Documenter / public API for v0.true-parity tag
- Julia General registration timing
- Interval *coverage* certification (explicitly out of parity — when separate programme?)
- Performance parity (M3 Poisson 0.45–0.80× R) as claim or non-goal?

---

## Out of scope

| Item | Reason |
|---|---|
| gllvmTMB engine surgery from GLLVM.jl lane | AGENTS.md hard boundary |
| Two-directional qualification claim | T1 / D-204 |
| fitted / predict / residuals as parity gate | T3 |
| Full ~122-row naive port in one programme | Owner gate-tier (P3) supersedes |
| CRAN / Julia General release | Separate ceremony |
| Interval coverage certification | Class-2 gap sheet; separate programme |
| Re-freeze at 0.7.1 **now** | T2 — wait for second-order contract |
| Production code during **map-clearance arc** | Map plans, does not build |

---

## Map clearance definition

**Status: CLEARED for map arc (2026-09-05, M0-10 Rose OK-with-owner-signoffs).**

The programme map is **cleared** when: P3, P5–P8, P10 each have a recorded answer (or explicit
defer with owner sign-off); P13 scheduled; P1/P2/P4/P9/P11/P12 **closed**; Rose scans programme +
2026-09-02 maps for contradiction; ultra-plan Phase 1 slice list complete.

**Remaining owner sign-offs (do not block map clearance; block v0.true-parity claim):**

| Item | State | Action to sign |
|---|---|---|
| Gate-tier row list | **PROPOSED** (42 rows) | Maintainer merge of Rose-scanned PR citing `true-parity-gate-tier-2026-09-05.md` (T9) |
| Phylo Q1–Q4 | **Ada-default pending override** | Owner may override any answer in `phylo-transport-questions-2026-09-02.md` without reopening G0 |
| θ-map implement vs demote | **Research open** | Owner chooses at end of `RESEARCH-THETA-MAP-20260905` (`theta-map-disposition-2026-09-05.md`) |

**Leaf cross-links:**

| M0 slice | Leaf |
|---|---|
| M0-3 / P3 | `true-parity-gate-tier-2026-09-05.md` |
| M0-4 / P5 | `theta-map-disposition-2026-09-05.md` |
| M0-5 / P2 design | `bridge-eligible-row-tag-design-2026-09-05.md` |
| M0-6 / P10 | `phylo-transport-questions-2026-09-02.md` |
| M0-8 / P8 | `t8-aghq-bind-next-slice.md` §Gate-tier disposition |
| M0-2 / P4 | `second-order-parity-contract.md` |
| M0-9 / P11 | §0.7.1 Class-1 above; `gllvmtmb-071-gap-sheet.md` |

**Next hand-off:** `/goal` first **build** arc (owner picks M2 second-order campaigns vs partial M3
surface — after gate-tier sign-off or explicit proceed-with-PROPOSED list).
