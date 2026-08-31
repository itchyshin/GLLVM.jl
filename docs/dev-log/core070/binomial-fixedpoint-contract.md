# Binomial fixed-point versus merit diagnostic

Reference b4d5fee64def88bc768dda1f1f77c29b295edd86; original seed43 p5K2n60,
k5, unpenalized,14 free parameters. Original failed public/internal receipts are
retained; no fixture/tolerance/estimator or R source changes.

Define A(theta) as checked conditional modes and observed-curvature quadrature
caches, Q(theta,A) as the normalized negative log integral, F(theta)=Q(theta,A(theta)),
and g(theta)=partial_theta Q(theta,A)|A=A(theta). Frozen R's outer algorithm
requires small g and monotone F, but g is not in general grad F at finite k.
The retained native endpoint has positive directional derivative of F along -g.

Diagnostic only: from each retained native/R endpoint, attempt at most8 damped
Newton steps solving g(theta)=0, using central-difference Jacobian h=1e-5*(1+abs(theta_j)),
maximum parameter step1, and at most8 halvings reducing squared norm(g).
Keep every trial, both runs, residuals and F. No assertion that this is a fitter,
a maximum, a convergence repair or an alternative approved estimator.
At initial/final points compare total finite-difference gradient of F at h/h2;
record asymmetry and singular values of the root Jacobian, not a Hessian claim.

The check distinguishes a reachable frozen-gradient fixed point requiring F
increases from an ordinary line-search implementation error. Finding a point
does not prove uniqueness; failure to find one does not prove nonexistence.
If residual root is found, compute final g, F, total FD gradient and likelihood
difference from both original endpoints. Never promote original parity to PASS.

OWNS: Ada named diagnostic runner/verifier, this contract and evidence. No src/
or parity fixture edits. Totoro Julia1.12.6, pinned reference/environment, one
thread. Estimate2–5min; numerical cap300s. Preserve failures and report unmet
premises rather than widening tolerances or scaling into an unsized campaign.
