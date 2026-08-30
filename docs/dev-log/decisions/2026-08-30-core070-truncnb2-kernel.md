# Truncated NB2 mean-parameter kernel repair contract

Candidate work following the retained Poisson-limit diagnosis. Remote fitting/parity and independent review remain unpaid; local checks are pure kernels only.

For t=r*log1p(mu/r), p0=exp(-t), q=-expm1(-t), and a=1/(1+mu/r), use

    log NB(y) = -t + y*(log(mu)-log(r)-log1p(mu/r))
                - log(r+y) - logbeta(r,y+1).
    log truncNB(y) = log NB(y) - log(q), y>=1.

This is the same negative-binomial normalization as Distributions.logpdf, with
log probabilities computed from the mean rather than a rounded probability.
It has constant count complexity; the O(y) high-precision recurrence remains an
independent test oracle. Retain support handling before evaluating logbeta.

Conditional mean and variance can be expressed as

    m = mu/q,
    v = m*(1+mu/r - mu*p0/q).

This removes the subtract-two-squared-means form at large means. Small-mean
conditioning still needs quantitative checks; no arbitrary variance floor.
The log-link score is a*(y-m), and observed negative curvature follows from
`da/deta=-a*(1-a)` and `dm/deta=a*v`:

    Wobs = a^2*v + a*(1-a)*(y-m).

Compute a*(1-a) as a^2*(mu/r) where numerically admissible, avoiding a rounded
`1-a` near r=infinity. This uses the same moment calculation for score, Fisher
and observed curvature. It is algebraically equivalent to the existing observed
formula, not a switch to Fisher. Negative observed weights remain possible and
must not be clipped into artificial positive curvature.

Initial tests:90 density points against256-bit recurrence;20 mean/variance
pairs including mu=1e-12 and r=1e12;27 score/curvature pairs against nested AD;
zero-count support. Acceptance is numerical accuracy at these points, not a
claim about every finite parameter or package integration. Extend to dispersion
derivatives, large counts and normalization before considering closure.

Reference code inspected locally: Distributions0.25.125 negativebinomial.jl
`logpdf`, SpecialFunctions `logbeta`/`loggammadiv`. This change derives algebra
above; no external implementation is copied. Same likelihood parameterization,
no ridge/floor, no new public API.

## Dispersion derivative correction and final local gate
The direct beta form passed205 density/moment/mean-derivative checks but failed18 additional log-dispersion derivative checks. Large-r digamma subtraction was inaccurate despite accurate scalar densities. Production now uses the five-term alternating expansion of sum log1p(k/r) when x=(y-1)/r<=0.01 and y*x^6/6<=eps*max(1,y*x/2). Each omitted log1p remainder is bounded by x^6/6; summing yields the displayed conservative bound. Power sums are closed form, keeping work constant in y. The rest of the domain retains the log-beta normalization. No parameter cap or change to the target likelihood.

All352 final local scalar assertions pass:205 initial,81 dispersion/normalization/large-count,66 second/mixed derivatives and branch-transition checks. Counts reach1,000,000; large-count absolute2e-8/relative2e-12 criteria were declared before that check and do not replace any parity tolerance. Full package loading initially failed on missing StatsModels in the old local lock; qualification therefore loads exact scalar source and link definitions, not a fake fitter. Whole-package and fitted R replay remain unpaid.
