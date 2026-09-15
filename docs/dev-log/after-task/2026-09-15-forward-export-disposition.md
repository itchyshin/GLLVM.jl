# After-task — FORWARD export parity disposition (77 R names)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (true-parity `/goal`, parallel dispatch — **forward export only**)  
**Branch:** `docs/forward-export-disposition-20260915` from `origin/main` @ `0da63860`  
**Worktree:** `/Users/z3437171/local-scratch/lanes/GLLVM.jl-forward-export-disposition-20260915` (isolated; **not** `feat/second-order-delta-followup-20260915`)  
**Scope:** Docs-only disposition inventory — **no** `src/`, **no** `Project.toml`, **no** ledger JSON mutation, **no** `covered` promotion, **no** gllvmTMB engine surgery.

## Rose fence

- **This file classifies FORWARD gaps; it does not close them, rebind `parity_ledger.py`, or promote capability rows.**
- **FORWARD=77** is a **name-twin** counter at the frozen R oracle (`b4d5fee6`); many rows are **engine-present / export-absent** or **R-only refuse**, not greenfield engine work.
- Follow-on from `docs/dev-log/after-task/2026-09-15-true-parity-ledger-gap-inventory.md` (item 3 complete); complements Layer 3 there with per-export dispositions.

## Checks run

```text
python3 tools/parity_ledger.py          # FORWARD=77 REVERSE=92 @ frozen oracle
Rscript ../gllvmTMB/tools/parity_ledger.R   # read-only twin join (48 matched, 6 DIFFER)
graft ask "export bridge parity forward renamed twins" --source
```

Measured @ programme HEAD (`0da63860`):

| Bucket | Count | Meaning |
|--------|------:|---------|
| **TWIN_ALIAS** (re-bind name or thin export wrapper) | **18** | Julia capability exists under `fit_*`, `extract_*`, or `gllvm` — FORWARD gap is export/ledger hygiene |
| **PARTIAL_DECISION** | **2** | `indep`, `scalar` — Dest B engine paths exist; maintainer promotion of **export names** pending |
| **FORMULA_EXPORT_NEEDED** | **17** | `@formula` / keyword router exports (`latent`, `traits`, `phylo_*`, `spatial_*`, …) — aligns with ledger `BLOCKED_NEEDS_JULIA_SURFACE` minus true-missing rows |
| **TRUE_MISSING** | **12** | No honest Julia twin yet (meta, iSDM, slopes, confirmatory λ tooling, long-format simulate, pedigree exports) |
| **R_ONLY_REFUSE** | **1** | `gllvm_julia_setup` — R+JuliaCall bootstrap; Julia target is `bridge_fit` |
| **INTENTIONALLY_EXCLUDED** | **27** | Plots, screen workflow, unported mix/delta export names, VP/block_V, `truncated_nbinom1` export alias — not owed as Julia exports |

Companion table (ranked executable order): `docs/dev-log/core070/forward-export-disposition-20260915.tsv`.

## Disposition legend

| Code | Action |
|------|--------|
| **TWIN_ALIAS** | Add `parity_ledger.py` `ALIASES` row and/or export thin wrapper — **no new likelihood** |
| **PARTIAL_DECISION** | Ledger disposition + maintainer G0 on export-name promotion (Dest B) |
| **FORMULA_EXPORT_NEEDED** | Destination B / formula recognizer slice — engine often already on `main` |
| **TRUE_MISSING** | New public surface or R-only scope (iSDM, meta, slopes) |
| **R_ONLY_REFUSE** | Document as R-bridge-only; Julia ledger should not expect a twin export |
| **INTENTIONALLY_EXCLUDED** | Reclassify ledger `required_core` export rows to dispositioned non-owed (future tool pass) |

---

## Ranked inventory — all 77 FORWARD gaps

### A — TWIN_ALIAS (18) — twin exists under a different Julia name

| R export | Julia twin (current) | Notes |
|----------|----------------------|-------|
| `dep` | `fit_dep_gllvm` | None×dep; `docs/design/capability-status.md` implemented (function API) |
| `Beta` | `Beta` (Distributions) + `fit_beta_gllvm` | **False FORWARD gap** — marker exported; tool lacks alias |
| `kernel_indep` | `fit_kernel_indep_gllvm` | Design 65 dense kernel C1 |
| `kernel_dep` | `fit_kernel_dep_gllvm` | Twin join AGREE |
| `kernel_latent` | `fit_kernel_latent_gllvm` | Twin join AGREE |
| `kernel_scalar` | `fit_kernel_indep_gllvm` + common variance | Modifier = `indep(..., common=TRUE)` |
| `kernel_unique` | `fit_kernel_latent_gllvm` + diag ψ | Modifier on latent tier |
| `animal_dep` | `fit_animal_dep_gllvm` | Gaussian matrix API |
| `animal_latent` | `fit_animal_latent_gllvm` | Gaussian matrix API |
| `animal_indep` | `relatedness_cov` + indep Gaussian route | Engine partial; name export owed |
| `animal_scalar` | `relatedness_cov` + common variance | Scalar modifier pattern |
| `extract_Sigma_B` | `extract_Sigma(fit; level=:unit, part=:total)` | Used in `postfit_tables.jl` as Sigma_B |
| `extract_Sigma_W` | `extract_Sigma(fit; level=:unit_obs, part=:total)` | Same |
| `extract_residual_split` | `extract_residual_cov`, `link_residual` | Not identical API shape |
| `flag_unreliable_loadings` | `check_gllvmTMB`, `gllvmTMB_diagnose` | Partial threshold parity |
| `gllvmTMB_wide` | `gllvm(@formula(...), Y, data)` | Wide-matrix formula entry |
| `.proportions_bootstrap_ci` | `extract_proportions` + bootstrap CI | R internal; user-layer twin |
| `.proportions_wald_ci` | `extract_proportions` + Wald | R internal |

