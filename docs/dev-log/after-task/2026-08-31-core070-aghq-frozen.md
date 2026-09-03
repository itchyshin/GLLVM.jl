# Fixed-adaptation AGHQ prerequisite

## 1. Goal
Implement the fixed-grid surrogate needed by the reviewed Stage1a outer
algorithm. Programme ACTIVE/M1 PARTIAL; no public-estimator completion claim.

## 2. Implemented
Internal AGHQAdaptation, aghq_adaptation and aghq_frozen_logintegral in the
existing grid module. Observed Hessian supplied explicitly; fixed Float64
mode/factor cache, callback scalar type preserved for ForwardDiff. The existing
adaptive evaluator and all public defaults are unchanged; no exports added.

## 3a. Decisions and Rejected Alternatives
Use R's symmetrization and inverse-upper-Cholesky orientation. Floor eigenvalues
at1e-8 only when Cholesky fails and report the repair plus original minimum
eigenvalue. Tiny positive-definite eigenvalues remain unchanged. Reject nonfinite
input. This is adaptation repair, not loading regularization or mode convergence.
Differentiate only the frozen surrogate; do not claim its gradient includes
mode/curvature dependence. The later outer loop must re-adapt and check merit.

## 4. Files Touched
src/families/aghq_grid.jl, new test/test_aghq_frozen.jl, central test include;
predeclared symbolic contract, R/Julia comparison runners and verifier, scoped
review/evidence/checkpoint records. No R source or foreign-worktree edits.

## 5. Checks Run
Totoro Julia1.12.6, one Julia/BLAS thread. Red173pass/5error33.603s: missing
aghq_adaptation. First green211pass36.251s; final output-hash-bound replay
211pass31.641s. All frozen-oracle checks before/after pass. Estimated1-2minutes
per run,180s cap; all within estimate and terminal. No DRAC job or new login.

New38 assertions cover transformed Gaussian normalization/moments, observed
Poisson k1/Laplace equality, fixed-cache AD/FD at two steps, a detectable chain
term on re-adaptation, independent Simpson integration with node refinement,
five curvature branches, invalid inputs and buffer ownership. Existing173
AGHQ grid/adaptation/gate/affordability assertions remain passing.

The frozen R helper is evaluated alone from its source-pinned parsed expression.
All five mode/factor/log-Jacobian outputs agree within the predeclared1e-10
relative bound. Non-diagonal SPD and asymmetric inputs check orientation;
indefinite, singular and tiny SPD matrices check repair policy. No fitted-model,
recovery, full package suite, performance or Documenter build was run.

## 6. Tests of the Tests
Actual red missing-symbol regression retained. Three scratch artifact corruptions
(missing output, altered factors, missing source archive) reject. Final output
hash is present exactly once in the supervisor-hashed log. Unlazy gate freshly
reverified. No tolerance changed to obtain the passing result.

## 7a. Issue Ledger
Paid the fixed-adaptation/AD prerequisite. Public control admission and warnings,
outer adaptation/merit/backtracking/stopping, fit-object reporting and all public
AGHQ model comparisons remain open. This cache does not certify supplied modes.

## 8. Consistency Audit
No automatic loading ridge, VA/MSPL expansion or R0.7.1 changes. Earlier native
family evidence is historical after the whole-source pin changed; 21 family
bindings describe prior verified slices, not current-revision full validation.
Their executable freshness gates must be rerun before promotion. Full manifest
remains DRAFT_NOT_FROZEN and 76 family case specifications remain unbound.

## 9. What Did Not Go Smoothly
Noether found that emitting separate R/Julia factor records was not a comparison.
Added the source-pinned comparator and reran with an output hash bound to the
supervised log. The first green run remains retained. No numerical defect or
acceptance relaxation was required.

## 10. Known Residuals
Internal primitive only. Generic callback integration is tested on Gaussian and
Poisson targets, not every response/dispersion family. Native public AGHQ, outer
mode convergence, covariance/multinomial/data/postfit/bridge contracts, Student-t
reference-health issue, recovery/coverage and final docs remain unpaid.

## 11. Team Learning
Parent implemented; fresh Noether Terra/high public-code review and one follow-up
closed the comparator P2. No new B production child or full programme panel.
Five-dimensional affordability remains the existing separate gate; this cache
does not implement public admission policy. Model effort reported from dispatch,
not inferred from task difficulty; aggregate agent-hours not fabricated.

## 12. Cross-Product Coverage
This does NOT cover public Core+AGHQ parity, R0.7.1, performance or polished
Documenter. Cursor/Claude/unknown Julia lanes and R0.7.1/article work stay
protected. No push, merge, release, destructive cleanup or R engine edits.
Census and earlier family-source verification need refresh before disposition
or final candidate claims. Independent completion panels remain open.

Mission Control local da7f389c4eaf250623a879d70256258a2796b8ad: HTTP200/exact served readback, R fields unchanged, exact-file lease released.
