# Frozen marginal uncertainty pilots — not qualification

Dense follow-on: replay88175 exits0 and preserves original response, canonical
ridged covariance/precision and fitted coordinates exactly. New hash-linked
sidecar exports production uncertainty without widening the strict reference
schema. Comparator87652 exits1: R marginal gradient1.177556e-4 exceeds the
predeclared1e-4 threshold. The failed receipt is retained; there is no dense
uncertainty PASS. Next investigate/refine the same-data R optimizer under an
explicit policy; do not widen the gradient tolerance or silently replace the
reference. Shared tree/pedigree uncertainty regression55387 remains separate.

The R exports use production `standard_errors()` / `sd_report$cov.fixed`
and public `vcov()`, before later objective evaluations mutate TMB caches.
The covariance covers all seven free parameters. Julia reorders R coordinates
to beta, loading, log-residual-SD, then compares matched marginal curvature
and retained independent-fit covariance. Analytic gradients propagate the
full covariance to rotation-invariant LL' summaries and shared residual
variance. No conditional random-effect curvature, ridge or pseudoinverse.

Signed tolerances are from second-order-parity-contract.md section4:
matched covariance relative1e-4; own-optimum relative.01 with R conditioning
scale; own-optimum link endpoints within.05 Rinterval half-width. This
diagnostic uses Julia finite differences, rather than claiming AD on both
sides as the historical contract's rationale did. No tolerance was widened.

Tree R replay75225 and pedigree95000 exit0, preserving the previously
specified model/seed/BFGS policy. Source/data hashes remain in all receipts.
The R derived intervals here are independently calculated diagnostics, not
claims that an exported R LL' interval method has been admitted. Public
interval workflows, dense-vcv pairing, independent review and recovery remain
separate gates. Original unsuccessful optimizer attempts remain retained.

## Results

Final tree comparison78064 and pedigree61975 exit0. Matched covariance
relative errors are3.8823e-6 and2.1127e-6; own-optimum errors3.8387e-6
and2.1567e-6. Largest link-endpoint errors, relative to R half-width, are
7.8483e-6 and4.4075e-6. R condition numbers122.9505 and161.9355.
Checker95094 passes24/24 assertions, including corrupt covariance/order,
parameter binding, public beta block, fit status, data hash and intervals.
These tests are registered but the full suite has not been run.

R export hashes: tree c8fcb957ba4e90f9fa2c15718409b6169c6355f265b3911564a3ae8a88209a0b;
pedigree ebbe46e9f620f89b60bd6c3e44544d0c7abe5da40f39a2bbca9b4a0629f15e77.
CLI seals all three input hashes and records the checker hash. Initial tree
comparison01 predates that CLI sealing and remains in the ignored ledger;
the durable tree comparison02 uses the final checker. No refit was needed.
