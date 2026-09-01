# Cluster 1 — post-fit extractor family (src/extractors.jl)

Branch: `codex/core070-aghq-20260830` (worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`). Scope: the ~30
`BLOCKED_NEEDS_JULIA_SURFACE` rows in
`docs/dev-log/core070/required-source-case-map.json` naming the R
`extract_*`/`get*` post-fit accessor family. Owned files: `src/extractors.jl`
(new), `test/test_extractors.jl` (new), the include/export lines added to
`src/GLLVM.jl` and the one include line added to `test/runtests.jl`, and this
notes file. Did not touch `src/confint*`, `src/twolevel.jl`, `src/formula.jl`,
`docs/make.jl`, or any other file — everything reused there is called
unqualified from inside the `GLLVM` module, not duplicated.

## Target list — derived from the ledger, not the work-order prose

Ran the ledger query first (33 rows, `disposition ==
"BLOCKED_NEEDS_JULIA_SURFACE"`, evidence naming one of the Cluster-1 function
names):

```
extract_repeatability      × 4  (inference/CI-ROUTE-008..011)
getLoadings, getREsd, getResidualCor, getResidualCov   (namespace/export/*)
extract_Gamma, extract_ICC_site, extract_Omega, extract_Sigma (×2, incl.
  extract_Sigma_table), extract_coevolution_modules, extract_communality,
  extract_correlations, extract_cross_correlations, extract_cutpoints,
  extract_loadings, extract_lv_effects, extract_ordination,
  extract_phylo_signal, extract_proportions, extract_repeatability,
  extract_residual_cor, extract_residual_cov, extract_residual_split,
  extract_rotated_loadings, getLV, getLoadings, getREsd, getResidualCor,
  getResidualCov   (postfit/POSTFIT-SURFACE-*)
```

33 rows total (matches the work order's "~30 rows" estimate).

## Cross-check against what already exists (mid-flight correction applied)

Before writing anything, cross-checked every target name against
`src/postfit.jl` (2500+ lines), `src/confint_derived.jl`,
`src/twolevel.jl`, `src/link_residual.jl`, `src/ordination.jl`, and
`src/extract_gamma.jl`. Three names in the ledger were **already
implemented and exported** by other lanes before this slice started:

- `extract_Gamma` — `src/extract_gamma.jl`, exported.
- `extract_lv_effects` — `src/postfit.jl`, exported, with per-family methods
  (`GllvmFit`, `BinomialFit`, `PoissonFit`, `NBFit`, `GammaFit`, `BetaFit`,
  `OrdinalFit`).
- `getLV`, `getLoadings` — `src/postfit.jl`, exported (`getLoadings(fit;
  rotate::Bool=true)`; note this differs from the R signature — see
  "Deliberate deviations" below).

These are **not touched** by this slice (no re-export, no re-definition —
`GLLVM.jl` loads with zero "overwriting" warnings). Their ledger rows stay
`BLOCKED_NEEDS_JULIA_SURFACE` only because the receipted conversion batch
that flips the disposition hasn't run yet — that conversion is explicitly
out of this slice's scope ("later be converted by a receipted batch").

Also reused without duplication (all pre-existing, unexported-but-in-module
where noted):

- `_loadings`, `getLoadings`, `rotation`, `_svd_rotation` (postfit.jl)
- `ordination` (ordination.jl, exported)
- `sigma_y_site`, `communality`, `correlation`, `proportions` (unexported),
  `phylo_signal` (confint_derived.jl; `sigma_y_site`/`communality`/
  `correlation`/`phylo_signal` exported, `proportions` is not)
- `sigma_y_site`, `communality`, `correlation`, `link_residual`
  (link_residual.jl — non-Gaussian latent-scale twins, dispatched on
  `_NonGaussianLatentFit = Union{PoissonFit,NBFit,BetaFit,GammaFit}` plus
  `BinomialFit`/`OrdinalFit`/`OrdinalPerTraitFit`; exported)
- `repeatability`, `communality_B`, `communality_W`, `correlation_B`,
  `correlation_W` (twolevel.jl, exported)

`src/extractors.jl` is a thin `extract_*`/`get*` naming layer over this
machinery, plus a handful of genuinely new pieces (below). No existing
function was refactored or re-implemented.

## What `src/extractors.jl` newly implements

Dispatched mainly on `GllvmFit` (the Gaussian J1/J2/J3 engine) and
`TwoLevelFit`, with non-Gaussian `extract_communality`/`extract_correlations`
methods forwarding to `link_residual.jl`'s generics:

- `extract_Sigma(fit; level, part)` — unified covariance API. `level ∈
  (:unit, :unit_obs, :site)` (legacy `:B`/`:W` aliases accepted, mirroring
  R's `.normalise_level()`); `part ∈ (:total, :shared, :unique)`. New
  closed-form logic for the `GllvmFit`/`TwoLevelFit` tier split (`v_B,t =
  (Λ_BΛ_B')_tt + σ²_B,t`, `v_W,t = (Λ_WΛ_W')_tt + σ²_W,t + σ²_eps`, matching
  the formula documented in the R oracle's `extract-repeatability.R`);
  `:site` reuses `sigma_y_site(fit)` exactly.
- `extract_Sigma_table(fit; level, part)` — tidy `Vector{NamedTuple}` long
  format (`trait_i, trait_j, value`) over the upper triangle of
  `extract_Sigma(...).Sigma`.
- `extract_loadings(fit; rotate::Bool=true)` — forwards to `getLoadings`.
- `extract_rotated_loadings(fit)` — `(Λ=getLoadings(fit;rotate=true),
  R=rotation(fit))`.
- `extract_communality`, `extract_correlations` — `GllvmFit` forwards to
  `communality`/`correlation`; `TwoLevelFit` dispatches `level` to
  `communality_B/W`/`correlation_B/W`; non-Gaussian forwards to
  `link_residual.jl`'s generics.
- `extract_cross_correlations(fit; level, traits_i, traits_j)` — positional
  submatrix slice of `extract_correlations`.
- `extract_residual_cov`/`extract_residual_cor` + `getResidualCov`/
  `getResidualCor` aliases — thin re-slice of `extract_Sigma(...; part=
  :total)`.
- `extract_ordination(fit, Y; rotate)` — forwards to `ordination`.
- `extract_cutpoints(fit::OrdinalFit)` / `(fit::OrdinalPerTraitFit)` — reads
  `fit.τ`/`fit.C` directly.
- `extract_proportions(fit::GllvmFit; component)` — forwards to
  `proportions`.
- `extract_phylo_signal(fit::GllvmFit; Σ_phy)` — forwards to
  `phylo_signal`.
- `extract_repeatability(fit::TwoLevelFit)` — forwards to `repeatability`.
- `extract_ICC_site` — new closed form for `GllvmFit` (`v_B/(v_B+v_W)` from
  `extract_Sigma` tiers, NaN-safe like R's `.safe_icc_ratio()`); for
  `TwoLevelFit` it equals `extract_repeatability` (documented as such).
- `extract_Omega(fit::GllvmFit)` — new: sums the `:unit` + `:unit_obs`
  tiers (+ the phylogenetic `Λ_phy_aug Λ_phy_augᵀ` block when present),
  mirroring `extract_Omega`'s auto-tier-detection sum with
  `link_residual="none"` (no non-Gaussian link residual on a Gaussian fit).

## Deliberate deviations from R (documented in docstrings too)

- `extract_loadings`/`getLoadings` take a `rotate::Bool`, not R's `level` +
  `rotate ∈ {"none","varimax","promax"}` — GLLVM.jl's `_loadings` reads a
  single loadings matrix per fit type (no Julia-bridge rotation gate to
  special-case) and only has the canonical SVD rotation, not varimax/promax.
- `extract_cross_correlations` uses positional integer trait indices, not
  R's name-based subsetting — matches the existing GLLVM.jl convention in
  `extract_Gamma` (`row_traits`/`col_traits` are positional there too).
- No Fisher-z / Wald / bootstrap confidence-interval columns on any
  `extract_*` return here — R's `extract_repeatability`, `extract_communality`,
  `extract_correlations`, `extract_phylo_signal` all carry `ci=TRUE`
  data-frame returns with `lower`/`upper`/`method` columns. That is Cluster 2
  of the work order (derived-CI surfaces, `src/confint_derived*.jl` +
  `src/twolevel.jl`), explicitly out of this slice's file ownership. This
  slice returns point estimates only.
- Loading signs are never compared to R. `extract_rotated_loadings`'s `R` is
  the existing sign-fixed SVD rotation (`_svd_rotation`, largest-magnitude
  convention); every quantity checked against a closed form here is
  rotation/sign-invariant (Σ, communality, correlation, Ω, ICC).

## Still blocked (no stub — listed per the task brief)

- **`extract_residual_split`** — R's version (R/extract-omega.R) computes an
  explicit σ²_d / σ²_e / σ²_total decomposition for an OLRE
  (observation-level random effect) fit, keyed off a specific
  `indep(0+trait|obs-level)` term tag. GLLVM.jl's `K_W`/`has_diag` tier is a
  general within-unit reduced-rank+diagonal block, not an OLRE-tagged fit
  type, and the split further requires the full 17-family
  `link_residual_per_trait()` bank (`R/extract-sigma.R`) wired to that tag.
  `src/link_residual.jl` covers 6 families (Poisson/NB/Beta/Gamma/Binomial/
  Ordinal) generically, not the OLRE-specific split. No Julia surface exists
  for this quantity; not stubbed.
- **`extract_coevolution_modules`** — R's version (R/extract-sigma.R:2203)
  performs a module/eigen-decomposition of the coevolution axes on top of
  `extract_Gamma`'s cross-lineage block (matrix inverse-sqrt whitening +
  per-axis table construction, `.coevolution_axis_table()`). No Julia
  coevolution fit type (`CoevolutionGLMFit`, `fit_coevolution_gaussian`,
  `fit_coevolution_blockna`) computes or exposes this module decomposition.
  Genuinely new numerical work, not a thin readout; not attempted here.
- **`getREsd`** — R's version reads TMB `sdreport()`-style marginal standard
  errors of the random effects from the joint precision
  (`R/re-uncertainty.R`). This is Hessian/SE machinery — the same family as
  Cluster 2's CI surfaces — not a point-estimate readout of an
  already-computed quantity, and no accessor for per-random-effect SDs
  exists anywhere in GLLVM.jl today (`grep -rniE 'getREsd|re_sd' src/*.jl`
  returns 0 hits outside this note). Left blocked rather than approximated.

## Verification

- `using GLLVM` loads cleanly against the patched module (no method-overwrite
  warnings — confirms no collision with `postfit.jl`/`confint_derived.jl`/
  `twolevel.jl`/`link_residual.jl`/`ordination.jl`/`extract_gamma.jl`, all of
  which this slice reuses rather than duplicates).
- Standalone: `julia --project=. -e 'using GLLVM; include("test/test_extractors.jl")'`
  → **`71/71` pass** (27.8s), re-run and reconfirmed after the compiled
  module rebuilt.
- Targeted regression-adjacent subset — every file `src/extractors.jl`
  depends on or forwards to, run together in one process:
  `test_confint_derived.jl` + `test_twolevel.jl` + `test_ordination.jl` +
  `test_postfit.jl` + `test_extractors.jl` → **`1308/1308` pass** (1m21s).
- **Full-suite regression pass (`julia --project=. test/runtests.jl`, all
  ~300 files) is DEFERRED to the orchestrator's single consolidated Totoro
  run covering all three concurrent core070 slices together.** Multiple
  local attempts in this worktree were killed mid-suite under machine load
  (15-20, several concurrent agent sessions on the same shared Mac,
  including an unrelated `DRM.jl` process and sibling core070 lanes' own
  full-suite attempts) — every local attempt either died silently within
  ~1-2 minutes with zero bytes written, or (one run) ran ~35 minutes under
  heavy contention before being reaped, in both cases before reaching a
  trustworthy `Test Summary` line. The coordinator confirmed sibling lanes
  hit the identical failure mode and redirected all three slices to a
  single post-close Totoro run rather than each lane repeatedly contending
  for the same local machine. `test/runtests.jl` was touched only by the one
  `include("test_extractors.jl")` line this slice added, so nothing about
  this slice should change the full-suite outcome beyond adding its own 71
  passing assertions — the standalone and targeted-subset runs above are
  the evidence for that until the consolidated run lands.

## Commits

1. `feat(extractors): post-fit extractor family (Cluster 1)` —
   `src/extractors.jl`, `src/GLLVM.jl` (include + export lines).
2. `test(extractors): closed-form + forwarding checks for the extractor
   family` — `test/test_extractors.jl`, `test/runtests.jl` (include line).
3. `docs(core070): extractors slice notes` — this file.
