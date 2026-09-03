# Ordinal link validation and remaining reference boundaries

## 1. Goal
Resolve native link rejections against the frozen R contract while preserving
unvalidated and unrepresentable options as open work. Repair demonstrated ordinal
input behavior. Programme ACTIVE/M1 PARTIAL; full manifest DRAFT.

## 2. Implemented
The three ordinal fitters now check LogitLink/ProbitLink before reading responses.
All numerical kernels and supported-model controls remain unchanged. Added49
input assertions spanning named/shared/per-trait/X, unified and formula routes.
The separate24-row link contract tests17 actual native controls:7 reject,
10 enter code but remain unvalidated,7 have no equivalent Julia selector.
No R-spelled delta/Gaussian argument was invented to claim a rejection.

## 3a. Decisions and Rejected Alternatives
Unsupported ordinal Identity/Log/CLogLog links lack implemented CDF/density/
quantile kernels. Reject them clearly instead of reading data before a later
error. Retain supported logit/probit and their model identities; frozen R's
ordinal route is probit, Julia's default logit is distinct. Do not declare other
admitted links valid scientific extensions merely from reaching native code.

## 4. Files Touched
src/families/ordinal.jl; two new input/admission tests and central runner;
new link contracts/evidence and current-source refresh summaries; scoped
verification tools and family plan; README, quickstart, API page, CHANGELOG,
check-log and checkpoint. No R engine or foreign worktree edits.

## 5. Checks Run
Totoro one thread per bounded run, Julia1.12.6/R4.5.3/TMB1.9.21, exact frozen R.
Ordinal input red13pass36fail in20.614s; unchanged regression green49pass.
Combined green input/admission70pass in22.075s. Intermediate namespace failure
retained: ordinal49pass, admission18pass3fail; qualified GLLVM distribution names
repair only the fixture. Fresh shape50pass10.190s. Original NB2 three-case
required58pass62.418s. Original ordinal-probit required diagnostic5pass22.822s,
logLik difference5.47567e-9, both optimizer flags true. No full gradient/recovery
upgrade for this ordinal model. All before/after oracle checks pass, jobs terminal.

No-fit runs estimated<=60s/capped120s; paired runs estimated1–2min/capped5min.
All met their estimates. Fresh R4.6.0 extracted-source69descriptor replay passes.
Eleven coverage regressions, archived freeze red and aggregate selftest pass.
Full package suite and Documenter render NOT RUN.

## 6. Tests of the Tests
Same ordinal test hash retained red/green. Unreadable matrices expose response
access; valid links reach that sentinel, invalid links now raise clear errors.
A concrete long table checks the propagated error after pivoting. Nine new
contract/artifact corruptions reject, including false supported-extension labels.
Prior NB2 and shape artifact negatives re-exercised at explicit fresh replay paths.
Source archives, loaded package root, environment and process/log/typed output
hashes verified; actual test counts read from receipts. Unlazy3 scoped gates pass.

## 7a. Issue Ledger
Closed delayed ordinal link rejection and7 native reference link-boundary cases.
Combined with9 shape boundaries,16 of33 reference rejections have scoped native
proof. Ten admitted links and7 missing selectors remain unresolved; the latter
include Gaussian-log and six delta-family options. Full evidence collection and
public R bridge integration remain pending. Student original fit-health open.

## 8. Consistency Audit
README/docstrings/quickstart/API page agree on supported ordinal links and error
behavior. Family plan retains97 specs:2native+1formula+16boundary bindings,
78 unbound. These counts are not fitted-model or full-family totals. Current
NB2/shape summary filenames explicitly end in link-refresh; old snapshots remain
historical after the ordinal source change. Noether focused Terra/high review found no P0–P2 issues. One P3 source comment
about future-link prerequisites is queued; review was source-only because local
Optim was unavailable. See noether-ordinal-link-review.md; no full-programme panel
verdict implied.

## 9. What Did Not Go Smoothly
Three distribution markers were unqualified inside the new fixture's module,
causing UndefVarError; the failed run is preserved. The ordinal diagnostic has5
assertions, not the initially assumed3; verification now uses the actual fixture
and receipts. No tolerance, fixture data, starting point or R control changed.

## 10. Known Residuals
Ten native link admissions are unvalidated, seven reference options have no
matching Julia selector, and broad model/interface contracts remain incomplete.
The ordinal diagnostic only checks optimizer flags and likelihood. No broad
coverage, documentation build, bridge qualification or release evidence here.

## 11. Team Learning
A known link type is not automatically an implemented ordinal CDF. Validate the
family-specific domain at the fit boundary; preserve valid model numerics.
No new production children. One focused Noether review dispatched native Terra/high
with fresh context and only public code; no private transcript transfer or full
completion-panel claim. Actual aggregate agent-hours not inferred.

Mission Control: local commit 8524935639c857e7769bbcee1465544f913a0c6a;
HTTP 200, exact served readback, R fields unchanged, lease released. Existing
Totoro and Fir sockets verified at 02:43 UTC; Fir queue empty. No new login.

## 12. Cross-Product Coverage
This does NOT cover full Core+AGHQ, all family links, R bridge, covariance,
latent multinomial, calibrated coverage, performance or polished Documenter.
R0.7.1/article/foreign work remains protected. No push/merge/release/cleanup.
