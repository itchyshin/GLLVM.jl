# Wave-7 conversion batch (#3): notes

## Scope

Pays 7 of the 45 `BLOCKED_NEEDS_JULIA_SURFACE` rows in
`docs/dev-log/core070/required-source-case-map.json` whose function name
(after stripping the `POSTFIT-SURFACE-` prefix and any S3 dot-suffix)
matches an entry in `names(GLLVM)` as of this worktree's HEAD (verified by
cross-checking the 91 `BLOCKED_NEEDS_JULIA_SURFACE` rows against a live
`julia --project=. -e 'using GLLVM; names(GLLVM)'` dump: 45 matched, exactly
as the task brief specified).

- **6 comparison cases, 7 source rows executable** (one case,
  `CORE070-WAVE7-SANITY-MULTI`, covers two source_ids —
  `postfit/POSTFIT-SURFACE-sanity_multi` and `namespace/export/sanity_multi`
  — since they name the identical underlying Julia surface; same precedent
  as wave-6's duplicate-ledger-row handling).
- **38 deferred**, each with a per-row `reason` string in the contract.

All 6 cases were dry-run end-to-end against a **live local (non-frozen)
gllvmTMB 0.7.1** install in this environment (not the maintainer's pinned
frozen library — that path is supplied at Totoro run time, see "Running
this batch" below) and genuinely PASS at real cross-engine numeric
precision: `max_abs_diff` of 5.7e-6 (FITTED/PREDICT) and 8.6e-6 (RESIDUALS)
against the 1e-4 tolerance, and 0.0 / 6.7e-17 (own-consistency,
COMPARE-LOADINGS-SELF) against 1e-6. See "Dry-run evidence" below for the
full receipt.

## Why only 7 of 45, not more

The task brief asked me to "verify each R function's actual
signature/return in `.unlazy/core070-aghq/oracle-source/readback/R/`" —
never infer from a Julia docstring. Doing that reading (not just trusting
the Julia docstrings' own "mirrors R's X()" framing) surfaced that **most of
the 45 rows are same-name, different-surface collisions**, not simple
missing-conversion gaps:

| Julia name | Julia signature/scope (from src/) | R signature/scope (from oracle-source readback) | Verdict |
|---|---|---|---|
| `getREsd` | `getREsd(fit::GllvmFit, y)` — latent FACTOR SCORE conditional SDs | `getREsd(fit, block=)` — auxiliary RE blocks (diag_unit, phylo, re_int, ...); routes factor scores to `getLV(se=TRUE)` instead | different quantity entirely |
| `compare_Sigma_table` | `compare_Sigma_table(fit1, fit2)` — two-fit Σ_y bridge | `compare_Sigma_table(x, truth, ...)` — fit vs a KNOWN TRUTH matrix | different signature/purpose |
| `compare_dep_vs_two_psi` | `compare_dep_vs_two_psi(fit_dep, fit_alt, n)` — generic two-fit bridge (Julia's own docstring: "Gap vs R") | `compare_dep_vs_two_psi(fit_two_psi, ...)` — phylo "two-ψ" identifiability refit-and-compare on ONE fit | different model class |
| `vcov` | `vcov(fit, y)` — `Diagonal` over ALL packed params | `vcov.gllvmTMB_multi(object)` — full (off-diagonal-capable) FIXED-EFFECT-only block | different scope |
| `diagnostic_table` | `diagnostic_table(fit; ...)` — takes the raw fit | `diagnostic_table(x, table=)` — requires `x` already carry `gllvmTMB_diagnostic` metadata attached by `predictive_check()`/`residuals()` | different call shape |
| `profile_targets` | runs every target's curve directly | READINESS REGISTRY (which params COULD be profiled, without running anything) | different operation |
| `compare_loadings` | `compare_loadings(fit1, fit2)` — tcrossprod-invariant Λ1Λ1ᵀ vs Λ2Λ2ᵀ | `compare_loadings(Lambda_a, Lambda_b)` — raw matrices, Procrustes-rotated frobenius | different quantity, but resolvable as an own-consistency self-pair (both zero on self) |
| `fitted`/`predict`/`residuals` (S3-multi) | `p×n` matrix | `data.frame` with an `est`/`residual` column, same row order as the fit's own data | **resolvable** once the exact column is read (this batch's main positive finding) |

Each such gap is documented per-row in the contract's `deferred[].reason`,
citing the exact file/line read. This discipline — verify from source, not
docstring — is exactly what caught two of my own early mistakes before they
shipped as fabricated passes (see "Corrections made mid-batch" below).

## Phylo and slope-fixture rows

Per the task brief's explicit instruction: rows needing a PHYLO fit
(`extract_phylo_signal`, `profile_ci_phylo_signal`/`phylo_signal`,
`profile_targets` when phylo-scoped) were checked against this worktree's
receipts — `grep -r` over `test/parity/` and `.unlazy/core070-aghq/` found
**no executed paired R+Julia phylo fit** (no `STRUCT-PHY` plan was ever run).
Per the brief, these rows are deferred with that trace rather than inventing
an unproven fixture. Likewise `slope_sd_ci`: no healthy
`GaussianRandomSlopeFit` fixture exists in this worktree's receipts, and
R's own `slope-sd-ci.R` readback documents a prior hand-indexing failure
mode on the phylo route — deferred with that trace, carried forward from
the wave-5 surface-conversion contract.

## Corrections made mid-batch (own forensics, before shipping)

1. **`compare_Sigma_table`/`compare_dep_vs_two_psi`/`compare_indep_vs_two_psi`
   were provisionally planned as self-pair "point" cases**, mirroring
   `compare_loadings`. Reading `extract-sigma-table.R:494-544` and
   `extract-two-psi-cross-check.R:488-556` directly showed R's actual
   signatures take a `truth` ground-truth matrix or internally refit a
   phylo "two-ψ" alternative — neither is a two-fit self-pair at all, so
   these three were moved to `deferred[]` before ever touching the R/Julia
   scripts, rather than shipping a case that would "pass" by construction
   while testing nothing real.
2. **`residuals.gllvmTMB_multi`**: the R call was originally written as
   `as.numeric(residuals(fit_g, ...))`. A live dry run against a local
   (non-frozen) gllvmTMB install showed this returns `length(rs) == 15`
   (the data.frame's **column** count, not 400 rows) — `residuals()`
   returns a 400-row data.frame (`.row, trait, ..., residual, status,
   scale, method, seed`), not a bare vector. Fixed to `residuals(fit_g,
   ...)$residual` and re-verified numerically: `rs$residual == (y -
   fitted(fit_g)$est) / sigma_eps` exactly (`cor == 1`, constant ratio
   across all 400 rows), confirming the Gaussian exact-quantile-residual
   reduction the Julia docstring claims. This is exactly the "never infer
   from a Julia docstring" lesson the task brief flagged — caught here by
   actually running R, not just reading the source.
3. **`check_auto_residual` rejection case**: originally drafted assuming
   both engines refuse a non-fit argument (`expect_julia_raised: true`).
   Reading `src/diagnostics.jl:157-173` showed Julia's port has no
   `inherits()`-style type guard at all — `check_auto_residual(42)` returns
   `coherent=true` silently rather than erroring. Recorded as a documented
   **asymmetry** (`expect_r_raised: true`, `expect_julia_raised: false`)
   per the task brief's "per-side expectation fields for any asymmetric
   behavior" instruction, not forced into a false "both refuse" claim.

## Fixtures

Reused **gaussian_small** verbatim (seed 42, p=5, K=2, n=80,
`value ~ 0 + trait + latent(0 + trait | site, d=2, unique=FALSE)`,
`gllvmTMBcontrol(n_init=1L, se=TRUE)`) from
`tools/core070_surface_conversion_batch.R` /
`tools/core070_wave6_conversion_batch.R` — no new fixture was built. Per
the task brief, `twolevel_small`, `ordinal_small`, and
`structured_kernel_small` were considered but none of the 7 executable rows
needed them (all 7 are plain-gaussian-fit diagnostics/postfit surfaces).

## Comparison design per case kind

- **`point`** (3 cases: FITTED-MULTI, PREDICT-MULTI, RESIDUALS-MULTI):
  elementwise `max(abs(julia - r)) <= tolerance`, tolerance 1e-4
  (paired-independent-fit tier — R's `fit_g` and Julia's `fit_g` are two
  independent optimiser runs on the identical `Y`, never the same
  optimizer state, so 1e-6 "deterministic" tolerance does not apply here;
  matches the task brief's instruction).
- **`verdict`** (2 cases: CHECK-AUTO-RESIDUAL, SANITY-MULTI): compare
  specific boolean fields verified from source to exist on BOTH sides with
  the SAME semantics (R's `status=='ok'` vs Julia's `coherent`; R's
  `$converged`/`$pd_hessian` vs Julia's `.converged`/`.pd_hessian`) — per
  the task brief's guidance to compare "verdict/flag structure semantically
  ... rather than numeric tables where columns differ", used here because
  R's and Julia's diagnostic objects have different overall shapes (rich
  human-report list vs `NamedTuple`) even where individual fields agree.
- **`own_consistency`** (1 case: COMPARE-LOADINGS-SELF-CONSISTENCY): R's
  `compare_loadings(Λ,Λ)` and Julia's `compare_loadings(fit,fit)` compute
  genuinely different quantities (Procrustes frobenius vs tcrossprod
  frobenius) that are not cross-comparable at any tolerance, but each
  engine's own self-pairing must independently report ~0 disagreement —
  both checked against their own zero, not against each other's number.
  Mirrors the wave-6 `own_receipt_defect` pattern for a genuine
  surface-shape gap that is still worth exercising.

No `bootstrap`-kind case was built this wave (bootstrap_Sigma is deferred);
if a future wave builds one, the task brief's "bootstrap cases
structural-only" guidance and the wave-6 first-SE-cell 5e-3 CI-endpoint
precedent apply.

## Rejection case

One rejection case (`CORE070-WAVE7-REJ-CHECK-AUTO-RESIDUAL-NOT-A-FIT`)
records the documented asymmetry above: R refuses a non-fit argument (`
check_auto_residual(42)`), Julia's port does not. `expect_r_raised: true`,
`expect_julia_raised: false` — the verifier checks both sides against their
own per-side expectation (see `mut_rejection_julia_side_flipped` in the
self-test, which proves a value matching the OTHER engine's normal
behaviour, but not the contract's own expectation, is still rejected).

## Dry-run evidence

A full local dry run (`Rscript --vanilla tools/core070_wave7_conversion_batch.R
<local-gllvmTMB-library> <dest>`, against gllvmTMB 0.7.1 installed locally
in this environment, R 4.6.0) produced:

```
CORE070_WAVE7_CONVERSION_BATCH_PASS
```

with `receipt.json.status == "PASS"`, `oracle_error_count == 0`,
`julia_exit_code == 0`, and all 6 `results.tsv` rows `PASS`. Verified against
the Python verifier:

```
$ python3 tools/core070_verify_wave7_conversion_batch.py --self-test <dest>
CORE070_WAVE7_CONVERSION_VERIFY_SELF_TEST_OK rejected_mutations=9 cases=6 deferred=38
CORE070_WAVE7_CONVERSION_CONTRACT_OK cases=6 deferred=38 total_target_rows=45
CORE070_WAVE7_CONVERSION_STATE_OK <dest>
```

Per-case `max_abs_diff`: FITTED-MULTI 5.720044177537353e-06, PREDICT-MULTI
5.720044177537353e-06 (identical to FITTED, as expected — R's `fitted()` is
a thin wrapper over `predict()`), RESIDUALS-MULTI 8.644291438875129e-06, all
`<= 1e-4`. `own_consistency`: R frobenius 6.71962103663268e-17, Julia
frobenius 0.0, both `<= 1e-6`. This dry-run state directory was **not**
retained in this worktree (moved out to `/private/tmp/` after verification,
since it is not one of this batch's owned files) — the canonical retained
run is expected under `.unlazy/core070-aghq/wave7-conversion-01` (or similar)
once run against the maintainer's pinned frozen library, per "Running this
batch" below.

**Caveat on the frozen library**: the local dry run above used the
environment's live gllvmTMB 0.7.1 install, not the maintainer's pinned
frozen library at `reference_commit b4d5fee64def88bc768dda1f1f77c29b295edd86`.
The R call shapes verified here (data.frame return conventions for
`fitted`/`predict`/`residuals`, list fields for `check_auto_residual`/
`sanity_multi`, `compare_loadings`'s Procrustes signature) are all from
long-stable, non-experimental R surfaces unlikely to have changed between
that commit and the local install's version, but the canonical PASS/FAIL
verdict is whatever the frozen-library run on Totoro produces — this local
dry run is corroborating evidence, not a substitute for it.

## Running this batch

```sh
# On Totoro / wherever the maintainer's frozen gllvmTMB library lives
# (suite-run-01 env):
Rscript --vanilla tools/core070_wave7_conversion_batch.R \
  <frozen-library-path> .unlazy/core070-aghq/wave7-conversion-01

python3 tools/core070_verify_wave7_conversion_batch.py --self-test \
  .unlazy/core070-aghq/wave7-conversion-01
```

## Files

- `docs/dev-log/core070/wave7-conversion-batch-contract.json` — frozen
  contract: 6 cases (7 source rows), 38 deferred, 1 rejection case, 3
  negative controls.
- `tools/core070_wave7_conversion_batch.R` — R driver (frozen-library
  convention, mirrors `tools/core070_wave6_conversion_batch.R`).
- `tools/core070_wave7_conversion_batch.jl` — Julia child (fits
  `gaussian_small` natively, no RCall).
- `tools/core070_verify_wave7_conversion_batch.py` — verifier
  (`verify_contract` / `verify_state` / `--self-test`, 9 mutation
  negatives).
- `docs/dev-log/core070/wave7-conversion-notes.md` — this file.

## Dry-run case → branch mapping (Python verifier, `check_state`)

| case_id | kind | verifier branch exercised |
|---|---|---|
| `CORE070-WAVE7-CHECK-AUTO-RESIDUAL` | verdict | `jc.get("r_verdict")`/`jc.get("julia_verdict")` non-None check |
| `CORE070-WAVE7-SANITY-MULTI` | verdict | same |
| `CORE070-WAVE7-COMPARE-LOADINGS-SELF-CONSISTENCY` | own_consistency | `r_frobenius`/`julia_frobenius` `<= tolerance` checks |
| `CORE070-WAVE7-FITTED-MULTI` | point | `max_abs_diff <= tolerance` |
| `CORE070-WAVE7-PREDICT-MULTI` | point | `max_abs_diff <= tolerance` |
| `CORE070-WAVE7-RESIDUALS-MULTI` | point | `max_abs_diff <= tolerance` |
| `CORE070-WAVE7-REJ-CHECK-AUTO-RESIDUAL-NOT-A-FIT` | rejection | `r_raised is True and julia_raised is False` |
