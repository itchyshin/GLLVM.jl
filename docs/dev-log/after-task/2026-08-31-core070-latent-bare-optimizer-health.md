# Ordinary rank-one latent Gaussian model: optimizer-health repair and PASS

## 1. Goal
Pay the one remaining red gate on frozen `COV-ORD-LATENT-BARE`: the direct
native default-mean fit reported `converged=false` (gradient 1.674e-6 vs
requested `g_tol=1e-7`) while the other three routes converged and agreed.
Demonstrate the cause before changing code; repair minimally; replay the exact
frozen gate on Totoro.

## 2. Implemented
An identical-start 2x2 diagnosis (default-mean vs explicit trait-intercept
design, BackTracking(order=3) vs Hager-Zhang) from one deterministic start
vector; a red-first regression test on the frozen 3x18 response; a one-site
optimizer-selection repair in `fit_gaussian_sources`; Totoro attempt06 with a
fresh pinned plan through the retained targeted-run supervisor.

## 3a. Decisions and Rejected Alternatives
Diagnosis preceded code, per the handover. The two objectives are numerically
identical at the start (|diff| = 0) and along the whole trajectory, so a
mean-path arithmetic fix was rejected. Widening `g_tol`, dropping the
convergence-flag requirement, or editing the contract were never candidates.
The repair uses the already-established Hager-Zhang policy (the explicit-design
default since fdeffac7) rather than introducing any new optimizer.

## 4. Files Touched
`src/source_fit.jl` (optimizer selection + comment), `test/runtests.jl`
(one include), `test/test_source_fit_optimizer_health.jl` (new regression),
`docs/dev-log/core070/latent-bare-model-evidence.json` (PARTIAL -> PASS with
attempt06 receipts), `docs/dev-log/check-log.md`, this report. No frozen
oracle, contract, fixture, tolerance, R 0.7.1, or foreign-lane file changed.

## 5. Checks Run
Diagnosis (macOS, 1 thread): BackTracking stalls at gradient 1.674278e-6 on
BOTH mean designs; Hager-Zhang reaches 4.349108e-8 on both; at the stall point
measured delta-f is positive at every probed step (1e-10..1e-6) while predicted
decrease is ~2e-13 against eps(f)=3.6e-15 — an objective-roundoff stall,
demonstrated. Red run: 3 of 4 regression assertions failed pre-repair. Green
run: 247/247 across the regression plus six neighboring source suites. Totoro
attempt06 (R 4.5.3, Julia 1.12.6, 1 Julia/BLAS thread): process receipt PASS,
oracle before/after PASS, all four routes converged, native gradient
4.34910507607356e-8 <= 1e-7, max |deltaLL| 5.7e-13, loading-crossproduct
5.9e-8, residual variance 8.1e-10, 8/8 negative controls PASS.

## 6. Tests of the Tests
The regression failed red before the repair with the exact attempt05 gradient
fingerprint (1.674e-6). The strict verifier's eight corrupt-evidence
self-test mutations all still reject (`CORE070_LATENT_BARE_NEGATIVES_PASS 8`).
Contract SHA-256 unchanged: a055bd335e0a81b9e59596afe32a2f885c584ea1194132ae4c2c390e7ace1828.

## 7a. Issue Ledger
`COV-ORD-LATENT-BARE` is now `COV_ORD_LATENT_BARE_THREE_ROUTE_PASS`. The wider
Core + AGHQ manifest remains draft and Milestone 1 remains partial. Full source
coverage, multinomial, data/post-fit, Stage 1a AGHQ, recovery, performance,
full suites and Documenter remain unpaid. The full package suite was not run
in this slice (deferred by the approved plan; owed before any merge claim).

## 8. Consistency Audit
Frozen input `INPUT-GAUSS-LOADINGS` SHA-256
aab1742a88c5301f274206981f2f6a4d97062e0c4e31fa1d295c0a1ec5889cdc; every route
p=3, n=18, K=1, `unique=false`, free common residual SD, seven coordinates.
Verification was run by a fresh-context agent that did not author the repair
(own-the-verifier). Attempts 01-06 retained under
`.unlazy/core070-aghq/latent-bare-model-0*`.

## 9. What Did Not Go Smoothly
The dead codex lane's lease (pinned to a long-lived app daemon PID) refused the
Claude claim although the lane's own committed handover had stopped the cycle;
the takeover proceeded on the maintainer's explicit instruction and is recorded
as a justified deviation in the plan-actual reconciliation. The lane worktree
had no root Manifest; the retained attempt05 Manifest (matching the receipt
hash) was restored before any Julia ran.

## 10. Known Residuals
The default-mean and explicit-design paths still build different `X=nothing`
vs `X=D` objective closures; they are numerically identical here but remain
two code paths. Attempt06's environment references attempt05's retained Julia
depots on Totoro (unchanged, read-only reuse).

## 11. Next
Continue the reconciled programme via the arc-loop goal file: remaining
Milestone 1 closure items, then Milestone 2 capability qualification
(covariance sources/modes, formula/modifier grammar, multinomial, data and
fitted-object surfaces, R bridge, Stage 1a AGHQ), then Milestone 3
performance/Documenter — toward true R-Julia parity and beyond. Full suite
before any merge; push/merge/release stay gated on the maintainer.
