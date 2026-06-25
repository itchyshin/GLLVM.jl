# Check Log

## 2026-06-25 - Gaussian X_lv bridge endpoint

### Scope

Exposed the native ordinary Gaussian predictor-informed latent-score path through
the Julia bridge, without widening the public claim beyond point estimates.

- Added `X_lv` to `bridge_fit()` for complete-response `family = "gaussian"`
  fits only.
- Preserved the existing Gaussian bridge convention by centering responses by
  trait means, returning those means as `alpha`, and fitting
  `fit_gaussian_gllvm(Yc; X_lv = X_lv)` on the centred matrix.
- Added flat JuliaCall payload fields for the R side:
  `lv_effects = Lambda * alpha_lv'`, raw `alpha_lv`, `scores_mean`, and
  `scores_innovation`. The existing `scores` field remains the total rotated
  latent score.
- Added `predictor_informed_lv` to `bridge_capabilities()` so this route is not
  conflated with ordinary fixed-effect `X`.
- Rejected simultaneous `X` + `X_lv`, masks + `X_lv`, mixed-family `X_lv`,
  non-Gaussian `X_lv`, `d = 0`, and `ci_method != "none"` with explicit errors.
- Updated the parity/changelog/roadmap docs to describe this as a Gaussian
  point-estimate endpoint only; R-package row promotion remains gated.

### Checks Run

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: dependencies instantiated after a fresh worktree initially could not
precompile `GLLVM` because `Distributions` was absent from the local depot. This
left no `Project.toml` / `Manifest.toml` changes.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 19/19` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `bridge capabilities ledger 42/42` pass.

```sh
julia --project=. --startup-file=no test/test_lv_predictor.jl
```

Result: `predictor-informed latent-score mean 24/24` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
```

Result: `bridge fixed-effect X (non-Gaussian one-part families) 179/179` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `bridge CI routing 64/64` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `bridge missing-response mask 83/83` pass.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build completed. It emitted the existing
absolute-style local-link warnings, npm audit warnings from the Vitepress
toolchain, and skipped deployment outside CI; no build failure.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `GLLVM.jl 4540 pass, 3 broken, 4543 total` in `43m39.1s`.
The run reported that Aqua and JET were not in the direct project environment
and should be covered by `Pkg.test()`.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: `GLLVM.jl 4552 pass, 1 broken, 4553 total`; `GLLVM tests passed` in
`46m58.8s`.

```sh
git diff --check
```

Result: clean before the dev-log edits.

```sh
rg -n "predictor-informed latent-score|X_lv|lv_effects|scores_mean|scores_innovation|non-Gaussian X_lv|full R-user parity|R-bridge promotion|R-package row promotion" src test docs/src README.md CHANGELOG.md
```

Result: matches were the intended bridge guards, payload tests, capability note,
and claim-boundary docs. No broad R-Julia parity or non-Gaussian `X_lv` claim was
found.

### Deliberately Not Run

- No live R-side `gllvmTMB` bridge test was run in this Julia PR. The paired R
  admission should be a separate `gllvmTMB` slice after this endpoint is merged
  and available to the R bridge.
- No binary/non-Gaussian `X_lv` Julia bridge route was attempted. Native
  constrained-ordination machinery is related, but it is not this flat bridge
  contract and needs a separate recovery/parity design.

### Claim Boundary

IN: complete-response ordinary Gaussian `bridge_fit(...; family = "gaussian",
X_lv = X_lv)` point estimates with total scores, score mean/innovation
decomposition, raw `alpha_lv`, and rotation-stable `lv_effects`.

PARTIAL: this is an endpoint contract against the native Gaussian
`fit_gaussian_gllvm(...; X_lv=...)` oracle. It is not yet an R-package row
promotion, interval route, or missing-response route.

PLANNED/GATED: non-Gaussian `X_lv` bridge rows, binary/probit bridge parity,
simultaneous `X` + `X_lv`, masks + `X_lv`, and confidence intervals remain
separate validation gates.

## 2026-06-22 - Fixed-zero shared X coefficients

### Scope

Added Julia-side fixed-zero coefficient masks for the R-side `Xcoef_fixed`
contract that landed in `gllvmTMB` PR #536.

- `fit_gaussian_gllvm(..., β_fixed = ...)` now optimises only free shared
  Gaussian covariate coefficients, expands `pars.β` back to the full design
  length, and stores `pars.β_fixed`.
- `fit_gllvm_cov(..., γ_fixed = ...)` does the same for non-Gaussian one-part
  shared covariate coefficients and stores `fit.γ_fixed`.
- The bridge accepts `options["coef_fixed"]` / `xcoef_fixed` / `beta_fixed` /
  `gamma_fixed`, passes the mask to the native fitter, returns full coefficient
  vectors with constrained entries equal to zero, and reports
  `mean_coef_status` or `gamma_status`.
- Wald/profile/bootstrap CI term lists and refits omit fixed coefficients from
  the estimated parameter vector while preserving original coefficient indices
  in names such as `beta[1]`, `gamma[3]`.
- AIC/BIC degrees of freedom count free coefficients, not fixed-zero entries.

### Checks Run

```sh
julia --project=. --startup-file=no -e 'using GLLVM; println("loaded")'
```

Result: package loaded cleanly after the new helper include.

```sh
julia --project=. --startup-file=no -e 'include("test/test_fixed_effects.jl"); include("test/test_covariates.jl"); include("test/test_bridge_x.jl")'
```

Result: `fixed effects 18/18`, `Non-Gaussian covariates (Xβ) 30/30`, and
`bridge fixed-effect X 179/179` pass.

```sh
julia --project=. --startup-file=no -e 'include("test/test_confint_bootstrap.jl")'
```

Result: `parametric bootstrap CI 9/9` pass.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `GLLVM.jl 4495 pass, 3 broken, 4498 total` in 31m04.9s before the final
docstring/unused-local cleanup.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: `GLLVM.jl 4507 pass, 1 broken, 4508 total`; `GLLVM tests passed` in
36m15.0s.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build completed. It emitted existing local-link
warnings for absolute-style documentation links, npm audit warnings from the
Vitepress toolchain, and skipped deployment outside CI; no build failure.

```sh
julia --project=docs --startup-file=no docs/make.jl
```

Result: rerun after the changelog edit completed with the same known
DocumenterVitepress/local-link/npm warnings and no build failure.

```sh
git diff --check
```

Result: clean.

```sh
rg -n "selects variables|automatic deletion|guarantees convergence|proves identifiability|validated item selection|separation solved|nonzero constraint|non-zero constraint|general constraint" README.md docs/src src test
```

Result: no matches.

### Deliberately Not Run

- Cross-repository live R-to-Julia bridge tests were not rerun here; the paired
  R-side `Xcoef_fixed` implementation and merge were validated in `gllvmTMB`
  PR #536. This Julia PR supplies the engine/bridge endpoint used by that
  contract.

### Claim Boundary

IN: zero-only fixed shared coefficients for complete fixed-effect-X Gaussian and
non-Gaussian one-part fits already supported by the Julia fixed-X bridge.

PARTIAL: this is not a general linear-constraint system and does not estimate
nonzero fixed values. Julia receives positional masks; the R package owns
formula-name to position translation.

PLANNED/GATED: fixed coefficients combined with X+mask routes, NB1-X,
mixed-family-X, ordinal-X, and structural-covariance-X bridge rows remain
separate follow-ups.

## 2026-06-16 - Fixed-effect-X CI bridge endpoints

### Scope

Admitted complete-response fixed-effect-X Wald/profile/bootstrap CI payloads for
the bridge rows whose native fitters already route `X`: Gaussian, Poisson,
Bernoulli binomial, NB2, Beta, and Gamma.

- Added `_bridge_compute_ci_cov()` so `GllvmCovFit` bridge rows call native
  `confint(fit, Y; X = X, N = N, method = ...)` and return the existing flat
  CI payload contract.
- Threaded `ci_method`, `ci_level`, `ci_nboot`, and `ci_seed` through
  `_bridge_fit_onepart_cov()`.
- Added `ci_x_wald`, `ci_x_profile`, and `ci_x_bootstrap` capability columns.
  These are true only for Gaussian, Poisson, Binomial, NB2, Beta, and Gamma.
- Kept NB1-X, ordinal-X, ordinal-probit-X, mixed-family-X, and masks with
  fixed-effect X gated.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `40/40` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
