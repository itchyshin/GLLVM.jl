# After-task — Student-t no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-16
**Lane:** `cursor/studentt-nox-surface-20260816`
**Worktree:** `.worktrees/gllvmjl-studentt-nox-20260816`
**Base:** `origin/main` @ `cb54467a` (merge of #230, the BetaBinom no-X admit)
**Gate:** started only after the BetaBinom no-X `fit_gllvm` admit merged
(#230, merged 2026-08-16T12:21:24Z)

## Goal

Make `StudentTFamily` reachable through the unified `fit_gllvm` entry point — and
hence through `@formula` with no covariates — as the cheapest remaining surface
admit. No new engine, no new estimand, no bridge.

## Why this was the cheapest admit left

Student-t already had everything except the one-line route: a complete Laplace
family (`_glm_score` / `_glm_weight` / closed-form `_glm_logpdf`), a fit driver
(`fit_studentt_gllvm`), an exported marker, a `link_residual` rule, a `simulate`
method, and its own passing test file. The only missing piece was the
`_fit_gllvm` arm — which also silently closed the no-X `@formula` surface, since
`formula.jl` falls through to `fit_gllvm` at `q == 0`.

## The one real design question: what does the marker carry?

`StudentTFamily(ν, σ)` carries two fields, and they are **not** the same kind of
thing. Getting this wrong in either direction would have been a real error:

| Field | Kind | Treatment | Precedent |
|---|---|---|---|
| `ν` (degrees of freedom) | **structural** — defines the likelihood, held FIXED, never estimated | **forwarded** as the fitter's `nu` | `ZIB(N)` forwards its trials count |
| `σ` (scale) | **dispersion** — always estimated | **ignored** (tag payload; seed via `σ_init`) | `NB1(φ)` / `BetaBinom(φ)` inert payloads |

Treating `ν` as an inert payload (the NB1/BetaBinom reflex) would have pinned every
`fit_gllvm` Student-t fit to ν = 4 regardless of the marker. Treating `σ` as
structural would have advertised a scale the fitter overwrites.

### Sub-question: the duplicate-`nu` collision

Because `ν` is forwarded, a caller could also pass `nu` as a keyword. Julia
resolves a duplicated keyword in favour of the **splatted** one, so the bare
keyword would have silently won and contradicted `family`. Verified directly:

```julia
g(; nu = 4.0, kw...) = nu;  f(fam; kwargs...) = g(; nu = fam, kwargs...)
f(4.0)             # 4.0
f(4.0; nu = 9.0)   # 9.0   ← the marker loses, silently
```

The arm therefore rejects it with a clear `ArgumentError` naming the marker form.
This is a deliberate **deviation** from the `ZIB` precedent, which leaves the
analogous `N` collision unguarded — `ZIB` is out of lane here and was not touched.

## Change set

| File | Change |
|---|---|
| `src/families/studentt.jl` | marker docstring rewritten (routes; ν structural vs σ payload); `StudentTFamily()` and `StudentTFamily(ν)` convenience constructors (mirrors `NB1()`, C1b), ν defaulting to the fitter's own 4.0 |
| `src/families/fit_gllvm.jl` | new `_fit_gllvm(::StudentTFamily, …)` arm forwarding `nu = family.ν` with the duplicate-`nu` guard; availability string; docstring family list + example |
| `test/test_studentt.jl` | new focused `no-X public surfaces` testset |
| `docs/src/response-families.md` | entry-point example; `StudentTFamily(ν)` table row; identity-link note; the "reached through `fit_gllvm`" paragraph; new **Student-t** family section |
| `docs/src/tutorial.md` | Student-t as the outlier-robust continuous option, with both routes and the no-X fence |
| `README.md` | Student-t added to the one-part Laplace family list |
| `docs/design/capability-status.md` | evidence pointer + explicit OWED fence (no status or parity change) |
| `docs/dev-log/check-log.md` | entry |

`src/GLLVM.jl` was **not** opened — the marker was already exported.
`src/formula.jl` was **not** opened — the no-X surface opens by fall-through.

## Verification

Mac-LIGHT: no local `Pkg.test()` — GitHub CI is the verifier.

```
julia --project=. test/test_studentt.jl
Test Summary:                                | Pass  Total   Time
Student-t (heavy-tailed continuous, fixed ν) |   28     28  22.4s
```

28 = the 17 pre-existing engine assertions + 11 new surface assertions. The pre-existing
FD-gradient check still reports max rel err 6.4e-9 (≤ 1e-6 gate).

Direct surface smoke (p=3, n=30, K=1, 15 iterations, ν = 5):

```
StudentTFamily exported: true
StudentTFamily() = StudentTFamily{Float64}(4.0, 1.0)   StudentTFamily(5.0) = (5.0, 1.0)
fit_gllvm(family=StudentTFamily(5.0))   -> StudentTFit, nu=5.0, sigma=0.641214, ll=-115.947975
fit_studentt_gllvm(nu=5.0)              -> dll = 0.000e+00  (same engine)
family=StudentTFamily(5.0, 9.0)         -> dll = 0.000e+00  (marker sigma ignored)
family=StudentTFamily(50.0)             -> nu=50.0, dll = -1.3298  (marker nu IS read)
gllvm(@formula(y ~ 1), ...)             -> StudentTFit, dll = 0.000e+00
nu passed alongside marker              -> ArgumentError (names the marker form)
disp_group = :species                   -> ArgumentError (no grouped fitter)
row_eff = :random                       -> MethodError  (_cov_default_link; pre-existing)
@formula with a covariate (+X)          -> MethodError  (_cov_default_link; pre-existing)
unimplemented-family message            -> now lists StudentTFamily
```

The `StudentTFamily(50.0)` row is the one that matters: a heavier/lighter tail
gives a genuinely different log-likelihood, so the marker's ν is demonstrably read
rather than defaulted.

## Scope fences

+X, `disp_group`, and `row_eff` all error for Student-t, and **all three errored
the same way before this PR** — none is opened, none is closed. `disp_group` gives
a clear `ArgumentError`; +X and `row_eff` give a raw `MethodError` from the missing
`_cov_default_link(::StudentTFamily)`. That rough edge is pre-existing and was left
alone rather than swept into a surface-admit PR; see Next.

## Explicitly not done

- `src/bridge.jl` **not opened** ⇒ **no** new R-parity claim and **no** twin Δ. The
  twin's `student` route is not benchmarked here, so inventing a light Δ was out of
  scope by instruction.
- No coverage / ADEMP result.
- No analytic `studentt_laplace_grad` — the driver still uses a finite-difference
  Optim gradient (issue #105).
- No joint estimation of ν (needs a second auxiliary the scalar-aux path lacks).

## Rose fence

**Claimable:** Student-t is reachable through `fit_gllvm` and through
`@formula(y ~ 1)`, returning `StudentTFit` identical to `fit_studentt_gllvm` at the
same fixed ν; the marker's ν is forwarded and its σ is inert; a contradictory `nu`
keyword is rejected rather than silently honoured.

**Not claimable:** any R-parity / twin Δ; any coverage or ADEMP result; Student-t
under X, `disp_group`, or row effects; an analytic Laplace gradient; estimated ν.

## Next

1. A clean `ArgumentError` for families with no `_cov_*` methods (`+X` and
   `row_eff`), replacing the raw `MethodError` — one guard, benefits Student-t,
   Lognormal, and every future scalar family at once.
2. `TweedieED` marker export/admit — the last unexported marker holding a grouped
   arm; still open from the NB1 arc.
