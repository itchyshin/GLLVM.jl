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
- No true-parity, Class-1, M2-R2, compute-campaign, push, merge, or release
  claim is made.

Rose audit: this is a development regression only; no public capability
surface was changed.
