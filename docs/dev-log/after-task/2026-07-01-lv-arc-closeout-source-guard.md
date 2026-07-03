# After Task: LV Arc Closeout Source Guard

## Goal

Close the current LV arc as operating truth after the paired R-side
source-specific `lv = ~ env` guard made the structural-source boundary
fail-loud.

## Implemented

Updated the compact Phylo Model A evidence-freeze note, Design 73, and the
structural-dependencies note so the current arc reads as closed rather than
merely hardened. The evidence remains frozen for `B_eta_realized`; the old
population-`B_lv` route remains retired/parked for v1; source-specific
structural `lv = ~ env`, mixed-family LV expansion, and non-Gaussian structural
LV all remain outside the current arc.

## Mathematical Contract

No likelihood, fitter, confidence-interval, or simulation code changed in this
worktree. The frozen Phylo Model A target is still the eta-scale
realized/design-conditional `B_eta_realized`; the old population
`B_lv = Lambda * alpha_lv'` route remains negative evidence.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-lv-arc-closeout-source-guard.md`

## Tests Added

None in this Julia worktree. The paired `gllvmTMB` closeout added the focused
parser guard test for source-specific structural `lv = ~ env`.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: N/A - no Julia likelihood, fitter, init, bridge, or CI machinery changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia source changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata, exports, or dependencies changed.

## Checks Run

Paired `gllvmTMB` focused evidence:

```sh
Rscript -e 'parse("R/brms-sugar.R"); cat("parse-ok\n")'
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-canonical-keywords.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-ordinary-latent-random-regression.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
Rscript --vanilla -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-stage37-mixed-family.R")'
```

Focused tallies:

- `test-canonical-keywords.R`: 67 pass, 3 skips.
- `test-ordinary-latent-random-regression.R`: 23 pass, 7 skips.
- `test-julia-bridge.R`: 380 pass, 14 expected Julia-path skips.
- `test-stage37-mixed-family.R`: 6 pass.

## Consistency Audit

Rose scan target: current docs must say the LV arc is closed as truth-lock,
while still blocking source-specific `lv`, PR #127 reopening, mixed-family
`X_lv`/CIs/masks, and non-Gaussian/source-specific inheritance.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked as blocked evidence.

## Remaining Risks

- Gate 3 does not authorize R grammar exposure.
- The source-specific `lv = ~ env` guard is fail-loud evidence, not support.
- Non-Gaussian/source-specific LV still needs a new target, derivation, ADEMP
  gate, and maintainer authorization.

## Rose Verdict

Rose verdict: PASS WITH NOTES - the current LV arc is closed as operating truth,
with future structural and non-Gaussian LV work explicitly moved to separate
gated arcs.
