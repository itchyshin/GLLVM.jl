# After-task — true-parity ledger / capability gap inventory (read-only)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal` item 3)  
**Branch:** `docs/true-parity-ledger-gap-inventory-20260915` from `origin/main` @ `2fd0cec8`  
**Scope:** Inventory only — **no** engine edits, **no** ledger JSON mutation, **no** Totoro, **no**
`Project.toml` bump, **no** covered-row promotion, **no** gllvmTMB engine surgery.

## Rose fence (read first)

- **This inventory ≠ closing gaps ≠ `covered` promotion ≠ true parity destination reached.**
- **Core070 `FREE=0`** closes the **spreadsheet programme** (every required row bound or
  dispositioned); it is **not** permission to claim R workflows run identically through Julia
  (`docs/src/gllvmtmb-parity.md` §Ledger accounting).
- **Harness parity** (toy first-order cells, Arc 0 wrappers) is **strictly weaker** than
  **true parity** (`docs/dev-log/core070/true-parity-decision-map.md` §Destination).

## Programme anchors

| Item | Path / measurement |
|------|-------------------|
| Destination map | `docs/dev-log/core070/true-parity-decision-map.md` |
| Capability scoreboard | `docs/src/gllvmtmb-parity.md` |
| Twin capability join | gllvmTMB `tools/parity_ledger.R` (read-only); Julia `tools/parity_ledger.py` |
| Core070 ledger | `docs/dev-log/core070/required-source-case-map.json` |
| T5 partial defects | `docs/dev-log/after-task/2026-09-14-t5-partial-defect-inventory.md` (**7/8**) |
| Second-order prep | `docs/dev-log/after-task/2026-09-14-second-order-parity-inventory.md` |
| Pending board | `docs/dev-log/2026-09-14-true-parity-pending-board.md` |
| Frozen oracle | `b4d5fee64def88bc768dda1f1f77c29b295edd86` |

## Checks run (2026-09-15)

```text
python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json
python3 tools/parity_ledger.py   # FORWARD=77 REVERSE=92 @ frozen oracle
Rscript tools/parity_ledger.R    # gllvmTMB twin — 48 matched, 32 R-only, 33 J-only, 6 DIFFER
```

Measured @ programme HEAD (`2fd0cec8`):

| Ledger layer | Metric | Value |
|--------------|--------|------:|
| Core070 required | `REQUIRED` | **497** |
| Core070 required | `BOUND` | **306** |
| Core070 required | dispositioned (not free) | **191** |
| Core070 required | **`FREE`** | **0** |
| Disposition | `BLOCKED_NEEDS_JULIA_SURFACE` | **122** |
| Disposition | `PARTIAL_PENDING_DECISION_OPEN_QUESTION` | **47** |
| Disposition | `BLOCKED_SPEC_DEFECT` | **22** |
| Export parity (FORWARD) | R exports with no Julia **name** twin | **77** (0 untracked) |
| Export parity (REVERSE) | Julia exports with no R twin | **92** (291 ahead-accounted) |
| Capability-status join | matched / R-only / J-only / **DIFFER** | 48 / 32 / 33 / **6** |

## Layer 1 — True-parity destination gates (still owed)

From `true-parity-decision-map.md` §Destination (plain language):

