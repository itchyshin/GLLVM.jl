# Decision: truncated_poisson Identity (twin-aligned; zero-truncated)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Arc 0 / Rung 3 docs-only → engine follows in same programme)  
**Lane:** `cursor/capability-catchup-20260815`  
**Depends on:** PR #204 MERGED @ `2914cc18`; capability catch-up G0 (Ada defaults).  
**Do not** invent ZIP/ZINB twin Δ; **do not** treat this as ADEMP/coverage.

## Problem

Ledger row `truncated_poisson / truncated_nbinom2` is `planned` while twin
gllvmTMB already exposes zero-truncated Poisson (family_id 10) and truncated
NB2 (family_id 11). Without an Identity lock, a Julia engine risks mismatching
the twin estimand (untruncated vs truncated mean; support; link).

## Twin cites (load-bearing)

| Surface | Evidence |
|---|---|
| Constructor | `gllvmTMB/R/families.R` `truncated_poisson()` — log link only; `linkinv` returns truncated mean `λ/(1−e^{−λ})` for GLM display |
| Enum | `R/enum.R` `truncated_poisson = 10L` |
| TMB dens | `src/gllvmTMB.cpp` fid==10: `dpois(y, λ, true) - logspace_sub(0, -λ)` with `λ = exp(η)`; **y ≥ 1 strictly** |
| Registry | `docs/design/02-family-registry.md` Truncated Poisson = **partial** |

Twin parameterisation for the **likelihood**: η on the **untruncated** Poisson
mean scale (`μ = exp(η)`); observation law is Poisson truncated at zero.

## Julia estimand (this Identity)

| Item | Lock |
|---|---|
| Support | `{1, 2, …}` — reject `y = 0` fail-loud |
| Linear predictor | `η = β + Λz` (+ optional offset later); **log link only** |
| Mean parameter | Untruncated `μ = exp(η)` (matches TMB `lambda_t`) |
| Log-pmf | `log Poisson(y; μ) − log(1 − e^{−μ})` |
| Score / weight (log link) | `μ_tr = μ/(1−e^{−μ})`; `s = y − μ_tr`; `W = μ_tr(1+μ−μ_tr)` (same as hurdle positive block) |
| Dispersion | none |
| `truncated_nbinom2` | **Contingent** — separate Identity when scheduled; not this ACCEPTED lock |

## Twin light Δ

Twin **admits** truncated_poisson (partial). Light RCall Δ is **allowed** when
a paired cell is cheap; not required to land the engine. Do **not** silently
widen rtol if a first cell fails — diagnose Identity vs numerical.

## Out of scope

- truncated_nbinom2 engine (Rung 5 contingent)
- Hurdle / ZIP / ZINB re-open
- ADEMP / coverage campaigns
- Bridge `@formula` advertising until engine + focused tests green (may land
  with engine as `TruncatedPoisson()` marker)

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to truncated_poisson engine (Rung 4) in this
programme. Public capability claim waits for tests + ledger flip + Rose fence.
