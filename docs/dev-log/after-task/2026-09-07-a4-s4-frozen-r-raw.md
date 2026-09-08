# After Task: A4/S4 source-attested frozen-R raw objective receipt

## Goal

Record the three frozen Gaussian A4/S4 R marginal objectives at one declared
coordinate vector, with source/build provenance strong enough to make the
result reusable as raw material but not to mislabel it as paired evidence.

## Implemented

`tools/destination_b/run_a4_s4_frozen_r_raw.R` is a fresh-process, R-only
runner.  It checks the externally supplied frozen-build receipt digest, exact
source fields, marker, installed-tree digest, the exact loaded non-symlink
package DLL, and runtime helper hashes.  For the non-unit-height tree,
pedigree retaining four ancestors, and once-ridged dense VCV, it reconstructs
the frozen data/formula, validates the random-effect-integrated TMB object,
and evaluates its declared coordinate twice.  Its point-only construction
explicitly requests `se = FALSE` and rejects a retained `sd_report`.  It
writes exactly one no-clobber RDS receipt.

The runner treats the historic legacy DLL hash only as fixture lineage: row
inputs retain source/fixture facts, while the top-level receipt records the
fresh build's actual DLL bytes.  The current `raw-frozen-r-02.rds` is
explicitly unqualified and admission-closed; `raw-frozen-r-01.rds` is
preserved as the pre-correction receipt rather than overwritten.

## Mathematical Contract

For the named R coordinate vector

\[
\theta_R = [b_{\mathrm{fix}}(1{:}3),\ \log \sigma_\epsilon,
\ \theta_{\mathrm{rr,phy}}(1{:}3)],
\]

the only evaluated quantity is the already random-effect-integrated frozen R
objective

\[
\operatorname{NLL}_R(\theta_R) = \texttt{fit\$tmb_obj\$fn}(\theta_R).
\]

The runner calls it twice after checking the TMB data, precision, determinant,
map, design, and integrated `g_phy` block.  It requests no construction-time
standard-error report and calls no post-construction Hessian or interval
route.  It does not calculate a Julia value, a delta, an own optimum, a
profile, coverage, or an admission decision.

## Files Changed

- `tools/destination_b/run_a4_s4_frozen_r_raw.R` — source-attested raw-R
  runner, safe pedigree/dense JSON decoders, immutable receipt writer.
- `test/test_destination_b_a4_s4_frozen_r_raw.R` — provenance, path,
  no-clobber, malformed scalar-array, and retained-fixture regression tests.
- `docs/dev-log/core070/destination-b-a4-s4/raw-frozen-r-02.rds` — current
  immutable point-only raw R receipt, SHA-256
  `63c087dad7c4d3cdcaffa349d732fbee721c25e69abd2ca2f1db5d0a349fe599`.
  `raw-frozen-r-01.rds` remains retained as the pre-correction receipt rather
  than being overwritten.
- `docs/dev-log/core070/destination-b-a4-s4/README.md` — distinguishes the
  new R-only receipt from paired evidence.
- `.unlazy/destination-b-a4-s4-frozen-r-raw/GATES.md` — ignored closeout
  acceptance ledger.
- `docs/dev-log/check-log.md` — check summary.
- This after-task report.

## Tests Added

`test/test_destination_b_a4_s4_frozen_r_raw.R` is the new direct R contract
suite.  It checks the exact non-symlink package DLL rule, independent
build/marker/tree verification, immutable publication, raw-request removal of
the legacy DLL field, a post-validation DLL mutation, all claim-boundary
fields, a retained real pedigree table, malformed nested parent arrays, and
the real dense 8-by-8 original VCV.

Tests of the tests: the retained pedigree initially failed in the live runner
because scalar JSON arrays were lists; the new decoder test first failed while
the helper was absent.  A reviewer then supplied a nested parent-list control,
which first reproduced acceptance and now rejects.  The dense list-matrix
test likewise first failed while its decoder was absent.  These are
representation/failure controls, not fitted-model recovery evidence.

## Benchmark Numbers

N/A — no Julia or R likelihood implementation changed.  The three-row raw
receipt took 2.1 seconds wall time, which is an execution receipt rather than a
speed claim.

## R-Parity Verdict

