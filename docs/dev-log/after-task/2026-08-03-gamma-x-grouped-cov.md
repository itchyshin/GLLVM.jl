# After-task: Gamma+X engine Arc 1 (`fit_gamma_gllvm_grouped_cov`)

**Date:** 2026-08-03  
**Lane:** `fix/gamma-x-grouped-cov-20260803`  
**Worktree:** `.worktrees/gllvmjl-gamma-x-grouped-cov-20260803`  
**Base:** `origin/main` @ `0e241215` (+ cherry-picked identity `82cdd5e5`/`2e865b82`)  
**Decision:** `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`

## Goal

Twin API B under X for Gamma: stop routing public/bridge Gamma+X through
shared-α `fit_gllvm_cov`. Ship per-trait shape α + shared site-X fitter, route
bridge/formula, and lock Julia-only identity tests. Arc 2 RCall cells deferred.
#177 left alone.

## What shipped

1. `fit_gamma_gllvm_grouped_cov` + `GammaGroupedCovFit` in
   `src/families/grouped_dispersion.jl` (FD LBFGS; `O = Xγ` into grouped Laplace)
2. Export in `src/GLLVM.jl`; Wald/profile/bootstrap CI adapter in
   `src/confint_family.jl`
3. Bridge `_bridge_fit_onepart_cov` routes `gamma` to grouped_cov; assemble Union
   includes `GammaGroupedCovFit`
4. `@formula` Gamma+X dispatch to grouped_cov; other families unchanged
5. Identity tests `test/test_gamma_x_identity.jl`; bridge_x oracles updated
6. Docs cascade: response-families, gllvmtmb-parity, capability-status fence,
   surgical check-log append, coordination board, AGENTS phase snapshot

## Verification

| Check | Result |
|---|---|
| `test/test_gamma_x_identity.jl` | **7/7 pass** |
| `test/test_bridge_x.jl` | **204/204 pass** |
| `test/test_formula.jl` | **11/11 pass** |
| Formula Gamma route smoke | → `GammaGroupedCovFit` |
| Tolerance widen | **none** |

## Rose verdict

**OK** to claim: public/bridge Gamma+X use per-trait shape α + shared γ; Julia
identity vs shared `fit_gllvm_cov` under G=1 holds in the #172/#175 band.

**Not OK:** light RCall Gamma+X parity (Arc 2); full family parity; no-X Option B
flip; ADEMP/coverage; Ordinal+X; merging #177.

## Remaining OWED

- Push / PR when Shinichi asks (local-only until then).
- Separate `/goal`: Gamma+X light RCall Arc 2 (rtol `1e-6`).
- Parallel: land #177 (NB2/Beta Arc 2) when MERGEABLE — not this lane.
- Optional later: analytic Gamma gradient under X; harden shared
  `fit_gllvm_cov` Gamma against DomainError when FD explores α→0
  (pre-existing; identity fixture uses a stable seed).

## Next

`START A FRESH TASK` for Gamma+X light RCall Arc 2 after this PR is on `main`
(or when Shinichi opens that `/goal`).
