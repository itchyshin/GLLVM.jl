# After-task — Delta-lognormal / Delta-Gamma no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-16
**Lane:** `cursor/delta-nox-surface-20260816`
**Worktree:** `.worktrees/gllvmjl-delta-nox-20260816`
**Base:** `origin/main` @ `63cdf892` (merge of #232, Student-t no-X admit)
**Gate:** tip CI for `63cdf892` confirmed before merge of this PR

## Goal

Make `DeltaLogNormal` and `DeltaGamma` reachable through the unified `fit_gllvm`
entry point — and hence through `@formula` with no covariates — as the cheapest
remaining two-part surface admit. No new engine, no new estimand, no bridge.

## Why this was the cheapest admit left

Both Delta families already had complete two-part Laplace engines, named fitters
(`fit_delta_lognormal_gllvm` / `fit_delta_gamma_gllvm`), fit result types, and
passing recovery tests. The gap was the public marker export + `_fit_gllvm` arm
(and the zero-arg constructors so callers need not invent unused dispersion).

## Design: tag payloads, not structural fields

Unlike `StudentTFamily(ν)` / `ZIB(N)`, the Delta markers' `σ` and `α` are
**estimated** by the named fitters. They are therefore inert **tag payloads** —
same pattern as `NB1(φ)` / `BetaBinom(φ)` — never forwarded and never used as
starting values. `DeltaLogNormal()` / `DeltaGamma()` default the unused field so
the public call stays clean.

No Identity decision was required: the public default is the same shared-scalar
estimand the named fitters already ship (shared `σ` / shared `α`). There is no
competing per-species default on these engines.

## Change set

| File | Change |
|---|---|
| `src/families/twopart.jl` | marker docs; `DeltaLogNormal()` / `DeltaGamma()` constructors |
| `src/families/fit_gllvm.jl` | `_fit_gllvm` arms; docstring + availability string |
| `src/GLLVM.jl` | export `DeltaLogNormal`, `DeltaGamma` |
| `test/test_delta_fit.jl` | no-X `fit_gllvm` + `@formula` surface tests |
| `test/test_delta_gamma.jl` | same for Delta-Gamma |
| `docs/src/response-families.md` | table rows + family sections |
| `docs/src/tutorial.md` | unified-entry examples |
| `README.md` | surface mention |
| `docs/design/capability-status.md` | evidence pointer + OWED fence |
| `docs/dev-log/check-log.md` | entry |

`src/formula.jl` and `src/bridge.jl` were **not** opened. No twin light Δ.

## Verification

Mac-LIGHT focused tests (local):

```
julia --project=. test/test_delta_fit.jl
Test Summary:             | Pass  Total  Time
fit_delta_lognormal_gllvm |   13     13  7.0s

julia --project=. test/test_delta_gamma.jl
Test Summary:      | Pass  Total   Time
Delta-Gamma family |   39     39  25.2s
```

Full suite = GitHub CI on the PR.

## Rose fence

Status cells unchanged (`delta_*` already `implemented`). No R-parity, ADEMP, or
coverage claimed. +X / `disp_group` / row effects / bridge remain OWED.
