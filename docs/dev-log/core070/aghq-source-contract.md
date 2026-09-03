# Stage 1a: frozen-source contract and implementation obligations

Reference: gllvmTMB `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
Historical source annex; see [current required cases](aghq-required-cases.md) for implementation and verification status. The original39 helper checks remain unchanged; partial Gaussian/Poisson/binomial public candidates now exist. Full public-fit parity remains unpaid.
This annex does not freeze or complete the programme manifest.

## Estimator boundary

The public R control defaults to `aghq=FALSE`, but requesting AGHQ also uses
`aghq_ridge=2` unless overridden (`R/gllvmTMB.R:1861–1864`). That finite penalty
is outside the approved unpenalised programme. Every AGHQ reference fit here
must name `gllvmTMBcontrol(aghq=k, aghq_ridge=Inf)`; its Laplace comparator must
also have no penalty. Neither a default ridged R fit nor an automatic-ridge fit
is an unpenalised parity oracle. No R source change is needed.

Use a canonical reference formula such as
`value ~ 0 + trait + latent(0 + trait | site, d=1, unique=FALSE)` with explicit
`unit='site'`, `trait='trait'`, and frozen family/data. Ordinary `latent()` with
its default unique component adds a second random block and is ineligible.
The equivalent native Julia call and supported fitted-object surface remain
B6 implementation work; the existing quadrature grid is not that interface.

## Reachable admission and reporting

`R/fit-multi.R:6333–6402` evaluates the following chain, in this order:

1. `k=1`: compute Laplace; no ignored-request warning.
2. Random vector must be exactly `z_B`; additional blocks reject AGHQ.
3. A B-tier ordinary loadings block must exist.
4. Predictor-informed latent scores are ineligible.
5. Missing-predictor models are ineligible.
6. Any multinomial rows are ineligible.
7. A present graph gate with no quadrature route retains Laplace.
8. Automatic selection applies its additional affordability/trait policy.

Ineligible requests retain Laplace and emit the explicit ignored-request
warning (except `k=1`); they do not silently report AGHQ. The broad internal
random-block gate is not evidence that the public Stage 1a path admits all
blocks it can analyse. Tests of this chain require actual public fits and are
still unpaid; pure helper tests cannot satisfy them.

The graph gate uses a min-fill treewidth upper bound with threshold4
(`R/aghq-gate.R:194,252–260`). Automatic selection declines malformed, empty,
unresolved or unaffordable gate results, and declines at **20 traits**, not
20 sites (`R/aghq-control.R`, `.aghq_auto_decide`). An explicit numeric request
bypasses the trait cutoff, but not the preceding structural gate.

At tier B, the callable resolver starts Gaussian/ordinary discrete families at
k5 and Tweedie/ordinal/delta families at k9. Public `TRUE` is normalized to
`"auto"`; NULL to FALSE. Positive integer k2 is admitted too; do not invent an
odd-node-only restriction. Fractional, zero, negative, nonfinite, vector and
numeric-string controls reject in the public normalizer. The internal node
resolver alone is weaker validation and must not replace that normalizer.

Although helper prose describes a ladder, the public caller resolves a single
`aghq_k_req` and reuses that k in its adaptation loop. No automatic node-refinement
claim follows from the ladder constant. B6 must test refinement separately.

## Adaptive objective and derivatives

For site i with standard-normal latent vector z and parameters theta, define
`h_i(z;theta) = p(y_i | z,theta) phi(z)`. If m_i and L_i are the conditional
mode and inverse-curvature Cholesky factor, the finite-node approximation is

```
I_i,k(theta) = det(L_i(theta)) sum_r exp(logw_r)
              h_i(m_i(theta) + L_i(theta) z_r; theta)
