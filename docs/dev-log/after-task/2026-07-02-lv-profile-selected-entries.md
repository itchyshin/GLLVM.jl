# After Task: LV Profile Selected Entries

## Goal

Close the pre-existing dirty LV profile-selection work by validating and
banking selected-entry profile support for `B_lv`.

## Implemented

Added an internal `indices` option to `_lv_effect_profile()` so profile-LR can
be run for selected `vec(B_lv)` entries instead of every entry. The helper
validates non-empty, in-range, unique indices and returns the corresponding
subset of terms, estimates, and profile intervals. The profile solver now
warm-starts constrained refits from the nearest previous constrained solution
while stepping and bisecting.

## Mathematical Contract

No estimand changed. The profiled quantity remains `B_lv = Lambda * alpha_lv'`,
with profile deviance `D(c) = 2 * (nll_constrained(B_lv[i] = c) - nll_hat)`
inverted against the one-df chi-square cutoff for the selected entry. This is
an internal computation helper for canaries and diagnostics, not a public
source-specific `lv` exposure.

## Files Changed

src:

- `src/confint_family.jl`

test:

- `test/test_phylo_xlv.jl`

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-lv-profile-selected-entries.md`

## Tests Added

Added selected-entry checks in `test/test_phylo_xlv.jl`. These would have
failed before because `_lv_effect_profile()` did not accept `indices`; the test
also checks an out-of-range index failure path.

## Benchmark Numbers

N/A - no hot-path likelihood or fitting code changed. This changes an expensive
profile helper used for diagnostics.

## R-Parity Verdict

Parity: N/A - no R-facing bridge behavior or likelihood parameterisation
changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - internal profile helper change.
- Allocs: not run - no inner likelihood hot path changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
# bridge missing-response mask | 83 pass

julia --project=. --startup-file=no test/test_phylo_xlv.jl
# phylo × X_lv (Model A) | 25 pass

julia --project=. --startup-file=no test/test_lv_ci.jl
# X_lv Wald CIs — confint_lv_effects | 127 pass

git diff --check -- src/confint_family.jl test/test_phylo_xlv.jl
# passed, no output
```

## Consistency Audit

The change is internal. It does not add a public `confint_lv_effects()` argument,
does not expose source-specific `lv`, and does not alter the old Model A public
boundary. Selected-entry profile support is suitable for local canaries only.

## GitHub Issue Maintenance

No issue action needed. This is local handover work in the phylo `X_lv` branch.

## What Did Not Go Smoothly

The relevant CI tests are slow because they exercise profile and bootstrap
paths. They completed successfully.

## Team Learning

Fisher/Curie: selected-entry profile tooling should be explicit and tested,
because canary evidence should not require profiling every `B_lv` entry.

## Remaining Risks

- Profile-LR remains expensive and should be used selectively.
- This does not make old population-`B_lv` evidence positive.
- Source-specific `phylo_latent(..., lv = ~ x)` remains parked.

## Known Limitations

No public API is added. `indices` is an internal helper argument on
`_lv_effect_profile()`, not a documented user-facing feature.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && rg -n 'source-specific.*lv|ready to expose|partial support|active compute' docs/design docs/dev-log
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - selected-entry profile support is implemented
and tested as internal diagnostic tooling; public source-specific LV support
remains blocked.
