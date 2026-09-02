# canary repair: phylo x Poisson `B_eta_realized` profile endpoint gate

**Scope**: `src/phylo_poisson_xlv.jl` (`_phylo_poisson_xlv_constrained_refit`,
`_phylo_poisson_xlv_profile_eta_realized`), `test/test_phylo_poisson_xlv.jl`.
Owner: Gauss/Karpinski persona (julia-engineer).

## The last red

`test/test_phylo_poisson_xlv.jl:170-174` was the only failing test in the
whole suite, on every CI run and every consolidated Totoro suite:

```julia
@test prof.endpoint_status == [:profile]   # was [:failed]
@test all(isfinite, prof.lower)
@test all(isfinite, prof.upper)
@test prof.lower[1] < prof.estimate[1] < prof.upper[1]
@test prof.lower[1] <= prof.target[1] <= prof.upper[1]
```

`prof.endpoint_status` came back `[:failed]` — `prof.lower[1]` and
`prof.upper[1]` were `NaN` even though every other diagnostic on the same
profile (`lr_deviance`, `constrained_error`, `constrained_converged`) already
described a healthy fit.

## Root cause confirmed

Traced the endpoint search directly (fixed seed 725, the test's own fixture).
The fitted model itself sits at a genuine phylogenetic-variance boundary:

```
fit.converged = true, loglik = -322.477, sigma2_phy = 8.37e-308
```

Instrumenting `_profile_bisect_side`'s calls to `dev_lower` during the
false-position root search near the true lower crossing (`c ≈ -0.054`)
showed the constrained refit landing on essentially the same answer on every
call — `nll` stable to 4 significant figures, `constraint_error` stable at
`~1.3-1.4e-5` (two orders of magnitude inside the `1e-3` default
`constraint_tol`) — while `Optim.converged(res)` (NelderMead) flickered
`true`/`false`/`true`/`false` across adjacent, nearly-identical calls:

```
c=-0.06714646912493988  converged=false  constraint_error=1.48e-5  nll=323.8407
c=-0.04989985809388102  converged=true   constraint_error=1.34e-5  nll=323.5976
c=-0.05852316360941045  converged=false  constraint_error=1.41e-5  nll=323.7162
```

At every one of those points `sigma2_phy` in the refit's theta was ~1e-260
to ~1e-308 — deep underflow territory. The old `dev_at` ok-gate was
`refit.converged && isfinite(refit.nll) && refit.constraint_error <=
constraint_tol`, so every `converged=false` call returned `NaN`, and the
bracket-then-bisect root finder in `_profile_bisect_side` treats a `NaN`
deviance as "singular region, contract in" (`confint_profile.jl:306-309`).
With roughly half the calls near the crossing spuriously discarded this way,
the root search exhausted its bisection budget without a finite outer
endpoint and returned `NaN` — `_profile_bisect_side`'s own documented
behaviour (`confint_profile.jl:318-320`): "a singular/failed refit is not
evidence of a likelihood crossing... require a finite outer endpoint."

This is a NelderMead artifact of the boundary, not a symptom of an unsound
profile: the refit that "failed" the gate has virtually the same objective
and virtually the same constraint error as the ones the gate accepted a
step earlier and a step later. Confirmed: **the diagnosis in the task brief
is correct — the canary is not wrong, the gate was.**

## The fix

`Optim.converged` is a generic solver diagnostic, not the domain success
criterion for a constrained refit. The domain criterion already exists:
"landed on the constraint to within tolerance, with a finite objective." At
the `sigma2_phy = 0` boundary the generic diagnostic is unreliable (NelderMead
oscillates near double-precision underflow on the packed log-variance
coordinate) in exactly the way `_tweedie_verdict`'s `:power_at_boundary`
handling and the Student-t `nu_boundary` convention (`families/studentt.jl`)
already document for this family of problems: don't trust the raw optimizer
flag at a variance boundary, trust the domain check.

Concretely (`src/phylo_poisson_xlv.jl`):

1. `_phylo_poisson_xlv_constrained_refit` now also returns `sigma2_phy` (the
   unpacked variance at the refit optimum) and `sigma2_boundary::Bool` —
   `true` when that variance is `<= 1e-8` (`_PHYLO_POISSON_XLV_SIGMA2_BOUNDARY_TOL`).
   Any real phylogenetic variance fitted from count data is many orders of
   magnitude above `1e-8`; the floor sits purely in underflow territory, so it
   only fires on true boundary degeneracy, never on an interior estimate.
2. `dev_at`'s ok-gate is now:
   `domain_ok = isfinite(nll) && constraint_error <= constraint_tol`;
   `boundary_accept = domain_ok && !converged && sigma2_boundary`;
   `ok = domain_ok && (converged || boundary_accept)`.
   A refit is accepted when it satisfies the constraint with a finite
   objective, *and* either the optimizer says it converged, or it didn't
   converge but the refit sits at the variance boundary where that flag is
   known-unreliable.
3. Every entry in the profile result now carries an
   `endpoint_boundary::Vector{Bool}` field: `true` iff the lower or upper
   endpoint search for that entry accepted at least one refit through the
   boundary-tolerant path. This makes the boundary acceptance observable —
   a user (or a future test) can see the endpoint was accepted at a
   degenerate variance rather than a normal converged optimum.

This is *not* "drop the converged check everywhere." Off the boundary, a
`converged=false` refit is still rejected unless it happens to also satisfy
the constraint (rare, and harmless if it does — the constraint is the
correctness criterion either way). The boundary flag only widens acceptance
in the one regime where the diagnosis showed the raw flag was noise, not
signal.

## Guarding against an over-loose gate (requirement (b))

Added a deliberately unsatisfiable-tolerance red test to
`test/test_phylo_poisson_xlv.jl` (after the canary's existing
`@test_throws` block): `constraint_tol = 1e-14` with `profile_iterations =
3` — a tolerance no double-precision NelderMead continuation can hit, and an
iteration budget too small to approach it. This is a genuinely failed
endpoint search, unrelated to any variance boundary:

```julia
prof_fail = GLLVM._phylo_poisson_xlv_profile_eta_realized(
    fit, Y, phy, X_lv, [1], eta_target;
    level = 0.95, profile_iterations = 3, constraint_tol = 1e-14,
    newton_maxiter = 120, newton_tol = 1e-10)
@test prof_fail.endpoint_status == [:failed]
@test all(isnan, prof_fail.lower)
@test all(isnan, prof_fail.upper)
@test prof_fail.constrained_error[1] > 1e-14
@test prof_fail.endpoint_boundary == [false]
```

Confirmed red before the constant/threshold reasoning was in place (i.e. it
is not accidentally satisfied by the boundary-tolerant path):
`constrained_error[1] ≈ 0.0211`, `endpoint_boundary == [false]` — the failure
is genuine constraint non-satisfaction, and the gate correctly reports
`:failed` for it under the same (unchanged-for-non-boundary) logic.

## Evidence

Standalone run, `test/test_phylo_poisson_xlv.jl`:

```
Test Summary:                                        | Pass  Total  Time
Phylo x Poisson predictor-informed LV S1 likelihood  |    9      9  4.7s
Test Summary:                                        | Pass  Total  Time
Phylo x Poisson B_eta_realized selected-entry canary |   27     27  8.4s
```

(27 assertions in the second testset, up from 22 before the new red-first
failure test was added; all pass, including the previously-red lines
170-174.)

Collateral checks — profile-CI machinery this gate shares (`_profile_bisect_side`,
`confint_profile.jl`) is untouched, verified by running every profile-CI test
file standalone:

```
test/test_confint_profile.jl        : profile CI                                    | 8/8 pass
test/test_profile_derived_fix.jl    : profile_ci_derived fix on phylo cell           | 20/20 pass
test/test_profile_failure_bounds.jl : GE profile failure bounds                      | 4/4 pass (needs `using GLLVM`
                                       in scope when run standalone — pre-existing,
                                       not a regression; runtests.jl already provides it)
test/test_profile_rootfind.jl       : Profile CI root-finder (fast false-position)   | 9/9 pass
```

No tolerance was widened anywhere; no assertion in the original canary test
was weakened; the fixture (seed 725, the tree, the counts) is untouched.

## Root cause verdict

**Confirmed**: the profile *was* sound (finite crossing on both sides, truth
inside the interval, deviance under cutoff, constraint satisfied to
`~1e-6`-`1e-5`); the ok-gate's blind trust in `Optim.converged` at a genuine
variance boundary was the bug. Fixed at the gate, per the house convention
already established for Tweedie's `:power_at_boundary` and Student-t's
`nu_boundary`. The canary's own diagnosis (task brief) was correct.
