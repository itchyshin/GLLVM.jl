# After-task — NB1 no-X grouped route: missing `hessian` kwarg (wrong default, not wrong algorithm)

**Date:** 2026-08-24
**Lane:** `parity-catchup` on `handover/2026-08-24-claude`, worktree
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`. PLATFORM: claude.
**Follows:** `2026-08-24-rung-a-nox-dispersion-cells.md`, which recorded this defect as
`@test_broken` after the parity cell caught it.
**Reviewed as:** Ada (orchestration), Gauss (numerics), Rose (same-class sweep).

## Goal, stated as a check first

`fit_nb1_gllvm_grouped(Y; K, group)` agrees with `gllvmTMB` `nbinom1()` at rtol 1e-6
on the Rung A fixture, the parity cell's `@test_broken` flips back to `@test` and
passes, every previously-green cell stays green in the same invocation, and the full
`Pkg.test()` is clean — with no tolerance widened.

## Root cause

`nb1_grouped_marginal_loglik_laplace` defaults to `hessian = :fisher`
(`src/families/grouped_dispersion.jl:1154`). `fit_nb1_gllvm_grouped` declared **no
`hessian` keyword at all**, so every no-X NB1 fit silently inherited the
expected-information Laplace.

The decisive evidence is that the file already documented the opposite. Its NB1
section header, line 1079:

> `# The fit/cov default hessian=:observed is the TMB Laplace curvature (different objective).`

That contract covers **fit *and* cov**. `fit_nb1_gllvm_grouped_cov` honoured it
(`hessian::Symbol = :observed`, threaded through); the no-X sibling did not. The NB2
(`fit_nb_gllvm_grouped`) and Beta (`fit_beta_gllvm_grouped`) routes had the keyword
all along. NB1 no-X was the lone straggler — the code contradicted its own stated
contract.

**This reframes every symptom.** The optimiser was never failing; it was converging
*correctly* to a **different objective**. That is exactly why the earlier triage found
stability under `g_tol` 1e-5→1e-10 and `newton_tol` 1e-9→1e-12 with
`converged == true` throughout, and a reproducible offset rather than noise. Those
"ruled out" results were not dead ends — in hindsight they were the signature of a
wrong objective rather than a bad optimisation.

## Fix

Give `fit_nb1_gllvm_grouped` the same `hessian::Symbol = :observed` default as its
siblings, and thread it into `nb1_grouped_marginal_loglik_laplace`. Two lines of code
plus a docstring note. No algorithm changed, no new machinery: the observed-curvature
weight function `_nb1_grouped_laplace_weight` already existed and was already exercised
by the `_cov` route.

```
twin gllvmTMB                = -1129.6667320371555
no-X default (now :observed) = -1129.6667320237123   Δ =  1.3443241186905652e-8  ✓
no-X hessian=:fisher         = -1129.7817843739615   Δ = -0.11505233680600213    (old default)
zero-X _cov route            = -1129.6667320237116   Δ =  1.3443923307931982e-8
```

**A default changed, not a capability removed.** `:fisher` remains a legitimate
expected-information objective and is still reachable explicitly; it was only ever
wrong as a *silent default*. A regression testset asserts it stays reachable, stays a
different objective, and stays strictly worse against TMB's — pinning the **direction**
of the fix, not merely its magnitude.

## Files changed

| File | Change |
|---|---|
| `src/families/grouped_dispersion.jl` | `hessian::Symbol = :observed` on `fit_nb1_gllvm_grouped`; threaded into the objective; docstring + rationale note |
| `test/parity/test_nox_dispersion_parity.jl` | `@test_broken` → `@test`; two regression testsets (no-X ≡ zero-X `_cov`; `:fisher` still reachable and still different) |
| `docs/design/capability-status.md` | NB1 no-X receipt flipped from NOT-PAID to **PAID**, carrying the defect history |
| `docs/dev-log/check-log.md` | root cause, fix, verification, same-class sweep |

