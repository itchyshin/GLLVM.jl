# After Task: grouped five-family interval-feasibility interior matrix

## 1. Goal

Strengthen the public Julia grouping route with one strict, identifiable
interior interval-feasibility matrix across all four grouping sources and the
five scoped response families.

## 2. Implemented

Added a deterministic public-API test with two traits and 96 observations. It
selects nonzero shared unit, nested unit_obs, crossed cluster, and diagonal
cluster2 terms for Gaussian, Poisson, Binomial, Beta, and NB2. Each family must
converge, have finite diagnostics and positive-definite curvature, return a
usable interval object, and return finite available variance intervals for
both traits at every source. The test also proves the four selected incidence
covariance bases are distinct and that changing each source affects the
objective. This validates an existing development route; it does not add a new
public API.

## 3a. Decisions and Rejected Alternatives

The retained test requires actual finite source-by-trait interval endpoints,
not merely construction of an interval object. Rejected alternatives were the
first one-trait boundary fixture, accepting unavailable intervals as success,
and treating this Julia-only cell as frozen-R parity or recovery evidence.

### Mathematical Contract

For every family, the shared linear predictor is

~~~math
\eta = D\gamma + \sum_s (Z_s \otimes L_s^*)a_s,
\qquad a_s \sim N(0, I).
~~~

Conditional on that predictor, each response follows its selected Gaussian,
Poisson, Binomial, Beta, or NB2 family with the route's link and nuisance
parameters. Only the Gaussian member additionally has a normal residual term.
There is one explicit incidence matrix Z_s for each selected grouping source.
The test requires pairwise separation of the induced Z_s Z_s' bases and rank
four for their stacked representation, then checks finite-curvature interval
extraction from the complete marginal objective. The complete packing and
transformation contract is in
docs/dev-log/decisions/destination-b-grouped-fit.md.

## 4. Files Touched

- test/test_destination_b_grouping_interval_matrix.jl — five-family,
  four-source interior feasibility and diagnostic matrix.
- test/runtests.jl — registered the focused test in the established shard.
- docs/dev-log/check-log.md — exact test tallies and scope boundary.
- docs/dev-log/core070/t12-grouping-levels-design.md — marks an obsolete
  Julia-surface snapshot as superseded while preserving its frozen-R record.

## 6. Tests of the Tests

One Test.jl file supplies 189 assertions. It exercises the public fit_gllvm and
interval extractors, compares each source against independent incidence-basis
and sensitivity calculations, and tests the malformed unused unit_obs label
path. Thus it satisfies both the independent-calculation and malformed-input
test-of-tests clauses.

## Benchmark Numbers

Benchmarks: N/A — the tranche adds validation and documentation only; no Julia
likelihood or sparse-linear-algebra hot path changed. The retained focused
matrix receipt completed in 20.2 s on the local Mac, so it remains below the
30-minute
compute gate.

## R-Parity Verdict

Parity: N/A — this is a Julia-only interval-feasibility cell. It does not
compare frozen gllvmTMB 0.7.0 estimates, objectives, parameters, or interval
endpoints.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia src hot path changed.
- Allocs: N/A — no Julia inner loop changed.
- Aqua: N/A — no exports, dependencies, or project metadata changed.

## 5. Checks Run

- julia --startup-file=no --project=. test/test_destination_b_grouping_interval_matrix.jl
  completed 189/189 in 20.2 s.
- GLLVM_TEST_SHARD=18/292 julia --startup-file=no --project=. test/runtests.jl
  completed 190/190 in 20.2 s.
- Full Pkg.test() was not run: it is a broader approval-gated run rather than
  evidence needed to validate this 20-second, test-only tranche.
- The repository-wide after-task executable is not green: it scans the whole
  active Unlazy program, whose parent Destination B ledger remains open and
  whose pre-existing destination-b-adapter, destination-b-tree,
  destination-b-uncertainty, and totoro-t4-p6-grid ledgers are unreadable.
  This report is a scoped checkpoint, not a closure of that parent ledger.

## 8. Consistency Audit

Ran rg "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md
docs CLAUDE.md and rg "340.?x|machine precision|closed.?form" README.md
docs/src docs/PERF-plus-design.md. README.md and docs/src/grouped-models.md
already describe the explicit current route. The material stale match was the
historical T12 Julia-surface inventory; it now carries a top-level
supersession notice. Route-specific Gaussian-only text in
docs/src/structured-term-fitting.md was retained because it names a different
Gaussian-only interface.

## 7a. Issue Ledger

No issue action needed: this validates one local development cell and the user
did not authorise a push, issue, merge, release, or public claim.

## 9. What Did Not Go Smoothly

The first one-trait fixture made most non-Gaussian variance intervals
unavailable. Independent review rejected it as interval-feasibility evidence.
The retained two-trait interior fixture explicitly requires available intervals
and was re-reviewed after that repair.

## 11. Team Learning

An interval test must require finite, target-level endpoints at an identifiable
interior configuration. Merely accepting an interval API or counting a
diagnostic object is not evidence that an interval is usable.

## Remaining Risks

- This is one fixed-seed, two-trait, 96-observation interior cell, not a
  recovery or coverage campaign.
- It is not frozen-R pairing, a public R-bridge admission, or a signed
  grouping parity result.
- Boundary, singular, small-sample, alternative covariance-mode, and
  realistic-size behaviours remain to be assessed separately.
- It does not qualify S3b/S4, dense vcv, pedigree, FRK, 0.7.1 parity, a
  release, or Destination B as a whole.

## 10. Known Residuals

The interval contract confirms availability and finite endpoint ordering for
this interior scenario only. It does not claim nominal coverage, narrow
intervals, or statistical identification in difficult designs.

## Next Command

none for this sub-slice — the parent Destination B ledger remains open; select
a signed paired or recovery row before using it to support any wider grouping
claim.

## 12. Cross-Product Coverage

This matrix covers the product of five named response families, four selected
grouping sources, one independent covariance-mode configuration, two traits,
one fixed seed, and interval availability at one interior shape. It does NOT cover frozen-R pairing, latent or dependent covariance modes, boundary or
small-sample designs, recovery/coverage, public bridge admission, or
realistic-size and real-data products.

## Rose Verdict

Rose verdict: PASS WITH NOTES — 189 focused assertions and independent review
support the stated interior feasibility cell; parity, recovery, coverage, and
broad robustness remain open.
