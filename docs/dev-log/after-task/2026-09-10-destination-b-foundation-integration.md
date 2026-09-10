# After Task: Destination B foundation integration candidate

## Goal

Replay the authorised Destination B implementation onto current GLLVM.jl while
preserving the published landing mark, and remove the S4 formula-receipt merge
barrier without treating a scaffold as R--Julia evidence.

## Implemented

Local-only candidate commits `154bc848`, `84801781`, `5f1e50f1`, and
`f422412c` bring in the shared grouping engine, multivariate precision
consumer, bounded bridge materials, and corrected S4 formula contract. The
previous SVG hero declaration was removed so the published Image 2.5 PNG mark
remains the only landing hero. The S4 receipt test is now part of
`test/runtests.jl`.

Fresh review then corrected two candidate defects. Synthetic in-memory
attestations can now be used only with `allow_synthetic = true` and return a
synthetic status; the default validator rejects them. The grouped unpacker now
uses a concrete unique-variance vector rather than `Any[]`.

## Mathematical Contract

The grouped Gaussian route retains the documented marginal model
\(\eta = X\beta + \sum_q Z_q b_q\), with each `Z_q` an incidence matrix and
each selected term contributing its own trait covariance. The precision route
retains the frozen-R transport convention, including the dense-`vcv`
ridged-once canonical precision; it does not reinvert in Julia. See
`docs/dev-log/decisions/destination-b-grouped-fit.md` and
`docs/dev-log/decisions/destination-b-transport-conventions.md`.

## Files Changed

- `src/`: grouped Gaussian/Laplace/profile implementation, multivariate
  precision consumer, formula and public dispatch wiring from the foundation;
  `src/grouped_fit.jl` additionally makes unique variances concrete.
- `test/`: grouped, precision, interval, bridge and S4 contract coverage;
  `test/runtests.jl` includes the S4 validator; the new concrete-container
  assertion is in `test/test_grouped_gaussian.jl`.
- `docs/`: Destination B contracts, retained non-promotional evidence,
  grouping/precision guides, check log, and this report. `README.md` now
  repeats the experimental partial R-to-Julia, not-0.7-parity boundary.

## Tests Added

- S4 synthetic-fixture rejection: failed before the repair because the
  default validator accepted invented attestations; now passes and exercises
  the explicit failure path.
- Grouped concrete-unique container: failed before the repair with
  `Any === Union{Nothing,Vector{Float64}}`; now passes.
- Existing grouped dense-oracle and precision sparse-vs-dense tests remain the
  independent-calculation safeguards for the imported numerical kernels.

## Benchmark Numbers

N/A — this integration repairs a container type and evidence boundary; no
speed claim or benchmark comparison was made.

## R-Parity Verdict

Not qualified. The frozen R 0.7.0 records are retained provenance and fixed
coordinate checks, not a fresh paired fit/recovery result. S3b/S4 public
admission remains closed because `phylo_dep()` structured Julia transport and
its interval mapping are not admitted.

## JET / Allocs / Aqua Verdicts

- JET: not separately run for the new grouped unpacker in this slice; the
  concrete-container regression test addresses the reviewed hot-path finding.
- Allocs: not measured; no allocation or speed claim is made.
- Aqua: `Pkg.test()` was launched in its quality environment, but this session
  lost the final child-process terminal receipt; do not treat it as green.

## Checks Run

- `test/test_destination_b_a4_s4_public_r_formula_receipt.jl`: 27 passed,
  0 failed, 0 errored (0.8 s).
- `test/test_grouped_gaussian.jl`: 26 passed, 0 failed, 0 errored (3.3 s).
- Earlier integrated focused cohort: 292 passed assertions across grouped
  Gaussian/fitter/public/fixed-coordinate, four-level interval, and
  multivariate precision tests.
- `julia --project=. test/runtests.jl`: unsharded driver listed 294 files and
  returned cleanly; the environment did not preserve a per-assertion tally.
- `Pkg.test()`: launched but not counted as a verdict, as above.

## Consistency Audit

Searched `README.md`, `docs/src`, and `docs/PERF-plus-design.md` for
`Gaussian only|not yet implemented|planned next|TODO|FIXME|340.?x|machine precision|closed.?form|gllvmTMB|R reference|read.?only reference`.
The landing and README retain partial-bridge wording. Historical documents
remain as records rather than being rewritten.

## GitHub Issue Maintenance

No issue action: this is a local candidate; no push, merge to `main`, release,
registry action, or FRK action was authorised. FRK remains parked at
gllvmTMB#1275.

## What Did Not Go Smoothly

The initial merged S4 test could be misread as evidence because its fabricated
receipt used fresh-attestation labels. Independent review caught it before
promotion. The outer `Pkg.test()` launcher yielded control before its child
produced a durable terminal receipt, so full quality status remains explicitly
unverified.

## Remaining Risks and Next Command

This candidate is not a Destination B qualification. Required next work is a
reviewed structured `phylo_dep()` Julia transport/interval route, live paired
R--Julia receipts, independent recovery, and a retained full-suite quality
receipt. Resume with:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Rose verdict: FAIL — local integration is coherent, but full quality receipt,
live S3b/S4 pairing, and recovery evidence are still absent; no completion or
parity claim is permitted.