F_k(theta) = -sum_i log I_i,k(theta).
```

R's grid already includes the probabilists' scaling and adaptive correction
in logw. Do not divide by sqrt(pi) a second time. Verify normalization and
Gaussian moments, including nonidentity transformations.

The reference optimizes a frozen-adaptation surrogate in short passes, then
recomputes the conditional modes/curvatures to evaluate its merit objective.
It uses capped steps (1,2,5,25,uncapped under continuation), rejection/backtracking
on the re-adapted objective, and optional multistart. Defaults include400 passes,
mode-shift tolerance1e-4, absolute gradient1e-4, relative gradient1e-6,
objective tolerance1e-9, escalation patience3 and minimum step1/64.
These are source observations, not proof of numerical adequacy.

For finite k, writing adaptation as A(theta), the total derivative is
`dF(theta,A(theta))/dtheta = partial_theta F + partial_A F * dA/dtheta`.
The frozen-node AD gradient is only the first term. A stable adaptation point
alone does not prove the omitted term is zero. Do not adopt the reference
comment's fixed-point equivalence as a mathematical proof. Before B6 dispatch,
Noether must review the chosen differentiated quantity and its mode/curvature
dependence. Require finite differences of the **re-adapted** objective, low-
dimensional independent quadrature, node refinement, and k1/Laplace equivalence.
No relaxation of tolerances or implicit estimator change is authorized here.

Reference convergence requires two accepted passes, settled modes and a
gradient/objective stopping condition; stagnation without a satisfactory
gradient is explicitly not certified convergence (`R/fit-multi.R:6810ff`).
Record requested and actual integration, k and k^d, penalty state, stopping
reason, convergence, mode shift, gradients, multistart and parameter movement.
`used=TRUE` means the branch ran; it does not prove movement or an improved fit.

## Executable subset and remaining gates

`aghq-control-subset.json` freezes39 pure reference-control checks with source
SHA256 pins, stable IDs, expressions, expected outcomes and B6 ownership.
`tools/core070_aghq_policy.py` replays only named function definitions from the
frozen archive; it does not install or fit R. All39 pass on local R4.6.0 and Totoro R4.5.3; omitted-case,
stale-source and forced-false negative controls reject. Receipts are under
`.unlazy/core070-aghq/aghq-control-subset/attempt2/`.

This establishes the R helper behavior only. Still required: Julia control
implementation, actual admission/rejection fits and warnings, estimator tests,
post-fit behavior, same-model numerical comparisons, and separately designed
recovery/coverage evidence. Those rows must enter the full capability manifest
before its final freeze; this annex is not a substitute for them.


## Noether follow-up: observed curvature and repair branch

Noether (configured Terra/high, fresh read-only review) confirmed the ridge and
chain-rule distinctions. The frozen R adapter uses the **observed** conditional
Hessian (`R/fit-multi.R:9554`), while Julia's generic family default is Fisher.
B6 must explicitly select observed adaptation and compare modes, factors and
values at fixed parameters; a generic-default call is not sufficient.

R also floors eigenvalues at1e-8 when its conditional Hessian is not positive
definite (`R/fit-multi.R:9569`). This adaptation repair is distinct from a loading
penalty. Julia's internal quadrature instead returns negative infinity on that
failure (`src/families/aghq_grid.jl:238`). The repair-triggering route is therefore
an accounted-for required compatibility gap, not an excluded model. PD-only
fixtures may establish a scoped subcase but cannot erase this branch or certify
general parity. Before B6 dispatch, name its owner and separate test ID, review
whether/how the exact R repair is reproduced, and record the trigger and actual
curvature treatment in diagnostics. Do not silently floor every Hessian or
claim absence of a loading ridge means absence of curvature repair.

The implementable outer contract is fixed k, observed adaptation, short frozen-
surrogate steps, re-adapted merit acceptance, capped continuation/backtracking,
and explicit frozen-gradient reporting. Verify AD versus finite differences
with adaptation held fixed. Also inspect directional differences of the
re-adapted objective to expose the chain term; only an implementation including
that term may claim a total derivative. Keep R's two accepted passes, settled
modes and satisfactory surrogate-gradient criterion distinct from a total-
objective stationarity claim. Stagnation alone stops but does not certify.
This review qualifies the design; it is not implementation or numerical evidence.
