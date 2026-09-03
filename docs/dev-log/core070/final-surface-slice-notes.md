# Final missing-surface cluster — implementation notes

Implements `docs/dev-log/core070/final-surface-spec.md` §1 (implementable-now,
smallest-first). Lane ownership: new files `src/postfit_tables.jl` +
`test/test_postfit_tables.jl`, include/export lines in `src/GLLVM.jl` and
`test/runtests.jl`. No other files touched.

## Items implemented (12 of 14; one commit each)

| # | Name | Notes |
| - | --- | --- |
| 1.1 | `deviance` | `-2*loglikelihood(fit)`, exact R contract. |
| 1.2 | `profile_cross_rho_ci` | Grid interpolation over a `(rho, delta_deviance)` table. |
| 1.3 | `predict_cross_covariance` | Positional form; `kernel_value * gamma_shape`. |
| 1.4 | `predict_missing` | `(row, col, est)` at masked cells only. |
| 1.5 | `simulate_unit_trait` | Balanced two-level Gaussian DGP. **Location deviation**: lands in `src/postfit_tables.jl`, not `src/simulate.jl` (this lane does not own `src/simulate.jl`). |
| 1.6 | `profile_cross_rho` | Grid-refit sensitivity driver, duck-typed `refit(K, rho)`. |
| 1.8 | `rotate_loadings` | Varimax/promax. Scope: `GllvmFit`/`level=:unit` only (no `TwoLevelFit`). |
| 1.9 | `extract_rotated_loadings_table` | Tidy wrapper over 1.8, `loading_scale=:raw|:standardized`. |
| 1.11 | `extract_coevolution_modules` | SVD of `Σ_row^(-1/2) Γ Σ_col^(-1/2)`; operates on any shared covariance matrix (`scale=:shape` only). |
| 1.12 | `imputed` | Reduced Gaussian-FIML form; `std_error=NaN`, `status=:se_not_computed` honestly (no conditional-SE Hessian block). |
| 1.13 | `tidy` | Core tiers (`:fixed`, `:ran_pars`, `:cutpoint`), **`GllvmFit` (plain Gaussian) only** — tighter than the spec's own reduced scope. |
| 1.14 | `summary` | `GllvmSummary` struct + `Base.summary(fit::GllvmFit, Y; X)`. Same `GllvmFit`-only scope as 1.13. |

## Items skipped

- **1.7 `simulate_site_trait`** — time-boxed out. It is the largest item in
  the bucket (full site×species×trait DGP: spatial exponential kernel,
  phylo block, occupancy truncated-Poisson sampling, multiple error gates)
  and did not fit in the remaining slice budget after 1.1-1.6/1.8/1.9/1.11-1.14.
  Not a building-block-wrong call — genuinely deferred. Its landing spot
  would face the same `src/simulate.jl` ownership deviation as 1.5.
- **1.10 `extract_residual_split`** — excluded per the orchestrator's
  explicit instruction (gated on the §3.3 maintainer decision: whether
  Julia's `sigma2_e` at `:unit_obs`/`:unique` should exclude `σ_eps²`, which
  it currently does not).

## A spec building-block claim found wrong (§1.14)

The spec's §1.14 "Reuse" note says `extract_communality` is `TwoLevelFit`-only
and needs "extending to `GllvmFit` in this slice (small, implementable-now)".
That is **wrong** against this checkout: `extract_communality(fit::GllvmFit)`
already exists (`src/extractors.jl:262`, forwards to the `communality`
generic). No extension was added — `summary()` calls it directly. Extending
an already-correct method would have been an unrelated/duplicate change
under the surgical-changes rule.

## A real bug this slice's own tests surfaced (§1.13/1.14)

