# Wave-6 conversion batch notes (core070 conversion batch #2)

Reference commit: `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
Contract: `docs/dev-log/core070/wave6-conversion-batch-contract.json`.
Runner: `tools/core070_wave6_conversion_batch.R` -> `tools/core070_wave6_conversion_batch.jl`.
Verifier: `tools/core070_verify_wave6_conversion_batch.py`.

## Scope

Batch #2 targets `BLOCKED_NEEDS_JULIA_SURFACE` rows in
`docs/dev-log/core070/required-source-case-map.json` whose Julia surface now
exists but was **not** in wave-5 (`docs/dev-log/core070/surface-conversion-batch-contract.json`,
20 executable + 21 deferred, 41-row target). Two source groups, both traced
against the live `required-source-case-map.json` (769 rows; 117 currently
`BLOCKED_NEEDS_JULIA_SURFACE`):

### Group 1 — STRUCTURED-TERM rows unlocked by the formula recognizer

Commit `5371137c` (`feat(formula): structured-term recognizer`) landed
`src/formula.jl`'s `_recognize_source_term` / `_fit_gaussian_structured_sources`
(lines 340-646), implementing `docs/dev-log/core070/formula-recognizer-spec.md`
Sec 2 Steps 0-6. That spec's own "Post-verification correction" (2026-09-01)
tallies exactly **9 implementable rows**:

- `namespace/export/{indep, scalar, kernel_indep, kernel_dep, kernel_scalar,
  kernel_latent, kernel_unique}` — 7 rows
- `covariance/{COV-KERNEL-LATENT, COV-KERNEL-FOLDED-UNIQUE}` — 2 rows

All 9 are executable (verified against the current `required-source-case-map.json`:
all 9 source_ids are still listed `BLOCKED_NEEDS_JULIA_SURFACE` as of this batch,
confirming they were not paid in wave-5). Case design:

- `indep`, `scalar`, `kernel_indep`, `kernel_dep`, `kernel_scalar`: single-term
  fits on the `structured_kernel_small` fixture (reused **verbatim** from
  `test/parity/fixtures/core070_structured_data.R` — deterministic, no RNG:
  `expand.grid(site=1:12, trait=1:3)`, `species` = 3 levels of 4 sites each,
  `value = sin(idx/3) + trait_int/5`, `C`/`K2` PD 3x3 species kernels).
- `kernel_latent` + `kernel_unique` + `covariance/COV-KERNEL-FOLDED-UNIQUE`:
  all three ledger rows paid by the **same** fit,
  `kernel_latent(species, K=C, d=1, name="k1", unique=TRUE)` — this is
  `structured-required-case-plan.json`'s `STRUCT-KER-SINGLE-PSI` case,
  reference call reused verbatim. `kernel_unique` has **no standalone**
  `SourceCovariance` mode (`_source_term_covariance` throws for a bare
  `:kernel_unique` spec, `src/formula.jl:604-606`); the only Julia surface for
  it is this fold, matching the spec's "Julia comparand is the fold" framing.
- `covariance/COV-KERNEL-LATENT`: `STRUCT-KER-MULTI` — two
  `kernel_latent(..., unique=FALSE)` terms. Verified `fit_gaussian_sources`
  (`src/source_fit.jl:290-307`) already accepts an arbitrary-length `sources`
  vector with no single-source restriction — the "Step 7: multi-source lift"
  restriction the spec flags is **bridge-only** (`src/bridge.jl:2031-2034`'s
  R<->Julia marshalling), and `_fit_gaussian_structured_sources` bypasses the
  bridge entirely, calling `fit_gaussian_sources` directly. So `STRUCT-KER-MULTI`
  is executable through the recognizer today, contrary to a naive reading of
  "Step 7 not done."
- `STRUCT-KER-MULTI-PSI-PRUNED` (two `kernel_latent(..., unique=TRUE)` terms) is
  **not** used for any paired-numerics case: `structured-required-case-plan.json`
  marks it `BLOCKED_REFERENCE_PARAMETER_LOSS` — an R-side reference defect
  (silently drops parameters on the multi-kernel + unique=TRUE combination).
  Per `formula-recognizer-spec.md` Sec 3.4 ("R-side reference defects... never
  reproduce"), this is not asserted anywhere in this batch.
- 4 rejection-path cases assert **both** engines refuse: `dep`+`indep`,
  `dep`+`kernel_latent`, `indep`+`kernel_latent` (the exclusion-gate quartet,
  `GLLVM._check_source_term_exclusions`, `src/formula.jl:538-559`, porting
  fit-multi.R's guard quartet), and a standalone `kernel_unique(...)` term
  (no fold partner).

### Group 2 — STALE-BLOCKED postfit rows

Checked all 9 names in the task's list against `src/GLLVM.jl`'s export list
(`grep -n "^export" src/GLLVM.jl`) and direct function definitions:

| Row | Julia surface | Verdict |
|---|---|---|
| `extract_rotated_loadings_table` | `extract_rotated_loadings(fit)` (`src/extractors.jl:233`, exported) — matrix form, R returns a long table | **executable** (composed: flatten+sort both) |
| `extract_lv_effects` | `extract_lv_effects(fit::GllvmFit)` (`src/postfit.jl:353`, exported) but **hard-gates** on `_has_lv_predictor(fit)` (requires an `X_lv=` concurrent-ordination fit) | **deferred** — no reused fixture carries `X_lv` |
| `flag_unreliable_loadings` | no literal function; composed via `confint(fit; parm="Lambda")` zero-crossing, same composition the already-paid `namespace/export/flag_unreliable_loadings` row used (`docs/dev-log/core070/namespace-1-batch-contract.json`) | **executable** (composed) |
| `fitted.gllvmTMB_multi` | `StatsAPI.fitted(fit::AnyGllvmFit, data)` = `predict(...; type=:response)` (`src/postfit.jl:306`) | **executable** |
| `logLik.gllvmTMB_multi` | `StatsAPI.loglikelihood(fit::AnyGllvmFit)` (`src/postfit.jl:580`) — naming-convention difference only (R's S3 `logLik()` vs the StatsAPI.jl `loglikelihood()` idiom) | **executable** |
| `deviance.gllvmTMB_multi` | **no** `deviance` function/dispatch anywhere in `src/` for any Gllvm fit type (also absent from the export list) | **deferred** — composing an ad hoc definition without R source access risks the wrong estimand |
| `confint.gllvmTMB_multi` | `confint(fit::GllvmFit; ...)` (`src/confint.jl:246`) | **executable** |
| `nobs.gllvmTMB_multi` | `StatsAPI.nobs(fit::AnyGllvmFit)` (`src/postfit.jl:614`) | **executable**, but flagged `known_defect_pending_decision: true` — R returns `p*n` (cell count), Julia returns `n` (unit count); the case asserts each engine against its **own** formula, never R==Julia |
| `extract_Gamma` | `extract_Gamma(fit::GllvmFit; row_traits, col_traits)` (`src/extract_gamma.jl:36`, exported) requires a `Λ_phy`-bearing fit (`fit_gaussian_gllvm(...; K_phy>0, Σ_phy=K*)`); no reused fixture carries a phylo tier, and per `formula-recognizer-spec.md` Sec 1.5 the native `Σ_phy=` route is explicitly **not the same model** as any R gllvmTMB coevolution formula | **deferred** — identical deferral wave-5 already recorded for this same row |

7 executable, 2 deferred (`extract_lv_effects`, `extract_Gamma`) + 1 more
deferred (`deviance.gllvmTMB_multi`) = 9 rows total, matching the task's
named list exactly (the 9 names given, "and similar" not expanded further —
no other `postfit/POSTFIT-SURFACE-*` `BLOCKED_NEEDS_JULIA_SURFACE` row was
brought into scope; the remaining ~43 stay untouched for a future wave).

All postfit cases use `gaussian_small`, reused **verbatim** (seed 42,
`Lambda_true`, `sigma_true`) from `tools/core070_surface_conversion_batch.R`.

## Executable / deferred tally

Contract-verified totals (asserted by `docs/dev-log/core070/wave6-conversion-batch-contract.json`
and checked by `tools/core070_verify_wave6_conversion_batch.py`):
**15 executable contract cases / 18 target `source_id`s (15 executable + 3
deferred) / 4 rejection-path validation cases / 3 negative controls.**

Breakdown by group:

- **Group 1 (structured-term): 9 target source_ids, all 9 executable, 0
  deferred.** 7 namespace exports (`indep, scalar, kernel_indep, kernel_dep,
  kernel_scalar, kernel_latent, kernel_unique`) + 2 covariance rows
  (`COV-KERNEL-LATENT, COV-KERNEL-FOLDED-UNIQUE`), paid by **9 contract
  cases** (some `source_id`s share an underlying fit: the `kernel_latent`
  namespace row, `kernel_unique` namespace row, and `COV-KERNEL-FOLDED-UNIQUE`
  covariance row are all paid by the single `STRUCT-KER-SINGLE-PSI` fit,
  under 3 distinct `case_id`s each recording its own `source_id`; `STRUCT-KER-MULTI`
  pays `COV-KERNEL-LATENT` directly). Plus 4 rejection-path cases (not
  counted toward `target_source_ids`).
- **Group 2 (postfit): 9 target source_ids, 6 executable, 3 deferred.**
  Executable (6 contract cases, 1:1 with source_ids):
  `extract_rotated_loadings_table`, `flag_unreliable_loadings`,
  `fitted.gllvmTMB_multi`, `logLik.gllvmTMB_multi`, `confint.gllvmTMB_multi`,
  `nobs.gllvmTMB_multi` (defect-flagged). Deferred (3): `extract_lv_effects`,
  `extract_Gamma`, `deviance.gllvmTMB_multi`.

9 (group 1) + 6 (group 2) = **15 executable contract cases**. 0 (group 1) + 3
(group 2) = **3 deferred**. 9 + 9 = **18 target source_ids**.

## Dry mapping: case -> R branch (from `tools/core070_wave6_conversion_batch.R`)

| case_id | R branch |
|---|---|
| `CORE070-WAVE6-INDEP-FIT` | `r_case_value()` -> `fit_structured("indep(0 + trait \| species, common = FALSE)")` -> `structured_quantity(fit, "...")`, `level_name="source"` |
| `CORE070-WAVE6-SCALAR-FIT` | same route, RHS `scalar(0 + trait \| species)` |
| `CORE070-WAVE6-KERNEL-INDEP-FIT` | same route, RHS `kernel_indep(species, K = C, name = "k1")`, `level_name="kernel"` |
| `CORE070-WAVE6-KERNEL-DEP-FIT` | RHS `kernel_dep(species, K = C, name = "k1")` |
| `CORE070-WAVE6-KERNEL-SCALAR-FIT` | RHS `kernel_scalar(species, K = C, name = "k1")` |
| `CORE070-WAVE6-KERNEL-LATENT-SINGLE-PSI-NAMESPACE` / `-COVARIANCE` | RHS `kernel_latent(species, K = C, d = 1, name = "k1", unique = TRUE)` (same fit, memoised by RHS string in `structured_fit_cache`) |
| `CORE070-WAVE6-KERNEL-LATENT-MULTI-NAMESPACE` | RHS `kernel_latent(...k1...) + kernel_latent(...k2...)` (`unique=FALSE`) |
| `CORE070-WAVE6-KERNEL-LATENT-MULTI-COVARIANCE-EXPORT` | same RHS as SINGLE-PSI (pays `kernel_unique` again via the fold) |
| `CORE070-WAVE6-POSTFIT-EXTRACT-ROTATED-LOADINGS-TABLE` | `r_postfit_value("rotated_loadings_flat")` -> `extract_rotated_loadings_table(fit_g)$estimate`, sorted |
| `CORE070-WAVE6-POSTFIT-FLAG-UNRELIABLE-LOADINGS` | `kind == "boolean_flags"` branch -> `confint(fit_g, parm="Lambda")`, zero-crossing flags |
| `CORE070-WAVE6-POSTFIT-FITTED-MULTI` | `r_postfit_value("fitted_values_flat")` -> `as.numeric(fitted(fit_g))` |
| `CORE070-WAVE6-POSTFIT-LOGLIK-MULTI` | `r_postfit_value("loglik_scalar")` -> `as.numeric(logLik(fit_g))` |
| `CORE070-WAVE6-POSTFIT-CONFINT-MULTI` | `r_postfit_value("confint_sigma_eps_bounds")` -> `confint(fit_g, parm="sigma_eps")` |
| `CORE070-WAVE6-POSTFIT-NOBS-MULTI` | `kind == "own_receipt_defect"` branch -> `nobs(fit_g)` vs `p*n` |
| 4 `CORE070-WAVE6-REJ-*` | `for (rc in contract$rejection_cases)` loop -> `tryCatch(gllvmTMB(...))`, records `raised`/`message` |

## Local verification performed (no live R / frozen library / Julia+GLLVM load)

- `Rscript -e "parse(file='tools/core070_wave6_conversion_batch.R')"` — **PARSE_OK**.
- `julia -e 'Meta.parseall(read("tools/core070_wave6_conversion_batch.jl", String))'` — **JULIA_PARSE_OK**.
- `python3 tools/core070_verify_wave6_conversion_batch.py --self-test` —
  **CORE070_WAVE6_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=7 cases=15 deferred=3**
  (7 independent mutations rejected, exceeds the >=4 hard-rule floor).
- `python3 tools/core070_verify_wave6_conversion_batch.py` (no `--state`) —
  contract-only check prints OK, then hard `SystemExit` (no state given).
- `python3 tools/core070_verify_wave6_conversion_batch.py /nonexistent/dir` —
  hard `SystemExit: --state directory does not exist`.

No live R (frozen `gllvmTMB` library) or live Julia (`using GLLVM`) run was
performed — that requires the frozen reference library and this repo's Julia
project environment, run on Totoro per the command below.

## Totoro run command (suite-run-01 env pattern)

```sh
ssh -F ~/.ssh/config -o ControlPath=~/.ssh/cm-%r@%h:%p totoro.biology.ualberta.ca \
  'cd /project/<path>/GLLVM.jl && \
   OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
   Rscript --vanilla tools/core070_wave6_conversion_batch.R \
     <frozen-library-path> .unlazy/core070-aghq/wave6-conversion-01'

