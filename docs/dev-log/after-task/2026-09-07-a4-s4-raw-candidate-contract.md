# After Task: A4/S4 raw candidate receipt and frozen-R validation contract

**Date:** 2026-09-07
**Owner:** Codex/Ada
**Branch:** `codex/destination-b-20260907`
**Worktree:** `/private/tmp/destination-b-20260907-main`
**Frozen R reference:** gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`

## Goal

Retain and independently audit the closed three-row A4/S4 private bridge
attempt, then add a fail-closed validation contract that prevents an arbitrary
R object or coordinate vector from being presented as paired evidence.

## Implemented

`raw-bridge-03` records returned private Gaussian bridge candidates for the
non-unit ultrametric tree, ancestor-augmented pedigree, and once-ridged dense
VCV rows.  It is intentionally a raw transport receipt, not a paired result:
all rows remain `qualified = false` and public formula admission is closed.
The preceding sandbox-lock and JSON-decoding failures are retained alongside it.

`tools/destination_b/a4_s4_frozen_r_evaluator.R` now validates only the exact
future frozen-R request.  It binds the fixed R coordinate order, frozen source
and DLL identities, fixture/reference/precision/response hashes, repeated
maps, inherited scales, and dense one-ridge rule.  It rejects every live
evaluation path: a real marginal-objective comparison must be implemented in a
single integrated frozen-runner process where the actual TMB object and its
provenance can be bound together.

The homepage continues to show the new GLLVM.jl identity mark, and its
landing-page text now makes the Gaussian teaching-route boundary clear without
misdescribing the entire package as Gaussian-only.

## Mathematical Contract

The future paired point uses the frozen R order

`theta_R = [b_fix[1:3], log_sigma_eps, theta_rr_phy[1:3]]`.

The corresponding Julia order is

`[beta[1:3], pack_lambda(Lambda)[1:3], log_sd_residual_shared]`.

For a future matched point, the only eligible R target is the exact
random-effect-integrated Gaussian marginal objective already built by the
frozen package, `fit$tmb_obj$fn(theta_R)`.  Rebuilding a
`MakeADFun(random = NULL)` objective would instead compare the joint score and
is prohibited.  This slice validates the transport contract only; it evaluates
neither objective and therefore makes no parity claim.

## Files Changed

`tools/`

- `tools/destination_b/a4_s4_frozen_r_evaluator.R` — validation-only private
  request contract; all live evaluation is rejected.

`test/`

- `test/test_destination_b_a4_s4_frozen_r_evaluator.R` — all three requests,
  malformed coordinates, provenance/map/scale/ridge mutations, and live-path
  rejection.

`docs/`

- `docs/dev-log/core070/destination-b-a4-s4/raw-bridge-{01,02,03}.json` — two
  retained failed attempts and the raw unqualified candidate receipt.
- `docs/dev-log/core070/destination-b-a4-s4/raw-bridge-03.json.rds.*` — raw
  bridge return sidecars audited against the JSON record.
- `docs/dev-log/core070/destination-b-a4-s4/README.md` — distinguishes raw
  returns from a successful paired-evidence receipt.
- `docs/src/index.md` — Gaussian landing-route boundary beside the logo.
- `docs/dev-log/check-log.md` — this check entry.
- `docs/dev-log/after-task/2026-09-07-a4-s4-raw-candidate-contract.md` — this
  report.

## Tests Added

`test/test_destination_b_a4_s4_frozen_r_evaluator.R` is one direct R contract
script.  It exercises all three prescribed rows plus malformed-coordinate,
provenance, map, scale, ridge, admission, qualification, and live-evaluation
failure paths.  It is a tests-of-the-tests boundary/malformed-input check; no
R fit is invoked.

## Benchmark Numbers

N/A — no hot-path or likelihood code changed.  The raw tree first-call elapsed
time is not a benchmark.

## R-Parity Verdict

Parity: N/A — the validation-only contract does not evaluate an R or Julia
likelihood.  `raw-bridge-03` proves candidate transport only, not matched-point
or independently optimized parity.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia source path changed.
- Allocs: N/A — no inner-loop path changed.
- Aqua: not run — no `Project.toml` change; the full package test environment
  remains a separate approval-gated check.

## Checks Run

```text
Rscript --vanilla test/test_destination_b_a4_s4_frozen_r_evaluator.R
# A4_S4_FROZEN_R_EVALUATOR_OK
# 1 direct R contract script, exit 0

