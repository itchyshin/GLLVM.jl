# Fixed Student-t df input boundary — partial programme checkpoint

## 1. Goal
Reject nonfinite fixed degrees of freedom before reading responses; retain
finite positive fixed df and the estimated route. This is a bounded repair
within the approved Core070 programme, not completion of M1.

## 2. Implemented
The dedicated fitter now requires finite positive scalar/vector `nu`. The
generic `fit_gllvm` route receives the same guard through dispatch. No marker
constructor or likelihood formula was changed. A sentinel response matrix has
a valid shape but throws on reads, preventing any fit during admission tests.

## 3a. Decisions and Rejected Alternatives
Frozen R commit `b4d5fee64def88bc768dda1f1f77c29b295edd86` rejects df <= 1.
Julia's documented fixed df > 0 is intentionally broader; do not narrow it to
imitate R. Estimated df remains 1 + exp(theta). Do not treat the Gaussian limit
as permission to pass infinity into a finite-t likelihood. No new upper cap,
ridge, clipping, optimizer change, or tolerance widening was introduced.
Initial scale/df validation is a separate neighbouring audit still required.

## 4. Files Touched
`src/families/studentt.jl`; new `test/test_studentt_input_validation.jl` and its
central test include; `tools/core070_student_input.py`; Student-t reader page,
tutorial, README and both changelogs; this report, evidence summary, check-log
and programme checkpoint. Mutable receipts are in
`.unlazy/core070-aghq/student-input-01/`.

## 5. Checks Run
Full-package offline snapshots on Julia 1.10.0, one Julia/BLAS thread:
- Original engine: 24 passed, 3 failed, 0 errors, exit 1, 9.799 seconds.
  Infinite scalar, infinite vector member, and infinite marker route all
  reached a response read instead of rejecting the argument.
- Repaired engine: 27 input assertions plus 51 unchanged density/AD assertions
  passed, exit 0, 8.578 seconds. Tests load the actual full package snapshot;
  exact source, tests, executable, manifest and raw log hashes are retained.
- Seven damaged-evidence controls pass. Fresh Unlazy reverify: one met, one
  unmet; aggregate exit 1 correctly preserves unpaid full parity and review.
- Totoro and DRAC Fir existing sockets returned `totoro` and `login1`.
  No new login, remote compute, model fit or scientific campaign was run.
- `git diff --check` passed. Full core/Pkg.test, Aqua/JET/Allocs, Documenter
  execution and rendered visual review were not run for this checkpoint.

## 6. Tests of the Tests
The original engine is the negative control for the new regression. Valid
finite low-df and estimated-route controls must reach the sentinel read, so
an unconditional rejection fails. Evidence controls reject a nonzero green
exit, source-change flag, timeout, modified log, modified test, modified source,
and missing receipt. These seven controls operate on disposable copies.

## 7a. Issue Ledger
- Reproduced fixed infinite df admission: repaired and targeted checks pass.
- Stale tutorial said empty StudentTFamily fixed the same df: corrected to
  estimated df, matching source and tests.
- Original Student-t fitted fixture R health: still fails/unpaid.
- Full finite source-to-case mapping: still unpaid; 698 nonexcluded overlapping
  facts remain unmapped. This leaf does not promote any coarse capability row.
- Existing Distributions.Multinomial import warning: observed in both runs;
  unchanged, not hidden or declared resolved.

## 8. Consistency Audit
Reader/API text distinguishes finite fixed df from estimated df and the Julia
low-df extension. Both changelogs agree. Numerical equations and parameter
counts are unchanged. Earlier whole-source numerical receipts are historical
after this source edit, including the six qualified binomial models. Final
candidate requalification is still required. R0.7.1 and article lanes untouched.

## 9. What Did Not Go Smoothly
Sandbox socket access initially returned Operation not permitted; the approved
existing-socket hostname check then succeeded without a fresh authentication.
The first preflight used a repository name where a directory was expected;
the corrected absolute-path preflight found the existing owned lane.
The README/changelog paths were added to the lease after their small edits,
not before. No other writer was found; future reader-file scope must be named
before editing. The leaf gate itself was written before regression execution.

## 10. Known Residuals
No claim of fitted Student parity, complete family admissions, recovery,
coverage, performance, embedding, full-suite success or final documentation.
Independent domain/Rose review remains unpaid; no new reviewer dispatch or
previously denied transcript transfer was attempted. Programme remains ACTIVE,
M1 PARTIAL; no push, merge, cleanup or release.

## 11. Team Learning
At admission boundaries, a matrix that refuses reads distinguishes argument
rejection from accidental numerical failure without paying for a fit. Positive
controls are essential: legitimate broader Julia support must survive the fix.
Parent implemented and verified this leaf; no independent reviewer is implied.

## 12. Cross-Product Coverage
This checks Julia direct and generic fixed-df input guards and adjacent scalar
derivatives. It does NOT cover formula/bridge embedding, fitted likelihood
parity, missing data, covariance routes, AGHQ, or the R0.7.1 programme.

Rose verdict: NOT RUN — targeted repair verified; independent completion
review and required programme gates remain outstanding.
