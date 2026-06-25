## 1. Goal

Expose the already-landed native Gaussian predictor-informed latent-score
implementation through the flat `GLLVM.bridge_fit()` endpoint so the R package
can later wire `latent(..., lv = ~ x, engine = "julia")` without inventing a
separate transport contract.

## 2. Implemented

- Added `X_lv` to `bridge_fit()` for complete-response `family = "gaussian"`
  point fits.
- Preserved the existing Gaussian bridge convention: trait means are returned as
  `alpha`, and `fit_gaussian_gllvm()` receives the centred response matrix.
- Returned total latent scores in the existing `scores` field and added
  `scores_mean`, `scores_innovation`, raw `alpha_lv`, and stable
  `lv_effects = Lambda * alpha_lv'`.
- Added `predictor_informed_lv` to `bridge_capabilities()` so `X_lv` is separate
  from ordinary fixed-effect `X`.
- Added bridge tests against the native centred Gaussian oracle and negative
  tests for unsupported combinations.
- Updated the bridge parity page, changelog, roadmap, and check log.

## 3a. Decisions and Rejected Alternatives

- Centred responses before fitting the Gaussian `X_lv` bridge route. This keeps
  `alpha` aligned with the existing Gaussian no-X bridge contract and avoids
  making the latent-score predictors absorb trait intercepts.
- Returned `lv_effects` as the main cross-language estimand because
  `Lambda * alpha_lv'` is rotation-stable. Raw `alpha_lv` is still returned, but
  only as a lower-level axis diagnostic.
- Rejected simultaneous fixed-effect `X` and latent-score `X_lv` in this slice.
  The native fitter has an `X` argument, but the bridge needs a separate parity
  and design pass before exposing the combined mean structure.
- Rejected confidence intervals for `X_lv` bridge fits. The native interval
  engines already reject Gaussian `X_lv` fits, so the bridge fails before fitting
  when `ci_method != "none"`.
- Rejected non-Gaussian and mixed-family `X_lv` routes here. The constrained
  ordination machinery is related, but not yet the flat R bridge parity contract.

## 4. Files Touched

- `src/bridge.jl`
- `test/test_bridge_lv_predictor.jl`
- `test/test_bridge_capabilities.jl`
- `test/runtests.jl`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/changelog.md`
- `docs/src/roadmap.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-bridge-gaussian-xlv.md`

## 5. Checks Run

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: dependencies instantiated after the fresh worktree initially lacked
precompiled dependencies; no `Project.toml` or `Manifest.toml` churn remained.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `19/19` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `42/42` pass.

```sh
julia --project=. --startup-file=no test/test_lv_predictor.jl
```

Result: `24/24` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
```

Result: `179/179` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `83/83` pass.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build passed. Existing local-link warnings,
Vitepress npm audit warnings, and skipped deployment outside CI were unchanged
from the repository's current docs build behavior.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `4540 pass, 3 broken, 4543 total` in `43m39.1s`. Aqua/JET were not in
the direct project environment; `Pkg.test()` covered that battery.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: `4552 pass, 1 broken, 4553 total`; `GLLVM tests passed` in `46m58.8s`.

```sh
git diff --check
```

Result: clean before the dev-log edits.

```sh
rg -n "predictor-informed latent-score|X_lv|lv_effects|scores_mean|scores_innovation|non-Gaussian X_lv|full R-user parity|R-bridge promotion|R-package row promotion" src test docs/src README.md CHANGELOG.md
```

Result: only intended implementation, tests, capability metadata, and guarded
docs matches.

## 6. Tests of the Tests

- `test/test_bridge_lv_predictor.jl` compares the bridge output to a direct
  native `fit_gaussian_gllvm(Yc; X_lv = X_lv)` oracle. If the bridge stopped
  centering responses, returned unrotated scores in the public payload, or
  mismatched `lv_effects`, the equality checks would fail.
- The negative tests assert failures for `d = 0`, simultaneous `X` + `X_lv`,
  `ci_method = "wald"`, wrong `X_lv` row count, non-Gaussian `X_lv`, and
  mixed-family `X_lv`. If a future edit silently widened the route, these tests
  would fail.
- `test/test_bridge_capabilities.jl` locks the new
  `predictor_informed_lv` column and its Gaussian-only row.

## 7a. Issue Ledger

- Fixed: Julia bridge lacked an endpoint for the native Gaussian `X_lv` fit that
  landed in the previous slice.
- Deferred: R-side `engine = "julia"` admission for `latent(..., lv = ~ x)` is
  a separate `gllvmTMB` PR after this Julia endpoint lands.
- Deferred: binary/probit and other non-Gaussian `X_lv` bridge routes remain
  separate validation gates.
- Deferred: the `gllvmTMB` pkgdown formula keyword-grid article still needs a
  separate docs cleanup because `unique()` is soft-deprecated compatibility
  syntax and `indep()` should be the primary standalone diagonal example.

## 8. Consistency Audit

- Rechecked open PR state before editing shared dev-log files: only draft PR
  #113 (`claude/studentt-105-20260620`) was open, unrelated to this bridge lane.
- Rechecked recent commits: only the already-merged Gaussian `X_lv` and build
  commits were recent.
- Scanned `src`, `test`, `docs/src`, `README.md`, and `CHANGELOG.md` for `X_lv`
  and parity wording. The only broad parity phrase left is the existing guarded
  "narrower than full R-user parity" wording in bridge capability notes.
- Updated nearby bridge docs rather than leaving stale "R-bridge promotion
  remains gated" language after the endpoint itself became available.

## 9. What Did Not Go Smoothly

- The fresh worktree initially failed to precompile because local Julia
  dependencies were not instantiated. Running `Pkg.instantiate()` fixed the
  environment and left no manifest changes.
- `test/runtests.jl` and `Pkg.test()` were long and quiet for extended stretches.
  Process checks showed active CPU use; both eventually completed successfully.

## 10. Known Residuals

- This is not an R-side row promotion. `gllvmTMB` still needs to pass `X_lv`
  through JuliaCall, decode the new fields, and test the R object contract.
- No confidence intervals are available for Gaussian `X_lv` bridge fits.
- No missing-response, simultaneous `X` + `X_lv`, mixed-family, binary,
  count, ordinal, Gamma, Beta, or structured-source `X_lv` bridge route is
  admitted here.
- The R pkgdown keyword-grid page still needs a later `unique()` to `indep()`
  compatibility cleanup.

## 11. Team Learning

- Keep `X` and `X_lv` as separate bridge capability axes. They are different
  mean structures and should not share a status column.
- For cross-language `X_lv`, expose rotation-stable `lv_effects` as the primary
  payload and raw `alpha_lv` as diagnostic context.
- Long full-suite runs can be quiet for many minutes; when in doubt, sample or
  inspect the process before interrupting a CPU-active Julia test.
