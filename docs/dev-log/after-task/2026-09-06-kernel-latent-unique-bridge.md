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
