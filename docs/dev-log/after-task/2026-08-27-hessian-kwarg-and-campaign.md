# After-task — the `hessian` kwarg lands, the campaign adjudicates (2026-08-27)

Ada reporting; Gauss (engine), Curie (campaign design), Fisher (adjudication
metrics), Rose (escape audit) perspectives engaged. Covers PR #268 (merged,
main `023a4695`) and the campaign it unblocked. The NB2 default flip is a
separate in-flight slice with its own check-log entry; it closes with its own
PR.

## 1. Goal

Make the Fisher-vs-observed Laplace curvature question measurable **by
fitting** (decision #1 of the consolidated decisions doc): a user-facing
`hessian` kwarg on every single-part family fitter, bit-identical defaults,
then the first campaign-scale A/B measurement.

## 2. Implemented

- `hessian::Symbol` kwarg on nine fitters (beta, negbin, negbin1, gamma,
  poisson, binomial, studentt, tweedie, gp1; exponential already had it):
  validation, threading into the negll marginals, analytic-gradient gates,
  X_lv fail-loud, docstrings.
- `test/test_hessian_kwarg.jl` (23 assertions incl. the Tweedie contracts),
  wired.
- The Tweedie wrapper `kwargs...` passthrough fix (the escape — §9).
- The curvature-adjudication campaign: `campaigns/curvature_adjudication/`
  (quadrature oracle, cell runner, parallel driver, sbatch template, 900-cell
  grid, RESULTS.md).
- Compute-fleet provisioning: Totoro + Fir/Narval/Rorqual/Nibi
  (`docs/dev-log/compute/2026-08-27-fleet-provisioning.md`).

## 3a. Decisions and Rejected Alternatives

- **Kwarg selects the log-det role only; mode search stays Fisher-scored**
  (upholds the 2026-08-25 role separation; rejected: a joint switch, which
  would change the mode and break TMB comparability).
- **Analytic gradient gated on curvature validity** rather than re-deriving
  every gradient for both curvatures now (rejected as scope creep; FD fallback
  is correct, just slower).
- **Campaign oracle = dense 1-D log-trapezoid (8001 nodes), K=1 only**;
  rejected AGHQ-grade oracle for K>1 as a separate arc (and AGHQ is fenced).
- Maintainer decisions taken on the evidence: flip gamma (no-op — already
  observed since 2026-08-25) and NB2 (executing).

## 4. Files Touched

PR #268: 9 `src/families/*.jl` fitters, `src/families/tweedie.jl` wrapper,
`test/test_hessian_kwarg.jl`, `test/runtests.jl`, `docs/dev-log/check-log.md`,
plus the docs commits (`docs/design/capability-status.md` 0.7.1 delta,
`docs/dev-log/plans/2026-08-27-roadmap-to-completion.md`,
`docs/dev-log/audits/2026-08-27-ledger-evidence-bundle.md`). Campaign and
fleet files committed locally, riding the next PR.

## 5. Checks Run

- Baselines to 15 digits before edits; all defaults bit-identical after
  (Tweedie's recovered post-hoc via stash — §9).
- Local `Pkg.test()`: **6884 pass / 0 fail / 4 expected-broken, 77m43s**.
- CI on #268: all six checks green (macOS, 3× ubuntu variants, Windows,
  Documenter + deploy).
- Totoro proof suite (pre-kwarg tree): 6867 pass / 4 broken, 85m29s.
- Campaign: 787/900 cells complete; 113 failures all Exponential (§10).

## 6. Tests of the Tests

The contract test's bit-identity assertions caught a real gate defect during
development (canonical links forced to FD, a 1.4e-11 trajectory difference) —
the gate was fixed, not the test. The full suite caught the Tweedie escape the
targeted verification missed — the redundancy is the system working.

## 7a. Issue Ledger

No new GitHub issues opened. The Exponential mode-solver defect (known,
Arc 2) gained campaign-scale quantification; recorded in RESULTS.md and the
roadmap rather than a new issue, since the roadmap arc already tracks it.

## 8. Consistency Audit

Capability ledger untouched by #268 itself (the kwarg is not a ledger row);
the 0.7.1 delta section and the evidence bundle were added in the same push
deliberately. CHANGELOG untouched by #268 (kwarg is additive, default-
preserving); the NB2 flip carries the CHANGELOG entry. Docs preview built
green on the PR.

## 9. What Did Not Go Smoothly

1. **The Tweedie escape**: the one wrapper without `kwargs...` passthrough
   silently dropped the kwarg into a `try/catch` sentinel collapse — and the
   verification net (baselines, A/B, contract test) covered "nine families"
   that were the eight other edited fitters plus an unedited control,
   missing the ninth edited one. Caught by the full suite; fixed one line;
   all three verification layers now cover Tweedie.
2. **The Totoro campaign first ran on a stale checkout** (cloned pre-push):
   863/900 MethodErrors. Recovered with a fresh checkout; the stale one kept
   the proof suite untouched.
3. `/project/def-snakagaw` over quota on Fir and Rorqual — fell back to
   `$HOME`; two partial directories flagged to the maintainer for deletion
   (guard-blocked for the agent, correctly).

## 10. Known Residuals

- Exponential: 75% campaign mortality; no curvature verdict until the Arc 2
  mode-solver fix; re-run its 150 cells after.
- gp1/tweedie: no campaign cell type yet (density-piece care needed).
- Beta/NB1/Student-t: flip decision open (estimator-vs-reporting trade-off,
  maintainer's call).
- K>1 adjudication needs a better oracle (separate arc).
- Two-part fitters don't expose `hessian` yet (kernel accepts it).
- The stranded CI.yml commit still needs `gh auth refresh -s workflow`.

## 11. Team Learning

- **A verification net's coverage must be enumerated against the CHANGE SET,
  not against a family list** — "nine families" hid an off-by-one between
  edited-set and measured-set. Mechanisable: diff-derived coverage checks.
- **A bare `catch` around an objective converts API bugs into numerical
  failures** — the sentinel screen then fires correctly but points the
  diagnosis at optimisation. Candidate follow-up: catch only expected
  exception types in packed objectives.
- Remote clones must be pinned to the intended SHA, not "the branch at
  whenever the clone ran".

## 12. Cross-Product Coverage

The campaign harness (oracle + cell + driver + sbatch array) is directly
reusable for DRM.jl's curvature questions and any sister package's Laplace
A/B. The fleet provisioning doc covers all compute-heavy repos, not just
GLLVM.jl.
