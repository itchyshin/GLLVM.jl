# core070 docs cascade — missing-manual-entries fix

Owner (this task): documentation-writer. Branch `codex/core070-aghq-20260830`.
Scope: `docs/` tree only (`docs/src/**`, `docs/make.jl`) plus this notes file.
Did not touch `src/` or `test/`.

## The blocker

Documenter CI (run 33586904722) failed with `[:missing_docs]`: "86
docstrings not included in the manual" — every symbol landed by today's
core070 slices (extractors, derived-CI, diagnostics, SE machinery,
structured-term fitting, api-renames, estimand-alignment) had a docstring in
`src/` but no `@docs` block anywhere under `docs/src/`.

## What was read first

The nine slice-notes files under `docs/dev-log/core070/`:
`extractors-slice-notes.md`, `derived-ci-slice-notes.md`,
`diagnostics-slice-notes.md`, `se-machinery-slice-notes.md`,
`final-surface-slice-notes.md`, `structure-kwarg-notes.md`,
`api-rename-notes.md`, `estimand-alignment-notes.md`,
`nobs-adoption-notes.md`. These gave the honest scope/caveats used in the new
pages' orienting prose (tier-scoped `level=` defaults, GllvmFit-only coverage
on several functions, conditional-on-θ̂ SEs, the renamed-function shims, the
deliberate `loading_ci`/`loading_profile` non-build for the confirmatory-fit
gate — that last one turned out moot, since `se-machinery-slice-notes.md`
records those two rows as *already implemented* by the derived-ci slice
before the SE-machinery slice ran; both docstrings exist and are now on the
[Derived confidence intervals](../../derived-confidence-intervals.md) page).

## Page structure created

Six new `docs/src/*.md` pages, wired into `docs/make.jl`'s nav (`Guides &
Methods` and `Reference & Benchmarks` sections):

| Page | Symbols |
| --- | --- |
| `postfit-extractors.md` | `extract_Sigma`, `extract_Sigma_table`, `extract_loadings`, `extract_rotated_loadings`, `extract_residual_cov`, `extract_residual_cor`, `getResidualCov`, `getResidualCor`, `extract_communality`, `extract_correlations`, `extract_cross_correlations`, `extract_proportions`, `extract_Omega`, `extract_ICC_site`, `extract_repeatability`, `extract_cutpoints`, `extract_ordination`, `extract_phylo_signal` (18 names, several multi-method) |
| `derived-confidence-intervals.md` | `standardized_loading_wald_ci`, `raw_loading_wald_ci`, `loading_ci`, `loading_profile`, `repeatability_wald_ci`, `repeatability_bootstrap_ci`, `repeatability_ci`, `TwoLevelRepeatabilityProfileWithdrawn`, `profile_ci_total_variance`, `profile_ci_phylo_signal`, `slope_sd_ci` (11) |
| `diagnostics.md` | `sanity_multi`, `gllvmTMB_diagnose`, `check_gllvmTMB`, `gllvmTMB_check_consistency`, `check_auto_residual`, `diagnose_kernel_separability`, `fit_diagnostic_table`, `predictive_check`, `confint_inspect`, `compare_fits_Sigma_table`, `compare_loadings`, `compare_fits_dep_vs_two_psi`, `compare_fits_indep_vs_two_psi` (13), plus a "Renamed in this release" table for the five deprecated shims that live in these two files |
| `se-profile-machinery.md` | `latent_score_sd`, `bootstrap_Sigma`, `standard_errors`, `tmbprofile_wrapper`, `profile_curve_targets`, `profile_phylo_signal`, `profile_targets` (deprecated shim, documented but not promoted) (7) |
| `postfit-tables.md` | `tidy`, `Base.summary(::GllvmFit, ::AbstractMatrix)`, `GllvmSummary`, `deviance`, `rotate_loadings`, `extract_rotated_loadings_table`, `predict_missing`, `predict_cross_covariance`, `imputed`, `profile_cross_rho`, `profile_cross_rho_ci`, `extract_coevolution_modules`, `simulate_unit_trait` (13) |
| `structured-term-fitting.md` | `fit_gaussian_structured` (1, public); internal recognizer helpers cross-referenced to `low-level-reference.md` |

`low-level-reference.md` (existing page) got three new `@docs` clusters
appended, following its existing "names beginning with `_` are internal"
convention: the structured-term grammar recognizer (`GLLVM.SourceTermSpec`,
`GLLVM._recognize_source_term`, `GLLVM._source_term_covariance`,
`GLLVM._check_source_term_exclusions`, `GLLVM._read_literal_flag`,
`GLLVM._assert_no_augmented_lhs`, `GLLVM._resolve_kernel`,
`GLLVM._fit_gaussian_structured_sources`), and two standalone internal
helpers (`GLLVM._psd_sqrt_factor`, `GLLVM.LaplaceModeWorkspace`) — 10 names.

Total: 18 + 11 + 13 + 7 + 13 + 1 + 10 = **73 distinct symbol names**,
covering all **86** flagged docstrings (several symbols carry more than one
method-specific docstring — e.g. `extract_communality` has 3, `latent_score_sd`
has 5, `tmbprofile_wrapper` has 2 — and Documenter's `@docs` block pulls in
every method's docstring for a bare name in one entry, so one line per name
was sufficient; only `Base.summary` needed a signature-qualified entry
(`Base.summary(::GllvmFit, ::AbstractMatrix)`) to disambiguate from the
pre-existing single-arg entry already on `low-level-reference.md`).

## Deprecated forwarding shims — not promoted

Per the task brief, six deprecated names must not get a promoted manual
entry: `getREsd`, `compare_Sigma_table`, `compare_dep_vs_two_psi`,
`compare_indep_vs_two_psi`, `diagnostic_table`, `profile_targets`.

Checked each in `src/re_sd.jl`/`src/diagnostics.jl`/`src/confint_profile.jl`:
the first five have **no docstring at all** on their forwarding-shim
definitions (`function old(args...; kwargs...) = (Base.depwarn(...);
new(args...; kwargs...))` with no `"""..."""` above it) — so Documenter's
missing-docs check never touched them; nothing to exclude. Only
`profile_targets` has a docstring on its shim (explicitly stating it is
deprecated in favour of `profile_curve_targets`), so it needed an `@docs`
entry to satisfy the build — it is included on `se-profile-machinery.md`,
but the surrounding prose frames it purely as "renamed, not documented
further" rather than giving it its own explanation. `diagnostics.md` also
carries a short "Renamed in this release" table (with old → new mapping and
the one-line reason from `api-rename-notes.md`) covering all six names for a
reader who searches the old name, without promoting any of the five
docstring-less ones to an `@docs` block.

## A pre-existing bug this pass surfaced (not fixed — src/ is out of scope)

Three internal helper functions are `[`name`](@ref)`-cross-referenced from
*other* docstrings but have no docstring of their own:
`_laplace_mode` (`src/families/laplace.jl`/`binomial.jl`),
`_profile_ci_bounded` (`src/confint_derived.jl`), and `_principal_angles`
(`src/diagnostics.jl`, plain `#` comment, no `"""`). Pulling in the
docstrings that reference them (via the new `@docs` blocks above) turned
these into `[:cross_references]` build errors — `Cannot resolve @ref for
md"[`_laplace_mode`](@ref)"` etc. Since these three functions have no
docstring, they cannot be given an `@docs` entry (Documenter requires an
actual docstring to exist). Worked around on the docs side only: added a
"Cross-referenced internal helpers without a docstring" subsection to
`low-level-reference.md` with a plain Markdown header per name (`###
\`_laplace_mode\``, etc.) and a short description sourced from the calling
code's own comments — Documenter's `@ref` resolves against a matching header
anchor as well as a docstring, so this satisfies the cross-reference check
without inventing a docstring that doesn't exist in `src/`. Flagging for a
future `src/`-owning slice: adding a one-line docstring to these three
functions would make this workaround unnecessary and is the more normal fix,
but that edit belongs to `src/`, outside this task's ownership boundary.

