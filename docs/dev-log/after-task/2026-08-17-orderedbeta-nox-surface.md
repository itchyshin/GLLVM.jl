# After-task — Ordered-beta no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-17
**Lane:** `cursor/orderedbeta-nox-20260817`
**Worktree:** `.worktrees/gllvmjl-orderedbeta-nox-20260817`
**Base:** `origin/main` @ `320c83b1` (merge of #245, Beta-hurdle no-X admit)
**Identity:** `docs/dev-log/decisions/2026-08-16-orderedbeta-fit-gllvm-identity.md` (#240)

## Goal

Make `OrderedBeta` reachable through the unified `fit_gllvm` entry point — and
hence through `@formula` with no covariates — after the tag-payload Identity
lock. No new engine, no new estimand, no bridge.

## Locks applied

C1 / C1-cuts tag-payload `c0`, `c1`, `φ` (never read; never `c0_init` /
`c1_init` / `φ_init`); C1b `OrderedBeta() = OrderedBeta(-1.0, 1.0, 10.0)`;
C2 one `_fit_gllvm(::OrderedBeta)` arm; C3 no bridge / no twin Δ; C4 no +X /
`disp_group` / `row_eff`; C5 export `OrderedBeta`. Include
`ordered_beta.jl` moved before `fit_gllvm.jl`.

## Change set

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `OrderedBeta`; move `include("families/ordered_beta.jl")` before `fit_gllvm.jl` |
| `src/families/ordered_beta.jl` | `OrderedBeta() = OrderedBeta(-1.0, 1.0, 10.0)`; docstring restates C1 / C1-cuts |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::OrderedBeta)` → `fit_ordered_beta_gllvm`; docstring + availability string |
| `test/test_ordered_beta.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter, 1e-8; `OrderedBeta(0, 2, 3)` tag-inert on `c0`, `c1`, **and** `φ`) |
| `docs/src/response-families.md` | table row + unified-entry paragraph + example |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `docs/src/gllvmtmb-parity.md` | Julia-forward note |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell unchanged) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl` and `src/bridge.jl` were **not** opened.
`src/families/tweedie.jl` was **not** opened. No twin light Δ.

## Verification

Mac-LIGHT focused tests (local):

```
julia --project=. --startup-file=no test/test_ordered_beta.jl
Test Summary:       | Pass  Total   Time
Ordered-beta family |   36     36  11.5s
```

Full suite = GitHub CI on the PR.

## Rose fence

Status cell `ordered_beta / beta_hurdle` stays `implemented` (engine + test
already existed). No R-parity, ADEMP, or coverage claimed. +X / `disp_group` /
row effects / bridge remain OWED. Twin has no ordered-beta family — a light Δ
would be invented. `"ordered"` on the bridge already means ordinal.

Rose verdict: PASS WITH NOTES — surface admit only; Tweedie `fit_gllvm` stay
STOP (T2–T5 unpaid).

## Next

Tweedie stays STOP. Overnight handoff at
`docs/dev-log/handover/2026-08-17-overnight-surface-handoff.md`.
