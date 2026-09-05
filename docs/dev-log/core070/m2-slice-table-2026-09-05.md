# M2 foundation — gate-tier row → build slice map (2026-09-05)

**Status:** DRAFT — M2 foundation day-1 (planning only; no receipts).  
**Branch:** `cursor/m2-foundation-day1-20260905`  
**Oracle:** frozen gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`  
**Basis:** 42 **SIGNED** gate-tier rows (`true-parity-gate-tier-2026-09-05.md`); programme map
`true-parity-programme-decision-map-2026-09-05.md`; wayfinder M2 gate
(`2026-09-05-true-parity-wayfinder.md` §M2); second-order contract
(`second-order-parity-contract.md`, SIGNED M0-2).

**Rule:** signed rows are **planning scope**, not covered. A row closes only when its slice
delivers a receipt at the committed shape and tolerance.

---

## Slice key

| Tag | Meaning |
|---|---|
| **2SO-harness** | Receipt fields + `se=TRUE` parity harness wiring |
| **2SO-toy** | Each-own-optimum batch-1 at toy shape (p≤5, n≤150) |
| **T4-pre** | D-139 pre-run — one realistic-size cell per family before full grid |
| **T4-grid** | Full P6 grid: Gaussian, Poisson, NB2; p∈{20,50}; n∈{500,2000} |
| **θ-map** | `RESEARCH-THETA-MAP-20260905` — parameter alignment + implement vs demote |
| **phylo** | Phylo transport Q1–Q4 build arc (`phylo-transport-design.md`) |
| **bridge** | JuliaCall ACC-class path + bridge-eligible tag receipts |
| **grp** | Four grouping-level Julia surfaces (`t12-grouping-levels-design.md`) |
| **extract** | User-facing predict/summary/vcov/confint parity |
| **RD** | Real-data eight-class acceptance workflow |

**Compute doctrine (D-220 / D-139):** campaigns on Totoro/DRAC; Cursor lane ≤30 min smoke;
estimate before launch; lane reads results asynchronously.

---

## Build slice table

| Slice id | Name | Bar | Est. | Gate-tier rows closed | Deps | Milestone |
|---|---|---|---|---|---|---|
| **M2-S0** | Slice table + T4 estimate (this doc) | docs | 0.5 d | — (meta) | M1 signed | M2 foundation |
| **M2-S1** | Second-order receipt harness | Julia | 3–5 d | enables all **2SO** rows | `second-order-parity-contract.md` §5 | M2 |
| **M2-S2** | Toy 2SO batch-1 each-own-optimum | Julia + R oracle | 2–4 d | A2†, A5†, A7†, D4†, D5† | M2-S1; toy fixtures exist | M2 |
| **M2-S3** | **T4 D-139 pre-run — Gaussian** | Totoro | 0.5 d | **A2** (partial RSZ), **A3** (partial) | M2-S1; estimate in `t4-totoro-estimate-2026-09-05.md` | M2 |
| **M2-S4** | T4 D-139 pre-run — Poisson + NB2 | Totoro | 1 d | A5†, A10† (partial RSZ) | M2-S3 receipt | M2 |
| **M2-S5** | T4 full grid (12 cells) | Totoro | 2–3 d | A2, A3, A5, A6, A10, A11†, A13† | M2-S4 pre-runs pass | M2 |
| **M2-R1** | θ-map research ticket | research | 8–12 d | unblocks A9, A11 matched tier | M0-4 open | M2 |
| **M2-R2** | Matched-coordinates tier (conditional) | Julia | 5–10 d | A9, A11 (2SO matched); programme §7 | M2-R1 owner decision | M2 |
| **M3-P1** | Phylo transport Q1–Q4 | Julia + bridge | 15–25 d | A14, A15; C4 prerequisite | `phylo-transport-questions-2026-09-02.md` | M3 |
| **M3-G1** | Grouping four levels | Julia | 10–15 d | B1–B4 | fit-input contracts | M3 |
| **M3-B1** | Bridge spine + ACC template | Julia + RCall | 5–8 d | D1, D6, D7, C5 | `bridge-eligible-row-tag-design-2026-09-05.md` | M3 |
| **M3-E1** | Extractors (predict/summary/vcov/confint) | Julia | 8–12 d | D2–D5 | M2-S1 (2SO extractors) | M3 |
| **M3-C1** | 1FO family + ordination receipts (remaining) | mixed | 5–10 d | A1, A4, A6, A8, A10, A12, A13 | M3-B1 for BRG rows | M3 |
| **M4-RD1** | Real-data — urbanisation_map full RD | Totoro + bridge | 5–8 d | C1 | M3-B1; thin ACC scout exists | M4 |
| **M4-RD2** | Real-data — avian_trait_scales | Totoro | 5–8 d | C2 | M4-RD1 pattern | M4 |
| **M4-RD3** | Real-data — nest_morpho + BIRDBASE | Totoro | 8–12 d | C3, C4 | M3-P1 for C4 | M4 |
| **M5-A1** | Gate-tier disposition sign-off + Rose audit | review | 3–5 d | all 42 rows evidenced or dispositioned | M2–M4 slices | M5 |
| **—** | Reverse gap disposition (R lane) | R twin | — | D8 | `tools/parity_ledger.py`; no Julia build | meta |

† = partial at toy or each-own-optimum only until T4-grid or θ-map resolves blockers.

**Parallel lanes (disjoint `OWNS:` where possible):** M2-R1 θ-map ∥ M2-S3/S4 T4 pre-runs ∥ M3-P1
phylo (after day-1 foundation). Do not parallel-edit shared harness files without lane check.

---

## Gate-tier row index (42 rows → primary slice)

### A — Paired second-order families (15)

| Row id | Tier | Route | Primary slice(s) | Blocker / note |
|---|---|---|---|---|
| A1 `family/GAUSSIAN-IDENTITY-1FO` | 1FO | NAT/BRG | M3-C1 | Existing toy + bridge receipts |
| A2 `family/GAUSSIAN-IDENTITY-2SO` | 2SO | NAT | **M2-S2 → M2-S3 → M2-S5** | **Day-1 target**; T4 pre-run first |
| A3 `family/GAUSSIAN-IDENTITY-RSZ` | RSZ | NAT | M2-S3 → M2-S5 | p∈{20,50}, n∈{500,2000} |
| A4 `family/POISSON-LOG-1FO` | 1FO | BRG | M3-C1 | Bridge receipt exists |
| A5 `family/POISSON-LOG-2SO` | 2SO | NAT | M2-S2 → M2-S4 → M2-S5 | |
| A6 `family/BINOMIAL-LOGIT-1FO` | 1FO | BRG | M3-C1 | |
| A7 `family/BINOMIAL-LOGIT-2SO` | 2SO | NAT | M2-S2 | Toy batch-1 pass (pilot 3/5) |
| A8 `family/BETA-LOGIT-1FO` | 1FO | BRG | M3-C1 | |
| A9 `family/BETA-LOGIT-2SO` | 2SO | NAT | M2-S2 → M2-R2 | θ-map blocked (matched-coords) |
| A10 `family/NB2-LOG-1FO` | 1FO | BRG | M3-C1 | |
| A11 `family/NB2-LOG-2SO` | 2SO | NAT | M2-S2 → M2-S4 → M2-R2 | θ-map blocked; boundary NaN risk |
| A12 `covariance/COV-ORD-LATENT-BARE-1FO` | 1FO | BRG | M3-C1 | |
| A13 `covariance/COV-ORD-LATENT-BARE-RSZ` | RSZ | BRG/NAT | M2-S5 | Realistic-size owed |
| A14 `covariance/COV-PHYLO-LATENT-1FO` | 1FO | NAT | M3-P1 | After phylo Q1–Q4 |
| A15 `covariance/COV-PHYLO-LATENT-RSZ` | RSZ | NAT | M3-P1 | |

### B — Grouping levels (4)

| Row id | Tier | Primary slice | Blocker |
|---|---|---|---|
| B1 `grouping-levels/UNIT-KWARG-NAME-PARITY` | GRP | M3-G1 | Julia surface owed |
| B2 `grouping-levels/UNIT-OBS-NONGAUSSIAN-KWARG` | GRP | M3-G1 | Beyond `TwoLevelFit` |
| B3 `grouping-levels/CLUSTER-THIRD-AXIS-KWARG` | GRP | M3-G1 | |
| B4 `grouping-levels/CLUSTER2-INDEP-KWARG` | GRP | M3-G1 | |

### C — Real-data workflows (5)

| Row id | Tier | Primary slice | Blocker |
|---|---|---|---|
| C1 `real-data/URBANISATION-MAP-RD` | RD | M4-RD1 | Full eight-class acceptance |
| C2 `real-data/AVIAN-TRAIT-SCALES-RD` | RD | M4-RD2 | P7 order: second repo |
| C3 `real-data/NEST-MORPHO-GLLVM-RD` | RD | M4-RD3 | |
| C4 `real-data/BIRDBASE-PCM-RD` | RD | M4-RD3 | M3-P1 phylo prerequisite |
| C5 `real-data/META-WORKFLOW-SMOKE` | RD | M3-B1 | End-to-end `engine="julia"` |

### D — Bridge spine + extractors (8)

| Row id | Tier | Primary slice | Blocker |
|---|---|---|---|
| D1 `bridge/ACC-CLASS-RECEIPT-TEMPLATE` | meta | M3-B1 | Design note landed |
| D2 `extractor/PREDICT-INSAMPLE-LINK` | 1FO | M3-E1 | Wave-7 measured |
| D3 `extractor/SUMMARY-FIXED-EFFECTS` | 1FO | M3-E1 | |
| D4 `extractor/VCov-FIXED-BLOCK` | 2SO | M2-S1 → M3-E1 | Pairs with 2SO contract |
| D5 `extractor/CONFINT-WALD-LINK` | 2SO | M2-S1 → M3-E1 | |
| D6 `fit-input/FIT-GAUSSIAN-CORE` | 1FO | M3-B1 | `fit-input-contract.md` |
| D7 `fit-input/FIT-LAPLACE-CORE` | 1FO | M3-B1 | Six dense-Laplace families |
| D8 `parity/REVERSE-GAP-DISPOSITION` | meta | R lane | Tool-produced |

---

## Dependency graph (build order)

```
M1 signed gate-tier
    │
    ├─► M2-S1 (2SO harness) ──► M2-S2 (toy 2SO)
    │         │
    │         └─► M2-S3 (T4 pre Gaussian) ──► M2-S4 (T4 pre Poisson/NB2)
    │                      │
    │                      └─► M2-S5 (T4 full grid)
    │
    ├─► M2-R1 (θ-map research) ──?──► M2-R2 (matched tier) ──► A9, A11 close
    │
    ├─► M3-P1 (phylo) ──► A14, A15, C4
    ├─► M3-G1 (grouping) ──► B1–B4
    ├─► M3-B1 (bridge) ──► D1, D6, D7, C5, BRG 1FO rows
    ├─► M3-E1 (extractors) ──► D2–D5
    │
    └─► M4-RD* (real-data) ──► C1–C5 ──► M5-A1 (sign-off)
