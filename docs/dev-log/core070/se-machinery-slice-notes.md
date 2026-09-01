# core070 E-cluster: SE-machinery slice notes (getREsd, bootstrap_Sigma, profile-curve wrappers)

**Owner (this slice):** julia-engineer (Gauss/Karpinski personas), 2026-09-01.
**Branch:** `codex/core070-aghq-20260830`.
**Scope:** the ~15 BLOCKED rows in
`docs/dev-log/core070/required-source-case-map.json` for
`getREsd`, `bootstrap_Sigma`, `loading_ci`, `loading_profile`,
`tmbprofile_wrapper`, `profile_targets`, `profile_phylo_signal`
(`namespace/export/*` and `postfit/POSTFIT-SURFACE-*` rows, 14 total).

## What landed

| Row (source_id) | Disposition before | What changed |
| --- | --- | --- |
| `namespace/export/getREsd`, `postfit/POSTFIT-SURFACE-getREsd` | `BLOCKED_NEEDS_JULIA_SURFACE` | New `getREsd` methods in `src/re_sd.jl` (Gaussian + 5 dense-Laplace families) |
| `namespace/export/bootstrap_Sigma`, `postfit/POSTFIT-SURFACE-bootstrap_Sigma` | `BLOCKED_NEEDS_JULIA_SURFACE` | New `bootstrap_Sigma` in `src/confint_derived_wald.jl` (append) |
| `namespace/export/tmbprofile_wrapper`, `postfit/POSTFIT-SURFACE-tmbprofile_wrapper` | `BLOCKED_NEEDS_JULIA_SURFACE` | New `tmbprofile_wrapper` in `src/confint_profile.jl` (append) |
| `namespace/export/profile_targets`, `postfit/POSTFIT-SURFACE-profile_targets` | `BLOCKED_NEEDS_JULIA_SURFACE` | New `profile_targets` in `src/confint_profile.jl` (append) |
| `namespace/export/profile_phylo_signal`, `postfit/POSTFIT-SURFACE-profile_phylo_signal` | `BLOCKED_NEEDS_JULIA_SURFACE` | New `profile_phylo_signal` in `src/confint_profile.jl` (append) — SCOPED, see gap below |
| `namespace/export/loading_ci`, `postfit/POSTFIT-SURFACE-loading_ci` | `BLOCKED_NEEDS_JULIA_SURFACE`, already REPAIR-deferred 2026-09-01 to `deferred[]` (confirmatory-fit gate: R's `loading_ci()` refuses fits with no `lambda_constraint` pins) | Not touched. See gap below. |
| `namespace/export/loading_profile`, `postfit/POSTFIT-SURFACE-loading_profile` | `PARTIAL_PARITY_DEFECT_PENDING_DECISION` / `BLOCKED_NEEDS_JULIA_SURFACE`, already REPAIR-deferred to `deferred[]` (same confirmatory-fit gate; estimand-alignment family) | Not touched. See gap below. |

## getREsd — statistical scope (read this before using the numbers)

Every SD `getREsd` returns is **conditional on θ̂** — `sqrt(diag(Cov(z | y,
θ̂)))` for the latent factor scores `z`. This does **not** propagate
uncertainty in θ̂ itself (fixed effects, loadings, dispersion). This is
exactly TMB's `sdreport()` convention for `random` effects (Kristensen,
Nielsen, Berg, Skaug & Bell 2016, *J Stat Soft* 70(5), §2.3): the Laplace
approximation treats the random-effect block as Gaussian at the mode with
precision equal to the negative Hessian of the joint nll wrt the random
effects, evaluated at `(ẑ, θ̂)`.

Two exact/approximate regimes:

1. **Gaussian closed-form (`GllvmFit`)** — EXACT. `z_s | y_s, θ̂ ~ N(m_s,
   M⁻¹)`, `M = I_K + Λ'Ψ⁻¹Λ`, `Ψ = Σ_y − ΛΛ'`. `M` doesn't depend on the
   site, so every row of the returned `n × K` matrix is identical. Verified
   in `test/test_se_machinery.jl` against a DIFFERENT closed-form identity
   (`Cov(z|y) = I − Λ'Σ_y⁻¹Λ`, the standard joint-Gaussian conditioning
   formula) to ≤ 1e-10 — a genuine cross-check, not a tautology, since the
   test recomputes via `Σ_y⁻¹` directly rather than the Woodbury `Ψ⁻¹` path
   `getREsd` itself uses.

