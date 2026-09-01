# Conversion batch #4 (wave-8) — pairing `src/postfit_tables.jl`'s 12-item cluster

Pays 7 of the 12 `BLOCKED_NEEDS_JULIA_SURFACE` ledger rows in
`docs/dev-log/core070/required-source-case-map.json` that correspond to the
12 functions landed in `src/postfit_tables.jl`
(`docs/dev-log/core070/final-surface-slice-notes.md`: `deviance`,
`profile_cross_rho_ci`, `predict_cross_covariance`, `predict_missing`,
`simulate_unit_trait`, `profile_cross_rho`, `rotate_loadings`,
`extract_rotated_loadings_table`, `extract_coevolution_modules`, `imputed`,
`tidy`, `summary`). The other 5 are deferred with a per-row trace in the
contract's `deferred[]`.

## Row enumeration (12 target rows, exact)

Searched `required-source-case-map.json`'s `rows[]` for every
`postfit/POSTFIT-SURFACE-*` entry whose function name (after the
`POSTFIT-SURFACE-` prefix and any `.gllvmTMB`/`.gllvmTMB_multi` S3
dot-suffix) is one of the 12 `postfit_tables.jl` functions, restricted to
`disposition: BLOCKED_NEEDS_JULIA_SURFACE` (a plain "the Julia surface did
not exist yet" blocker — now resolved by the surface landing):

- `postfit/POSTFIT-SURFACE-deviance.gllvmTMB_multi`
- `postfit/POSTFIT-SURFACE-extract_coevolution_modules`
- `postfit/POSTFIT-SURFACE-extract_rotated_loadings_table`
- `postfit/POSTFIT-SURFACE-imputed.gllvmTMB`
- `postfit/POSTFIT-SURFACE-predict_cross_covariance`
- `postfit/POSTFIT-SURFACE-predict_missing`
- `postfit/POSTFIT-SURFACE-profile_cross_rho`
- `postfit/POSTFIT-SURFACE-profile_cross_rho_ci`
- `postfit/POSTFIT-SURFACE-rotate_loadings`
- `postfit/POSTFIT-SURFACE-simulate_unit_trait`
- `postfit/POSTFIT-SURFACE-summary.gllvmTMB_multi`
- `postfit/POSTFIT-SURFACE-tidy.gllvmTMB_multi`

**Two rows deliberately excluded**, both matching the task brief's own
`impute_model?` question mark and its "rows whose function is NOT one of
the 12 stay out" instruction:

- `postfit/POSTFIT-SURFACE-impute_model` — a *different* R function
  (`impute_model`, not `imputed`), not implemented by this slice's 12
  functions (`final-surface-slice-notes.md` lists `imputed`, not
  `impute_model`). Its own `disposition` is `BLOCKED_NEEDS_JULIA_SURFACE`,
  the same class as the other rows, but it names a function this batch's
  surface set does not cover — pulling it in would be paying a ledger row
  with a function that was never built.
- `postfit/POSTFIT-SURFACE-tidy` (bare, no `.gllvmTMB_multi` suffix) — the
  NAMESPACE-level `export(tidy)` re-export of `generics::tidy`, already
  `disposition: BLOCKED_SPEC_DEFECT` with a `reclassify_proposed` to
  `compatibility_adapter` recorded by an earlier wave (its own `evidence.note`:
  "case has null r_call and empty comparands by design"). Distinct row from
  `tidy.gllvmTMB_multi` (the one actually converted here), and reclassifying
  or converting the bare-generic row is a separate maintainer decision, not
  part of this batch.

Also excluded on inspection (found while enumerating, not part of the 12):
`namespace/S3method/*`, `namespace/export/*`, and `postfit-policy/POST-*`
rows for the same function names — these have their own separate
`disposition`s (several already `PASS` from wave-3's namespace batch, one
`PARTIAL_PENDING_DECISION_RECLASSIFY`) and are not `postfit/POSTFIT-SURFACE-*`
rows; the task brief's own example list names only `postfit/POSTFIT-SURFACE-*`
rows.

## Executable vs deferred split (7 / 5)

**Executable (7)**, all on the `gaussian_small` fixture reused verbatim from
`tools/core070_surface_conversion_batch.R` /
`tools/core070_wave6_conversion_batch.R` /
`tools/core070_wave7_conversion_batch.R` (seed 42, p=5, K=2, n=80):

| case_id | source_id | kind | tolerance |
| --- | --- | --- | --- |
| `CORE070-WAVE8-DEVIANCE-MULTI` | `deviance.gllvmTMB_multi` | point | 1e-3 |
| `CORE070-WAVE8-TIDY-FIXED-ESTIMATE` | `tidy.gllvmTMB_multi` | point | 1e-4 |
| `CORE070-WAVE8-SUMMARY-FIXEF-AND-LOGLIK` | `summary.gllvmTMB_multi` | point | 1e-4 |
| `CORE070-WAVE8-ROTATE-LOADINGS-LLT-INVARIANT` | `rotate_loadings` | point | 1e-4 |
| `CORE070-WAVE8-EXTRACT-ROTATED-LOADINGS-TABLE-SHAPE` | `extract_rotated_loadings_table` | verdict | — |
| `CORE070-WAVE8-PREDICT-MISSING-ZERO-ROWS` | `predict_missing` | verdict | — |
| `CORE070-WAVE8-SIMULATE-UNIT-TRAIT-STRUCTURAL` | `simulate_unit_trait` | verdict | — |

One deliberate fixture extension: **wave6/wave7's Julia child never passed
`X` to `fit_gaussian_gllvm`**, so Julia's `β` was empty (zero-mean model);
R's fixture formula (`value ~ 0 + trait + latent(...)`) always had 5
per-trait fixed-effect intercepts. That mismatch never mattered for wave-7's
cases (fitted/predict/residuals don't need `X` to be comparable), but
`tidy`/`summary`'s fixed-effect quantities are vacuous without it. This
batch's Julia child builds `X_g`, a `p × n × p` one-hot trait design
matching R's `0 + trait` dummy coding column-for-column, and fits
`fit_gaussian_gllvm(Y_g; K=2, X=X_g)` — the R fixture (formula, DGP, seed)
is **unchanged**; only the Julia reproduction now supplies the `X` argument
it always needed for full parity.

**Deferred (5)**, all because the R counterpart genuinely needs a
cross-lineage coevolution kernel fit (`extract_coevolution_modules`,
`predict_cross_covariance`, `profile_cross_rho`, `profile_cross_rho_ci`) or
an `mi()`-predictor fit (`imputed.gllvmTMB`) that is not proven anywhere in
this worktree's receipts — the same "do not invent an unproven fixture in a
lean batch" discipline wave-7 established for its phylo-fixture-absent rows
(`profile_ci_phylo_signal`, `profile_phylo_signal`, `extract_Gamma`, etc.).
Each deferred row's `reason` string names the exact R source location read
and the exact fixture gap; see the contract's `deferred[]`.

`predict_missing` is executable **despite** no missing-data fixture existing,
because R's own docstring documents a testable degenerate case without one:
"A complete-data fit (no masked cells) returns a zero-row data frame with the
same columns" — and Julia's `predict_missing` docstring states the identical
equivalence for `mask = nothing`. Both sides are checked to return 0 rows on
the complete-data `gaussian_small` fixture; the masked-cell reconstruction
machinery itself is out of scope (same class of gap as the 5 deferred rows).

`simulate_unit_trait` and `imputed` were flagged in the task brief as
"RNG-independent structural checks... never cross-engine numeric equality of
random draws." `simulate_unit_trait` is executable that way (own-consistency
shape/finiteness checks on each side, plus one legitimate cross-engine
structural invariant — both DGPs draw the same total element count from the
same `n_units`/`n_obs_per_unit`/`n_traits` argument contract). `imputed` is
**not** executable even structurally in this batch: unlike `predict_missing`,
R's `imputed.gllvmTMB` has no documented complete-data/degenerate zero-row
case to fall back on — it *requires* `object$missing_data$predictors` to be
a non-empty list (a genuine `mi()`-formula fit) and aborts loudly otherwise.
There is no fixture-free path to a real R-side call; deferred with that exact
reason.

## Rejection case (symmetric, not asymmetric)

`CORE070-WAVE8-REJ-ROTATE-LOADINGS-BOGUS-LEVEL`: both R (`match.arg` on
`level`) and Julia (`rotate_loadings`'s explicit `level === :unit` guard)
refuse an unrecognised `level` argument. `expect_r_raised = true`,
`expect_julia_raised = true` — a genuine matching-refusal, unlike wave7's
`check_auto_residual(42)` case (a documented asymmetry). Included to keep
the verifier's rejection-case machinery, and its per-side expectation
fields, exercised by a case that is not a copy-paste of wave7's asymmetric
example.

## Dry case → branch mapping (no live R/Julia run in this task)

Per the task's own instruction ("Local verification: R/Julia parse,
verifier `--self-test`, dry case→branch mapping in your reply"), no R or
Julia process was actually executed against the frozen library in this
task — the mapping below was checked by reading both scripts' dispatcher
branches against the contract's `cases[]`/`rejection_cases[]` `case_id`s,
confirming every `case_id` the contract declares has exactly one matching
`if/elseif` arm in both `tools/core070_wave8_conversion_batch.R`'s
`r_case_value()`/verdict dispatcher and
`tools/core070_wave8_conversion_batch.jl`'s point/verdict dispatcher, and no
arm exists for a `case_id` the contract does not declare (both scripts
`stop`/`error` on an unmatched `case_id` — `BOGUS_CASE_ID`, never silently
skip):

| case_id | R branch | Julia branch |
| --- | --- | --- |
| `CORE070-WAVE8-DEVIANCE-MULTI` | `r_case_value()` point switch, `deviance(fit_g)` | point dispatch, `GLLVM.deviance(fit_g)` |
| `CORE070-WAVE8-TIDY-FIXED-ESTIMATE` | `r_case_value()` point switch, `tidy(fit_g)$estimate` | point dispatch, `GLLVM.tidy(fit_g, Y_g; X=X_g)` estimates |
| `CORE070-WAVE8-SUMMARY-FIXEF-AND-LOGLIK` | `r_case_value()` point switch, `summary(fit_g)$fixef$Estimate` + `$header$logLik` | point dispatch, `summary(fit_g, Y_g; X=X_g)` fixef + logLik |
| `CORE070-WAVE8-ROTATE-LOADINGS-LLT-INVARIANT` | `r_case_value()` point switch, `tcrossprod(rotate_loadings(fit_g, ...)$Lambda)` | point dispatch, `rot.Lambda * rot.Lambda'` |
| `CORE070-WAVE8-EXTRACT-ROTATED-LOADINGS-TABLE-SHAPE` | verdict dispatcher, `extract_rotated_loadings_table(fit_g)` shape/axis_share checks | verdict dispatch, same checks on `GLLVM.extract_rotated_loadings_table(fit_g, Y_g; ...)` |
| `CORE070-WAVE8-PREDICT-MISSING-ZERO-ROWS` | verdict dispatcher, `nrow(predict_missing(fit_g)) == 0` | verdict dispatch, `length(GLLVM.predict_missing(fit_g, Y_g).row) == 0` |
| `CORE070-WAVE8-SIMULATE-UNIT-TRAIT-STRUCTURAL` | verdict dispatcher, `simulate_unit_trait(...)` shape/finite checks | verdict dispatch, `GLLVM.simulate_unit_trait(_SUT_RNG; ...)` shape/finite checks |
| `CORE070-WAVE8-REJ-ROTATE-LOADINGS-BOGUS-LEVEL` | rejection loop, `rotate_loadings(fit_g, level="bogus_level_value")` | rejection loop, `GLLVM.rotate_loadings(fit_g, Y_g; level=:bogus_level_value)` |

Every `contract$cases[[i]]$kind` (`"point"` ×4, `"verdict"` ×3) matches one
of the two kinds each script's dispatcher `if kind == "point" / "verdict"`
branch handles; the contract carries no `"own_consistency"` kind in this
batch (unlike wave-7), so that branch was omitted from both scripts rather
than left as dead code.

## Local verification performed

- `python3 -c "import json; json.load(open('docs/dev-log/core070/wave8-conversion-batch-contract.json'))"` — `JSON_OK`.
- `python3 tools/core070_verify_wave8_conversion_batch.py --self-test` —
  `CORE070_WAVE8_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=9 cases=7 deferred=5`
  (9 independent mutations rejected, ≥6 required; includes a mutation
  specific to this batch's symmetric rejection case, `julia_raised` flipped
  to `False` against its `expect_julia_raised=true`).
- `python3 tools/core070_verify_wave8_conversion_batch.py` (no `--state`) —
  contract-only structural pass (`CORE070_WAVE8_CONVERSION_CONTRACT_OK
  cases=7 deferred=5 total_target_rows=12`), then the expected `FATAL` exit
  1 for missing `--state` (a self-test/contract-only pass never substitutes
  for a real retained-run check).
- `Rscript -e 'parse("tools/core070_wave8_conversion_batch.R")'` —
  `R_PARSE_OK`.
- `Rscript -e 'jsonlite::read_json(...)'` against the actual contract file —
  confirms `cases: 7 deferred: 5 rejection: 1 target: 12`.
- `julia -e 'Base.Meta.parseall(read("tools/core070_wave8_conversion_batch.jl", String))'` —
  `JULIA_PARSE_OK`.

No R+Julia+frozen-library live run was performed in this task (no `julia`
process was started against `GLLVM.jl`'s actual source, and no frozen
`gllvmTMB` library was loaded) — that is the Totoro run below.

## Totoro run command

```sh
Rscript --vanilla tools/core070_wave8_conversion_batch.R \
  /path/to/frozen-gllvmTMB-library \
  .unlazy/core070-aghq/wave8-conversion-01
python3 tools/core070_verify_wave8_conversion_batch.py \
  .unlazy/core070-aghq/wave8-conversion-01
```

(Frozen library path and receipts directory convention match wave-6/wave-7:
`.unlazy/core070-aghq/wave{6,7}-batches/`.)

## Files touched (this lane only)

- `docs/dev-log/core070/wave8-conversion-batch-contract.json`
- `tools/core070_wave8_conversion_batch.R`
- `tools/core070_wave8_conversion_batch.jl`
- `tools/core070_verify_wave8_conversion_batch.py`
- `docs/dev-log/core070/wave8-conversion-notes.md` (this file)