```

Result: `169/169` pass, including fixed-effect-X Wald parity against native
`confint()` for Poisson, Bernoulli binomial, NB2, Beta, Gamma, and Gaussian,
plus small Poisson-X profile parity and bootstrap smoke.

### Deliberately Not Run

- Full `Pkg.test()` / `test/runtests.jl` was not run for this narrow bridge
  endpoint slice. The touched surface is `src/bridge.jl` plus the fixed-X,
  capability, and bridge-CI tests, which were run directly.
- Documenter was not rebuilt locally.
- The paired R bridge admission is a separate commit in `gllvmTMB`; this Julia
  entry records only the engine-side endpoint route.

### Claim Boundary

IN: complete-response fixed-effect-X bridge CI payloads for Gaussian, Poisson,
Bernoulli binomial, NB2, Beta, and shared-Gamma rows.

PARTIAL: this is endpoint-routing parity against native GLLVM.jl CI engines,
not broad native `gllvmTMB` parity, coverage calibration, or speed evidence.

PLANNED/GATED: NB1-X CIs, ordinal-X CIs, mixed-family-X CIs, masks combined
with fixed-effect X, structured-dependence bridge rows, and per-trait Gamma
expansion remain follow-ups.

## 2026-06-16 - Masked no-X CI bridge endpoints

### Scope

Admitted response-mask no-X Wald/profile/bootstrap CI payloads for the one-part
non-Gaussian bridge rows whose likelihoods already route masks: Poisson,
Bernoulli binomial, NB2 grouped, NB1 grouped, Beta grouped, and Gamma grouped.

- `confint(fit, Y; ...)` now accepts `mask` for scalar and grouped one-part
  non-Gaussian fit types and passes it to the likelihood closure and bootstrap
  refits.
- `bridge_fit()` now passes the observed-cell mask into the non-Gaussian CI
  route instead of stopping for all masked CIs.
- `bridge_capabilities()` now separates `missing_response` from
  `ci_mask_wald` / `ci_mask_profile` / `ci_mask_bootstrap`.
- Per-trait ordinal CIs, Gaussian masks, mixed-family masks, X+mask, variational
  masked CIs, and X-row CIs remain gated.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `83/83` pass. This includes masked Wald routing across Poisson,
Binomial, NB2, NB1, Beta, and Gamma; masked profile/bootstrap smoke for Poisson;
and sentinel-invariance checks for masked Poisson CIs.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `37/37` pass after adding the `ci_mask_*` capability columns.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass; complete-response CI routing was unchanged by the new
mask keyword.

Paired live R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly with `0` failures after the R admission patch.

```sh
git diff --check
```

Result: clean.

### Not Run

- Full `Pkg.test()` / `test/runtests.jl`.
- Documenter build.

### Rose Boundary

PASS WITH NOTES. This admits masked no-X CI endpoints for named one-part
non-Gaussian rows only. It does not claim CI calibration, broad R/TMB parity,
ordinal intervals, mixed-family intervals, X-row intervals, or structured terms.

## 2026-06-16 - Grouped-dispersion `getLV()` bridge scores

### Scope

Added conditional latent-score extraction for the grouped-dispersion fit types
used by the R bridge: `NBGroupedFit`, `NB1GroupedFit`, `BetaGroupedFit`, and
`GammaGroupedFit`.

- `src/families/grouped_dispersion.jl` now has a shared grouped Laplace-mode
  helper and `getLV()` methods for NB2, NB1, Beta, and Gamma grouped fits.
- `bridge_fit()` already called `getLV()` for those rows; before this slice the
  missing methods made `_bridge_scores()` degrade to a `0 x 0` score payload.
  After this slice, grouped bridge rows return finite `n x K` scores.
- No grouped likelihood, optimizer, parameterisation, dispersion scale, CI
  route, or Gamma shared-group policy changed.

### Checks Run

```sh
julia --project=. -e 'using GLLVM; ... grouped bridge/getLV probe ...'
```

Result before the fix: direct grouped `getLV()` calls failed with
`MethodError: no method matching getLV(::NBGroupedFit, ...)` and analogous
errors for NB1, Beta, and Gamma; `bridge_fit()` returned `size(scores) = (0, 0)`.

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `81/81 pass`. The test now checks finite `bridge_fit().scores` for
NB2, NB1, Beta, and Gamma grouped rows and direct finite `getLV()` outputs with
and without a mask.

```sh
julia --project=. test/test_bridge_capabilities.jl
```

Result: `34/34 pass`.

```sh
julia --project=. -e 'using GLLVM; Y=[1 3 2 4 5 2 3 6 4 7; 2 1 4 3 5 6 7 4 8 6]; br=bridge_fit(; y=Float64.(Y), family="nb1", d=1); println(size(br.scores)); println(all(isfinite, br.scores)); println(size(br.loadings));'
```

Result: `(10, 1)`, `true`, `(2, 1)`.

```sh
julia --project=. test/test_bridge_missing_mask.jl
```

Result: `37/37 pass`.

Paired live R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
Rscript --vanilla -e 'options(gllvmTMB.GLLVM.jl.path = "/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration"); devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly with 0 failures.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This admits grouped conditional score payloads for R-side
post-fit reconstruction. It does not add grouped-dispersion CI endpoints,
simulation, extractor parity, newdata prediction, structured terms, or broad
native-vs-Julia validation beyond the existing fixture evidence.

## 2026-06-16 - Gamma shared bridge route

### Scope

Changed the Julia bridge default for `family = "gamma"` from per-trait grouped
Gamma (`group = 1:p`) to one shared grouped-Gamma shape (`group = fill(1, p)`).
This matches current native `gllvmTMB` ordinary Gamma, where one scalar
`sigma_eps` coefficient of variation is shared across Gamma traits.

- `src/bridge.jl` still uses `fit_gamma_gllvm_grouped()`; only the group
  assignment changes.
- The per-trait grouped Gamma engine remains available for a later native
  per-trait Gamma expansion.
- `test/test_bridge_grouped_dispersion.jl` now expects Gamma `df =
  p + rr_df + 1` and `dispersion_group_id = fill(1, p)`, while NB2/NB1/Beta
  remain per-trait grouped.

### Checks Run

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `49/49 pass`.

```sh
julia --project=. test/test_bridge_capabilities.jl
```

Result: `34/34 pass`.

Paired R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly. The paired R test reports Gamma small-fixture
native-vs-Julia point parity: Julia `logLik = 17.595906505513`, native TMB
`logLik = 17.595906784863`, `df = 5` in both engines, and public Gamma
`sigma` matching native `sigma_eps` to about `6e-10`.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is current-oracle Gamma point parity for one small complete
balanced reduced-rank bridge fixture. It does not implement native per-trait
Gamma CV/shape, Gamma CIs, masks, fixed-effect covariates, structured terms, or
speed claims.

## 2026-06-16 - NB1 tiny-phi Fisher boundary fix

### Scope

Fixed a numerical instability in the NB1 Fisher-information helper near the
Poisson boundary. `_nb1_fisher_mu(mu, phi)` previously evaluated the exact
trigamma-difference expression down to `phi ~= 1e-9`, where cancellation made
the expected information collapse to `1e-12` or spike far above the Poisson
limit. The grouped NB1 reduced-rank bridge then over-rewarded boundary fits.

- `src/families/negbin1.jl` now uses the Poisson-limit information
  `1 / (mu * (1 + phi))` for `phi <= 1e-6`.
- `test/test_nb1.jl` adds a boundary regression test for `phi = 1e-8` and
  `1e-9`, plus a near-boundary guard at `1e-5`.
- No NB1 parameterisation changed: the scale remains
  `Var(y) = mu * (1 + phi)`.

### Checks Run

```sh
julia --project=. test/test_nb1.jl
```

Result: `34/34 pass`.

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `49/49 pass`.

```sh
julia --project=. test/test_grouped_dispersion_tweedie_nb1.jl
```

Result: `15/15 pass`.

Paired R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly. The NB1 reduced-rank small fixture now reports
native `logLik = -52.4618425767`, Julia `logLik = -52.4619219625`, `df = 6`
for both, and delta `-7.9386e-05`. Evaluating Julia at the native fitted
parameters gives `-52.4618425607`, matching native TMB to about `1.6e-08`.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This fixes a Julia NB1 boundary numerical bug and supports the
small-fixture reduced-rank bridge parity row. It does not promote broad NB1
simulation recovery, NB1 confidence intervals, masks, fixed-effect covariates,
or structured terms.

## 2026-06-16 - Bridge no-latent NB1 admission

### Scope

Relaxed the Julia `bridge_fit()` latent-rank gate from positive `d` to
non-negative `d`, allowing the R bridge to request no-latent (`d = 0`) rows.
The immediate verified row is grouped NB1 with no latent variables: two trait
intercepts plus two per-trait NB1 `phi` values, no loading parameters.

- `src/bridge.jl` now rejects only `d < 0`.
- `test/test_bridge_grouped_dispersion.jl` adds a no-latent NB1 bridge row and
  keeps the negative-rank rejection locked.
- No family likelihood, parameterisation, optimiser, or CI route changed.

### Checks Run

```sh
gh pr list --state open --json number,title,headRefName,baseRefName,updatedAt,isDraft --limit 20
```

Result: two older draft PRs visible (`#95` integration, `#94`
`a1-nongaussian-ci`); no active PR on this local branch.

```sh
git log --all --oneline --since="6 hours ago" -- src/bridge.jl test/test_bridge_grouped_dispersion.jl docs/dev-log/check-log.md docs/dev-log/after-task | head -120
```

Result: current local bridge commits only (`2a07745`, `5cb7ea5`).

```sh
julia --project='.' -e 'using GLLVM; Y=[1 3 2 4 5 2 3 6 4 7 5 8; 2 1 4 3 5 6 7 4 8 6 9 7]; fit=GLLVM.fit_nb1_gllvm_grouped(Y; K=0, group=collect(1:size(Y,1)), iterations=200); println(fit); println(GLLVM._nparams(fit)); println(size(GLLVM._loadings(fit))); println(fit.loglik); println(fit.converged)'
```

