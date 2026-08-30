# Source covariance: reference established, native route unpaid

Frozen R reference: `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
Evidence: [source-fixed-point-evidence.json](source-fixed-point-evidence.json).
This is a fixed-parameter reference check and a model distinction, not fitted or production Julia parity.

For the captured loadings-only animal, single-kernel and two-kernel Gaussian cases, observation o has trait t[o] and source group g[o]. The verified covariance is

```
V[o,v] = sigma_eps^2 * (o == v)
       + sum_r lambda_r[t[o]] * lambda_r[t[v]] * C_r[g[o],g[v]].
```

Here C is the inverse of the precision actually passed to TMB, in captured group order. Under complete unit-major ordering this is `sigma_eps^2 I + sum_r (Z C_r Z') ⊗ (lambda_r lambda_r')`. Means are the captured trait fixed effects, not estimated centering. No latent-score optimization is substituted for marginal likelihood. TMB solves conditional Gaussian modes; no outer optimizer ran.

Six points (three models, two parameter vectors; three traits, eighteen units, six groups, rank one per source) pass 44 assertions. Maximum absolute negative-log-likelihood difference is 8.527e-14; maximum scaled outer-gradient error is 1.013e-14. Independent R dense and Julia dense computations agree. Shifting a fixed mean rejects equality at every point. The repeated groups make projected source covariance rank six on eighteen units, while independent residual noise makes the full covariance positive definite.

Animal and single-kernel input bytes are identical in this fixture because both use identity source covariance. They exercise two admissions but do not provide two independent covariance challenges. The second named kernel supplies the nonidentity challenge. Nonidentity animal covariance, other ranks, other modes and optimized fits remain unpaid.

## Existing matrix-normal route is a different model

`src/coevolution_kronecker.jl` applies `Kstar ⊗ (Lambda Lambda' + sigma_eps^2 I)`. Thus residual noise is correlated by Kstar. `src/coevolution_blockna.jl` restricts that covariance to observed cells; selection does not change its residual model. Preserve these methods for their own model.

A separate control chooses one observation per group (six groups, a valid positive-definite matrix-normal domain), uses the second nonidentity kernel and its loading vector, and compares the existing kernel with additive independent noise. Its negative-log-likelihood differences are 0.8717882 and 3.1760369. This is a one-source counterexample, not the full two-source R likelihood. It disproves interchangeability of the two covariance constructions; it does not declare the existing method mathematically incorrect.

## B1 implementation boundary

The reusable representation must retain source identities, observation-to-group incidence, trait loading matrices, residual distribution/scale, means and observed-cell order separately. Add independent source contributions; never multiply residual covariance by a source kernel by default. For rank greater than one, the candidate extension is `Lambda_r Lambda_r'`, subject to the frozen identification and admission contract. Slopes, unique/common components and non-Gaussian likelihoods require their own source evidence before this representation is widened.

Begin with a small dense reference implementation and a regression against these exact coordinates, then derive a sparse/low-rank computational path with the same normalization. Do not silently repurpose matrix-normal APIs. Formula B2 and bridge B5 must map the same representation only after native admission and model contracts are reviewed. Production native density, fitting, diagnostics, postfit, recovery and interface parity all remain unpaid.

## Provenance and failed attempt

Totoro `source-fixed-point-02`: R 4.5.3, TMB 1.9.21, Julia 1.12.6, one Julia/BLAS thread. Frozen installed R package integrity passed before and after. R points took 1.02 seconds; Julia points 17.71 seconds including compilation, below the under-three-minute estimate and 300-second hard cap. Thirty-three output artifacts were read back and hash-checked against Totoro; the evidence JSON also binds process logs, input hashes and source pins.

Attempt 1 is retained under `.unlazy/core070-aghq/source-fixed-point/attempt1/`: the two-kernel precision was indexed on the wrong axis, producing a nonsquare matrix. Frozen C++ indexes `Ainv_kernel(r,i,j)`. The corrected extraction `[r,,]` asserts dimensions source × group × group `(2,6,6)`. Neither model nor tolerance changed. This failure is a harness correction, not a source-engine bug.

Verify retained evidence with `python3 tools/core070_verify_source_points.py`. A PASS from this verifier never promotes the master DRAFT contract or a required native capability row.

## Independent review

Noether (fresh Terra/high read-only CLI, 180 seconds, exit0) accepted this bounded representation and counterexample. See [review](source-covariance-review.md). For future long-form data use source-specific group incidence g_r(o); a literal Kronecker expression assumes complete matching order. The first native evaluator should remain Gaussian, complete p×n, fixed ordered SPD source matrices, one loading vector per source, one or two sources and scalar residual scale. Broader programme cells remain required but must be separate increments. Noether did not run tests or issue a milestone-completion verdict.
