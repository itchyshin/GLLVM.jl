# Core070 + AGHQ execution foundation — milestone remains open

## 1. Goal

Start the approved R 0.7.0 Core + AGHQ programme without disturbing existing
Cursor, Claude, R 0.7.1, or article work. This report records the foundation,
not programme completion.

## 2. Implemented

Created `codex/core070-aghq-20260830` from the PR #274 candidate in
`/private/tmp/GLLVM.jl-core070-aghq-20260830`. Persisted the approved contract,
ignored runtime gates, and a reproducible Git census. Dispatched three bounded,
disjoint workers after the Luna census review. Corrected two Julia fields on
Mission Control and verified that the server returned both exact values.

## 3a. Decisions and Rejected Alternatives

The reviewed lane launcher creates a different branch prefix and changes Claude
permission settings. We instead used ordinary `git worktree add` with the
approved Codex branch prefix; no permission settings changed. Foreign dirty
work was neither reset nor stashed. Clean and missing checkouts are protected,
not presumed disposable. R current main is not the frozen R 0.7.0 reference.

Memory receipt: the approved plan's Ask-brain orientation and project routing
informed ownership, compute routing and evidence boundaries. The execution
artifacts use current Git and source evidence, not historical memory as proof.
Golden Set: no memory-regression run in this administrative slice; the applicable
repeated-failure checks were branch-aware census, explicit lane ownership and
served-board readback. No brain memory edits beyond the requested board update.

## 4. Files Touched

- `docs/dev-log/plans/2026-08-30-core070-aghq-execution.md`: approved contract.
- `tools/core070_inventory.py`: read-only inventory tool.
- `.gitignore`: exclude mutable Unlazy records.
- `LOOP/core070-checkpoint.md`: continuation state; inherited goal retained.
- `docs/dev-log/check-log.md`: append current evidence correction without
  removing historical records.
- This report.
- Ignored `.unlazy/core070-aghq/`: inventory, gates, worker briefs/receipts,
  protected lanes, and Mission Control before/expected/served snapshots.
- External, authorized curated file only:
  `Shinichi/Shinichi/Dashboards/mission-control/live/status/gllvmTMB.json`
  in the local-only brain repository (commit `f35161c`).

The three worker-owned implementations are in progress and are not declared
verified or complete by this report.

## 5. Checks Run

A1's approved executable gate reran `python3 tools/core070_inventory.py` with
both canonical repository paths and an explicit output path; exit 0 and
`CORE070_CENSUS_COMPLETE`. Independent Luna low CLI review returned exit 0.
Parent reconciled the article task's true checkout before accepting the review.

Census: Julia 103 registered, 103 functional, 32 dirty and 71 clean. R 210
registered, 42 functional, 122 missing and 46 broken; among functional R
checkouts, 10 dirty and 32 clean. Ref/stash counts: Julia 389/5, R 1431/16.
These are observations at capture time, not permanent expected totals.

Mission Control update verifier: exit 0,
`MC_TARGETED_UPDATE_PASS`; protected JSON values and the R narrative prefix
were equal before and after. Served endpoint
`http://127.0.0.1:8823/p/gllvmTMB/status.json`: HTTP 200, exit 0,
`MC_SERVED_READBACK_PASS`. Exact-file lease released after local commit.

Live PR #274 inspection: OPEN on `7a4ac8de`; CI `33295781600` passed Julia
1.10 Ubuntu and the existing parity job; current-Julia Ubuntu/macOS/Windows
failed. Documenter `33295781601` passed. No new full package suite, recovery,
coverage, benchmark, or documentation build is represented by this report.
JET/Allocs/Aqua: not run in this administrative slice.

## 6. Tests of the Tests

The census verifies each checkout's exact top-level and records broken/missing
paths instead of silently reading a parent repository. Mission Control's
comparison restores the two permitted fields in the candidate object and
requires equality with the entire original object before writing.

Parent review withheld A2 preservation approval after finding that its stash
fixture did not retain a stash, and that broken-checkout Git fallback, failed
bundles and patch-readback needed stronger guards. A3's initial narrow manifest
was also rejected as programme completion evidence. Both repairs are active.

## 7a. Issue Ledger

PR #274 is observed, not merged. No issue was opened, closed, or commented on:
this slice establishes local implementation and evidence ownership. Existing
numerical and parity failures remain unpaid until their targeted gates pass.

## 8. Consistency Audit

Compared live CI with the inherited check-log closure language and the board's
old Julia narrative. Added explicit superseding text while retaining history.
Preserved R 0.7.1, random-slope, MSPL, and article fields in the board object.

## 9. What Did Not Go Smoothly

The launcher was unsuitable for the approved branch and permission boundary.
The Luna scout initially inferred the article lane from historical names;
parent verified the actual active `gllvmTMB_main2` checkout. Initial worker
checkers were too permissive, so no preservation or manifest-complete claim was
accepted. Review uncovered these before claim-bearing runs.

## 10. Known Residuals

Milestone 1 is open. Preservation has not yet passed real archive/readback.
The required manifest is not frozen; the draft must separate R admission from
Julia availability and include the full approved contract. Numerical repairs
and integration checks remain pending. Runtime receipts currently in temporary
storage must be preserved durably. No cleanup authority is inferred.

## 11. Team Learning

Read-only metadata scouting used Luna low through enforced CLI dispatch.
Preservation used Terra medium; contract/runner and numerical diagnosis used
Terra high. These are the executed routing choices, not accumulated agent-hour
measurements. No new Sol production child or max/ultra effort was used.

A manifest that excludes missing implementation can certify the wrong scope.
A preservation test that removes its own stash fixture can miss the very object
it purports to protect. Both require explicit negative controls and review.

## 12. Cross-Product Coverage

This foundation covers the known local worktree registrations and current
curated Julia board correction. It does NOT cover remote storage discovery,
complete preservation, capability parity, public AGHQ, bridge qualification,
performance improvement, recovery/coverage calibration, or final Documenter
acceptance. R 0.7.1 and the article programme remain separate.

Rose verdict: NOT REVIEWED — the required independent milestone panel has not
run. Programme status: IN PROGRESS; no completion claim.
