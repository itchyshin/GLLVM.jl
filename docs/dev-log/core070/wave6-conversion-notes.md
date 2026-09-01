# Wave-6 conversion batch notes (core070 conversion batch #2)

Reference commit: `b4d5fee64def88bc768dda1f1f77c29b295edd86`.
Contract: `docs/dev-log/core070/wave6-conversion-batch-contract.json`.
Runner: `tools/core070_wave6_conversion_batch.R` -> `tools/core070_wave6_conversion_batch.jl`.
Verifier: `tools/core070_verify_wave6_conversion_batch.py`.

## REPAIR round (2026-09-01, wave6-conversion1 forensics)

Attempt 1 (`totoro:...suite-run-01/wave6-conversion1`) failed. Root causes and fixes,
one per coordinator forensic item:

1. **All structured-term cases had `oracle_values = null`.** Root cause: the
   R stage passed a top-level `cluster = "species"` argument to every
   `gllvmTMB()` structured-term call; the live engine warned "Unused
   optional grouping argument(s): cluster — no formula covariance keyword
   uses cluster" (none of `dep`/`indep`/`scalar`/`kernel_*` consume it — the
   grouping is embedded entirely in the term itself, via the bar `|group`
   for `dep`/`indep`/`scalar` or the bare leading symbol for `kernel_*`).
   Compounding this, the formula RHS was derived by regex-stripping
   `cs$r_call` (fragile against embedded commas), the most likely source of
   the actual silent-NULL fits. **Fix:** dropped `cluster=` entirely,
   replaced with the SAME `unit = "site", trait = "trait"` convention
   already proven working in this file's own `gaussian_small` fit (and in
   `tools/core070_surface_conversion_batch.R`); replaced all regex-derived
   formula RHS with literal hardcoded R expressions per `case_id`
   (`structured_formula_rhs` / `rejection_formula_rhs` lookup tables); added
   `stopifnot(!is.null(fit))`, `stopifnot(!is.null(ll), is.finite(ll))`, and
   `stopifnot(!is.null(Sigma))`/`!is.null(out)` guards at every extraction
   step, so a NULL is now a loud `tryCatch`-caught error (→ `oracle_errors`),
   never a silent `oracle_values` entry. The coverage-loud-check was also
   hardened: it now treats a NULL `oracle_values[[case_id]]` (should one
   still somehow occur) identically to a missing entry — computed via
   `null_valued_case_ids <- Filter(function(id) ... is.null(oracle_values[[id]]), ...)`
   and unioned into `missing_case_ids` before the `stop()` call, which still
   runs strictly **before** the Julia child is invoked (line order verified:
   the `stop()` call is at R-file line ~296, the Julia `system2()` call is
   at line ~360).
2. **Julia crashed on `Float64(::Nothing)`.** A null R oracle value survives
   `jsonlite::write_json(..., null="null")` as JSON `null`, which the Julia
   child's hand-rolled JSON reader parses as `nothing`; broadcasting
   `Float64.(...)` over `nothing` threw and crashed the whole process before
   any report was written. **Fix:** added `oracle_numeric_or_missing(oracle,
   case_id)`, a helper that returns `(false, Float64[])` on any
   null/missing/non-coercible oracle entry and NEVER throws; every
   numeric-comparison branch (`term_expr_map` cases, the remaining `point`
   postfit cases) now calls this helper first and records a per-case
   `"error" => "null_oracle_value: ..."` / `pass=false` result instead of
   crashing — the same soft-fail-per-case pattern
   `tools/core070_surface_conversion_batch.jl` already uses for a missing
   oracle value.
