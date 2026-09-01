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
