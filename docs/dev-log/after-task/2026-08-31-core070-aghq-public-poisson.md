# After-task — public Poisson AGHQ and fitted-object identity

## 1. Goal
Implement the reviewed public Poisson AGHQ leaf while preserving the frozen
R0.7.0 objective. Full programme ACTIVE; M1 PARTIAL; manifest DRAFT_NOT_FROZEN.

## 2. Implemented
Public fit_poisson_gllvm accepts opt-in AGHQ and stores requested/actual
integration, node count, stopping reason, controls, copied warm-start controls,
all start outcomes, observed caches and input identity. Legacy constructors and
default Laplace retain their path. Generic and intercept-only formula fits
reach this public estimator. Ineligible direct requests report Laplace fallback.

Wald/profile inference uses the fitted frozen-node objective. Bootstrap replays
fitted controls, retains every attempt and returns NaN rows for failed refits.
Prediction preserves finite masked-cell offsets without reintroducing masked
responses into the likelihood. Simulation uses the unpenalized log-Poisson law.
Generic Wald now requires positive-definite information, not merely positive
entries on an inverse diagonal. Non-PD results have all NaN standard errors.

## 3. What Changed the Next Action
The original fixture now reaches a real public Julia AGHQ result and inference,
so the next work is remaining Stage1a admissions/families and manifest coverage,
not another internal-only Poisson helper. This does not satisfy the full programme.

## 3a. Decisions and Rejected Alternatives
Retain frozen adaptation for inference, matching the reference's fitted
objective. Do not silently substitute total derivatives through adaptation or
Laplace inference. Reject unsupported hessian selectors for eligible AGHQ;
copy and replay base controls rather than inventing bootstrap defaults.
Keep two failed bootstrap attempts; do not rerun until ten successes appear.

## 4. Files Touched
Poisson fit/metadata/adapter and module wiring; shared confidence intervals,
Poisson postfit/simulation branches; public/paired runners and verifier; tests;
SHA stdlib dependency; README/CHANGELOG/quickstart/API/low-level reference;
scoped contracts, review, evidence and developer records. No foreign-lane edits.

## 5. Checks Run
Final Totoro Julia1.12.6, one Julia/BLAS thread, source-pinned run:
432 assertions PASS in117.659561s:53 public,330 numerical prerequisites,
8 frozen-R pair,12 functional inference,29 existing adjacent regressions.
Frozen R oracle verifies before and after. Original seed44 p5K2n60, all14free,
k5 unpenalized: absolute LL delta7.4375066e-9; same-R-point intercept SE delta
1.3967055e-8; AD-vs-FD Hessian difference4.0461407e-5. Both engines satisfy the
reference frozen-gradient rule (R needs its relative leg).

Profile beta1 interval [0.9918549,1.3412493] brackets estimate. Bootstrap8/10
converged; failures retained at attempts5 and8, too few for finite percentile
bounds. This is a functional smoke, not recovery or coverage evidence.

Strict Documenter/VitePress build PASS70.261499s; executed quickstart output
(actual=:aghq,nodes=3,converged=true,pd_hessian=true) confirmed in checksummed
HTML. No deployment. Logo/favicon/default-asset/large-chunk warnings remain.
No full Pkg.test/core suite or visual-polish claim. Fit runs estimated2–5min,
300s cap; docs3–8min,590s cap. All launched jobs terminal, no DRAC compute.

## 6. Tests of the Tests
Original public red: missing integration field and invalid Wald PD verdict.
Four artifact corruptions reject: missing inference, missing RDS, corrupted
pair result, missing process. Source/fixture/DGP/environment/log/manifest pins
are rechecked. Unlazy PU-VERIFY approved and freshly reverified, exit0/all met.
The gate covers this leaf only, not the full programme's capability manifest.

## 7a. Issue Ledger
Paid public ordinary Poisson AGHQ identity, functional fitted-object/inference
paths and generic/formula forwarding. Full Stage1a other-family controls,
exhaustive admission/fallback coverage, repaired-curvature reachability, recovery,
full package checks and M1 completion panel remain outstanding.

## 8. Consistency Audit
Finite-node total re-adapted gradient differs from frozen gradient by0.0193509;
convergence is not total stationarity. Default legacy PoissonFit constructors
carry integration=nothing. Public quadrature is Poisson only. No full-R-parity,
universal speed, calibrated coverage, final documentation polish or release claim.
Read docs/dev-log/core070/aghq-public-poisson-evidence.json for exact receipts.

## 9. What Did Not Go Smoothly
The first green attempt failed loading SHA from the old manifest. Offline
resolution changed only GLLVM's SHA dependency listing; the old manifest is
retained. The setup process intentionally failed immutable-source verification
because resolution changed that manifest; subsequent tests pin the resolved file.
The next test caught masked-offset prediction loss. Two isolated runner attempts
failed imports before numerical work. Strict docs first failed seven missing
internal docstrings; all were added to canonical low-level documentation.
Initial HTML inspection searched a source-only block name; corrected inspection
checks the actual rendered output and matching remote/local SHA256. No failed
run or original fixture was removed; no tolerance was widened.

## 10. Known Residuals
Other families/structured AGHQ, Student-t R health/density,17 link dispositions,
covariance, structured multinomial, data/postfit/bridge, manifest freeze, recovery,
performance, full package checks and final visual docs remain unpaid. Earlier
family evidence is historical after source changes. No milestone panel verdict.

## 11. Team Learning
Parent implements and runs; fresh Noether Terra/high source review plus one
repair follow-up found omitted bootstrap base controls and ignored curvature
selector, then confirmed both repairs. No new B production child or completion
panel. Requested model/effort recorded; no fabricated provider/model receipt or
aggregate agent-hours. Fresh environment setup must precede immutable execution.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, R0.7.1, article work, calibrated
inference, complete worktree disposition or public release. Protected lanes
unchanged. No push, merge, cleanup or R engine edits. Mission Control local
2115d5d51d5660fcfd480623e41387b50ad08917, HTTP200/exact field and unchanged R
fields verified; exact-file lease released. Goal remains active.