2. **Dense-Laplace non-Gaussian (Binomial, Poisson, NegativeBinomial,
   Gamma, Beta)** — Laplace-APPROXIMATE. `z_s | y_s, θ̂ ≈ N(ẑ_s, A_s⁻¹)`,
   `A_s = Λ'W_sΛ + I_K`, `W_s` the SAME per-cell curvature
   `laplace_loglik_site` (`src/families/laplace.jl`) already assembles for
   its log-det term, honouring that fit's own recorded `fit.hessian`
   (Fisher or observed — e.g. Gamma defaults to `:observed`). Verified for
   Poisson against a hand-written, independently-derived per-site Hessian
   inversion (textbook Poisson/log-link Fisher weight `W_t = μ_t`) to
   `atol=1e-8`.

**Not covered**: AGHQ-integrated fits (Binomial/Poisson `aghq > 0`) throw
`ArgumentError` — their conditional covariance is not the same
single-Gauss-Hermite-node object this file assumes, and building that
correctly is out of this slice's scope. Ordinal (cutpoint-based mode-finder,
no plain `(β, Λ, link)` + `_laplace_mode` shape) and every other family in
`src/families/` are simply not covered — calling `getREsd` on them is a
`MethodError`, the honest failure mode rather than a silently wrong number.

## bootstrap_Sigma — thin driver, honest partial parity with R

`bootstrap_Sigma` (appended to `src/confint_derived_wald.jl`) is a thin
driver + table assembler over the EXISTING `bootstrap_ci_derived`
(`src/confint_derived.jl`): it loops the upper triangle of
`sigma_y_site(fit)` and calls `bootstrap_ci_derived(fit, fb ->
sigma_y_site(fb)[i,j]; ...)` per entry. No new bootstrap machinery.

**Gap, honestly recorded**: R's `bootstrap_Sigma()`
(`gllvmTMB/R/bootstrap-sigma.R`) bootstraps `Sigma`, `R` (correlation),
`communality`, `ICC`, and `cross_corr`, across separate `unit`/`unit_obs`/
`phy` tiers, in ONE call. This Julia driver covers only the `Sigma` entries
at the single `:unit`-equivalent tier `sigma_y_site` computes (GLLVM.jl has
one site-level Σ_y, not R's separate unit/unit_obs tiers). `level` is kept
as a keyword and validated (only `:unit` accepted) rather than silently
accepted-and-ignored. The other summaries are already independently
reachable via direct `bootstrap_ci_derived` calls on `communality`/
`correlation`; a unified multi-summary table matching R's return shape is
future work, not built in this slice. Cost is `O(p²)` bootstrap runs (one
`bootstrap_ci_derived` call per matrix entry) — fine for small fixtures,
expensive at large `p`; documented in the docstring.

## tmbprofile_wrapper / profile_targets / profile_phylo_signal — curve, not just bounds

R's `tmbprofile_wrapper()` calls `TMB::tmbprofile()` to get a raw
`(parameter value, deviance)` TRACE, then reduces it to `(lower, upper)` via
`.profile_bounds()`. GLLVM.jl's existing `profile_ci`
(`src/confint_profile.jl`) already reproduces that REDUCED bound but never
materialised the trace — every constrained-refit deviance was computed and
discarded inside `_profile_bisect_side`. The new `tmbprofile_wrapper`
re-walks the SAME bracket-then-expand loop (reusing `_profile_wald_se` /
`_profile_refit_with_fixed` verbatim) but records every evaluated `(θ_i,
nll)` pair, then calls the existing `profile_ci` for the bound rather than
duplicating the root-finding. `profile_targets` batches this over several
named/indexed parameters into a `Dict`.

R's `profile_targets()` is a READINESS REGISTRY (which parameters a fit
COULD be profiled on, without running anything — needed there because
`TMB::tmbprofile()` needs a live `tmb_obj` checkpoint to run cheaply and
reversibly). GLLVM.jl's `profile_ci`/`tmbprofile_wrapper` have no comparable
checkpoint step, so running IS the cheap operation here; `profile_targets`
runs every target directly rather than reporting a separate readiness flag.
This is a deliberate estimand/interface difference from R, not a bug.

