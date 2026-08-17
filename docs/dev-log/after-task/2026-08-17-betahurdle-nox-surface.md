# After-task — Beta-hurdle no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-17
**Lane:** `cursor/betahurdle-nox-20260817`
**Worktree:** `.worktrees/gllvmjl-betahurdle-nox-20260817`
**Base:** `origin/main` @ `07a01ede` (merge of #244, Hurdle-NB no-X admit)
**Identity:** `docs/dev-log/decisions/2026-08-17-betahurdle-fit-gllvm-identity.md` (#243)

## Goal

Make `BetaHurdle` reachable through the unified `fit_gllvm` entry point — and
hence through `@formula` with no covariates — after the tag-payload Identity
lock. No new engine, no new estimand, no bridge.

## Locks applied

C1 tag-payload `φ` (never read; named fitter has no `φ_init`); C1b
`BetaHurdle() = BetaHurdle(5.0)`; C2 one `_fit_gllvm(::BetaHurdle)` arm; C3 no
bridge / no twin Δ; C4 no +X / `disp_group` / `row_eff`; C5 export `BetaHurdle`.

## Change set

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `BetaHurdle` |
| `src/families/beta_hurdle.jl` | `BetaHurdle() = BetaHurdle(5.0)`; docstring restates C1 |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::BetaHurdle)` → `fit_beta_hurdle_gllvm`; docstring + availability string |
| `test/test_beta_hurdle.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter, 1e-8; `BetaHurdle(80.0)` tag-inert) |
| `docs/src/response-families.md` | table row + unified-entry paragraph + example |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `docs/src/gllvmtmb-parity.md` | Julia-forward note |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell unchanged) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl` and `src/bridge.jl` were **not** opened.
`src/families/tweedie.jl` was **not** opened. No include move
(`beta_hurdle.jl` already precedes `fit_gllvm.jl`). No twin light Δ.

## Verification

Mac-LIGHT focused tests (local):

```
julia --project=. --startup-file=no test/test_beta_hurdle.jl
Test Summary:     | Pass  Total   Time
beta-hurdle GLLVM |   62     62  10.4s
```

Full suite = GitHub CI on the PR.

## Rose fence

Status cell `ordered_beta / beta_hurdle` stays `implemented` (engine + test
already existed). No R-parity, ADEMP, or coverage claimed. +X / `disp_group` /
row effects / bridge remain OWED. Twin has no beta-hurdle family — a light Δ
would be invented.

Rose verdict: PASS WITH NOTES — surface admit only; Ordered-beta still needs
its own engine slice.

## Next

Ordered-beta engine (#240 Identity). Tweedie stays STOP (T2–T5 unpaid).
