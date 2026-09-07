# Destination B joint grouped Laplace contract

## Scope

This private kernel is the fixed-parameter, non-Gaussian grouped component of
Destination B.  It supports Poisson/log, Binomial/logit, Beta/logit, and
NB2/log.  Gaussian remains on its separate exact-marginal path.  This note
does not qualify a public fitting capability, intervals, recovery, or an R
bridge.

## Model and parameterisation

For a response matrix whose rows are traits and whose columns are sampling
units, stack responses as `vec(Y)`.  Given a fixed-effect design `X`,
coefficient vector `beta`, and a sparse grouped design `W`,

\[
  \eta = X\beta + Wb, \qquad b \sim N(0, I_m).
\]

When `A` is the unit-by-group incidence matrix and `L` is the trait-by-factor
matrix, the grouped design is `W = kron(A, L)`.  The column ordering is group
then trait factor, and the row ordering is unit then trait, so it agrees with
`vec(Y)`.  Multiple nonzero entries in a row of `A` are retained: crossed
effects are represented by one shared, global `b`, never by separately solved
unit modes.

The conditional log posterior, including the normal-prior constant, is

\[
 q(b) = \sum_i \log p(y_i \mid \eta_i(b))
        -\tfrac12 b^\top b - \tfrac m2\log(2\pi).
\]

At the joint mode `bhat`, the Laplace log marginal is evaluated as

\[
 \log \widetilde p(y) =
 \sum_i \log p(y_i \mid \eta_i(bhat)) - \tfrac12 bhat^\top bhat
 - \tfrac12\log\det\{I_m + W^\top D_{obs}W\}.
\]

The `-m/2 log(2pi)` normal-prior constant cancels the `+m/2 log(2pi)` Laplace
integration constant exactly.  Family `_glm_logpdf` methods provide every
remaining response-density constant.  The prior precision is exactly `I_m`,
so its log determinant is exactly zero rather than omitted by convention.

Newton steps solve the joint score equation using Fisher weights only:
`I_m + W' * Diagonal(D_fisher) * W`.  The reported determinant uses
`D_obs = -d2 log p(y|eta) / deta2`, obtained from `_glm_obs_weight`; it is not
silently replaced by Fisher curvature.  A non-positive-definite observed
precision, invalid family data/trials, a non-finite evaluation, or exhausted
Newton iterations returns a diagnostic result and is never recorded as a
successful objective value.

The legacy family core protects other routes by clamping `eta` to `[-30, 30]`
and clamping family means.  That creates a non-differentiable conditional
objective if a grouped Newton score is computed through the raw link.  This
kernel therefore admits only the strict interior where neither clamp changes a
value.  An initial state in the clamped domain, or a line search with no
admissible interior step, returns `:saturated_domain`; it does not report a
mode, Hessian, or determinant.  Saturated trial steps may be safely rejected
when a smaller interior step is available.  This is conservative by design
until a separately derived piecewise objective and derivatives are supplied.

## Initial checks

Focused tests must establish: (1) `W = kron(A,L)` ordering; (2) no-random-effect
exact reduction including log-density constants; (3) a one-dimensional Poisson
quadrature anchor; (4) a crossed design has one global precision with nonzero
cross-block; (5) NB2 uses observed, not Fisher, determinant curvature; and
(6) invalid inputs and nonconvergence are diagnostics.
Finite-difference checks compare the conditional score and observed Hessian in
the differentiable interior for every admitted family.  The corresponding
extreme-predictor checks require `:saturated_domain`, because no legitimate
smooth finite-difference derivative exists at a clamp boundary.
# Integration repair and independent review

The fixed NB2 interval stencil at log-r perturbation2.2663365337639677e-5
stalled under Fisher scoring despite a regular neighbouring mode. The original
stronger suite was33/38; observed Newton alone regressed it to29/38. The accepted
repair uses observed Newton when positive definite, Fisher fallback otherwise,
and admits a likelihood decrease only within32eps(Float64)*(1+abs(logpost))
while requiring strict reduction of the actual joint score. Convergence and
interval tolerances are unchanged; seeds and response fixtures are unchanged.
The resulting integrated kernel47/47 and outer38/38 passed. This is numerical
convergence repair, not changed model identity or coverage certification.

Sol read-only review confirmed global Wb, observed curvature determinant,
full-coordinate marginal Hessian and invalid-stencil rejection. Its defects in
direct Beta/NB2 marker validation and sticky saturation status are repaired;
independent zero-random-effect density normalization checks for the other three
families and a terminal gradient diagnostic have been added. Scalar quadrature
anchors for all four families and a fully identified crossed multi-source fit
remain owed. Review receipt: ignored grouped-review-result.md and events.
