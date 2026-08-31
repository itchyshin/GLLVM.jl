# AG — Gaussian Stage1a numerical contract

Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86. R/fit-multi.R:5611–5649
keeps one log_sigma_eps free for Gaussian/lognormal, unless per-row diagonal
random effects absorb it. Stage1a requires only z_B, so use unique=false and
one shared residual SD. Do not substitute per-trait residual variance.
src/gllvmTMB.cpp:2717–2719 uses dnorm(y,eta,sigma_eps,log=true).

Parent owns src/families/aghq_gaussian.jl, test/test_aghq_gaussian.jl,
named AG runners/verifier and central includes/reference records. No R edits.

For each site, observed rows O, residual r=Y[O,s]-mean[O,s]-offset[O,s]:
logjoint = -(|O|+K)log(2pi)/2 - |O|log(sigma) -
           ||r-Lambda[O,:]z||²/(2sigma²) - z'z/2.
H=I+Lambda[O,:]'Lambda[O,:]/sigma²;
z_hat=H\(Lambda[O,:]'r/sigma²). No mode iteration or ridge is needed.
Require finite positive sigma, finite H, a real SPD factorization, a checked
joint score and visible curvature diagnostics. Invalid numeric trials fail.
Completely masked sites integrate to one with standard-normal latent moments.

Default mean is per-trait intercepts. Optional complete X[p,n,q] defines X_s*beta
with q free coefficients; q=0 is a zero mean. No implicit added intercept for X.
Pack theta=[beta;log_sigma;pack_lambda(Lambda)]. Copy inputs, validate observed
Y/offset, shapes and finite complete design; never reintroduce masked placeholders.
For every theta, independent exact marginal is N(mean, Lambda Lambda'+sigma² I)
on each site's observed submatrix. Use covariance Cholesky for the test oracle.

Predeclared checks:
AG01 normalization/modes/masks/offsets, k1/2/3/5 exact-value equality <=1e-9.
AG02 same-point frozen AD gradient equals exact marginal gradient for k>=2
within1e-7; frozen Hessian equality needs k>=3 within1e-6. Explicit k1-gradient
and k2-Hessian discrepancies are expected negative controls, not waived failures.
AG03 fixed-cache finite-difference derivatives, malformed inputs, zero-column X,
complete fixed-effects X, input mutation, unrepresentable sigma/invalid theta.
AG04 unchanged original seed42 p5K2n80 centered fixture; all p+1+9=15 parameters
free for paired R intercept model, two starts, k5, no ridge,400 outer passes.
Both-engine frozen-gradient health; absolute fitted delta logLik <=1e-3;
shared sigma and invariant covariance agreement; same-point objective <=1e-6.
Exact Gaussian marginal at the Julia winner <=1e-8; exact gradient check.

The outer optimizer remains the existing frozen-surrogate algorithm; no shortcut
returns the exact optimizer while claiming an AGHQ optimizer. Warm start may use
exact Gaussian fit, then both starts run through aghq_multistart_optimize.
Public Gaussian GllvmFit metadata, controls/fallbacks, postfit and inference remain
required integration work after this adapter. This is not full Stage1a parity.

Execution: Totoro Julia1.12.6, pinned R library/manifest,1 Julia/BLAS thread.
Estimate2–5min per bounded test/pair, cap300s; oracle before/after. Strict docs
estimate3–8min cap590s. No DRAC campaign or >30min run in this slice.
