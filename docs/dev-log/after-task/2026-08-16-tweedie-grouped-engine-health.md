# After-task — grouped Tweedie false-convergence (OWED from #236)

**Date:** 2026-08-16
**Lane:** `cursor/tweedie-grouped-engine-health-20260816`
**Worktree:** `.worktrees/gllvmjl-tweedie-grouped-engine-20260816`
**Base:** `origin/main` @ `cb3c8716` (merge of #236)
**Gate:** port the #236 sentinel/convergence contract onto
`fit_tweedie_gllvm_grouped`. **The `fit_gllvm` bare-marker admit is NOT opened.**

## Goal

Close OWED #1 of #236: `fit_tweedie_gllvm_grouped` carried the same three
defects the scalar fitter had — `log(max(Y, 1e-6))` warm start, a bare `1e12`
failure sentinel, and a naked `Optim.converged` verdict — and it is the only
Tweedie route reachable from a public entry point today
(`fit_gllvm(...; disp_group = :species)`).

## Change set

| File | Change |
|---|---|
| `src/families/grouped_dispersion.jl` | Tweedie block only: `_tweedie_log_offset` warm start; `_TWEEDIE_FAIL_PENALTY` in `negll`; `_tweedie_verdict` + the two `@warn`s; docstring |
| `src/families/tweedie.jl` | `_tweedie_verdict` docstring now names both fitters |
| `test/test_tweedie_grouped_engine_health.jl` | **new** — one-group G-a on the shipped cell + per-species sweep |
| `test/runtests.jl` | register the new file |
| `docs/src/response-families.md` | drop the "grouped not repaired" warning; contract now covers both fitters |
| `CHANGELOG.md` | Fixed entry; remove the #236 "still carries" sentence |
| `docs/dev-log/check-log.md` | entry |

No other family block in `grouped_dispersion.jl` was opened. `src/families/fit_gllvm.jl` and `src/bridge.jl` were not opened.

## Tests of the tests

The new file fails under the old behaviour: on the shipped `test_tweedie.jl`
cell with one shared group, the pre-repair fitter advertised start-pinned /
sentinel points as `converged = true` (the same rows #236 recorded for the
scalar fitter). The one-group sweep requires start-agreement, `loglik > -569.74`
(the pre-repair *best* start), no `_TWEEDIE_FAIL_PENALTY` in a public result,
and a strictly interior power. It also requires the one-group fit to match
`fit_tweedie_gllvm` on `(power, φ, loglik)` — the two fitters now share the
estimand *and* the contract. The per-species sweep pins the public
`disp_group = :species` route the same way.

## Local verify (Mac-LIGHT)

```
test/test_tweedie_grouped_engine_health.jl     47/47    3m35.7s
test/test_tweedie.jl + test_grouped_dispersion_tweedie_nb1.jl
                                               39/39    1m13.2s
```

Full `Pkg.test()` is this CI run's job. No tolerance widened, no seed changed.

## Stale-wording scan

```
rg "fit_tweedie_gllvm_grouped still|has not been repaired|carries the (identical|same) three"
```

The only remaining hit is the historical #236 after-task, which was true when
written and is left in place. `docs/src/response-families.md` no longer claims
the grouped fitter is unrepaired.

## Scope fences honoured

- `src/families/fit_gllvm.jl` **not opened** — no bare-marker admit, no T2/T3/T4/T5.
- `src/bridge.jl` **not opened** — still zero `"tweedie"` occurrences. **No
  R-parity claim, no twin Δ.**
- Other grouped families' `1e12` sentinels left alone (out of lane).

## Rose fence

**Claimable:** that `fit_tweedie_gllvm_grouped` no longer reports
`converged = true` on a stalled, sentinel, or boundary point; that a one-group
power-start sweep on the shipped cell agrees with itself and with
`fit_tweedie_gllvm`; that a per-species sweep on the existing grouped smoke
cell agrees and stays interior.

**Not claimable:** that Tweedie is admitted through `fit_gllvm` with a bare
marker; any R-parity result or twin Δ; a grouped ADEMP/coverage certificate
(the one-group match to the scalar fitter is an estimand identity, not a
recovery study); that the power can be pinned; that other families' grouped
`1e12` sentinels are repaired.

## Explicitly not done — still OWED

1. The whole `fit_gllvm` surface admit — T2 (power pin / power-free marker),
   T3 (`power_init` unification), T4 (per-trait coerce), T5 (public name +
   constructors). Untouched by instruction; the Identity's STOP still stands.
2. No analytic Tweedie Laplace gradient — still finite-difference.
3. No coverage certificate.
4. `TweedieFit.p` vs `TweedieGroupedFit.power` naming (Identity §T5; breaking).

## Next

Re-open the Identity's T2/T3/T5 and the `fit_gllvm` admit only after this lands
on `main`. The public `disp_group = :species` route already used this fitter;
it now inherits the contract without a surface-admit change.

Rose verdict: PASS WITH NOTES — grouped engine-health closed; surface admit
still shut; no R-parity claim.
