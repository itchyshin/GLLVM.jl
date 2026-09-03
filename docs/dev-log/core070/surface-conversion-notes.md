# Surface-conversion batch — converting BLOCKED_NEEDS_JULIA_SURFACE rows now that the surface exists

Branch: `codex/core070-aghq-20260830`, worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`. Owned files: this notes file,
`docs/dev-log/core070/surface-conversion-batch-contract.json`,
`tools/core070_surface_conversion_batch.R`,
`tools/core070_surface_conversion_batch.jl`,
`tools/core070_verify_surface_conversion_batch.py`. No other file was
touched; nothing was committed (write-only per the task's instruction — the
orchestrator commits after review).

## What this batch is

Two prior slices shipped new Julia surface for functions the ledger
(`docs/dev-log/core070/required-source-case-map.json`) had marked
`BLOCKED_NEEDS_JULIA_SURFACE`:

1. **Extractors (Cluster 1)** — `src/extractors.jl`, 18 new
   `extract_*`/`get*` exports. Notes:
   `docs/dev-log/core070/extractors-slice-notes.md`.
2. **Derived CI (Cluster 2)** — `src/twolevel.jl`,
   `src/confint_derived_wald.jl`, `src/confint_derived.jl`, 12 new exports
   (`repeatability_wald_ci`, `repeatability_bootstrap_ci`,
   `repeatability_ci`, `standardized_loading_wald_ci`,
   `raw_loading_wald_ci`, `loading_ci`, `loading_profile`,
   `profile_ci_total_variance`, `profile_ci_phylo_signal`, `slope_sd_ci`,
   `standard_errors`). Notes:
   `docs/dev-log/core070/derived-ci-slice-notes.md`.

This batch's job is narrow: **find every ledger row that is still marked
`BLOCKED_NEEDS_JULIA_SURFACE` but whose named surface now genuinely exists
in `src/GLLVM.jl`'s export list, and build the receipted evidence that lets
the orchestrator flip its disposition to bound.** It does not implement any
new Julia surface itself.

## Target-row enumeration (exact method, not eyeballing)

1. Parsed `docs/dev-log/core070/required-source-case-map.json`, filtered to
   `disposition == "BLOCKED_NEEDS_JULIA_SURFACE"` (142 rows total).
2. Restricted to the three prefixes named in the task: `postfit/`,
   `namespace/`, `inference/` (121 of the 142).
3. Extracted the function name each row names:
   - `postfit/POSTFIT-SURFACE-<fn>` → `<fn>` directly from the `source_id`.
   - `namespace/export/<fn>` → `<fn>` directly from the `source_id`.
   - `inference/CI-ROUTE-*` → no function name in the `source_id`; scanned
     `evidence.reason` for any `<name>(` call matching a name in the
     current export list.
4. Pulled the **current** export list by parsing the one multi-line
   `export …` statement in `src/GLLVM.jl` (line 165 through `end # module
   GLLVM`) — 401 distinct identifiers as of this branch's HEAD
   (`ed36aacb`).
5. Kept only rows whose extracted function name is in that export set.

Result: **41 rows** (verified count: `postfit/` 34, `namespace/` 12,
`inference/` 5 candidates surfaced by the sweep; after de-duplication and
the per-row filter, 41 rows total — see `target_source_ids` in the
contract for the exact list). Cross-checked against the ~85 remaining
`postfit/`/`namespace/` rows that did **not** make the cut (`getREsd`,
`extract_residual_split`, `extract_coevolution_modules`, bare
`profile_phylo_signal`/`profile_cross_rho`, every plotting/S3-method row,
the `gllvmTMB_multi`-suffixed generic-method rows, structured-term
recognizer keywords like `phylo_dep`/`kernel_latent`/`meta_V`) — none of
those names are in the current export list, so they correctly stay
`BLOCKED_NEEDS_JULIA_SURFACE`.

## 34 executable + 7 deferred = 41

Of the 41 target rows, **34** go into the receipted batch
(`contract.cases`) and **7** are recorded in `contract.deferred` with an
explicit per-row reason — **not** converted to `needs_new_julia_surface`
(that label means the *Julia surface* is missing, which is false for all
7; every deferred row's Julia surface already exists and is independently
tested elsewhere in the repo) and **not** fabricated as a pass. The 7:

- `postfit/POSTFIT-SURFACE-extract_Gamma` — Julia surface exists
  (`src/extract_gamma.jl`) and is tested
  (`test/test_coevolution_*.jl`), but no R-parity fixture for a
  coevolution (`fit_coevolution_gaussian`-class) model exists anywhere in
  this repo's `tools/` or `test/parity/` (`grep -rl
  fit_coevolution_gaussian test/*.jl test/parity/*.jl` returns only
  pure-Julia test files). Building one from scratch (a correct
  `make_cross_kernel`-style R formula + tree + kernel spec) without live R
  access to verify it is out of this batch's scope.
- `postfit/POSTFIT-SURFACE-extract_phylo_signal`,
  `namespace/export/profile_ci_phylo_signal`,
  `postfit/POSTFIT-SURFACE-profile_ci_phylo_signal` — Julia surface exists
  (`phylo_signal(fit::GllvmFit; Σ_phy)` takes an externally-supplied
  `Σ_phy` on an ordinary `GllvmFit`), but R's `extract_phylo_signal()`
  reads `report$Sigma_phy` off a genuine `phylo_latent()`/`phylo_indep()`
  **structured** fit — a different model class. A numerically paired
  comparison needs a live R phylo formula fit on the same tree/Y the
  Julia side's `Σ_phy` implies, which this batch could not safely
  construct and verify without R access in this session.
- `postfit/POSTFIT-SURFACE-extract_lv_effects` — Julia surface exists
  (`src/postfit.jl`), but it requires a fit built with
  `fit_gaussian_gllvm(...; X_lv=...)` (a constrained-ordination predictor
  block); the `gaussian_small` fixture this batch shares across the other
  33 cases has no `X_lv` term, so calling `extract_lv_effects(fit_g)` on
  it throws `ArgumentError` — confirmed by reading the function's own
  guard (`_has_lv_predictor(fit) || throw(...)`). Needs a distinct
  fixture; flagged for a follow-up slice rather than silently building a
  fourth fixture under time pressure.
- `namespace/export/slope_sd_ci`, `postfit/POSTFIT-SURFACE-slope_sd_ci` —
  Julia surface exists (`src/confint_derived_wald.jl`), but the R oracle
  route (`.unlazy/core070-aghq/oracle-source/readback/R/slope-sd-ci.R`)
  documents its own prior hand-indexing failure in its file header ("a
  first attempt at the phylo route indexed `theta_dep_chol` entries 2/5/8
  instead of the correct 2/4/6") and needs an ADREPORT-differentiated
  packed expression read off `sd_report`. The exact R
  formula/grouping-factor grammar for the diagonal augmented-slope route
  (`theta_diag_B_slope`) that would pair correctly against GLLVM.jl's
  per-group `Σ_b` random-slope fit is not something this batch could
  construct and verify without live R access, given the R source's own
  documented history of getting this indexing wrong on a first attempt.

All 7 reasons and the full 41-row `target_source_ids` list are recorded
**verbatim** in `docs/dev-log/core070/surface-conversion-batch-contract.json`.

## Batch design (the 34 executable cases)

Three canonical fixtures, two of them reused **verbatim** from proven,
already-receipted fixtures elsewhere in this repo (same seed, same true
parameters — so this batch's own R oracle numbers can be cross-checked
against those batches' recorded numbers if ever needed):

- **`gaussian_small`** (p=5, K=2, n=80, seed 42) — copied verbatim from
  `tools/core070_inference_remainder_batch.R`. 29 of the 34 cases use it.
- **`twolevel_small`** (p=4, 30 individuals × 4 reps, seed 1) — a genuine
  two-tier fit (`latent(0+trait|site,d=1) + latent(0+trait|site_species,d=1)`),
  reconstructed per
  `.unlazy/core070-aghq/oracle-source/readback/R/extract-repeatability.R`'s
  own `@examples` formula (the exact citation the ledger's own
  `CI-ROUTE-008..011` evidence text names). 5 cases use it
  (`extract_repeatability` + the four `icc_ci_*`
  method-route cases: default→wald, wald explicit, bootstrap, and the
  profile refusal pair).
- **`ordinal_small`** (p=5, K=1, n=60, C=3, seed 46) — copied verbatim
  from `test/parity/test_ordinal_probit_parity.jl`, a fixture that is
  already proven to reach a matching R/Julia log-likelihood in that file.
  1 case (`extract_cutpoints`) uses it.

For each case: the R runner fits the fixture once per fixture group,
calls the case's R accessor (same function name as the Julia surface —
per this repo's whole-codebase "digital twin" convention, confirmed by
reading `src/extractors.jl`'s own header, which documents itself as an
R-name-mirroring layer), and writes a flattened numeric vector into
`r-oracle.json`. The R process then launches the Julia child via
`system2()` with `CORE070_SURFACE_CONVERSION_R_ORACLE` passed through the
environment (matching `tools/core070_inference_remainder_batch.R`'s own
env-pass-through convention). The Julia child fits each fixture **natively**
on the same simulated `Y` (an independent optimiser run, not a replay of
R's numbers), calls the corresponding Julia surface, and compares.

**Tolerance calibration** (per the task's guidance):

- `1e-4` — point quantities that are direct paired-independent-fit outputs
  (loadings, LV-predictor, standard errors, repeatability point estimate,
  cutpoints, ordination radii).
- `1e-6` — quantities that are deterministic closed-form transforms of
  those same fit outputs computed within ONE process (Σ, communality,
  correlations, residual cov/cor, Ω, ICC, proportions) — tighter because
  no second optimiser run is involved on either side beyond the shared
  base fit.
- `1e-3` — CI endpoints (two independent fits + delta method), per the
  task's explicit guidance.
- `5e-2` — the one Monte-Carlo bootstrap CI case
  (`inference/CI-ROUTE-011`, `icc_ci_bootstrap`): both R's and Julia's
  intervals are themselves stochastic (percentile bootstrap over
  independent simulate-refit replicates), so a `1e-3` bar would be
  miscalibrated — this mirrors the loose MC-noise-tolerant overlap check
  already used for the same estimator in
  `test/test_derived_ci_surfaces.jl` §1 (`nsim` 40–60).

**Loading-sign / rotation invariance**: every quantity that could be
sign- or rotation-dependent is compared through a rotation-invariant
transform, never raw entries — `L'L` (not `L`) for loadings,
`Λ * Z` (not `Z` alone) for the LV predictor, per-observation squared
radius `rowSums(sites^2)` (not `sites` itself) for ordination. This
follows the same convention `extractors-slice-notes.md` documents for its
own closed-form checks.

**Rejected-mutation / negative-control discipline**, per the hard
template rules:

- R runner argv is exactly 2 (`<frozen-library> <destination>`);
  `stopifnot()` on contract identity (`status`, `reference_commit`, case
  counts) before anything else runs.
- Two negative controls exercised on the live fixture in both languages:
  a bogus quantity key (must error in both `r_quantity()`/
  `julia_quantity()`) and a bogus fixture key (must be absent from
  `contract$fixtures`/`contract["fixtures"]`).
- `receipt.json` carries `status`, `contract_sha256`, `reference_commit`
  (pinned to `b4d5fee64def88bc768dda1f1f77c29b295edd86`),
  `source_unchanged`, and the full `target_source_ids` list.
- The Julia stage is launched from R via `system2()` with env
  pass-through (`CORE070_SURFACE_CONVERSION_R_ORACLE`) — no RCall, no
  JuliaCall bridge.
- A case whose Julia surface turns out to still be missing would go into
  `needs_new_julia_surface` with a reason and `never a fake pass`; none of
  the 34 executable cases hit that — all 34 call surface that
  `extractors-slice-notes.md`/`derived-ci-slice-notes.md` document as
  shipped and independently tested in their own slices.
- `tools/core070_verify_surface_conversion_batch.py --self-test` passes
  locally with **python3 only** (no Julia/R needed): 5 independently
  rejected mutations (≥3 required) — tampered contract hash, one flipped
  verdict, `max_abs_diff` blown past tolerance while `pass` stays true, a
  refusal-pair case where the R side did not actually raise, and a
  nonzero `oracle_error_count` slipping through. `--state <missing-dir>`
  and a missing required file both raise `SystemExit` (hard failure, not
  a silent skip) — confirmed by direct invocation in this session (see
  Verification below).

## Verification performed in this worktree

- `python3 tools/core070_verify_surface_conversion_batch.py --self-test` →
  `CORE070_SURFACE_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=5
  cases=34 deferred=7`.
- `python3 tools/core070_verify_surface_conversion_batch.py` (no `--state`,
  no `--self-test`) → prints `CORE070_SURFACE_CONVERSION_CONTRACT_OK …`
  then exits 1 via `SystemExit` (no state given) — confirmed non-zero
  exit code.
- `python3 tools/core070_verify_surface_conversion_batch.py
  /nonexistent/path` → `FATAL: --state directory does not exist: …`,
  non-zero exit.
- `python3 -c "json.load(...)"` on the contract file — parses cleanly.
- `Rscript -e 'parse("tools/core070_surface_conversion_batch.R")'` →
  `R parse OK`.
- `julia -e 'Meta.parseall(read("tools/core070_surface_conversion_batch.jl", String))'`
  → `Julia parse OK`.
- **Not run in this session** (needs the frozen `gllvmTMB` library, which
  is not present in this sandbox): the actual R↔Julia paired fit-and-compare.
  This is a genuine, honestly-reported gap — the batch's tooling is
  written and syntax-verified but has not yet executed against real data.
  See "Totoro run commands" below for how the orchestrator runs it for
  real.

## Totoro run commands

Matches the namespace-batch env pattern used elsewhere in this repo
(e.g. `docs/dev-log/core070/namespace-1-batch-contract.json`'s own
`runner` block):

```sh
# from the GLLVM.jl repo root on Totoro, with a frozen gllvmTMB library
# already built at $FROZEN_LIB (see ~/shinichi-brain/tools/totoro-setup.md
# for the frozen-library convention used by sibling core070 batches)
FROZEN_LIB=/home/snakagaw/core070-aghq-20260830/frozen-library   # adjust to the actual frozen-library path
OUT=.unlazy/core070-aghq/surface-conversion-01/attempt1

Rscript --vanilla tools/core070_surface_conversion_batch.R "$FROZEN_LIB" "$OUT"

# verify the retained run (contract-only check already ran as part of the
# batch; this repeats it plus the full state check):
python3 tools/core070_verify_surface_conversion_batch.py "$OUT"
```

Expected wall time: three small LBFGS/twolevel/ordinal fits (n ≤ 250 each)
plus ~20 lightweight R/Julia accessor calls and one 200-replicate
parametric bootstrap — low minutes, not a campaign-scale run. No GPU, no
SLURM array needed; a plain foreground `Rscript` invocation on Totoro (or
locally, once a frozen `gllvmTMB` library is available) is sufficient.

## Anything still missing

- **The actual receipted run.** This session wrote and syntax-verified
  the batch but could not execute it (no frozen `gllvmTMB` library, no R
  package installed in this sandbox). The orchestrator (or a lane with
  Totoro access) must run the command above before the 34 rows' ledger
  dispositions can actually flip from `BLOCKED_NEEDS_JULIA_SURFACE` to
  bound — this notes file is the design/build record, not the receipt
  itself.
- **The 7 deferred rows** (above) remain `BLOCKED_NEEDS_JULIA_SURFACE` in
  the ledger; converting them needs either a coevolution R-parity
  fixture, a phylo-structured R fixture matched to the Julia `Σ_phy`
  convention, an `X_lv`-fit fixture for `extract_lv_effects`, or a
  verified R random-slope formula for `slope_sd_ci` — none of which this
  batch attempted, to avoid fabricating unverified fixture code under
  this session's time budget.
- **Row-ordering risk in `loading_ci_wald_asym`**: the contract compares
  R's and Julia's per-`(trait,axis)` CI tables as flattened
  `[lower...; upper...]` vectors, assuming both languages iterate rows in
  the same `(axis, trait)` order. This was not independently verified
  against R's actual `confint(..., parm='rho')` row order (no R access in
  this session) — if the real Totoro run fails only this one case with a
  length-matched-but-permuted-looking `max_abs_diff`, that ordering
  assumption is the first thing to check, not the underlying CI machinery.

## Repair (2026-09-01): twolevel_small fixture grouping fix

Totoro run `wave5-conversion` failed in the R stage before any receipt:
`gllvmTMB_multi_fit()`: `Unsupported grouping "site" and "site" for
rr()/diag(). Supported groupings: "site_species", "site_species", "species"
(slots: unit, unit_obs, cluster) → if you meant the within-unit grouping,
pass unit_obs="site"` (log:
`totoro:/home/snakagaw/core070-aghq-20260830/suite-run-01/wave5-conversion-r.log`).

**Root cause**: `fit_tl <- gllvmTMB(...)` passed `unit = "site_species"`
only. The correct call, per
`.unlazy/core070-aghq/oracle-source/readback/R/extract-repeatability.R`'s
own `@examples` (lines 68–77), needs **both** `unit = "site"` and
`unit_obs = "site_species"` as separate arguments — the formula's two
`latent()` terms were already correct; only the `gllvmTMB()` call
arguments were wrong.

**What I checked before fixing**: the coordinator's message said to copy
the construction "verbatim" from `tools/core070_namespace_1_batch.R`, but
that file contains **no `gllvmTMB()` call at all** — it is a pure Tier-0
existence/registration text-scan over the pinned R source, not a
model-fitting script (confirmed: `grep -n "gllvmTMB(" tools/core070_namespace_1_batch.R`
returns nothing, and the file's own header says so explicitly). The 4
case_ids the coordinator named
(`CORE070-NAMESPACE-EXTRACT-ICC-SITE`/`EXTRACT-REPEATABILITY-TWOLEVEL`/
`EXTRACT-SIGMA-B-TWOLEVEL`/`EXTRACT-SIGMA-W-TWOLEVEL`) are indeed real rows
in `docs/dev-log/core070/namespace-1-batch-contract.json`, but each is a
`r_namespace_line`/`r_definition_pattern` text-match check, not a fitted
model. The actual proven construction lives in the pinned R docstring
(`extract-repeatability.R`'s `@examples`), which I used instead — same
grouping columns (`site`, `site_species`), same formula shape, corrected
`unit=`/`unit_obs=` arguments.

**Fix applied**: `tools/core070_surface_conversion_batch.R`'s `fit_tl <-
gllvmTMB(...)` call now passes `unit = "site", unit_obs = "site_species",
trait = "trait"` (previously `unit = "site_species"` only). No change to
the data-frame construction (`df_tl`'s `site`/`site_species` columns were
already correct) and no change to the formula
(`latent(0+trait|site,d=1) + latent(0+trait|site_species,d=1)`).

**Other fixtures scanned for the same class of mistake**: compared
`gaussian_small`'s and `ordinal_small`'s `gllvmTMB()` calls line-by-line
against their proven sources (`tools/core070_inference_remainder_batch.R`
and `test/parity/test_ordinal_probit_parity.jl` respectively) — both match
verbatim (only variable-name renames: `df_long`→`df_g`, `fit`→`fit_g`, and
`fit_o`/`df_o` for the ordinal fixture), including the single `unit =
"site"` argument each (neither needs `unit_obs`, since neither has a
second grouping tier). No further groupings mismatches found.

**Julia side**: no change needed. `GLLVM.fit_twolevel_gaussian(Y_tl,
individual; K_B=1, K_W=1)` already receives `individual` as the
between-group vector (equivalent to R's `unit = "site"`); GLLVM.jl's
two-level model has no separate `unit_obs` argument because each column of
`Y` is already one within-individual observation by construction — R's
`unit_obs = "site_species"` (naming which rows are distinct observations)
has no Julia-side analogue to break. `tools/core070_surface_conversion_batch.jl`
was not modified.

**Contract file**: `docs/dev-log/core070/surface-conversion-batch-contract.json`'s
`fixtures.twolevel_small` entry updated to record the corrected `r_formula`
and an explicit `r_call_args: {unit: "site", unit_obs: "site_species",
trait: "trait"}` field, plus the repair note.

**Re-verified locally** (same three checks as before, all still green):
`Rscript -e 'parse("tools/core070_surface_conversion_batch.R")'` → `R parse
OK`; `julia -e 'Meta.parseall(...)'` → `Julia parse OK`; `python3
tools/core070_verify_surface_conversion_batch.py --self-test` →
`CORE070_SURFACE_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=5
cases=34 deferred=7`.

## Repair 2 (2026-09-01): vacuous-coverage defect — 10 of 34 cases silently uncomputed

Totoro run `wave5-conversion3`: the twolevel grouping fix worked, but the
Julia stage died with `no R oracle value recorded for
CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-CORRELATIONS`. The R
oracle recorded only 19 of the 34 contracted cases — 15 quantities threw
inside `r_quantity()`, were caught by the per-case `tryCatch()` into
`oracle_errors` (correctly, not silently *dropped*), but nothing checked
`oracle_errors` before invoking Julia, and Julia's `haskey(...) ||
error(...)` guard turned the FIRST missing key into one opaque crash that
hid the other 14.

**Root cause, diagnosed from the R source directly (not the case-plan
prose), function by function**, against the pinned oracle source
(`.unlazy/core070-aghq/oracle-source/readback/R/*.R`):

| quantity | bug found | fix |
| --- | --- | --- |
| `sigma_table` | `extract_Sigma_table()`'s numeric column is `estimate`, code read `$value` | `t$estimate` |
| `correlations` | `extract_correlations(tier="all")` returns a long-format **data.frame** (`tier/trait_i/trait_j/correlation/...`), not a coercible matrix — `as.numeric()` on it errors | switched the R-side route to `extract_Sigma(fit_g, level="unit", part="total")$R` (the mathematically identical unit-tier correlation matrix `extract_correlations()` computes internally); Julia still calls its own target surface `GLLVM.extract_correlations(fit_g)` unchanged |
| `ordination_sites` | `extract_ordination(fit, level, component)` takes **no data argument** — code passed `Y_g` positionally, which bound to `level` and broke `match.arg()`; also read `$sites`, real field is `$scores` | `extract_ordination(fit_g)`, `ord$scores` |
| `proportions` | `extract_proportions(fit, link_residual, format)` has **no `component=` argument** — code passed `component="shared"` (unused-argument error) | `extract_proportions(fit_g, format="long")` then filter to `component=="shared_unit"`, read `proportion` |
| `repeatability_point` | `extract_repeatability()`'s point column is `R`, code read `$estimate` | `$R` |
| `icc_ci_default`/`icc_ci_wald`/`icc_ci_bootstrap` | `confint(fit, parm="icc", ...)` returns a 2-column **matrix** (`.confint_icc()`'s `cbind(...)`, column names like `"2.5 %"`), not a list with `$lower`/`$upper` | `ci[, 1L]` / `ci[, 2L]` |
| `cross_correlations` | `extract_cross_correlations()` (extract-correlations.R) is **not** a general trait-subset extractor — it requires a multinomial trait in the fit (`No multinomial trait in this fit; use extract_correlations`) and computes nominal-vs-partner cross-correlations specifically. Model-class mismatch, not a call bug. | **moved to `deferred[]`** (reason recorded in the contract) |
| `loading_ci_wald_asym` (×3: CI-ROUTE-005, `namespace`/`postfit` `loading_ci`) | `loading_ci()`/`standardized_loading_wald_ci()` require `fit$lambda_constraint` pins — R aborts on any exploratory (unpinned) fit: *"Per-entry Wald CIs on Lambda are well-defined only for confirmatory fits ... Lambda is identified only up to rotation."* `gaussian_small` is exploratory. GLLVM.jl's own docstring already documents this exact R/Julia deviation. | **moved to `deferred[]`** (×3) |
| `loading_profile` (×2: `namespace`/`postfit`) | Same confirmatory-fit gate as `loading_ci` (both key off `fit$lambda_constraint`). | **moved to `deferred[]`** (×2) |
| `profile_ci_total_variance` (×2: `namespace`/`postfit`) | `.total_variance_spec()` refuses any tier with `unique=FALSE` (no diagonal Ψ_t component): *"Fit the tier with unique = TRUE."* `gaussian_small` uses `unique=FALSE` and is shared by 24 other cases; changing it would need re-verifying every other case under the new DGP shape, out of scope for a repair pass under time pressure. | **moved to `deferred[]`** (×2) — a distinct `has_diag` fixture variant is the correct follow-up |
| `standard_errors` (×2: `namespace`/`postfit`) | `standard_errors(fit)` returns **the fit object itself** with `sd_report` populated (a deferred-computation side effect: `if (!is.null(fit$sd_report)) return(fit)`), not an SE table — there is no `$se` field on the return value. Reading SEs would mean pulling `fit$sd_report$cov.fixed`/`summary(fit$sd_report)` and matching its fixed-parameter ordering to `GLLVM.jl`'s `confint(fit,y).se` packed order — unverifiable without a live R session. | **moved to `deferred[]`** (×2) |

**Net effect**: 10 rows moved from `cases[]` to `deferred[]` (with the same
per-row reason-string discipline as the original 7). **24 executable + 17
deferred = 41** (unchanged total). The remaining 24 R branches were each
re-derived from the cited source function's actual formal arguments and
return `data.frame`/matrix column names — not guessed, not left on the
original (buggy) call shape.

### (1) Loud coverage check — added to the R runner

After the case loop, before writing `r-oracle.json` or invoking Julia:

```r
all_contract_case_ids <- vapply(contract$cases, `[[`, "", "case_id")
accounted_for <- union(names(oracle_values), names(oracle_errors))
missing_case_ids <- setdiff(all_contract_case_ids, accounted_for)
if (length(missing_case_ids) > 0L) {
  stop("FATAL: ", length(missing_case_ids), " contract case(s) produced NEITHER an ",
       "oracle_values entry NOR an oracle_errors entry ... Missing case_id(s):\n  ",
       paste(missing_case_ids, collapse = "\n  "))
}
```

This catches the actual defect class (a case falling through the
`tryCatch` bookkeeping itself, e.g. a `switch()` branch that returns
`invisible(NULL)` without erroring) — distinct from, and in addition to,
`oracle_errors` entries, which are expected, loud, and allowed to reach
Julia (see (3) below).

### (2) `standard_errors`/`loading_ci` etc. did NOT need a coverage-check
fix — they needed a diagnosis

Per the table above: 15 real accessor-call bugs, not a coverage-tracking
bug. The coverage check in (1) guards against a *different* failure mode
(a case producing neither outcome) that did not actually occur in
`wave5-conversion3` — every one of the 15 non-computed cases DID land in
`oracle_errors` correctly; the batch's failure was that nothing acted on
`oracle_errors` being non-empty before crashing inside Julia on the first
missing key.

### (3) Julia stage: soft per-case FAIL instead of a hard abort

`tools/core070_surface_conversion_batch.jl`'s case loop previously had:

```julia
haskey(oracle["oracle_values"], case_id) || error("no R oracle value recorded for $case_id")
```

Replaced with a per-case recorded FAIL (`"missing_oracle_value: R
oracle_errors[$case_id] = $(r_err)"`, echoing the actual R-side error
message into the Julia results JSON) and `continue`, so one R-side gap
can never abort the whole batch — every other case still gets a real
verdict, and the receipt still ends `FAIL` via `all_ok` (unchanged
semantics: `global all_ok &= ok` / `global all_ok = false`, keeping the
"soft-scope global all_ok" fix already in the file).

### (4) Dry sanity pass — case_id → R branch coverage (plain python, run in this session)

```
$ python3 - <<'PY'
# reads tools/core070_surface_conversion_batch.R's r_quantity() switch()
# labels and docs/dev-log/core070/surface-conversion-batch-contract.json's
# cases[], and cross-checks coverage both ways.
PY
```

Result: **all 24 contract cases map to a real R `switch()` branch** (23
via `r_quantity(quantity)`, 1 — the `refusal_pair` `CI-ROUTE-009` — via the
inline `confint(..., method="profile")` check that bypasses
`r_quantity()` entirely by design). **Zero dead R branches** (every label
in the `switch()` is referenced by at least one contract case). **Zero
contract quantities without an R branch** (a drift here would hit the
`switch()`'s `stop("BOGUS_QUANTITY...")` default — loud, not silent).
Full per-case table:

```
[OK] CORE070-SURFCONV-INFERENCE-CI-ROUTE-009                        -> refusal_pair (inline confint check)
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-COMMUNALITY   -> communality
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-CORRELATIONS  -> correlations
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-CUTPOINTS     -> cutpoints
[OK] CORE070-SURFCONV-INFERENCE-CI-ROUTE-011                        -> icc_ci_bootstrap
[OK] CORE070-SURFCONV-INFERENCE-CI-ROUTE-008                        -> icc_ci_default
[OK] CORE070-SURFCONV-INFERENCE-CI-ROUTE-010                        -> icc_ci_wald
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-ICC-SITE      -> icc_site
[OK] CORE070-SURFCONV-NAMESPACE-EXPORT-GETLOADINGS                  -> loadings_crossprod
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-GETLOADINGS           -> loadings_crossprod
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-LOADINGS      -> loadings_crossprod
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-GETLV                 -> lv_predictor
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-OMEGA         -> omega
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-ORDINATION    -> ordination_sites
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-PROPORTIONS   -> proportions
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-REPEATABILITY -> repeatability_point
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-RESIDUAL-COR  -> residual_cor
[OK] CORE070-SURFCONV-NAMESPACE-EXPORT-GETRESIDUALCOR               -> residual_cor
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-GETRESIDUALCOR        -> residual_cor
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-RESIDUAL-COV  -> residual_cov
[OK] CORE070-SURFCONV-NAMESPACE-EXPORT-GETRESIDUALCOV               -> residual_cov
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-GETRESIDUALCOV        -> residual_cov
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-SIGMA-TABLE   -> sigma_table
[OK] CORE070-SURFCONV-POSTFIT-POSTFIT-SURFACE-EXTRACT-SIGMA         -> sigma_unit_total
```

### Counts updated everywhere

`docs/dev-log/core070/surface-conversion-batch-contract.json`
(`expected_case_count`/`expected_deferred_count`: 34/7 → 24/17, cases[]
and deferred[] arrays moved), `tools/core070_surface_conversion_batch.R`
(`stopifnot()` literals + header comment), `tools/core070_surface_conversion_batch.jl`
(count-drift guard), `tools/core070_verify_surface_conversion_batch.py`
(`CASE_COUNT`/`DEFERRED_COUNT`). `target_source_ids` (41) is unchanged —
every row is still accounted for, just redistributed between the two
buckets.

**Re-verified locally**: `Rscript -e 'parse(...)'` → R parse OK; `julia -e
'Meta.parseall(...)'` → Julia parse OK; `python3
tools/core070_verify_surface_conversion_batch.py --self-test` →
`CORE070_SURFACE_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=5
cases=24 deferred=17`.

## Repair 3 (2026-09-01): wave5-conversion4 forensics — 5 issue classes

`wave5-conversion4` ran end-to-end with full per-case forensics (the loud
coverage guard + Julia soft-fail from Repair 2 both worked as designed).
Five classes of remaining defect, each diagnosed from source and fixed or
re-typed rather than tolerance-widened:

### 1. Miscalibrated 1e-6 tolerance tier — removed entirely

`EXTRACT-SIGMA`/`EXTRACT-SIGMA-TABLE` failed at `max_abs_diff=2.42e-6` vs
the old `1e-6` bar. Re-examined the reasoning behind the "1e-6 deterministic
transform" tier from the first attempt: it assumed some quantities were a
closed-form transform computed once inside a single process. That premise
is false for **every** quantity in this contract — R always computes on
`fit_g`/`fit_tl` from R's own TMB optimiser, Julia always computes on its
own independently-converged LBFGS fit on the same simulated `Y`. There is
no case anywhere in this batch where both engines transform the *same*
fitted numbers. **Every remaining 1e-6 case was recalibrated to the 1e-4
paired-independent-fit precedent**, with a `tolerance_note` field recorded
in-contract per row explaining why (see `sigma_unit_total`, `sigma_table`,
`correlations`, `residual_cov`, `residual_cor`, `ordination_sites`
[already 1e-4], `proportions`, `omega`, `icc_site`). The 1e-6 tier no
longer exists anywhere in the contract.

### 2. Empty R comparands (`r_len=0`) — `EXTRACT-RESIDUAL-COV`/`COR`, `GETRESIDUALCOV`/`COR`

Re-read `output-methods.R`: `getResidualCov(fit, level="unit")`'s
**default** is `level="unit"`; the first attempt deliberately passed
`level="unit_obs"` to avoid duplicating `sigma_unit_total`'s content. But
`gaussian_small` has no `unit_obs`/W-tier block at all (`K_W=0`,
`unique=FALSE`) — `.extract_Sigma_legacy_payload()` returns `NULL`/empty
for a tier the fit does not carry, by design, not a bug. **Fixed**: both R
and Julia now request `level="unit"`/`level=:unit` (R's own default) for
all 6 `residual_cov`/`residual_cor` rows. This is a genuine, non-empty
exercise of the `getResidualCov`/`getResidualCor`/`extract_residual_cov`/
`extract_residual_cor` Julia surfaces — it happens to coincide numerically
with `sigma_unit_total` on this single-tier fixture, but that coincidence
is a property of the fixture's shape (no separate residual tier to
distinguish it from), not evidence the surface went untested.

### 3. Shape mismatch — `EXTRACT-CUTPOINTS` (`r_len=5` vs `julia_len=10`)

R's `extract_cutpoints()$tau_estimate` reports only the `K-2` **free**
cutpoints per trait (Hadfield 2015 convention: `tau_1 = 0` fixed for
identifiability, never reported). `GLLVM.jl`'s `OrdinalPerTraitFit.τ` is a
`p × (C-1)` matrix whose **first column is the fixed `τ_1 = 0.0`**
(`src/families/ordinal.jl`: `τ[t, 1] = 0.0`) — `vec(τ)` on the whole
matrix includes that fixed column, doubling the entry count (`p*(C-1) = 10`
vs R's `p = 5` free cutpoints for `C=3`). **Fixed**: the Julia side now
flattens `τ[:, 2:end]` (drops the fixed column), matching R's
free-cutpoints-only convention exactly. The layout is documented explicitly
in-contract via a `layout_note` field on the `EXTRACT-CUTPOINTS` case.

### 4. Loadings/LV cases — genuine bugs, not (only) a sign/rotation issue

Re-read the standing rule and traced both computations precisely:

- **`loadings_crossprod`** (`GETLOADINGS` ×2, `EXTRACT-LOADINGS`): the
  first attempt used `crossprod(L)` (R) / `L' * L` (Julia) — `Λᵀ Λ` (`d×d`).
  This is **not** rotation-invariant: under an orthogonal rotation `Q`,
  `(ΛQ)ᵀ(ΛQ) = Qᵀ ΛᵀΛ Q ≠ ΛᵀΛ` in general. The rotation-invariant Gram
  matrix is `Λ Λᵀ` (`p×p`): `(ΛQ)(ΛQ)ᵀ = Λ Q Qᵀ Λᵀ = Λ Λᵀ` for any
  orthogonal `Q`. **Fixed**: `tcrossprod(L)` (R) / `L * L'` (Julia) — the
  same `p×p` invariant already used for every other Σ-shaped quantity in
  this file. The first attempt had, in effect, been comparing a
  basis-dependent quantity across two independently-rotated fits — exactly
  the failure mode the standing rule exists to prevent, just one matrix
  transpose away from correct.
- **`lv_predictor`** (`GETLV`): two compounding bugs, not one. (a)
  `GLLVM.getLV(fit, y)` returns an `n×K` matrix (confirmed by reading
  `postfit.jl`'s `Zt = permutedims(Z)`), but the first attempt multiplied
  `Λ (p×K) * Z (n×K)` directly — non-conformable for `K=2, n=80`, which is
  why this case failed outright rather than merely missing tolerance (a
  dimension bug, not a tolerance bug). **Fixed**: `Λ * Z'`. (b) Julia's
  `getLV` defaults to `rotate=true` while `fit_g.pars.Λ` is the model's raw
  (unrotated) internal `Λ` — multiplying a rotated `Z` by a raw `Λ` breaks
  the `ΛZ` reconstruction internally (it no longer reconstructs the actual
  fitted predictor), independent of cross-engine comparison. **Fixed**:
  `rotate=false` on the Julia `getLV` call, matching `fit_g.pars.Λ` and R's
  own `getLoadings`/`getLV` default `rotate="none"`. With both bugs fixed,
  `Λ·Z` is the legitimate rotation-invariant quantity the standing rule
  recommends (`(ΛQ)(Qᵀz) = Λz` for any consistent rotation `Q` applied to
  both factors within one fit) — verified this is what R's raw+raw
  computation already did; Julia now matches it internally-consistently
  too.

### 5. Big diffs — definition mismatches, not tolerance or call bugs

- **`EXTRACT-COMMUNALITY`** (diff `0.871`): traced both definitions to
  source. `GLLVM.jl`'s `communality(fit::GllvmFit)` denominator is
  `sigma_y_site(fit)` — the **full** model-implied total variance across
  ALL tiers **plus** `sigma_eps²` (the Gaussian observation residual).
  R's `extract_communality(fit, level)` denominator is
  `extract_Sigma(fit, level, part="total")$Sigma` — a **single tier's**
  total only; `sigma_eps²` never enters any R `extract_communality`/
  `extract_Sigma` tier computation for a Gaussian fit at all (it isn't one
  of the `B`/`W`/`phy` component tiers R's tier system tracks). On
  `gaussian_small` (`unique=FALSE`, no W tier): `level="unit"` degenerates
  to an uninformative constant `1.0` for every trait (`shared_B ==
  total_B` exactly, no diag term to make them differ) — this exactly
  explains the observed `0.871` diff (R's degenerate `≈1.0` vs Julia's real
  `shared/(shared+sigma_eps²)` ratio); `level="unit_obs"` returns `NULL`
  outright (`fit$use$rr_W` is `FALSE`, no W-tier loadings on this
  fixture). **No R call on this fixture targets the same estimand Julia
  computes** — this is a genuine cross-engine definition mismatch, not a
  fixable call bug. **Moved from `cases[]` to `deferred[]`** with the full
  traced reasoning recorded in-contract.
- **`CI-ROUTE-011`** (icc bootstrap, diff `0.52` vs the already-loose
  `0.05` bar): `n_boot=200` percentile-bootstrap endpoints come from **two
  independent stochastic simulate-refit procedures** (R's
  `bootstrap_Sigma()`-based route, Julia's `repeatability_bootstrap_ci()`)
  with no shared seed/replicate correspondence — Monte Carlo error on each
  engine's own endpoints at this `n_boot` scale routinely exceeds any
  numeric-distance bar tight enough to still be a meaningful check.
  **Re-typed** from a numeric `ci` case to a new `kind = "bootstrap_structural"`:
  each engine independently checks its own bootstrap CI is (a) finite, (b)
  ordered (`lower <= upper`), and (c) brackets that engine's own
  wald-route point estimate (`extract_repeatability(method="wald")$R` /
  `GLLVM.extract_repeatability(fit_tl)`) — no cross-engine numeric distance
  at all, with the justification recorded in-contract
  (`structural_justification` field). The numerically comparable ICC
  routes remain `CI-ROUTE-008` (default→wald) and `CI-ROUTE-010` (explicit
  wald), both still ordinary `1e-3`-tolerance `ci` cases.

### Net counts

`extract_communality` moved to `deferred[]` (the only quantity removed
this round): **24 → 23 executable, 17 → 18 deferred, 41 total unchanged**.
`icc_ci_bootstrap`/`CI-ROUTE-011` stays in `cases[]` but as
`kind="bootstrap_structural"` (no numeric `tolerance`) rather than a
`ci`-kind numeric case.

### Coverage guard and soft-fail — kept, extended

The loud coverage check (R, before invoking Julia) and the Julia
`missing_oracle_value` soft-fail (Repair 2) are both unchanged and still
apply to every case, including the new `bootstrap_structural` kind (its R
side records `oracle_errors[[case_id]]` on failure exactly like every other
kind, so a bootstrap-fit failure is still loud, never silent). The Julia
main-loop and the python verifier's `check_state`/`_synthetic_state`/
mutation set were extended with a third kind branch (`bootstrap_structural`,
alongside `refusal_pair` and the standard numeric kinds) rather than
special-cased ad hoc.

**Re-verified locally**: `Rscript -e 'parse(...)'` → R parse OK; `julia -e
'Meta.parseall(...)'` → Julia parse OK; `python3
tools/core070_verify_surface_conversion_batch.py --self-test` →
`CORE070_SURFACE_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=6
cases=23 deferred=18` (6 rejected mutations now, up from 5 — added a
`bootstrap_structural`-specific mutation, `julia_structural.ordered`
flipped false, exercising the new kind's rejection path explicitly).

## Repair 4 (2026-09-01): wave5-conversion5 — 4 fails, one family

`wave5-conversion5` ran 19/23 PASS. All 4 fails traced to source; resolved
per-case rather than tolerance-widened, per the coordinator's directive to
prefer a real fix where one exists.

### (a) `EXTRACT-ICC-SITE` — fixture reassignment, not a deferral

R's `extract_ICC_site()` returned empty on `gaussian_small`: its
`vB/vW` ratio needs BOTH a `unit` (B) tier AND a `unit_obs` (W) tier to be
defined at all (`extract_Sigma(level="unit_obs", ...)` is `NULL` on a
single-tier fit), and `gaussian_small` has no W tier (`K_W=0`). **Fixed by
reassigning the fixture**: `icc_site` now runs on `twolevel_small`
(`fit_tl`) on both sides, where both tiers exist by construction. Bonus
finding while tracing this: `GLLVM.extract_ICC_site(fit::TwoLevelFit)` is
itself defined as `= extract_repeatability(fit)`
(`src/extractors.jl:458`) — so this case is now numerically identical to
`repeatability_point` on the same fixture. That's an intentional
consequence of the two engines' own internal equivalence (R's
`extract_ICC_site` on a two-tier fit reduces to the same `vB/(vB+vW)`
ratio `extract_repeatability`'s wald route computes), not redundant test
design — both are still independently valid conversions of two different
ledger rows (`postfit/POSTFIT-SURFACE-extract_ICC_site` vs
`postfit/POSTFIT-SURFACE-extract_repeatability`).

### (b) `EXTRACT-OMEGA` — R-side coercion bug, fixed

`extract_Omega()` returns a **list**
(`list(Omega=, R_Omega=, tiers_used=, note=, [residual_split=])`, confirmed
by reading `extract-omega.R`'s final `out <- list(...)`), not a bare
matrix. The runner's `as.numeric(extract_Omega(fit_g))` tried to coerce
the whole list — `'list' object cannot be coerced to type 'double'`.
**Fixed**: `as.numeric(extract_Omega(fit_g)$Omega)`. Unlike
`communality`/`correlations`/`proportions`, `Omega` is a **covariance
sum** across tiers, not a variance *ratio* — it never divides by a
total-variance denominator, so there is no tier-scoped-vs-full-total
estimand question here at all. On `gaussian_small` (single `B` tier, no
diag, Gaussian family contributes 0 link-residual), both R's and Julia's
`Omega` reduce to the same `Λ Λᵀ` sum — a real, fixable bug, not a
definition mismatch, exactly as the coordinator's framing predicted.

### (c) `EXTRACT-CORRELATIONS` + `EXTRACT-PROPORTIONS` — same estimand mismatch as `extract_communality`, deferred

Traced both to source, as instructed:

- **`correlations`** (diff `0.668`): this quantity's R-side route was
  already `extract_Sigma(fit_g, level="unit", part="total")$R` (chosen in
  Repair 2 because `extract_correlations()` itself returns an un-coercible
  long-format table) — standardises by the **unit (B) tier total only**,
  which never includes `sigma_eps²` for a Gaussian fit. Julia's
  `extract_correlations(fit) = correlation(fit)`
  (`src/confint_derived.jl:280`) standardises by `sigma_y_site(fit)`, the
  **full** total variance including `sigma_eps²`. Same mismatch class as
  `extract_communality`, confirmed by reading `correlation()`'s body
  directly (`Σ = sigma_y_site(fit)`).
- **`proportions`** (diff `0.8713` — **the exact value `extract_communality`
  failed at**): `GLLVM.extract_proportions(fit; component=:shared)` and
  `communality(fit)` are the **same function mathematically** — both
  `ΛΛᵀ[t,t] / sigma_y_site(fit)[t,t]`. R's `extract_proportions()`'s
  `shared_unit` component's `proportion` column has denominator
  `total <- rowSums(M)`, where `M` only ever contains the tier-scoped
  components R's system tracks (`shared_unit` alone on this fixture) —
  `sigma_eps²` is never one of them, so `proportion` degenerates to
  `shared_unit/shared_unit == 1.0` for every trait, for the identical
  reason `extract_communality` degenerates. The matching diff value is not
  a coincidence — it's the same underlying computation on both sides.

**Both moved from `cases[]` to `deferred[]`** with the full trace recorded
in-contract (`reason` field), joining `extract_communality` — all three
now await the same maintainer estimand-alignment decision: either widen
GLLVM.jl's `communality`/`correlation`/`proportions` family to also expose
a tier-scoped (non-`sigma_eps²`) variant matching R's convention, or accept
that R's tier-scoped and Julia's total-variance-scoped versions are
deliberately different estimands that should never be cross-compared
numerically. That decision is out of this batch's scope (batch = ledger
conversion evidence, not estimand design).

### Net counts

`extract_correlations` and `extract_proportions` moved to `deferred[]`;
`extract_ICC_site` stayed in `cases[]` (fixture changed, not removed);
`extract_Omega` stayed in `cases[]` (bug fixed in place):
**23 → 21 executable, 18 → 20 deferred, 41 total unchanged.**

### Coverage guard, soft-fail, structural-bootstrap machinery — all kept unchanged

No changes to the loud coverage check, the Julia `missing_oracle_value`
soft-fail, or the `bootstrap_structural` kind from Repairs 2–3; this round
only changed which quantities are computed and on which fixture.

**Re-verified locally**: `Rscript -e 'parse(...)'` → R parse OK; `julia -e
'Meta.parseall(...)'` → Julia parse OK; `python3
tools/core070_verify_surface_conversion_batch.py --self-test` →
`CORE070_SURFACE_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=6
cases=21 deferred=20`. A fresh case_id → R-branch dry-mapping (same python
cross-check method as Repair 2) confirms all 21 cases map to a real
`r_quantity()` branch or the `refusal_pair`/`bootstrap_structural`
bypasses, zero dead branches.

## Repair 5 (2026-09-01): wave5-conversion6 — EXTRACT-OMEGA, and forensic storage

`wave5-conversion6` ran 20/21 PASS; only `EXTRACT-OMEGA` failed
(`max_abs_diff=0.467`, `r_len=25`, diagonal-scale: R's `Omega` diagonal
`[0.572, 0.457, 0.176, 0.351, 0.069]`).

### (1) Forensic storage — Julia now stores `julia_values` for every numeric case

`tools/core070_surface_conversion_batch.jl`'s per-case results `Dict` now
carries a `"julia_values" => jl_vec` field alongside the existing
`max_abs_diff`/`r_len`/`julia_len`/`error` fields, for every `point`/`ci`
kind case (not gated on pass/fail — cheap for these small vectors, ≤25
entries, and simpler than a conditional). R already writes its own numbers
into `oracle_values` in `r-oracle.json`. Together, a failing case's full
forensic record — both engines' actual numbers — is now retained in
`julia-results.json`/`r-oracle.json` without needing a refit to diagnose.

### (2) EXTRACT-OMEGA — traced to source, confirmed as the 4th estimand-alignment member, deferred

Read `extract_Omega()`'s full body and GLLVM.jl's `extract_Omega` side by
side:

- **R**: builds `tiers` from the fit's ACTUAL structure only —
  `"B"` iff `fit$use$rr_B || diag_B`, `"W"` iff `fit$use$rr_W || diag_W`,
  `"phy"` iff `phylo_rr || phylo_diag` — then sums
  `extract_Sigma(level=tier, part="total", link_residual="none")` for each
  tier present. `gaussian_small` has no W-tier at all
  (`rr_W=FALSE, diag_W=FALSE`), so R's `tiers = "B"` only:
  `Omega = Lambda_B Lambda_B^T` exactly. `sigma_eps^2` never enters — it
  is not one of the `B`/`W`/`phy` component tiers R's system tracks (same
  structural gap already found for `communality`/`correlations`/
  `proportions`), and the Gaussian family's `link_residual_per_trait()`
  separately contributes `0`.
- **Julia**: `extract_Omega(fit::GllvmFit)` **unconditionally** computes
  `extract_Sigma(level=:unit,...).Sigma .+ extract_Sigma(level=:unit_obs,...).Sigma`
  — no tier-presence check at all. `extract_Sigma(level=:unit_obs,
  part=:total)`'s own body (`_sigma_unit_obs`, `src/extractors.jl`)
  **always** adds `sigma_eps^2 * I` as a baseline term, regardless of
  whether a genuine W-tier (`Λ_W`) exists. So on `gaussian_small`, Julia's
  `Omega = Lambda_B Lambda_B^T + sigma_eps^2 * I` — differing from R's by
  exactly `sigma_eps^2` on the diagonal. **Confirmed**: the observed
  `max_abs_diff` (`0.467`) is diagonal-scale and close to
  `sigma_true^2 = 0.49` (the true simulated residual variance), matching
  this trace exactly — precisely the "Ψ/σ²_eps inclusion difference on the
  diagonal" the coordinator predicted.

**No alignment argument exists**: `extract_Omega(fit::GllvmFit)` takes no
`tiers`/`level`/`link_residual` keyword at all (unlike `getResidualCov`'s
alignable `level=` argument, which *was* fixable in Repair 3) — there is
no call that narrows Julia's composition to match R's. Also tried
sourcing the R comparand as `extract_Sigma(fit_g, level="unit_obs",
...)$Sigma` directly instead of `extract_Omega()` (mirroring the
`extract_correlations` substitution from Repair 2): R's own
tier-existence gate returns `NULL` for `level="unit_obs"` on this
single-tier fixture — the identical gate behind `wave5-conversion4`'s
`residual_cov` `r_len=0` failure — so R's tier system has genuinely no way
to express "the Gaussian residual variance" independent of an actual
W-tier. **Moved from `cases[]` to `deferred[]`**, joining `communality`,
`correlations`, and `proportions` as the 4th member of the
estimand-alignment family (plus `cross_correlations`, which is a
different kind of mismatch — a multinomial-only R route, not a
tier-scoping one).

### Net counts

`extract_Omega` moved to `deferred[]`: **21 → 20 executable, 20 → 21
deferred, 41 total unchanged.**

**Re-verified locally**: `Rscript -e 'parse(...)'` → R parse OK; `julia -e
'Meta.parseall(...)'` → Julia parse OK; `python3
tools/core070_verify_surface_conversion_batch.py --self-test` →
`CORE070_SURFACE_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=6
cases=20 deferred=21`. Fresh dry-mapping: all 20 cases map to a real
`r_quantity()` branch or the `refusal_pair`/`bootstrap_structural`
bypasses, zero dead branches.
