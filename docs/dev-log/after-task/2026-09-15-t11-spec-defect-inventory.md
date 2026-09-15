# After-task — T11 `BLOCKED_SPEC_DEFECT` inventory (22 rows)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`, parallel dispatch)  
**Branch:** `docs/t11-spec-defect-inventory-20260915` from `origin/main` @ `25af0c0f1`  
**Scope:** Inventory + ranked actions only — **no** `src/`, **no** ledger JSON mutation, **no**
Totoro, **no** gllvmTMB engine surgery (read-only twin reference).

## Rose fence (read first)

- **This inventory ≠ fixing defects ≠ rebinding rows ≠ `covered` promotion ≠ true parity reached.**
- **`BLOCKED_SPEC_DEFECT`** here means the Core070 programme could not run a numeric
  R↔Julia receipt against the row as written — not that Julia or R is necessarily wrong.
- **`FREE=0`** closes spreadsheet accounting; these **22** rows remain **honest 0.7 debt**
  until disposition or case-plan repair is **maintainer-signed** on the ledger.
- Companion table: `docs/dev-log/core070/t11-spec-defect-inventory-2026-09-15.md`.

## Programme anchors

| Item | Path |
|------|------|
| Gap inventory (context) | `docs/dev-log/after-task/2026-09-15-true-parity-ledger-gap-inventory.md` |
| T11 decision hook | `docs/dev-log/core070/true-parity-decision-map.md` §Not yet specified (T11) |
| R-side leads (read-only) | `docs/dev-log/core070/r-side-defects-2026-09-02.md` (group E + bridge B) |
| Ledger | `docs/dev-log/core070/required-source-case-map.json` |
| Postfit batch triage | `docs/dev-log/core070/postfit-2-batch-contract.json` §`spec_defect_rows` |
| Slope case drafts | `docs/dev-log/core070/manifest-freeze-work/drafts/covariance.json` |
| Covariance batch | `docs/dev-log/core070/covariance-batch-contract.json` |

## Checks run (2026-09-15)

```text
python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json
# (enumerated BLOCKED_SPEC_DEFECT source_id list via JSON filter — 22 rows, 11 covariance + 11 postfit)
```

Measured @ `25af0c0f1`: **`BLOCKED_SPEC_DEFECT` = 22** (matches gap inventory @ `2fd0cec8`).

Historical note: ledger recount 2026-09-02 listed **44** `BLOCKED_SPEC_DEFECT` including **22 AGHQ**
rows; D4/T8 policy work reclassified AGHQ bindable remainder — the **residual 22** are the subject
of this inventory.

## Root-cause taxonomy (how to read the table)

| Class | Meaning |
|-------|---------|
| **Joint ambiguity** | Manifest `planned_case_ids` and the executable case-plan annex disagree, or comparands assume an API shape neither engine must share. |
| **R bug / R rough edge** | Frozen 0.7.0 R behaviour or bridge gate contradicts user docs or hides a route R can fit (verify on gllvmTMB lane). |
| **Julia mis-disposition** | Row is correctly **`compatibility_adapter`** or **`BLOCKED_NEEDS_JULIA_SURFACE`** but ledger still says `BLOCKED_SPEC_DEFECT`. |

## All 22 rows

### A — Covariance / slopes / folded loading (11 rows)

| # | `source_id` | Root-cause class | Short root cause |
|---|-------------|------------------|------------------|
| 1 | `covariance/COV-ANIMAL-FOLDED-UNIQUE` | **Julia mis-disposition** (ledger triage) | Wave-4 triage checked **slopes/structured** plans only; cases **are** authored in `covariance-required-case-plan.json` and the **formula** arm is executable R-only in `covariance-batch-contract.json`. Native arm is intentionally open (no auto folded Λ); should not stay bulk `SPEC_DEFECT` without split disposition. |
| 2 | `covariance/COV-SLOPE-F01-L0` | **Joint ambiguity** | Draft case specs exist in `manifest-freeze-work/drafts/covariance.json` (binomial **logit** augmented slope) but **`CORE070-COV-SLOPE-F01L0-*` never landed** in `slopes-required-case-plan.json` — manifest points at phantom case ids. |
| 3 | `covariance/COV-SLOPE-F01-L1` | **Joint ambiguity** | Same annex gap for binomial **probit** admission (`F01-L1`). |
| 4 | `covariance/COV-SLOPE-F03-L0` | **Joint ambiguity** | Draft only: lognormal/log augmented slope — annex not authored. |
| 5 | `covariance/COV-SLOPE-F04-L0` | **Joint ambiguity** | Draft only: Gamma/log augmented slope — annex not authored. |
| 6 | `covariance/COV-SLOPE-F05-L0` | **Joint ambiguity** | Draft only: NB2/log augmented slope — annex not authored. |
| 7 | `covariance/COV-SLOPE-F07-L0` | **Joint ambiguity** | Draft only: Beta/logit augmented slope — annex not authored. |
| 8 | `covariance/COV-SLOPE-F08-L0` | **Joint ambiguity** | Draft only: beta-binomial/logit augmented slope — annex not authored. |
| 9 | `covariance/COV-SLOPE-F09-L0` | **Joint ambiguity** | Draft only: Student-t/identity augmented slope — annex not authored; **R bridge** still omits `student()` from `.GLLVM_JULIA_BRIDGE_FAMILIES` (`r-side-defects-2026-09-02.md` B — verify separately). |
| 10 | `covariance/COV-SLOPE-F14-L0` | **Joint ambiguity** | Draft only: ordinal probit augmented slope — annex not authored. |
| 11 | `covariance/COV-SLOPE-F15-L0` | **Joint ambiguity** | Draft only: NB1/log augmented slope — annex not authored. |

