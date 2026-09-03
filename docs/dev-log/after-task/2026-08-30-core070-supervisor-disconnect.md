# Targeted supervisor observer-disconnect repair

## 1. Goal
Keep required post-fit checks running when the SSH output observer disconnects.

## 2. Implemented
Persist local events and progress before notifications. Mirror notifications through unbuffered writes; record BrokenPipeError as an observer warning and stop mirroring. Child failures still fail. Other terminal notification errors now retain a failed receipt.

## 3a. Decisions and Rejected Alternatives
No rerun or rewriting of the old failed batch. Do not ignore arbitrary I/O errors or infer success from an internal marker. No signal-handling or daemonization expansion.

## 4. Files Touched
Targeted supervisor, fault-injection tests, scoped evidence, check-log and LOOP checkpoint.

## 5. Checks Run
Real closed-pipe tests failed twice on original source; a later terminal-I/O regression failed once on the intermediate candidate. Final local24 process/evidence tests PASS15.94s. Totoro final6 tests and supervisor self-test PASS, with remote source hashes verified. No fits or compilation.

## 6. Tests of the Tests
Real child exits0 and7 remain distinct after disconnect. Terminal disconnect recorded; unrelated startup/terminal I/O faults fail. Existing malformed-plan, timeout, missing-executable, stale-pin, process-exit and artifact-tampering controls remain passing.

## 7a. Issue Ledger
Supervisor BrokenPipeError path repaired at tested scope. Duplicated fixture assertion counts remain next. Historical batch stays failed. Current candidate model qualification remains unpaid.

## 8. Consistency Audit
Observer warnings cannot hide child failures; receipts and local event logs survive tested pipe loss. Early and final notifications both covered. No numerical tolerance or reference changes.

## 9. What Did Not Go Smoothly
Neighbour test found final non-pipe I/O errors could prevent writing a receipt; fixed after demonstrating failure. The first Totoro pass is historical to the intermediate revision; final revision was uploaded into a new directory and rechecked.

## 10. Known Residuals
No guarantee against process termination, SIGHUP, host failure or disk exhaustion. No independent review or full package/numerical parity. Remote fixtures were not rerun.

## 11. Team Learning
Observability must not control scientific execution. Keep authoritative progress on disk before optional terminal output, and preserve failure semantics separately from observer warnings.

## 12. Cross-Product Coverage
This does NOT cover Core/AGHQ completion, assertion-count repair, fitted health, documentation rendering, performance or release. Rose NOT RUN; M1 PARTIAL. No new child, push, merge, foreign edit or cleanup.