Result: `NB1GroupedFit(p=2, K=0, G=2, ...)`, `_nparams = 4`,
`size(Lambda) = (2, 0)`, finite log-likelihood, `converged = true`.

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `49/49 pass`.

```sh
rg -n "d must be a positive integer|d must be a non-negative integer|d = 0|K = 0|no-latent|full parity|complete bridge|CRAN-ready" src/bridge.jl test/test_bridge_grouped_dispersion.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-16-bridge-no-latent-nb1.md
```

Result: expected no-latent / `d = 0` hits, the new non-negative error string in
`src/bridge.jl`, and historical negative-scope wording only.

```sh
git diff --check
```

Result: clean.

Paired live R bridge fixture after this Julia edit:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla - <<'RS'
# fitted gllvmTMB(value ~ 0 + trait, family = nbinom1()) through
# engine = "julia" and engine = "tmb"; compared logLik, df, and phi.
RS
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: Julia and native TMB
both reported `logLik = -53.17549`, `df = 4`; `delta = 4.253763e-08`;
maximum absolute NB1 `phi` difference was `5.42191e-05`.

### Rose Boundary

PASS WITH NOTES. This admits no-latent bridge rows at the Julia transport layer
and verifies grouped NB1. It does not promote reduced-rank NB1 parity, grouped
CI endpoints, masks, mixed-family rows, or structured terms.

## 2026-06-15 - Bridge method capability metadata

### Scope

Expanded `GLLVM.bridge_capabilities()` with method-level metadata needed by the
R-first `gllvmTMB` bridge ledger.

- Added no-X CI capability columns for Wald, profile, and bootstrap routes.
- Added in-sample post-fit method columns for coefficient payloads, fit
  statistics, summary, prediction, residuals, simulation, and ordination.
- Kept the existing fitters, likelihoods, REML behavior, optimizer behavior, and
  CI implementations unchanged.
- Documented that `ci_no_x_*` columns are scoped to complete one-part
  no-covariate fits only.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. -e 'using GLLVM; caps=GLLVM.bridge_capabilities(); @assert :ci_no_x_wald in propertynames(caps); @assert :postfit_predict in propertynames(caps); println(length(caps.family), " capability rows")'
```

Result: `10 capability rows`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `19/19 pass` in `0.2s`.

Paired live R bridge regression:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 519` in `68.9s`.

### Rose Boundary

PASS WITH NOTES. This is metadata for R-side drift prevention, not new engine
support. REML remains Gaussian-only; AI-REML remains a later exact-Gaussian
speed idea only.

## 2026-06-15 - Mixed-family bridge per-trait payload labels

### Scope

Fixed the Julia-side mixed-family bridge payload so the flat `families` field is
row-aligned with the input family vector instead of repeating the joined model
tag.

- `bridge_fit(; family = ["gaussian", "poisson", "binomial"])` still returns
  `family = "gaussian+poisson+binomial"` as the compact model tag.
- The same payload now returns `families = ["gaussian", "poisson", "binomial"]`
  and per-trait `link = ["IdentityLink", "LogLink", "LogitLink"]`.
- `_bridge_assemble` now accepts an optional per-trait `families` vector and
  rejects malformed lengths.
- `test/test_bridge_mixed.jl` locks the successful payload shape, the mixed CI
  unavailable-status payload, and the length-mismatch failure path.
- `docs/src/gllvmtmb-parity.md` now records the exact boundary: Julia mixed
  metadata is fixed; R bridge admission and parity remain queued.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_mixed.jl
```

Result: `18/18 pass` in `5.7s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.1s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM; Y = [0.2 0.4 -0.1 0.3 0.5 -0.2 0.1 0.6; 1 3 2 4 1 2 5 3; 0 1 1 0 1 0 1 1]; br = bridge_fit(; y=Y, family=["gaussian","poisson","binomial"], d=1); println(join(br.families, ",")); brci = bridge_fit(; y=Y, family=["gaussian","poisson","binomial"], d=1, options=Dict("ci_method"=>"wald")); println(brci.ci_method); println(length(brci.ci_param_names));'
```

Result:

```text
gaussian,poisson,binomial
wald
0
```

Paired live R bridge regression:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 439` in `65.2s`.

### Rose Boundary

PASS WITH NOTES. Julia mixed-family bridge metadata is now correctly row-aligned,
but `gllvmTMB` still rejects mixed-family `engine = "julia"` fits until
point/logLik parity, labels, and CI-status rows are validated together.

## 2026-06-15 - R-first handoff and roadmap sync

### Scope

Reframed the historical Codex handoff and roadmap so they no longer read as a
current release or bridge-completion claim.

- `docs/dev-log/CODEX_HANDOFF.md` now starts with a 2026-06-15 note: the current
  finish sequence is R-first, native `gllvmTMB` is the oracle, and broad
  engine-side rows still require R-side admission, bridge parity, docs, issue
  evidence, and Rose audit.
- The old TL;DR phrase "full gllvmTMB parity and beyond" was narrowed to
  "broad engine-side parity candidate".
- `docs/src/roadmap.md` now uses the same R-first sequencing, conservative
  release map, and Gaussian-only REML / exact-Gaussian AI-REML boundary.

No engine code, bridge code, tests, or benchmarks changed.

### Checks Run

```sh
rg -n "full gllvmTMB parity|full parity|AI-REML|REML|R-first|engine-side parity candidate" docs/dev-log/CODEX_HANDOFF.md docs/src/roadmap.md
```

Result: expected hits only. "Full parity" appears only in a warning not to read
the historical handoff as a current release claim. REML/AI-REML hits are
boundary wording only.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is documentation governance only. It does not add a new
engine capability or R bridge row.

## 2026-06-15 - Ordinal-Probit Bridge Mask Key

### Scope

Added a distinct `ordinal_probit` bridge family key so the R
`gllvmTMB::ordinal_probit()` constructor routes to cumulative-probit ordinal
GLLVM fits instead of the cumulative-logit `ordinal` default.

- `bridge_fit(...; family = "ordinal_probit", mask = M)` now calls
  `fit_ordinal_gllvm(..., link = ProbitLink(), mask = M)`;
- bare `family = "ordinal"` remains cumulative-logit;
- masked no-X one-part family evidence now covers Poisson, Bernoulli Binomial,
  NB2, Beta, Gamma, and Ordinal-probit from the R bridge.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl
```

Result: `23/23 pass` in `16.8s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: `66/66 pass` in `46.2s`.

Paired live R bridge:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result: `232/232 pass` in `50.9s`.

### Rose Boundary

PASS WITH NOTES. This proves the bridge family key, probit-link routing, and
R-live masked no-X family matrix. It does not add masked CI refits, X+mask,
Gaussian masks, or ordinal prediction/residual payloads.

## 2026-06-15 - Bridge Missing-Response Mask Hook

### Scope

Added the minimal Julia transport hook needed by the R-first
`gllvmTMB(..., engine = "julia", missing = miss_control(response = "include"))`
slice:

- `bridge_fit(...; mask = M)` now accepts a `p x n` observed-cell mask
  (`true = observed`) for one-part no-X non-Gaussian families;
- all-true masks normalize to the complete-data bridge path;
- Gaussian masks, X+mask, mixed-family masks, and masked CI requests fail
  before fitting;
- bridge latent scores and latent-scale summaries call the mask-aware
  post-fit/link-residual paths so sentinel placeholders do not influence
  predictions or correlations.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl
```

Result: `17/17 pass` in `15.5s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: `52/52 pass` in `18.9s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: `66/66 pass` in `46.1s`.

```sh
~/.juliaup/bin/julia --project=. -e 'using Test, GLLVM, Distributions; include("test/test_missing_data.jl")'
```

Result: `34/34 pass` in `12.5s`. The direct file form needs
`Distributions` loaded because the standalone test file assumes the full
`test/runtests.jl` include context.

```sh
~/.juliaup/bin/julia --project=. test/test_postfit.jl
```

Result: post-fit family blocks passed (`96/96`, `9/9`, `10/10`, `8/8`,
`163/163`, `160/160`, `215/215`, `215/215`, `216/216`).

```sh
~/.juliaup/bin/julia --project=. test/test_confint_family.jl
```

Result: `122/122 pass` in `4m15.5s`.

### Rose Boundary

PASS WITH NOTES. This is a bridge transport and post-fit correctness hook, not
full missing-data release readiness. Masked CI refits, X+mask, Gaussian masks,
and per-family R-side parity rows remain separate gates.

## 2026-06-15 - gllvmTMB Bridge X Admission Status Sync

### Scope

Synced `docs/src/gllvmtmb-parity.md` with the current R-side
`gllvmTMB(..., engine = "julia")` bridge surface:

- complete, balanced one-part no-X reduced-rank bridge fits are admitted for
  Gaussian, Poisson, Binomial, NB2, Beta, Gamma, and Ordinal;
- fixed-effect `X` is admitted for complete, balanced one-part Gaussian,
  Poisson, Binomial, NB2, Beta, and Gamma bridge fits;
- response-missing masks, mixed-family bridge metadata, ordinal covariate fits,
  structured terms, and user-selectable Julia optimizer controls remain explicit
  follow-ups;
- REML wording is Gaussian-only, and HSquared-style AI-REML is recorded as a
  later exact-Gaussian scouting target, not non-Gaussian Laplace terminology.

Also updated `docs/dev-log/codex-fast-algorithms-brief.md` with the same REML /
AI-REML boundary.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: 50/50 passed in 18.0s.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is a documentation/status-sync slice only. It does not
claim new Julia engine behavior beyond the already-tested `bridge_fit(...; X=...)`
contract, and it does not claim non-Gaussian REML or AI-REML.

## 2026-06-15 - PR #94 Successor Issue Drafts

### Scope

Converted the `GLLVM.jl#94` unique-content audit into a local successor-issue
draft bank without mutating GitHub remotely.

