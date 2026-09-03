# Frozen confidence-interval routing contract

This expands the finite inference contract with 98 executable, stable-ID cases in
`test/parity/fixtures/core070_inference_routes.tsv`. The reference remains R commit
b4d5fee64def88bc768dda1f1f77c29b295edd86. Final result: 98/98 routing expectations pass.
These are **source-function control-flow probes, not installed-package or numerical
interval evidence**. The whole programme manifest remains DRAFT.

## Exact execution boundary

The runner parses frozen `R/mspl.R`, `R/fit-multi.R`, and
`R/z-confint-gllvmTMB.R` and evaluates function definitions only in a disposable
R environment. No package initialization, objective, fit, profile or bootstrap runs.
The real dispatcher, token recognition, selected parsers and inference guards run.
For `stage=dispatch`, named `.confint_*` endpoints throw a typed boundary condition
containing the requested method. For `stage=guard`, those helper bodies run until
the declared rejection. A synthetic `profile_targets` inventory provides only
`beta` / `sigma_eps` labels; it does not establish actual fitted inventory support.
The null-coalescing helper is a harness implementation. All substitutions are local;
reference files and installed packages are not edited.

A deliberately invalid method arriving at an intercepted endpoint means only that
the top-level dispatcher forwards it. It is **not an admitted inference method**.
Numerical helper eligibility, supported fitted sources, convergence and calibration
remain separate obligations. The TSV's compatibility-adapter classifications apply
to dispatch behavior, not to the availability of every requested cross-product.

## Requirements now explicit

| Target | Omitted method | Required behavior exposed here |
|---|---|---|
| Lambda | Wald | Intercept before generic method matching; preserve wald_asym routing. Helper accepts Wald, asymmetric Wald, profile and bootstrap; later numerical behavior unpaid. |
| ICC | Wald | Explicit profile rejects with `gllvmTMB_repeatability_profile_withdrawn`. Invalid method rejects. |
| Phylogenetic signal | Profile | Target-specific dispatch; invalid method rejects. Profile/Wald/bootstrap computations unpaid. |
| Communality | Wald | Explicit nonlinear profile rejects; invalid method rejects. |
| Correlation | Fisher-z | Explicit nonlinear profile rejects. All tested unit_slope interval methods reject. Invalid method rejects. |
| Proportion | Wald | Explicit nonlinear profile rejects; invalid method rejects. |
| Sigma | Profile | Seven exact canonical/legacy tokens reach Sigma handler; generic invalid method rejected. No claim that every tier exists in every fit. |
| Fixed effects | Profile | Wald needs standard errors. Bootstrap falls back to Wald with a visible message. |
| Direct profile target | Profile | Wald follows the target helper after the SE gate. Bootstrap falls through to fixed-effect Wald with a visible message; this is not target bootstrap support. |

For direct-target bootstrap, reaching the fixed-effect tidier does not prove that
its eventual parameter selection will return the requested variance/dispersion
quantity. Keep this as a compatibility/limitation obligation; do not certify an
interval from that branch interception.

Missing SEs and all-nonfinite covariance diagonals reject Wald for both fixed and
direct targets. Profile reaches its endpoint without SEs. This does not certify
partially nonfinite covariance matrices or any computed interval. Weighted-objective
inference rejects before dispatch. MSPL rejects before dispatch and remains an
explicit programme exclusion, not a new implementation obligation.

Source anchors: `z-confint-gllvmTMB.R:261` (Lambda helper), `:768` (SE guard),
`:855` (ICC), `:894` (phylogenetic signal), `:941` (communality), `:1034`
(correlation), `:1188` (proportion), `:1608` (public dispatcher), `:1802` (Sigma).
Frozen source hashes are checked against the retained oracle inventory.

## Failures retained and checks of the checks

Attempt 1: 84 pass / 14 fail. R `as.list(environment)` omitted hidden dot-prefixed
helpers, so per-case restoration retained intercepted functions. Fixed with
`all.names=TRUE`; no reference change. Attempt 2: 97 pass / 1 fail. The expected
rho diagnostic said "not implemented"; frozen source actually says "not supported".
Corrected the literal expectation after reading that branch. Attempt 3: 98 pass.
Old runner/fixture bytes, process exits, plans and logs remain checksummed.
Eight negative controls reject false numerical/installed claims, omitted cases,
stale source pins, changed reference, corrupt receipts and a deliberately false
live expected route. The last runs the probe and requires exit 1, not a hash failure.

## Remaining implementation and validation

B4 must map these targets to Julia quantities and explicit status, and freeze
same-model fitted cases with estimands, normalization, identification, interval
method, health rules and tolerances. Extend source cases for loading pins/scales,
Sigma components, correlation cluster/cluster2 fences, malformed tokens, and
post-dispatch helper admission before freezing the full inference manifest.
Native, formula and bridge reachability stay separate. No calibrated-coverage,
full inference, M1 or release claim follows from these 98 route checks.
