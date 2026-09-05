# TRUE PARITY programme — decision map (2026-09-05)

**Extends** (does not replace) `docs/dev-log/core070/true-parity-decision-map.md` (2026-09-02 wayfinder map).  
**Purpose:** programme-level tickets for the **multi-month TRUE PARITY journey** after the 3-day parity-next package closed on main @ `a2e641de`.  
**Rule:** map tickets hold **questions**; build slices follow map clearance (ultra-plan Phase 0.6).

---

## Destination

**When this programme is done**, GLLVM.jl satisfies all seven clauses in the 2026-09-02 true-parity map **and** the owner has signed a **gate-tier row list** naming which ledger rows are required for the public **v0.true-parity** claim (expected **~30–50 rows**, not all 497).

Concretely, a maintainer can run representative **R workflows against frozen gllvmTMB 0.7.0** through Julia (native and/or bridge-eligible paths), obtain **first- and second-order** agreement at committed tolerances, pass **realistic-size** and **real-data** acceptance classes, and read a single page (`docs/src/gllvmtmb-parity.md`) that states what parity does **not** mean — **without** implying harness parity, FREE=0 ledger accounting, or 3/5 matched-coordinates pilot = programme §7 complete.

**Stopping condition:** programme decision map has **no open owner tickets**; gate-tier signed; Rose audit OK; **no** CRAN/Julia General release required as part of this destination.

**Not the destination:** closing all ~122 `BLOCKED_NEEDS_JULIA_SURFACE` rows unless owner promotes them into gate-tier in Q3.

---

## Decisions so far

*(Inherited from `true-parity-decision-map.md` — full table there. Programme-relevant highlights only.)*

| Decision | Answer | Recorded |
|---|---|---|
| Programme vs harness | Fixture + real-workflow = true parity; harness alone insufficient | `true-parity-decision-map.md` §Destination |
| Qualification direction | One-way R→Julia @ 0.7.0; reverse = tool list to R lane | T1; D-204 |
| Oracle (pending reconfirm) | Frozen 0.7.0 `b4d5fee6`; re-freeze after second-order contract | T2 |
| Second-order scope | SE + fixed-effect vcov + Wald endpoints; not fitted/predict/residuals | T3 |
| Grouping levels | Four names required on both sides; Julia surfaces mostly owed | T12; D6 |
| One Cursor lane | D-220; campaigns on Totoro/DRAC, not in chat | vault D-220 |
| 3-day package DONE | Trust fences, §7 NOT DONE fence, ACC thin scout — **not true parity** | `2026-09-05-parity-next-ultra-plan.md`; main @ `a2e641de` |
| Ledger snapshot | FORWARD≈77 · REVERSE≈85 @ `b4d5fee6` | `gllvmtmb-parity.md`; check-log 2026-09-05 |

---

## Not yet specified — programme tickets

Each line is a **map ticket** (decide / research / prototype). Default = Ada recommendation if Shinichi says "use your judgment".

### P1 — Destination ref: 0.7.0 oracle vs 0.7.1+ live surface

- **Question:** Does v0.true-parity qualify against **only** frozen 0.7.0, or also require 0.7.1 Class-1 exports (`traits()`, `column_coef`, …)?
- **Who:** decide-with-Shinichi
- **Default:** 0.7.0 for claim; 0.7.1+ on separate catch-up board until promoted
- **Blocks:** gate-tier row pick (P3), public wording

### P2 — Bridge width and bridge-eligible rows

- **Question:** Which ledger rows must pass via `engine = "julia"` bridge vs native Julia only?
- **Who:** research → decide-with-Shinichi
- **Default:** tag bridge-eligible in ledger; no bridge row without ACC-class receipt
- **Blocks:** M3 surface arc ordering

### P3 — Gate-tier row list (~30–50 for v0.true-parity)

- **Question:** Which `required_core` rows are **must-have** vs compatibility disposition?
- **Who:** decide-with-Shinichi (Fisher + Pat input)
- **Default:** paired second-order families + four grouping levels + one real-data repo per major family class
- **Blocks:** all build slicing

### P4 — Second-order tolerances (T3 closure)

- **Question:** Adopt draft rtol/abs in `second-order-parity-contract.md` or tighten?
- **Who:** decide-with-Shinichi after contract reread
- **Default:** adopt draft; record conditioning, not gate
- **Blocks:** M2 realistic-size grid

### P5 — Matched-coordinates tier (§7)

- **Question:** Implement θ-map for beta/NB2 and pursue matched tier, or demote v0.true-parity to each-own-optimum-only?
- **Who:** prototype (θ-map spec) → decide-with-Shinichi
- **Default:** 2-week research ticket; owner chooses at end
- **Blocks:** second-order programme completion claim

### P6 — Realistic-size grid (T4)

- **Question:** First (p, n, family) cells and host?
- **Who:** decide-with-Shinichi after se=TRUE timing
- **Default:** Gaussian, Poisson, NB2 at p∈{20,50}, n∈{500,2000} on Totoro
- **Blocks:** M2 campaigns

### P7 — Real-data repos (T7)

- **Question:** Order of four Ayumi repos; data access?
- **Who:** decide-with-Shinichi
- **Default:** urbanisation_map first (ACC receipt exists), then avian_trait_scales
- **Blocks:** M4

### P8 — AGHQ bind (T8)

- **Question:** Strategy for 14 bindable `BLOCKED_SPEC_DEFECT` AGHQ rows?
- **Who:** research + decide
- **Default:** defer AGHQ from v0.true-parity gate-tier unless owner promotes
- **Blocks:** AGHQ receipts only

### P9 — Promotion authority (T9)

- **Question:** Rose draft PR sufficient to flip disposition, or maintainer sentence each?
- **Who:** decide-with-Shinichi
- **Default:** draft PR + Rose = proposal; maintainer merge = sign-off

### P10 — Phylo transport Q1–Q4

- **Question:** Unanswered phylo design questions
- **Who:** decide-with-Shinichi
- **Default:** defaults in `phylo-transport-questions-2026-09-02.md`
- **Blocks:** phylo structured dependence arc

### P11 — traits() / column_coef / 0.7.1 Class-1

- **Question:** Port, bridge-only, or disposition as R-only compatibility?
- **Who:** decide-map-only (four-section sub-map)
- **Default:** change-control — not in 0.7.0 true-parity claim
- **Blocks:** formula recognizer programme

### P12 — Compute envelope

- **Question:** Totoro vs DRAC split for multi-seed recovery and realistic-size grids
- **Who:** decide-with-Shinichi
- **Default:** Totoro-first; DRAC when estimate >30 min smoke or grid >10k fits (D-139)
- **Blocks:** campaign launches

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

The programme map is **cleared** when: P1–P12 each have a recorded answer (or explicit defer with owner sign-off); P13 scheduled; Rose scans programme + 2026-09-02 maps for contradiction; ultra-plan Phase 1 slice list written from cleared tickets.

**Next hand-off:** `/goal` map-clearance arc → then first **build** arc (likely M2 second-order or gate-tier surface — chosen after P3).
