# After-task — B1 nested Gaussian unit_obs paired fit

## 1. Goal
Retain one frozen-R 0.7.0 / Julia same-data Gaussian `unit_obs` pair with a valid nested, replicated design and explicit evidence limits.

## 2. Implemented
Added a frozen-R receipt runner, symbolic alignment record, machine-readable receipt, and registered Julia regression for diagonal W-tier `unit_obs`. No Julia likelihood source or gllvmTMB engine source changed.

## 3. What Changed the Next Action
The candidate now has one paired nested diagonal `unit_obs` result. Next B1 leaf is a separate paired Gaussian `cluster` fixture; crossed or latent W, intervals, recovery, S3b/S4, and all-parity claims remain outside this slice.

## 3a. Decisions and Rejected Alternatives
Used `indep(0 + trait | obs)` / `GroupingTerm(:unit_obs; mode=:indep)`, not a latent factor. Required two repeats per group--trait cell so W is not an observation-level residual. Kept Julia's currently nested-only contract; did not claim frozen R's broader crossed design or expose structured R formula syntax.

## 4. Files Touched
`tools/destination_b/b1_unit_obs_gaussian_reference.R`, the B1 receipt and symbolic alignment record, `test/test_destination_b_b1_unit_obs_paired_fit.jl`, `test/runtests.jl`, check log, and this report. No public docs or exports changed.

## 5. Checks Run
Frozen R 4.6.0 fit: convergence 0; logLik `-50.296108604526843`. `OPENBLAS_NUM_THREADS=1 GLLVM_TEST_SHARD=155/296 Pkg.test()` passed 23/23 in 6.1 s. `jq` receipt-integrity check returned true; `git diff --check` passed. No full suite, JET, Aqua, benchmark, recovery, coverage, or deployment ran.

## 6. Tests of the Tests
The initial test was deliberately red because the retained receipt did not yet exist. The final test binds source/version/archive/shared-library/data/runner hashes, formula, convergence, response ordering and shape; it matches fixed R coordinates and a separate Julia refit. A within-parent changed-membership control changes incidence and likelihood. Independent review found two P1 provenance/wording omissions; both were repaired and the shard rerun.

## 7a. Issue Ledger
No issue action: this is an unpushed local candidate and no GitHub action was authorised. FRK remains parked at gllvmTMB#1275. B1 cluster/cluster2, S3b/S4, intervals, recovery, and full package verification remain open programme work.

## 8. Consistency Audit
Ran `rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs CLAUDE.md` and `rg -n "gllvmTMB|R reference|read.?only reference|0\.7 parity|engine = .julia." README.md docs/src docs/dev-log/decisions/2026-09-10-destination-b-b1-unit-obs-symbolic-alignment.md`. Existing Gaussian-only guide qualifiers and historical records remain accurate; README continues to say experimental partial R-to-Julia bridge, not 0.7 parity.

## 9. What Did Not Go Smoothly
The initial `jq` display projected fitted fields from the wrong level, appearing as null although the receipt was intact; a direct R object-shape probe proved the runner correct. The first negative control reassigned a replicate to the same group; it was corrected to the other group within the same parent.

## 10. Known Residuals
One p=2, n=48, nested diagonal Gaussian fixture only. No crossed or latent W, interval feasibility, recovery/coverage, cluster/cluster2, non-Gaussian, phylogeny, dense-vcv, public formula bridge, `engine="julia"`, 0.7.1, broad 0.7, or Destination B completion evidence.

## 11. Team Learning
Hopper-style source semantics plus an independent Noether review caught both the incidence-control mistake and missing provenance locks before promotion.

## 12. Cross-Product Coverage
One family (Gaussian) × one W covariance (diagonal) × one nested design × one fixed interior fixture. This slice does NOT cover REML, penalties, missingness, aggregation, R `engine="julia"`, crossed designs, other grouping levels, covariance structures, families, sizes, or interval/recovery regimes.

## Rose Verdict
Rose verdict: PASS WITH NOTES — this retained evidence slice is coherent, but the Destination B programme remains unqualified for the residuals listed above.
