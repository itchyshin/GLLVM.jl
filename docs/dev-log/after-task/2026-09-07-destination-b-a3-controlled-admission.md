# After Task: Destination B A3 Controlled Admission and Readers

## Goal

Make the deliberately closed phylogenetic-precision candidate impossible to
reach through the ordinary Julia formula route, then retain auditable evidence
for its private controlled reader/admission checks.

## Implemented

The authorized R bridge now rejects the ordinary
`gllvmTMB(..., engine = "julia")` phylogenetic-precision formula route before
data packing or Julia startup.  Only an explicit, per-process private candidate
option used by the evidence harness can continue.  The bridge preserves
canonical Julia interval identities while exposing formula-column labels through
the existing R readers.  Three controlled evidence receipts, two independent
no-fit reader receipts, and two deliberately corrupted-runtime-digest controls
are retained.  A fresh independent reviewer found no remaining A3 blocker.

## Mathematical Contract

This slice changes no likelihood, covariance parameterisation, optimizer,
interval calculation, or R/C++ engine.  Its contract is a routing invariant:
an ordinary precision formula request stops with
`GJL-GATE-PRECISION-ADMISSION` before R long-data packing or Julia startup.  A
controlled evidence call may cross that gate only after the rejection has been
observed and only with an explicit process-local option.  Julia's canonical
`beta[i]` interval targets remain the validation identities; R maps them to
`beta[<model.matrix column>]` only after validation for reader display.

## Files Changed

- `gllvmTMB/R/julia-bridge.R` — early admission guard and formula-label mapping.
- `gllvmTMB/tests/testthat/test-julia-bridge-destination-b.R` and
  `gllvmTMB/tests/testthat/test-julia-bridge.R` — controlled gate and reader
  regression coverage.
- `gllvmTMB/docs/dev-log/decisions/destination-b-bridge.md` — bounded
  provenance/admission decision record.
- `GLLVM.jl/tools/destination_b/precision_public_dispatch_pilot.R` —
  controlled formula evidence and actual Julia-executable digest binding.
- `GLLVM.jl/tools/destination_b/test_controlled_precision_public_readers.R` and
  `GLLVM.jl/tools/destination_b/test_installed_precision_readers.R` — no-fit
  reader/digest verification.
- `GLLVM.jl/docs/dev-log/core070/destination-b-adapter/` — retained dispatch,
  readback, and negative-control receipts.
- `GLLVM.jl/docs/dev-log/check-log.md`, recovery checkpoint, and ignored Unlazy
  gate ledger — corrected A3 status and explicit non-admission boundary.

## Tests Added

The regression suite covers the early default gate, formula-labelled readers,
and mismatched/corrupted runtime provenance.  The two altered-digest receipts
are Tests-of-the-Tests controls: they fail at the exact digest assertion rather
than allowing an altered executable to pass.  The controlled tree, pedigree,
and dense cases exercise the neighbouring supported reader surface without
changing the frozen R likelihood.

## Benchmark Numbers

N/A — no Julia hot-path change.

## R-Parity Verdict

Parity: N/A — no R likelihood, Gaussian marginal objective, initialization, or
interval implementation changed.  The retained controlled calls check candidate
object identity/readers, not fitted frozen-R parity.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no Julia source change.
- Allocs: N/A — no Julia hot-path change.
- Aqua: N/A — no dependency/export/project change.

## Checks Run

```sh
OPENBLAS_NUM_THREADS=1 R_LIBS_USER=/private/tmp/destination-b-r070-build-l9Y1ri/library:/Users/z3437171/Library/R/arm64/4.6/library \
  /usr/local/bin/Rscript --vanilla -e 'devtools::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-bridge-destination-b.R", reporter="silent", stop_on_failure=TRUE)'
```

Exit 0: 132 successful expectations, 0 failures/errors, 1 intentional opt-in
Julia skip.

```sh
OPENBLAS_NUM_THREADS=1 R_LIBS_USER=/private/tmp/destination-b-r070-build-l9Y1ri/library:/Users/z3437171/Library/R/arm64/4.6/library \
  /usr/local/bin/Rscript --vanilla -e 'devtools::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R", reporter="silent", stop_on_failure=TRUE)'
```

Exit 0: 563 successful expectations, 0 failures/errors, 19 configured live
Julia skips because no live GLLVM.jl path was supplied, and 2 pre-existing
deprecation warnings for legacy covariance accessors.

```sh
Rscript --vanilla -e '<read five authoritative A3 JSON receipts and require closed/unqualified default-gate metadata>'
```

Exit 0: `A3_RECEIPT_STATUS_PASS`.  The authoritative controlled receipts bind
the actual in-process Julia executable digest
`fd739b38b3a1ac367a5dff676834db5ff873e75e4e8220c8793e41be1b4ead30` across
tree, pedigree, and dense cases.  Both intentionally altered-digest receipts
fail at the required equality assertion.

## Consistency Audit

The correction searched the checkpoint and check log for `closed public`,
`public phylogenetic`, `formula triad`, and `A3`; the stale “closed public”
heading was replaced with the precise controlled-candidate boundary.  The
bridge decision record explicitly distinguishes a private evidence option from
a public interface.  No README, public tutorial, or release wording was changed
because this route remains closed.

## GitHub Issue Maintenance

No issue action: FRK remains parked at gllvmTMB#1275 and A3 is not a public
capability claim.

## What Did Not Go Smoothly

Earlier receipts described an actual formula call as “public” even though its
metadata said closed.  Independent review correctly found that metadata did not
block the route.  The repair moved the gate ahead of packing/startup, added
runtime-digest negative controls, and corrected the durable wording.

## Team Learning

For a closed bridge candidate, result metadata is evidence, never enforcement:
test the ordinary public dispatch directly and bind its runtime provenance.

## Remaining Risks

- A3 is tested only; all receipts are unqualified and admission remains closed.
- A4/S4 independent acceptance, frozen-R fitted parity, recovery, coverage,
  broad interval feasibility, and full programme regressions remain open.
- The private candidate option must not be documented as a user-facing route.

## Known Limitations

This neither establishes gllvmTMB 0.7.0/0.7.1 parity nor admits tree,
pedigree, or dense-`vcv` phylogenetic fitting through the public Julia engine.
It does not alter FRK, the frozen R/C++ engine, or Destination B's broader
qualification status.

## Next Command

none — the bounded A3 repair is checked; resume the parent Destination B
programme at A4/S4 without enabling the formula gate.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the bounded A3 gate/reader evidence is sound;
all S4 and programme-level qualification gates remain explicitly open.
