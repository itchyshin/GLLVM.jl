# After-task — Tweedie engine health: false convergence repaired (G-a…G-d)

**Date:** 2026-08-16
**Lane:** `cursor/tweedie-engine-health-20260816`
**Worktree:** `.worktrees/gllvmjl-tweedie-engine-20260816`
**Base:** `origin/main` @ `7b45ba04` (merge of #234, the Tweedie no-X Identity)
**Gate:** the engine-health arc that
`docs/dev-log/decisions/2026-08-16-tweedie-fit-gllvm-identity.md` §T6 blocks the
`fit_gllvm` surface admit on. **The surface admit is NOT opened here.**

## Goal

Close G-a…G-d in §T6 of the Identity: stop `fit_tweedie_gllvm` advertising
start-pinned, sentinel, and out-of-contract points as `converged = true`.

## What was actually wrong

The Identity recorded the symptoms. The cause, found by instrumenting `Optim`'s
stopping flags on the shipped test cell (`test/test_tweedie.jl:48-63`,
`Random.seed!(2024)`, p=5, n=40, K=2), is **one bad warm start feeding two
different lies in the convergence verdict**.

### Cause: the log warm start destroys the intercepts

`Zemp = log.(max.(Yc, 1e-6))` maps every exact zero to `−13.8` **whatever the
data scale**. The shipped cell has 50 structural zeros in 200 cells, so:

| quantity | shipped warm start | truth |
|---|---|---|
| `β0` | `[-6.697, -2.357, -2.047, -1.391, -3.337]` | `[-0.332, 0.662, 0.510, 0.860, 0.155]` |
| `‖Λ0‖` | `10.14` | `1.142` |

That start sits at `loglik = −7.74e8` (φ=1, p=1.5). The optimiser never recovers.

### Lie 1 — `f_converged` on an objective of size 1e11

`Optim`'s f-change test is **relative**, so on an objective of ~`3.9e11` it fires
after a few stalled steps while the gradient residual is still `8.1e15`:

```
p_init=1.5  f(θ0)=3.8887e11  f(θ̂)=3.88867e11  iters=7  g_residual=8.077e15
   stopped_by = (x_converged=false, f_converged=TRUE, g_converged=false, …)
   Optim.converged = true
```

### Lie 2 — `g_converged` on the flat failure plateau

`negll` returned a bare `1e12` whenever the marginal could not be evaluated. That
plateau is exactly flat, so the finite-difference gradient is **exactly zero** and
`Optim` reports genuine gradient convergence at iteration 1:

```
p_init=1.7  f(θ0)=9.13e16  f(θ̂)=1e12  iters=1  g_residual=0
   stopped_by = (…, g_converged=TRUE, …)   Optim.converged = true
```

`−1e12` was then returned as the maximised Laplace log-likelihood, with
`φ̂ = 3.2e54` and `p̂ = 1.0` — outside the open interval `(1,2)` that
`TweedieFit`'s own docstring promises.

## Change set

| File | Change |
|---|---|
| `src/families/tweedie.jl` | `_tweedie_log_offset` + offset warm start; named `_TWEEDIE_FAIL_PENALTY` / `_TWEEDIE_XI_MAX`; new `_tweedie_verdict` convergence contract; `@warn` on the two hard failures; docstring |
| `test/test_tweedie_engine_health.jl` | **new** — G-a…G-d |
| `test/test_tweedie.jl` | `@test fit.converged` added to the existing machinery block (tightened, not reseeded, not widened) |
| `test/runtests.jl` | register the new file |
| `docs/src/response-families.md` | Tweedie convergence-contract note |
| `CHANGELOG.md` | Fixed entry |
| `docs/dev-log/check-log.md` | entry |

### 1. Warm-start offset (root cause → G-a)

`log(Y + c)` with `c = 0.1 · mean(Y[Y > 0])` over the **observed** cells. The
zeros stay on the data's own scale: `β0` lands near truth, `‖Λ0‖ = 1.74`.

### 2. `_tweedie_verdict` (→ G-b, G-c, and the residual G-a risk)

`Optim`'s verdict is necessary but not sufficient. Three added checks:

| reason | test | reported |
|---|---|---|
| `:objective_failed` | objective still at `_TWEEDIE_FAIL_PENALTY`, or non-finite | `converged=false`, `loglik = -Inf` (**never** `−1e12`), `@warn` |
| `:power_at_boundary` | `abs(ξ) > 20` (power within ~2e-9 of 1 or 2) | `converged=false`, `@warn` |
| `:gradient_not_small` | `g_residual > max(g_tol, g_tol·abs(nll))` | `converged=false` |

The gradient test is **scale-relative**, which is precisely what defeats Lie 1:
at `nll = 3.9e11` the bar is `3.9e6` and the observed `8.1e15` fails it, while at
the healthy optimum the bar is `3.4e-3` and the observed `5.6e-6` passes with
three orders of margin.

## Verification

Mac-light. Focused tests locally; full `Pkg.test()` is GitHub CI's job.

### G-a — power-start sweep, shipped cell, verbatim

Before (from the Identity, reproduced on this base):

```
p_init=1.1 -> p̂=1.251948 φ̂=2.07988    loglik=-569.73996    conv=true iters=11
p_init=1.3 -> p̂=1.300000 φ̂=1          loglik=-1090.0722    conv=true iters=4
p_init=1.5 -> p̂=1.500000 φ̂=1          loglik=-3.8886709e11 conv=true iters=7
p_init=1.7 -> p̂=1.000000 φ̂=3.24777e54 loglik=-1e12         conv=true iters=1
p_init=1.9 -> p̂=1.000000 φ̂=2.20421e205 loglik=-1e12        conv=true iters=1
```

After:

```
p_init=1.1 -> p̂=1.27689669 φ̂=1.0937254 loglik=-336.5943511 conv=true iters=23
p_init=1.3 -> p̂=1.27689670 φ̂=1.0937254 loglik=-336.5943511 conv=true iters=23
p_init=1.5 -> p̂=1.27689671 φ̂=1.0937254 loglik=-336.5943511 conv=true iters=24
p_init=1.7 -> p̂=1.27689671 φ̂=1.0937254 loglik=-336.5943511 conv=true iters=24
p_init=1.9 -> p̂=1.27689670 φ̂=1.0937255 loglik=-336.5943511 conv=true iters=28
```

All five starts agree to 8 significant figures, all reach `g_converged` with a
gradient residual of ~5e-6, and the optimum beats the pre-repair **best** start
by 233 nats and the pre-repair **default** start by ~9 orders of magnitude. A
`φ_init ∈ {0.5, 1, 2, 5}` sweep at `p_init = 1.5` lands on the same point.

### G-d — recovery, correct DGP

The shipped cell draws from a "rough Poisson intensity" approximation, not a
Tweedie, so it could never support a recovery claim. The new check uses
`_tweedie_sample` (the actual compound Poisson–Gamma), p=6, n=80, K=1, φ=1.0,
power=1.5, 3 replicates:

```
rep 1: φ̂=0.9778 p̂=1.4640 conv=true
rep 2: φ̂=0.9496 p̂=1.5025 conv=true
rep 3: φ̂=1.1374 p̂=1.5295 conv=true
mean φ̂ = 1.0216 (true 1.00)   mean p̂ = 1.4987 (true 1.50)
```

### Test tally

```
julia --project=. test/test_tweedie_engine_health.jl
Test Summary:                   | Pass  Total     Time
Tweedie engine health (G-a…G-d) |   48     48  7m41.4s
```

The 7m41s is honest cost: the pre-repair fits were fast **because** they stopped
after 1–7 iterations; the repaired ones run 23–28.

### Blast radius — every other Tweedie-dependent test file

```
test/test_tweedie.jl                 14/14    48.3s   (incl. the new `@test fit.converged`)
test/test_missing_response_extra.jl  35/35   3m33.1s  (mask/`missing` invariance survives the offset)
test/test_postfit_zib_tweedie.jl     37/37    43.7s
test/test_confint_family.jl        240/240   6m53.9s  (2026-08-03 seed repair stands)
```

`test_tweedie.jl` also gained `LinearAlgebra` to its `using` line: it calls `dot`
and only ran standalone by borrowing the import from `runtests.jl`. Pre-existing;
fixed because this arc needed to run the file on its own.

The grouped-Tweedie files (`test_grouped_dispersion_tweedie_nb1.jl`,
`test_aicbic_newfits.jl`) exercise `fit_tweedie_gllvm_grouped`, which this PR
does not touch.

## Gate status

| Gate | Status |
|---|---|
| **G-a** power-start sweep agrees | ✅ 8 significant figures across 5 starts |
| **G-b** no `1e12` sentinel in a public result | ✅ `converged=false` + `loglik=-Inf` + warning |
| **G-c** `p̂` strictly interior or flagged | ✅ `abs(ξ) > 20` ⇒ flagged + warning |
| **G-d** ADEMP recovery on `(φ, power)` | ✅ 3 replicates, correct DGP |

## Explicitly not done — OWED

1. **`fit_tweedie_gllvm_grouped` carries the identical three defects** and is the
   only route reachable from a public entry point today
   (`fit_gllvm(disp_group = :species)`). `src/families/grouped_dispersion.jl:1563`
   is the same `log.(max.(Yc, 1e-6))`; `:1589`/`:1591` the same bare `1e12`;
   `:1602` the same naked `Optim.converged(res)`. Not fixed here to keep this PR
   to one file and one concern, and because `grouped_dispersion.jl` is a shared
   choke point with live parallel lanes. **This is the top OWED item** — the
   helpers it needs (`_tweedie_log_offset`, `_tweedie_verdict`) now exist and the
   change is ~4 lines.
2. **The whole `fit_gllvm` surface admit** — T2 (power pin / power-free marker),
   T3 (`power_init` unification), T4 (per-trait coerce), T5 (public name +
   constructors). Untouched by instruction; the Identity's STOP still stands.
3. No analytic Tweedie Laplace gradient — still finite-difference.
4. No coverage certificate; 3 replicates is a recovery floor, not a coverage study.
5. `TweedieFit.p` vs `TweedieGroupedFit.power` naming disagreement — recorded in
   the Identity §T5, still not harmonised (breaking).

## Scope fences honoured

- `src/bridge.jl` **not opened** — zero occurrences of `"tweedie"`, nothing to
  admit or fence. **No R-parity claim, no twin Δ, invented or otherwise.**
- `test/test_confint_family.jl` **not opened** — the 2026-08-03 seed repair was
  not re-litigated (its Tweedie fit was re-run as a blast-radius check only).
- No test tolerance widened and no seed changed anywhere. The one change to an
  existing test is an **added** assertion.

## Rose fence

**Claimable:** that `fit_tweedie_gllvm` no longer reports `converged = true` on a
stalled, sentinel, or boundary point; that its power-start sweep on the shipped
cell agrees to 8 significant figures where it previously spanned 9 orders of
magnitude; that `(φ, power)` recover from the correct DGP at one small cell;
that G-a…G-d as written in the Identity §T6 pass for the **scalar** fitter.

**Not claimable:** that Tweedie is admitted, reachable through `fit_gllvm` with a
bare marker, or surface complete; anything about the **grouped** fitter, which
still carries all three defects; any R-parity result or twin Δ; any coverage or
ADEMP certificate beyond the 3-replicate recovery floor above; that the power can
be pinned.

## Next

1. Port `_tweedie_log_offset` + `_tweedie_verdict` into
   `fit_tweedie_gllvm_grouped` (OWED #1) — that is what the surface admit will
   actually route to under T4.
2. Only then re-open the Identity's T2/T3/T5 and the `fit_gllvm` admit.
