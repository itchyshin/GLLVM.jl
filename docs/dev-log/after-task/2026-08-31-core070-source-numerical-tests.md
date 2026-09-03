# Gaussian source targeted numerical checkpoint

## 1. Goal
Resume the approved Core070+AGHQ programme after compute restoration. M1 remains
PARTIAL; full manifest DRAFT_NOT_FROZEN. Prior connection check was progress:
it established that all six hosts were reachable and cleared the next gate.

## 2. Implemented
No engine or fixture edits. Executed the prepared baseline and candidate on
Totoro and retained exact process, source, environment and log receipts.
Updated candidate status, check-log, LOOP and Mission Control Julia fragment.

## 3a. Decisions and Rejected Alternatives
Use Totoro for this bounded check, one Julia/BLAS/OMP thread, estimate under
five minutes per run, cap300s. No large DRAC campaign. Missing shared sockets
must not block Totoro without trying its authorized key-auth reconnect.
Brain tools/totoro-setup.md explicitly permits this; COMPUTE-PLAYBOOK's older
ask-to-reopen sentence conflicts. User reiterated the direct connection rule.
No fresh DRAC authentication and no changes to SSH configuration or vault rules.

## 4. Files Touched
Source numerical summary and candidate-status JSON, check-log, LOOP checkpoint,
this report; ignored baseline/candidate receipts and gate verifier. Only the
Julia fragment of the external Mission Control status file was updated.

## 5. Checks Run
Totoro Julia1.12.6 baseline: exit1, intended missing-API assertion,8.3807s,
zero errors. Candidate: exit0,46/46model checks and71/71retained source-input
binding checks,27.1641s. Source/environment/log hashes verified. Source gate
reverification:5met,1unmet(GS-DOCS),0abandoned. Evidence index:
../core070/gaussian-sources-numerical-tests.json. Timing is operational elapsed
time including loading/compilation, not a comparative performance claim.

## 6. Tests of the Tests
Baseline has no source-fit API and fails the availability assertion after
successful package loading; identical tests pass on candidate. Seven receipt
negative controls reject missing cases, stale/missing pins, wrong command,
missing receipt, changed logs and nonzero exits. Independent covariance,
derivative and analytic source-fit controls run. Implementation preceded the
valid baseline red, so this is not retroactive TDD process compliance.

## 7a. Issue Ledger
Source tests pass; full package, Documenter, paired fitted-R comparisons,
recovery/coverage and performance remain unpaid. All original binomial,
Student-t, default-unique, AGHQ, covariance, multinomial, data/postfit/bridge
obligations remain. No full-manifest freeze or milestone completion.

## 8. Consistency Audit
Six binding helpers have runtime construction evidence, not fitted parity.
No tolerances, fixtures, likelihood or API changed this turn. API-load receipt
remains historically loading-only. Candidate summary now links fresh numerical
evidence without rewriting that original receipt. R0.7.1 and article lanes
untouched; no push, merge, release or cleanup.

## 9. What Did Not Go Smoothly
Previous turns incorrectly applied DRAC socket-only restrictions to Totoro.
Brain runbook retrieval and user correction resolve the operational rule.
First gate-check invocation omitted --cwd and therefore resolved relative
scripts under the ledger directory: infrastructure exit2, not numerical failure.
Re-ran inspected commands with explicit repository --cwd; five checks passed.
The old after-task skill also contains a stale prohibition of Pkg.test(); the
current project instruction requires full Pkg.test(), which remains pending.

## 10. Known Residuals
No full package/Aqua/JET/Allocs, fitted-R, recovery or Documenter claim. Prepared
source documentation is still unexecuted. Next: use retained exact R fixtures
and reference build for paired source fitting; preserve failed health cases.
Keep DRAC runs scheduled and seek sized pre-run approval for runs above30min.

## 11. Team Learning
Parent executed and checked receipts; no new agent dispatched. Prior Noether
static review retained, no new completion panel or Rose sign-off. No actual
agent-hours or model receipt invented. Ask-brain MCP search across all projects
and runbook read provided the explicit Totoro reconnect rule. No memory write.

## 12. Cross-Product Coverage
This checkpoint does NOT cover fitted R parity, formula/bridge reachability,
recovery, coverage, full package tests or executed Documenter. Full
R0.7.0Core+AGHQ goal remains active. Source
fitter is not capability-complete until remaining documentation, paired-model
and package evidence and independent programme review are present.

Rose verdict: NOT REQUESTED — this is an interim validation checkpoint, not
milestone closure or programme sign-off.
