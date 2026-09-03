# Internal unpenalized AGHQ outer adaptation

## 1. Goal
Implement the reviewed outer loop needed for public Stage1a AGHQ. Full programme
ACTIVE/M1 PARTIAL; public controls/model adapters and final parity remain open.

## 2. Implemented
Internal aghq_outer_optimize with observed-cache callback, fixed-surrogate AD,
short LBFGS steps, re-adapted merit acceptance, backtracking, permanent cap
reduction, explicit convergence/stagnation/failure reasons, trace and returned
parameter movement. Final adaptation, objective and frozen gradient are freshly
recomputed at the returned accepted point; unchecked trials are never returned.

## 3a. Decisions and Rejected Alternatives
R's unpenalized branch is the reference. No loading ridge. Default schedule
1,2,5,25,ordinary optimizer budget; disable continuation or choose a nondefault
cap to hold it fixed. Two accepted passes, settled modes and satisfactory
absolute/relative frozen gradient are needed to certify convergence. Objective
stagnation may stop the run but cannot independently certify convergence.
Julia LBFGS is explicit; identical nlminb trajectories are not claimed.

## 4. Files Touched
New src/families/aghq_outer.jl, module/test includes, test/test_aghq_outer.jl,
scoped runner/verifier, symbolic contract, review/evidence and developer records.
No response-family engine, R source, protected worktree or public export edits.

## 5. Checks Run
Totoro Julia1.12.6, one Julia/BLAS thread, existing authenticated connection.
Initial red211pass11fail6error38.068s: missing outer-driver symbol. First
implementation251pass43.782s. Non-default rho regression252pass1fail46.137s;
repair plus cache/gradient tests258pass46.634s. Final schedule-complete replay
records262 assertions (51 outer,211 prerequisite) in aghq-outer-evidence.json.
All reference checks before/after pass. Estimates1-2minutes per run,180s cap.

Actual normalized Gaussian latent marginal fit agrees with its analytic mean
estimate and objective within1e-8. Deterministic cases check stale-surrogate
rejection, halving to/beyond rho_min, permanent cap ceiling, all cap stages,
relative gradient, warm-start and moved-point stagnation, invalid controls,
cache/shape errors, finalization, interruption and no unchecked final trial.
No public R AGHQ fit comparison, recovery, full suite or Documenter build run.

## 6. Tests of the Tests
Missing-symbol and non-dyadic rho=.3 red regressions retained. Three scratch
corruptions reject missing source, missing process and changed plan. Source and
process/log hashes checked on final current revision. Unlazy gate freshly
reverified; no tolerance widened to make a result pass.

## 7a. Issue Ledger
Paid the internal single-start unpenalized outer driver. Still required:
family-specific observed mode/cache adapters and mode-health checks, public
control validation/eligibility/warnings/defaults, initializations, multistart
ranking, fit-object/reporting integration, public fit comparisons and recovery.
The callbacks are internal numerical plumbing, not a public estimation surface.

## 8. Consistency Audit
Frozen-gradient metadata never claims the omitted adaptation chain derivative.
No constant-objective convergence at a bad gradient. A finite objective can be
usable with an unavailable gradient only when explicitly nonconverged. Earlier
family bindings remain historical pending whole-source revalidation; they are
not current complete-candidate evidence. Full manifest DRAFT_NOT_FROZEN.

## 9. What Did Not Go Smoothly
A non-default rho_min exposed clipping instead of R's literal halving rule.
The failing regression justified a one-line repair. Noether identified missing
malformed-cache tests; those were added. Its derivative concern was covered by
the already included AF-03 test, not by inventing a total-gradient claim.

## 10. Known Residuals
No public AGHQ estimator yet, no multistart or family-wide quadrature verdict.
Callback mode validity remains the adapter's duty. Student reference health,
17 link dispositions,76 unbound family cases, covariance/data/postfit/bridge,
structured multinomial, recovery/performance/final docs remain unpaid.

## 11. Team Learning
Parent implementation; fresh Noether Terra/high source review plus one repair
follow-up, no remaining P0-P2 findings in reviewed scope. Final cap-schedule tests
were added by parent after that source review. No new B production child or
programme completion panel; no actual aggregate agent-hours inferred.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, R0.7.1, calibrated coverage or polished
Documenter. All Cursor/Claude/unknown Julia lanes and R0.7.1/article lanes remain
protected. No push, merge, release, destructive cleanup, R engine edit or DRAC
submission. Census and full source-bound evidence must refresh before final
candidate claims. All targeted jobs terminal once the final receipt is verified.

Mission Control local 76c958c3d546de6ac36c51d70e45c42ab0476c94: HTTP200, exact served field verified, R fields unchanged, exact-file lease released.