### B — PARTIAL_DECISION (2)

| R export | Julia route | Blocker |
|----------|-------------|---------|
| `indep` | `fit_gllvm` / none×indep | Export-name promotion vs modifier semantics (Dest B Arc 0) |
| `scalar` | `indep(..., common=TRUE)` | Same |

### C — FORMULA_EXPORT_NEEDED (17)

Ledger already marks these `BLOCKED_NEEDS_JULIA_SURFACE` — disposition here is **public formula/keyword export**, not net-new engine in most cases.

| R export | Engine / scaffold on Julia side |
|----------|-----------------------------------|
| `latent` | `fit_gllvm`, family fitters |
| `traits` | `@formula` wide LHS (Destination B) |
| `phylo` | Phylo router; sparse/contrast/edge paths |
| `phylo_indep` | `fit_phylo_gaussian`, precision payloads |
| `phylo_latent` | `fit_phylo_gaussian`, `fit_phylo_glm` |
| `phylo_dep` | `fit_phylo_dep_gllvm` |
| `phylo_scalar` | Phylo indep + common variance |
| `phylo_unique` | Phylo latent + diag ψ |
| `phylo_rr` | RRR / constrained ordination partial |
| `phylo_signal_mi` | `phylo_signal` + interval extractors |
| `spatial` | SPDE / spatial router |
| `spatial_indep` | `spatial_cov` + indep |
| `spatial_latent` | `fit_spde_latent_gllvm` |
| `spatial_dep` | `fit_spatial_dep_gllvm` (fail-loud Arc 0) |
| `spatial_scalar` | Spatial indep + common variance |
| `spatial_unique` | Spatial latent + unique ψ |
| `spde` | SPDE mesh + latent field fitters |
| `animal_unique` | Animal latent + unique ψ (no export) |

### D — TRUE_MISSING (12)

| R export | Why true missing |
|----------|------------------|
| `meta` | Meta-analytic GLLVM keyword — no Julia public surface |
| `meta_V` | Known-sampling-covariance keyword — deferred meta arc |
| `isdm_source` | iSDM programme — R public, Julia absent |
| `isdm_sources` | iSDM multi-source registry |
| `pedigree_to_A` | Pedigree → A matrix; Julia builders exist without R export names |
| `pedigree_to_Ainv_sparse` | Sparse precision builder export |
| `phylo_slope` | **Deferred** — slopes arc after phylo transport (`true-parity-decision-map.md`) |
| `animal_slope` | **Deferred** — same |
| `confirmatory_lambda` | Confirmatory λ tooling — **Deferred** (adjacent to D3 `loading_profile`; Stage 1 explicitly out of scope here) |
| `simulate_site_trait` | Long-format unit×trait simulator export |
| `suggest_lambda_constraint` | R Heywood / loading constraint helper |
| `suggest_lambda_constraints` | Plural form of above |

### E — R_ONLY_REFUSE (1)

| R export | Reason |
|----------|--------|
| `gllvm_julia_setup` | R-side JuliaCall session bootstrap (`namespace-2-batch-contract.json`); Julia analogue is **`bridge_fit`** invoked from R, not a Julia export |

### F — INTENTIONALLY_EXCLUDED (27)

Not owed as Julia **export name** twins (viz, screening, unported mix constructors). Ledger should disposition in a future **tool-only** pass — **not** this docs slice.

| R export | Class |
|----------|-------|
| `VP`, `block_V` | Variance/meta helpers |
| `delta_beta`, `delta_gamma_mix`, `delta_gengamma`, `delta_lognormal_mix`, `delta_poisson_link_gamma`, `delta_poisson_link_lognormal`, `delta_truncated_nbinom1`, `delta_truncated_nbinom2` | Unported / alternate delta export names |
| `gamma_mix`, `gengamma`, `lognormal_mix`, `nbinom2_mix` | Mix family constructors not mirrored as exports |
| `plot_Sigma_comparison`, `plot_Sigma_heatmap`, `plot_Sigma_table`, `plot_anisotropy`, `plot_anisotropy2`, `plot_correlations`, `plot_loadings_confidence_eye`, `plot_rotated_loadings` | R ggplot postfit viz |
| `ridge_path`, `screen_gllvmTMB`, `screen_table` | R screening / diagnostic workflows |
| `truncated_nbinom1` | R export name; Julia engine uses `TruncatedNegBin1` marker |