3. **Three postfit oracle errors.**
   - **(a) `EXTRACT-ROTATED-LOADINGS-TABLE`** ("argument 1 is not a
     vector"): the assumed R column names (`trait_i`, `factor_j`,
     `estimate`) were inferred only from the Julia docstring cross-reference
     (`src/extractors.jl:231`), never from live R source or a live
     `str()`/`names()` inspection. Re-guessing a second time without live R
     access risks a repeat failure, so this row **moved from `cases[]` to
     `deferred[]`** with a traced reason; `GLLVM.extract_rotated_loadings`
     itself is confirmed to exist and stays a genuine (not missing) surface.
   - **(b) `FLAG-UNRELIABLE-LOADINGS`** ("Per-entry Wald CIs on Lambda
     well-defined only for confirmatory fits; no lambda_constraint pins"):
     **deferred exactly per the coordinator's trace** — this is the same
     confirmatory-fit / `lambda_constraint` gate that already blocks
     `loading_ci` elsewhere in this ledger; the Julia composition this batch
     built (`confint(fit; parm="Lambda")` zero-crossing) compares a
     different estimand on an unconstrained fixture and is not a valid
     paired case here.
   - **(c) `FITTED-MULTI`** ("list object cannot be coerced"): R's
     `fitted(fit_g)` returns a list/matrix structure, not a plain numeric
     vector; the correct component name is not resolvable without a live R
     `str()` inspection. **Moved to `deferred[]`** with a traced reason;
     `GLLVM.fitted(fit::AnyGllvmFit, data)` itself is confirmed to exist.

   All three deferrals note explicitly that the underlying Julia surface
   *does* exist — these are shape/gate uncertainties on the R side, not
   missing-Julia-surface rows, and are flagged for re-authoring once a live
   R session can confirm the actual return shapes.
4. **Self-test hardening.** Added an 8th self-test mutation,
   `mut_null_oracle_value_with_pass_true`, which plants a `pass=true`
   result whose `error` string flags `null_oracle_value` and asserts
   `check_state()` rejects it (a new `check_state()` guard was added:
   `need(not (isinstance(err, str) and "null_oracle_value" in err))` paired
   with `pass=true`). Self-test now rejects **8** independent mutations
   (`--self-test` output:
   `CORE070_WAVE6_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=8 cases=12 deferred=6`).

Net effect on counts: **case_count 15→12, deferred_count 3→6** (3 postfit
cases moved to deferred: `extract_rotated_loadings_table`,
`flag_unreliable_loadings`, `fitted.gllvmTMB_multi`). `target_source_ids`
stays 18 (12 executable + 6 deferred). All 9 group-1 structured-term rows
remain executable — that group's failure was purely a calling-convention
and extraction-mechanism bug (items 1/2 above), not an estimand or
return-shape uncertainty.

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
  `value = sin(idx/3) + trait_int/5`, `C`/`K2` PD 3x3 species kernels). R
  call: `gllvmTMB(value ~ 0 + trait + TERM, df, unit = "site", trait =
  "trait", family = stats::gaussian(), control = control)` (REPAIR: no
  `cluster=`).
