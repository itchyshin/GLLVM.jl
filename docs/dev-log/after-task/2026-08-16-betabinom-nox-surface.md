# After-task — BetaBinom no-X `fit_gllvm` + `@formula` surface admit

**Date:** 2026-08-16
**Lane:** `cursor/betabinom-nox-engine-20260816`
**Worktree:** `.worktrees/gllvmjl-betabinom-nox-20260816`
**Base:** `origin/main` @ `a9ce2667` (merge of #227, the NB1 half)
**Identity:** `docs/dev-log/decisions/2026-08-16-nb1-betabinom-fit-gllvm-identity.md` (#226)

## Goal

Make `BetaBinom` reachable through the unified `fit_gllvm` entry point — and hence
through `@formula` with no covariates — with the **per-trait φ** estimand already
shipped on the R bridge and on `@formula` + X, and with the p×n trial counts `N`
**required** at that boundary. BetaBinom only; the NB1 half shipped in #227.

## Why this arc is bigger than #227 despite sharing one Identity

The Identity warned against assuming symmetry, and the change sets bear that out:

| | NB1 (#227) | BetaBinom (here) |
|---|---|---|
| API-B coerce | one name added | one name added |
| `_fit_gllvm_grouped` arm | **already existed** | **added** |
| Boundary data guard | none owed | **required `N`, C3 — the load-bearing part** |

## Change set

| File | Change |
|---|---|
| `src/families/beta_binomial.jl` | `BetaBinom` marker docstring (routes, inert `φ`, required `N`, the `Distributions.BetaBinomial` naming note); `BetaBinom() = BetaBinom(1.0)` (C1b) |
| `src/GLLVM.jl` | export `BetaBinom` (conductor choke point; one-word insertion on the existing beta-binomial export line) |
| `src/families/fit_gllvm.jl` | API-B coerce extended to `BetaBinom`; new `_fit_gllvm_grouped(::BetaBinom, …)` carrying the required-`N` guard; both availability strings; docstring family list, `disp_group` list, example; the absent-bare-arm comment extended to cover BetaBinom |
| `src/formula.jl` | docstring only — records the no-X `BetaBinom()` fall-through and that it inherits the `N` requirement |
| `test/test_betabinomial_x_identity.jl` | new focused `BetaBinom no-X public surfaces` testset |
| `docs/src/response-families.md` | `BetaBinom()` table row; the family section retitled from the driver to the marker, with the per-species default, the required `N`, and the naming note; per-species-dispersion prose + examples |
| `docs/src/tutorial.md` | marker route beside the shared-φ driver; per-species default; required `N` |
| `README.md` | per-species default now names beta-binomial with `family = BetaBinom()` |
| `docs/design/capability-status.md` | evidence pointer only (no status or parity change) |
| `docs/dev-log/check-log.md` | entry |

## Identity locks honoured

- **C1** — the marker's `φ` is a tag payload: not forwarded, not `φ_init`.
  `fit_gllvm(Y; family = BetaBinom(7.5), N)` matches `BetaBinom()` exactly.
- **C2** — per-trait via the existing API-B coerce, plus the **new** grouped arm.
  **No** `_fit_gllvm(::BetaBinom, …)` arm: with the coerce it would be unreachable
  and would advertise the shared-φ estimand. Shared φ remains
  `fit_beta_binomial_gllvm` only.
- **C3** — `N` is a plain keyword, **required** at the entry point, no marker
  payload, and a scalar is rejected rather than normalised. The named fitters'
  `N = ones` default is untouched.
- **C4** — export + rule-3 cascade in the same PR, including the naming note.
- **Formula** — opens by fall-through (`formula.jl` `q == 0`), tested here; no
  #218 → #220 style split was available.

## Verification

Mac-LIGHT: no local `Pkg.test()` — GitHub CI is the verifier.

```
julia --project=. test/test_betabinomial_x_identity.jl
Test Summary:                             | Pass  Total   Time
BetaBinomial + X identity (API B under X) |   26     26  10.8s
```

26 = the 12 pre-existing X-identity tests + 14 new no-X surface tests.

Direct surface smoke (p=3, n=25, K=1, 15 iterations, `N` a genuine p×n matrix
with entries 5–8):

```
BetaBinom exported: true              BetaBinom() = BetaBinom(1.0)
fit_gllvm(family = BetaBinom(), N)      -> BetaBinomialGroupedFit, group=[1,2,3], 3 φ, ll=-132.740046
fit_gllvm(family = BetaBinom(7.5), N)   -> Δll = 0.0            (marker φ ignored)
fit_beta_binomial_gllvm_grouped(1:p)    -> Δll = 0.0            (same engine)
gllvm(@formula(y ~ 1), …, N)            -> BetaBinomialGroupedFit, Δll = 0.0
missing N                               -> ArgumentError naming `N` and the N=1 reason
scalar N = 8                            -> ArgumentError (not broadcast)
@formula, missing N                     -> ArgumentError (inherited)
row_eff = :random                       -> ArgumentError (was a raw MethodError)
fit_beta_binomial_gllvm                 -> BetaBinomialFit, shared φ = 36.08 (distinct route)
```

`row_eff = :random` is the coerce side-effect the Identity predicted: it replaces an
unhandled `MethodError` with the family's clear `ArgumentError`, closing no working
route.

## Explicitly not done

- `src/bridge.jl` **not opened** — nothing is owed there (`"betabinomial"` already on
  every relevant list, including `_BRIDGE_TRIALS_FAMILIES`). No bridge behaviour
  changed ⇒ **no** new R-parity or twin Δ claim, and no coverage/ADEMP claim.
- No scalar-`N` convenience; no change to the named fitters' `N = ones` default.
- `TweedieED` marker export/admit — the last unexported marker holding a grouped
  arm; same class, own G0.

## Rose fence

**Claimable:** BetaBinom is reachable through `fit_gllvm` and through `@formula` with
no X, with per-trait φ, matching the estimand already shipped on the bridge and on
`@formula` + X, and requiring an explicit p×n trials matrix `N`.

**Not claimable:** any new R-parity / twin Δ; any coverage or ADEMP result; any
change in bridge behaviour; shared-φ availability through `fit_gllvm`; that a scalar
`N` is accepted; that `TweedieED` is admitted.

## Next

1. `TweedieED` marker export/admit — closes the unexported-marker class opened by
   this Identity's out-of-scope note.
2. Scalar-`N` convenience inside `src/families/beta_binomial.jl`, applied to all four
   BB fitters at once, if wanted (fenced by the Identity as a follow-up).