`_tidy_fixed_rows`/`_tidy_ran_pars_rows` initially called `coef_table`/
`confint` without forwarding `X`. For any fit with fixed effects this
silently mismatches the Hessian reconstruction in `confint.jl` (`GllvmFit`
does not store its own `X`, matching the convention everywhere else in the
package) and returns **all-`NaN` standard errors** — not an error, just
silently wrong. Caught by the `1.13`/`1.14` tests once they used a fit with
`q>1` fixed-effect columns and checked `isfinite(std_error)` for real (an
earlier draft's `conf_int`-bound assertions were accidentally vacuous —
guarded by `if isfinite(...)` — against an all-`NaN` fit, which is itself a
lesson: an `if isfinite` guard around an assertion can silently skip the
assertion instead of catching the bug it exists to catch). Fixed by adding
an `X` kwarg to `tidy`, `summary`, and their private helpers, forwarded to
every `coef_table`/`confint` call — documented explicitly in both
docstrings.

## Deliberate scope reductions (documented in docstrings, not stubs)

- `rotate_loadings`/`extract_rotated_loadings_table`: `GllvmFit` only, no
  `TwoLevelFit` level mapping.
- `extract_coevolution_modules`: `scale=:shape` only, positional indices;
  no named kernel-tier levels, no `scale=:effect` (needs a stored ρ, §2.7).
- `imputed`: point estimates only; conditional SEs NOT computed (`status =
  :se_not_computed` on every row, never a stub SE).
- `tidy`/`summary`: `GllvmFit` (plain Gaussian) only — tighter than the
  spec's own "Scope now" (which mentions non-Gaussian families, SPDE
  κ/τ, rr-implied sds). This is a further, honestly-documented reduction
  made for this slice's time budget, not a claim of broader coverage.
- `predict_cross_covariance`: `rho`/`kernel_includes_rho` metadata columns
  deferred to the `CrossKernel` wrapper (§2.6, not built).
- `predict_missing`: fit-stored mask / zero-argument shape deferred to
  §2.5 (not built); ordinal_probit expected-category replacement and the
  experimental `se=` routes out of scope (§3.8).

## Verification

Per-commit: red-first test written before the implementation, standalone
`julia --project=. test/test_postfit_tables.jl` run to green, and a clean
`julia --project=. -e 'using GLLVM'` load check (no warnings beyond the
pre-existing `Distributions.Multinomial` identifier-conflict warning, which
predates this slice).

Final standalone tally (all 12 items, one `@testset` per item):

```
Test Summary:                                     | Pass  Total     Time
postfit_tables.jl — final missing-surface cluster |  623    623  1m05.4s
```

No full-suite (`Pkg.test()`) run locally per the task's instruction — the
orchestrator consolidates on Totoro.

## Commits (one per item, `src/postfit_tables.jl` + `test/test_postfit_tables.jl`
## + include/export lines in `src/GLLVM.jl`/`test/runtests.jl`)

```
a9464034 feat(postfit_tables): deviance = -2*loglikelihood (core070 §1.1)
a526c701 feat(postfit_tables): profile_cross_rho_ci grid interpolation (core070 §1.2)
37782ca1 feat(postfit_tables): predict_cross_covariance, positional form (core070 §1.3)
f1424ba1 feat(postfit_tables): predict_missing, explicit-args form (core070 §1.4)
db8612df feat(postfit_tables): simulate_unit_trait balanced two-level Gaussian DGP (core070 §1.5)
11ecfafb feat(postfit_tables): profile_cross_rho grid-refit driver (core070 §1.6)
fbbec2e4 feat(postfit_tables): rotate_loadings varimax/promax (core070 §1.8)
dfa13a57 feat(postfit_tables): extract_rotated_loadings_table (core070 §1.9)
4238ebb4 feat(postfit_tables): extract_coevolution_modules core math (core070 §1.11)
9e0ea04c feat(postfit_tables): imputed, reduced Gaussian-FIML form (core070 §1.12)
df3e61b5 feat(postfit_tables): tidy core tiers, GllvmFit only (core070 §1.13)
8e990916 feat(postfit_tables): summary core + tidy/summary X-forwarding fix (core070 §1.14)
```