- `kernel_latent` + `kernel_unique` + `covariance/COV-KERNEL-FOLDED-UNIQUE`:
  all three ledger rows paid by the **same** fit,
  `kernel_latent(species, K=C, d=1, name="k1", unique=TRUE)` — this is
  `structured-required-case-plan.json`'s `STRUCT-KER-SINGLE-PSI` case,
  reference call reused verbatim (minus `cluster=`). `kernel_unique` has
  **no standalone** `SourceCovariance` mode (`_source_term_covariance`
  throws for a bare `:kernel_unique` spec, `src/formula.jl:604-606`); the
  only Julia surface for it is this fold, matching the spec's "Julia
  comparand is the fold" framing.
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
| `extract_rotated_loadings_table` | `extract_rotated_loadings(fit)` (`src/extractors.jl:233`, exported) — matrix form, R returns a long table | **deferred** (REPAIR: R-side column names unconfirmed without live R access; "argument 1 is not a vector" on attempt 1) |
| `extract_lv_effects` | `extract_lv_effects(fit::GllvmFit)` (`src/postfit.jl:353`, exported) but **hard-gates** on `_has_lv_predictor(fit)` (requires an `X_lv=` concurrent-ordination fit) | **deferred** — no reused fixture carries `X_lv` |
| `flag_unreliable_loadings` | no literal function; composed via `confint(fit; parm="Lambda")` zero-crossing | **deferred** (REPAIR, per coordinator trace: R aborts on gaussian_small — confirmatory-fit `lambda_constraint` gate, same family as `loading_ci`) |
| `fitted.gllvmTMB_multi` | `StatsAPI.fitted(fit::AnyGllvmFit, data)` = `predict(...; type=:response)` (`src/postfit.jl:306`) | **deferred** (REPAIR: R's `fitted(fit_g)` returns a list/matrix, correct component unconfirmed without live R access; "list object cannot be coerced" on attempt 1) |
| `logLik.gllvmTMB_multi` | `StatsAPI.loglikelihood(fit::AnyGllvmFit)` (`src/postfit.jl:580`) — naming-convention difference only (R's S3 `logLik()` vs the StatsAPI.jl `loglikelihood()` idiom) | **executable** |
| `deviance.gllvmTMB_multi` | **no** `deviance` function/dispatch anywhere in `src/` for any Gllvm fit type (also absent from the export list) | **deferred** — composing an ad hoc definition without R source access risks the wrong estimand |
| `confint.gllvmTMB_multi` | `confint(fit::GllvmFit; ...)` (`src/confint.jl:246`) | **executable** |
| `nobs.gllvmTMB_multi` | `StatsAPI.nobs(fit::AnyGllvmFit)` (`src/postfit.jl:614`) | **executable**, but flagged `known_defect_pending_decision: true` — R returns `p*n` (cell count), Julia returns `n` (unit count); the case asserts each engine against its **own** formula, never R==Julia |
| `extract_Gamma` | `extract_Gamma(fit::GllvmFit; row_traits, col_traits)` (`src/extract_gamma.jl:36`, exported) requires a `Λ_phy`-bearing fit (`fit_gaussian_gllvm(...; K_phy>0, Σ_phy=K*)`); no reused fixture carries a phylo tier, and per `formula-recognizer-spec.md` Sec 1.5 the native `Σ_phy=` route is explicitly **not the same model** as any R gllvmTMB coevolution formula | **deferred** — identical deferral wave-5 already recorded for this same row |

3 executable (`logLik.gllvmTMB_multi`, `confint.gllvmTMB_multi`,
`nobs.gllvmTMB_multi`), 6 deferred (`extract_lv_effects`, `extract_Gamma`,
`deviance.gllvmTMB_multi`, plus the 3 REPAIR-round deferrals:
`extract_rotated_loadings_table`, `flag_unreliable_loadings`,
`fitted.gllvmTMB_multi`) = 9 rows total, matching the task's named list
exactly (the 9 names given, "and similar" not expanded further — no other
`postfit/POSTFIT-SURFACE-*` `BLOCKED_NEEDS_JULIA_SURFACE` row was brought
into scope; the remaining ~43 stay untouched for a future wave).

All postfit cases use `gaussian_small`, reused **verbatim** (seed 42,
`Lambda_true`, `sigma_true`) from `tools/core070_surface_conversion_batch.R`.

## Executable / deferred tally (post-REPAIR)

Contract-verified totals (asserted by `docs/dev-log/core070/wave6-conversion-batch-contract.json`
and checked by `tools/core070_verify_wave6_conversion_batch.py`):
**12 executable contract cases / 18 target `source_id`s (12 executable + 6
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
- **Group 2 (postfit): 9 target source_ids, 3 executable, 6 deferred.**
  Executable (3 contract cases, 1:1 with source_ids): `logLik.gllvmTMB_multi`,
  `confint.gllvmTMB_multi`, `nobs.gllvmTMB_multi` (defect-flagged). Deferred
  (6): `extract_lv_effects`, `extract_Gamma`, `deviance.gllvmTMB_multi`,
  `extract_rotated_loadings_table`, `flag_unreliable_loadings`,
  `fitted.gllvmTMB_multi`.

9 (group 1) + 3 (group 2) = **12 executable contract cases**. 0 (group 1) + 6
(group 2) = **6 deferred**. 9 + 9 = **18 target source_ids**.

## Dry mapping: case -> R branch (from `tools/core070_wave6_conversion_batch.R`)

| case_id | R branch |
|---|---|
| `CORE070-WAVE6-INDEP-FIT` | `r_case_value()` -> `structured_formula_rhs[[case_id]]` = `"indep(0 + trait \| species, common = FALSE)"` -> `fit_structured_rhs(rhs)` -> `structured_quantity(fit, rhs)`, `level_name="source"` |
| `CORE070-WAVE6-SCALAR-FIT` | same route, RHS `"scalar(0 + trait \| species)"` |
| `CORE070-WAVE6-KERNEL-INDEP-FIT` | same route, RHS `"kernel_indep(species, K = C, name = \"k1\")"`, `level_name="k1"` |
| `CORE070-WAVE6-KERNEL-DEP-FIT` | RHS `"kernel_dep(species, K = C, name = \"k1\")"` |
| `CORE070-WAVE6-KERNEL-SCALAR-FIT` | RHS `"kernel_scalar(species, K = C, name = \"k1\")"` |
| `CORE070-WAVE6-KERNEL-LATENT-SINGLE-PSI-NAMESPACE` / `-COVARIANCE` | RHS `"kernel_latent(species, K = C, d = 1, name = \"k1\", unique = TRUE)"` (same fit, memoised by RHS string in `structured_fit_cache`) |
| `CORE070-WAVE6-KERNEL-LATENT-MULTI-NAMESPACE` | RHS `"kernel_latent(...k1...) + kernel_latent(...k2...)"` (`unique=FALSE`) |
| `CORE070-WAVE6-KERNEL-LATENT-MULTI-COVARIANCE-EXPORT` | same RHS as SINGLE-PSI (pays `kernel_unique` again via the fold) |
| `CORE070-WAVE6-POSTFIT-LOGLIK-MULTI` | `r_postfit_value("loglik_scalar")` -> `as.numeric(logLik(fit_g))` |
| `CORE070-WAVE6-POSTFIT-CONFINT-MULTI` | `r_postfit_value("confint_sigma_eps_bounds")` -> `confint(fit_g, parm="sigma_eps")` |
| `CORE070-WAVE6-POSTFIT-NOBS-MULTI` | `kind == "own_receipt_defect"` branch -> `nobs(fit_g)` vs `p*n`, `stopifnot(!is.null(r_nobs))` guarded |
| 4 `CORE070-WAVE6-REJ-*` | `for (rc in contract$rejection_cases)` loop -> `rejection_formula_rhs[[rc$case_id]]` -> `tryCatch(gllvmTMB(...))`, records `raised`/`message` |

## Local verification performed (no live R / frozen library / Julia+GLLVM load)

- `Rscript -e "parse(file='tools/core070_wave6_conversion_batch.R')"` — **PARSE_OK**.
- `julia -e 'Meta.parseall(read("tools/core070_wave6_conversion_batch.jl", String))'` — **JULIA_PARSE_OK**.
- `python3 tools/core070_verify_wave6_conversion_batch.py --self-test` —
  **CORE070_WAVE6_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=8 cases=12 deferred=6**
  (8 independent mutations rejected, including the new null-oracle-value
  mutation, exceeds the >=4 hard-rule floor).
- `python3 tools/core070_verify_wave6_conversion_batch.py` (no `--state`) —
  contract-only check prints OK, then hard `SystemExit` (no state given).
- `python3 tools/core070_verify_wave6_conversion_batch.py /nonexistent/dir` —
  hard `SystemExit: --state directory does not exist`.
- Confirmed programmatically: no `cluster` string remains in any `r_call` in
  `cases[]` or `rejection_cases[]`; `target_source_ids` union/count checks
  all pass (12 cases + 6 deferred = 18 target rows, no duplicates, disjoint).
- Confirmed by line-number grep: the R coverage `stop()` call
  (`~line 296`) textually precedes the Julia `system2()` invocation
  (`~line 360`) — the R stage fails before invoking Julia on incomplete
  coverage.

No live R (frozen `gllvmTMB` library) or live Julia (`using GLLVM`) run was
performed — that requires the frozen reference library and this repo's Julia
project environment, run on Totoro per the command below.

## Totoro run command (wave6-conversion2)

```sh
ssh -F ~/.ssh/config -o ControlPath=~/.ssh/cm-%r@%h:%p totoro.biology.ualberta.ca \
  'cd /project/<path>/GLLVM.jl && \
   OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
   Rscript --vanilla tools/core070_wave6_conversion_batch.R \
     <frozen-library-path> .unlazy/core070-aghq/wave6-conversion-02'

# then, locally or on Totoro:
python3 tools/core070_verify_wave6_conversion_batch.py .unlazy/core070-aghq/wave6-conversion-02
```

## Remaining risk for the live re-run

- `indep`/`scalar` don't have a prior verbatim R call in any case-plan file
  (only the `kernel_latent`/`kernel_dep` family had a proven `add()`-helper
  precedent, and even that helper's `cluster=` turned out to be unused).
  This batch now uses the SAME `unit=`/`trait=` convention proven in
  `gaussian_small`'s own fit for every structured term, for internal
  consistency — but that convention has only been proven for the *plain*
  `latent(...)` term, not yet for `dep`/`indep`/`scalar`/`kernel_*`
  specifically. If `unit=`/`trait=` also turns out to be unconsumed or
  wrong for these terms, the fix is the same class of change (drop/adjust
  the top-level gllvmTMB() kwargs) and will surface as a loud
  `oracle_errors` entry per case, never a silent NULL, given this round's
  hardening.
- The three items 3(a)/3(b)/3(c) postfit deferrals remain **genuinely
  deferred pending a live R session** (not merely postponed by choice) —
  re-authoring them needs `str()`/`names()` output from the actual returned
  R objects, which this Julia-only worktree cannot produce.
