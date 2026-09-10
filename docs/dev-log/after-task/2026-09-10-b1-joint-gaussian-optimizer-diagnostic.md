# After-task — B1 joint Gaussian four-source optimizer diagnostic

## 1. Goal

Exercise the approved joint Gaussian B1 shape with all four grouping sources
and determine whether it can serve as a frozen-R matched-parameter acceptance
fixture.

## 2. Implemented

Added a deterministic two-trait, 36-observation joint fixture, frozen-R
receipt runner, symbolic alignment record, and registered Julia diagnostic.
The model uses rank-one `unit` latent covariance with `unique = FALSE`, plus
diagonal nested `unit_obs`, crossed `cluster`, and crossed `cluster2` sources.
No Julia likelihood source or gllvmTMB engine source changed.

## 3. What Changed the Next Action

All four source incidence systems now run together through the public Julia
fit interface and respond to two independent membership controls. The frozen
R optimizer point is not stationary enough to accept as a paired-parameter
reference, so the next joint B1 action is a new stationary R reference design
or a separately justified optimization protocol—not relaxing the comparator.

## 3a. Decisions and Rejected Alternatives

The fixture uses `latent(0 + trait | unit, d = 1, unique = FALSE)` for the
rank-one unit source, rather than adding an unidentifiable p=2 latent-plus-
unique decomposition. `unit_obs`, `cluster`, and `cluster2` use `indep()`.
The receipt preserves three same-data, same-initial-state R attempts:
default `nlminb`, tight-control `nlminb`, and BFGS. Rejected alternatives were
treating R convergence code zero as stationary, choosing BFGS because it is
documented for related fits despite its poorer score here, changing the seed
or fixture until a comparator passed, or widening the parameter tolerance.

## 4. Files Touched

`tools/destination_b/b1_joint_gaussian_reference.R`, the joint receipt and
symbolic alignment record, `test/test_destination_b_b1_joint_gaussian_paired_fit.jl`,
`test/runtests.jl`, `docs/dev-log/check-log.md`, and this report.

## 5. Checks Run

Frozen R 4.6.0 on gllvmTMB 0.7.0 recorded default maximum outer gradient
`2.1410189650930688e-5` at log likelihood `-32.847374868499401`. Tight
same-start `nlminb` returned the same point with convergence code 1; same-start
BFGS gave a lower log likelihood and larger gradient. The frozen-R-documented
same-data `n_init = 5` attempt improved the score to
`1.8152100309904722e-5`, but did not reach the `1e-6` stationary-reference
threshold.

`OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=158/299 Pkg.test()` passed 47/47 in
6.8 s. Full `Pkg.test()`, JET, Aqua, benchmarks, recovery, coverage, and
deployment were not run; they are neither necessary nor authorised for this
focused diagnostic.

## 6. Tests of the Tests

The test locks source, archive, installed shared-library, data, and runner
hashes; raw R coordinate ordering; the explicit non-acceptance gate; and all
four incidence patterns. It evaluates Julia at the retained R coordinates,
requires the exact likelihood agreement there, and separately changes a
crossed cluster2 membership and a valid same-parent unit_obs membership. It
also requires an independently optimized Julia result to converge with a small
gradient but deliberately makes no R-to-Julia refit equality assertion.

## 7a. Issue Ledger

No issue, push, merge, release, registry, or R-engine action was taken. FRK
remains parked at gllvmTMB#1275. The joint B1 acceptance row remains open.

## 8. Consistency Audit

The formula, coordinate conversion, source labels, seed, data hash, receipt
limitations, and test title all describe an optimizer diagnostic rather than a
qualified paired fit. Public documentation remains the already-published
experimental partial R-to-Julia bridge wording; it makes no 0.7 parity claim.

## 9. What Did Not Go Smoothly

The initial independent Julia refit differed from frozen R by more than the
one-micro-unit parameter tolerance despite objective agreement. Direct score
inspection showed that R's nominal convergence flag masked a non-negligible
outer gradient. Tighter same-start `nlminb` and BFGS did not repair this; the
documented five-start attempt reduced but did not repair it. The test was
rewritten to retain the barrier instead of hiding it.

## 10. Known Residuals

No stationary matched-parameter R reference is available yet for this joint
fixture. This is not a qualified joint B1 row, interval feasibility, recovery,
coverage, non-Gaussian joint evidence, S3b/S4, dense-vcv, FRK, 0.7.1, broad
0.7 parity, or Destination B completion.

## 11. Team Learning

An optimizer status code is not an evidence gate. Retaining the outer score,
same-start alternative attempts, and a named non-acceptance field prevents a
clean-running regression from being mistaken for statistical parity.

## 12. Cross-Product Coverage

One Gaussian family × one rank-one unit covariance × three diagonal grouping
covariances × one 2-trait, 36-observation fixed-seed shape. It covers direct
objective identity and incidence sensitivity only; it does not cover
independently fitted parameter parity, other covariances, families, sample
shapes, interval/recovery regimes, or public bridge admission.

## Rose Verdict

Rose verdict: PASS WITH BLOCKER — the diagnostic is independently reviewed and
honestly scoped, but its named joint B1 matched-parameter acceptance gate is
blocked by the non-stationary frozen-R reference.
