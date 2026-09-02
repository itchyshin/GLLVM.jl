# Diagnostics and model comparison

These functions read an already-fitted model (or a pair of fits) and report
on its health — score-centring consistency, boundary/degeneracy scans,
residual-family checks, kernel separability — or compare two fits on the same
species set. None of them fits a new model.

## Single-fit diagnostics

`sanity_multi` and `gllvmTMB_diagnose`/`check_gllvmTMB` run Hessian-based
health checks (positive-definiteness, gradient norm) and a boundary scan on
the implied `Σ_y` (near-zero variances, near-±1 correlations). The
Hessian-based fields are only populated for `GllvmFit` (Gaussian) fits with
`y` supplied — GLLVM.jl has no generic Hessian path across its ~50
non-Gaussian fit types, so those fields come back `missing` on other families
rather than a guess. R's per-family boundary rows (binomial-prevalence
loading, multinomial degeneracy, ordinal cutpoint span, spatial-domain
diameter) are not ported; only the generic variance/correlation scan is.

`gllvmTMB_check_consistency` re-simulates a fit's own single-tier Gaussian
generative model and tests score-centring across replicate refits via a
Hotelling T² omnibus test. It is scoped to a plain Gaussian generative model
(`K_W == 0`, no diagonal component, no phylogenetic block, no fixed-effect
`β`) — any other model structure raises `ArgumentError` rather than
simulating the wrong generative process. `estimate = TRUE` (R's re-fit
`joint_p_value` route) is not implemented; that field is always `missing`.

`check_auto_residual` checks a fit's declared link against its family; the
family-mixing branch of R's check is vacuously `false` here, since GLLVM.jl
fit types are one family per whole model (no native per-trait mixed-family
surface).

`diagnose_kernel_separability` checks only the two-tier `Λ_B` vs `Λ_W` case
GLLVM.jl currently fits; single-tier fits report `separable = missing`.

`fit_diagnostic_table` computes its summary rows directly from the raw fit
(unlike R's `diagnostic_table`, which reads metadata already attached by a
prior `predictive_check()`/`residuals()` call).

`predictive_check` simulates from the fit's own family (reusing the existing
per-family `simulate` machinery — no new simulation code) and summarises
against the observed data. Fit types with no `simulate` method raise
`ArgumentError` naming the gap.

`confint_inspect` reports per-term profile-likelihood diagnostics; it does
not wire in bootstrap CIs or render R's comparison plot.

## Comparing two fits

`compare_fits_Sigma_table` and `compare_loadings` compare the implied
covariance/loadings of two fits using rotation- and sign-free invariants only
— `compare_loadings` compares `Λ1Λ1ᵀ` vs `Λ2Λ2ᵀ` (Frobenius norm) and
principal angles between column spaces, never a signed entrywise `Λ` diff.

`compare_fits_dep_vs_two_psi` and `compare_fits_indep_vs_two_psi` bridge any
two same-`p` fits via their implied `Σ_y` and an information-criterion
comparison (`nobs`/BIC). This is a generic two-fit bridge, not R's specific
named "two-ψ" phylogenetic reparameterisation — GLLVM.jl does not implement a
distinct "two-ψ" model family — so `n` (sample size for BIC) must be passed
explicitly.

```@docs
sanity_multi
gllvmTMB_diagnose
check_gllvmTMB
gllvmTMB_check_consistency
check_auto_residual
diagnose_kernel_separability
fit_diagnostic_table
predictive_check
confint_inspect
compare_fits_Sigma_table
compare_loadings
compare_fits_dep_vs_two_psi
compare_fits_indep_vs_two_psi
```

## Renamed in this release

Five functions in `src/diagnostics.jl` and `src/re_sd.jl` were renamed away
from names that shadowed an R function with **different semantics** — the R
function reads a different quantity or has a different call shape — freeing
those names for a future true R-mirror (maintainer decision round2-3 #5):

| Old name | New name | Why it moved |
| --- | --- | --- |
| `getREsd` | [`latent_score_sd`](@ref) (see [SE and profile machinery](se-profile-machinery.md)) | R's `getREsd(fit, block=)` reads auxiliary TMB random-effect blocks; Julia's reads latent factor-score conditional SDs — a different quantity. |
| `compare_Sigma_table` | [`compare_fits_Sigma_table`](@ref) | R's version compares a fit against a supplied ground-truth matrix; Julia's compares two fits. |
| `compare_dep_vs_two_psi` | [`compare_fits_dep_vs_two_psi`](@ref) | R's version internally refits a named "two-ψ" alternative; Julia's is a generic two-fit bridge. |
| `compare_indep_vs_two_psi` | [`compare_fits_indep_vs_two_psi`](@ref) | Same mismatch, the `indep` counterpart. |
| `diagnostic_table` | [`fit_diagnostic_table`](@ref) | R's version needs metadata already attached by a prior call; Julia's computes from the raw fit. |

Each old name still resolves, via a deprecated forwarding call that emits a
`Base.depwarn` and delegates to the new name — it is not otherwise
documented here. A sixth rename, `profile_targets` →
[`profile_curve_targets`](@ref), is covered on
[SE and profile machinery](se-profile-machinery.md).

See also: [Confidence intervals](confidence-intervals.md) ·
[Post-fit extractors](postfit-extractors.md) ·
[Working with a fit](working-with-a-fit.md).
