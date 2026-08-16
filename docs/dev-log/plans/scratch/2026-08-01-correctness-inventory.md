# Correctness inventory — logLik-first catch-up arc

**Date:** 2026-08-01  
**Base:** `origin/main` @ `05210eca` (worktree `/tmp/gllvmjl-parity-restart-20260801`)  
**Twin:** gllvmTMB `origin/main` @ `cee55a07`  
**Scope:** model-identity blockers for live marginal logLik / packed-objective oracle cells  
**Out of arc:** #129 (CI scale), #128 (H² denominator) — inference/derived quantities, not objective

---

## Fenced issues (not logLik blockers)

| Issue | One-line mismatch | Files / symbols | Blocks logLik cell? | Fix direction |
|-------|-------------------|-----------------|---------------------|---------------|
| **#129** | Julia Wald tags `sigma_phy` `:linear` (identity) but profile tags it `:log_sd` and applies `exp()` to bounds; R uses log-SD + `exp()` in both paths | `src/confint.jl` (`_confint_all_term_names`, ~L104–106); `src/confint_profile.jl` (`_profile_all_term_names`, ~L117–121; back-transform ~L494–496) | **No** — CI only; packed objective unchanged | **FENCE** this arc; later align tag + transform with R (`log(sigma_phy)` pack or drop profile `exp`) |
| **#128** | Julia `phylo_signal` divides phylo var by non-phylo `Sigma_y_site`; R profiles `sigma2_phy / (sigma2_phy + sigma2_non)` | `src/confint_derived.jl` (`phylo_signal`, ~L305–322; `sigma_y_site` builder ~L141–170) | **No** — derived H² only | **FENCE** this arc; later add phylo term to denominator |

---

## In-scope model-identity blockers

| Issue | One-line mismatch (Julia vs R) | Files / symbols | Blocks logLik cell? | Fix direction (Julia→R) |
|-------|-------------------------------|-----------------|---------------------|------------------------|
| **#132** | R estimates per-trait NB2 dispersion `log_phi_nbinom2[p]`; Julia default fitter packs one shared `log r` for all traits | `src/families/negbin.jl` (`NBFit.r::Float64`, `fit_nb_gllvm`, `nb_lv_nll_packed` last entry); `src/families/fit_gllvm.jl` (default `_fit_gllvm(::NegativeBinomial)` → shared fitter) | **Yes** for default `fit_nb_gllvm` / `fit_gllvm(NegativeBinomial())` NB2 cell; **No** if oracle uses grouped per-trait path with `group = 1:p` | Extend default NB2 pack/unpack to length-`p` `log r` vector (mirror gllvmTMB); or document + gate default fitter and route parity through existing `fit_nb_gllvm_grouped(Y; group=1:p)` / `fit_gllvm_grouped` (`src/families/grouped_dispersion.jl`). Map public scales: gllvm `φ = 1/r` (see `src/bridge.jl` dispersion payload). **Note:** X_lv NB2 bridge still calls shared `fit_nb_gllvm` (~L901) — separate gate if C1 cells land before default fix. |
| **#148** | R estimates per-trait Beta precision `log_phi_beta[p]`; Julia default fitter packs one shared `log φ` | `src/families/beta.jl` (`BetaFit.φ::Float64`, `fit_beta_gllvm`, `beta_lv_nll_packed`); `src/families/fit_gllvm.jl` (default → shared fitter) | **Yes** for default Beta cell; **No** with `fit_beta_gllvm_grouped(Y; group=1:p)` | Same pattern as #132: per-trait `φ` vector in default fitter, or gate + grouped route (`src/families/grouped_dispersion.jl`). X_lv Beta bridge uses shared `fit_beta_gllvm` — same C1 caveat as NB2. |
| **#133** | R: per-trait intercept (`X_fix 0+trait`) + per-trait cutpoints with `τ₁=0` and `K−2` free cuts; Julia default: shared cutpoints, **no intercept** (`η = Λz`). Partial fix: per-trait cuts exist but still no intercept / wrong identifiability | `src/families/ordinal.jl` (`fit_ordinal_gllvm` → `OrdinalFit`; `fit_ordinal_gllvm_pertrait` → `OrdinalPerTraitFit` — per-trait `τ`, still `η=Λz` only); `src/families/fit_gllvm.jl` (default → shared-cutpoint fitter); `src/bridge.jl` (ordinal → `fit_ordinal_gllvm_pertrait`) | **Yes** for any ordinal logLik cell vs gllvmTMB default ordinal model | Add per-trait intercepts `β[p]` to ordinal Laplace core; per-trait cutpoints with R identifiability (`τ_{t,1}=0`, `K_t−2` free); make `fit_ordinal_gllvm_pertrait` (or new default) the parity entry; retire shared-cutpoint default for twin claims. |

