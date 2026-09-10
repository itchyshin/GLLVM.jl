# After-task — B1 crossed Gaussian cluster paired fit

## 1. Goal
Retain one frozen-R 0.7.0 / Julia same-data Gaussian `cluster` pair with an actually crossed, replicated design and explicit evidence limits.

## 2. Implemented
Added a frozen-R receipt runner, a retained machine-readable receipt, and a registered Julia regression for diagonal cluster-tier covariance. The existing symbolic alignment record now records the executed fixture and test. No Julia likelihood source or gllvmTMB engine source changed.

## 3. What Changed the Next Action
The candidate now has one paired crossed diagonal `cluster` result. The next B1 leaf is a distinct paired Gaussian `cluster2` fixture; joint grouping, intervals, recovery, S3b/S4, and all-parity claims remain outside this slice.

## 3a. Decisions and Rejected Alternatives
Used `indep(0 + trait | cluster_id)` / `GroupingTerm(:cluster; mode=:indep)`, not a latent factor or a unit effect. Four unit labels recur across each of six clusters, so `cluster` is genuinely crossed with the unselected unit axis. A first fixture made unit labels depend on cluster, which was nested rather than the declared crossed design; independent review caught it, and the runner, receipt locks, and test were regenerated rather than weakening the claim.

## 4. Files Touched
`tools/destination_b/b1_cluster_gaussian_reference.R`, the B1 cluster receipt and symbolic alignment record, `test/test_destination_b_b1_cluster_paired_fit.jl`, `test/runtests.jl`, check log, and this report. No public docs or exports changed.

## 5. Checks Run
Frozen R 4.6.0 fit: convergence 0; logLik `-9.3696900475934175`. After the crossed-design correction, `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=156/297 Pkg.test()` passed 20/20 in 5.8 s. Receipt identity check, `git diff --check`, and the after-task structure validator passed. The validator reports the inherited Unlazy ledger as not runnable, so gate state remains UNKNOWN rather than satisfied. No full suite, JET, Aqua, benchmark, recovery, coverage, or deployment ran.

## 6. Tests of the Tests
The regression binds the source/version/archive/shared-library/data/runner identities, formula, convergence, response shape and ordering. It matches fixed R coordinates and an independent Julia refit, then moves one observation to a different cluster; the likelihood must change. The reviewer initially found that the design was nested despite the intended crossed claim. The receipt was regenerated using shared `unit_1` through `unit_4` labels across clusters, and the focused Julia shard reran against that exact replacement receipt.

## 7a. Issue Ledger
No issue action: this is an unpushed local candidate and no GitHub action was authorised. FRK remains parked at gllvmTMB#1275. B1 `cluster2`, joint groupings, S3b/S4, intervals, recovery, and full package verification remain open programme work.

## 8. Consistency Audit
The alignment record, R runner, receipt, and Julia test all use the same diagonal cluster formula, packed-coordinate order, six-cluster/four-shared-unit/two-repeat shape, and frozen source locks. README continues to describe an experimental partial R-to-Julia bridge, not 0.7 parity.

## 9. What Did Not Go Smoothly
The initial fixture was accidentally nested because a unit label embedded the cluster label. The independent reviewer correctly classified that as a P1 evidence-scope error. The correction changed the data-generating design, then regenerated the receipt and its hashes; it was not an editorial relabeling.

## 10. Known Residuals
One p=2, n=48, crossed diagonal Gaussian fixture only. No latent or full cluster covariance, `cluster2`, joint groupings, interval feasibility, recovery/coverage, non-Gaussian, phylogeny, dense-vcv, public formula bridge, `engine="julia"`, 0.7.1, broad 0.7, or Destination B completion evidence.

## 11. Team Learning
Noether-style review of the declared incidence geometry is essential: a formula can be correct while the retained data silently instantiate a different nesting relation. The fixed receipt hashes make the corrected design auditable.

## 12. Cross-Product Coverage
One family (Gaussian) × one cluster covariance (diagonal) × one crossed design × one fixed interior fixture. This slice does NOT cover REML, penalties, missingness, aggregation, other grouping levels, joint terms, covariance structures, families, sizes, or interval/recovery regimes.

## Rose Verdict
Rose verdict: PASS WITH NOTES — fresh independent re-review found no P0/P1/P2 issue after the corrected crossed runner, receipt, test, alignment record, and cumulative handoff wording were checked. The Destination B programme remains unqualified for the residuals above.