## Rose sweep — assume ten more of the same kind

Audited **every** `fit_*_grouped*` entry point for the same omission:

| Fitter | declares `hessian` | passes it |
|---|---|---|
| `fit_nb_gllvm_grouped` / `_cov` (NB2) | yes | yes |
| `fit_beta_gllvm_grouped` / `_cov` | yes | yes |
| `fit_gamma_gllvm_grouped` / `_cov` | yes | yes |
| `fit_nb1_gllvm_grouped` / `_cov` | yes (**this fix**) | yes |
| `fit_beta_binomial_gllvm_grouped` / `_cov` | no — **not applicable** | — |
| `fit_tweedie_gllvm_grouped` | no — **not applicable** | — |

The last two are **not** the same bug. Beta-binomial explicitly documents *"No
`hessian=:observed`/`:fisher` knob (G0 lock — FD-outer, ForwardDiff-inner)"*, and
`_tweedie_grouped_loglik_site` takes no `hessian` parameter — in both cases no
fisher/observed split exists, so there is nothing to pass. Beta-binomial's own no-X
parity cell independently agrees with the twin at 6.15e-9, confirming it empirically
rather than by inspection alone. **NB1 was the only instance of this class.**

Every family that *has* the split now declares and passes it.

## Checks run

- **Parity suite: 195 pass / 0 broken / 0 failed, exit 0.** NB1 no-X Δ = 1.344e-8;
  every previously-green cell green in the same invocation.
- **Full `Pkg.test()`** — required because `src/` changed. Result in the check-log.
- No tolerance widened; no seed changed.

## What did not go smoothly

The first triage pass ruled out convergence and mode accuracy and concluded "defect in
the no-X path" without identifying *which* defect. That was correct but incomplete —
the invariance results were themselves the clue (a wrong objective, converged cleanly),
and reading the file's own section header would have pointed at `hessian` sooner than
the empirical bisection did. Lesson: when a fit is stable, converged, and reproducibly
offset, suspect the **objective** before the optimiser.

## Remaining risks / limitations

1. One fixture and one seed. The fix is verified on the Rung A cell plus the full
   suite; it is not a coverage claim.
2. `hessian=:fisher` callers of `fit_nb1_gllvm_grouped` who relied on the old *implicit*
   default will see a changed number. That is the intended correction, but it is a
   behaviour change for anyone who did not pass the keyword — flagged here because the
   old default was silent.
3. Tweedie's grouped route retains its own separate, previously recorded defects; out
   of scope here.

## Rose verdict

Not independently audited. The central claims — the fix, its direction, and the
same-class sweep — are all shipped as live assertions or reproducible commands, so any
reviewer can re-run them rather than take this report's word.

## Addendum — the sweep extended to the neighbouring class

The `hessian` sweep above covers one way a silent default can corrupt a Δ. The same
failure shape could hide in the **link** default, so that was swept too: every no-X
family fitter's `link::Link = …` default was compared against what the twin's engine
enforces or defaults to.

| Julia fitter | default link | twin | |
|---|---|---|---|
| `fit_lognormal_gllvm` | `LogLink()` | log | ✓ |
| `fit_truncated_poisson_gllvm` | `LogLink()` | log (engine-enforced) | ✓ |
| `fit_gamma_gllvm_grouped` | `LogLink()` | log | ✓ |
| `fit_nb1_gllvm_grouped` | `LogLink()` | log | ✓ |
| `fit_nb_gllvm_grouped` | `LogLink()` | log | ✓ |
| `fit_beta_gllvm_grouped` | `LogitLink()` | logit | ✓ |
| `fit_beta_binomial_gllvm_grouped` | `LogitLink()` | logit | ✓ |

All match. So across both dimensions a silent default could have gone wrong —
Laplace curvature and link — **NB1's `hessian` was the only instance**.
