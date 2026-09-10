# After Task: B1 balanced complete-crossed pre-run design

## Goal

Fix an immutable complete-crossed source-alignment construction without fitting.

## Implemented

The new dependency-free fixture/test lock the full crossing, DGP, response
digest, and static tensor screen. The decision and separate budget define the
future single-control frozen-R gate and fail-closed stop rule.

Repair: long rows now use exact `cluster_id` and `cluster2_id` formula columns;
the test proves wide grouping tuples are unique, long grouping tuples have the
expected two-trait multiplicity, and trait-qualified long tuples are unique.
It also locks a no-fit frozen-R source/DLL/marker/reference-runner preflight
mapping using values retrieved from the retained stationary receipt.

## Checks Run

- Before construction, the focused existence gate was red: `RED: fixture construction missing`.
- Repair TDD red: 27 passed, 1 failed, and 4 errors before formula-column,
  tuple, and provenance construction.
- `/Users/z3437171/.juliaup/bin/julia --project=. test/test_destination_b_b1_balanced_complete_crossed_design.jl` passed **43/43** after repair.
- No frozen-R or Julia fit/optimizer was run.

## Remaining Risks

- Static rank/eigenvalue evidence is not convergence, recovery, R-parity, or B1 qualification.
- The future frozen-R run is unapproved and unrun.
- The preflight helper is static-tested only; it was not executed against a frozen source/library.

## Authorized Execution Outcome

The external frozen-R provenance preflight subsequently passed. The exact input
CSV, exporter failure/pass logs, static runner check, preflight log, and both
separate control raw logs are retained under
`docs/dev-log/core070/destination-b-b1/`. Each requested JSON target remains
absent because the runner stopped at its no-clobber guard before package load
or fit. No optimizer ran; no retry is authorized.

## Rose Verdict

Rose verdict: FAIL — no B1 control result exists; the runner guard must be
repaired only under a fresh authorization and protocol.

## Guard Repair

The no-clobber guard is now factored into a pure R helper and tested on an
absent path, existing regular file, and symlink. The focused test and runner
parse pass, while the two failed pre-fit logs and absent JSON targets remain
checked. No fit was launched during repair.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the guard repair is mechanically ready for
independent review; no model result or B1 qualification exists.

## Rose Verdict

Rose verdict: PASS WITH NOTES — construction-only scope verified; inferential and paired claims withheld.

## One Authorized Control — Negative Receipt

The repaired guard then underwent independent review and a fresh authorization
allowed exactly one frozen-R control. Its no-fit provenance preflight passed.
The control receipt, hard-linked no-clobber marker, and separate raw preflight
and control logs were retained under `docs/dev-log/core070/destination-b-b1/`.
The no-fit receipt-I/O test verifies the marker/receipt hash identity, pinned
source/version/runner/specification, preflight raw log, and the recorded
nonqualification without loading `gllvmTMB`.

Final no-fit checks passed: `Rscript --vanilla
test/test_destination_b_b1_balanced_complete_crossed_control_receipt.R`,
`Rscript --vanilla test/test_destination_b_b1_balanced_complete_crossed_control_io.R`,
and `/Users/z3437171/.juliaup/bin/julia --startup-file=no --history-file=no
--project=. test/test_destination_b_b1_balanced_complete_crossed_design.jl`
(43/43), plus `git diff --check`.

The control completed in `0.94606304168701172` seconds but failed the immutable
gate: `convergence = 1` (`singular convergence (7)`) and
`max(abs(gr)) = 0.00092870391764413951 > 1e-6`. The stop rule was followed:
no retry, reseed, restart, start/mapping/optimizer/data/tolerance change, or
Julia paired fit. This is a retained negative single-control receipt, not a
paired result or B1 qualification.

## Rose Verdict

Rose verdict: FAIL for B1 qualification; PASS for the one-control execution
protocol and fail-closed stop boundary.
