# After-task — COM-Poisson no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-16
**Lane:** `cursor/compoisson-nox-20260816`
**Worktree:** `.worktrees/gllvmjl-compoisson-identity-20260816`
**Base:** Identity #239 on `origin/main` @ `d70a6a25` (merge of #237)
**Gate:** parallel to Tweedie grouped-health (#238); `src/families/tweedie.jl` not opened

## Goal

Make `COMPoisson` reachable through the unified `fit_gllvm` entry point — and
hence through `@formula` with no covariates — after the tag-payload Identity
lock. No new engine, no new estimand, no bridge.

## Why this was the cheapest remaining admit

Read off `origin/main` @ `d70a6a25` plus Identity
`docs/dev-log/decisions/2026-08-16-compoisson-fit-gllvm-identity.md`:

| Candidate | Why not cheaper |
|---|---|
| HurdlePoisson | already admitted (#237); empty marker |
| Tweedie | reserved (#234 / #238); out of lane |
| Hurdle-NB | unexported marker + same tag lock for `r` — more files |
| Ordered-beta | unexported; three estimated fields |
| **COM-Poisson** | marker already exported; one estimated `ν`; tests already in `runtests.jl`; twin has no CMP family |

Locks applied: C1 tag-payload `ν` (never read, never `ν_init`); C1b
`COMPoisson() = COMPoisson(1.0)`; C2 one `_fit_gllvm(::COMPoisson)` arm; C3 no
bridge / no twin Δ; C4 no +X / `disp_group` / `row_eff`.

## Change set

| File | Change |
|---|---|
| `src/families/com_poisson.jl` | `COMPoisson() = COMPoisson(1.0)`; docstring states `ν` is a tag payload |
| `src/families/fit_gllvm.jl` | `_fit_gllvm(::COMPoisson)` → `fit_compoisson_gllvm`; docstring + availability string |
| `test/test_com_poisson.jl` | no-X `fit_gllvm` + `@formula` smoke (loglik match vs named fitter, 1e-8; `COMPoisson(9.0)` tag-inert) |
| `docs/src/response-families.md` | table row + subsection + unified-entry paragraph |
| `docs/src/tutorial.md` | `fit_gllvm` route; no-X fence; Student-t `ν` contrast |
| `docs/src/gllvmtmb-parity.md` | Julia-forward row |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence (status cell unchanged) |
| `docs/dev-log/check-log.md` | entry |

`src/GLLVM.jl` was **not** opened (`COMPoisson` already exported).
`src/formula.jl` and `src/bridge.jl` were **not** opened.
`src/families/tweedie.jl` was **not** opened. No twin light Δ.

## Verification

Mac-LIGHT focused tests (local):

```
julia --project=. --startup-file=no test/test_com_poisson.jl
Test Summary:                 | Pass  Total  Time
Conway-Maxwell-Poisson family |   24     24  5.6s
```

Full suite = GitHub CI on the PR.

## Rose fence

Status cell `com_poisson` stays `implemented` (engine + test already existed).
No R-parity, ADEMP, or coverage claimed. +X / `disp_group` / row effects /
bridge remain OWED. Twin has no COM-Poisson family — a light Δ would be
invented.

Rose verdict: PASS WITH NOTES — surface admit only; Hurdle-NB / Ordered-beta
still need their own Identity-or-arm slices.

## Next

Hurdle-NB Identity (export + tag-payload `r`), not this lane. Tweedie stays
with #238.
