# After-task — Hurdle-Poisson no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-16
**Lane:** `cursor/hurdle-poisson-nox-20260816`
**Worktree:** `.worktrees/gllvmjl-hurdle-poisson-nox-20260816`
**Base:** `origin/main` @ `497be1c4` (merge of #235, ZIP no-X bridge fix)
**Gate:** parallel to Tweedie engine health (#236); `src/families/tweedie.jl` not opened

## Goal

Make `HurdlePoisson` reachable through the unified `fit_gllvm` entry point — and
hence through `@formula` with no covariates — as the cheapest remaining
`_fit_gllvm` surface admit. No new engine, no new estimand, no bridge.

## Why this was the cheapest admit left

Read off `origin/main` @ `497be1c4` plus the 2026-08-16 gap sheet
(`docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md`), excluding Tweedie
and AGHQ/CV:

| Candidate | Why not cheaper |
|---|---|
| Exponential | already has a `_fit_gllvm` arm |
| ZIB / Student-t / Delta / NB1 / BetaBinom | already admitted today |
| Tweedie | reserved (Identity #234; engine health #236); out of lane |
| COM-Poisson | marker already exported, but `ν` is **estimated** by `fit_compoisson_gllvm` while the marker carries `ν` — needs an Identity (structural vs tag-payload) before an arm |
| Hurdle-NB / BetaHurdle / OrderedBeta | same payload-vs-estimated Identity (`r` / `φ` / cutpoints) |
| **HurdlePoisson** | empty marker, working named fitter, tests already in `runtests.jl`, marker **not** exported, no `_fit_gllvm` arm. ZIB #218-class. |

No Identity decision was required: `struct HurdlePoisson end` has no field.

## Change set

| File | Change |
|---|---|
| `src/GLLVM.jl` | export `HurdlePoisson` |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::HurdlePoisson)` → `fit_hurdle_poisson_gllvm`; docstring + availability string |
| `test/test_hurdle_poisson.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter, 1e-8) |
| `docs/src/response-families.md` | table row + unified-entry paragraph + example |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell unchanged) |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl` and `src/bridge.jl` were **not** opened. `src/families/tweedie.jl`
was **not** opened. No twin light Δ.

## Verification

Mac-LIGHT focused tests (local):

```
julia --project=. test/test_hurdle_poisson.jl
Test Summary:  | Pass  Total   Time
Hurdle-Poisson |  171    171  13.2s
```

Full suite = GitHub CI on the PR.

## Rose fence

Status cell `hurdle_poisson / hurdle_nbinom2` stays `implemented` (engine + test
already existed). No R-parity, ADEMP, or coverage claimed. +X / `disp_group` /
row effects / bridge / Hurdle-NB remain OWED. Twin has no hurdle family — a
light Δ would be invented.

Rose verdict: PASS WITH NOTES — surface admit only; remaining hurdle / COM-Poisson
/ ordered-beta admits still need their own Identity-or-arm slices.

## Next

Hurdle-NB or COM-Poisson Identity (ν / r estimated vs marker field), not this
lane. Tweedie stays with #236.
