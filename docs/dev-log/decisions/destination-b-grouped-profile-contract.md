# Destination B: grouped Gaussian variance-profile contract

**Status:** implementation design only. This specifies one future internal
profile interval slice; it is not a fitted capability, recovery result,
coverage result, or public-interface admission.

## Narrow estimand and symbolic contract

The first eligible estimand is one named, trait-specific variance from a
Gaussian grouped fit in which **every** selected term is
`GroupingTerm(...; mode=:indep, common=false)`. For trait `t` and selected
source `s`, with `Y` having `p` traits and `n` observations, write

```
vec(Y) = D beta + sum_s (Z_s kron I_p) u_s + epsilon,
Cov(u_s) = I_gs kron Diagonal(v_s),
epsilon ~ N(0, sigma_eps^2 I_np),
v_s,t = exp(2 eta_s,t) >= 0.
```

The profile is on the natural variance `v_s,t`, not the log standard
deviation `eta_s,t`. At every fixed `v`, all remaining fixed effects, all
other grouped-source coordinates, and `sigma_eps` are re-optimised in the
same observed-marginal Gaussian objective. A constrained refit is therefore
not a conditional random-effect calculation.

| Symbol | Current grouped representation | Synthetic draw for future test | Extractor / profile coordinate | Truth / scope |
| --- | --- | --- | --- | --- |
| `beta` | trait-major mean design `D` | fixed trait intercepts | refitted nuisance | no interval target in this slice |
| `Z_s` | selected source incidence | fixed nondegenerate unit labels | retained unchanged in every refit | design provenance |
| `v_s,t` | `:indep` packed `eta_s,t`, `exp(2 eta_s,t)` | one positive independent Gaussian source variance | **one selected natural variance** | profile target |
| other source variances | remaining `:indep` coordinates | positive nuisance draws | refitted nuisance | not fixed by profile |
| `sigma_eps^2` | final `log_sigma_eps` coordinate | positive residual variance | refitted nuisance | not fixed by profile |

No latent-plus-unique, dependent covariance, common-variance, or multiple
component profile belongs in this first slice. All nuisance grouped terms are
also `:indep, common=false`; correlated/latent nuisance terms would turn the
identification check into a parameter-dependent Jacobian problem. The existing
necessary redundancy warning in `src/grouped_fit.jl:102-122` does not detect
incidence aliasing, so it is not an identification gate for this profile.

## Existing implementation anchors

- `src/grouped_fit.jl:125-165` maps an `:indep` source coordinate to
  `v = exp(2 log_sd)` and builds its diagonal covariance.
- `src/grouped_fit.jl:290-315` rebuilds the full observed-marginal objective.
  Its `all(isfinite, value)` guard at line 301 correctly protects ordinary
  fitting, but rejects `-Inf`, so directly inserting `log_sd = -Inf` cannot
  evaluate `v = 0`.
- `src/grouped_fit.jl:388-427` already identifies natural variance targets
  for observed-marginal Wald diagnostics. A profile selector must use the
  same term/trait labeling and packed-coordinate order.
- `src/marginal_target_intervals.jl:5-12` is the governing distinction:
  boundary failures are not repaired by a Hessian ridge and need a separate
  profile route.
- `src/boundary_inference.jl:69-92` records the variance-boundary convention:
  a lower endpoint can equal zero, and that fact is an inference result rather
  than a failed interval.
- `src/confint_profile.jl:287-321` and `:323-362` provide the reusable
  false-position/bisection bracket machinery. The proposed adapter must add
  an optimiser convergence/gradient gate to its finite-minimum check around
  line 261, must not use the negative-deviance clipping at line 292, must not
  accept the max-iteration midpoint at lines 318-320, and must not treat a
  failed outer refit as evidence of an outside bracket at lines 339-345.

## Fixed covariance-basis identification gate

Before fitting or profiling, require `rank(D) == size(D, 2)` and form the
fixed covariance basis for every source `s` and trait `t`,