## Lane-check note

The pre-edit hook on `docs/make.jl` flagged that `origin/codex/non-gaussian-fitter-gradients`
and `codex/poisson-laplace-analytic-gradient` carry their own commits
touching `docs/make.jl` not present in this checkout. Not investigated
further — this task's edit only appends new nav entries inside the existing
`"Guides & Methods"`/`"Reference & Benchmarks"` arrays; it does not remove or
reorder anything from the version already on this branch. Flagging for the
maintainer/Shannon at merge time in case the other lanes' `make.jl` diffs
overlap structurally.

## Verification

Both the exact CI invocation and the local-preview invocation build clean,
zero missing-docs errors, zero cross-reference errors:

```
$ julia --project=docs docs/make.jl
...
[ Info: CheckDocument: running document checks.
[ Info: Populate: populating indices.
[ Info: RenderDocument: rendering document.
[ Info: DocumenterVitepress: rendering MarkdownVitepress pages.
┌ Warning: Documenter could not auto-detect the building environment. Skipping deployment.
└ @ Documenter ~/.julia/packages/Documenter/V8kkd/src/deployconfig.jl:95
...
[ Info: Found no bases suitable for deployment (empty bases are skipped).
Copied: .../docs/build/.documenter/components/AuthorBadge.vue
Copied: .../docs/build/.documenter/components/Authors.vue
Copied: .../docs/build/.documenter/components/SidebarDrawerToggle.vue
Copied: .../docs/build/.documenter/components/VersionPicker.vue
```

No `[:missing_docs]` or `[:cross_references]` error anywhere in the log
(the CI job's deploy step is skipped locally only because no GitHub Actions
environment is detected — that is expected outside CI and orthogonal to the
missing-docs blocker this task fixes). `julia --project=docs docs/make.jl
--local` (the local-preview invocation, writes `versions.js`) also builds
clean and renders a full Vitepress site under `docs/build/`.

## Files touched

- `docs/make.jl` — nav entries for the six new pages (append-only, existing
  entries and ordering preserved).
- `docs/src/low-level-reference.md` — three new `@docs` clusters +
  ref-only-header subsection (append-only).
- `docs/src/postfit-extractors.md` (new)
- `docs/src/derived-confidence-intervals.md` (new)
- `docs/src/diagnostics.md` (new)
- `docs/src/se-profile-machinery.md` (new)
- `docs/src/postfit-tables.md` (new)
- `docs/src/structured-term-fitting.md` (new)
- `docs/dev-log/core070/docs-cascade-notes.md` (this file)