```

**Critical path for second-order programme (M2 done-when):** M2-S1 → M2-S3 → M2-S5, with M2-R1
running in parallel but not blocking each-own-optimum tier.

---

## Day-1 target (2026-09-05)

**Scope:** docs + D-139 estimate only — **no Totoro launch**, no `src/`/`test/` edits.

| Target | Row(s) | Slice | Action today |
|---|---|---|---|
| **Gaussian 2SO / T4 pre-run** | A2 (primary), A3 (partial) | M2-S3 | Write T4 estimate; queue spec for maintainer G0 |
| **D-220 one-lane discipline** | all campaign slices | — | Campaigns async on Totoro; lane does not block on results |
| **M2 foundation** | meta | M2-S0 | This slice table + `t4-totoro-estimate-2026-09-05.md` |

**Not day-1:** M2-S1 harness implementation, M2-S4 Poisson/NB2 pre-runs, θ-map research
start (unless owner reprioritises), any gate-tier **covered** promotion.

---

## Acceptance ledger pointer (Phase 2.5 — M2)

Unlazy leaves (to be created when build starts):

| Leaf | Slice | Pass criterion |
|---|---|---|
| `leaf-m2-s1-harness.md` | M2-S1 | Receipt fields written; `se=TRUE` path in parity harness |
| `leaf-m2-s3-t4-pre-gaussian.md` | M2-S3 | One cell p=20 n=500; cond(H) recorded; tolerance read |
| `leaf-m2-s5-t4-grid.md` | M2-S5 | 12 cells; each-own-optimum at signed tolerances |
| `leaf-m2-r1-theta-map.md` | M2-R1 | Alignment memo + owner decision stub |

Path: `.unlazy/m2-foundation-20260905/` (gitignored run state).

---

## Cross-links

| Artifact | Path |
|---|---|
| Gate-tier (42 rows SIGNED) | `true-parity-gate-tier-2026-09-05.md` |
| Programme map / P6 T4 grid | `true-parity-programme-decision-map-2026-09-05.md` |
| Second-order contract | `second-order-parity-contract.md` |
| T4 Totoro estimate | `t4-totoro-estimate-2026-09-05.md` |
| θ-map disposition | `theta-map-disposition-2026-09-05.md` |
| Wayfinder M2 gate | `docs/dev-log/plans/2026-09-05-true-parity-wayfinder.md` |
| Ultra-plan | `docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md` |
| Toy 2SO pre-run (2026-09-02) | `second-order-prerun-2026-09-02.md` |
| Matched pilot (3/5) | `second-order-matched-pilot-batch1-20260905.md` |

---

## Sign-off block

| Field | Value |
|---|---|
| Authored | Ada (M2 foundation day-1) |
| Date | 2026-09-05 |
| Maintainer sign-off | **PENDING** — planning doc only |
| Blocks v0.true-parity claim | yes — receipts owed per slice |
