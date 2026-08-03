# After-task: Gamma+X light RCall Arc 2

**Date:** 2026-08-03  
**Lane:** `parity/gamma-x-arc2-20260803`  
**Worktree:** `.worktrees/gllvmjl-gamma-x-arc2-20260803`  
**Base:** `fix/gamma-x-grouped-cov-20260803` @ `ca2b2c0b`  
**Decision:** `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`

## Goal

Prove Julia per-trait Gamma shape α + shared site-X γ matches live gllvmTMB
ordinary Gamma (`stats::Gamma(link="log")` / `log_phi_gamma`) at rtol `1e-6`.
No Ordinal+X; no #177 merge; no full-family-parity claim.

## What shipped

1. **OH unblocker (surgical engine):** grouped Gamma Laplace gained
   `hessian=:observed` (default), `W = α y / μ` under log link — mirror of
   NB2/Beta #175. Fisher-only was systematically Δ≈0.2–1 vs TMB. Identity G=1
   vs `fit_gllvm_cov` forces `hessian=:fisher`.
2. `fit_gllvmtmb_parity_loglik_x` accepts `:gamma`.
3. Gamma+X `@testset` in `test/parity/test_x_covariate_parity.jl`
   (`fit_gamma_gllvm_grouped_cov`, `group=collect(1:p)`, default observed).
4. Docs: README fence, capability-status, surgical check-log/board, LOOP.

## Verification

| Check | Result |
|---|---|
| Gamma+X light logLik (seed=46, p=5, K=1, n=120) | **Δ ≈ 3.03e-8** (rtol 1e-6) |
| Shared site-X suite (incl. Gamma cell) | **pass** |
| `test/test_gamma_x_identity.jl` | **7/7** |
| `test/test_bridge_x.jl` | **204/204** |
| Tolerance widen | **none** |

## Rose verdict

**OK** to claim: “Gamma+X light logLik under **per-trait** α + shared γ, twin
to gllvmTMB ordinary Gamma / `log_phi_gamma` (observed Laplace).”

**Not OK:** full family parity; NB2/Beta+X on this tip (#177); Ordinal+X;
ADEMP/coverage; Option B no-X flip; Phylo Model A.

## Remaining OWED

- Push / PR when Shinichi asks (local-only until then).
- Parallel: land #177 (NB2/Beta Arc 2) — untouched here.

## Next

`START A FRESH TASK` for push/PR or #177 landing — do not redo Arc 2 cells.
