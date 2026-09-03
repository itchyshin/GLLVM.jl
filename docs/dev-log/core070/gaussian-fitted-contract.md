# Gaussian fitted/postfit qualification — explicit control boundary

The unchanged required `NATIVE-01-GAUSSIAN` fixture (seed42, p5, K2, n80, centered by trait) passes31 assertions against frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86. This is ordinary latent **unique=FALSE**, not R default or common-unique variance behavior. See [evidence](gaussian-fitted-evidence.json).

The added postfit comparison uses a native explicit per-trait intercept design `X[t,site,t]=1`, matching R's free `0+trait` coefficients. Both have15 free parameters. The legacy fixture's zero-mean native fit remains untouched; it is not used to infer equality of parameter counts after manual centering.

## Control result

The original R call reports convergence0 and passes legacy likelihood/covariance tolerances, but raw maximum gradient0.00157349 exceeds the separately predeclared1e-4 postfit gate. Preserve that failure. Using only frozen public controls:

```r
gllvmTMBcontrol(
  n_init = 1L, se = FALSE, start_from = original_fit,
  optArgs = list(control = list(rel.tol = 1e-12, eval.max = 2000, iter.max = 1500))
)
```

on the identical formula/data gives convergence0 and raw gradient8.50576e-5, passing the unchanged limit. Parameter names and family IDs are checked unchanged. No source, likelihood, seed, variance structure or acceptance tolerance was altered.

Final11 postfit assertions pass: likelihood difference1.154e-11; conditional link/response prediction maximum difference4.320e-7; Gaussian randomized-quantile residual difference8.176e-7; intercept difference1.931e-11;15 parameters each;400 R likelihood rows. These residuals are continuous Gaussian standardized residuals, so no cross-language RNG equivalence is assumed. The data are centered: this does not test general nonzero intercept behavior.

## Evidence and limits

Totoro Julia1.12.6/R4.5.3/TMB1.9.21, qualified RCall environment and one Julia/BLAS thread. Final command39.26s including compilation, original fixture and refined comparison, below the under3minute estimate/hard300s. This composite command is not a performance benchmark. Installed R integrity passes before/after. The supervisor binds the real process exit independently of the legacy31-assertion family receipt, so a postfit failure cannot be hidden by a successful earlier family receipt.

Attempts1–2 stopped before fitting because the bundle lacked required provenance/execution files. Attempt3 retained the default-gradient failure; attempt4 unintentionally still ran default controls because launcher arguments were wrong (its explicit tight-control flag is false). Attempt5 is the first correctly activated refinement. All are retained; unexpected arguments are now rejected.

The retained verifier preserves both the default-gradient failure and the tightened-control success. The whole programme aggregator still rejects DRAFT_CONTRACT. Neither the31-check legacy receipt nor this11-check facet proves full postfit/capability completion.

R default/common-unique fitting still needs native controls for fixed residual plus unique variance. Current `fit_gaussian_gllvm(has_diag=true)` frees more variance coordinates and cannot simply be substituted. The existing per-variance fitter may match total interior covariance, but that does not establish the required lower-bound constraint or unique/residual decomposition. Newdata, nonzero means/general designs, inference, formula/bridge and other family/source cells remain unpaid.

## Independent review

Noether (configured Terra/high, fresh read-only context, 141 seconds, exit 0) accepts attempt 5 for this single-fixture qualification. The runner intentionally accepts either no flag (default-control diagnostic) or `--tight-r`; it is not intrinsically a tight-control-only executable. The evidence verifier requires both the final exact `--tight-r` argv and `tight_public_r_control=true`. Thus a future default invocation cannot satisfy this tightened-control acceptance gate. No new milestone verdict is implied.
