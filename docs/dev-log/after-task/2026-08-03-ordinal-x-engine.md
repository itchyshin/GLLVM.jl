# After-task: Ordinal+X engine Arc 1 (`fit_ordinal_gllvm_pertrait_cov`)

**Date:** 2026-08-03  
**Lane:** `fix/ordinal-x-pertrait-cov-20260803`  
**Worktree:** `.worktrees/gllvmjl-ordinal-x-engine-20260803`  
**Base:** `origin/main` @ `0630f8e4` (#179 identity ACCEPTED)  
**Decision:** `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md`

## Goal

Twin API B under X for Ordinal: ship per-trait cutpoints (τ₁=0 / K−2
log-spacings) + shared site-X γ, route bridge/`@formula`, and lock Julia-only
identity + FD checks. Arc 2 RCall cells deferred. No ADEMP. No Dropbox write.

## What shipped

1. Offset-aware per-trait ordinal Laplace (`η = β + offset + Λz`) in
   `src/families/ordinal.jl`
2. `fit_ordinal_gllvm_pertrait_cov` + `OrdinalPerTraitCovFit` (FD LBFGS;
   `O = Xγ`); export in `src/GLLVM.jl`; `getLV` / `_nparams` in `src/postfit.jl`
3. Bridge: `_BRIDGE_X_FAMILIES` admits `ordinal` / `ordinal_probit`;
   `_bridge_fit_onepart_cov` → pertrait_cov; `_bridge_assemble_ordinal_cov`;
   CI under X still guarded (follow-up)
4. `@formula` Ordinal+X → `fit_ordinal_gllvm_pertrait_cov`
5. Identity tests `test/test_ordinal_x_identity.jl`; bridge_x / capabilities
   oracles updated
6. Docs cascade: response-families, gllvmtmb-parity, capability-status fence,
   check-log, coordination board, AGENTS phase snapshot, LOOP scaffold

## Verification

| Check | Result |
|---|---|
| `test/test_ordinal_x_identity.jl` | **21/21 pass** |
| `test/test_bridge_capabilities.jl` | **107/107 pass** |
| `test/test_bridge_x.jl` | **212/212 pass** |
| `test/test_ordinal_pertrait.jl` | **98 + 15 pass** |
| `test/test_ordinal_fit.jl` | **10/10 pass** |
| `test/test_formula.jl` | **11/11 pass** |
| Tolerance widen | **none** |

## Rose verdict

**OK** to claim: public/bridge/`@formula` Ordinal+X use per-trait cutpoints
(τ₁=0, K−2) + shared γ; Julia identity (zero/constant offset; zero-X ≈ no-X)
and FD self-check ≤ 1e-6 hold.

**Not OK:** light RCall Ordinal+X parity (Arc 2); full family parity;
ADEMP/coverage; shared-cutpoint as public X default; Ordinal+X CI payloads.

## Remaining OWED

- Push / PR when Shinichi asks (local-only until then).
- Separate `/goal`: Ordinal+X light RCall Arc 2 (rtol `1e-6`, matching link).

## Next

`START A FRESH TASK` for Ordinal+X light RCall Arc 2 after this tip lands on
`main` (or when Shinichi opens that `/goal`).
