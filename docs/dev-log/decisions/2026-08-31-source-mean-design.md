# Complete fixed-effect means for Gaussian source models

Before implementation: retain the existing covariance parameterization and
default trait-mean model. Extend only the fixed-effect mean and its interfaces.

For Y of shape p traits by n units, y=vec(Y) has traits varying fastest.

    y ~ N(D beta, V)
    V = sigma_eps^2 I + sum_r kron(P_r C_r P_r', B_r)
    nll = (pn log(2pi) + logdet(V) + (y-D beta)' V^-1 (y-D beta))/2.

D is the complete mean design: either pn by q, or a p by n by q array reshaped
without changing Julia column order. X=nothing preserves p trait intercepts,
the same deterministic starting values and the existing objective path. X with
zero columns means a fixed zero mean, not implicit intercepts. beta has q entries;
covariance packing and fixed/free residual semantics are unchanged. Derivatives
differentiate only free coordinates. Initial beta for explicit X uses full-rank
least squares. Rank-deficient/nonfinite/wrong-shaped designs reject. Saturated
means reject with free residual; positive fixed noise admits them. No positive
residual estimate can be claimed when a free-noise model fits the responses
exactly. Empty sources plus zero-column X plus fixed noise is an entirely fixed
model: finite normalized likelihood, zero free parameters, zero gradient,
no optimizer/Hessian identification claim.

| Symbol | API | DGP | Extractor | Declared regression truth |
|---|---|---|---|---|
| D beta | X; formula RHS | trait means + shared x slope | beta and coefficient_names | (.2,-.4,.5,.8) |
| P C P' | SourceCovariance with groups | 24 independent groups,3 repeats | sources | C=I24 |
| B | mode=:indep | independent group effects by trait | trait_covariances[1] | diag(.16,.25,.36) |
| sigma_eps | existing free/fixed SD | independent Normal noise | sigma_eps | .35 |

The single-seed recovery regression uses MersenneTwister(8103201), p3,n72,
unmodified normal x and draws, no centering after sampling. Require absolute
coefficient errors<=.35, covariance diagonal errors<=.30 and SD error<=.15.
These are declared engineering-regression bounds, not calibrated coverage or
a multi-seed scientific claim. Failure is retained, never repaired by reseeding.

GaussianSourcesFit retains copied mean_design (pn by q), response_shape=(p,n),
and coefficient_names. Keep13/14-argument legacy construction for old valid
trait-intercept objects; new complete construction carries metadata explicitly.
coef returns beta. Display must distinguish trait count from coefficient count.

Formula route: gllvm(formula,Y,data; sources, family=Normal(), ...), no global K;
each source owns its rank. Reject K, pervar=true, non-Gaussian families and a
simultaneous X. Intercepts expand to trait intercepts; site predictors have
shared coefficients, with StatsModels contrasts/interactions/rank conventions.
Zero/intercept-only designs must be preserved. This uses the existing complete
mean-design helper, with optional names added without changing pervar defaults.
Long tables retain sorted trait/site order, reject duplicate/incomplete grids and
nonconstant site predictors. Source projection rows must match sorted site order;
wide projections match Y columns. This is explicit-source formula fitting, not
parsing R random-effect terms or constructing trees/pedigrees/meshes in a formula.

No source random slopes, covariance modifier expansion, missing data, non-Gaussian
source models, bridge implementation, intervals or new-data prediction is implied.

## Retained first implementation findings

The first green-labelled attempt was FAIL, not qualification: recovery gradient
2.15127208105792e-6 exceeded1e-7, despite passing coefficient/covariance recovery
checks; R pair matched all numerical checks but harness assumed the wrong free
parameter ordering. A test also called an internal StatsModels helper with
untyped Dict(). The corrected formula test then exposed repeated RHS symbols
in long interactions. All attempts remain stored. R free ordering is four b_fix,
one log_sigma_eps, three theta_rr_phy; native ordering is deliberately different.

Before a numerical repair, the optimizer diagnostic compares the existing
backtracking line search against Hager-Zhang using unchanged OLS/default source
starts, data and threshold. A single exact-Hessian step is diagnostic only.
No ridge, seed selection, tolerance change or false-convergence override is
authorized by these checks. Estimated diagnostic runtime1–3minutes on Totoro.

Diagnostic03 (28.18seconds) held data and starts fixed. Backtracking stopped at
gradient2.15127e-6 after26 iterations; LBFGS/Hager-Zhang reached1.56514e-8 in15,
and BFGS/Hager-Zhang reached2.78607e-8 in16. An exact Newton diagnostic step
of norm2.35e-8 left the rounded likelihood unchanged and gradient1.99e-13;
no Newton correction is shipped. Choose LBFGS/Hager-Zhang only for explicit X,
with the same g_tol and fresh-gradient/convergence requirements. The legacy
X=nothing path retains its existing backtracking algorithm and starts.
