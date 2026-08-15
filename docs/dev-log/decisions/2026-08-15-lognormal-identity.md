# Decision: one-part lognormal Identity (twin-aligned; fid 3)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Wave1 / Arc 0 docs-only → engine on owned files)  
**Lane:** `cursor/lognormal-identity-20260815`  
**Programme:** `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`  
**Depends on:** G0 parallel catch-up (Ada 4-set); catch-up tip `b2b99463` / #205 observe-only.  
**Do not** invent ZIP/ZINB twin Δ; **do not** treat this as ADEMP/coverage; **do not**
re-open delta_lognormal.

## Problem

Ledger row `lognormal` is `planned` while twin gllvmTMB already admits one-part
lognormal (`family_id` 3) with a live cpp dens. Julia already ships
**delta_lognormal** (two-part hurdle) but has **no** one-part
`fit_lognormal_gllvm` / `LogNormalFit`. Without an Identity lock, a greenfield
engine risks mixing twin `sigma_eps` (shared with Gaussian) vs per-trait
delta σ, or claiming bridge parity before focused FD + light RCall.

## Twin cites (load-bearing)

| Surface | Evidence |
|---|---|
| Constructor | `gllvmTMB/R/families.R` `lognormal()` — links listed identity/log/inverse; **engine admits log only** (`fit-multi.R` aborts non-log) |
| Enum | `R/enum.R` / `family_to_id`: `lognormal = 3L` |
| TMB dens | `src/gllvmTMB.cpp` fid==3: `dnorm(log(y), η, σ_eps, true) - log(y)`; **y > 0 strictly** |
| Scale | Shared scalar `PARAMETER(log_sigma_eps)` — same residual SD as Gaussian when both present; mapped off when no fid ∈ {0,3} |
| Abort list | `fit-multi.R` supported-family message includes `lognormal()` |

Twin likelihood: η is the **mean of log(y)** on the log-link scale (`E[log y] = η`);
observation law is lognormal with SD `σ_eps` on the log scale; Jacobian `−log(y)`.

## Julia estimand (this Identity)

| Item | Lock |
|---|---|
| Support | `(0, ∞)` — reject `y ≤ 0` fail-loud |
| Linear predictor | `η = β + Λz` (+ optional offset / shared site-X later under a separate X Identity if needed); **log link only** for v1 |
| Mean-on-log | `E[log y] = η` (matches TMB `eta_o`) |
| Log-density | `log Normal(log y; η, σ) − log(y)` |
| Dispersion | **Shared scalar** `σ` packed as `log σ` (twin `sigma_eps` pattern for one-part lognormal — **not** per-trait `log_sigma_lognormal_delta` from fid 12) |
| Packing (no-X v1) | `[β; pack(Λ); log σ]` |
| Relation to delta_lognormal | **Out of scope** — do not change two-part delta; one-part is a separate family |

## Twin light Δ

Twin **admits** one-part lognormal. Light RCall Δ is **allowed** when a paired
tiny cell is cheap (local compute; ≠ ADEMP). rtol stays `1e-6` — no silent widen.
If a first cell fails, diagnose Identity vs numerical before changing tol.

## Out of scope

- delta_lognormal / delta_gamma re-open
- ZIP/ZINB/ZIB
- Per-trait σ as default (would need a new Identity if twin changes)
- Shared choke points (`GLLVM.jl`, `fit_gllvm.jl`, `bridge.jl`, ledger, `runtests.jl`)
  — merge-conductor only after engine green on owned files
- ADEMP / coverage / Totoro-DRAC
- truncated_nbinom2 (owned elsewhere)

## Ownership (engine Wave2)

- **OWN:** `src/families/lognormal.jl` (new), `test/test_lognormal.jl` (new), this decision
- **NOT:** twopart.jl, censored_poisson, truncated_nbinom2, shared choke points

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to lognormal engine on owned files only.
Public capability claim waits for FD ≤1e-6 + focused tests + ledger flip + Rose fence.