# then, locally or on Totoro:
python3 tools/core070_verify_wave6_conversion_batch.py .unlazy/core070-aghq/wave6-conversion-01
```

## Known risks / things a live run may surface as `oracle_error`

- `extract_rotated_loadings_table(fit_g)`'s actual column names (`trait_i`,
  `factor_j`, `estimate`) are inferred from the docstring cross-reference in
  `src/extractors.jl:231` ("mirrors `gllvmTMB::extract_rotated_loadings_table()`"),
  not read from live R source — if the real R column names differ, the R
  oracle step raises and this batch records a loud `oracle_error` (never a
  silent skip), per this repo's established convention.
- `extract_lv_effects` field name for the R side was never authored (row is
  deferred), avoiding a repeat of the wave-5 "guessed field name" REPAIR
  cycle.
- The `kernel_latent`/`kernel_indep`/etc. R calling convention
  (`cluster="species"`, `gllvmTMBcontrol(n_init=1L, se=FALSE, aghq=FALSE,
  aghq_ridge=Inf)`) is copied verbatim from
  `test/parity/fixtures/core070_structured_input.R`'s `add()` helper — the
  only verified R calling shape for these terms in this repo. `indep`/`scalar`
  don't have a prior verbatim R call in any case-plan file; this batch applies
  the same verified `cluster=` convention to them for internal consistency,
  keyed off the same `species` grouping as the kernel cases.
