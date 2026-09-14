# After Task: Destination B G2 aggregate verification

## Goal

Record a reproducible current-head verification for the already implemented,
four-level grouping routes across the five approved response families.

## Implemented

No model code changed.  This slice reran the existing public `fit_gllvm`
fixtures in the isolated numerical-quality environment, recorded the aggregate
receipt, updated the programme ledger, and corrected one historical decision
note whose forward-looking wording had become stale.

## Mathematical Contract

For each admitted grouping source $q$, the public model contributes a shared
term $Z_q b_q$ to one predictor,

\[
\eta = X\beta + \sum_q Z_q b_q.
\]

The receipt checks the four distinct source identifiers in one joint fit rather
than independent per-unit solves.  The Gaussian route uses its exact marginal
path; the other four routes use the stated joint Laplace approximation.  See
`docs/dev-log/decisions/destination-b-joint-laplace.md` and
`docs/dev-log/decisions/destination-b-joint-identification.md`.

## Files Changed

- `.unlazy/destination-b/GATES.md` — local ignored programme ledger: G2 check
  and exact evidence.
- `docs/dev-log/core070/destination-b-g2/aggregate-verification-01.md` —
  immutable aggregate receipt.
- `docs/dev-log/decisions/destination-b-joint-laplace.md` — status supplement
  preserving, rather than deleting, the historical statement.
- `docs/dev-log/check-log.md` — actual command/tally summary.
- This after-task report.

## Tests Added

None: this is an evidence/ledger slice.  Existing tests were deliberately
re-executed.  Their Tests-of-the-Tests controls include a structural
nonidentification result, retained NB2 boundary unavailability, and a separate
36/36 four-family quadrature anchor.

## Benchmark Numbers

N/A — no hot-path code changed.  Focused test elapsed times are retained in
the aggregate receipt, not promoted as performance benchmarks.

## R-Parity Verdict

Parity: N/A — G2 verifies native Julia grouping routes only.  No frozen-R
fitted comparison was run; G3 and A4/S4 remain open.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia source change.
- Allocs: N/A — no Julia hot-path change.
- Aqua: N/A — no dependency, export, or project change.

## Checks Run

The focused quality-environment command in the aggregate receipt exited `0`:
Gaussian 63/63, Poisson 46/46, Binomial 58/58, Beta 63/63, NB2 small-fixture
55/55, and NB2 replication 61/61 (346 passing assertions total).  Separate
four-family scalar quadrature exited `0`, 36/36 in 3.9 seconds.

## Consistency Audit

Ran these exact searches:

```sh
rg -n 'Destination B|grouping|phylo_rr|parity|G2' README.md CLAUDE.md docs/src docs/PERF-plus-design.md
rg -n 'Gaussian only|not yet implemented|planned next|TODO|FIXME' README.md CLAUDE.md docs/src docs/PERF-plus-design.md
rg -n 'gllvmTMB|R reference|read.?only reference' README.md CLAUDE.md docs/src docs/PERF-plus-design.md
```

Current public documentation consistently retains partial-parity and closed
`phylo_rr` language.  The stale forward-looking line in the joint-Laplace
decision note is now explicitly superseded without rewriting history.

## GitHub Issue Maintenance

No issue action: this local evidence receipt neither opens a new capability nor
authorizes a push, merge, release, or public claim.

## What Did Not Go Smoothly

The n=96 NB2 fixture still cannot supply every source-variance interval, and
the Gaussian rank-one-plus-unique fixture remains structurally redundant.
Those outcomes are retained as diagnostics; neither was altered to get a pass.

## Team Learning

Aggregate current-head evidence is useful only when it preserves the hard
cells beside the successful ones and names the gate it actually closes.

## Remaining Risks

- G2 is not frozen-R parity or phylogenetic-formula admission.
- The G2 fixtures are deterministic, fixed-seed checks rather than recovery or
  coverage evidence.
- Full/core regression, user-workflow verification, and final independent
  reviews remain programme gates.

## Known Limitations

The checked scope is exactly the four named sources and five named families;
it does not generalize to every covariance parametrization, response family,
or group layout.  FRK remains parked at `gllvmTMB#1275`.

## Next Command

Build the separate A4/S4 source-overlay paired-fit acceptance harness for the
existing tree, pedigree-with-ancestors, and dense-`vcv` fixtures while keeping
the public R formula route closed.

## Rose Verdict

Rose verdict: PASS WITH NOTES — bounded G2 evidence is current and independently
reviewed; all frozen-R, phylogenetic, recovery, full-regression, and programme
completion claims remain explicitly open.