```
B_s,t = (Z_s * Z_s') kron E_t,t,
R = I_(n*p).
```

The columns `vech(B_s,t)` together with `vech(R)` must have full column rank.
This proves local linear independence of every independent source variance and
the shared residual variance for the actual supplied incidences; identical
incidences, a source proportional to the residual basis, or a rank-deficient
mean design are fail-closed selector errors. It is deliberately restricted to
all-`:indep`, all-`common=false` terms.

An implementation may avoid materialising these large covariance matrices by
forming their Gram matrix. For `B_s,t` above,

```
<B_s,t, B_u,v>_F = delta_t,v * ||Z_s' * Z_u||_F^2,
<B_s,t, R>_F     = ||Z_s||_F^2,
<R, R>_F         = n*p.
```

The algebra follows `trace((Z_s*Z_s')*(Z_u*Z_u')) = ||Z_s'Z_u||_F^2` and
`trace(E_t,t*E_v,v) = delta_t,v`. A dense small-fixture construction of the
same `B_s,t` matrices must cross-check the Gram entries and rank before the
scalable path is trusted.

## Smallest safe objective extension

Do **not** relax the global finite-parameter guard or teach generic fitting
that every `-Inf` log scale is valid. Add one internal reduced-profile adapter
around `_grouped_gaussian_objective`, conceptually:

```
_grouped_indep_variance_profile_objective(data, D, terms, incidences,
                                          selected=(term_index, trait_index),
                                          fixed_variance=v)
```

It must first validate all of the following:

1. Exactly one selected term exists, its mode is `:indep`, `common=false`,
   and the trait index is in range.
2. `v` is finite and `v >= 0` on the natural scale.
3. The incoming optimisation vector is the **reduced** full parameter vector:
   it omits only the selected `log_sd` coordinate. Every remaining coordinate
   stays finite and is checked by the existing all-finite rule.

The adapter expands the reduced vector to the normal full packed layout using
a finite placeholder at the omitted location. It then calls a narrowly
extended `_grouped_term_unpack` overlay that replaces only the selected
`:indep` diagonal entry with `v`, after ordinary exponential decoding. Thus
`v=0` is represented exactly as zero in the covariance; no `-Inf` is supplied
to the ordinary objective, and all nonselected source, coefficient, and
residual checks stay unchanged. The placeholder is an evaluator implementation
detail, **not** a reconstructed parameter estimate: at `v>0` the selected
full coordinate is reported as `eta = log(v)/2`, while at `v=0` that full
coordinate is reported missing. The retained record instead contains the
reduced minimizer, selected packed index and label, explicit natural overlay
value, and—only if needed for evaluation—a separately named finite evaluator
vector. The objective and selected covariance must be invariant to at least
two distinct finite placeholders. The profile refit also records objective
value, validity flag, convergence flag, finite-difference gradient maximum,
and stopping reason.

The full fit's packed coordinate determines `v_hat = exp(2 eta_hat)`. The
accepted reference is an **optimizer-local stationary fit**, not a proven
global maximum. For every profile point, try deterministic starts in this
order: last successful same-side warm start, the full-fit projection into the
reduced layout, and one fixed cold start. Retain every attempt. A failed warm
attempt alone does not invalidate a point when a fallback succeeds; all-start
failure does. No nuisance coordinate is copied from the unconstrained fit
without re-optimisation. Refits that reach the sentinel, have a non-finite
gradient, or fail their convergence gate contribute an explicit failed
diagnostic, not a numerical LR value.

## LR inversion and boundary behavior

For `ell_hat` from the accepted, optimizer-local full fit and an accepted
constrained refit, retain the raw and (only where permitted) adjusted LR,

```
D_raw(v) = 2 * (ell_hat - ell_profile(v)),
cutoff = quantile(Chisq(1), level).
```

Let `tol_neg` and `tol_D` be explicit documented numerical tolerances, with
`tol_neg` no larger than the ordinary final LR tolerance. Every otherwise
accepted refit follows this rule:

1. If `D_raw(v) < -tol_neg`, stop the entire interval with
   `:baseline_not_maximized`, retaining the refit and raw LR. The first slice
   does **not** silently rebase to that local solution; a future implementation
   may elect to rerun the full fit and the whole profile from a new baseline,
   but it must retain the failed attempt and never combine old and rebased LR
   traces.
2. If `-tol_neg <= D_raw(v) < 0`, record both values and set `D(v) = 0` with
   status `:roundoff_adjusted`.
3. Otherwise use `D(v) = D_raw(v)`. In particular, neither the root helper
   nor its caller may hide a material negative value through
   `sqrt(max(D, 0))`.

The confidence set is the finite, accepted set `D(v) <= cutoff`. First
evaluate `D(0)` through the exact-zero overlay:

- If `D(0) < cutoff - tol_D`, return lower endpoint `0`,
  `at_boundary=true`, status `:boundary_inside`.
- If `abs(D(0) - cutoff) <= tol_D`, return lower endpoint `0`,
  `at_boundary=true`, status `:boundary_crossing`; this is a verified zero
  crossing, not an ambiguous special case.
- If `D(0) > cutoff + tol_D`, seek a finite lower crossing on `[0, v_hat]`.

The upper crossing expands geometrically above `v_hat`. The existing
`_profile_bisect_side` / `_profile_root_falsepos` helpers may supply expansion
and safeguarded false-position proposals, but this adapter preserves the
natural-variance domain and never steps below zero. An endpoint bracket has
one finite, accepted inside refit with `D <= cutoff` and one finite, accepted
outside refit with `D >= cutoff`; an invalid/sentinel outer refit is not an
outside point. The retained ordered trace must also keep the confidence-set
component contiguous around `v_hat`: a finite re-entry below the cutoff after
an outside point, or incompatible results from the fixed deterministic starts,
fails the side as `:nonmonotone_profile` rather than selecting a convenient
crossing from a path-dependent local optimum.

Before returning either non-boundary endpoint, make one final constrained
refit at the proposed endpoint. Accept it only when the refit is valid,
finite, converged, and `abs(D(endpoint) - cutoff) <= tol_D`. If the helper
hits its iteration limit and merely returns its midpoint, or if its outer arm
was singular, report that side as unavailable with a status such as
`:root_not_verified` or `:invalid_refit`; do not turn a bracket midpoint into
an interval endpoint. Retain the bracket, every fixed `v`, raw/adjusted LR
values, reduced minimizers plus their explicit overlays (never a fabricated
zero full coordinate), validity/convergence flags, start attempts, and the
endpoint check in the returned diagnostics.

The `Chisq(1)` cutoff is a conventional Wilks reference for this interior,
optimizer-local likelihood construction; it is not a boundary-coverage or
coverage-calibration claim. `variance_lrt` / `chibar2_pvalue`
(`src/boundary_inference.jl:14-50`) may later be reported as a separate
one-component boundary test only for independently parameterised,
identified components. They do not replace profile endpoint calculation and
do not license a generic mixture-reference claim for correlated or
multi-component targets.

## Prewritten implementation tests

### Approved numerical defaults (Sol review, 2026-09-07)

The mathematical review and subsequent numerical review both approved this
bounded implementation, not a coverage or parity claim. Retained reviews are
in `.unlazy/destination-b/profile-contract-rereview-result.md` and
`profile-numerical-review-result.md`.

- `tol_D=1e-4` on the LR-deviance scale. For accepted finite likelihoods,
  `tol_neg=min(tol_D,64eps(Float64)*max(1,abs(ell_hat),abs(ell_profile)))`.
- Refit acceptance requires maximum absolute central-difference gradient at
  most `1e-5`, using steps `cbrt(eps(Float64))*max(1,abs(theta_i))`.
  Retain the steps and individual gradient components.
