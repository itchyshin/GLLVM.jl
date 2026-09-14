# After-task — T5 partial parity defect inventory (read-only)

**Date:** 2026-09-14  
**Lane:** Cursor / Ada (true-parity docs prep)  
**Branch:** `docs/destb-checkpoint-post-336` @ inventory time (PR [#337](https://github.com/itchyshin/GLLVM.jl/pull/337) LOOP sync)  
**Scope:** Inventory only — no engine edits, no Totoro, **#323 not waived** (`docs/dev-log/decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md` remains **PENDING_ACCEPTANCE**).

## Programme anchors

| Item | Path |
|------|------|
| LOOP arc | `LOOP/arcs.md` #16 — T5 — 8 `PARTIAL_PARITY_DEFECT` rows re-bind (**next** in arcs table; ledger ahead of LOOP on 7/8) |
| Goal gate | `LOOP/GOAL.md` — **#323** executed (Totoro receipt) **or** maintainer **waive** before downstream true-parity claims |
| Canonical audit (8 rows) | `docs/dev-log/core070/parity-defect-rebind-2026-09-02.md` |
| T5 execution record | `docs/dev-log/core070/t5-rebind-2026-09-03.md` |
| D3 disposition (row 8) | `docs/dev-log/after-task/2026-09-04-d3-loading-profile-exploratory.md` |
| Live ledger | `docs/dev-log/core070/required-source-case-map.json` |
| Ledger counts @ inventory | `python3 tools/core070_ledger_counts.py` → `REQUIRED=497`, `FREE=0`, **`PARTIAL_PARITY_DEFECT*` dispositions = 0** (historical key was `PARTIAL_PARITY_DEFECT_PENDING_DECISION`) |

\*Disposition rename on programme HEAD: defect rows that were `PARTIAL_PARITY_DEFECT_PENDING_DECISION` are either **bound** (no `disposition` key) or reclassified (row 8).

## Fixture / family context (all eight)

Original defects were measured on the shared **`gaussian_small`** paired fixture (seed 42, frozen oracle `b4d5fee64def88bc768dda1f1f77c29b295edd86`): **Gaussian** response, ordinary latent GLLVM — not a multi-family sweep. Postfit-policy rows are **family-agnostic** `nobs` contract rows exercised on the same fixture batch.

## Inventory — 8 rows

| # | Row id (`source_id`) | Family / link (fixture) | Current status (2026-09-14 ledger) | Evidence path | Proposed next bind | Blockers |
|---|----------------------|-------------------------|--------------------------------------|---------------|-------------------|----------|
| 1 | `postfit/POSTFIT-SURFACE-extract_communality` | Gaussian / identity (`gaussian_small`) | **BOUND** (no disposition; T5 receipt) | `docs/dev-log/core070/t5-rebind-2026-09-03.md`; receipt `.unlazy/core070-aghq/t5-rebind-01/estimand-rebind-02` (sha256 in ledger); fix `src/extractors.jl` tier defaults; tests `test/test_extractors.jl` | **None for re-bind** — close LOOP #16 line for this row; optional local re-run `core070_estimand_rebind_batch` on programme HEAD after #323 | **#323** programme gate; LOOP #16 still says “next” |
| 2 | `postfit/POSTFIT-SURFACE-extract_correlations` | Gaussian / identity (`gaussian_small`) | **BOUND** | Same estimand-rebind receipt / verifier `tools/core070_verify_estimand_rebind_batch.py` | Same as row 1 | Same |
| 3 | `postfit/POSTFIT-SURFACE-extract_proportions` | Gaussian / identity (`gaussian_small`) | **BOUND** | Same estimand-rebind receipt | Same as row 1 | Same |
| 4 | `postfit/POSTFIT-SURFACE-extract_Omega` | Gaussian / identity (`gaussian_small`) | **BOUND** | Same estimand-rebind receipt (R `$Omega` list-unwrap noted in T5 doc) | Same as row 1 | Same |
| 5 | `postfit-policy/POST-LOGLIK-NOBS` | Policy / n/a (Gaussian fixture in batch) | **BOUND** | `docs/dev-log/core070/t5-rebind-2026-09-03.md`; receipt `.unlazy/core070-aghq/t5-rebind-01/postfit-policy-batch-02`; fix `src/postfit.jl` nobs (decision #1) | **None for re-bind** — close LOOP #16 line | **#323** gate for programme; maintainer decision #1 already adopted |
| 6 | `postfit-policy/POST-NOBS-COUNT` | Policy / n/a | **BOUND** | Same postfit-policy receipt; verifier `tools/core070_verify_postfit_policy_batch.py` | Same as row 5 | Same |
| 7 | `postfit-policy/POST-NOBS-FALLBACK` | Policy / n/a | **BOUND** | Same postfit-policy receipt | Same as row 5 | Same |
| 8 | `namespace/export/loading_profile` | Export / estimand (confirmatory Λ profile) | **`BLOCKED_NEEDS_JULIA_SURFACE`** (D3 2026-09-04) | `docs/dev-log/after-task/2026-09-04-d3-loading-profile-exploratory.md`; ledger `evidence.reason` + `maintainer-decision-set-2026-09-03.md` D3; Julia exploratory API `loading_profile_exploratory` (`src/confint_derived.jl`, graft: deprecated shim `loading_profile`) | **Not a parity-defect re-bind** — future **confirmatory** mirror of R `loading_profile()` (`gllvmTMB` `loading-profile.R`, `fit$lambda_constraint` gate) **or** maintainer-written joint-ledger acceptance of needs-surface + Julia-beyond exploratory | R confirmatory surface has **no** Julia counterpart; wave5/wave7 deferred fixture gap for pinned loadings; Shinichi seam on joint ledger wording (D3) |

## Summary counts

| Metric | Value |
|--------|------:|
| Rows in canonical T5 set | **8** |
| Already **bound** with T5 Totoro receipts | **7** |
| Reclassified (defect cleared, surface owed) | **1** (`loading_profile`) |
| Rows still carrying `PARTIAL_PARITY_DEFECT_PENDING_DECISION` | **0** |

## Graft symbols touched (read-only)

- `loading_profile` → exploratory rename / deprecation shim (`src/confint_derived.jl`)
- Related profile machinery: `_profile_invert_callback`, `_profile_parm_index` (context only; not T5 row ids)

## Rose fence

- This inventory **≠** T5 arc **closed** in LOOP until #16 status and GOAL checkboxes are updated honestly.
- **≠** #323 executed or waived.
- **≠** full true parity or frozen-R smoke green.
- Seven bound rows **=** paired receipt evidence on 2026-09-03 programme refs, not a substitute for #323.

## Ready to execute after #323 gate?

| Work slice | Ready after #323? | Notes |
|------------|-------------------|-------|
| Close LOOP **#16** for rows **1–7** | **Yes** (docs-only) | Ledger already bound; no new Totoro required unless programme demands receipt refresh on post-DestB `main` |
| Close LOOP **#16** for row **8** | **No** (needs D3 follow-up) | Disposition is **needs-surface**, not a verifier re-bind; optional maintainer text on joint ledger |
| New Totoro **T5 re-bind campaign** | **Mostly N/A** | Already run (`t5-rebind-2026-09-03.md`); repeating is optional hygiene, not blocked on #323 |
| Broader true-parity execution (T3 second-order, realistic grid, etc.) | **No until #323** | Per `LOOP/GOAL.md` and `LOOP/checkpoint.md` — **do not waive #323** in this slice |

**Verdict:** After **#323** is dispositioned (Totoro receipt **or** documented maintainer waive), the programme can **immediately** mark T5 **7/8** done in LOOP and proceed to second-order / defect-adjacent work; row **8** remains a **surface/backlog** item, not a blocked re-bind.

## Checks run

- `python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json`
- Row field extraction script over the eight `source_id`s (local, read-only)
- `graft ask "PARTIAL_PARITY_DEFECT T5 loading_profile nobs extract" --source` (symbol cruxes only)

## Follow-up (out of scope here)

- Sync `LOOP/arcs.md` #16 + `LOOP/GOAL.md` T5 checkbox with this inventory (same docs PR lane or follow-on commit).
- Append `docs/dev-log/check-log.md` entry when LOOP sync lands.
- No push from this slice unless disjoint from PR #337 (this commit stays local on shared docs branch).
