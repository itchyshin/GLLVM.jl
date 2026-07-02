# After Task: Post-LV Capability Cost-Control Boundary

## Goal

Move to the next post-LV goal by cleaning remaining local hygiene and recording
the first bounded capability boundary without reopening source-specific `lv` or
large compute.

## Implemented

The redundant empty dev-log `.gitkeep` placeholders were removed in local commit
`bd8fad8`. I then audited the expensive family-CI and row-effect cost paths and
recorded the next implementation boundary: generic non-Gaussian family bootstrap
refit-control would be useful, but adding `bootstrap_iterations` to
`confint(fit, Y; method = :bootstrap)` is public API widening and needs a
separate maintainer-approved slice.

## Mathematical Contract

No likelihood, estimator, interval formula, or parameterization changed. The
existing contract remains parametric bootstrap from the fitted family model,
followed by one refit per bootstrap replicate and percentile intervals on the
selected working-scale parameters.

## Files Changed

- `docs/dev-log/decisions/2026-07-02-post-lv-capability-cost-control-boundary.md`
- `docs/dev-log/after-task/2026-07-02-post-lv-capability-cost-control-boundary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/.gitkeep` (deleted in `bd8fad8`)
- `docs/dev-log/decisions/.gitkeep` (deleted in `bd8fad8`)

## Tests Added

None. This was a documentation and boundary-lock slice after the prior test-gate
budgeting commits.

Tests-of-tests clause: N/A for this slice. The referenced gates were already
covered by the bounded ZIB smoke, row-effect missing-response equality check,
core suite, and full package suite.

## Benchmark Numbers

N/A - no hot-path implementation changed. The decision note records cost
evidence from the prior bounded ZIB and row-effect gates.

## R-Parity Verdict

Parity: N/A - no R bridge, Gaussian likelihood, fitter, or CI implementation
changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - no source change.
- Allocs: not run - no hot-path source change.
- Aqua: not run separately - the preceding full package suite already passed
  with Aqua and JET in the package test battery.

## Checks Run

```sh
git status --short --untracked-files=all
# clean

rg -n "function confint\\(fit::_CIFit|function _family_bootstrap|function _family_ci\\(fit::ZIBFit|bootstrap_iterations::Union|_lv_boot_kwargs|fit_zib_gllvm\\(" src/confint_family.jl src/families/twopart.jl test/test_confint_family.jl
# confirmed generic family confint lacks bootstrap_iterations while LV-effect
# helpers have it; ZIB family bootstrap refits call fit_zib_gllvm with defaults.

rg -n "ready to scale|partial support|source-specific.*covered|source-specific.*ready|active compute|phylo_latent\\(.*lv|spatial_latent\\(.*lv" docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md docs/dev-log/after-task/2026-07-02-full-pkgtest-after-lv-gates.md docs/dev-log/after-task/2026-07-02-zib-family-ci-smoke-budget.md docs/dev-log/after-task/2026-07-02-missing-response-extra-gate-budget.md
# only guard-language hits in the LV closeout note; no support-promotion hit.
```

## Consistency Audit

The decision note keeps the claim boundary consistent with the final LV
closeout: source-specific `lv` remains parked, the old population-`B_lv`
weak-cell route remains retired, and cost-control work is framed as a future
capability slice rather than a coverage claim.

## GitHub Issue Maintenance

No issue action. This is a local handover/decision boundary in the parked
handover worktree, and the hard rule remains no push or PR without explicit
maintainer authorization.

## What Did Not Go Smoothly

The tempting implementation path is to copy the LV-specific
`bootstrap_iterations` keyword into generic family `confint`. That would solve a
real runtime problem, but it changes the public keyword surface. I left it as a
separate authorized slice instead of hiding an API change inside cleanup.

## Team Learning

Rose/Fisher: test-budget fixes and interval-calibration evidence must stay
separate; cost-control knobs do not imply better coverage.

## Remaining Risks

- Generic non-Gaussian family bootstrap refits still use fitter defaults.
- ZIB bootstrap remains expensive and should remain a smoke gate unless a
  refit-control slice is approved.
- The next API slice needs docs and default-unchanged tests, not only source
  wiring.

## Known Limitations

This task does not implement generic family bootstrap refit-control, expose
source-specific `lv`, reopen PR #127, or run any new Totoro/DRAC compute.

## Next Command

```sh
git diff --check -- docs/dev-log/decisions/2026-07-02-post-lv-capability-cost-control-boundary.md docs/dev-log/after-task/2026-07-02-post-lv-capability-cost-control-boundary.md docs/dev-log/check-log.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the next capability boundary is explicit, but
generic family bootstrap refit-control remains a future maintainer-approved API
slice.
