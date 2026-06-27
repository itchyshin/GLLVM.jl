# After Task: Bridge Poisson predictor-informed latent-score route

**Date**: `2026-06-26`
**Executed by**: Claude (Codex on leave for a few days), using the juliaup
Julia 1.10 toolchain and modeling the merged binomial X_lv slice
(`2026-06-25-bridge-binomial-xlv.md`) process and validation gates.

## 1. Goal

Extend the predictor-informed latent-score (`X_lv`) route from the merged
Gaussian and binomial slices to **Poisson (log link)**, point-estimate only,
mirroring the binomial slice. Keep CI, response masks, fixed-effect `X` + `X_lv`,
mixed-family, and broader non-Gaussian parity gated.

## 2. Implemented

- `PoissonFit` gained `alpha_lv` and `theta_packed` fields; the old six-argument
  constructor is preserved for existing callers.
- `poisson_lv_nll_packed()` — the packed objective
  `eta = beta + Lambda * (X_lv * alpha_lv + z_innovation)'`, reusing the Laplace
  core via the parameter-dependent offset `Lambda * alpha_lv' * X_lv[s]`
  (no trial counts).
- `fit_poisson_gllvm(...; X_lv, alpha_lv_init)` — joint `(beta, alpha_lv, Lambda)`
  by finite differences; `alpha_lv` warm start from a least-squares regression of
  the initial PPCA scores on `X_lv`.
- Post-fit: `getLV` gains `X_lv` + `component = :mean/:innovation/:total`;
  `predict` and `residuals` gain `X_lv`; `extract_lv_effects()` / `lv_effects()`
  for `PoissonFit`; `_nparams` counts `alpha_lv`; `_has_lv_predictor(::PoissonFit)`
  and `_lv_score_mean_for_fit(::PoissonFit)` added.
- `simulate(::PoissonFit; X_lv)` — byte-identical RNG stream to the scalar-mu
  path when `X_lv` is absent; draws `z_total = X_lv*alpha_lv + z` otherwise.
- Bridge: `_BRIDGE_XLV_FAMILIES` constant; both `X_lv` admission gates accept
  `poisson`; the `key == "poisson"` route gains the `X_lv` sub-branch
  (`poisson_xlv_rr` model tag, `lv_effects` / `alpha_lv` / `scores_mean` /
  `scores_innovation` payloads, honest note); the capability ledger
  `predictor_informed_lv` flag and per-family notes include `poisson`.
- confint: `_family_ci(::PoissonFit)` rejects `X_lv` fits (mirrors binomial); the
  generic profile / bootstrap guards already reject via `_has_lv_predictor`.
- `link_residual`: split `_trait_mean_fitted(::Union{PoissonFit, NBFit})` so a
  Poisson `X_lv` fit uses the marginal per-trait mean count for the link-implicit
  residual scaling (the `X_lv`-less `predict` cannot reconstruct per-site scores;
  the `X_lv`-route Sigma is a point-estimate report).
- Docs: `changelog.md`, `gllvmtmb-parity.md`, and `model.md` add Poisson to the
  admitted `X_lv` point set, honestly labeled.

## 3. Mathematical Contract

Design 73 / the binomial route, with the Poisson log-link observation
likelihood:

```text
z_total[s] = X_lv[s] alpha_lv + z_s,   z_s ~ N(0, I_K)
y[t, s]    ~ Poisson(exp(beta_t + (Lambda z_total[s])_t))
B_lv       = Lambda alpha_lv'          (rotation-stable; primary estimand)
```

The predictor mean enters the existing Laplace core as the parameter-dependent
offset `Lambda * alpha_lv' * X_lv[s]`. Point estimates only; raw `alpha_lv` is
latent-axis dependent and retained for diagnostics.

## 3a. Decisions and Rejected Alternatives

Decision: reuse the Laplace-core offset trick rather than a parallel Poisson
likelihood. Rejected alternative: a separate X_lv likelihood. Confidence: high.

Decision: for the `X_lv`-route latent-scale Sigma, use the marginal per-trait
mean count for the Poisson link-residual rather than threading `X_lv` through
`sigma_y_site` / `link_residual` / `_bridge_assemble_ng`. Rationale: smallest
safe change; the `X_lv` Sigma is a point-estimate report and the marginal mean
count is a consistent Poisson-rate estimate. Rejected alternative: thread `X_lv`
through four functions (more invasive; touches the binomial-untouched Sigma
path). Confidence: medium-high — an `X_lv`-aware fitted-mean refinement is a
possible follow-up.

Decision: keep CI / mask / `X` + `X_lv` / mixed-family / other-family rows gated.
Confidence: high.

