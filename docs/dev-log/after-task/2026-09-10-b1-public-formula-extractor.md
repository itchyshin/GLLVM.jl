# After Task: B1 mixed public formula and extractor route

## Goal

Exercise the public Julia route for the actual B1 covariance mix: rank-one
latent `unit` plus independent `unit_obs`, `cluster`, and `cluster2` effects.

## Implemented

Added a deterministic public API test.  It supplies a two-trait wide response
matrix and one grouping-data row per response column, compares the `@formula`
route to the direct grouping route at identical zero-iteration starts, checks
all four named covariance extractions, and verifies that intervals are
withheld specifically because the deliberately zero-iteration fit is not
converged.

## Mathematical Contract

The tested interface builds the shared Gaussian covariance
`Z_unit Lambda Lambda' Z_unit' + sum_q Z_q D_q Z_q' + sigma_eps^2 I` for the
four declared sources.  This is an API/packing test only: it makes no claim
about frozen-R pairing, stationarity, interval feasibility, recovery, or
coverage.

## Files Changed

- `test/test_destination_b_public.jl` — mixed B1 formula/direct, extraction,
  and unavailable-interval assertions.
- `docs/dev-log/check-log.md` — exact focused-test record.
- `docs/dev-log/after-task/2026-09-10-b1-public-formula-extractor.md` — this
  report.

## Tests Added

`Destination B public mixed B1 grouping route` has 22 assertions.  It combines
the mixed B1 structure with the public formula interface and checks the
zero-iteration unavailable-interval boundary, so it would fail on an omitted
mapping, reordered incidence, missing extractor source, or silent interval
claim.

## Verification

`/Users/z3437171/.juliaup/bin/julia --startup-file=no --history-file=no --project=. test/test_destination_b_public.jl`
passed **39/39** in **10.0 s**.

Benchmarks: N/A — no hot-path source change.

Parity: N/A — this test changes neither likelihood nor bridge code.

- JET: N/A — no production hot path changed.
- Allocs: N/A — no production hot path changed.
- Aqua: N/A — no dependency/export/project change.

## Remaining Risks

The B1 frozen-R source-alignment control is still pending explicit approval.
If it passes, its separate paired test must add this balanced fixture's
independent Julia refit and empirical interval-feasibility checks.  Recovery
and coverage remain separate programme gates.

## Next Command

After approval, run the no-fit B1 frozen-R provenance preflight, then exactly
one bounded frozen-R control under its 45-minute estimate and 60-minute stop.

Rose verdict: PASS WITH NOTES — public-route coverage improved, but it does not
qualify B1 or substitute for the approved frozen-R and interval evidence.
