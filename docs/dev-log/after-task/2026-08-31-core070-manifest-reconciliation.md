# Current manifest integrity checkpoint

## 1. Goal
Resume the approved programme after confirming compute connectivity. Repair the
stale current-census verifier without promoting incomplete parity evidence.

## 2. Implemented
The draft verifier now reads the pinned source inventory, validates mapping
integrity, runs fresh checks, and optionally writes a new non-overwriting receipt.
Historical manifest-coverage-evidence.json remains byte-for-byte unchanged.

## 3a. Decisions and Rejected Alternatives
Do not merely change 752 to 769 and refresh historical hashes: the older receipt
records an earlier state. Census completeness and executable case coverage are
separate. Existing frozen-manifest validation remains authoritative and unchanged.
Direct passwordless Totoro access is authorized without Duo; existing DRAC sockets
are reused with fresh-login fallback disabled. No compute allocation is implied.

## 4. Files Touched
Current verifier, six draft-integrity regression tests, fresh reconciliation
receipt, this report, check-log and LOOP checkpoint. No engine, R or foreign lane
files changed. Runtime baseline and gate ledger live under manifest-reconcile-01.

## 5. Checks Run
Original verifier fails at its stale 752 count. New regression tests fail before
implementation; repaired verifier passes 30 unit tests plus evidence self-test
and rejects a label-only freeze. Current census: 769 facts, including 447 core,
86 adapters, 182 rejected and 54 excluded; 715 nonexcluded rows remain unmapped.
Totoro and eight DRAC sessions returned hostnames with exit 0. No fits launched.

## 6. Tests of the Tests
New controls reject missing/duplicate rows, reference and classification drift,
invented case IDs, blank rationale, false frozen labels, nonzero child exits and
missing test-count output. Existing scope-review/receipt/collection negative
controls remain exercised. Inputs are hashed before checks and compared afterward.

## 7a. Issue Ledger
Current-census repair passes. Full contract closure remains unpaid: zero master
executable bindings, despite separately retained model evidence. Gaussian native
and formula runner integration is next; bridge and independent scope review remain.

## 8. Consistency Audit
The 17 extra masks/known-covariance facts were already in the indexed inventory
and its tests; this patch does not invent requirements. Historical receipts are
not rewritten into current evidence. Neither draft integrity nor a count is a
scientific parity pass. Full manifest status stays DRAFT_INCOMPLETE_NOT_FROZEN.

## 9. What Did Not Go Smoothly
The first lane-preflight invocation used a repo name instead of an absolute path;
it was rerun correctly before edits. The initial checkpoint filename was absent;
the actual LOOP/core070-checkpoint.md was used. Baseline and regression failures
are retained, not discarded. No authentication failure occurred.

## 10. Known Residuals
Two full-suite runs and the specific external numerical-review payload await
approval. The programme remains ACTIVE/M1 PARTIAL. Recovery, coverage, performance,
remaining capabilities and final documentation validation are not complete.

## 11. Team Learning
Ada parent performed this bounded repair; no new child or independent review was
launched and no model/effort/hours receipt is invented. Rose verdict remains
NOT REQUESTED for this interim checkpoint. A durable historical receipt should
not also be a mutable gate's authoritative current-state input.

## 12. Cross-Product Coverage
This repair does NOT cover new fitted models, native/formula/bridge integration,
full package suites, independent scope approval or a frozen complete contract.
No push, merge, release, destructive cleanup or new DRAC allocation occurred.
