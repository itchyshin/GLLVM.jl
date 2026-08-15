# Decision: truncated_nbinom2 Identity (twin-aligned; zero-truncated NB2)

**Date:** 2026-08-15  
**Status:** ACCEPTED (Arc 0 / Identity docs-only → engine follows in same programme)  
**Lane:** `cursor/truncated-nbinom2-20260815`  
**Binding plan:** `docs/dev-log/plans/2026-08-15-truncated-nbinom2-identity-engine.md` (G0 LOCKED · Ada defaults)  
**Depends on:** PR #205 tip carrying `truncated_poisson` (merge-on-green); capability catch-up next_safe.  
**Do not** invent ZIP/ZINB twin Δ; **do not** treat this as ADEMP/coverage; **do not** reopen Phylo #127.

## Problem

Ledger row `truncated_nbinom2` is `planned` while twin gllvmTMB already exposes
zero-truncated NB2 (family_id 11). Without an Identity lock, a Julia engine risks
mismatching the twin estimand (untruncated vs truncated mean; support; link;
dispersion naming `φ` vs Julia `r`).

## Twin cites (load-bearing)

| Surface | Evidence |
|---|---|
| Constructor | `gllvmTMB/R/families.R` `truncated_nbinom2()` — log link only; `linkinv` returns truncated mean via `logspace_sub` / `logspace_add` on NB2 zero-mass |
| Enum | `R/enum.R` `truncated_nbinom2 = 11L` |
| TMB dens | `src/gllvmTMB.cpp` fid==11: `dnbinom_robust(y, log_mu, log_v_minus_mu, true) - logspace_sub(0, log_p0)` with `μ = exp(η)`, `φ = exp(log_phi_truncnb2(t))`, `log_p0 = φ · (log φ − log(μ+φ))`; **y ≥ 1 strictly** |
| Registry | `docs/design/02-family-registry.md` Truncated nbinom2 = **partial** |

Twin parameterisation for the **likelihood**: η on the **untruncated** NB2 mean
scale (`μ = exp(η)`); observation law is NB2 truncated at zero. Twin default
dispersion is **per-trait** `log_phi_truncnb2`.

## Julia estimand (this Identity)

| Item | Lock |
|---|---|
| Support | `{1, 2, …}` — reject `y = 0` fail-loud |
| Linear predictor | `η = β + Λz` (+ optional offset later); **log link only** |
| Mean parameter | Untruncated `μ = exp(η)` (matches TMB `mu_t`) |
| Dispersion | Julia `r` with `Var = μ + μ²/r` ≡ twin `φ`; **Arc1 fitter = shared scalar `r`** (Ada default). Twin per-trait `log_phi_truncnb2` is documented; **Arc1b / OWED** if light Δ needs per-trait |
| Log-pmf | `log NB2(y; μ, r) − log(1 − p0)`, `p0 = (r/(r+μ))^r` |
| Score / weight (log link) | `a = r/(r+μ)`; `μ_tr = μ/(1−p0)`; `s = a·(y − μ_tr)`; `W = a²·Var(Y\|Y>0)` with `Var_tr = (V+μ²)/(1−p0) − μ_tr²`, `V = μ + μ²/r`. **Do not omit `a`** (ordinary NB2 factor; Sol ceiling 2026-08-15) |
| Marker / fitter | `TruncatedNegBin2` + `fit_truncated_nbinom2_gllvm` |

## Twin light Δ

Twin **admits** truncated_nbinom2 (partial). Light RCall Δ is **allowed** when a
paired cell is cheap; not required to land the engine. If a shared-`r` cell fails
against twin’s per-trait default, do **not** silently widen rtol — OWED Arc1b
per-trait or gate parity.

## Out of scope

- truncated_nbinom1 / delta_truncated_* 
- Hurdle / ZIP / ZINB re-open or invent twin Δ
- ADEMP / coverage campaigns
- Phylo Model A / #127
- truncated-family confint / X/+cov variants
- Bridge `@formula` advertising until engine + focused tests green (may land with
  engine as `TruncatedNegBin2()` marker)

## STOP / CONTINUE

Identity ACCEPTED → **CONTINUE** to truncated_nbinom2 engine (Arc 1) in this
programme. Public capability claim waits for tests + ledger flip + Rose fence.
Rose fences: ≠ invent ZIP/ZINB twin Δ ≠ Phylo #127 ≠ ADEMP ≠ silent rtol widen.