The draft bank now contains seven durable successor records:

1. Generalized Poisson family.
2. Student-t one-part family.
3. True one-part lognormal family.
4. Standalone zero-truncated Poisson/NB.
5. ANOVA/LRT model-comparison API.
6. Unified check-fit diagnostics, calibration, and plots.
7. Structured Schur / structured Poisson prototype.

Stale #94 benchmark-script notes are routed to existing benchmark/runtime
issues (`#65` and `#61`) rather than duplicated as a new issue.

### Checks Run

```sh
gh issue list --repo itchyshin/GLLVM.jl --state open --limit 100 --json number,title,labels,updatedAt,url
gh issue list --repo itchyshin/gllvmTMB --state open --limit 100 --json number,title,labels,updatedAt,url
gh pr view 94 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
gh pr view 95 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
git log --oneline 65a1f10..HEAD --reverse
```

Live PR state at drafting time:

- `#94` open draft, conflicting, `a1-nongaussian-ci` at `09fc846`.
- `#95` open draft, mergeable, `integration` at `65a1f10`.
- local runtime stack head before this draft slice: `862f081`.

### Rose Boundary

PASS WITH NOTES. Do not close `#94` yet. Close only after the seven durable
successor records exist and the benchmark-script notes are routed into existing
benchmark issues. No GitHub issue, PR comment, closure, or push was performed in
this slice.

## 2026-06-15 - PR #94 Unique-Content Audit

### Scope

Audited draft/conflicting `GLLVM.jl#94` before closure or supersession.

Live state at audit time:

- `#94` open draft, conflicting, `a1-nongaussian-ci` at `09fc846`
- `#95` open draft, mergeable, `integration` at `65a1f10`
- local integration audit head: `d3d8129`

### Checks Run

```sh
gh pr view 94 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
gh pr view 95 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
git fetch origin pull/94/head:refs/remotes/origin/pr-94 pull/95/head:refs/remotes/origin/pr-95 main integration
```

Blob classification of `origin/main...origin/pr-94` paths against current local
integration:

| class | count |
| --- | ---: |
| absent from integration | 124 |
| present but different from local integration | 50 |
| byte-identical to local integration | 2 |

### Rose Boundary

PARTIAL BUT ACTIONABLE. Do not merge `#94`. Treat it as an archive to mine into
successor issues for Generalized Poisson, Student-t, standalone lognormal,
standalone zero-truncated count families, ANOVA/LRT, diagnostics, structured
Schur/Poisson prototypes, and stale benchmark rebuilds. Close only after those
successor issues/comments exist.

## 2026-06-15 - Test Warning Hygiene

### Scope

Removed duplicate-method warnings from the core and full package test logs:

- `test/test_takahashi_selinv.jl` now uses the package-loaded
  `GLLVM.takahashi_selinv` and `GLLVM.takahashi_diag` implementations instead
  of self-including `src/takahashi_selinv.jl` into `Main`;
- `test/test_bridge_ci.jl` renamed its local Poisson simulator helper to avoid
  overwriting the helper in `test/test_confint_family.jl` during full-suite
  execution.

No production source changed in this slice.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_takahashi_selinv.jl
```

Result: 8/8 passed in 0.4s, with no duplicate-method warning.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: 66/66 passed in 45.4s.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.0s. The previous
`takahashi_selinv.jl` and `_sim_poisson` overwrite warnings did not reappear.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m12.0s. The duplicate-method
warnings did not reappear under Pkg's temporary test environment.

### Rose Boundary

PASS. This is test-harness hygiene only. It reduces warning noise and does not
change model behavior, likelihoods, fitters, bridge payloads, or public API.

## 2026-06-15 - Sparse Phylo Node-Gradient Shortcut

### Scope

Wired the verified node-frame O(p) gradient into the public sparse phylo
gradient dispatcher for the phylo-unique shape only:

- `K_aug == 1`
- `K_phy == 0`
- `has_unique == true`

All other augmented sparse-phylo gradient shapes still route through the exact
leaf-block fallback (`_sparse_phy_grad_leafblock`). The fallback remains the
reference for `Λ_phy` and mixed augmented shapes because those derivatives need
the dense leaf-row x leaf-column block.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_node_gradient.jl
```

Result: 58/58 passed in 9.7s. The node route was checked against dense
ForwardDiff and the preserved leaf-block reference on balanced and caterpillar
trees. Max relative node-vs-leaf-block error for the `σ_phy` block was
`1.015e-13`; scalar/global blocks were zero or machine precision.

```sh
~/.juliaup/bin/julia --project=. test/test_sparse_phy_grad.jl
```

Result: 101/101 passed in 7m12.1s. The end-to-end sparse/dense value
consistency gate reported `8.731e-11` logLik difference at the sparse optimum;
the warm-start comparison to `fit_gaussian_gllvm` had `Δll_warm = 2.092e-5`.

```sh
~/.juliaup/bin/julia --project=. bench/sparse_phy_grad_bench.jl
```

Result:

| p | shortcut ms | leafblock ms | speedup | dense-FD ms | max rel err |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 100 | 0.344 | 1.027 | 2.99x | 198.884 | 8.76e-15 |
| 300 | 1.117 | 3.670 | 3.29x | skipped | 2.28e-14 |
| 600 | 1.114 | 24.030 | 21.58x | skipped | 7.11e-15 |

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.2s.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m36.2s.

### Rose Boundary

PASS WITH NOTES. This closes the verified phylo-unique node-gradient wiring
slice only. It does not claim O(p) for `Λ_phy`, mixed augmented phylo effects,
or any non-Gaussian Laplace adjoint route. The full package gate passed, but the
suite still emits pre-existing duplicate-include/helper overwrite warnings that
should be cleaned in a separate hygiene slice.

## 2026-06-14 - JuliaConnectoR R gllvm Parity Smoke

### Scope

Closed the first R `{gllvm}` vs GLLVM.jl JuliaConnectoR parity smoke gap:

- `gllvm_jl_init()` now accepts `jl_path` and defaults to `GLLVM_JL_PATH`,
  activating the local Julia project before importing `GLLVM`;
- the standalone fallback in `r/gllvmtmb_julia.R` mirrors the same activation
  path;
- `r/parity_check.R` scales R `{gllvm}` `params$theta` by `params$sigma.lv`
  before Procrustes-aligned loading comparison.

The previous apparent Poisson mismatch was harness drift: Julia could import a
stale/default-environment `GLLVM`, and the R loadings were compared before the
latent-variable scale was applied.

### Checks Run

```sh
JULIA_BINDIR=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin \
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(jl_path=Sys.getenv("GLLVM_JL_PATH")); set.seed(1); y <- matrix(rpois(30*4,3), nrow=30); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", row.eff="none"); stopifnot(res$diffs$logLik < 1e-6, res$diffs$beta["abs"] < 1e-5, res$diffs$loadings["abs"] < 1e-5)'
```

Result: exit code 0.

```text
logLik absolute diff: 2.086e-11
beta max abs diff:   1.760e-07
loadings max abs:    6.559e-07
```

### Rose Boundary

PASS WITH NOTES. This is one live Poisson `method="LA"` no-row-effect parity
smoke. It proves the scaffold can hit the same likelihood target when the local
project is activated and R loadings are scale-mapped. It does not prove full
family, dispersion, covariate, missingness, R-bridge, or CI parity.

## 2026-06-14 - Rose Status Drift Cleanup

### Scope

Cleaned public/status drift found by the Rose audit after the runtime-gap fixes:

- `AGENTS.md` no longer describes the integration tree as the old v0.1
  Gaussian-only pilot;
- `README.md` now states that Gamma joins Poisson, NB2, Binomial, and Beta in
  the analytic-gradient default set for no-mask/no-offset fits;
- `docs/dev-log/CODEX_HANDOFF.md` now treats v0.3.0 tagging as a
  maintainer-gated release-ledger decision, not an automatic next command.

No source code, tests, Project version, or R bridge code changed in this slice.

### Checks Run

Stale wording scan:

```sh
rg -n "v0\\.1\\.0 pilot|Gaussian only|Gamma and the|bump `Project.toml` to v0\\.3\\.0 and|tag a release" AGENTS.md README.md docs/dev-log/CODEX_HANDOFF.md
```

Result: no matches.

Whitespace:

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is a wording/ledger cleanup only. It does not merge
`GLLVM.jl#95`, close `GLLVM.jl#94`, update remote issues #91/#92/#96, validate
the R `{gllvm}` statistical parity gate, or authorize a tag.

## 2026-06-07 - Analytic Gradient Defaults

### Scope

