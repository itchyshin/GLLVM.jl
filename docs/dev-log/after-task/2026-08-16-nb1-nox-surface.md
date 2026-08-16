# After-task — NB1 no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-16
**Lane:** `cursor/nb1-nox-engine-20260816`
**Worktree:** `.worktrees/gllvmjl-nb1-nox-engine-20260816`
**Base:** `origin/main` @ `ef96463b` (merge of #226, the Identity)
**Identity:** `docs/dev-log/decisions/2026-08-16-nb1-betabinom-fit-gllvm-identity.md`

## Goal

Make `NB1` reachable through the unified `fit_gllvm` entry point — and hence
through `@formula` with no covariates — with the **per-trait φ** estimand already
shipped on the R bridge and on `@formula` + X. NB1 only; BetaBinom is a separate
asymmetric arc.

## Change set

| File | Change |
|---|---|
| `src/families/negbin1.jl` | docstring for the `NB1` marker; `NB1() = NB1(1.0)` (Identity C1b) |
| `src/GLLVM.jl` | export `NB1` (conductor choke point; one-word insertion) |
| `src/families/fit_gllvm.jl` | API-B coerce extended to `NB1`; `NB1` added to the availability string; docstring family list, `disp_group` list, example; comment fencing the absent bare arm |
| `src/formula.jl` | docstring only — records the no-X `NB1()` fall-through |
| `test/test_grouped_dispersion_tweedie_nb1.jl` | new focused `NB1 no-X public surfaces` testset |
| `docs/src/response-families.md` | `NB1()` table row, new family section, per-species-dispersion prose + examples |
| `docs/src/tutorial.md` | marker route + per-species default |
| `README.md` | per-species default now names NB1 with `family = NB1()` |
| `docs/design/capability-status.md` | evidence pointer only (no status or parity change) |
| `docs/dev-log/check-log.md` | entry |

## Identity locks honoured

- **C1** — the marker's `φ` is a tag payload: not forwarded, not `φ_init`.
  `fit_gllvm(Y; family = NB1(7.5))` matches `NB1()` to 1e-8 in the test.
- **C2** — per-trait via the existing API-B coerce. **No** `_fit_gllvm(::NB1, …)`
  arm: the grouped arm already existed, so a bare arm would be unreachable and
  would advertise the shared-φ estimand. Shared φ remains `fit_nb1_gllvm` only.
- **C4** — export + rule-3 cascade in the same PR.
- **Formula** — opens by fall-through (`formula.jl` q == 0), tested in the same PR;
  no #218 → #220 style split is available.

## Explicitly not done

- `src/bridge.jl` **not opened** — nothing is owed there (`"nb1"` already on every
  relevant list). No bridge behaviour changed ⇒ **no** new R-parity or twin Δ claim.
- `BetaBinom`: separate arc (needs `_fit_gllvm_grouped(::BetaBinom)` **and** the
  required p×n trials `N` boundary guard from Identity C3 — φ is unidentifiable at
  `N = 1`).
- `TweedieED` marker export; scalar-`N` convenience; any change to the named
  fitters' `N = ones` default; ADEMP / coverage.

## Verification

Mac-LIGHT: no local `Pkg.test()` — GitHub CI is the verifier.

```
julia --project=. test/test_grouped_dispersion_tweedie_nb1.jl
Grouped / species-specific NB1 & Tweedie dispersion (disp.group) | 25 / 25  (33.3 s)
```

Direct surface smoke (p=3, n=25, K=1, 15 iterations):

```
NB1 exported: true                    NB1() = NB1(1.0)
fit_gllvm(family = NB1())          -> NB1GroupedFit, group=[1,2,3], 3 φ, ll=-105.034168
fit_gllvm(family = NB1(7.5))       -> same loglik (marker φ ignored)
gllvm(@formula(y ~ 1), …)          -> NB1GroupedFit, same loglik
fit_nb1_gllvm_grouped(group = 1:p) -> same loglik
fit_nb1_gllvm                      -> NB1Fit, shared φ = 0.4725 (distinct route)
row_eff = :random                  -> ArgumentError (was a raw MethodError)
```

## Rose fence

**Claimable:** NB1 is reachable through `fit_gllvm` and through `@formula` with no
X, with per-trait φ, matching the estimand already shipped on the bridge and on
`@formula` + X.

**Not claimable:** any new R-parity / twin Δ; any coverage or ADEMP result; any
change in bridge behaviour; shared-φ availability through `fit_gllvm`; that
`BetaBinom` or `TweedieED` is admitted.

## Next

1. BetaBinom no-X arc (its own G0; C3 trials guard is the load-bearing part).
2. `TweedieED` marker export/admit — same class, own G0.
