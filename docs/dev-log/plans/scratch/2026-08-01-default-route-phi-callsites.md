# S0 — call-site inventory: `fit_gllvm` NB/Beta defaults

Lane: `default-route-phi-20260801`. Tip at inventory: `185b3db7`.
API B: plain `fit_gllvm(NB/Beta)` will coerce `disp_group=nothing` → `:species`
→ `NBGroupedFit` / `BetaGroupedFit`. Named `fit_nb_gllvm` / `fit_beta_gllvm`
remain shared-φ.

## Engine (S1)

| File | Current | Action |
| --- | --- | --- |
| `src/families/fit_gllvm.jl` | NB/Beta default → `fit_nb_gllvm` / `fit_beta_gllvm` | Coerce `nothing`→`:species` before grouped routing; update docstring (NB/Beta default = per-trait; shared via named fitters) |

Do **not** change Gamma. Do **not** touch Hessian defaults on grouped fitters.

## Parity (S2)

| File | Current | Action |
| --- | --- | --- |
| `test/parity/test_negbin_parity.jl` | `fit_nb_gllvm_grouped(...; group=1:p)` | Retarget to plain `fit_gllvm(...; family=NegativeBinomial())`; expect `NBGroupedFit` |
| `test/parity/test_beta_parity.jl` | `fit_beta_gllvm_grouped(...; group=1:p)` | Retarget to plain `fit_gllvm(...; family=Beta())`; expect `BetaGroupedFit` |
| `test/parity/README.md` | Says use grouped / not shared default | Update: default `fit_gllvm` **is** the per-trait route; shared via named fitters |

## Core tests asserting `NBFit`/`BetaFit` from plain `fit_gllvm` (S3)

| File | Lines / note | Action |
| --- | --- | --- |
| `test/test_fit_gllvm.jl` | `@test ... isa NBFit` / `BetaFit` | → `NBGroupedFit` / `BetaGroupedFit` |
| `test/test_nb_fit.jl` | `"dispatches to NBFit"` via `fit_gllvm` | → `NBGroupedFit`; keep `fit_nb_gllvm` recovery on `NBFit` |
| `test/test_beta_fit.jl` | `"dispatches to BetaFit"` via `fit_gllvm` | → `BetaGroupedFit`; keep `fit_beta_gllvm` recovery on `BetaFit` |
| `test/test_postfit.jl` | NB + Beta blocks use `fit_gllvm` then scalar `fit.r` / `fit.φ` + `NBFit`/`BetaFit` postfit methods | **Retarget to `fit_nb_gllvm` / `fit_beta_gllvm`** — grouped types have `getLV`/`_nparams` but not the shared `predict`/`residuals` methods used here |
| `test/test_unified_api.jl` | Already exercises `disp_group=:species` / vector; combination throws | Smoke that plain NB/Beta → grouped; leave Gamma alone |

## Docs wording “shared default” (S3)

| File | Issue | Action |
| --- | --- | --- |
| `docs/src/response-families.md` | NB/Beta sections say shared `fit.r` / `fit.φ`; grouped section presents per-species as opt-in | State public `fit_gllvm` default = per-trait; named fitters = shared; keep `disp_group` for custom groups |
| `docs/src/tutorial.md` | “By default each dispersion family carries **one shared** dispersion” | Narrow: NB/Beta public default is per-species; shared via named fitters; Gamma unchanged |
| `docs/src/model.md` | Mentions named fitters for X_lv | Leave X_lv fence; only honesty tweak if it claims shared as public default |

## Out of scope / leave alone

- `fit_nb_gllvm` / `fit_beta_gllvm` recovery tests and X_lv bridge cells
- Gamma default / `fit_gamma_gllvm`
- Root `LOOP/` catch-up files; attach scratch
- #129/#128, ADEMP, coverage, ordinal-logit, Phylo Model A
- Postfit expansion for `NBGroupedFit`/`BetaGroupedFit` predict/residuals (not this lane)

## Verify after cascade

- Type expects: plain `fit_gllvm` → grouped; named → shared
- Live `GLLVM_PARITY_TESTS=1` NB2/Beta on default path (Δ bands NB2 ~1e-4, Beta ~1e-8)