Parity: N/A — the receipt contains only R values.  No Julia objective, matched
delta, independently fitted comparison, or tolerance verdict was computed.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia source path changed.
- Allocs: N/A — no Julia inner-loop path changed.
- Aqua: N/A — no dependency, export, or `Project.toml` change.

## Checks Run

```text
Rscript --vanilla test/test_destination_b_a4_s4_frozen_r_raw.R
# A4_S4_FROZEN_R_RAW_UNIT_OK; exit 0

Rscript --vanilla test/test_destination_b_a4_s4_frozen_r_evaluator.R
# A4_S4_FROZEN_R_EVALUATOR_OK; exit 0

Rscript --vanilla test/test_destination_b_a4_s4_runner.R
# A4_S4_JSON_MATRIX_OK; exit 0

Rscript --vanilla tools/destination_b/run_a4_s4_frozen_r_raw.R ... raw-frozen-r-02.rds
# A4_S4_FROZEN_R_RAW_RECORDED_UNQUALIFIED; exit 0; 2.1 s

Independent RDS schema/repeat/no-legacy-row-DLL check
# A4_S4_RAW_SE_FALSE_RECEIPT_OK; exit 0

python3 tools/core070_build_oracle.py verify --destination .../oracle-build
# CORE070_ORACLE_VERIFY_PASS; exit 0
```

The base-R test scripts use `stopifnot` rather than a numerical test reporter,
so they expose success markers rather than assertion totals.  `Pkg.test()`,
the full/core Julia suite, JET, Aqua, and a Documenter rebuild were not run:
the touched code is a private R runner/internal evidence README, and the
estimated full package run remains separately approval-gated.

## Consistency Audit

Ran:

```text
rg -n "qualified|paired|raw|admission|objective|interval" docs/dev-log/core070/destination-b-a4-s4/README.md
rg -n "A4/S4|raw candidate|paired evidence|Destination B completion|0\\.7\\.1 parity" docs/dev-log/check-log.md docs/dev-log/after-task/2026-09-07-a4-s4-raw-candidate-contract.md docs/src README.md
```

The directory README now says that the RDS is raw R-only material, not paired
evidence.  No public README, API, tutorial, formula route, or capability table
changed.

## GitHub Issue Maintenance

No issue action.  The receipt neither opens the public `phylo_rr` route nor
changes FRK, which remains parked at `gllvmTMB#1275`.

## What Did Not Go Smoothly

1. A fresh source-attested compiler build has a different DLL hash from the
   historical fixture build.  Independent review required the runner to bind
   runtime DLL bytes to the build receipt/installed tree instead of claiming
   that old hash.
2. The first two live runner attempts stopped before receipt publication:
   pedigree scalar lists were indexed as vectors, then dense JSON rows were
   coerced to an 8-by-1 list matrix.  Both representation defects now have
   real-fixture tests; malformed nested parent arrays are fail-closed.
3. Independent claim review found that the initial receipt's default
   construction could compute a standard-error report.  The runner now sets
   `se = FALSE`, asserts no retained `sd_report`, and records the corrected
   point-only result as `raw-frozen-r-02.rds`; the original stays retained.
4. The RDS is intentionally no-clobber.  It should be inspected or superseded
   by a new named receipt, never overwritten.

## Team Learning

For frozen JSON evidence, validate its decoded R representation at each use
site; a byte-locked artifact can still arrive as a list shape unsafe for a
formula constructor.

## Remaining Risks

- The current receipt proves only that these loaded DLL bytes belong to this externally
  attested build; it does not claim a canonical/reproducible binary.
- Construction necessarily uses the frozen public optimiser, but its result is
  not retained or compared by this raw evaluator.
- Disabling construction-time `sdreport` does not supply an interval method;
  no Hessian, standard-error, or interval result is retained or compared.
- No Julia matched-point value, own optimum, interval, recovery, or coverage
  result exists here.
- The targeted tests do not replace full/core package, docs, or cross-platform
  checks.

## Known Limitations

This does not qualify A4/S4, S3b/S4, dense-VCV intervals, the public
`phylo_rr` formula route, 0.7.1 parity, Destination B completion, or FRK.

## Next Command

None for this immutable raw-R slice.  Start a separate, independently
reviewed paired-evaluator task before comparing this receipt with a Julia
consumer; do not repurpose it as admission evidence.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the raw receipt is source/build-bound,
independently reviewed, and explicitly fenced; all paired, interval, recovery,
public-admission, and programme claims remain open.