| # | Gate | Status @ `2fd0cec8` | Blocker / next action |
|---|------|---------------------|------------------------|
| 1 | Required ledger rows bound **or** signed disposition | **Met (accounting)** | `FREE=0`; **122** rows still **needs Julia surface** — not “done” for users |
| 2 | First-order **and** second-order receipts per paired cell | **Partial** | Toy 5-family D1 exists; contract **§7 NOT DONE**; realistic grid mostly **Totoro-blocked** |
| 3 | Realistic-size cell per family (p≥20, n≥500, κ recorded) | **Partial** | One pre-run + repair archive; full grid **blocked on compute** (`LOOP/arcs.md` #22) |
| 4 | Real-data workflow per qualified family | **Not started** | **gllvmTMB PR #1236** merge (`LOOP/arcs.md` #23) |
| 5 | Grouping levels `unit` / `unit_obs` / `cluster` / `cluster2` paired | **Partial** | R: all four args; Julia: Destination B route for **Gaussian, Poisson, Binomial, Beta, NB2** only — not full non-Gaussian / bridge depth (`t12-grouping-levels-design.md`) |
| 6 | Reverse gap list (tool + written decisions) | **Met (tool)** | `parity_ledger.py` + R join; **disposition** on Julia-only arcG row still **FAIL** in R tool CLOSURE line |
| 7 | Single-page “what parity does NOT mean” | **Met (docs)** | `gllvmtmb-parity.md` |

## Layer 2 — Core070 dispositions vs honest 0.7 **user** scope

**Spreadsheet closed; capability debt open.** The rows that most block an honest **0.7 user**
story (not every `required_core` export alias):

| Disposition bucket | Count | True-parity meaning | Representative ids / themes |
|--------------------|------:|---------------------|------------------------------|
| `BLOCKED_NEEDS_JULIA_SURFACE` | 122 | Engine or **public API** missing on Julia side | Namespace: `latent`, `phylo_*`, `spatial_*`, `meta*`, `isdm_*`, `loading_profile` (D3), postfit extractors tied to R formula grammar |
| `PARTIAL_PENDING_DECISION_OPEN_QUESTION` | 47 | Paired route exists but **estimand / promotion** unset | Namespace + postfit-policy rows; export `indep` / `scalar` **PARTIAL** in `parity_ledger.py` |
| `BLOCKED_SPEC_DEFECT` | 22 | **R-side or joint-spec** defect — not Julia-only build | Covariance + postfit rows — hand to gllvmTMB lane (T11) |
| Bound (receipt) | 306 | First-order (mostly) harness receipts | Includes T5 rows **1–7**; AGHQ compatibility tier bound 2026-09-04 |

**Cross-tab (required rows, top namespaces):**

| Namespace | `BLOCKED_NEEDS_JULIA_SURFACE` | `PARTIAL_PENDING` | bound-ish (`None` in counter) |
|-----------|------------------------------:|------------------:|------------------------------:|
| `namespace/` | 65 | 26 | 71 |
| `postfit/` | 41 | 14 | 34 |
| `postfit-policy/` | 1 | 4 | 16 |
| `covariance/` | 11 | 0 | 17 |
| `fit-input/` | 3 | 2 | 6 |

## Layer 3 — Export parity (`tools/parity_ledger.py`, FORWARD 77)

Among **required_core** FORWARD gaps (R export name lacks Julia export name):

| Class | Count | Notes |
|-------|------:|-------|
| `BLOCKED_NEEDS_JULIA_SURFACE` | **29** | Includes **`loading_profile`** (confirmatory; exploratory exists), **`phylo`/`spatial`/`meta`/`isdm`** keyword exports, **`confirmatory_lambda`**, pedigree helpers |
| `PARTIAL_PENDING_DECISION_OPEN_QUESTION` | **2** | `indep`, `scalar` — modifier vs mode promotion (DestB Arc 0 already **implemented** function paths; ledger export names pending) |
| `no disposition` (required_core) | **20** | Many have **Julia analogues under different names** (e.g. grid keywords implemented as fitters, not `@formula` exports) — **re-bind or reclassify**, not greenfield |

**Not owed as engine parity (tool already classifies):** 4 not-capability, 6 accounted-for-in-writing, 0 renamed-away.

## Layer 4 — Capability matrix (`docs/design/capability-status.md`)

Rows still **`planned`**, **`missing`**, or **`partial`** on Julia side (honest 0.7 scope fence):

| Capability row | Julia status | True-parity relevance |
|----------------|--------------|------------------------|
| `spatial × dep` | planned (fail-loud only) | Structured source grid incomplete |
| `multinomial / categorical` | **missing** | R scope-limited; no Julia engine |
| Simulation-validated **coverage certificate** | **missing** | **Out of parity claim** (Julia diagnostics ≠ R agreement) |
| Julia-only arcG / DRAC Wald coverage | partial | **Julia-beyond** — needs written disposition (R `parity_ledger.R` CLOSURE **FAIL**) |
| **AGHQ estimator** (public) | **missing** | R scope-limited opt-in; Julia internal kernel only |
| Keyworded random **slopes** | planned | Sequenced after phylo transport (decision map §Out of scope timing) |
| Mixed-family response vector | planned | Bridge partial; full depth not claimed |
| Bridge phylo / animal / spatial / kernel | **planned** | **`engine = "julia"`** one-way partial (`gllvmtmb-parity.md` §Bridge) |
| Response-column slope + `column_coef` family | **missing** | R 0.7.1 **Class-1** surface — **out of frozen 0.7.0 oracle** but **in** honest user gap vs live R |
| Broad AGHQ (Julia) | missing | Compatibility tier only (T8 closed defer) |

**Twin join DIFFER rows (6)** — status honesty required before promotion:

1. `spatial × dep` — R scope-limited vs Julia planned  
2. `phylo_latent + lv = ~ x` — R planned vs Julia **rejected** (intentional)  
3. `multinomial` — R scope-limited vs Julia **missing**  
4. Simulation coverage certificate — R scope-limited vs Julia **missing**  
5. **AGHQ** — genuine disagreement (R public knob vs Julia internal)  
6. Mixed-family vector — R scope-limited vs Julia **planned**

**R-NARROWER (21):** Julia marks `implemented` where R honestly hedges `scope-limited` — not a Julia bug; **promotion fence** until receipts match R’s narrower claim.

## Layer 5 — Programme arcs still open (cross-walk)

| Arc | State | Gap for true parity |
|-----|-------|---------------------|
| **T5** (#16) | **7/8** | Row 8 `loading_profile`: Stage **0** on main (#345); Stage **1** needs **`G0 Stage 1`** |
| **Second-order §7** | **NOT DONE** | SE + vcov + Wald at scale; holdouts in `second-order-holdouts-2026-09-04.md` |
| **T4 realistic-size** (#22) | blocked | Totoro/DRAC; grid closed (Gaussian, Poisson, NB2) |
| **T7 real-data** (#23) | blocked | PR **#1236** |
| **T8 AGHQ** (#17) | paused | Compatibility-only unless owner promotes |
| **T11 API collisions** (#18) | blocked | gllvmTMB lane |
| **S4 probe** (#3) | paused | Second **`S4 probe yes`** only |
| **#323** | waived (B) | ≠ smoke green; optional Totoro |
| **matched-θ** | OUT (C) | each-own-optimum only for beta/NB2 |
| **Version** (#24) | paused | **`0.3.0`** frozen |

## Ranked next executable slices

**Excluded here (hard stops):** D3 Stage **1**, S4 probe — no maintainer G0 / second yes.

| Rank | Slice | Owner | Executable now? | Closes true parity? |
|------|-------|-------|-----------------|---------------------|
| **1** | **T4 realistic-size second-order campaign** — closed grid (Gaussian, Poisson, NB2; p∈{20,50}, n∈{500,2000}); D-139 one-cell pre-run then Totoro batch | Cursor/Codex + Totoro | After **`ack Totoro D-139 …`** | **Partial** — destination gate #3 |
| **2** | **Second-order follow-up batch** — Wald dispatch + paired toy cells for Delta-lognormal/Delta-Gamma; then holdout families (Ordinal/Lognormal/Truncated per holdout table) | Engine + `confint_family.jl` | Local/engine yes; paired R receipts need RCall | **Partial** — contract §7 |
| **3** | **§2 disputed-default resolution** — binomial-cloglog / Tweedie-grouped Hessian selector; single maintainer decision then receipt class | Maintainer + Fisher | Docs/decision first | **Unblocks promotion** for those cells only |
| 4 | **Bridge mirror expansion** — six engine-only families invisible to R `julia-bridge.R` (drift probe RED; `capability-status.md` fence) | Julia + gllvmTMB read-only PR | Bounded Julia bridge slice | **Partial** — user-visible R→Julia |
| 5 | **Grouping levels** — extend `fit_gllvm(...; unit=, unit_obs=, cluster=, cluster2=)` beyond current five families | Engine | Multi-file; Shannon lease | **Partial** — destination gate #5 |
| 6 | **T7 prep** — `urbanisation_map` eight-class script dry-run locally | Applied | After **#1236** merge | Real-data gate |
| 7 | **Julia-only disposition** — arcG/DRAC row for R `parity_ledger.R` CLOSURE | Docs | Docs-only | Tool hygiene only |

### Top 3 for maintainer dispatch (executable without Stage 1 / S4)

1. **T4 realistic-size second-order on Totoro** (rank 1) — largest measurable step toward destination gates #2–#3.  
2. **Second-order follow-up batch for Delta + holdout families** (rank 2) — extends §7 without matched-θ.  
3. **§2 disputed-default decision + receipt class** (rank 3) — unblocks honest second-order claims for cloglog/Tweedie cells.

## Graft symbols (read-only)

- `parity_ledger` — `tools/parity_ledger.py`, `graft/tools/parity_ledger.md`
- `core070_ledger_counts` — `tools/core070_ledger_counts.py`
- `loading_profile` — D3 row 8; Stage 0 substrate `test/test_loading_profile_stage0.jl`

## Follow-up from this slice

- Pending board: mark **ledger gap inventory** done; pointer to this file.
- `LOOP/checkpoint.md`: refresh **NEXT** ranked list (item 3 complete).
- **No** change to `required-source-case-map.json`.
