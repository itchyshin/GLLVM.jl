# Julia recon — ordinal routes + bridge X gap (S1)

**Date:** 2026-08-03  
**Repo tip:** `docs/ordinal-x-identity-20260803` @ `0e241215` (`origin/main`)

## Public no-X default

| Surface | Route | Evidence |
|---|---|---|
| `fit_gllvm(...; family=Ordinal())` | → `fit_ordinal_gllvm_pertrait` | `src/families/fit_gllvm.jl:17`, `:144` |
| Bridge `ordinal` / `ordinal_probit` | → `fit_ordinal_gllvm_pertrait` | `src/bridge.jl:1054–1058` |
| Shared-cutpoint comparator | `fit_ordinal_gllvm` → `OrdinalFit` | `src/families/ordinal.jl:402–416`, `:246–267` |

Docstring: per-trait is the **native gllvmTMB ordinal bridge target**; shared
kept for experiments (`src/families/ordinal.jl:549–554`).

## Cutpoint packing map

### Per-trait (twin target)

`_unpack_cutpoints_pertrait` (`src/families/ordinal.jl:308–324`):

- Sets `τ[t, 1] = 0.0` (τ₁ fixed).
- Free params = log-spacings for indices `2..(C[t]-1)` → **C−2 = K−2 free**.
- Init `_pack_initial_ordinal_pertrait` absorbs first threshold into
  intercept `β0[t] = -τ0[1]` and packs only spacings for `c in 2:(C-1)`
  (`:327–351`).

**Matches twin** τ₁=0 + K−2 log-spacings per trait.

### Shared (Julia comparator only)

`_unpack_cutpoints` (`src/families/ordinal.jl:298–306`): free base `ψ[1]`
then exp-increments → **C−1 free** cutpoints. **Not** the twin fid-14
convention (cf. twin missing-predictor K−1 path, not RESPONSE ordinal).

## Bridge “no covariate kernel”

- `_BRIDGE_X_FAMILIES` = poisson, binomial, negbinomial, beta, gamma —
  **Ordinal and NB1 absent** (`src/bridge.jl:171–173`, `:183–184` comment
  “no covariate kernel yet”).
- Passing `X` with `family` ordinal/nb1 throws loud
  (`src/bridge.jl:393–405`).
- `fit_gllvm_cov` has no `Ordinal` dispersion/kernel markers
  (`src/families/covariates.jl:103–108` — no Ordinal method; Ordinal not in
  cov family set).

## X_lv note (orthogonal fence)

Shared-cutpoint `fit_ordinal_gllvm(...; X_lv=...)` exists for
predictor-informed LVs (`src/families/ordinal.jl:402+`). That is **not**
shared site-X `γ` / `fit_*_cov`. Phylo-ordinal structural LV decisions
(2026-07-02) remain orthogonal.

## Gap named for Arc 1

Engine need after ACCEPTED identity: a covariate path that keeps
**per-trait cutpoints** (τ₁=0 / K−2 packing) + **shared site-X γ**, and
routes bridge/`@formula`+X for ordinal through it. No such fitter on this
tip.
