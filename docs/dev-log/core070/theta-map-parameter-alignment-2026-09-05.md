# θ-map parameter alignment — batch-1 (2026-09-05)

**Ticket:** `RESEARCH-THETA-MAP-20260905` (M2-R1)  
**Status:** RESEARCH — alignment tables filled enough for **implement-vs-demote**  
**Branch:** `cursor/m2-r1-theta-map-20260905`  
**Oracle R twin:** gllvmTMB worktree HEAD `c5ddd198b` (read-only; D-220)  
**Julia tip (this memo branch):** see commit tip  
**No programme §7 / true-parity claim.** No `src/` or R engine edits in this ticket.

Related: `theta-map-disposition-2026-09-05.md` · matched pilot
`second-order-matched-pilot-batch1-20260905.md` · harness
`tools/core070_second_order/theta_map.jl`.

---

## Verdict (owner-decidable)

| Question | Answer |
|---|---|
| Honest `θ_R → θ_JL` without changing public APIs? | **Yes** for batch-1 defaults — **bijection** on `{b_fix, theta_rr_B, log_phi_*}` once the harness accepts **per-trait** dispersion length `p`. |
| Pilot 2 blocked cells (`beta_logit`, `nb2_log`)? | **Harness false-negative**, not a model mismatch. Pilot `julia_theta_len` already matches R (`15` / `19`); `theta_map.jl` wrongly requires `length(log_phi_*) == 1`. |
| Implement vs demote? | Prefer **implement (harness-only)** — fix `tools/core070_second_order/theta_map.jl` (+ matched pilot re-smoke). **Demote** only if owner refuses matched tier for beta/NB2 even after the map fix. |

Companion disposition: `theta-map-spec-or-demote-2026-09-05.md`.

---

## Batch-1 pilot shapes (anchor evidence)

From `second-order-matched-pilot-batch1-20260905/*.json` (p=5 unless noted):

| Cell | p | K | n | R `opt$par` counts | Julia `θ` len | Pilot |
|---|---:|---:|---:|---|---:|---|
| gaussian | 5 | 2 | 80 | `b_fix`×5, `theta_rr_B`×9, `log_sigma_eps`×1 | 10 | **pass** (exclude `b_fix`; Y pre-centred) |
| poisson | 5 | 2 | 60 | `b_fix`×5, `theta_rr_B`×9 | 14 | **pass** |
| binomial_logit | 5 | 2 | 60 | `b_fix`×5, `theta_rr_B`×9 | 14 | **pass** |
| beta_logit | 5 | 1 | 60 | `b_fix`×5, `theta_rr_B`×5, `log_phi_beta`×5 | **15** | **blocked** (map) |
| nb2_log | 5 | 2 | 80 | `b_fix`×5, `theta_rr_B`×9, `log_phi_nbinom2`×5 | **19** | **blocked** (map) |

Length identity already holds for beta/NB2:  
`|θ_JL| = p + rr_theta_len(p,K) + p` = `|b_fix| + |theta_rr_B| + |log_phi_*|`.

---

## R TMB θ slots (R scout — do not re-scout)

Source: R twin HEAD `c5ddd198b`. Dispersion lives in **separate TMB parameter vectors**.  
Cites: `gllvmTMB.cpp:1078-1304`, `:3071-3177`; `R/fit-multi.R:5694-5914`;
`docs/design/03-likelihoods.md:42-77,:589-656`.

### Shared blocks (all batch-1 cells)

| R name | Length | Role | Notes |
|---|---|---|---|
| `b_fix` | p (typically) | Fixed effects / trait intercepts | Present on non-Gaussian cells; Gaussian pilot excludes (pre-centred Y) |
| `theta_rr_B` | `p·K − K(K−1)/2` | Packed lower-triangular Λ | Same packing convention as Julia `pack_lambda` |
| `theta_diag_B` | optional | Diagonal companion | Not in batch-1 ordinary-latent pilot cells |
| `z_B` / `s_B` | random | Latent scores | Integrated / random — **not** outer θ for matched Hessian |

### Per-family dispersion

| Family | R TMB slot | Length | Link | Likelihood meaning | Trap |
|---|---|---|---|---|---|
| gaussian | `log_sigma_eps` | **1** (shared) | σ = exp(log_σ) | Residual SD | — |
| poisson | *(none)* | 0 | — | Mean-only | — |
| binomial | *(none)* | 0 | — | Bernoulli / trials | — |
| nbinom2 | `log_phi_nbinom2` | **p** (per-trait) | φ = exp(log_phi) | Var = μ + μ²/φ | TMB optimizes **log_phi**, **not** log_σ; public σ = 1/√φ |
| Beta | `log_phi_beta` | **p** (per-trait) | φ = exp(log_phi) | precision φ | Same **log_phi ≠ log_σ** trap |