Runtime-gated the dormant analytic Laplace gradients. Poisson, NB2, Binomial,
and Beta defaulted to `gradient = :analytic` on the plain no-mask/no-offset path,
preserving the existing finite-difference fallback. At that time Gamma was left
finite because the benchmark gate found accuracy failures; the Gamma decision is
superseded by the 2026-06-14 entry below.

### Benchmark Evidence

Fitter-only run using the `bench/speed_bench.jl` simulators and timing logic
(`reps = 1`, `iterations = 300`; the full script stalled in profile-CI before
printing its final table):

| size | family | finite s | analytic s | speedup | delta logLik | gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 20x100x2 | Poisson | 2.592 | 0.274 | 9.46x | -9.09e-13 | pass |
| 20x100x2 | NB2 | 4.276 | 0.383 | 11.16x | -1.82e-12 | pass |
| 20x100x2 | Binomial | 4.719 | 0.416 | 11.33x | 3.18e-12 | pass |
| 20x100x2 | Beta | 15.511 | 1.261 | 12.30x | 1.14e-13 | pass |
| 20x100x2 | Gamma | 0.263 | 0.257 | 1.02x | -7.24e-4 | fail |
| 50x200x2 | Poisson | 50.685 | 4.847 | 10.46x | -1.09e-11 | pass |
| 50x200x2 | NB2 | 53.144 | 4.736 | 11.22x | -7.28e-12 | pass |
| 50x200x2 | Binomial | 59.231 | 5.357 | 11.06x | -1.09e-11 | pass |
| 50x200x2 | Beta | 223.527 | 17.699 | 12.63x | 6.37e-12 | pass |
| 50x200x2 | Gamma | 31.894 | 1.925 | 16.56x | 3.93e23 | fail |

### Checks Run

```sh
julia --project=. test/test_laplace_grad.jl
```

Result: 26 passed in 30.7s.

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3296 passed, 1 broken, 3297 total in 27m25.4s. The full suite includes
the quality battery (`test_quality.jl` with Aqua/JET checks).

```sh
tmp=$(mktemp -d /tmp/gllvm-doc-env-XXXXXX)
JULIA_PROJECT="$tmp" julia -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. The direct `julia --project=docs docs/make.jl` path could
not instantiate locally because `GLLVM` v0.3.0 is not registered, so the build
used a temporary docs environment with the local worktree developed. Pre-existing
warnings remain for absolute local links, missing logo/favicon assets, missing
`docs/package.json`, and npm audit reporting 4 moderate vulnerabilities.

```sh
git diff --check
rg -n "finite-difference outer gradients|opt-in today|kept opt-in|finite \\(the current default\\)|Default :finite|flip the package default" README.md docs/src docs/dev-log/CODEX_HANDOFF.md bench src/families/{poisson,negbin,binomial,beta,gamma}.jl test/test_laplace_grad.jl
```

Result: whitespace clean; stale-default wording scan had no matches beyond the
intended Gamma `gradient::Symbol = :finite` when searched separately.

### Rose Verdict

PASS WITH NOTES. The 2026-06-07 default flip was restricted to the four families
that cleared the measured speed/accuracy gate. This Gamma caveat is superseded
by the 2026-06-14 entry below. Remaining note from this historical run:
`bench/speed_bench.jl` should stream fitter rows or make profile-CI optional.

## 2026-06-03 - Homepage Mobile Publication

### Scope

Published a narrow documentation hotfix for the live GLLVM.jl homepage. The
deployed mobile page rendered VitePress `layout: home`, `hero:`, and `features:`
frontmatter as ordinary page text. The homepage now uses plain
Documenter-compatible Markdown and starts as a docs page:

1. package title;
2. one-sentence identity;
3. install command;
4. first model example.

No source code, exported API, likelihood parameterization, or test behavior
changed.

### Checks Run

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0 locally before publication. Documenter and
DocumenterVitepress completed. Residual warnings remain: pre-existing absolute
local links in several article pages (`/quickstart`, `/api`, etc.), deployment
auto-detection skipped, missing `logo.png`/`favicon.ico`, missing
`docs/package.json`, and npm audit reporting 4 moderate vulnerabilities.

Playwright mobile check at 390 x 664 px against a local static server:

- no rendered `layout: home`, `hero:`, or `features:` text;
- no horizontal overflow;
- `Install` visible near the top;
- `Fit your first model` visible in the first phone viewport.

Screenshot evidence:
`/tmp/gllvm-mobile-audit/screens/gllvm_local_mobile_simplified.png`.

```sh
git diff --check
rg -n 'layout: home|hero:|features:|https://https://' docs/src docs/make.jl
rg -n 'Fast Generalised Linear Latent Variable Models|Install|Fit your first model|What works today' docs/build/.documenter/index.md docs/build/1/index.html
```

Result: whitespace clean; no frontmatter tokens in public source; rendered
index contains the install-first order.

### Rose Verdict

PASS WITH NOTES. The live-page source bug is fixed in the publication branch
and the mobile top is screenshot-verified. Remaining notes: full `Pkg.test()`
was not run for this docs-only hotfix, pre-existing article-link warnings remain
outside the homepage hotfix, and the live site updates only after the Documenter
deployment workflow completes.

## 2026-06-14 - High-rate Poisson mode safeguard (#91)

### Scope

Fixed the integration-branch reproduction of GLLVM.jl #91, where the default
analytic-gradient `fit_poisson_gllvm` path could accept a runaway first step for
a high-rate `K = 2` Poisson fit. The root cause was the shared dense-Laplace
inner mode solve: full Fisher-scoring steps could lower the conditional
log-posterior by many orders of magnitude, making the warm-start marginal and
the analytic Poisson gradient invalid.

`src/families/laplace.jl` now keeps full Newton steps near the mode, but uses
step-halving against the conditional log-posterior for the cheap scalar families
where this safeguard is needed (`Poisson`, `Binomial`, `NegativeBinomial`,
`Beta`, `Gamma`, `Exponential`). Heavier bespoke families keep the previous
full-step path to avoid turning their expensive log-density calls into an inner
line search. A one-time restart from `z = 0` remains available when a solve
returns non-finite values.

`test/test_poisson_fit.jl` now carries the high-rate #91 fixture and checks:

1. the fitted intercepts stay on the empirical log-mean scale;
2. the fitted log-likelihood is finite and the optimizer converges;
3. the analytic Poisson Laplace gradient matches a central finite-difference
   gradient on the same high-rate warm start.

### Checks Run

Before the fix, on `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration`
at `65a1f10`, the reconstructed #91 fixture produced:

```text
kind = :allZ_col
analytic_converged = true
analytic_beta6 = -1.3725979588255058e6
fd_beta6 = 3.5848998478056116
beta06 = 2.046028486073364
analytic_maxabs = 1.3726000048539918e6
```

After the fix:

```text
kind = :allZ_col
converged = true
beta6 = 1.8845273881056652
beta06 = 2.046028486073364
maxabs = 0.16150109796769874
loglik = -9573.527202270865

kind = :interleaved_site
converged = true
beta6 = 1.9494694468357439
beta06 = 2.1177137251431333
maxabs = 0.16824427830738942

kind = :global_seed_interleaved
converged = true
beta6 = 1.9931572688527104
beta06 = 2.1386437132753118
maxabs = 0.1454864444226014
```

High-rate warm-start gradient check after the fix:

```text
marg0 = -10049.149835755072
grad analytic norm = 456.8484012361648
finite norm = 456.8484007642873
diff norm = 2.2149188558598164e-6
maxabsdiff = 1.0488242692119343e-6
```

Focused tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_fit.jl
```

Result: `12/12 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_laplace.jl
```

Result: `4/4 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_laplace_grad.jl
```

Result: `26/26 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_missing_response.jl
```

Result: `23/23 pass`; masked analytic-vs-FD max differences remained
`5.42e-8` for Poisson and `2.41e-8` for Binomial.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM, Test, Distributions, LinearAlgebra, Random; include("test/test_laplace_alloc_equiv.jl")'
```

Result: `7/7 pass`.

Affected scalar-family fit tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_nb_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_fit.jl
```

Results: Binomial `8/8`, NB `7/7`, Beta `7/7`, Gamma `7/7` pass.

Affected scalar-family marginal tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_negbin_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_laplace.jl
```

Results: Beta `2/2`, Gamma `2/2`, NB `2/2`, Binomial `9/9` pass.

`test/test_missing_response_extra.jl` was started twice and interrupted after
several minutes both times. The interrupt stack was inside long finite-difference
fits for Tweedie / row-effect wrappers, not in the new Poisson safeguard branch.
Full `test/runtests.jl` and `Pkg.test()` remain the next gates before PR.

### Rose Verdict

PASS WITH NOTES. #91 is reproduced on the integration branch and fixed with a
fit-level regression plus a gradient-vs-FD gate. The safeguard is intentionally
scoped to cheap scalar families to avoid slowing bespoke heavy likelihoods.
Remaining blocker: full-suite validation has not yet been run after this patch.

### 2026-06-14 — #91 full-suite validation and self-contained CI test import

`test/test_confint_family.jl` failed when run directly because the Tweedie
bootstrap test used `dot` without importing `LinearAlgebra`. Added the explicit
test-file import; no package source changed in this cleanup.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_family.jl
```

Result: `122/122 pass` in `4m08.6s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3749 pass, 3 broken, 0 failed, 0 errored` in `30m42.6s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m51.7s`.

