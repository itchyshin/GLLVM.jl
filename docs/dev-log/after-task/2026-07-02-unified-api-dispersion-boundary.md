# After Task: Unified API Dispersion Boundary

## Goal

Verify and document the unified `fit_gllvm` routing for grouped dispersion and
its structural-variant guard.

## Implemented

- Added user-facing response-family docs for
  `fit_gllvm(...; disp_group = :species)` and explicit integer group vectors.
- Documented that grouped dispersion is a single specialised route and is not
  combined with `row_eff` or Gaussian `pervar` in the same call.
- Kept unsupported-family behavior as fail-loud `ArgumentError` wording.

## Mathematical Contract

N/A - no fit routing, likelihood, or error behavior changed.

## Files Changed

docs:

- `docs/src/response-families.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-unified-api-dispersion-boundary.md`

## Tests Added

None.

## Benchmark Numbers

N/A.

## R-Parity Verdict

No new R bridge claim. This records Julia unified-API routing that mirrors
gllvm-style keywords.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_unified_api.jl
# fit_gllvm unified API - keyword routing | 22 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'disp_group = :species|Grouped dispersion is a single|unsupported families fail|row_eff|pervar|fit_gllvm\\(Yc; family = NegativeBinomial' docs/src/response-families.md docs/src/tutorial.md docs/src/gllvmtmb-parity.md README.md
# new response-family docs plus existing related references

git diff --check -- docs/src/response-families.md
# clean, no output
```

## Consistency Audit

The docs now match `test/test_unified_api.jl`: `disp_group = :species` and an
explicit length-`p` integer vector route to grouped-dispersion fitters, while
unsupported families and combined variant requests fail loudly.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

Nothing material.

## Team Learning

Boole: gllvm-style keyword aliases need user-facing docs as well as docstrings.
Rose: the no-combination guard is part of the public truth and should be stated.

## Remaining Risks

- Full `Pkg.test()` is still not available from tonight's run.
- The docs build still emits pre-existing local-link warnings unrelated to this
  slice.

## Known Limitations

This is documentation-only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_missing_response_extra.jl
```

## Rose Verdict

Rose verdict: OK. The docs now expose the tested unified route without implying
unsupported combinations.
