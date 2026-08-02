# After-task — A4/A5 NB2 / Beta / Ordinal logLik (honest blocked)

**Date:** 2026-08-01  
**Lane:** `catchup/loglik-oracle-20260801`  
**Worktree:** `.worktrees/gllvmjl-catchup-loglik-20260801`  
**Tip:** `b7c2cdb8`  
**Twin:** gllvmTMB `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`  
**Rose verdict:** **NOT-DONE** for family logLik claims — param progress only for #133.

## Goal

OPEN GATE A4/A5: align Julia→R public surface (#132/#148/#133), then land live
NB2 / Beta / Ordinal gllvmTMB logLik cells. Fan-out three parallel children.

## What landed

| Slice | Status | Evidence |
| --- | --- | --- |
| #133 Ordinal param | **Landed** (`b7c2cdb8`) | Per-trait β; τ₁=0; K−2 free cuts; default `fit_gllvm(Ordinal)` → pertrait; bridge df/`alpha`; focused tests 123 pass |
| Ordinal logLik oracle | **FAIL — not claimed** | Julia −29.814695 · R −27.560310 · Δ −2.254385; debug child pending |
| #132 NB2 parity entry | Draft grouped `1:p` / `disp_group=:species` (uncommitted) | Live Δ +0.21846 — FAIL |
| #148 Beta parity entry | Draft grouped `1:p` (uncommitted) | Live Δ +1.72816 — FAIL |

## ΔlogLik tables (live, not exit codes)

### Still green (A2/A3 — unchanged)

| Family | Julia | R | Δ (jl − r) | Result |
| --- | ---: | ---: | ---: | --- |
| Gaussian | −501.450700343274 | −501.45070035305673 | 9.78e-9 | GREEN |
| Binomial | −194.681986234064 | −194.68198623424576 | 1.82e-10 | GREEN |
| Poisson | −634.171284410425 | −634.1712844171735 | 6.75e-9 | GREEN |

### A4/A5 targets (blocked)

| Family | Julia | R | Δ (jl − r) | Result |
| --- | ---: | ---: | ---: | --- |
| NB2 (grouped per-trait) | −820.1965048660471 | −820.4149674231894 | +0.21846255714228846 | BLOCKED |
| Beta (grouped per-trait) | +135.68642413930405 | +133.9582599708042 | +1.728164168499859 | BLOCKED |
| Ordinal probit (after #133) | −29.814695 | −27.560310 | −2.254385 | BLOCKED |

## Root-cause notes (children)

- **NB2 / Beta:** φ / precision granularity via grouped routes is not the remaining
  gap. Both children report Fisher-weight Laplace determinant vs gllvmTMB
  observed/AD Hessian. NB observed-curvature probe shrank Δ (~0.22 → ~0.012) but
  was reverted pending a shared+grouped joint hook.
- **Ordinal:** parameterization wiring progressed; same-model logLik still open —
  debug follow-up `[Debug](5c7486d2-21e9-4e82-8950-48f10d998a2f)`.

## Not covered / fenced

- No green NB2 / Beta / Ordinal logLik claim
- #129 / #128 still fenced
- No ADEMP / coverage / Totoro-DRAC
- No push

## Next

1. Integrate ordinal debug receipt.
2. One Laplace observed-Hessian slice for NB2 (+ Beta mirror) on shared and
   grouped paths together.
3. Re-run three cells; only then promote claims + Melissa final reconcile.

## Rose claim fence

OK to say: #133 param alignment committed; three logLik oracles still red with
cited Δ. **Not OK** to say: NB2/Beta/Ordinal parity green, or catch-up DONE.