---

## Top 10 next **executable** Julia surfaces

**Hard excludes:** `loading_profile` Stage **1**, **S4 probe** (maintainer G0 / second yes).

| Rank | Slice | Disposition class | Closes true parity? |
|------|-------|-------------------|---------------------|
| **1** | **`parity_ledger` ALIASES batch** — `dep`, `kernel_*`, `animal_dep`/`animal_latent`, `Beta`, `extract_Sigma_B/W` | TWIN_ALIAS (tool + optional export wrappers) | **No** — tool hygiene; shrinks FORWARD count honestly |
| **2** | **Thin export wrappers** — `extract_Sigma_B`, `extract_Sigma_W`, optional `dep()` → `fit_dep_gllvm` | TWIN_ALIAS | **Partial** — postfit R script portability |
| **3** | **`gllvmTMB_wide` deprecated alias** → `gllvm` wide API | TWIN_ALIAS | **Partial** — reader migration |
| **4** | **`pedigree_to_Ainv_sparse` export** atop `AugmentedPhy` / sparse phy builders | TRUE_MISSING → TWIN_ALIAS | **Partial** — phylo transport S2 |
| **5** | **`indep` / `scalar` export promotion** after maintainer G0 (Dest B) | PARTIAL_DECISION | **Partial** — formula grid none-row |
| **6** | **`traits()` + `latent()` formula recognizers** (Destination B A4) | FORMULA_EXPORT_NEEDED | **Partial** — largest user-visible R grammar gap |
| **7** | **`phylo_indep` / `phylo_latent` keyword exports** wiring to existing fitters | FORMULA_EXPORT_NEEDED | **Partial** — bridge + phylo transport |
| **8** | **`spatial_indep` / `spatial_latent` public exports** to SPDE fitters | FORMULA_EXPORT_NEEDED | **Partial** — spatial row honesty (incl. `spatial × dep` DIFFER) |
| **9** | **`flag_unreliable_loadings` port** from R thresholds into `check_gllvmTMB` | TWIN_ALIAS / postfit | **Partial** — diagnostics parity |
| **10** | **`simulate_site_trait`** long-format simulator export | TRUE_MISSING | **Partial** — simulation API parity |

**Not ranked here (deferred / other lane):** meta/iSDM family, slopes (`phylo_slope`, `animal_slope`), confirmatory λ, `loading_profile` Stage 1, S4.

---

## Top 5 — twin renames vs true missing (actionable)

### Twin renames (fastest FORWARD shrink)

1. **`dep` → `fit_dep_gllvm`** (none×dep engine shipped)  
2. **`kernel_indep` / `kernel_dep` / `kernel_latent` → `fit_kernel_*_gllvm`** (capability rows AGREE / implemented)  
3. **`extract_Sigma_B` / `extract_Sigma_W` → `extract_Sigma` with `level` kw** (postfit already uses this internally)  
4. **`Beta` → already-exported `Beta` marker** (ledger false gap; ALIASES only)  
5. **`gllvmTMB_wide` → `gllvm` wide-matrix `@formula` path** (R wrapper soft-deprecated)

### True missing (needs new arc, not an alias)

1. **`traits()` + full keyword router** (`latent`, grid sources) — Destination B  
2. **`meta` / `meta_V`** — meta-analytic keyword surface  
3. **`isdm_source` / `isdm_sources`** — iSDM programme  
4. **`phylo_slope` / `animal_slope`** — deferred slopes arc  
5. **`confirmatory_lambda`** — deferred confirmatory estimand (adjacent D3; not Stage 1)

---

## Twin capability join (read-only reminder)

From gllvmTMB `tools/parity_ledger.R` @ Julia `origin/main`:

- **6 DIFFER** rows still require status honesty before any promotion (`spatial × dep`, phylo_latent+lv, multinomial, coverage certificate, AGHQ, mixed-family vector).
- **21 R-NARROWER** rows: Julia `implemented` vs R `scope-limited` — promotion fence, not automatic FORWARD work.

---

## Follow-up (not done in this slice)

- Pending board: pointer to this file under forward-export / item 3 sibling.
- **`tools/parity_ledger.py` ALIASES update** — separate bounded tool PR (not docs-only).
- **`required-source-case-map.json` re-disposition** — maintainer batch; **no JSON edit here**.

## Graft

- `parity_ledger.py`, `_bridge_fit_onepart` — bridge/export crux (`graft ask`, read-only).