julia --project=. test/test_destination_b_a4_s4_receipts.jl
# A4/S4 paired matrix receipt schema | 60 / 60, exit 0

R/jsonlite/readRDS audit of raw-bridge-03
# 87 / 87 comparisons; JuliaCall verifier:
# schema_valid_raw_candidate_unqualified, qualified = false

julia --project=. test/runtests.jl
# 655 pass / 0 fail / 1 error / 3 expected broken in 1m35.9s
# stopped at missing test-only StableRNGs in the root project environment

julia --project=docs docs/make.jl --local
# exit 1 before rendering: Documenter is not installed in this local docs env
```

## Consistency Audit

The following targeted scans were run:

```text
rg -n "Generalised Linear|non-Gaussian|mixture|VA/ELBO|SPDE|phylogenetic-GLM" docs/src/index.md
rg -n "successful fit receipt|successful paired-evidence receipt|raw bridge|candidate-only|qualified = false" docs/dev-log/core070/destination-b-a4-s4
rg -n "This landing page introduces|This landing page makes a Gaussian-only promise|true parity|speed results do not generalise" docs/src/index.md
```

Broader-method terms occur only in the landing-page limitation, not as its
current support claim.  The A4/S4 directory keeps raw transport and paired
evidence distinct.

## GitHub Issue Maintenance

No issue action.  FRK remains parked at gllvmTMB#1275; no public bridge or
formula-route issue was opened or advanced.

## What Did Not Go Smoothly

1. The first raw candidate attempt could not create Julia's usage-log lock in
   the sandbox; the second exposed JSON row decoding.  Both are retained.
2. The first evaluator draft incorrectly allowed arbitrary live fit objects and
   alternate coordinates.  Independent review found the P0 defects.  The
   repaired version is validation-only rather than speculative evidence code.
3. The advertised direct core command does not stack/install test-only
   `StableRNGs`; CI's canonical `Pkg.test()` route does.  The docs environment
   also lacks installed `Documenter`.

## Team Learning

For a marginal-objective parity gate, a correct coordinate schema is not enough:
the evaluated TMB object itself must be bound to the frozen model and input
bytes in the same process.

## Remaining Risks

- No live matched-point frozen-R/Julia objective comparison exists.
- No independently optimized Julia own optimum exists; cross-evaluating R's
  optimum would not substitute for it.
- Dense VCV intervals are explicitly unavailable, so dense remains
  unqualified even if later point objectives agree.
- Raw receipt execution/source metadata is runner-recorded and unverified;
  it is not an immutable paired-evidence binding.
- The full canonical `Pkg.test()` and a fresh docs build have not run locally.

## Known Limitations

- This does not admit A4/S4, the public `phylo_rr` formula route, 0.7.1 parity,
  Destination B completion, recovery, coverage, or FRK.
- The frozen-R helper intentionally cannot evaluate an objective yet.
- The current local rendered docs output predates the landing-page wording
  repair; no deployment was made.

## Next Command

After explicit approval for the estimated 55--70 minute suite:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Then start a fresh, integrated frozen-runner slice for a live matched-point
evaluation; do not use the validation-only helper as paired evidence.

## Rose Verdict

Rose verdict: PASS WITH NOTES — raw candidate transport and its fail-closed
validation contract are independently checked and honestly fenced; no live
paired-evidence, full-package test, or fresh docs-build claim is made.