Noted quality noise: the `Pkg.test()` sandbox still prints duplicate-method
warnings from repeated local helper definitions (`takahashi_selinv.jl` include
warnings and `_sim_poisson` in `test_confint_family.jl` / `test_bridge_ci.jl`).
They did not fail the gate, but should be cleaned in a later test-hygiene slice.

Rose verdict: PASS WITH NOTES. The #91 safeguard branch is full-suite green on
Julia 1.10; remaining notes are R parity not run (not bridge-facing) and
pre-existing duplicate-helper warning noise in the test harness.

Docs build note: `julia --project=docs docs/make.jl` is blocked locally because
`docs/Project.toml` expects registered package `GLLVM`. A no-deploy temp build
using `Pkg.develop(path=pwd())` reached Vitepress but failed on pre-existing
dead local links (`./quickstart`, `./model`, `./benchmarks`, `./comparison`, and
related extensionless page links). This is a docs-cleanup follow-up, not part of
the #91 numerical change.

### 2026-06-14 — Vitepress dead-link cleanup

Normalised the remaining relative page links in `docs/src/{index,quickstart,
comparison,gllvmtmb-parity}.md` to the existing absolute Vitepress route style.
This removed the hard Vitepress dead-link failure found during local no-deploy
docs validation.

```sh
/Users/z3437171/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.activate(; temp=true); Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); using Documenter, DocumenterVitepress, GLLVM; makedocs(; source="docs/src", build="/tmp/gllvm-docs-build", warnonly=true, ...)'
```

Result: passed; Vitepress built the site successfully in `4.66s`.

Remaining warnings: Documenter still warns on absolute local links (`/quickstart`,
`/api`, etc.) and DocumenterVitepress reports missing optional Vitepress assets /
`docs/package.json`. These are pre-existing warning-level documentation
infrastructure items, not hard build failures after this cleanup.

Rose verdict: PASS WITH NOTES. Hard dead-link blocker removed; warning-level
docs infrastructure cleanup remains.

## 2026-06-14 - Gamma Analytic Gradient Default

### Scope

Re-opened the Gamma analytic-gradient default after the high-rate Poisson
Laplace-mode safeguard. Gamma now joins Poisson, NB2, Binomial, and Beta in
defaulting to `gradient = :analytic` on the plain no-mask/no-offset path, with
the existing finite-difference fallback retained for masked or offset fits.

### Benchmark Evidence

The full original `bench/speed_bench.jl` grid was interrupted after roughly 13
minutes while still in the first grid cell, so the benchmark harness was updated
with opt-in runtime knobs (`GLLVM_SPEED_BENCH_GRID`, `GLLVM_SPEED_BENCH_REPS`,
`GLLVM_SPEED_BENCH_ITERS`, `GLLVM_SPEED_BENCH_PROFILE_CI`) and per-family
progress logging. Default full-run behaviour is unchanged.

Quick decision grid:

```sh
GLLVM_SPEED_BENCH_GRID=quick GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=80 GLLVM_SPEED_BENCH_PROFILE_CI=0 \
  /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma results:

| size | finite s | analytic s | speedup | delta logLik |
| --- | ---: | ---: | ---: | ---: |
| 8x40x1 | 0.2573 | 0.0255 | 10.09x | 2.842e-14 |
| 12x60x1 | 0.6706 | 0.0693 | 9.68x | 2.842e-13 |

Medium confirmation cell:

```sh
GLLVM_SPEED_BENCH_GRID=20,100,2 GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=120 GLLVM_SPEED_BENCH_PROFILE_CI=0 \
  /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma result: finite `10.8304s`, analytic `0.7590s`, speedup `14.27x`,
`delta logLik = -1.819e-12`.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_fit.jl
```

Result: `7/7 pass` in `10.7s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_laplace.jl
```

Result: `2/2 pass` in `2.2s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_laplace_grad.jl
```

Result: `26/26 pass` in `31.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m09.1s`.

### Rose Verdict

PASS WITH NOTES. Benchmark gate and full package tests passed after the default
change. Remaining note: R bridge parity was not rerun because the likelihood
target and bridge payload shape are unchanged.

## 2026-06-14 - JuliaConnectoR Bridge Smoke Repair

### Scope

Repaired the older `r/gllvmjl.R` / `r/gllvmtmb_julia.R` JuliaConnectoR scaffold
enough for a live transport smoke check:

- `gllvm_jl_init()` now loads `Distributions`, so family marker constructors such
  as `Distributions.Poisson()` are available.
- Added `.jl_value()` to tolerate JuliaConnectoR fields that are already
  converted to R values, avoiding double-`juliaGet()` failures on `β`, `loglik`,
  coefficient tables, and Unicode dispersion fields.
- Construct family markers through `Distributions.<Family>()`, not through the
  `GLLVM` module handle.
- Updated bridge README/status prose from "not executed" to
  "transport smoke-tested; parity open."

### Checks Run

```sh
JULIA_BINDIR="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin" \
JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(); set.seed(11); y <- matrix(rpois(30*4, 3), nrow=30); rownames(y) <- as.character(seq_len(nrow(y))); colnames(y) <- paste0("sp", seq_len(ncol(y))); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", disp.formula=~1, iterations=80L); stopifnot(is.finite(res$julia_fit$logLik), all(is.finite(res$julia_fit$coefficients))); print(res$diffs)'
```

Result: command exited `0`; Julia transport returned finite `logLik` and
coefficients.

Parity result: **not passed**. R `{gllvm}` vs GLLVM.jl on the smoke cell:
`|ΔlogLik| = 0.6194035`, max beta diff `0.04862639`, Procrustes-aligned loading
diff `2.862522`.

### Rose Verdict

PARTIAL. Transport defects are fixed and documented, but the end-to-end R
`gllvm` parity claim remains open. Next slice should reconcile likelihood target,
starts, centering, and parameterization before promoting this bridge path.

## 2026-06-14 - Phylo-signal Wald CI Scale Fix (#92)

### Scope

Ported the narrow fix for GLLVM.jl #92 from the stale `a1-nongaussian-ci` branch
onto the current integration branch. The Gaussian phylo fitter packs the
phylo-unique `σ_phy` block on the natural signed scale, but `_derived_unpack`
was exponentiating it. That over-transformed the `phylo_signal_wald_ci` numerator
and could push H² outside `[0, 1]`.

Changes:

- `_derived_unpack` now reads `σ_phy` directly on the natural signed scale.
- `confint_derived_wald.jl` is included by the package and the transformed-Wald
  derived CI helpers are exported.
- `test_confint_derived_wald.jl` now guards packed-vs-public `phylo_signal`
  equality for both `has_phy_unique` and `K_phy > 0` paths.
- `test_confint_derived_wald.jl` is wired into `test/runtests.jl`.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived_wald.jl
```

Result: `108/108 pass` in `21.3s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived.jl
```

Result: `45/45 pass` in `13.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_profile_derived_fix.jl
```

Result: `20/20 pass` in `10.1s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_profile.jl
```

Result: `4/4 pass` in `21.4s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3869 pass, 1 broken, 0 failed, 0 errored` in `36m18.1s`.

### Rose Verdict

PASS. The scale bug is fixed on the current branch, the orphan test is now part
of the main suite, and the full package gate passed.

## 2026-06-15 - Gaussian-X bridge mean coefficient payload

### Scope

Added the flat `mean_coef::Vector{Float64}` payload field to
`GLLVM.bridge_fit(...; family = "gaussian", X = X)`. The existing Gaussian-X
fields are preserved; the new field exposes the full mean coefficient vector
needed by the R bridge to reconstruct in-sample fitted values for the supplied
`X` design.

Changes:

- `src/bridge.jl` now merges `mean_coef = fit.pars.β` onto the Gaussian-X bridge
  payload.
- `test/test_bridge_x.jl` now checks that `mean_coef` is a `Vector{Float64}` and
  equals the native Gaussian fit coefficient vector exactly.
- `docs/src/gllvmtmb-parity.md` records the payload contract.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: `52/52 pass` in `17.4s`.

### Rose Verdict

PASS WITH NOTES. This is a payload-only bridge change, not a likelihood change.
It closes the R-side Gaussian-X in-sample prediction gap when paired with the
matching `gllvmTMB` consumer; `newdata` prediction and ordinal probabilities
remain separate bridge payloads.

## 2026-06-15 - Bridge capability reporter for R drift guard

### Scope

Added `GLLVM.bridge_capabilities()` as a flat, JuliaCall-friendly reporter for
the current `bridge_fit` surface. The helper does not change fitting behavior;
it lets `gllvmTMB` enforce a one-way bridge-drift contract: every R-admitted
row must be supported by the paired Julia checkout, while Julia-only rows must
be explicitly planned or rejected on the R side.

Changes:

- `src/bridge.jl` now defines `_BRIDGE_ONEPART_FAMILIES` and the exported
  `bridge_capabilities()` ledger.
- `src/GLLVM.jl` exports `bridge_capabilities`.
- `test/test_bridge_capabilities.jl` locks the reported rows, including NB1 as
  a Julia one-part no-X route and the mixed-family vector route as no-X only.
- `docs/src/gllvmtmb-parity.md` records the R drift-guard contract.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.1s`.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3891 pass, 3 broken, 0 failed, 0 errored` in `30m39.8s`.

