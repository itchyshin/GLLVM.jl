# core070 diagnostics/compare cluster — slice notes

Owner: julia-engineer (Gauss/Karpinski persona). Branch
`codex/core070-aghq-20260830`. Files touched: `src/diagnostics.jl` (new),
`test/test_diagnostics.jl` (new), `src/GLLVM.jl` (include + export lines),
`test/runtests.jl` (include line).

## Scope

Closes the following BLOCKED rows in
`docs/dev-log/core070/required-source-case-map.json`:

- `namespace/export/{gllvmTMB_check_consistency, gllvmTMB_diagnose,
  predictive_check, sanity_multi}`
- `postfit/POSTFIT-SURFACE-{check_gllvmTMB, check_auto_residual,
  diagnostic_table, diagnose_kernel_separability, compare_Sigma_table,
  compare_dep_vs_two_psi, compare_indep_vs_two_psi, compare_loadings,
  confint_inspect}`

All thirteen are now exported Julia functions in `src/diagnostics.jl`, each
docstring citing the exact R source file/line it ports from
`.unlazy/core070-aghq/oracle-source/readback/R/`.

## R source citations

| Julia function | R source |
| --- | --- |
| `gllvmTMB_check_consistency` | `check-consistency.R:131-240` |
| `check_auto_residual` | `check-auto-residual.R` |
| `sanity_multi` | postfit-2 required surface (no single R file — composed from GLLVM.jl's own `confint`/Hessian path) |
| `gllvmTMB_diagnose` | `diagnose.R:2005-2213` (holistic wrapper); boundary scan mirrors the spirit of `.gllvmTMB_build_fit_health()` (`diagnose.R:15-127`) |
| `check_gllvmTMB` | `diagnose.R:1548-2005` |
| `diagnostic_table` | `diagnostic-tables.R:53-151` |
| `diagnose_kernel_separability` | `kernel-helpers.R` / `kernel-keywords.R` |
| `compare_Sigma_table` | `extract-sigma-table.R` |
| `compare_loadings` | `rotate-loadings.R` |
| `compare_dep_vs_two_psi` / `compare_indep_vs_two_psi` | `extract-two-psi-cross-check.R` |
| `predictive_check` | `predictive-diagnostics.R:78-229` |
| `confint_inspect` | `confint-inspect.R:128-388` |

## Ground rules honoured

- **Read-only**: no function here fits a new model; all operate on an
  already-fitted GLLVM object (or a pair of them for `compare_*`).
- **tcrossprod-only loadings comparison**: `compare_loadings` compares
  `Λ1Λ1ᵀ` vs `Λ2Λ2ᵀ` (Frobenius norm) and principal angles between column
  spaces (via `svd(Λ1'Λ2)`) — never a signed entrywise Λ diff.
  `compare_Sigma_table` similarly compares the implied `Σ_y = ΛΛᵀ +
  diag(σ_eps²)`, a rotation/sign-free invariant.
- **`predictive_check`** reuses the existing per-family
  `simulate(fit, n; rng)` machinery in `src/simulate_fit.jl` (non-Gaussian
  families) and the Gaussian simulator in
  `src/families/aghq_gaussian_fit.jl` — no new simulation code was written.
  Fit types with no `simulate` method (e.g. `OrdinalPerTraitFit`) throw
  `ArgumentError` naming the gap; test coverage confirms this.

## Documented gaps (never silently stubbed)

- `gllvmTMB_check_consistency`: GLLVM.jl has no TMB joint/marginal Laplace
  random-effect split. This port re-simulates the single-tier Gaussian
  generative model directly (`K_W == 0 && !has_diag && K_phy == 0`, no
  fixed-effect `β`) and tests score-centring via a Hotelling T² omnibus test
  on the packed-NLL score across `n_sim` replicate fits, rather than TMB's
  internal joint/marginal split. `estimate = TRUE` (R's re-fit `joint_p_value`
  path) is not implemented — always `missing`. Any other model structure
  throws `ArgumentError` rather than simulating the wrong generative model.
- `check_auto_residual`: GLLVM.jl fit types are one family per whole model
  (no native per-trait mixed-family surface), so the family-mixing branch of
  R's check is vacuously `false` on the current family surface — documented,
  not silently "verified". The ordinal-probit branch is fully checked
  against `fit.link`.
- `sanity_multi` / `gllvmTMB_diagnose`: the Hessian-based `pd_hessian` /
  `gradient_norm` checks only run for `GllvmFit` (Gaussian) with `y`
  supplied — GLLVM.jl has no generic Hessian path across the ~50 non-Gaussian
  fit types, so those fields come back `missing` rather than a guess.
  `gllvmTMB_diagnose`'s per-family boundary rows (binomial-prevalence
  loading row, multinomial degeneracy, ordinal cutpoint span, spatial-domain
  diameter — `diagnose.R:417-1548`) are not ported; only a generic
  variance-near-zero / correlation-near-±1 boundary scan on the implied Σ_y.
- `diagnose_kernel_separability`: only checks the two-tier `Λ_B` vs `Λ_W`
  case GLLVM.jl currently fits; R's kernel-keyword machinery covers a
  broader family of named structured-covariance kernels. Single-tier fits
  report `separable = missing`.
- `compare_dep_vs_two_psi` / `compare_indep_vs_two_psi`: R's "two-ψ"
  alternative is a specific named reparameterisation GLLVM.jl does not
  implement as a distinct family; these are the generic Σ_y +
  information-criterion bridge, applicable to any two same-`p` fits — not
  literally the R "two-ψ" comparison. `n` (sample size for BIC) must be
  passed explicitly since `StatsAPI.nobs(fit)` needs the response matrix.
- `confint_inspect`: does not wire in bootstrap CIs (bounded scope) and
  does not render R's comparison plot (`confint-inspect.R:388-490`).
- `compare_Sigma_table`: no paired-fit comparison SE (single-fit Σ_y CIs
  exist in `confint_derived.jl`, but not a comparison SE across two fits) —
  point-estimate comparison only.

## Verification

`julia --project=. -e 'using Test, GLLVM; include("test/test_diagnostics.jl")'`
→ **51/51 passed, 0 failed, 0 errored** (standalone run, not the full suite —
per task instructions the orchestrator consolidates the full suite on
Totoro). `using GLLVM` loads clean (only the pre-existing
`Distributions.Multinomial` shadow warning, unrelated to this change).

## Merge-collision flag for the maintainer

The lane-check hook on both `Write` and `Edit` reported that
`src/diagnostics.jl` and `test/test_diagnostics.jl` already exist with
**unrelated content** on two other branches:

- `fam-ordprobit` (commit `b64a90ce feat(families): ordinal probit`)
- `a6-diagnostics` (commit `fbdd2ae8 feat(diagnostics): randomized-quantile
  residuals + check_fit`)

Both carry a *different* `src/diagnostics.jl` — randomized-quantile
(Dunn–Smyth) residuals plus a `check_fit` summary (`_pit`,
`quantile_residuals`, `check_fit`). That content does not overlap in
symbol names with this slice's `gllvmTMB_check_consistency` /
`gllvmTMB_diagnose` / `check_gllvmTMB` / `sanity_multi` / `compare_*` /
`predictive_check` / `confint_inspect` cluster, but it is a **filename
collision** this checkout does not have. This branch was assigned
`src/diagnostics.jl` explicitly by the orchestrator's task brief; the
maintainer (or Shannon) will need to reconcile the two `diagnostics.jl`
histories at merge time — most likely by keeping both function sets in the
same file, or splitting one out (e.g. `residuals_diagnostics.jl`) rather
than a straight two-way merge collision.
