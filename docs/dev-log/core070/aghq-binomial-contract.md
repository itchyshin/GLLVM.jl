# AB — binomial Stage 1a numerical contract

Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86; reference
src/gllvmTMB.cpp obs_loglik fid1 and src/gllvmTMB_cloglog.h (archive hash verified).
Parent owns new src/families/aghq_binomial.jl, test/test_aghq_binomial.jl,
named AB runners/verifier and central module/test includes. Existing ownership
lease covers these files. No new B production child. No R source edits.

For observed cell (t,s), eta=beta[t]+offset[t,s]+Lambda[t,:]'z[s],
y is successes, N is trials, 0<=y<=N. Joint log density is
sum(log choose(N,y)+y log(p)+(N-y)log(1-p))-z'z/2-Klog(2pi)/2.
Logit and probit p are clamped to [1e-12,1-1e-12], matching the frozen template.
Cloglog uses log(p)=log(1-exp(-exp(eta))) with the reference series at eta<=-20
and right evaluation cap700; log(1-p)=-exp(min(eta,700)). This intentionally
preserves the pinned source's branches, not a new probability-floor policy.
Zero-trial rows contribute exactly zero. Missing/masked cells omit counts,
trials, offsets and constants. N defaults to ones, must match Y shape, and
observed inputs must be finite integral counts <=2^53, with y<=N.

theta=[beta;pack_lambda(Lambda)], standard-normal prior, no ridge. Use checked
conditional modes and observed Hessians. Existing Fisher-scoring mode is a
proposal; actual frozen-reference joint gradient must meet1e-7. A refinement
may optimize that exact joint, never falsely certify a nonstationary proposal.
Finite observed curvature uses reviewed aghq_adaptation (visible repair flag).
Outer integration reuses existing fixed-k frozen-surrogate loop, unchanged.

AB01 scalar normalized probabilities, all3 links, tails and zero trials.
AB02 mask/trial/offset validation and invariance; no input aliasing.
AB03 modes, independent K1 integration and k1 Laplace equality in admitted
interior cases; fixed-cache AD-vs-FD1e-6; negative mode/parameter tests.
AB04 original seed43 p5K2n60 Bernoulli fixture bytes unchanged; real internal
Julia and public frozen-R k5 unpenalized fit attempted with all14 parameters
and two starts. Keep all attempts; strict LL1e-3 and reference gradient-rule
checks required before any paired-fit pass. Nonconvergence stays visible.

Predeclare public work still required after numerical adapter: BinomialFit
estimator metadata including N, public controls/fallbacks, generic/formula
reachability, objective-consistent inference, prediction/simulation with trials,
docs and exhaustive Stage1a admissions. This adapter is not that public surface.
Each Totoro run one Julia/BLAS thread, estimate2–5min, main300s cap. DRAC reserved
for separately sized recovery/coverage; no calibrated inference claim here.
