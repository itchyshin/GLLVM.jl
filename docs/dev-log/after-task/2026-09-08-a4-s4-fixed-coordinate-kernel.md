# After Task: A4/S4 source-attested fixed-coordinate kernel check

## Goal

Turn the retained source-attested, R-only A4/S4 raw objective record into a
strictly private same-coordinate Julia-kernel check, while preserving the
frozen source/build provenance and without widening any public or statistical
claim.

## Implemented

`tools/destination_b/export_a4_s4_frozen_r_raw_summary.R` is an RDS-to-JSON
adapter.  It accepts only the current `raw-frozen-r-02.rds` schema and exact
three-row source/map/precision contract; it neither loads `gllvmTMB`, refits a
model, starts Julia, nor calculates a delta.  It publishes a no-clobber raw
summary with the input RDS SHA-256 and the dynamic fresh-build provenance.

`tools/destination_b/a4_s4_fixed_coordinate_evaluator.jl` consumes that
summary and calls only `GLLVM._precision_multivariate_nll` at the declared
coordinates.  It reorders

\[
\theta_R=[b_1,b_2,b_3,\log\sigma_\epsilon,\lambda_1,\lambda_2,\lambda_3]
\]

to Julia's `[beta; lambda; log_sd_residual_shared]`, uses rank one,
`:barelowrank`, a shared residual, and `sigma2_phy = 1`.  Its optional output
path is no-clobber and atomic.  Neither tool calls the bridge, an optimizer,
an interval routine, or a public formula route.

The retained result is
`docs/dev-log/core070/destination-b-a4-s4/fixed-coordinate-kernel-cross-evaluation-02.json`,
SHA-256 `977b57d5a52cb7a0b7e278bcecf38825778d91a7a04ae1cdb3dc11b302ceac17`.
It has output schema `destination-b-a4-s4-fixed-coordinate-kernel-cross-evaluation-2`
and is explicitly `qualified = false`, admission-closed, and a
`private_kernel_cross_evaluation`.

## Mathematical Contract

For each prescribed tree, pedigree, and dense row, both values are negative
marginal log likelihoods.  The recorded difference is therefore

\[
\Delta = \operatorname{NLL}_{\mathrm{Julia}}(\theta_J)
       - \operatorname{NLL}_{R}(\theta_R),
\]

not a sign-flipped comparison and not a comparison only up to an arbitrary
constant.  The retained values are:

| Row | R NLL | Julia NLL | Delta |
| --- | ---: | ---: | ---: |
| tree, non-unit height | 18.562779828405443 | 18.562779828405443 | 0 |
| pedigree, 4 ancestors retained | 21.948928545782763 | 21.948928545782771 | 7.1054273576010019e-15 |
| once-ridged dense VCV | 7.627081699167352 | 7.6270816991673573 | 5.3290705182007514e-15 |

Before the Julia kernel is reached, its evaluator SHA-binds the shared
fixture, the row reference, the precision-source file, and the decoded
little-endian Float64 response bytes.  It separately preserves the repeated
16-observation `species_id`, the unique tip-to-augmented map, inherited tree
scale 4 / pedigree-dense scale 1, and the dense one-ridge convention.

## Files Changed

- `tools/destination_b/export_a4_s4_frozen_r_raw_summary.R` — strict R-only
  raw evidence summary adapter.
- `test/test_destination_b_a4_s4_frozen_r_raw_summary.R` — summary schema,
  provenance, no-clobber, and inert-route tests.
- `tools/destination_b/a4_s4_fixed_coordinate_evaluator.jl` — private,
  byte-bound fixed-coordinate Julia kernel evaluator.
- `test/test_destination_b_a4_s4_fixed_coordinate_evaluator.jl` — coordinate,
  normalizer, map, scaling, ridge, mutation, CLI, and provenance tests.
- `docs/dev-log/core070/destination-b-a4-s4/fixed-coordinate-kernel-cross-evaluation-02.json`
  — retained unqualified v2 record.
- `docs/dev-log/core070/destination-b-a4-s4/README.md` and
  `docs/dev-log/check-log.md` — evidence boundary and check record.
- This report.

## Tests Added

The R test starts from a legal raw-4-shaped fixture, then rejects substituted
source pin, source-provenance marker, status, `sdreport` boundary, response
hash, augmented map, and precision determinant.  It also checks the current
raw-02 artifact read-only and refuses an existing output.

The Julia test verifies the coordinate permutation and full-normalizer dense
Gaussian NLL independently, validates all three maps/scales, rejects a
double-scaled tree and twice-ridged dense precision, and mutates copied
fixture/reference/precision-source bytes.  It also checks malformed summaries,
no-clobber/symlink CLI failures, and the v2 runner/source provenance fields.

## Benchmark Numbers

N/A.  This is a three-row fixed-coordinate check, not a performance claim.
The fresh R summary took under one second; the three Julia evaluations took
about six seconds after package load in this run.  Those timings are execution
receipts, not benchmarks.

## R-Parity Verdict

**Fixed-coordinate kernel agreement only.**  The three declared R and Julia
NLLs agree to the displayed floating-point differences above.  This is not
independent optimizer agreement, a bridge result, a public formula result,
interval feasibility, recovery, coverage, S3b/S4 qualification, 0.7.1 parity,
or Destination B completion.