```sh
~/.juliaup/bin/julia --project=docs docs/make.jl
```

Result: failed before rendering because `Documenter` was not installed in the
docs environment.

```sh
~/.juliaup/bin/julia --project=docs -e 'using Pkg; Pkg.instantiate()'
```

Result: failed with `expected package GLLVM [2dc8e01c] to be registered`.
No docs source error was reached.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 353` in `61.6s`, including the new live R subset guard against
`GLLVM.bridge_capabilities()`.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The capability reporter is metadata-only and live-consumed by
the R bridge drift test. The local Documenter build remains blocked by the
pre-existing docs-environment registration issue, so no rendered-docs claim is
made for this slice.

## 2026-06-15 - Bridge documentation current-surface sync

### Scope

Reconciled Julia-side bridge documentation with the R-first plan and the current
`gllvmTMB(..., engine = "julia")` surface.

Changes:

- `docs/src/gllvmtmb-parity.md` now records NB1 no-X bridge admission, the
  still-open NB1-X and NB1/Gaussian-mask rows, and the NB1 complete-data no-X
  post-fit boundary.
- The same page now separates broad engine capabilities from narrower R bridge
  claims so engine rows do not automatically become R-user promises.
- `r/README_bridge.md` now labels the `r/` directory as a legacy direct
  `gllvm_julia()` scaffold, not the current `gllvmTMB` bridge admission surface.
- `r/gllvmtmb_julia.R` roxygen now points readers away from the legacy scaffold
  for current fixed-effect-X bridge support.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.2s`.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The docs now support the R-first plan and avoid treating the
larger Julia engine surface as an R bridge promise. This does not add new bridge
functionality; `gllvmTMB` tests remain the source of truth for admitted R rows.

## 2026-06-15 - R-first bridge claim wording cleanup

### Scope

Applied Rose's R-first corrective pass after the maintainer asked to complete the
`gllvmTMB` user surface before promoting broader Julia claims.

Changes:

- `README.md`, `CLAUDE.md`, and `CHANGELOG.md` now say broad/status-tracked
  coverage instead of full parity or "parity and beyond".
- `docs/src/changelog.md` and `docs/src/gllvmtmb-parity.md` now separate native
  Julia routes from public R bridge parity.
- `GLLVM.bridge_capabilities()` now reports `status = "partial"` for current
  bridge rows and explains that no-X CI columns are native route metadata, not a
  full R-user parity claim.
- `test/test_bridge_capabilities.jl` now locks that partial-status vocabulary.

### Checks Run

```sh
rg -n "full GLM|gllvmTMB parity|parity and beyond|surpassed|full Wald|status = \"supported\"|must be supported" README.md CLAUDE.md CHANGELOG.md src/bridge.jl test/test_bridge_capabilities.jl docs/src -S
```

Result: one remaining scoped caveat in `docs/src/gllvmtmb-parity.md`:
"additional gllvm/gllvmTMB parity rows that are not all public through the R
bridge yet".

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `20/20 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" /usr/local/bin/Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 552` in `68.0s`.

```sh
~/.juliaup/bin/julia --project=docs --startup-file=no docs/make.jl
```

Result: failed before rendering because `Documenter` is not installed in the
local docs environment.

```sh
~/.juliaup/bin/julia --project=docs --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: failed because the docs environment expects unregistered package
`GLLVM [2dc8e01c]`.

```sh
tmp=$(mktemp -d); JULIA_PROJECT="$tmp" ~/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. Residual warnings were the known pre-existing absolute
local links, optional Vitepress assets, npm audit warnings, and chunk-size
warning; Vitepress rendered successfully.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The stale blanket parity wording is removed from the visible
Julia surfaces touched here, and the R bridge live test accepts the partial-status
metadata. This slice changes claim metadata only; it does not promote a new
family, CI route, or bridge admission cell.

## 2026-06-15 - NB1 missing-response bridge mask admission

### Scope

Extended the paired Julia bridge route so NB1 (`nb1`) no-X reduced-rank point
fits can accept the same observed-cell mask already used by the R-first
`gllvmTMB` missing-response bridge. This is an incremental bridge admission:
masked cells are excluded from the NB1 likelihood and score reconstruction, but
masked CI/profile/bootstrap refits, NB1 fixed-effect-X fits, Gaussian masks, and
mixed-family masks remain separate unsupported cells.

Changes:

- Added `nb1` to `_BRIDGE_MASK_FAMILIES`.
- Passed `mask = M` into `fit_nb1_gllvm()` and NB1 bridge assembly.
- Added `mask` support to `getLV(::NB1Fit, ...)` so bridge scores ignore
  masked-cell sentinels.
- Added NB1 native-vs-bridge parity and sentinel-invariance tests.
- Updated `docs/src/gllvmtmb-parity.md` and `docs/src/roadmap.md` to reflect the
  R-first bridge ledger, complete balanced mixed-family point-fit row, and the
  remaining unsupported cells.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `20/20 pass`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `34/34 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 571` in `70.7s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/runtests.jl
```

Result: `3931 pass / 3 broken / 0 fail` in `31m06.6s`. Direct core run reported
`Aqua not in this environment` and `JET not in this environment`; run
`Pkg.test()` for the full quality battery.

```sh
tmp=$(mktemp -d); JULIA_PROJECT="$tmp" ~/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. Residual warnings were the known pre-existing absolute
local links, optional Vitepress assets, npm audit warnings, and chunk-size
warning; Vitepress rendered successfully.

```sh
rg -n "R bridge still rejects mixed-family|mixed-family R bridge admission|do not admit family lists|NB1.*missing-response.*remain|NB1 covariate\s*or missing-response|missing-response masks are wired only for poisson, binomial, negbinomial, beta|17b2154|6056071|f1894bc" README.md CLAUDE.md CHANGELOG.md docs/src src test -S
```

Result: no matches.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. NB1 masked point fits and masked score reconstruction are now
covered for the bridge, with live R-Julia evidence. Masked CIs/simulations,
NB1-X, Gaussian masks, and mixed-family masks remain deliberate unsupported
cells.

## 2026-06-16 - Bridge grouped-dispersion default

### Scope

Changed the Julia bridge no-X default for NB2, NB1, Beta, and Gamma from the
shared-scalar fitters to the existing per-trait grouped-dispersion fitters
(`group = 1:p`). This aligns the bridge point-fit nuisance structure with native
`gllvmTMB` / `gllvm` default dispersion rather than weakening the R oracle.
Grouped-dispersion CI endpoints are deliberately not routed yet; requesting
`ci_method != "none"` for these four bridge rows now fails loudly with a
grouped-dispersion status message.

Changes:

- Added grouped-dispersion payload fields to `bridge_fit()`: `dispersion_group`,
  `dispersion_group_id`, `dispersion_parameter`, `dispersion_engine_scale`, and
  `dispersion_public_scale`.
- Updated NB2/NB1/Beta/Gamma no-X bridge branches to call
  `fit_nb_gllvm_grouped()`, `fit_nb1_gllvm_grouped()`,
  `fit_beta_gllvm_grouped()`, and `fit_gamma_gllvm_grouped()`.
- Changed `GLLVM.bridge_capabilities()` CI columns so grouped-dispersion rows
  report `false` until grouped-fit CI engines land.
- Updated the bridge capability, CI, and missing-mask tests to match the new
  grouped default.
- Narrowed README / Documenter wording so public status separates scalar-CI
  routes from grouped-dispersion CI follow-up.

### Checks Run

```sh
julia --project=. -e 'include("test/test_bridge_grouped_dispersion.jl")'
```

Result: `40/40 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_capabilities.jl")'
```

Result: `32/32 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_missing_mask.jl")'
```

Result: `35/35 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_ci.jl")'
```

Result: `63/63 pass`.

Final reruns after the docs/status wording edits:

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_grouped_dispersion.jl"); include("test/test_bridge_capabilities.jl")'
```

Result: grouped dispersion `40/40 pass`; capabilities `32/32 pass`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_missing_mask.jl")'
```

Result: `35/35 pass`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_ci.jl")'
```