---

## Binomial / Poisson — additional open correctness issues

**Verdict:** No open GitHub `[correctness]` issues filed against the ordinary Laplace Binomial/Poisson one-part model. Engine shape matches R for the planned cells: per-trait intercepts `β`, logit (Binomial) / log (Poisson) links, trial matrix `N` (Binomial), Laplace marginal via `src/families/laplace.jl`.

| Item | Severity | Notes | Blocks Bin/Pois logLik cell? |
|------|----------|-------|------------------------------|
| *(none filed)* | — | `_glm_logpdf` / score / weight in `src/families/binomial.jl`, `src/families/poisson.jl`; fitters `fit_binomial_gllvm`, `fit_poisson_gllvm`; bridge no-X routes (`src/bridge.jl` ~L835, ~L884) | **No** (model identity OK for plain RR + intercept cells) |
| DRAFT RCall scaffold | transport | `test/parity/test_gaussian_parity.jl`, `test/parity/README.md` — call shape / extractor names unvalidated live | **Yes** until validated — fails as transport, not numerics |
| Oracle must compare same packed θ | methodology | Rotation-invariant logLik at fixed `(β, Λ[, N])`, not free-fit loadings | N/A — test design, not engine bug |
| #149 `n >= p` assert | robustness | `src/fit.jl:354` — **Gaussian closed-form only**; Laplace Bin/Pois fitters have no such guard | **No** for Laplace cells with `n ≥ p`; watch only if Gaussian cell reuses closed-form path with tiny `n` |
| Phylo / tier Gaussian bugs (#134, #135, #136) | correctness | Gaussian + structured dependence only | **No** for ordinary (non-phylo) Bin/Pois Laplace cells fenced this arc |
| X_lv / C1 predictor-informed score | follow-up gate | Bridge wired for Poisson/Binomial X_lv (`src/bridge.jl`); not needed for first plain cells | **No** unless arc expands to C1 before base cells green |

---

## Related correctness issues (other families / paths — gate separately)

| Issue | Relevance to this arc |
|-------|----------------------|
| #131 communality/correlation denominator | Derived post-fit; fence with #128/#129 |
| #134 phylo loadings silently dropped if `Σ_phy` omitted | Gaussian phylo path only |
| #135 W-tier cross-trait covariance | Gaussian multilevel only |
| #136 signed vs log `sigma_phy` | Gaussian phylo unique SD only |
| #137 derived-profile constraint check | Profile CI, not logLik |
| #92 `phylo_signal_wald_ci` broken | Wald derived CI; fenced |

---

## Suggested family cell order (from plan + this inventory)

1. **Gaussian** — validate DRAFT oracle transport first.  
2. **Binomial + Poisson** — no model-identity blockers found; proceed once R call shape live.  
3. **NB2 + Beta** — use `fit_*_gllvm_grouped(...; group=1:p)` in oracle **or** fix #132/#148 on default fitters before claiming same-model.  
4. **Ordinal** — blocked until #133 (intercept + cut identifiability) landed; do not use `fit_ordinal_gllvm` (shared cuts) for twin claims.

---

## Evidence sources

- GitHub issues #132, #133, #148, #129, #128 (`gh issue view`, 2026-08-01)  
- Code at `/tmp/gllvmjl-parity-restart-20260801` @ `05210eca`  
- Plan: `docs/dev-log/plans/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`  
- Parity doc: `docs/src/gllvmtmb-parity.md` (grouped dispersion routing note)
