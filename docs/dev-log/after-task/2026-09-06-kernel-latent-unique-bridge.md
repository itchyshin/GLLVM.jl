# After-task — D-220 kernel-latent unique regression

**Date:** 2026-09-06  
**Owner:** Cursor/Ada  
**Scope:** Julia-side regression for the bounded dense-kernel source route.

Added a focused regression covering a non-identity dense K, repeated source
groups, and `unique = true`. The test checks the source covariance contract
and the bridge payload's named source covariance.

Evidence:

- `Pkg.instantiate()` completed successfully.
- `julia --project=. test/test_kernel_latent_unique_bridge.jl` passed
  **11/11**, including `KERNEL_LATENT_UNIQUE_JULIA_OK`.
- The verified branch was pushed to origin. No true-parity, Class-1, M2-R2,
  compute-campaign, PR, merge, release, or public-capability claim is made.

Rose audit: this is a development regression only; no public capability
surface was changed.

Rose verdict: PASS WITH NOTES — the focused Julia and paired R checks support
only this fixed, one-source Gaussian transport route; full-package and CI
evidence remains the before-merge gate.

Follow-up reverify: `test/test_bridge_sources.jl` now includes a direct
`bridge_fit` versus `fit_gaussian_sources` identity cell for non-identity K,
repeated groups, and `unique = true`. It passed **24/24**, including equality
of log likelihood, residual SD, convergence, B, and `cov2cor(B)`. The existing
Gaussian source and kernel-smoke files were rerun serially (**46/46** and
**11/11**, respectively). These are engine-transport checks only.

## Rose claim audit (J5 closeout, 2026-09-06)

Internal only. This section is the Slice D Rose claim audit. It does not
authorise NEWS, README, Documenter, register promotion, merge, or a public
capability claim.

**Admitted claim (internal, development):** Julia-side transport for one
Gaussian dense-kernel source with non-identity K, repeated groups, and
`unique = true`. `bridge_fit` matches `fit_gaussian_sources` on log
likelihood, residual SD, convergence, source B, and `cov2cor(B)`. The
sibling R cell uses the public formula
`kernel_latent(unit, K = K, d = 1, unique = TRUE)`.

**Live paired-cell evidence (sibling R lane):**
`TALLY failed=0 skipped=0 error=0 warning=0 passed=20`
(extractor 4 + rejection 7 + paired logLik / B / cov2cor(B) 9). Cited
in `.unlazy/julia-fixed-dense-kernel/GATES.md` J4. Not a true-parity
certificate and not Class-1 promotion.

**Public-surface scan:** this branch vs `origin/main` touches only
`test/test_kernel_latent_unique_bridge.jl`, `test/test_bridge_sources.jl`,
this after-task, and `docs/dev-log/check-log.md`. No NEWS-equivalent
surface, README, or capability-status row was edited.

**Not claiming:** true parity; Class-1 promotion; Totoro/DRAC campaigns;
M2 / Destination B / arc A work; #1236 merge; intervals; non-Gaussian
families; multi-source kernels; or any user-facing capability.

Rose verdict (claim audit): PASS WITH NOTES — file exists, cites
no-public-claim, and cites paired PASS 20. The notes are the same
scope fence as above.
