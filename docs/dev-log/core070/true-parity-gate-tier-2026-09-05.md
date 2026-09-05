# v0.true-parity gate-tier row list — SIGNED (2026-09-05)

**Status: SIGNED by maintainer 2026-09-05.** This list is the agreed v0.true-parity
gate-tier per G0 Q3 (~30–50 rows, not all 497). **Do not read as covered** — signed
means programme planning scope only; row receipts still owed per build arcs. Proposal
landed in map-clearance PR #292 (`1b38906c`); sign-off recorded via gate-tier sign-off PR (T9 / P3).

**Oracle:** frozen gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`  
**Basis:** G0 locked 2026-09-05; Ada default = paired second-order families + four grouping
levels + one real-data repo per major family class + minimal bridge/native ordination spine.

**Row count:** 42 proposed gate-tier rows (compatibility and beyond-tier rows dispositioned
separately in build arcs).

---

## Tier key

| Tag | Meaning |
|---|---|
| **1FO** | First-order paired receipt (logLik, point estimates, cross-objective) |
| **2SO** | Second-order paired receipt (SE, vcov, Wald CI — `second-order-parity-contract.md`) |
| **RSZ** | Realistic-size cell (p ≥ 20, n ≥ 500, cond(H) recorded) |
| **RD** | Real-data workflow (eight acceptance classes) |
| **BRG** | Bridge-eligible (`engine = "julia"`) — requires ACC-class receipt per bridge design note |
| **NAT** | Native Julia route required (bridge cannot honestly carry) |
| **GRP** | Grouping-level surface |

---

## A — Paired second-order families (15 rows)

Batch-1 families from `second-order-parity-contract.md` §6 (signed tolerances 2026-09-05).

| # | Row id | Family / structure | Tier | Route | Notes |
|---|---|---|---|---|---|
| A1 | `family/GAUSSIAN-IDENTITY-1FO` | Gaussian identity + `latent()` bare | 1FO | NAT/BRG | Existing toy + bridge receipts |
| A2 | `family/GAUSSIAN-IDENTITY-2SO` | same | 2SO | NAT | Realistic-size owed (T4 default grid) |
| A3 | `family/GAUSSIAN-IDENTITY-RSZ` | same | RSZ | NAT | p∈{20,50}, n∈{500,2000} |
| A4 | `family/POISSON-LOG-1FO` | Poisson log + `latent()` bare | 1FO | BRG | Bridge receipt exists |
| A5 | `family/POISSON-LOG-2SO` | same | 2SO | NAT | |
| A6 | `family/BINOMIAL-LOGIT-1FO` | Binomial logit + `latent()` bare | 1FO | BRG | |
| A7 | `family/BINOMIAL-LOGIT-2SO` | same | 2SO | NAT | |
| A8 | `family/BETA-LOGIT-1FO` | Beta logit + `latent()` bare | 1FO | BRG | |
| A9 | `family/BETA-LOGIT-2SO` | same | 2SO | NAT | Matched-coords blocked (θ-map research) |
| A10 | `family/NB2-LOG-1FO` | NB2 log + `latent()` bare | 1FO | BRG | |
| A11 | `family/NB2-LOG-2SO` | same | 2SO | NAT | Matched-coords blocked (θ-map research) |
| A12 | `covariance/COV-ORD-LATENT-BARE-1FO` | Ordinary `latent()` bare ordination | 1FO | BRG | `COV-ORD-LATENT-BARE` ledger row |
| A13 | `covariance/COV-ORD-LATENT-BARE-RSZ` | same | RSZ | BRG/NAT | Realistic-size owed |
| A14 | `covariance/COV-PHYLO-LATENT-1FO` | `phylo_latent()` bare (post-transport S3) | 1FO | NAT | Sequenced after phylo Q1–Q4 defaults |
| A15 | `covariance/COV-PHYLO-LATENT-RSZ` | same | RSZ | NAT | |

---

## B — Grouping levels (4 rows)

Owner requirement (T12 / D6): four names on both sides.

| # | Row id | Level | Tier | Route | Notes |
|---|---|---|---|---|---|
| B1 | `grouping-levels/UNIT-KWARG-NAME-PARITY` | `unit` | GRP | NAT | Name parity + scalar row effect where applicable |
| B2 | `grouping-levels/UNIT-OBS-NONGAUSSIAN-KWARG` | `unit_obs` | GRP | NAT | Within-unit RE beyond Gaussian-only `TwoLevelFit` |
| B3 | `grouping-levels/CLUSTER-THIRD-AXIS-KWARG` | `cluster` | GRP | NAT | Non-species third grouping |
| B4 | `grouping-levels/CLUSTER2-INDEP-KWARG` | `cluster2` | GRP | NAT | Second independent diagonal grouping |

Design detail: `docs/dev-log/core070/t12-grouping-levels-design.md`.

---

## C — Real-data workflows (5 rows)

One Ayumi repo per major family class; four maintainer-named repos + urbanisation_map scout
receipt (thin ACC — promotion to full RD gate still owed).

| # | Row id | Repo | Primary family class | Tier | Route | Notes |
|---|---|---|---|---|---|---|
| C1 | `real-data/URBANISATION-MAP-RD` | `urbanisation_map` | Binomial (multi-trait) | RD | BRG | Thin ACC scout exists; full eight-class acceptance owed |
| C2 | `real-data/AVIAN-TRAIT-SCALES-RD` | `avian_trait_scales` | Gaussian / mixed continuous | RD | NAT/BRG | Default second after urbanisation_map |
| C3 | `real-data/NEST-MORPHO-GLLVM-RD` | `nest_morpho_gllvm` | Count / morphometric | RD | NAT | |
| C4 | `real-data/BIRDBASE-PCM-RD` | `BIRDBASE_pcm` | Phylo-structured | RD | NAT | Phylo transport prerequisite |
| C5 | `real-data/META-WORKFLOW-SMOKE` | Any gate-tier repo | Cross-family smoke | RD | BRG | Ensures ≥1 repo per class has end-to-end `engine="julia"` path |

Inventory: `docs/dev-log/core070/real-data-model-inventory.md`.

---

## D — Bridge spine + user-facing extractors (8 rows)

Minimal surfaces Pat/Fisher flagged as user-facing must-haves beyond raw likelihood.

| # | Row id | Surface | Tier | Route | Notes |
|---|---|---|---|---|---|
| D1 | `bridge/ACC-CLASS-RECEIPT-TEMPLATE` | Bridge-eligible tag + ACC receipt | meta | BRG | Design: `bridge-eligible-row-tag-design-2026-09-05.md` |
| D2 | `extractor/PREDICT-INSAMPLE-LINK` | `predict()` in-sample link scale | 1FO | NAT | Wave-7 measured, not parity gate — disposition only if demoted |
| D3 | `extractor/SUMMARY-FIXED-EFFECTS` | `summary()` fixed effects table | 1FO | NAT | |
| D4 | `extractor/VCov-FIXED-BLOCK` | `vcov()` fixed block | 2SO | NAT | Pairs with second-order contract |
| D5 | `extractor/CONFINT-WALD-LINK` | Wald CI endpoints | 2SO | NAT | |
| D6 | `fit-input/FIT-GAUSSIAN-CORE` | Gaussian fit input contract | 1FO | NAT/BRG | `fit-input-contract.md` core cells |
| D7 | `fit-input/FIT-LAPLACE-CORE` | Non-Gaussian Laplace fit input | 1FO | NAT/BRG | Six dense-Laplace families |
| D8 | `parity/REVERSE-GAP-DISPOSITION` | Reverse list (`parity_ledger.py`) | meta | — | Tool-produced; R lane owns R-side ports |

---

## E — Explicitly NOT in gate-tier (disposition defaults)

These remain in the full ledger but are **compatibility** or **beyond** unless owner promotes:

| Category | Default disposition | Reference |
|---|---|---|
| All 14 AGHQ bind rows | **Deferred** from v0.true-parity gate-tier | `t8-aghq-bind-next-slice.md` |
| AGHQ policy / invalid control rows | Compatibility — bound, not user claim | `required-source-case-map.json` |
| `traits()`, `column_coef`, 0.7.1 Class-1 | Change-control — separate 0.7.1 catch-up board | Programme map §0.7.1 Class-1 |
| Spatial / iSDM / slopes engines | Beyond gate-tier; phylo transport first | `true-parity-decision-map.md` out of scope |
| Interval coverage certification | Separate programme (Class-2) | gap sheet |
| Full ~122 `BLOCKED_NEEDS_JULIA_SURFACE` | Compatibility disposition unless promoted here | G0 Q3 |

---

## Sign-off block

| Field | Value |
|---|---|
| Proposed by | Ada (map-clearance arc M0-3) |
| Proposed date | 2026-09-05 |
| Maintainer sign-off | **SIGNED — Shinichi 2026-09-05** |
| Signed row count | **42** |
| Proposal PR | #292 merged @ `1b38906c` |
| Sign-off PR | gate-tier sign-off branch (T9) |

**P3 status:** **CLOSED SIGNED 2026-09-05** — gate-tier list locked for programme planning.