- Normalize the covariance Gram by its positive diagonal and symmetrize.
  With dimension `k`, use `tau_G=k*eps(Float64)*maximum(abs,eigenvalues)`.
  Eigenvalues below `-tau_G` invalidate the computation; within `±tau_G`
  count as zero; require every eigenvalue above `tau_G`. Retain diagonal,
  spectrum, threshold, numerical rank and condition diagnostic.
- For `D`, use SVD threshold `max(size(D)...)*eps(Float64)*sigma_max` and
  retain singular values, threshold, dimensions and rank. These numerical
  gates may reject algebraically identifiable but ill-conditioned designs.
- Select the lowest objective among accepted starts at each fixed variance.
  Different nuisance endpoints alone are not a nonmonotone-profile failure;
  apply re-entry checks to the ordered best-accepted trace and retain all
  attempts. Outside-to-inside re-entry remains an explicit refusal.

### Test cases

The first implementation must add deterministic, synthetic Gaussian tests;
these are specification gates, not a coverage campaign.

1. **Interior independent component.** Build a complete two- or three-trait
   response with every grouped term `:indep, common=false`, nondegenerate
   incidences, one clearly positive selected variance, positive residual
   variance, and a fixed start. Require full rank for both `D` and the dense
   covariance-basis construction, and cross-check the latter against the
   scalable Gram formula. After an accepted full fit, profile refits must
   change at least one nuisance coordinate from its full-fit value, return
   finite lower and upper endpoints, and retain a final finite LR crossing
   within `tol_D` on both sides.
2. **Exact zero.** Call the reduced adapter directly at `v=0`. It must yield a
   finite marginal objective with a selected covariance diagonal exactly zero,
   while all free packed parameters remain finite. Supplying `-Inf` to the
   ordinary `_grouped_gaussian_objective` must remain a sentinel failure. Two
   distinct finite evaluator placeholders must produce identical objective and
   selected covariance values; the `v=0` result must expose no fabricated
   selected full packed coordinate.
3. **Zero/cutoff decisions.** Use deterministic mocked accepted refits for
   `D(0) < cutoff - tol_D`, `abs(D(0) - cutoff) <= tol_D`, and
   `D(0) > cutoff + tol_D`. Require respectively `:boundary_inside`, a
   verified zero `:boundary_crossing`, and a finite lower-crossing search.
4. **Baseline and refit failures.** A material negative `D_raw` must return
   `:baseline_not_maximized`, while a negative amount inside `tol_neg` is
   retained and tagged `:roundoff_adjusted`. Separately test: warm start fails
   but full-projection or cold start succeeds; all deterministic starts fail;
   an unconverged or excessive-gradient finite minimizer; and a sentinel
   objective. Only the first case may continue, with every attempt retained.
5. **Failure-safe root.** Give the root adapter deterministic finite traces
   with no crossing within the helper iteration budget, a final-refit failure,
   and a nonmonotone/path-dependent re-entry across the cutoff. Require
   `:root_not_verified`, `:invalid_refit`, or `:nonmonotone_profile` as
   appropriate—never a midpoint or a failed outer refit as a reported
   endpoint.
6. **Identification and selector rejection.** Reject `:latent` with
   `unique=true`, `:dep`, `common=true`, multiple selected coordinates,
   out-of-range traits, negative or non-finite `v`, malformed reduced vectors,
   unconverged full fits, rank-deficient `D`, identical source incidences, and
   a residual-aliasing one-trait incidence (`Z*Z' = I_n`) before optimisation.

The test suite must also compare the selected covariance entry against the
fit's existing `term_covariances` at `v_hat`, check source/trait labels and
response/incidence provenance survive every refit, and assert that no profile
result is emitted when the final LR crossing cannot be verified.

## Explicit limits

This proposal is one internal Gaussian grouped variance profile only. It does
not add a public API, bridge option, latent-factor profile, generic
variance-component profile, R parity, profile coverage, or a claim that every
boundary target has an interval. Sol numerical review is required before code
is written. It makes no Wilks boundary-calibration or coverage claim.