Init defaults (`fit-multi.R`): `log_phi_nbinom2` starts at 0; `log_phi_beta` starts at 1.0.

---

## Julia packed θ (integrator + local smoke; Julia scout may refine)

Batch-1 matched driver uses `fit_gllvm` for beta/NB2
(`tools/core070_second_order/run_matched_batch1.jl`). Per `src/families/fit_gllvm.jl`
API B: `NegativeBinomial` / `Beta` default **`disp_group = :species`** →
`fit_*_gllvm_grouped` → `θ = [β; pack_lambda(Λ); log.(disp_1…disp_p)]`.

Verified smoke (this session, worktree):

| Fit | `|θ|` via `_family_ci` | Tail names |
|---|---|---|
| `BetaGroupedFit` p=5 K=1 | 15 | `phi[1]…phi[5]` (stored as log in θ) |
| `NBGroupedFit` p=5 K=2 | 19 | `r[1]…r[5]` (log in θ) |

Loading pack: `src/packing.jl` — diagonals then column-wise strict lower
(matches gllvmTMB.cpp:343-376). Confirmed by poisson/binomial matched **pass**.

| Julia path | Dispersion | Pairable to R default? |
|---|---|---|
| `fit_gllvm(... Beta/NB)` default | per-trait ×p | **Yes — bijection** |
| `fit_beta_gllvm` / `fit_nb_gllvm` shared | ×1 | **No** vs R default ×p (nested submodel) |
| Grouped G < p | ×G | Pairable only if R `dispersion_trait_map` ties same groups |

**TBD (Julia scout):** exact name strings in `_grouped_dispersion_names`; any
`theta_diag_B` Julia analogue for batch-1 (none expected).

---

## Alignment table (batch-1)

Legend: **bijection** = 1–1 same length & meaning · **block map** = reorder/concat by name ·
**exclude** = intentional drop · **non-pairable** = different model dimension ·
**harness-bug** = lengths match but map code rejects.

| Cell | R slots → Julia θ | Class | Notes |
|---|---|---|---|
| gaussian | `log_sigma_eps` → θ[1]; `theta_rr_B` → θ[2:end]; drop `b_fix` | **block map + exclude** | Pilot pass; SE/vcov ≤ 1e-4 |
| poisson | `b_fix`∥`theta_rr_B` → `[β; pack(Λ)]` | **bijection** | Pilot pass |
| binomial_logit | same as poisson | **bijection** | Pilot pass |
| beta_logit | `b_fix`∥`theta_rr_B`∥`log_phi_beta` → `[β; pack(Λ); log φ_1…φ_p]` | **bijection** (blocked as **harness-bug**) | R ×p ↔ Julia ×p; map requires ×1 |
| nb2_log | `b_fix`∥`theta_rr_B`∥`log_phi_nbinom2` → `[β; pack(Λ); log r_1…r_p]` | **bijection** (blocked as **harness-bug**) | Same; NB2 φ ≡ Julia r (size) |

### Proposed map (no engine change)

```text
θ_JL = vcat(rpar[b_fix], rpar[theta_rr_B], rpar[log_phi_*])   # when |log_phi_*| == p
# reject pooling p→1; reject if |log_phi_*| ∉ {0,1,p} without group map
```

Fix site: `tools/core070_second_order/theta_map.jl` `map_r_theta_glm` —
accept `length(didx) == p` (species) as well as `== 1` (shared).

---

## Cost sketch (for owner)

| Branch | Work | Risk |
|---|---|---|
| **Implement harness** | ~20–40 LOC in `theta_map.jl` + re-run matched batch-1 smoke (≤30 min) | Low; no API |
| **Demote matched tier** | Fence text in disposition + gate-tier A9/A11 notes | Leaves beta/NB2 each-own-optimum only |

---

## Out of scope

- Production `src/` / R parameterisation changes  
- Widening second-order tolerances  
- Programme §7 claim  
- Merging PR #297 (parallel T4 human merge)

---

## Checklist for owner decision

- [x] Parameter alignment table (batch-1)  
- [x] beta/NB2 dispersion mismatch diagnosed (harness vs model)  
- [x] Matched-pilot blockers cited  
- [x] Implement path without public API change identified  
- [ ] Owner chooses implement vs demote (append `theta-map-disposition-2026-09-05.md` §Owner decision)
