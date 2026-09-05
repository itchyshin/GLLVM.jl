# G0 gates — paired reader journey

Status: **G0 implementation; stop at G1.** This is a documentation-only lane.
It neither changes the Julia or R engines nor promotes a capability or
validation claim.

The shared question, symbolic model, source/link inventory, and G1 evidence
requirements are deliberately identical to the gllvmTMB lane record at
`gllvmTMB/dev/website-renewal/GATES.md`. This copy keeps the Julia worktree
self-contained for source review.

## Shared reader contract

**Entry question:** Which responses vary together, and what is shared versus
response-specific?

The R route is formula-first: a wide data frame uses `traits(...) + latent(...)`
and interprets model-implied covariance, correlation, and communality before
orientation-dependent loadings. The Julia route is matrix-first: responses by
units (`p x n`) and a Gaussian model with a diagonal, per-response residual
matrix `Psi`. A shared residual `sigma_eps^2 I` is a restricted shortcut, not
the same model as R's ordinary `latent()` teaching fit.

## G1 evidence required before publishing

- [x] Reciprocal R/Julia links and current-limit links name the intended routes in source and rendered output.
- [x] `julia --project=docs docs/make.jl --local` and the R article build checks succeed.
- [ ] Rendered pages inspected at 1440 px, 768 px, and 390 px.
- [ ] Keyboard/focus, reduced-motion, and horizontal-overflow checks recorded.
- [x] Source-versus-rendered scan confirms experimental status, orientation,
  partial parity, residual semantics, and Gaussian-only speed wording.
- [ ] Screenshots and an evidence report exist; nothing is published.
