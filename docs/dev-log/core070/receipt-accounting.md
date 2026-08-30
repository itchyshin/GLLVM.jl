# Count executions, retain all required case IDs

`assertion_counting = "execution_groups_v1"` is required for new aggregate receipts. Each cell carries sorted, nonempty `execution_case_ids`. A single-case call defaults to its own ID. The actual group helper records the complete requested group after one fixture execution.

Cells sharing a group must have identical membership, fixture path/hash and passed/failed/errored/broken counts. Groups must be disjoint and complete before aggregation. Each required cell still exists and must pass; grouping cannot remove an obligation or hide a failed member. The existing `actual_assertions` field counts unique **passed** assertions. Failed/error/broken counts remain in cells and block success; the Python counting helper retains each count category once per execution.

Independent executions of the same file use different groups and count separately. Filename-only deduplication is unsafe because the file may be run under different controls. A fixture with28 passes attributed to three families contributes28, not84. A synthetic cross-language check uses that shared execution plus two independent executions of the same file with2 and3 passes: five required IDs, one file, three executions,33 passed assertions.

Historical run files are immutable. The recovered16-family batch still contains273 attributed passes in its old raw metadata and217 unique passes/3 failures in its actual test log. Do not rewrite it to the new schema or promote it. Fresh current-source runs are needed for current aggregation. No likelihood, seed, model, tolerance or required-case inventory changed in this repair.
