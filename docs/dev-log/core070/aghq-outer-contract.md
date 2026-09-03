# Unpenalized AGHQ outer adaptation driver

Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86, fit-multi.R:6540-6960.
Implements the outer algorithm reviewed in aghq-source-contract.md; this leaf
adds no public fit keyword and does not discharge family-specific adapters.

Let A(theta) be site caches with observed curvature and separately computed
conditional modes. Minimize F(theta)=Q(theta,A(theta)), where Q is the negative
sum of normalized frozen-grid log integrals. Differentiate Q only with A fixed.
No loading penalty. The derivative is labelled frozen, never total.

| State / symbol | Rule | Evidence |
|---|---|---|
| theta_best,F_best | only accepted re-adapted evaluations, allowance1e-10 | AO-02 |
| A(theta) | callback returns nonempty site caches of consistent shape | AO-01,AO-06 |
| cap | 1,2,5,25,default optimizer budget when continuation and cap1 | AO-03 |
| acceptance | F_cur<=F_best+1e-10, consecutive accepted count | AO-02,AO-03 |
| rho | halve rejected direction down to1/64 before reducing cap | AO-02 |
| stage ceiling | permanently lower after exhausted backtracking | AO-03 |
| shift | max absolute difference in conditional modes | AO-01,AO-04 |
| g | max abs AD gradient of frozen Q at current adaptation | AO-01,AO-04 |
| stopping | >=2 consecutive accepts, shift<1e-4, gradient or objective leg | AO-04 |
| g_ok | abs g<1e-4 OR g/max(1,abs F)<1e-6 | AO-04 |
| objective leg | abs dF<1e-9 stops, but cannot certify convergence alone | AO-04 |
| finalization | re-adapt returned best, recompute F AND its frozen gradient | AO-05 |

Defaults:400 adaptation evaluations; cap1; continuation=true; patience3;
rho_min1/64; tolerances above. Julia uses Optim.LBFGS for capped surrogate steps,
with ForwardDiff gradients and default uncapped-budget1000 iterations. This is
a documented Julia optimizer choice, not a claim of identical nlminb iterates.
For deterministic transition tests the internal step callback is injectable.
No step proposed after the last permitted adaptation evaluation can be returned
without evaluation. Failed adaptation/evaluation retains the accepted point;
failed finalization returns usable=false. Interruptions must propagate.

The final gradient is recomputed at returned parameters, avoiding stale trial
metadata; convergence still requires the actual accepted-pass stopping rule.
A cache callback must solve and check conditional modes; the driver cannot infer
that from cache existence. Public admission/control defaults, initializations,
family adapters, multistart selection and fitted-object reporting remain next.

Predeclared cases (no family-wide parity claim):
AO-01: actual normalized Gaussian latent marginal via quadrature, analytic mean
       estimate and final objective <=1e-8; default optimizer moves parameters.
AO-02: surrogate descent can worsen re-adapted merit; all rejected/backtracked
       attempts retained, no false convergence, final accepted state preserved.
AO-03: continuation escalates by accepted count and permanently lowers ceiling.
AO-04: stationary start needs two evaluations; high-gradient zero movement or
       stagnation is not convergence; objective-relative gradient honored.
AO-05: adaptation/optimizer/finalization failure and evaluation cap do not return
       an unexamined trial or stale adaptation/gradient; exceptions recorded.
AO-06: malformed controls, initial parameters and cache shapes reject clearly.

Parent owns src/families/aghq_outer.jl, module/test includes, new scoped tests,
verification scripts and records. Original family engines and R untouched.
Totoro one Julia/BLAS thread; estimate1-2minutes per targeted run,180s cap.
Large recovery and public-fit comparisons remain separately predeclared work.
