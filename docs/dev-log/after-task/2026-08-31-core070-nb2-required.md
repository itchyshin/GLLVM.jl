# Required NB2 and truncated-NB2 parity checkpoint

## 1. Goal
Integrate the repaired NB2 health contract into the real required parity runner,
then revalidate the neighbouring truncated-NB2 original case. Preserve full
Core+AGHQ scope: programme ACTIVE, M1 PARTIAL, full manifest DRAFT.

## 2. Implemented
The NB2 fixture now enforces relative logLik tolerance1e-6 instead of1e-3.
Its test-only adapter records both raw gradients, finite-difference stability,
19 free coordinates, packing, objective reconciliation and same-point density.
Both execution inventories pin the adapter. Complete R fit and health-report
hashes are printed into supervisor-hashed stdout. No engine changes this turn.

## 3a. Decisions and Rejected Alternatives
Original seed45/p5/K2/n80 and public Julia/R controls unchanged. No refitting
through BFGS for ordinary NB2: the R default is healthy. Truncated NB2 retains
its separate explicit public continuation policy and failed default receipt.
No artificial equivalence between large, weakly identified size estimates.

## 4. Files Touched
test/parity/nb2_health.jl and test_negbin_parity.jl; parity_helpers.jl and
tools/core070_evidence.py execution inventories; new required verifier and
corruption tests; draft contract, two catalogue rows, evidence summary, math
decision, both changelogs, check-log and programme checkpoint.

## 5. Checks Run
Combined run estimated1–3min, five-minute cap, one Totoro thread; actual child
39.665s. Julia1.12.6, R4.5.3, TMB1.9.21, Rb4d5fee pinned. Actual runparity.jl
selected NATIVE-06-NB2 and NATIVE-12-TRUNCATED-NB2:18+21=39 assertions pass.
Both oracle checks pass; complete run terminal.

- NB2 native gradient9.481e-7, R gradient6.509e-5; abslogLik delta3.413e-6,
  same-point nll delta-3.115e-11. Original400 observations unchanged.
- Truncated NB2 native gradient6.537e-6, selected R gradient2.746e-5;
  abslogLik delta8.673e-8. Default Rcode1 remains explicit.
- Python collection9, execution-counting4, process-evidence5 and manifest6
  tests pass; aggregate selftest passes. Julia parser passes.
- Whole RDS fits read back independently in base R; current source, runtime,
  fixture, case counts and process evidence checked. Unlazy reverify2/2.

## 6. Tests of the Tests
Sixteen numerical-summary corruptions rejected across both policies. Nine
artifact mutations rejected: missing run, omitted NB2 cell/health, altered
health/raw fit/log/plan, nonzero child and stale source. Exact39 count and
two distinct case IDs required. Optional skipped tests cannot pass this gate.
Acceptance command bound before the remote run; artifact mutation check added
after results, without claiming a prior independent review.

## 7a. Issue Ledger
Ordinary NB2 required-runner tolerance and health omissions closed for the
original seeded model. Full source-case mapping, Student R health/density,
covariance/multinomial/AGHQ contracts and recovery remain open.

## 8. Consistency Audit
Both catalogue rows now point to this fresh two-case receipt. Formula and
bridge status remain UNPAID; full catalogue remains a family-smoke catalogue.
FullmanifestDRAFT not promoted. Changelogs corrected from pending integration
to verified two-case scope. Independent Rose and numerical review NOT RUN.

## 9. What Did Not Go Smoothly
First preflight used the repository name where a directory was required;
corrected to the owned absolute worktree. A generated source delimiter had
excess escaping; corrected before parser verification and remote execution.
No failed fit was removed or replaced; the remote batch passed on its first run.

## 10. Known Residuals
Full package checks and Documenter rendering NOT RUN. Broader scientific
recovery, performance and bridge qualification unpaid. NB1 and two-part
probability-conversion neighbours need separate model/derivative checks.
Old helper/fixture/contract-bound evidence is historical after integration.

## 11. Team Learning
Strong diagnostic evidence becomes an enforceable parity requirement only
after integration into the actual runner and fresh replay. Parent execution
only; no new production child or completion panel. No invented agent-hours.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ parity, identified boundary dispersions,
coverage calibration, new benchmarks, rendered documentation or release
readiness. R0.7.1/article/foreign lanes untouched. No push, merge, release,
destructive cleanup, R engine edits or DRAC campaign.
