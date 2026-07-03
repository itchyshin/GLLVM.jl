# After Task: R + Julia v1.0 Contract Phase 0/1

## Goal

Start the R + Julia v1.0 capability-contract arc by recording the current
paired-repo truth, bridge asymmetries, source guards, and first matrix gates.

## Implemented

Added a dated v1.0 contract orientation packet and capability matrix under
`docs/dev-log/v1-contract/`. The packet separates R-side bridge truth from the
local Julia branch truth, records source-specific `lv = ~ env` as fail-loud,
keeps the all-six phylo non-Gaussian S2 runners as plumbing only, and names the
next drift/gate checks before any API, bridge, or compute widening. A separate
bridge-drift gate note records the expected R-vs-Julia asymmetries that must be
either reconciled or kept behind named gates.

## Mathematical Contract

N/A - no likelihood, estimator, optimizer, covariance parameterization, or
simulation design changed. This is a governance and evidence-contract slice.

## Files Changed

- `docs/dev-log/v1-contract/2026-07-03-r-julia-v1-contract-orientation.md`
  - New orientation and gate packet.
- `docs/dev-log/v1-contract/r-julia-v1-capability-matrix.md`
  - New v1.0 matrix covering bridge, inference, formula/LV, structural
    dependence, and family rows.
- `docs/dev-log/v1-contract/2026-07-03-bridge-drift-gates.md`
  - New expected-drift note comparing R-side and local Julia bridge capability
    surfaces.
- `docs/dev-log/check-log.md`
  - Added this phase log entry.
- `docs/dev-log/after-task/2026-07-03-r-julia-v1-contract-phase0.md`
  - This after-task report.

## Tests Added

None. This slice adds no code path. The next implementation slice should add
or tighten drift tests comparing R `gllvm_julia_capabilities()` and Julia
`GLLVM.bridge_capabilities()`.

## Benchmark Numbers

N/A - no hot-path change.

## R-Parity Verdict

Parity: N/A - no fitter, likelihood, bridge runtime, or CI calculation changed.
The packet explicitly records that parity remains incomplete for several rows.

## JET / Allocs / Aqua Verdicts

- JET: not run - no Julia code changed.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata or exports changed.

## Checks Run

```sh
git status --short
git branch --show-current
git rev-parse --short HEAD
```

Result: current `GLLVM.jl` branch was
`claude/jl-bridge-capabilities-20260619` at `b093dc16`, with pre-existing
`AGENTS.md` and `CLAUDE.md` edits. This slice did not touch those files.

```sh
Rscript -e 'parse("R/julia-bridge.R"); source("R/julia-bridge.R"); caps <- gllvm_julia_capabilities(); print(caps[, c("family", "fit_no_x", "fixed_effect_X", "missing_response", "ci_no_x_wald", "ci_no_x_profile", "ci_no_x_bootstrap", "status")], row.names=FALSE); gates <- gllvm_julia_gate_registry(); cat("gates=", nrow(gates), "\n")'
```

Result: parse/source succeeded in the `gllvmTMB` checkout; R-side capability
ledger printed 10 rows including `mixed-family vector`, and the gate registry
reported 20 gates. The command also printed the parsed expression because the
initial `parse()` result was not wrapped in `invisible()`; this was noisy but
not a failure.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `bridge_capabilities honest local surface`: 60/60 pass in 13.1s.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_fit.jl
```

Result: `bridge_fit minimal no-X contract`: 175/175 pass in 21.8s.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM; cap=GLLVM.bridge_capabilities(); println(join(propertynames(cap), ",")); for i in eachindex(cap.family); println(join((cap.family[i], cap.fit_no_x[i], cap.fixed_effect_X[i], cap.missing_response[i], cap.ci_no_x_wald[i], cap.ci_no_x_profile[i], cap.ci_no_x_bootstrap[i], cap.status[i]), "\t")); end'
```

Result: local Julia capability surface printed seven rows:
`gaussian`, `poisson`, `binomial`, `negbinomial`, `beta`, `gamma`,
`ordinal`. All rows have `fit_no_x = true`, `fixed_effect_X = false`,
`missing_response = false`, `ci_no_x_wald = true`,
`ci_no_x_profile = false`; `ci_no_x_bootstrap = true` only for Gaussian.

```sh
Rscript -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

Result: 380 pass / 14 skipped / 0 failed. Skips were the expected live
`GLLVM.jl` path checks.

```sh
Rscript -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-canonical-keywords.R")'
```

Result: 86 pass / 3 skipped / 0 failed. Skips were INLA-dependent checks.

```sh
git diff --check
```

Result: clean.

## Consistency Audit

Patterns used during orientation:

```sh
rg -n "bridge_capabilities|function bridge_fit|ci_no_x_profile|mixed-family|fixed_effect_X|missing_response|profile" src/bridge.jl test/test_bridge_capabilities.jl test/test_bridge_fit.jl docs/dev-log/capability-bridge-matrix.md docs/src/index.md docs/src/roadmap.md
rg -n "gllvm_julia_capabilities|gllvm_julia_gate_registry|GJL-GATE|mixed-family|source-specific|lv\s*=\s*~|ci_no_x_profile|fixed_effect_X|missing_response|profile" R/julia-bridge.R tests/testthat/test-julia-bridge.R tests/testthat/test-canonical-keywords.R docs/design/61-capability-status.md docs/dev-log/dashboard/status.json
```

Result: expected hits only. The scans showed the core truth used by this
packet: local Julia bridge rejects `X`, masks, mixed-family vectors, and
profile CI transport; R-side `gllvmTMB` has a broader partial ledger with named
`GJL-GATE-*` guards; source-specific structural `lv = ~ env` is tested as
fail-loud in `test-canonical-keywords.R`.

```sh
rg -n "partial support|ready to expose|source-specific.*support|mixed-family CI support|active compute|AI-REML|non-Gaussian REML" docs/dev-log/v1-contract docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-03-r-julia-v1-contract-phase0.md
```

Result: expected boundary hits only. New v1.0 packet text blocks
source-specific support, says no active compute, and keeps REML/AI-REML
language restricted to guard wording.

## GitHub Issue Maintenance

No issue action. This phase is a local contract packet, not a public issue or
PR update.

## What Did Not Go Smoothly

The paired `gllvmTMB` checkout is heavily dirty and unsuitable as a clean code
worktree for this arc. The first R bridge test invocation failed because
`testthat::test_file()` was run without `pkgload::load_all()`; rerunning with
the package loaded passed. The first R capability command was noisy because
`parse()` printed the full expression. Bare `julia` was not on `PATH`; the
explicit `/Users/z3437171/.juliaup/bin/julia` path works.

## Team Learning

The v1.0 arc needs a drift-report step before code changes. Otherwise the
R-side bridge ledger and the local Julia branch can both be internally honest
while still disagreeing.

## Remaining Risks

- The matrix is a dated starting point, not yet the canonical replacement for
  `docs/dev-log/capability-bridge-matrix.md`.
- No Mission Control refresh has happened yet because this packet does not
  change operating truth.
- The drift-gate note is not yet backed by an automated R-vs-Julia drift test.

## Known Limitations

This phase does not widen bridge support, expose source-specific `lv`, start
`unique=` Julia parity, alter package APIs, run Totoro/DRAC compute, or reopen
any phylo Model A public exposure route.

## Next Command

```sh
Rscript -e 'pkgload::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the v1.0 contract packet is a useful first
truth-lock, but live Julia capability output and focused tests remain next.
