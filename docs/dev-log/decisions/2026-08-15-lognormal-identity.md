# Decision: one-part lognormal Identity (twin-aligned; fid 3)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Opus ceiling APPROVED-WITH-EDITS applied; Wave1 Identity → Wave2 engine on owned files)  
**Lane:** `cursor/lognormal-catchup-20260815`  
**Ceiling review:** Opus `APPROVED-WITH-EDITS` (agent `6f3e89ba-edcd-4bff-9b5d-44b26ce28697`)  
**Programme:** `lanes/gllvmjl-parallel-family-catchup-20260815/LOOP/`  
**Depends on:** G0 parallel catch-up (Ada 4-set); observe #205; base `origin/main` tip.  
**Do not** invent ZIP/ZINB twin Δ; **do not** treat this as ADEMP/coverage; **do not**
re-open delta_lognormal.

## Problem

Ledger row `lognormal` is `planned` while twin gllvmTMB already admits one-part
lognormal (`family_id` 3) with a live cpp dens. Julia already ships
**delta_lognormal** (two-part hurdle) but has **no** one-part
`fit_lognormal_gllvm` / `LognormalFit`. Without an Identity lock, a greenfield
engine risks mixing twin `sigma_eps` (shared with Gaussian) vs per-trait
delta σ, or claiming bridge parity before focused FD + light RCall.

## Twin cites (load-bearing)

| Surface | Evidence |
|---|---|
| Constructor | `gllvmTMB/R/families.R` `lognormal()` — links listed identity/log/inverse; **engine admits log only** (`R/fit-multi.R:468-469`) |
| Enum | `R/enum.R` / `family_to_id`: `lognormal = 3L` |
| TMB dens | `src/gllvmTMB.cpp` fid==3: `dnorm(log(y), η, σ_eps, true) - log(y)`; **y > 0 strictly** |
| R fail-loud | `R/fit-multi.R:2617-2624` — lognormal/Gamma rows must be strictly positive |
| Scale | Shared scalar `PARAMETER(log_sigma_eps)` — same residual SD as Gaussian when both present; mapped off when no fid ∈ {0,3} |
| Abort list | `fit-multi.R` supported-family message includes `lognormal()` |
| Response mean | `R/methods-gllvmTMB.R:339-342` — `exp(η)` is the **median**; conditional mean is `exp(η + σ²/2)` |

Twin likelihood: η is the **mean of log(y)** on the log-link scale (`E[log y] = η`);
observation law is lognormal with SD `σ_eps` on the log scale; Jacobian `−log(y)`.

## Julia estimand (this Identity)

| Item | Lock |
|---|---|
| Support | `(0, ∞)` — reject `y ≤ 0` fail-loud (parity with twin R check) |
| Linear predictor | `η = β + Λz` (+ optional offset / shared site-X later under a separate X Identity); **log link only** for v1 |
| Mean-on-log | `E[log y] = η` (matches TMB `eta_o`) |
| Log-density | `log Normal(log y; η, σ) − log(y)` |
| Reported `loglik` | **Must include** `Σ −log y` Jacobian (not a Gaussian-on-log-y shortcut that drops it) |
| `predict(type=:response)` | `exp(η + σ²/2)` (conditional mean); **not** `exp(η)` (median) |
| Dispersion | **Shared scalar** `σ` packed as `log σ` — twin `sigma_eps` / #856-closed-as-false-premise (per-trait promotion collapsed 13/20 sims to the zero boundary with `convergence=0` + `pdHess=TRUE`) — **not** per-trait `log_sigma_lognormal_delta` (fid 12) |
| Packing (no-X v1 free-σ) | `[β; pack(Λ); log σ]` with `β` length `p` → free count `p + rr + 1` |
| Profile-out | **Admissible without changing the estimand**: because `log y` is exactly Gaussian, closed-form `gaussian_marginal_loglik` + `Λ = σ·L` profile (`src/profile.jl`) may drop the log-σ axis; packing then becomes `[β; pack(L)]` with σ recovered. v1 ships the **profiled** Gaussian-reuse path; free-σ packing remains the FD/Identity reference layout |
| Mixed-family σ | Twin **ties** one `σ_eps` across Gaussian+lognormal rows. Julia v1 is **single-family only** — “shared with Gaussian” is twin context, not a Julia v1 obligation |
| Relation to delta_lognormal | **Out of scope** — do not change two-part delta; one-part is a separate family |

## Twin light Δ

Twin **admits** one-part lognormal. Light RCall Δ is **allowed** when a paired
tiny cell is cheap (local compute; ≠ ADEMP). rtol stays `1e-6` — no silent widen.
If a first cell fails, diagnose Identity vs numerical before changing tol.
Jacobian inclusion is load-bearing for that Δ (data-dependent constant otherwise).

## Out of scope

- delta_lognormal / delta_gamma re-open
- ZIP/ZINB/ZIB
- Per-trait σ as default (would need a new Identity; #856 evidence forbids casual promotion)
- Shared choke points (`GLLVM.jl`, `fit_gllvm.jl`, `bridge.jl`, ledger, `runtests.jl`)
  — merge-conductor only after engine green on owned files (see `ADMIT.md`)
- User-facing table pages (`docs/src/response-families.md`, `docs/src/gllvmtmb-parity.md`)
  — conductor / docs lane when API is exported (convention cascade); listed here so they are not orphaned
- ADEMP / coverage / Totoro-DRAC
- truncated_nbinom2 / censored_poisson / ZIB+X (owned elsewhere)

## Ownership (engine Wave2)

- **OWN:** `src/families/lognormal.jl` (new), `test/test_lognormal.jl` (new), this decision, `ADMIT.md`
- **NOT:** twopart.jl, censored_poisson, truncated_nbinom2, shared choke points

## Docs-only vs engine gate

The prior Identity-only commit (`06a3b5a1` / PR #207) was **docs-only** — **no test run
applies** to that commit. STOP/CONTINUE below is **not** a green engine gate.
Engine green requires focused FD ≤ 1e-6 + owned tests in this catch-up lane.

## STOP / CONTINUE

Identity **ACCEPTED** (Opus edits applied) → **CONTINUE** to lognormal engine on owned files only.
Public capability claim waits for FD ≤ 1e-6 + focused tests + ledger flip + Rose fence.
