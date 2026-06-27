# After Task: Bridge NB2 predictor-informed latent-score route

**Date**: `2026-06-26`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10, modeling the
merged binomial slice and the paired Poisson slice
(`2026-06-26-bridge-poisson-xlv.md`).
**Branch**: `claude/nbinom2-xlv-20260626`, **stacked on** the Poisson branch
`claude/poisson-xlv-20260626` (GLLVM.jl PR #118), because the `X_lv` bridge
infrastructure (`_BRIDGE_XLV_FAMILIES`) is introduced there. The NB2 PR rebases
onto `main` after #118 merges.

## 1. Goal

Extend the predictor-informed latent-score (`X_lv`) route to **negative-binomial
(NB2, log link)**, point-estimate only, mirroring the Poisson slice with the
extra shared dispersion `r`. Keep CI, masks, fixed-effect `X` + `X_lv`,
mixed-family, grouped-dispersion `X_lv`, and the other families gated.

## 2. Implemented

- `NBFit` gained `alpha_lv` + `theta_packed` (back-compat seven-arg constructor
  preserved).
- `nb_lv_nll_packed()` — packed objective with layout `[β; alpha_lv; Λ; log r]`,
  reusing the Laplace core via the parameter-dependent offset
  `Λ * alpha_lv' * X_lv[s]`.
- `fit_nb_gllvm(...; X_lv, alpha_lv_init)` — joint `(β, alpha_lv, Λ, log r)` by
  finite differences; `alpha_lv` warm start from a least-squares regression of
  the initial PPCA scores on `X_lv`.
- Post-fit: `getLV`/`predict`/`residuals` gain `X_lv` (+ `component` on `getLV`);
  `extract_lv_effects`/`lv_effects` for `NBFit`; `_nparams` counts `alpha_lv`;
  `_has_lv_predictor(::NBFit)`; `_lv_score_mean_for_fit` widened to
  `Union{PoissonFit, NBFit}`.
- `simulate(::NBFit; X_lv)` — byte-identical scalar-μ stream when `X_lv` absent.
- Bridge: `negbinomial` added to `_BRIDGE_XLV_FAMILIES`; the `negbinomial` route
  gains an `X_lv` sub-branch that uses the **shared-dispersion** `fit_nb_gllvm`
  (not the per-trait grouped fitter), tagged `negbinomial_xlv_rr` with
  `lv_effects` / `alpha_lv` / `scores_mean` / `scores_innovation` and an honest
  note; the capability ledger `predictor_informed_lv` flag + the NB note include
  NB2.
- confint: `_family_ci(::NBFit)` rejects `X_lv` fits; generic profile/bootstrap
  guards reject via `_has_lv_predictor`.
- `link_residual`: `_trait_mean_fitted(::NBFit)` uses the marginal per-trait mean
  count for `X_lv` fits (same fallback as Poisson; the `X_lv` Σ is point-only).
- Docs: `changelog`, `gllvmtmb-parity`, `model` add NB2 (noting the
  shared-dispersion route).

## 3. Decisions

- The `X_lv` route uses the shared-`r` fitter rather than the per-trait grouped
  dispersion used by the no-X NB2 bridge route. Rationale: the predictor-informed
  point route is a narrow C1 slice; shared dispersion keeps it consistent with
  the Poisson route and avoids threading `X_lv` through the grouped fitter.
  Grouped-dispersion `X_lv` is a documented follow-up. Confidence: high.
- Stacked on #118 because NB2's bridge admission depends on the
  `_BRIDGE_XLV_FAMILIES` gate added there. Confidence: high.

## 4. Files Touched

- `src/families/negbin.jl`, `src/postfit.jl`, `src/simulate_fit.jl`,
  `src/bridge.jl`, `src/confint_family.jl`, `src/link_residual.jl`
- `test/test_bridge_lv_predictor.jl`, `test/test_bridge_capabilities.jl`
- `docs/src/changelog.md`, `docs/src/gllvmtmb-parity.md`, `docs/src/model.md`
- `docs/dev-log/check-log.md`, this after-task report

## 5. Checks Run

- `test/test_bridge_lv_predictor.jl` -> PASS `142/142` (new NB2 packed-objective
  + native/bridge testsets; first run, no errors).
- Targeted regression (`test_bridge_capabilities`, `test_nb_fit`,
  `test_simulate`, `test_postfit`, `test_bridge_ci`) -> ALL PASS (no regression
  from the post-fit changes, the `_lv_score_mean_for_fit` widening, the
  `_trait_mean_fitted` fallback, the simulate method, or the confint guard).
- `git diff --check` -> clean (to be reconfirmed before commit).
- Full `Pkg.test()` -> PASS; `GLLVM.jl 4694 pass, 1 broken, 4695 total,
  44m28.9s` (the pre-existing 1 broken is unchanged; +25 tests over the Poisson
  baseline `4669 pass`). Aqua + JET ran.

## 6. Tests of the Tests

- The packed-objective test compares `nb_lv_nll_packed()` (with `log r`) to the
  offset Laplace likelihood at a fixed `r` (`atol = 1e-10`).
- The native test simulates NB2 counts with genuine latent innovation, checks
  convergence, positive `r`, `B_lv` recovery correlation (`> 0.9`), score
  decomposition, the `X_lv`-aware simulate, and direct `confint` rejection.
- The bridge test checks the `negbinomial_xlv_rr` model tag, payload shapes,
  score algebra, note wording, and CI / mask / fixed-effect-`X` rejection.
- The capability ledger locks `negbinomial` into `predictor_informed_lv`.

## 7. Known Residuals

- NB2 `X_lv` uses the shared-dispersion fitter and the marginal-mean link
  residual (point-estimate report); grouped-dispersion `X_lv` and an
  `X_lv`-aware fitted mean are follow-ups.
- CI / masks / `X` + `X_lv` / mixed-family / NB1 / Gamma / Beta / ordinal `X_lv`
  remain gated.
- R-side `gllvmTMB` NB2 `X_lv` admission is a paired follow-up (after the Julia
  PR merges).

## 8. Team Learning

- The dispersion families slot into the Poisson pattern cleanly: the only extra
  is the trailing `log r` in the packed layout and the shared-vs-grouped
  dispersion choice for the `X_lv` route.
- The Poisson link-residual fallback generalises directly to NB2 (both are
  μ-hat-dependent count families).