## JET / Allocs / Aqua Verdicts

- JET: not run; the new code is a private tools harness, not a hot exported
  package path.
- Allocs: not run; no performance claim is made.
- Aqua: not run; no dependencies, exports, or project metadata changed.

## Checks Run

```text
Rscript --vanilla test/test_destination_b_a4_s4_frozen_r_raw_summary.R
# A4_S4_FROZEN_R_RAW_SUMMARY_OK; exit 0

julia --project=. --startup-file=no test/test_destination_b_a4_s4_fixed_coordinate_evaluator.jl
# 45/45; A4_S4_FIXED_COORDINATE_EVALUATOR_OK; exit 0; 26.6 s

Rscript --vanilla tools/destination_b/export_a4_s4_frozen_r_raw_summary.R \
  docs/dev-log/core070/destination-b-a4-s4/raw-frozen-r-02.rds \
  /private/tmp/a4s4-fixed-coordinate-v2.pSfJFK/raw-summary.json
# A4_S4_FROZEN_R_RAW_SUMMARY_OK; exit 0

julia --project=. --startup-file=no tools/destination_b/a4_s4_fixed_coordinate_evaluator.jl \
  /private/tmp/a4s4-fixed-coordinate-v2.pSfJFK/raw-summary.json \
  docs/dev-log/core070/destination-b-a4-s4/fixed-coordinate-kernel-cross-evaluation-02.json
# exit 0

Independent retained-receipt R/jsonlite assertions
# A4_S4_FIXED_COORDINATE_V2_RETAINED_RECEIPT_OK; exit 0
```

The full `Pkg.test()` suite remains separately approval-gated: prior measured
planning puts it at roughly 55–70 minutes.  The full/core package suites,
JET, Aqua, and a docs-site build were not run for this private tools-and-dev-log
slice.

## Consistency Audit

Ran
`rg -n 'fixed-coordinate-kernel-cross-evaluation-(0[12])|private_kernel_cross_evaluation|qualified = false|0\\.7\\.1 parity|Destination B completion' docs/dev-log/core070/destination-b-a4-s4 docs/dev-log/check-log.md docs/dev-log/after-task/2026-09-08-a4-s4-fixed-coordinate-kernel.md`;
all current references retain the private, unqualified boundary.  Ran
`rg -n 'phylo_rr|A4/S4|Destination B' README.md docs/src docs/PERF-plus-design.md CLAUDE.md || true`;
the public documentation continues to say that `phylo_rr` admission is closed,
and no public page was changed by this slice.

An independent reviewer first found a P1: the evaluator carried declared
hashes but did not bind the fixture/reference/precision bytes it actually
read.  The repair hashes those files before parsing and recomputes response
bytes; mutation tests prove each byte gate.  A second fresh review issued
**CLEAN** and confirmed that v2 carries the four immutable identities per row,
names the direct precision kernel sources, and retains the private,
unqualified boundary.

The first local output lacking those in-artifact byte identities was not
retained in the repository.  The final v2 artifact is a fresh post-repair run.

## GitHub Issue Maintenance

No issue action.  This does not open the public `phylo_rr` route or alter the
frozen R oracle.  FRK remains parked at `gllvmTMB#1275`.

## What Did Not Go Smoothly

1. The initial synthetic evaluator test added a `kind` field to the canonical
   map although the real raw R record has only six map fields.  End-to-end
   review caught this before it could become retained evidence; the evaluator
   now derives kind from the separately validated row.
2. The first evaluator version compared declared hashes but did not hash the
   bytes it read.  Independent review identified the gap; byte gates and
   mutation tests were added before the final run.
3. The first post-repair output did not itself identify the evaluator/source
   state.  Output schema v2 now carries input, evaluator, and direct-kernel
   source hashes marked `runner_recorded_unverified` where appropriate.

## Team Learning

For a frozen cross-language record, validate both levels: the transport
document must carry immutable identities, and the consumer must independently
hash the files it actually reads.  Otherwise a correctly shaped receipt can
mask a changed numerical input.

## Remaining Risks

- The R summary adapter reads a retained source-attested RDS; it does not
  reopen or rebuild the R installation.  The raw-R runner/build verification
  remains the source of that build attestation.
- Julia runner hashes record the loaded files and input summary but are not a
  signed source-build proof.
- This is one fixed coordinate in three Gaussian rows.  It says nothing about
  either engine's optimizer behaviour away from that point.
- No interval, recovery, coverage, public workflow, or real-data evidence is
  supplied by this slice.

## Known Limitations

This does not qualify A4/S4, S3b/S4, dense-VCV intervals, the public
`phylo_rr` formula route, grouping B1, 0.7.1 parity, Destination B completion,
or FRK.

## Next Command

Start a fresh, independently scoped bridge/own-optimum or interval slice only
after reconciling it with the existing A4/S4 bridge contract.  Do not repurpose
this private kernel record as public or paired-evidence admission.

## Rose Verdict

Rose verdict: **PASS WITH NOTES** — independent review found and closed the
map-shape and actual-byte-binding defects before the v2 artifact was retained.
The result is useful as a source-attested fixed-coordinate kernel identity
check, but all bridge, optimization, interval, recovery, public-admission, and
programme gates remain open.