## 4. Files Touched

- `src/families/poisson.jl`, `src/postfit.jl`, `src/simulate_fit.jl`,
  `src/bridge.jl`, `src/confint_family.jl`, `src/link_residual.jl`
- `test/test_bridge_lv_predictor.jl`, `test/test_bridge_capabilities.jl`
- `docs/src/changelog.md`, `docs/src/gllvmtmb-parity.md`, `docs/src/model.md`
- `docs/dev-log/check-log.md`, this after-task report

## 5. Checks Run

- `julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl`
  -> PASS; `bridge predictor-informed latent-score X_lv 117/117`, including the
  new `Poisson X_lv packed objective matches offset Laplace core` (1) and
  `Poisson X_lv native and bridge route` (15) testsets. The former
  `poisson ... fails loudly` assertion was converted to a passing route.
- Targeted regression set (one session):
  `test/test_bridge_capabilities.jl`, `test/test_poisson_fit.jl`,
  `test/test_simulate.jl`, `test/test_postfit.jl`, `test/test_bridge_ci.jl`
  -> ALL PASS (no regression from the `_trait_mean_fitted` split, the post-fit
  changes, the `simulate` method, or the confint guard).
- `git diff --check` -> clean.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'`
  -> PASS; `GLLVM.jl 4669 pass, 1 broken, 4670 total, 44m35.9s`. The pre-existing
  1 broken is unchanged; the slice adds 40 tests over the binomial baseline
  (`4629 pass, 1 broken`). Aqua and JET ran in the test environment.

## 6. Tests of the Tests

- The packed-objective test compares `poisson_lv_nll_packed()` to the offset
  Laplace likelihood (`atol = 1e-10`); a transposed or omitted offset fails it.
- The native test simulates Poisson counts with genuine latent innovation,
  checks convergence, `B_lv` recovery correlation (`> 0.95`), score
  decomposition (`total = mean + innovation`), prediction finiteness, the
  `X_lv`-aware `simulate`, and direct `confint` rejection.
- The bridge test checks the `poisson_xlv_rr` model tag, payload shapes
  (`lv_effects`, `alpha_lv`, `scores_mean`, `scores_innovation`), score algebra,
  note wording, and CI / mask / fixed-effect-`X` rejection.
- The capability ledger locks `poisson` into `predictor_informed_lv`.

## 7a. Issue Ledger

No new GitHub issue. Continues the Design 73 predictor-informed latent-score
lane. The R-side `gllvmTMB(..., engine = "julia")` admission of Poisson `X_lv`
is the paired follow-up slice.

## 8. Consistency Audit

- Prose (`changelog`, `gllvmtmb-parity`, `model`) states the admitted route as
  Gaussian + Poisson (log) + binomial logit/probit/cloglog point estimates only;
  CI / mask / `X` + `X_lv` / mixed-family / other-family rows are explicitly
  gated.
- REML / AI-REML wording was not introduced.
- No broad R-Julia parity claim; no R validation row promoted from this
  Julia-only work.

## 9. What Did Not Go Smoothly

The first deterministic test run errored in the bridge Sigma extractor: the
Poisson `link_residual` needs a per-trait fitted mean, which the `X_lv`-less
`predict` cannot reconstruct (binomial sidesteps this because its link-residual
is mu-hat-free). Resolved with the marginal-mean-count fallback for `X_lv`
Poisson fits.

## 10. Known Residuals

- The R package still gates `engine = "julia"` `X_lv` to Gaussian + binomial; a
  follow-up `gllvmTMB` PR must admit Poisson `X_lv` on the R side and test the
  object contract.
- The Poisson `X_lv` Sigma uses the marginal mean count for the link-residual
  (point-estimate report); an `X_lv`-aware fitted-mean refinement is a possible
  follow-up.
- CI / profile / bootstrap, response masks, `X` + `X_lv`, mixed-family, and
  NB / Gamma / Beta / ordinal `X_lv` remain deliberately gated.

## 11. Team Learning

- Count families have a mu-hat-dependent link-residual, so their `X_lv` bridge
  Sigma needs a fitted-or-marginal mean — the gotcha that the mu-hat-free
  binomial route did not surface.
- Family/link variants widen independently from CI and from each other; point
  estimates and interval routes remain separate status axes.
- Recovery targets `B_lv` (rotation-stable), not raw `alpha_lv` / `Lambda`.
- Claude can carry the live Julia slice with the juliaup toolchain when Codex is
  unavailable, provided it models the established slice process and runs the same
  validation gates (targeted + full `Pkg.test()`) before opening a PR.
