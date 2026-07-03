# After Task: Bridge CI Doc Boundary Alignment

## Goal

Move beyond the LV closeout by reconciling public documentation with the current
grouped-dispersion and ordinal CI bridge evidence.

## Implemented

- Replaced the stale README install command with the GitHub install route used
  while GLLVM.jl is not in the General registry.
- Tightened README feature wording for response-missing masks and CI routes.
- Aligned `docs/src/roadmap.md`, `docs/src/confidence-intervals.md`, and
  `docs/src/gllvmtmb-parity.md` so they agree that grouped NB2/NB1/Beta/Gamma
  CI endpoints are routed, while grouped Tweedie and per-trait ordinal endpoints
  remain follow-ups.
- Updated the bridge CI test comment so it no longer says grouped-dispersion CI
  engines are still absent.

## Mathematical Contract

N/A - no likelihood, optimiser, bridge payload, or interval calculation changed.

## Files Changed

docs:

- `README.md`
- `docs/src/roadmap.md`
- `docs/src/confidence-intervals.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-bridge-ci-doc-boundary-alignment.md`

tests:

- `test/test_bridge_ci.jl`

## Tests Added

None. One stale test comment was corrected.

## Benchmark Numbers

N/A.

## R-Parity Verdict

No new R-parity claim. This records the existing bridge truth: grouped
NB2/NB1/Beta/Gamma CIs are routed; grouped Tweedie, per-trait ordinal CIs, and
mixed-family CIs remain gated.

## JET / Allocs / Aqua Verdicts

- JET: not run.
- Allocs: not run.
- Aqua: not run.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_grouped_dispersion.jl
# bridge grouped dispersion default | 121 pass

julia --project=. --startup-file=no test/test_bridge_ci.jl
# bridge CI routing | 64 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n "Pkg\\.add\\(\\\"GLLVM\\\"\\)|Grouped-dispersion fits and per-trait ordinal cutpoint fits|grouped-dispersion bridge endpoints remain explicit unavailable|grouped-dispersion and per-trait ordinal-cutpoint point payloads|mixed-family R bridge is partial|every non-Gaussian family" README.md docs/src test
# only the intentional docs homepage sentence remains:
# docs/src/index.md: GLLVM.jl is not yet in the General registry, so `Pkg.add("GLLVM")` will not resolve.

git diff --check -- README.md docs/src/roadmap.md docs/src/confidence-intervals.md docs/src/gllvmtmb-parity.md test/test_bridge_ci.jl
# clean, no output
```

## Consistency Audit

The public wording now separates implemented grouped-dispersion CI rows from
gated Tweedie, per-trait ordinal, and mixed-family CI endpoints. The LV boundary
is unchanged: source-specific `lv` remains parked and no source-specific grammar
is exposed.

## GitHub Issue Maintenance

No issue or PR action taken.

## What Did Not Go Smoothly

The first broad search was too noisy; the useful signal came from narrowing to
top-level docs and bridge CI tests.

## Team Learning

Rose: capability prose must distinguish engine support, bridge admission, and
unavailable-status rows. Hopper: bridge ledger status should be reflected in
docs as exact row-level truth, not broad "all" language.

## Remaining Risks

- Full `Pkg.test()` is still not available from tonight's run.
- The docs build still emits pre-existing local-link warnings unrelated to this
  slice.

## Known Limitations

This is a documentation and comment alignment slice only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_postfit_zib_tweedie.jl
```

## Rose Verdict

Rose verdict: OK for this slice. The changed wording is narrower than the
previous public surface and does not promote a new bridge or LV capability.
