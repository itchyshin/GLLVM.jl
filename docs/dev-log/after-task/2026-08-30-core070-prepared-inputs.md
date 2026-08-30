# Core070 prepared covariance/multinomial inputs

## 1. Goal
Inspect actual frozen R model-input construction, beyond parser markers, without
changing R source or treating prepared inputs as a successful fitted model.

## 2. Implemented
Disposable-process pre-MakeADFun capture;14 deterministic cases; exact input,
parameter/map/random records; source/package/process hashes; model candidate
rows with explicit Julia/interface/inference debt; retained-evidence verifier.

## 3a. Decisions and Rejected Alternatives
The public API lacks prepare-only. A typed stop in a runtime tracer captures the
arguments and prevents the original MakeADFun body from running. Do not replace
R input preparation with a hand-coded proxy or treat the typed stop as a fit.
No R files, fixture family models, or numerical tolerances were changed.

## 4. Files Touched
`tools/core070_fit_input.R`, retained-input verifier/test, the prepared-input
fixture, subset/evidence/contract records, master contract pointer, check-log and
checkpoint. These tools do not edit Julia numerical sources or the R library.

## 5. Checks Run
Totoro R4.5.3/TMB1.9.21; qualification1.12s,14-case batch1.72s. Eleven inputs
prepared,three expected rejections; source-installed tree/marker/build-log checks
exit0 before and after. Captured objects and rejection records:58 remote files
matched local byte hashes. Two multi-kernel captured input objects are identical
with automatic unique TRUE versus default FALSE. Unlazy G1 freshly reverified.
No TMB objective construction, numerical optimizer, full suite or campaign.

## 6. Tests of the Tests
Wrong-DLL tracer request rejects instead of returning prepared status. The same
14-case fixture with its first expected predicate deliberately false exits1;
remaining cases still retained. Evidence tests reject omitted cases, stale
capture source, corrupt artifact and required-process exit1 even after refreshing
the receipt hash. Aggregate negative-control batch status is FAIL by design;
the positive input command is separately verified exit0.

## 7a. Issue Ledger
Prepared-input expectations:14/14. Original attempt13/14 retained. Eleven actual
numerical model candidates:UNPAID; Julia calls and exact acceptance rules still
unresolved. Broader matrix/slope/mask/data/postfit contract and full manifest:
OPEN/DRAFT. Student reference health remains failed and untouched.

## 8. Consistency Audit
Observed variance maps are recorded separately from symbolic covariance intent.
Ordinary per-row Gaussian default fixes the separate residual; loadings-only
keeps it free. Binomial/nominal auto-Psi suppression and multinomial source fences
are explicit. Later AGHQ adaptation, objective constants and postfit are outside
capture. No completed parity or final Rose panel claimed.

## 9. What Did Not Go Smoothly
An initial supervisor invocation used positional arguments instead of named
flags; it failed before R launched. First batch's only failed assertion matched
lowercase 'not admitted' against a capitalized multi-kernel diagnostic. Corrected
the diagnostic substring and required the specific multinomial condition class;
no admission rule or positive model changed. Failed batch and artifacts retained.

## 10. Known Residuals
Capture proves only the prefix before tape construction. Prefix design/start
calculations still run. It does not prove later numerical validity, normalization,
identifiability, convergence, recovery, or postfit. Independent implementation
review and broader model cases remain due.

## 11. Team Learning
A passing marker parser does not reveal parameter maps. Capturing the real tape
inputs exposed default-model differences that could otherwise create false
parity. Keep negative outcomes and require an explicit capture boundary.

## 12. Cross-Product Coverage
Covers the declared ordinary Gaussian/Poisson/binomial, Gaussian animal and
single/multiple named-kernel inputs, selected multinomial latent/source inputs
and three rejections. It does NOT cover all families/links, all source/mode/
slope/unique/common combinations, matrix pathologies, missing data, offsets,
loading masks, known covariance, postfit, Julia native/formula/bridge fitting,
AGHQ, calibrated recovery, performance, or executed/rendered Documenter pages.
It does NOT cover the protected R0.7.1/article programmes; neither was edited.