### profile_phylo_signal — scoped gap (deliberate, matches the `loading_ci`/`loading_profile` pattern)

`profile_phylo_signal(fit, t)` profiles the RAW packed parameter
`sigma_phy[t]` (the per-trait phylogenetic-unique SD scale), **not** the
composite phylogenetic-SIGNAL summary `phylo_signal(fit)[t]` (an H²-like
ratio of variance components) that `profile_ci_phylo_signal`
(`src/confint_derived.jl`, owned by a sibling agent today) already profiles
via its own constrained-refit-WITH-PENALTY machinery on that nonlinear
derived quantity. Building a curve variant of THAT quantity needs the
identical penalty-profile plumbing `confint_derived.jl` already owns;
duplicating it in `confint_profile.jl` would create two divergent
implementations of the same profile rather than one canonical one. This
mirrors the required-source-case-map's own "estimand-alignment family"
deferral note already recorded for `loading_ci`/`loading_profile` — Julia
surface exists, but the two engines compute (partially) different
estimands, traced honestly on both sides rather than papered over.

## loading_ci / loading_profile — deliberately NOT built

Both rows were already REPAIR-deferred to `deferred[]` on 2026-09-01 in the
case map, with the reason: "Same confirmatory-fit gate as
inference/CI-ROUTE-005 — `loading_ci` refuses fits with no
`lambda_constraint` pins." GLLVM.jl has no `lambda_constraint`-pinned
confirmatory-fit mode (that is a **fit-mode feature**, not a CI function —
adding it means a new argument to `fit_gaussian_gllvm`/the family fitters
that pins specific Λ entries at construction time and threads that pin
through the optimiser, well beyond a post-fit CI wrapper). Building
`loading_ci`/`loading_profile` against the wrong (unpinned/exploratory) fit
would compute a DIFFERENT estimand than R's function and silently
misrepresent it as parity. Per the task brief ("implement ONLY the parts
expressible on existing fits and record the constrained-fit gap
honestly"), nothing was added for these two rows in this slice.

## Files touched

- `src/re_sd.jl` (new) — `getREsd` methods.
- `test/test_se_machinery.jl` (new) — standalone TDD suite (not wired into
  `test/runtests.jl`, which is owned by a sibling agent today).
- `src/confint_profile.jl` (append-only) — `tmbprofile_wrapper`,
  `profile_targets`, `profile_phylo_signal`, plus their internal
  `_tmbprofile_curve` helper. No existing function edited.
- `src/confint_derived_wald.jl` (append-only) — `bootstrap_Sigma`. No
  existing function edited.
- `src/GLLVM.jl` — one new `include("re_sd.jl")` line (after
  `extractors.jl`, since `getREsd` needs `sigma_y_site` and the family fit
  structs) and one new export line
  (`getREsd, bootstrap_Sigma, tmbprofile_wrapper, profile_targets,
  profile_phylo_signal`).

## Verification (standalone; full suite NOT run — that is a sibling
lane's job today per the task brief)

```
julia --project=. -e 'using GLLVM; println("OK")'   # clean load
julia --project=. test/test_se_machinery.jl          # 483 pass, 0 fail
```

Test tally: **483 passed, 0 failed, 0 errored** across 7 `@testset`s:
`getREsd Gaussian: exact vs direct dense (≤1e-10)`,
`getREsd Poisson: vs direct per-site Hessian inversion`,
`getREsd Poisson: AGHQ fit refuses`,
`bootstrap_Sigma matches bootstrap_ci_derived (same seed)`,
`tmbprofile_wrapper: curve + bounds agree with profile_ci`,
`profile_targets batches tmbprofile_wrapper`,
`profile_phylo_signal: scoped to sigma_phy[t], requires has_phy_unique`.