Result: `63/63 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB` on branch
`codex/julia-per-trait-dispersion-spec`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 21`
in `22.8s`. This is a narrow smoke check, not full R-side grouped-dispersion
parity promotion.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `3981 pass / 3 broken / 0 fail` in `31m57.5s`. Direct core run reported
`Aqua not in this environment` and `JET not in this environment`; run
`Pkg.test()` for the full quality battery.

```sh
rg -n "bridge_fit|bridge_capabilities|confidence intervals|CI routes|NB2|NB1|Beta|Gamma|grouped dispersion|per-species / grouped" README.md docs/src docs/dev-log src test -g '!docs/node_modules/**'
```

Result: relevant hits reviewed. Public docs were narrowed where grouped-
dispersion CI status could be mistaken for completed endpoints.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. Point-fit routing now matches the R oracle's per-trait nuisance
structure for the four promoted dispersion families, and CI status is explicit
rather than silently inherited from the former shared-scalar path. Remaining
follow-ups are grouped-dispersion CI engines, R-side payload consumption/parity
rows, and full `Pkg.test()` / Documenter checks before PR promotion.

## 2026-06-16 - Bridge per-trait ordinal cutpoints

### Scope

Changed the Julia bridge ordinal and ordinal-probit no-X default from shared
cutpoints to per-trait cutpoints. This matches the native `gllvmTMB` ordinal
shape for point payloads while preserving `fit_ordinal_gllvm()` as the
shared-cutpoint Julia comparator and the current shared-cutpoint CI route.

Changes:

- Added `OrdinalPerTraitFit` and `fit_ordinal_gllvm_pertrait()` with one
  ordered cutpoint vector per trait.
- Stored per-trait cutpoints as a `p x max(C_t - 1)` matrix padded with `NaN`
  after each trait's last threshold, plus per-trait category counts `C`.
- Added post-fit, residual, latent-scale extractor, and display methods for
  `OrdinalPerTraitFit`.
- Routed `bridge_fit(; family = "ordinal")` and
  `bridge_fit(; family = "ordinal_probit")` through the per-trait fitter.
- Added bridge payload fields `cutpoints`, `n_categories`, `cutpoint_mode =
  "per_trait"`, and `cutpoint_link`.
- Changed `GLLVM.bridge_capabilities()` so ordinal and ordinal-probit no-X CI
  columns report `false` until a per-trait ordinal CI engine lands.
- Updated bridge CI tests so ordinal CI requests fail loudly instead of silently
  using the old shared-cutpoint confidence-interval route.
- Updated parity and response-family docs to separate shared-cutpoint Julia
  support from per-trait R-bridge parity support.

### Checks Run

```sh
julia --project=. test/test_ordinal_pertrait.jl
```

Result: direct per-trait ordinal tests `96/96 pass`; bridge ordinal payload
tests `15/15 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl"); include("test/test_bridge_missing_mask.jl")'
```

Result: capabilities `34/34 pass`; bridge CI `64/64 pass`; bridge
missing-response mask `37/37 pass`.

```sh
julia --project=. -e 'include("test/test_ordinal_laplace.jl"); include("test/test_ordinal_fit.jl"); include("test/test_ordinal_probit.jl"); include("test/test_postfit.jl")'
```

Result: ordinal Laplace `2/2 pass`; shared ordinal fit `9/9 pass`; ordinal
cumulative-link `10/10 pass`; post-fit blocks all passed, including ordinal
post-fit `216/216 pass`.

Final focused rerun:

```sh
julia --project=. --startup-file=no -e 'include("test/test_ordinal_pertrait.jl"); include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl"); include("test/test_bridge_missing_mask.jl")'
```

Result: direct per-trait ordinal `96/96 pass`; bridge ordinal payload `15/15
pass`; bridge capabilities `34/34 pass`; bridge CI `64/64 pass`; bridge
missing-response mask `37/37 pass`.

```sh
rg -n "species-specific cutpoints still a gap|common ordered cutpoints \(species-specific|ordinal.*CI endpoints.*✅|CI routes.*Ordinal|Ordinal/Ordinal-probit\).*CI|full ordinal parity|complete ordinal" src docs/src README.md test -g '!docs/node_modules/**'
```

Result: no hits.

```sh
git diff --check
```

Result: clean before the dev-log / after-task report was added.

### Deliberately Not Run

- Full `test/runtests.jl` and `Pkg.test()` were not rerun for this ordinal-only
  slice. The grouped-dispersion slice immediately before this one had a green
  direct core suite, and this slice reran the ordinal, bridge capability, bridge
  CI, bridge mask, and post-fit blocks touched by the change.
- Documenter was not rebuilt for this ordinal slice.
- The paired R bridge was not updated in this commit. The R side still needs to
  decode the new per-trait ordinal payload and mark ordinal CI support as
  unavailable before advertising this row.

### Rose Verdict

PASS WITH NOTES. Julia now has a per-trait ordinal point route for the R bridge,
and the bridge no longer overclaims ordinal CI support. The remaining follow-up
is R-side payload/capability synchronization plus a later per-trait ordinal CI
engine.

## 2026-06-16 — grouped-dispersion CI bridge endpoints

Branch: `codex/julia-per-trait-dispersion`

Purpose: promote the paired `gllvmTMB engine = "julia"` no-X NB2/NB1/Beta/Gamma
grouped-dispersion rows from point-fit-only to routed Wald/profile/bootstrap CI
payloads, while keeping per-trait ordinal cutpoint CIs gated.

### Changes

- Added grouped-dispersion adapters to the generic non-Gaussian
  `confint(fit, Y; method = ...)` layer for `NBGroupedFit`, `NB1GroupedFit`,
  `BetaGroupedFit`, and `GammaGroupedFit`.
- Routed `bridge_fit(..., options = Dict("ci_method" => ...))` through those
  adapters for NB2, NB1, Beta, and Gamma no-X bridge rows.
- Kept default `ci_method = "none"` payloads byte-lean: grouped fits still omit
  `ci_*` fields unless a CI method is explicitly requested.
- Updated `bridge_capabilities()` and bridge docs so grouped-dispersion
  Wald/profile/bootstrap rows are admitted and per-trait ordinal CI rows remain
  follow-ups.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_grouped_dispersion.jl
```

Result: `121/121` pass, including grouped Wald payload checks and a small
Gamma no-latent profile/bootstrap smoke.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

First run failed because the test expectation still listed scalar CI rows only.
After updating the expected ledger, rerun result: `34/34` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass; the existing scalar-family bridge CI parity and status
suite stayed green.

### Deliberately Not Run

- Full `Pkg.test()` / `test/runtests.jl` was not run for this narrow engine
  slice. The touched surface is the grouped bridge CI route plus capability
  metadata; the targeted bridge grouped, capability, and CI suites were run.
- Documenter was not rebuilt locally. The edited docs are source Markdown only.
- The paired R bridge was not updated in this Julia commit. That is the next
  lane and must widen the R-side CI gate, tests, NEWS, validation register, and
  dashboard together.

### Claim Boundary

IN: no-X grouped-dispersion NB2, NB1, Beta, and shared-Gamma bridge payloads can
return Wald/profile/bootstrap CI fields when explicitly requested. PARTIAL:
fixed-effect-X, masked, mixed-family, REML, and per-trait ordinal CI routes
remain gated. PLANNED: broader calibration and speed evidence belong in the
R/Julia simulation-comparator programme, not this endpoint-routing slice.

## 2026-06-25 — predictor-informed latent-score C1

Branch: `codex/lv-predictor-c1-20260625`

Purpose: add the Julia-side ordinary Gaussian unit-tier analogue of the R
`gllvmTMB` Design 73 C1 surface, without broad parity, interval, or
non-Gaussian claims.

### Changes

- Added `gaussian_lv_nll_packed`, an explicit Gaussian likelihood for
  `z_total[s, :] = X_lv[s, :] * alpha_lv + z_innovation[s, :]`.
- Added `fit_gaussian_gllvm(...; X_lv = X_lv, alpha_lv_init = ...)` for the
  ordinary Gaussian unit-tier path only.
- Added `getLV(...; component = :mean/:innovation/:total, X_lv = X_lv)`.
- Added `extract_lv_effects()` / `lv_effects()` for the rotation-stable
  trait-effect matrix `B_lv = Lambda * alpha_lv'`.
- Guarded Wald/profile/bootstrap intervals for `X_lv` fits; this C1 slice is
  point-estimate only.
- Updated model docs, changelog, tests, and the after-task report.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_lv_predictor.jl
```

Result: `24/24` pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'include("test/test_fixed_effects.jl"); include("test/test_postfit.jl")'
```

Result: fixed effects `18/18` pass; post-fit ordination core `96/96`,
predict/fitted `9/9`, residuals `10/10`, AIC/BIC `8/8`, Poisson `163/163`,
NB `160/160`, Beta `215/215`, Gamma `215/215`, Ordinal `216/216`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'include("test/test_confint.jl"); include("test/test_confint_profile.jl"); include("test/test_confint_bootstrap.jl")'
```

Result: Wald CI `14/14`, profile CI `4/4`, bootstrap CI `9/9`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/runtests.jl
```

Result: full local test suite passed with `4519` pass, `3` broken, `4522`
total in `31m25.4s`. The run reported that Aqua and JET are not available in
this direct `test/runtests.jl` environment and should be run through
`Pkg.test()` for the full battery.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: package test suite passed with `4531` pass, `1` broken, `4532` total
in `36m58.2s`. This run used the temporary `Pkg.test()` environment with Aqua
and JET available.

```sh
/Users/z3437171/.juliaup/bin/julia --project=docs --startup-file=no docs/make.jl
```

Result: Documenter/VitePress build completed. The run reported pre-existing
invalid-local-link warnings for the docs navigation (for example `/quickstart`,
`/response-families`, and `/api`) and npm audit warnings from the VitePress
dependency tree; neither was introduced by this slice.

### Deliberately Not Run

- No push or PR was opened: `gllvmTMB` PR #558 is open and green, GLLVM.jl draft
  PR #113 is open, and this repo requires explicit maintainer instruction
  before pushing.

### Claim Boundary

IN: ordinary Gaussian unit-tier predictor-informed latent-score point estimates.
PARTIAL: score algebra and post-fit extraction are tested, but recovery,
coverage, and bridge promotion are not admitted. OUT: W-tier, diagonal random
effects, phylogenetic/source-specific blocks, non-Gaussian families, REML, and
interval calibration.
