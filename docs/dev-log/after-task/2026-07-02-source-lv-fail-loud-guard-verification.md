# After Task: Source LV Fail-Loud Guard Verification

## Goal

Verify the specific source-grammar risk raised by Shinichi: `lv = ~ env` must
not look accepted for `spatial_latent()`, `phylo_latent()`, `animal_latent()`,
or `kernel_latent()` and then be silently dropped.

## Implemented

No source behavior changed. This was a cross-repo evidence-only verification.

The R twin currently has a parser guard in `R/brms-sugar.R` that rejects
source-specific `lv` with a message saying silently dropping `lv` is not
allowed. The focused test in `tests/testthat/test-canonical-keywords.R` covers
phylo, spatial, animal, kernel, and legacy alias structural keywords.

## Mathematical Contract

No model contract changed. Ordinary predictor-informed score means remain
separate from source-specific structural dependence. Structural random-slope
syntax remains a different route from predictor-informed `lv` grammar.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-source-lv-fail-loud-guard-verification.md`

## Tests Added

None. Existing R-side guard tests cover the current source-specific `lv`
failure boundary.

## Benchmark Numbers

N/A - parser guard verification only.

## R-Parity Verdict

Parity: guarded. The R parser rejects source-specific `lv = ~ env` before it
can be silently dropped or misread as public support. The GLLVM.jl handover tree
keeps the same public boundary: no source-specific `lv` grammar exposure and no
PR #127 reopening without maintainer authorization.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source change.
- Allocs: not run - no hot-path code change.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
cd "/Users/z3437171/Dropbox/Github Local/gllvmTMB"
git status --short
# heavily dirty from unrelated local work; treated as read-only for this slice

rg -n 'source-specific|lv\s*=|lv =|GJL-GATE|silently|not.*wired|unsupported.*lv|fail-loud|latent.*lv' R/brms-sugar.R tests/testthat/test-canonical-keywords.R tests/testthat/test-ordinary-latent-random-regression.R R/animal-keyword.R R/kernel-keywords.R R/spde-keyword.R R/phylo-signal-ci.R
# found the source-specific lv parser guard and the structural keyword test set

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-canonical-keywords.R")'
# test-canonical-keywords.R | 82 pass, 0 fail, 3 skip
# skips were INLA-not-installed spatial tests, unrelated to lv source guards
```

## Consistency Audit

The guard covers `phylo_scalar`, `phylo_unique`, `phylo_indep`,
`phylo_latent`, `phylo_dep`, legacy `phylo(..., mode = "latent")`, the spatial
counterparts including `spatial_latent`, the animal counterparts, and the
kernel structural keywords. This directly addresses the accepted-but-dropped
failure mode.

## GitHub Issue Maintenance

No issue or PR action taken. gllvmTMB was audited read-only because its local
worktree contains broad unrelated changes.

## What Did Not Go Smoothly

The first repository-wide search produced too much output because gllvmTMB has a
large dirty local history and many design logs. The audit was narrowed to the
parser and focused guard test files.

## Team Learning

Boole/Rose: source-specific `lv` must remain a fail-loud parser boundary, not a
soft warning and not a silently ignored argument.

## Remaining Risks

- The gllvmTMB worktree is not clean, so this verification is focused evidence,
  not a release-ready R-package state claim.
- Public source-specific `lv` support still requires a separate grammar/API
  decision and maintainer authorization.

## Known Limitations

This did not run the full gllvmTMB test suite or R CMD check. It ran the focused
canonical keyword guard test only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_bridge_ci.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - source-specific `lv = ~ env` is verified as a
fail-loud boundary in the R twin, and no source-specific support was promoted.
