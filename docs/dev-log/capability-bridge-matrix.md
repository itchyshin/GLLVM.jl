# Capability And Bridge Matrix

Date: 2026-06-14

This is the governing matrix for finishing the `GLLVM.jl` + `gllvmTMB` twin.
It replaces broad "full capability" wording with auditable rows. A row can be
called `covered` only when the Julia engine, R bridge, point estimates,
objective/logLik, CI or CI-status, tests, docs, visuals where relevant, issue
ledger, and Rose verdict agree.

## Current Branch Cautions

- The local `GLLVM.jl` checkout now exposes a deliberately narrow
  `GLLVM.bridge_fit` for no-covariate one-part families. It passed
  `test/test_bridge_fit.jl` 175/175 on 2026-06-14. Bridge support is still
  `partial`, not `covered`, because fixed-effect `X`, mixed families,
  missing-response masks, broader CI routing, and live `gllvmTMB` R roundtrips
  remain open.
- Non-Gaussian CI wording is inconsistent across public docs: some files state
  six one-part families have Wald/profile CIs, while other docs still call
  non-Gaussian inference planned. Keep the matrix at `partial` for
  non-Gaussian inference overall until docs, tests, and issue evidence align.
- Preview figures under `.claude/preview/florence*` are experimental evidence,
  not public capability status.

## Status Vocabulary

| Status | Meaning |
| --- | --- |
| `covered` | Implemented, tested, documented, bridged if user-facing, and evidence-linked. |
| `partial` | Some real implementation exists, but one or more gates are missing. |
| `experimental` | Prototype or research path exists; not promoted to user-facing support. |
| `planned` | Roadmap item with no promoted implementation. |
| `unsupported` | Deliberately unavailable or out of scope. |

## Response Families

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Gaussian | covered | partial | covered | gllvmTMB bridge parity | Minimal no-X `bridge_fit` route tested; live R roundtrip and X/missingness remain open. |
| Poisson | covered | partial | partial | GLLVM #91 | Minimal no-X `bridge_fit` route and Wald CI parity tested; high-rate divergence blocks broad promotion. |
| Binomial | covered | partial | partial | bridge parity | Minimal no-X `bridge_fit` route tested; CI labels and R roundtrip need evidence. |
| Negative binomial NB2 | covered | partial | partial | bridge parity | Minimal no-X `bridge_fit` route tested; dispersion transform and observed-Hessian parity must stay explicit. |
| NB1 | planned | planned | planned | new issue | No public covered claim. |
| Beta | covered | partial | partial | bridge parity | Minimal no-X `bridge_fit` route tested; precision transform and CI route need parity evidence. |
| Gamma | covered | partial | partial | gradient default gate | Minimal no-X `bridge_fit` route tested; #96 mode-finder safeguards fixed locally; analytic default still blocked until benchmark/logLik deltas are <= 1e-6. |
| Ordinal | partial | partial | partial | bridge/API row | Minimal no-X `bridge_fit` route tested; cutpoint, prediction, and label route need bridge tests. |
| COM-Poisson | experimental | planned | planned | family issue | Keep experimental until recovery and R route exist. |
| Tweedie | planned | planned | planned | family issue | Roadmap only. |
| Exponential | planned | planned | planned | family issue | Gamma subcase is not a public row yet. |
| Two-part / hurdle | partial | planned | partial | two-part bridge issue | Dedicated paths exist in parts; unified bridge and CI route missing. |

## Model Structures

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Latent factors/loadings | covered | partial | partial | R parity | Minimal bridge tests rotated-loading parity to direct Julia fits; R Procrustes parity still needed. |
| Fixed-effect covariates `X` | partial | partial | partial | gllvmTMB #488 | Integration reports broader support; current local docs are stale. |
| Row effects / random intercepts | partial | partial | partial | family audit | Must be family-by-family, not blanket. |
| Random slopes | planned | planned | planned | new issue | Start with Gaussian, then non-Gaussian batches. |
| Phylogenetic dependence | partial | partial | partial | GLLVM #61 | Representation equality exists and #92 phylo-signal transformed-Wald scale is fixed locally; O(p) wiring and R bridge remain gates. |
| Animal / relmat | partial | planned | partial | structure issue | Name alignment and PSD/PD tests required. |
| Spatial / SPDE | experimental | planned | planned | GLLVM #62 | Field visuals and CI status required before promotion. |
| Kernel / NNGP / Matern | planned | planned | planned | DRM #270 / GLLVM #62 | Fixed-kernel first; NNGP/Matern remain roadmap. |
| Coevolution / cross-kernel | experimental | planned | planned | gllvmTMB #361 | Use C0-C5 serialized gates. |

## Data Complications

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Response missingness | partial | planned | partial | GLLVM #27 | Mask data term only; all-true mask equals complete logLik exactly. |
| Predictor missingness | partial | planned | partial | GLLVM #27 | Explicit `mi()` design only; no mean-imputation shortcut. |
| Mixed missingness | planned | planned | planned | new issue | Define interaction or reject deliberately. |
| Unbalanced tables | partial | planned | partial | bridge issue | Preserve table shape and labels through R route. |

## Inference And Post-Fit

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Wald CIs | partial | partial | partial | CI status issue | Minimal bridge tests Poisson Wald CI parity; unsafe Hessian blocks Wald inference, not the fit object. |
| Profile CIs | partial | partial | partial | profile visual issue | Promoted targets need profile curves, not endpoints only. |
| Bootstrap CIs | partial | partial | partial | coverage issue | Calibration claims require coverage study. |
| Derived CIs | partial | planned | partial | bridge/docs issue | #92 phylo-signal transformed-Wald scale/export/test gap is fixed locally; R bridge exposure and public docs remain open. |
| AIC/BIC/logLik | covered | partial | covered | bridge method issue | Minimal bridge returns AIC/BIC/logLik and tests logLik parity; R object methods need roundtrip tests. |
| Prediction/fitted | partial | planned | partial | bridge method issue | Prediction labels and newdata route need tests. |
| Residuals | partial | planned | partial | bridge method issue | Dunn-Smyth/Pearson support must be family-specific. |
| Summary/coef/vcov | partial | planned | partial | bridge method issue | Flat payload and stable labels required. |

## Speed And Algorithm Rows

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Analytic Laplace gradients | experimental | unsupported | partial | GLLVM #65 | Default flip only when faster and logLik delta <= 1e-6. |
| Exact implicit Laplace adjoint | planned | unsupported | planned | new issue | FD gradient parity <= 1e-6 before replacing finite differences. |
| Takahashi selected inverse | experimental | unsupported | planned | GLLVM #61 | Wire O(p) only where equality to reference is verified. |
| Observed-information / Fisher scoring | planned | unsupported | planned | new issue | Use HSquared AI-REML as design inspiration only; do not call non-Gaussian Laplace AI-REML. |
| Profile endpoint acceleration | planned | partial | partial | new issue | Endpoint solver must match baseline profile CIs. |
| Bootstrap/profile batching | planned | partial | partial | new issue | Separate cold start, warm start, marshalling, kernel, and reconstruction times. |

## Promotion Rule

Before changing any `partial`, `experimental`, or `planned` row to `covered`,
the implementing slice must record:

1. engine files and tests;
2. R bridge files or deliberate rejection tests;
3. point-estimate and objective/logLik evidence;
4. CI endpoints or CI-status vocabulary;
5. exact-equality, gradient-vs-FD, R-Julia parity, ADEMP recovery, or comparator
   evidence as appropriate;
6. docs/article and visual updates for user-facing behavior;
7. issue update and after-task report;
8. Rose verdict.
