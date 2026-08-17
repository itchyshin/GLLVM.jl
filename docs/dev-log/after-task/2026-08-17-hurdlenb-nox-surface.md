# After-task — Hurdle-NB no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-17
**Lane:** `cursor/hurdlenb-nox-20260817`
**Worktree:** `.worktrees/gllvmjl-hurdlenb-nox-20260817`
**Base:** `origin/main` @ `5bd236dc` (merge of #241, COM-Poisson no-X admit)
**Identity:** `docs/dev-log/decisions/2026-08-17-hurdlenb-fit-gllvm-identity.md` (#242)

## Goal

Make `HurdleNB` reachable through the unified `fit_gllvm` entry point — and
hence through `@formula` with no covariates — after the tag-payload Identity
lock. No new engine, no new estimand, no bridge.

## Locks applied

C1 tag-payload `r` (never read; named fitter has no `r_init`); C1b
`HurdleNB() = HurdleNB(10.0)`; C2 one `_fit_gllvm(::HurdleNB)` arm; C3 no
bridge / no twin Δ; C4 no +X / `disp_group` / `row_eff`; C5 export `HurdleNB`.

## Change set

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `HurdleNB` |
| `src/families/twopart.jl` | `HurdleNB() = HurdleNB(10.0)`; docstring restates C1 |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::HurdleNB)` → `fit_hurdle_nb_gllvm`; docstring + availability string |
| `test/test_hurdle_nb.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter, 1e-8; `HurdleNB(99.0)` tag-inert) |
| `docs/src/response-families.md` | table row + unified-entry paragraph + example |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `docs/src/gllvmtmb-parity.md` | Julia-forward note |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell unchanged) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl` and `src/bridge.jl` were **not** opened.
`src/families/tweedie.jl` was **not** opened. No include move
(`twopart.jl` already precedes `fit_gllvm.jl`). No twin light Δ.

## Verification

Mac-LIGHT focused tests (local):

```
julia --project=. --startup-file=no test/test_hurdle_nb.jl
Test Summary: | Pass  Total   Time
Hurdle-NB     |   24     24  22.7s
```

Full suite = GitHub CI on the PR.

## Rose fence

Status cell `hurdle_poisson / hurdle_nbinom2` stays `implemented` (engine +
test already existed). No R-parity, ADEMP, or coverage claimed. +X /
`disp_group` / row effects / bridge remain OWED. Twin has no hurdle family —
a light Δ would be invented.

Rose verdict: PASS WITH NOTES — surface admit only; Beta-hurdle / Ordered-beta
still need their own Identity-or-arm slices.

## Next

Beta-hurdle Identity (#243) then engine if surgical. Ordered-beta engine after
#241 (cleared) and after Hurdle-NB / Beta-hurdle Identities. Tweedie stays STOP.
