# B1 fixed-coordinate curvature audit — pre-run protocol

## Status and authority

This is a **pre-run protocol only**. It does not authorize an R/TMB objective,
gradient, Hessian, fit, optimizer, Julia fit, retry, or source change. A **fresh
authorization is required** before the one evaluation below. The estimate is
**10 seconds**, with a 60-second hard stop. The estimate is deliberately
conservative relative to the retained 0.7705-second fit receipt; it is not
permission to run.

The retained n=180 record is a *stationary-candidate negative receipt*, not a
stationary point: `convergence = 1`, `singular convergence (7)`, and
`max(abs(g)) = 9.9329370235209566e-5 > 1e-6`. A later curvature result at
these coordinates would therefore be a fixed-coordinate diagnostic only. It
cannot repair convergence, support standard errors, establish an optimum, or
qualify B1.

## Immutable inputs

Machine-readable pins live in
`b1-fixed-coordinate-curvature-audit.toml` and are checked by
`tools/verify_b1_fixed_coordinate_curvature_protocol.jl` before any future
evaluation.

| Item | Pinned value |
| --- | --- |
| Receipt | `docs/dev-log/core070/destination-b-b1/frozen-r070-joint-gaussian-stationary-paired-receipt-20260910.json` (`b14de9d4b3aa62fd7c9b9957e853b5607499998b1ba23fd5ad812d668131820a`) |
| Frozen source / archive | `b4d5fee64def88bc768dda1f1f77c29b295edd86` / `0c2f4323eb9fb19acccf039b8d57b4dd6bda82e2aa8b4a7bb712f36a64b022bc` |
| Frozen shared library | `3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30` |
| Reference runner / fixture module | `tools/destination_b/b1_joint_gaussian_stationary_reference.R` (`9d1f1fa95655bd8887d7e04d2c2d10c0311fac094205a4d47dd7ee6ebb9ca585`) / `tools/destination_b/b1_joint_gaussian_common.R` (`61009033b613bd1eb8f97b42c073e180ad71418d758d9da97aa8f8cd5a793924`) |
| Formula | `value ~ 0 + trait + latent(0 + trait | unit, d = 1, unique = FALSE) + indep(0 + trait | obs) + indep(0 + trait | cluster_id) + indep(0 + trait | cluster2_id)` |
| Data | MD5 `8d61143f2ce6102bb8460fb1575cc249`; 2 traits, 12 units, 3 unit-observations/unit, 5 replicates, 8 clusters, 7 cluster2 groups, 180 wide rows / 360 long rows |

The four fitted grouping blocks are fixed as: unit latent (`theta_rr_B`,
coordinates 4–5), unit-observation independent (`theta_diag_W`, 6–7), cluster
independent (`theta_diag_species`, 8–9), and cluster2 independent
(`theta_diag_cluster2`, 10–11). The fixed effects occupy 1–2 and residual
`log_sigma_eps` occupies 3. The TOML also pins all 11 numeric coordinates in
that exact order. Any change to source, receipt bytes, data digest/dimensions,
formula, runner/module hashes, raw names, values, or block packing is a hard
rejection—no substitute data or reordered coordinate vector is allowed.

## One permitted future action, after fresh authorization

After the static verifier and existing no-fit frozen-provenance preflight both
pass, an authorized evaluator may construct the frozen TMB objective at the
pinned vector and perform exactly once each:

1. objective `f(theta*)`;
2. gradient `g(theta*)`; and
3. observed Hessian `H(theta*)`.

It must make **zero optimizer calls**, not call a fit wrapper that optimizes,
and must stop after those three calls. It may not reseed, rebuild, refit,
restart, remap, change data/source/tolerances, or run a Julia comparison. A
failure, timeout, non-finite value, preflight failure, or schema mismatch is a
final HOLD, not a reason for a second evaluation.

## Pre-registered outputs and interpretation

Return the 11 ascending eigenpairs `(lambda_j, q_j)` of the symmetric observed
Hessian. Canonicalise each `q_j` by making the first largest-absolute coordinate
positive (ties use the lower coordinate index). Label an eigenpair by its
largest-absolute coordinate only when that loading is at least 0.70; otherwise
label it `mixed`. For every eigenvector report squared-mass projections onto
`fixed`, `residual`, and all four group blocks; a block is dominant only at
projection at least 0.80.

The evaluator must report the Hessian relative asymmetry
`max(abs(H-H'))/max(1,max(abs(H)))`, eigenpair residuals
`max(abs(H*q_j-lambda_j*q_j))/max(1,abs(lambda_j))`, and orthonormality error.
Require asymmetry and orthonormality no larger than `1e-10` and residuals no
larger than `1e-8`. Interpret `lambda < -1e-8` as clear negative curvature,
`abs(lambda) <= 1e-8` as numerically flat/indeterminate, and `lambda > 1e-8`
as clear positive curvature. Only `max(abs(g)) <= 1e-6` permits the word
“locally stationary”; otherwise every curvature statement must say
“conditional on the non-stationary fixed coordinate”.

The static verifier is intentionally engine-free: it reads TOML/JSON and hashes
only. Its negative controls demonstrate rejection of source-hash, coordinate
order, and dimension drift without constructing or evaluating a model.
