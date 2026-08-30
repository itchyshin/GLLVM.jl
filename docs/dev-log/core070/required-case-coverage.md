# Required source-to-case coverage — not frozen

The former aggregate loader checked the33 declared obligation groups but did not require a crosswalk from separate source inventories to executable cases. A regression demonstrated that changing the real draft status to `FROZEN` was accepted by the loader without such a mapping. The repaired public loader rejects this with `SOURCE_COVERAGE`.

The new source index accounts for752 **source facts**, not752 distinct capabilities or required fits. Export declarations, function definitions, admission probes and inference routes overlap. Each fact retains its source inventory, original classification and row hash. Frozen R source bytes, exact namespace declarations and the declaration fixtures are checked; data declarations are parsed without evaluating their expressions.

| Inventory | Required core | Adapter | Rejected | Excluded |
|---|---:|---:|---:|---:|
| aghq | 27 | 2 | 9 | 1 |
| covariance | 37 | 2 | 56 | 0 |
| data | 28 | 0 | 28 | 0 |
| family | 21 | 1 | 33 | 14 |
| fit-input | 11 | 0 | 3 | 0 |
| inference | 0 | 71 | 23 | 4 |
| isdm | 20 | 0 | 17 | 0 |
| namespace | 172 | 8 | 0 | 35 |
| postfit | 100 | 0 | 0 | 0 |
| postfit-policy | 24 | 0 | 5 | 0 |

Of these facts,698 are non-excluded and currently lack reviewed executable-case links. The54 exclusion records include repeated representations of exclusions across inventories. The geo-preparation utility `add_utm_columns`, previously labeled non-core in the namespace census, is conservatively retained as an adapter obligation for scope review; its absence from Julia is not silently converted into a user-approved exclusion. Runtime DLL registration is an adapter requirement, not a Julia DLL API clone. No R-only presentation classification is used to discard numeric information.

## What freezing now requires

The frozen manifest must bind `required-source-index.json` and `required-source-case-map.json` by hash. Every known source fact appears exactly once in the map. Required and adapter facts need executable cases; rejected facts need executable negative cases; approved exclusions retain a reason. Unknown case IDs, orphan executable cases, duplicate facts, missing mappings, classification changes and absent rationale fail.

A separately stored scope-review receipt must bind that exact index and mapping, name the reviewer, link hashed review evidence, cover all seven programme domains and contain no unresolved scope branches. This record must come from an actual review; the mechanical checker verifies its bindings, not the truth of a reviewer's reasoning. No such review has been performed in this slice.

The index is explicitly **KNOWN_SOURCE_CENSUS_NOT_EXHAUSTIVE_SCOPE**. Further admission branches may exist outside these inventories. A complete map of this index alone cannot justify freezing; the semantic source sweep and independent review remain necessary. The real manifest stays DRAFT. Existing synthetic process/receipt tests explicitly isolate transport by using the metadata loader; they are not demonstrations of programme scope completion. The production entrypoints always use the source-coverage-aware loader.

## Remaining work, in dependency order

1. Resolve aliases and map namespace/postfit information to model and estimand contracts. Keep native Julia, formula and public R bridge reachability separate.
2. Turn admitted family/link/parameter and covariance branches into finite model cases. Retain all rejected combinations; do not create an assumed Cartesian product.
3. Bind data and inference guards to actual supported models, target parameters, conditioning and uncertainty. A source-helper check is not a fitted-object test.
4. Write the actual Stage1a AGHQ estimator and control cases, including warning/fallback behavior and excluded combinations.
5. Assign concrete fixtures, reference and Julia calls, model identity and acceptance rules to each executable row. The six qualified K1 binomial comparisons remain evidence candidates; they do not replace the older K2 smoke or unpaid formula/bridge coverage.
6. Review the complete source-branch scope, bind the review receipt, then freeze and run the required-case gate. Keep review and implementation states separate.

## Verification

`python3 tools/core070_verify_manifest_coverage.py` runs24 tests across coverage, collection, assertion counting and process evidence, plus the aggregate self-test. A positive small synthetic map and pinned review exercise the mechanism; negative controls cover omissions, changed classification, fake IDs, missing reasons, stale review and source hashes. The original relabeled-draft regression changed fromFAIL toPASS. Existing binomial qualification evidence still verifies; no numerical source, fixture or acceptance threshold changed.

The acceptance leaf was written after the first red regression and initial repair, rather than before them. This is recorded as a process miss; final checks were subsequently approved and re-run. No claim is made that the leaf existed before implementation.
