# After-task — lognormal + truncated-Poisson bridge logLik receipt wiring

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (true-parity follow-up to #353 inventory ranks 1–2)  
**Branch:** `feat/lognormal-truncpois-loglik-receipts-20260915` from `origin/main` @ `d05cb15c8`  
**Worktree:** `/Users/z3437171/local-scratch/gllvmjl-feat-lognormal-truncpois-loglik-receipts-20260915`

## Rose fence

- **≠ full family parity ≠ capability row promotion ≠ ledger JSON mutation.**
- Bridge notes now **cite** the existing parity cells; default `runtests.jl` unchanged.
- Measured Δ below is **re-run evidence** on this machine (2026-09-15), matching the 2026-08-24 receipt.

## Live Δ (GLLVM_PARITY_TESTS=1)

Command:

```sh
cd "$WT" && GLLVM_PARITY_TESTS=1 julia --project=test/parity -e '
using Test, GLLVM, RCall, Random, LinearAlgebra
include("test/parity/parity_helpers.jl")
@testset "slice" begin
  include("test/parity/test_lognormal_parity.jl")
  include("test/parity/test_truncated_poisson_parity.jl")
end
'
```

| Cell | Julia logLik | R logLik | abs Δ | Pass |
|------|-------------|----------|-------|------|
| lognormal (seed=52, p=5, K=2, n=60; fid 3) | −594.6707717158076 | −594.6707717381979 | **2.239e-8** | 23/23 (both files) |
| truncated_poisson (seed=53, p=5, K=2, n=60; fid 10) | −618.0776776554326 | −618.0776776581457 | **2.713e-9** | (same run) |

## OWED status after

| Surface | Before | After |
|---------|--------|-------|
| `src/bridge.jl` capability + fit notes | “light RCall Δ still OWED” | Points at parity test + receipt abs Δ |
| `test/test_bridge_*` + `test_bridge_capabilities.jl` | Asserted OWED wording | Assert PAID + parity path; `!occursin("still OWED")` |
| `twin-bridge-headline-inventory-20260915.tsv` | `live_delta_fenced_bridge` | `live_delta` + wiring date |

**Still OWED (unchanged scope):** CI / X / X_lv / masks on these families; SE-Wald on `LognormalFit` / `TruncatedPoissonFit`; full family parity claim.

## Checks

- Focused bridge tests (see PR).
- Full `Pkg.test()` — CI on PR.

## Follow-up

- Inventory top-8 ranks 3–8 unchanged (Student-t symmetric rtol, ZI cells, ordinal Wald, delta φ alignment).