**Cross-cut (R, not separate ledger rows):** augmented `(1 + x | site)` routes on 0.7.0 may be **hard to discover** through the Julia bridge (`r-side-defects` B; gllvmTMB **#1195** / **#1196** on slope syntax). That is **T11 gllvmTMB lane** verification — not an excuse to leave phantom `planned_case_ids` on the Julia ledger.

### B — Postfit compatibility adapters (11 rows)

Each row: **`evidence_kind=compatibility_adapter`**, null `r_call`, empty comparands — postfit-2 batch correctly bucketed **`SPEC_DEFECT`** for *receipt execution* but ledger already carries **`reclassify_proposed: compatibility_adapter`**.

| # | `source_id` | Root-cause class | Short root cause |
|---|-------------|------------------|------------------|
| 12 | `postfit/POSTFIT-SURFACE-ordiplot` | **Julia mis-disposition** | Bare S3 generic; real work is `ordiplot.gllvmTMB_multi` (separate row, `PARTIAL_PENDING`). |
| 13 | `postfit/POSTFIT-SURFACE-plot.gllvmTMBmesh` | **Julia mis-disposition** | Graphics-only; mesh geometry owed elsewhere. |
| 14 | `postfit/POSTFIT-SURFACE-plot.sdmTMBmesh` | **Julia mis-disposition** | Deprecated alias → `plot.gllvmTMBmesh`. |
| 15 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_Sigma_phy_slope` | **Julia mis-disposition** | Console formatter over Sigma/slope payload (payload row separate). |
| 16 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_check_consistency` | **Julia mis-disposition** | Print wrapper; `check_consistency()` is the numeric surface. |
| 17 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_confint_inspect` | **Julia mis-disposition** | Print wrapper; `confint_inspect()` payload separate. |
| 18 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_coverage_study` | **Julia mis-disposition** | Print wrapper; `coverage_study()` payload separate. |
| 19 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_identifiability` | **Julia mis-disposition** | Print wrapper; identifiability check payload separate. |
| 20 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_reportable_table` | **Julia mis-disposition** | Column-stripping print; table construction separate. |
| 21 | `postfit/POSTFIT-SURFACE-print.gllvmTMB_slope_ci` | **Julia mis-disposition** | Caveat header print; `slope_sd_ci()` payload separate. |
| 22 | `postfit/POSTFIT-SURFACE-tidy` | **Julia mis-disposition** | NAMESPACE re-export of `generics::tidy`; computation is `tidy.gllvmTMB_multi`. |

**Not in the 22:** inference `CI-ROUTE-*` unsupported-method rows were **`SPEC_DEFECT` in the inference batch contract** but ledger disposition today is **`PARTIAL_PENDING`** / other buckets — excluded from this count.

## Summary by class

| Root-cause class | Count | Programme meaning |
|------------------|------:|-------------------|
| Joint ambiguity (slope annex / phantom case ids) | 10 | Case-plan authoring + ledger re-disposition → **`BLOCKED_NEEDS_JULIA_SURFACE`** when specs land |
| Julia mis-disposition (postfit adapters) | 11 | Maintainer ledger reclassify → **`compatibility_adapter`** (no numeric parity receipt) |
| Julia mis-disposition (COV-ANIMAL-FOLDED-UNIQUE triage) | 1 | Split: formula R-only bind vs native **`NEEDS_JULIA_SURFACE`** |
| R bug / rough edge (linked, not extra rows) | 0 exclusive | Slope discoverability + bridge family gates — **gllvmTMB T11 verify** |

## Ranked top 5 — fix or reopen (executable without Totoro)

| Rank | Action | Owner | Outcome for honest 0.7 |
|------|--------|-------|-------------------------|
| **1** | **Ledger batch reclassify** the 11 postfit rows using existing `reclassify_proposed` blocks (`postfit-2-batch-contract.json`). | Maintainer + docs lane | Removes false “spec defect” noise; **`FREE=0` unchanged**, user-facing debt honest |
| **2** | **Author `slopes-required-case-plan.json`** entries for the 10 `COV-SLOPE-F*-L0/L1` rows by promoting drafts from `manifest-freeze-work/drafts/covariance.json`; then re-disposition to **`BLOCKED_NEEDS_JULIA_SURFACE`**. | Julia programme / docs | Turns phantom ids into buildable slope receipts (Poisson-first track already scoped) |
| **3** | **Re-triage `COV-ANIMAL-FOLDED-UNIQUE`**: bind formula case from `covariance-batch-contract.json` (R-only receipt path exists); native → **`NEEDS_JULIA_SURFACE`** with explicit folded-Λ scope. | Julia programme | Fixes mis-checked annex; separates grammar proof from engine gap |
| **4** | **T11 handoff (read-only)**: gllvmTMB lane verifies augmented-slope admission vs bridge refusals; file or close **#1195/#1196** with measured “working route” strings. | gllvmTMB | User-visible R consistency; Julia slope work pairs to frozen R admission table |
| **5** | **Pending-board / parity doc sentence**: state that **22 `SPEC_DEFECT` ≠ 22 engine bugs** (11 adapter relabels + 10 annex gaps + 1 triage split). | Docs | Prevents overstating Core070 disposition as Julia lag |

**Explicitly excluded (this slice):** D3 Stage 1, S4 probe, T4/Totoro, `required-source-case-map.json` edit without maintainer sign-off, gllvmTMB `src/` / `R/` changes.

## Graft symbols (read-only)

- `core070_ledger_counts` — `tools/core070_ledger_counts.py`
- `postfit_2_batch` — `docs/dev-log/core070/postfit-2-batch-contract.json`

## Follow-up

- Point true-parity `/goal` item T11 at this file + companion table.
- **No** change to `LOOP/checkpoint.md`, pending board, or ledger JSON from this lane.
