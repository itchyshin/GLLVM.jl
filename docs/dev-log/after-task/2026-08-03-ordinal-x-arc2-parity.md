# After-task: Ordinal+X light RCall Arc 2

**Date:** 2026-08-03  
**Lane:** `parity/ordinal-x-arc2-20260803`  
**Worktree:** `.worktrees/gllvmjl-ordinal-x-arc2-20260803`  
**Base:** `fix/ordinal-x-pertrait-cov-20260803` @ `e2b4afde` (tip exception
while PR #180 CI finishes; rebase onto post-#180 `main` before push/PR)  
**Decision:** `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md`  
**LOOP:** `lanes/ordinal-x-arc2-20260803/LOOP/`

## Goal

Prove Julia per-trait ordinal cutpoints (τ₁=0 / K−2) + shared site-X γ matches
live gllvmTMB `ordinal_probit` at rtol `1e-6` via
`fit_ordinal_gllvm_pertrait_cov` + `ProbitLink`. No engine redesign; no ADEMP;
no full-family-parity claim.

## What shipped

1. `fit_gllvmtmb_parity_loglik_x` accepts `:ordinal` →
   `gllvmTMB::ordinal_probit()`.
2. Ordinal+X `@testset` in `test/parity/test_x_covariate_parity.jl`.
3. Narrow docs: capability-status, `gllvmtmb-parity.md`, check-log, board,
   LOOP kit.

## Verification

| Check | Result |
|---|---|
| Ordinal+X light logLik (seed=47, p=5, K=1, n=80, C=3) | **Δ ≈ 5.38e-9** (rtol 1e-6) |
| Julia converged | **true** (`loglik ≈ -381.782050211`) |
| gllvmTMB converged | **true** (`logLik ≈ -381.782050217`) |
| Tolerance widen | **none** |
| `src/` engine redesign | **none** |

## Rose verdict

**OK** to claim: “Ordinal+X light logLik under **per-trait** cutpoints + shared
γ, twin to gllvmTMB `ordinal_probit`.”

**Not OK:** full family parity; ADEMP/coverage; Option B shared-cutpoint public
X; Phylo Model A; silent rtol widen.

## Remaining OWED

- Merge #180 when Julia CI green (engine Arc 1).
- Rebase this tip onto post-#180 `main`, then push/PR when Shinichi asks.
- No push from this lane until asked.

## Next

`START A FRESH TASK` for push/PR after #180 lands — do not redo the light cell.
