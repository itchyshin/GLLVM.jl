# After-task — B1 crossed Gaussian cluster2 paired fit

## 1. Goal
Retain one frozen-R 0.7.0 / Julia same-data Gaussian `cluster2` pair with a crossed, replicated design and explicit evidence limits.

## 2. Implemented
Added a frozen-R receipt runner, symbolic alignment record, machine-readable receipt, and registered Julia regression for diagonal `cluster2` covariance. No Julia likelihood source or gllvmTMB engine source changed.

## 3. What Changed the Next Action
The candidate now has one paired crossed diagonal `cluster2` result, completing the four individual B1 source-alignment leaves. The next B1 work is joint-grouping evidence, then its required interval/recovery work; S3b/S4 remains a separate authorised line.

## 3a. Decisions and Rejected Alternatives
Used `indep(0 + trait | cluster2_id)` / `GroupingTerm(:cluster2; mode=:indep)`, not a latent or dependent structure: both R and Julia restrict this tier to diagonal covariance. Used named R `parList(opt$par)` reconstruction and deliberately reordered it for Julia. An independent source audit found that treating the Julia order as R's raw optimizer order would be a P1 error; the receipt now retains trait levels and `X_fix_names` to make the ordering auditable.

## 4. Files Touched
`tools/destination_b/b1_cluster2_gaussian_reference.R`, the B1 cluster2 receipt and symbolic alignment record, `test/test_destination_b_b1_cluster2_paired_fit.jl`, `test/runtests.jl`, check log, and this report. The cumulative foundation handoff was corrected because `cluster2` is no longer outstanding. No public docs or exports changed.

## 5. Checks Run
Frozen R 4.6.0 fit: convergence 0; logLik `-2.9311750821141498`. After the runner provenance corrections, `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=157/298 Pkg.test()` passed 32/32 in 6.1 s. Receipt-integrity, diff-whitespace, after-task structure, and independent-review recheck remain to run. No full suite, JET, Aqua, benchmark, recovery, coverage, or deployment ran.

## 6. Tests of the Tests
The registered test began red because its receipt did not exist. The first generated receipt omitted the runner hash; the test failed on that missing provenance field after 20 assertions, and the generator was corrected to calculate its own hash before the final rerun. Independent review then required raw R outer-coordinate provenance and direct crossed-design assertions. The final test locks source/version/archive/shared-library/data/runner/trait-order identities, raw `[b_fix; log_sigma_eps; theta_diag_cluster2]` order, the deliberate Julia reorder, both directions of the four-unit by six-cluster2 crossing, fixed R coordinates, an independent Julia refit, and a non-bijective membership control.

## 7a. Issue Ledger
No issue action: this is an unpushed local candidate and no GitHub action was authorised. FRK remains parked at gllvmTMB#1275. Joint B1 grouping, S3b/S4, intervals, recovery, and full package verification remain open programme work.

## 8. Consistency Audit
The alignment record, R runner, receipt, and Julia test use the same diagonal cluster2 formula, named R-to-Julia coordinate reordering, six-group/four-shared-unit/two-repeat design, trait ordering metadata, and frozen source locks. README continues to describe an experimental partial R-to-Julia bridge, not 0.7 parity.

## 9. What Did Not Go Smoothly
The first direct red-test invocation bypassed the test environment and could not load JSON3; registration in the normal shard exposed the intended missing-receipt failure. The first receipt then omitted the runner hash; the failing assertion led to a generator repair and fresh frozen-R run, not a weaker lock.

## 10. Known Residuals
One p=2, n=48, crossed diagonal Gaussian fixture only. No joint grouping, latent/full cluster2 covariance, interval feasibility, recovery/coverage, non-Gaussian, phylogeny, dense-vcv, public formula bridge, `engine="julia"`, 0.7.1, broad 0.7, or Destination B completion evidence.

## 11. Team Learning
An independent source audit is valuable even when an R-to-Julia test passes: a deliberate conversion can hide a false statement about native coordinate order. Named extraction plus stored trait ordering makes the intended conversion inspectable.

## 12. Cross-Product Coverage
One family (Gaussian) × one cluster2 covariance (diagonal) × one crossed design × one fixed interior fixture. This slice does NOT cover REML, penalties, missingness, aggregation, joint terms, other covariance structures, families, sizes, or interval/recovery regimes.

## Rose Verdict
Rose verdict: PASS WITH NOTES — fresh independent re-review found no P0/P1/P2 issue after raw R coordinate provenance and crossed-design assertions were added. The Destination B programme remains unqualified for the residuals above.
