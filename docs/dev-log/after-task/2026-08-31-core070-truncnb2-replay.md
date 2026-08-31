# Original truncated NB2: repaired Julia fit and public R continuation

## 1. Goal
Replay the original seed58,p5,K1,n120 target after the stable scalar repair;
qualify both complete fits without substituting data, dispersion or curvature.
Programme ACTIVE, M1 PARTIAL, full manifest DRAFT.

## 2. Implemented
Added a same-controls replay and a separate public BFGS continuation diagnostic.
Both use default native fit_truncated_nbinom2_gllvm_pertrait and observed
Laplace curvature. The R continuation uses start_from=original_fit,
optimizer=optim, method=BFGS, reltol1e-12,maxit1500. All15 coordinates remain
free, and original/final R data and parameter maps are identical. No engine
changes this turn. Two verifiers recompute numerical predicates and compare
serialized R whole-fit fields with the result report.

## 3a. Decisions and Rejected Alternatives
Keep per-trait dispersion, log link on untruncated mean and original fixture
hash. Native objective is negative observed-Hessian Laplace marginal logLik;
check central finite differences at h and2h. Retain relative logLik threshold
1e-6, both raw-gradient limits1e-4 and step-stability limit1e-4. Added same-point
native/R nll threshold1e-6 and reported-R-objective reconciliation1e-8.
The BFGS experiment addresses PORT stopping independently of the repaired
Julia density. No tolerance, df/dispersion cap, code overwrite or fake fit.

## 4. Files Touched
Four tools core070_truncnb2_{replay,bfgs}.jl and their Python verifiers,
truncnb2-replay-evidence.json, this report, check-log, programme checkpoint and
response-family reader boundary. Raw attempts under
.unlazy/core070-aghq/truncnb2-replay-01 and truncnb2-bfgs-{01,02}.

## 5. Checks Run
Totoro Julia1.12.6,R4.5.3,TMB1.9.21, one Julia/BLAS thread, frozen Rb4d5fee.
Each run estimated1–3min, cap300s. Oracle before/after passes in all3 batches.

| Attempt | Child seconds | Result |
| --- | ---: | --- |
| Repaired kernel, unchanged tight nlminb | 30.089 | 8pass/1fail: Rcode1 |
| BFGS diagnostic01 | 26.831 | Own report parse error, retained |
| BFGS diagnostic02 | 27.994 | 11pass; complete batch29.586s |

Native gradient max improved from5.396422948888539e-4 to6.536981751954038e-6;
step disagreement from4.2048769823455024e-4 to1.4080714992003955e-7.
Final public Rcode0, raw-gradient max2.746089928674922e-5. Native converged.
Absolute optimized logLik difference8.67307790031191e-8; same-point nll
difference1.659207100601634e-7. Both15 free parameters, all finite.
Original default Rcode1 retained. Repaired Julia source hashc8048849 unchanged.

## 6. Tests of the Tests
Replay verifier rejects7 corrupted fields; BFGS verifier rejects8, including
wrong data/fixture/DGP hashes, gradients, step discrepancy and likelihood/
same-point deltas. Archived source/process/log hashes verified. Serialized
R parameters, gradients, optimizer code and data/map equality independently
read back using base R without refitting. Pre-run gates failed on missing
receipts; fresh reverify now has2met/1unmet for BFGS and1met/2unmet for replay.
Full-scope gate deliberately remains unpaid. Julia parser checks both scripts.

## 7a. Issue Ledger
The original fixture now has a qualified explicit public R continuation
recipe. The default parity test/helper remains unmodified and still fails R
health. Integrating that explicit control policy into required-case records
and rerunning the required runner is unpaid, as is broader family coverage.
Do not silently relabel this as default-model convergence.

## 8. Consistency Audit
Reader notes distinguish recorded recipe from defaults and broader capability.
Original fixture and numerical engine unchanged. Source pins current for this
fit. Full manifest remains unfrozen; Rose review NOT RUN. No release claims.

## 9. What Did Not Go Smoothly
The first BFGS diagnostic used invalid single-quoted R macro syntax in a
message field. Julia had already run the fit before encountering that later
parse error; its serialized object and failed process remain preserved.
Corrected only the quoting, ran local Julia parse checks, then a fresh remote
attempt. Numerical controls and gates unchanged. A parser preflight should
precede every new remote script, not only its repair.

## 10. Known Residuals
No full package suite, recovery/coverage campaign, default-R parity pass,
formula/bridge qualification or rendered-docs proof. Required runner policy
integration remains unpaid. Student original still fails health and density
checks; ordinary NB2 tolerance diagnosis and full source-case mapping remain.

## 11. Team Learning
Separating the native density repair from the reference stopping policy
identified two distinct failures. Whole-fit public continuation resolves this
recorded R case without changing R source or mixing fields from separate fits.
Parent performed this bounded execution; independent domain review unpaid.

## 12. Cross-Product Coverage
This does NOT cover the full Core+AGHQ contract, multiple seeds, interval
coverage, inference, general speed claims, public AGHQ or multinomial latent
models. R0.7.1/article/foreign lanes untouched. No push, merge, release or cleanup.
