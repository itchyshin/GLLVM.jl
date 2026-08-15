# After-task — overnight ADMIT (lognormal + censored_poisson)

**Date:** 2026-08-16 (overnight; Shinichi AFK)  
**Lane:** `cursor/family-admit-overnight-20260815`  
**Worktree:** `.worktrees/gllvmjl-admit-conductor-20260815`  
**PR:** https://github.com/itchyshin/GLLVM.jl/pull/215

## Goal

Wire non-OWED ADMIT choke points after engine PRs landed on `main`.

## Merged engines (Phase A)

| PR | Merge SHA | Notes |
|---|---|---|
| #213 lognormal | `7954cdb77cc5` | Opus CLEAR held |
| #208 ZIB Identity | `32eb3dc769d4` | docs |
| #212 censored_poisson | `ffa92aeaf7e4` | Opus CLEAR `3480854a` |
| #211 ZIB+X engine | pending CI on `main` | retargeted after #208 |

## Wired (this slice)

- `src/GLLVM.jl`: includes + exports for `Lognormal` / `CensoredPoisson`
- `src/families/fit_gllvm.jl`: `_fit_gllvm` arms + availability list
- `test/runtests.jl`: `test_lognormal.jl`, `test_censored_poisson.jl`
- `docs/design/capability-status.md`: both → `implemented` + fence notes

## Explicitly not wired

- Twin light Δ / `bridge.jl` (OWED)
- ZIB `fit_gllvm` / `@formula` / bridge (OWED per ZIB+X ADMIT)
- ZIBCovFit export + `test_zib_x_identity.jl` — wait for #211

## Verification

```
lognormal family (one-part, twin fid 3) | 16 / 16
censored_poisson family (Julia-forward) | 46 / 46
```

## Rose

Ledger notes fence twin-Δ; README marketing claim not expanded.

## Next

1. Merge #211 when green → add non-OWED ZIB ADMIT (`fit_zib_gllvm_cov`/`ZIBCovFit` export, `runtests`, optional postfit).
2. Merge #215 on full Julia+Documenter green.
3. Morning: full `Pkg.test()` if overnight CI incomplete; close or supersede conflicting #214.
