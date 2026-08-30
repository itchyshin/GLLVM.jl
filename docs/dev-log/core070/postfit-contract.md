# Frozen postfit contract: source and policy qualification

The namespace previously had 100 postfit-information obligations without resolved definitions. [The inventory](postfit-surface-inventory.json) now binds all 100 to exact source locations and signatures: 99 functions and the explicit `generics::tidy` reexport. The verifier reparses the pinned R source; invented signatures or omitted entries fail. These definitions are not 100 completed capabilities.

[The policy subset](postfit-policy-subset.json) binds 29 predeclared probes to the installed frozen R commit b4d5fee64def88bc768dda1f1f77c29b295edd86. These use minimal field-bearing objects and function formals, not genuine fits. All 29 pass. They specify information and admission rules; same-model numerical comparisons on valid fitted objects remain unpaid.

## Requirements exposed by the probes

| Surface | Frozen behavior | Julia obligation |
|---|---|---|
| predict / fitted | predict defaults to link; fitted to response | Explicit scale mapping; current native predict defaults to response. Do not change an idiomatic default just to imitate R, but document and test the adapter. |
| prediction conditioning | re_form=~0 or NA removes random effects; ~. includes them | Test fixed versus conditional predictors on training and new data; preserve offsets and factor order. |
| prediction SE | Training-only, no multinomial, missing-predictor model or REML; requires sdreport | Same conditional fixed-effect delta-method estimand with populated covariance. A passed guard with an empty placeholder is not a numerical SE test. |
| residuals | exact randomized quantile or simulation rank; normal/uniform scales; conditional RE default TRUE | Record CDF intervals, randomization, ties, trait filters, scale and metadata. Compare injected common uniforms/CDF limits where possible; equal R/Julia seeds do not produce equal draws. |
| simulation | Unconditional RE redraw default FALSE for condition_on_RE | Qualify admitted source/family redraw routes and warned fallbacks separately. Do not equate conditional simulation with parametric bootstrap. |
| coef / vcov | Named fixed effects; empty coefficient vector legal; fixed/free mapping matters | Preserve parameter identity and fixed masks, not just a vector of the same length. vcov numerical, mask and missing-sdreport routes remain unpaid. |
| likelihood / deviance | nobs counts observed likelihood rows; df counts estimated coordinates; deviance=-2logLik | Preserve estimator/integration information and distinguish fit health. R's at_maximum attribute is not independent proof of optimizer convergence. |
| tidy / summaries | fixed, random parameters and cutpoint effects | Equivalent information with explicit links/status/uncertainty; R table and console formatting need not be cloned. |

The nobs priority probe intentionally supplies inconsistent placeholder counts to reveal field precedence. It does not endorse inconsistent real fitted objects. The lognormal response probe covers common sigma only; it cannot certify per-trait dispersion behavior. Mixed-row link dispatch is tested directly as a policy helper, not as evidence that a Julia mixed-family fit is equivalent.

## Inference and graphics still need branch contracts

Top-level confint methods are profile, Wald and bootstrap. This is not the whole dispatcher: Lambda has a separate default and accepts wald_asym; ICC, phylogenetic signal, communality, correlation, proportion, Sigma and profile-target tokens have separate admission and fallback behavior. Some nonlinear profile methods are explicitly withheld. Each required target/method/source combination needs an exact source-backed case before inference parity can be claimed. MSPL and automatic loading-ridge policy remain excluded by the approved scope.

Plot information remains required: correlations, ellipses, loadings, integration, communality, variance and ordination, including rotations and uncertainty where admitted. Rendering may be Julia idiomatic. Definitions of these functions are now pinned; numerical quantities, reader-visible limitations and rendered examples have not been qualified by this slice.

## Remaining contract work

1. Map every required definition to a model/estimand and native, formula and bridge status, preserving aliases/reexports rather than counting them as independent methods.
2. Expand data/conditioning/parameter-target branches and reject unsupported cross-products explicitly. Do not assume every combination of 100 names and 17 families is admitted.
3. Freeze valid same-model fitted-object fixtures and predeclare numerical tolerances, randomization and health rules before results. Execute those cases on qualified compute.
4. Keep the whole programme manifest DRAFT until the required finite cases, not merely signatures, are complete.

Verify this source/policy slice with `python3 tools/core070_verify_postfit.py`. No Julia source or R engine was modified. No fits, simulations, intervals or graphics were executed.

## Response parameter is not always a response mean

A 29th probe verifies the frozen zero-truncated-Poisson response helper returns the underlying rate lambda=exp(eta). At lambda=0.5 it returns0.5, whereas the distribution in frozen C++ fid10 has E[Y|Y>0]=lambda/(1-exp(-lambda))=1.270747. The C++ likelihood explicitly subtracts log(1-exp(-lambda)), so truncation is in the model; it does not reparameterize lambda as the positive-count mean. Julia's TruncatedPoisson marker already documents the untruncated-rate link.

B4 must distinguish literal reference output from the scientific expected response: test and label the rate for R correspondence, and identify any conditional-mean output separately. Do not copy a broad “all response predictions are means” claim. No R engine or Julia postfit API was changed here, and this helper probe is not a fitted prediction test. Similar semantic checks remain necessary for other truncated/two-part/ordinal responses.

## Executed interval dispatch subset

The [inference routing contract](inference-routing-contract.md) adds98 source-function
cases for target-specific defaults, method forwarding, selected typed rejections,
SE prerequisites and visible bootstrap-to-Wald fallback. All98 pass, with failed
probe attempts retained. These are disposable source-environment probes, not an
installed package, fitted interval or exhaustive inference contract. In particular,
forwarding an invalid method to an intercepted endpoint does not admit that method.
