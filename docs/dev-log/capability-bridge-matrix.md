# Capability And Bridge Matrix

Date: 2026-06-14

This is the governing matrix for finishing the `GLLVM.jl` + `gllvmTMB` twin.
It replaces broad "full capability" wording with auditable rows. A row can be
called `covered` only when the Julia engine, R bridge, point estimates,
objective/logLik, CI or CI-status, tests, docs, visuals where relevant, issue
ledger, and Rose verdict agree.

## Current Branch Cautions

- The local `GLLVM.jl-integration` runtime branch has green local evidence for
  the #91 high-rate Poisson safeguard, #92 phylo-signal transformed-Wald scale
  fix, #96 Laplace mode-finder safeguard, and Gamma analytic-gradient default.
  These are local branch facts only until the PR/issue ledger is reconciled on
  GitHub.
- The local dashboard `GLLVM.jl` checkout is not the current paired bridge
  runtime. Current R bridge evidence targets `GLLVM.jl-integration` at the head
  shown on the dashboard, where `GLLVM.bridge_capabilities()` exposes the
  tested bridge surface. Do not infer bridge capability from stale files in this
  dashboard worktree.
- The `gllvmTMB` `engine-julia` branch live bridge tests now pass 394/394
  against current `GLLVM.jl-integration`, including the bridge capability drift
  guard, fixed-effect-X rows, missing-response-mask rows, Gaussian
  Wald/profile/bootstrap CI transport, NB1 no-X admission, and NB1 post-fit
  methods. That validates bridge mechanics for the tested cells; it does not
  validate all family/structure parity rows.
- Non-Gaussian CI wording has had a first cleanup pass, but the matrix remains
  `partial` for non-Gaussian inference overall until docs, issue evidence,
  visual diagnostics, and R bridge parity all agree.
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
| Poisson | covered | partial | partial | GLLVM #91 | Minimal no-X `bridge_fit` route and Wald CI parity tested; high-rate divergence fixed locally on `GLLVM.jl-integration`, but GitHub issue/PR reconciliation and broader R parity remain open. |
| Binomial | covered | partial | partial | bridge parity | Minimal no-X `bridge_fit` route tested; CI labels and R roundtrip need evidence. |
| Negative binomial NB2 | covered | partial | partial | bridge parity | Minimal no-X `bridge_fit` route tested; dispersion transform and observed-Hessian parity must stay explicit. |
| NB1 | covered | partial | partial | bridge parity | `GLLVM.jl-integration` exposes a no-X `bridge_fit(family="nb1")` row; `gllvmTMB` admits complete-data no-X NB1 fits with formula-vs-direct logLik equality, Wald `phi` CI smoke, and post-fit predict/fitted/residuals/augment/simulate coverage. NB1 X, masks, masked simulations, profile/bootstrap CIs, native TMB parity, and mixed-family NB1 remain queued. |
| Beta | covered | partial | partial | bridge parity | Minimal no-X `bridge_fit` route tested; precision transform and CI route need parity evidence. |
| Gamma | covered | partial | partial | gradient default gate | Minimal no-X `bridge_fit` route tested; #96 mode-finder safeguards fixed locally; Gamma now defaults to analytic gradients locally after quick/medium benchmark gates with logLik deltas <= 1.9e-12 and full `Pkg.test()` green. |
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
| Phylogenetic dependence | partial | partial | partial | GLLVM #61 | Representation equality exists and #92 phylo-signal transformed-Wald scale/export/test path is fixed locally; O(p) sparse-gradient wiring and R bridge exposure remain gates. |
| Animal / relmat | partial | planned | partial | structure issue | Name alignment and PSD/PD tests required. |
| Spatial / SPDE | experimental | planned | planned | GLLVM #62 | Field visuals and CI status required before promotion. |
| Kernel / NNGP / Matern | planned | planned | planned | DRM #270 / GLLVM #62 | Fixed-kernel first; NNGP/Matern remain roadmap. |
| Coevolution / cross-kernel | experimental | planned | planned | gllvmTMB #361 | Use C0-C5 serialized gates. |

## Data Complications

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Response missingness | partial | partial | partial | GLLVM #27 | Mask data term only; all-true mask equals complete logLik exactly. R bridge coverage is admitted only for no-X non-Gaussian rows live-tested against `GLLVM.jl-integration`; Gaussian/NB1 masks, X+mask, masked simulations, and masked CI refits remain unsupported. |
| Predictor missingness | partial | planned | partial | GLLVM #27 | Explicit `mi()` design only; no mean-imputation shortcut. |
| Mixed missingness | planned | planned | planned | new issue | Define interaction or reject deliberately. |
| Unbalanced tables | partial | planned | partial | bridge issue | Preserve table shape and labels through R route. |

## Inference And Post-Fit

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Wald CIs | partial | partial | partial | CI status issue | Minimal bridge tests Poisson Wald CI parity; unsafe Hessian blocks Wald inference, not the fit object. |
| Profile CIs | partial | partial | partial | profile visual issue | Gaussian profile CI transport is live-tested through `confint.gllvmTMB_julia`; promoted broader targets still need family/structure status rows and profile curves, not endpoints only. |
| Bootstrap CIs | partial | partial | partial | coverage issue | Calibration claims require coverage study. |
| Derived CIs | partial | planned | partial | bridge/docs issue | #92 phylo-signal transformed-Wald scale/export/test gap is fixed locally and wired into the full suite; R bridge exposure and public docs remain open. |
| AIC/BIC/logLik | covered | partial | covered | bridge method issue | Minimal bridge returns AIC/BIC/logLik and tests logLik parity; R object methods need roundtrip tests. |
| Prediction/fitted | partial | partial | partial | bridge method issue | In-sample prediction/fitted rows are routed for current one-part bridge payloads, including NB1 no-X and selected X rows. `newdata`, ordinal probabilities, mixed-family row-wise links, and broader structures remain queued. |
| Residuals | partial | partial | partial | bridge method issue | Response residual and augment rows are routed for current in-sample bridge payloads, including masked-row status where admitted. Dunn-Smyth/Pearson support and ordinal probabilities remain family-specific future work. |
| Summary/coef/vcov | partial | planned | partial | bridge method issue | Flat payload and stable labels required. |

## Speed And Algorithm Rows

| Capability | Julia engine | R bridge | Inference | Priority issue/gate | Evidence boundary |
| --- | --- | --- | --- | --- | --- |
| Analytic Laplace gradients | partial | unsupported | partial | GLLVM #65 | Gamma default is flipped locally after finite-vs-analytic speed/logLik gates; other family defaults remain finite until their benchmark grids pass the same rule. |
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
