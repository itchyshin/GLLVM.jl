# After-task — decision A executes; Exponential healed and adjudicated (2026-08-28)

Ada reporting; Gauss (engine), Fisher (adjudication), Curie (campaign), Rose
(adversarial audit — 11-agent workflow) perspectives engaged. Covers PR #270
(merged, main `f549c81d`), closing the arc that began with the maintainer's
"A - flip all three".

## 1. Goal

Execute decision A (Beta, NB1, Student-t → `hessian = :observed`) as coupled
changes per the NB2 template, and clear whatever the adversarial audit found
in the same verified unit.

## 2. Implemented

- Three family flips: default overrides + specialised observed weights (two
  delegating to the hand-derived grouped formulas; Student-t's derived
  in-session and checked against its score) + Beta's analytic-gradient
  log-det moved in the same commit + grouped Beta/NB1 marginal defaults
  aligned.
- Exponential: `:observed` re-routed through the generic core (retiring the
  Gamma grouped-kernel detour), `_glm_obs_weight` specialised, and the
  registry default DECLARED — the audit's census blocker.
- `_grouped_laplace_mode`: zero-restart + log-posterior backtracking; NB1
  opted in; TweedieED opt-in reverted same day (measured 48m20s regression —
  the merit function pays the infinite-series log-density).
- Census: `KNOWN_OPEN` six → two families in one day; ten certified cells;
  `DEFERRED_BY_DECISION` emptied. Contract pins track every dated flip.
- Campaign: oracle hardened; healed 150-cell Exponential re-run; gp1/tweedie
  and Binomial probit/cloglog cell types staged (unrun).

## 3a. Decisions and Rejected Alternatives

- **Decision A taken by the maintainer** on the written brief (estimator
  quality + TMB parity over reported-loglik accuracy; position C — split by
  surface — rejected in the brief as the gradient-desync class reborn).
- Exponential fix shape: re-route chosen over (i) the prototyped-and-deleted
  two-stage Fisher-warm-start continuation (unnecessary once the objective
  evaluation was correct) and (ii) damping the detour's own loop (the detour
  had no reason to exist once the generic core took the kwarg).
- TweedieED backtracking: correctness rider deliberately traded away on
  measured cost; exposure recorded as engine debt with a named fix shape.

## 4. Files Touched

22 files in the integrated commit `ad32531a` (4 family files, laplace core,
laplace_grad, grouped_dispersion, tweedie, census/contract/identity/oracle
tests, CHANGELOG, two Documenter pages, check-log, campaign files) + the
audit archive `d0915af8`.

## 5. Checks Run

- FD gate (`test_laplace_grad.jl`) on the moved Beta gradient — adjudicated
  against a central difference of the actual objective.
- Census 60+/60+, contract, dual-safety, family files, identity tests.
- Full suite ×3 iterations: 6885/7/4 (stale pins), 6890/2/4 (eleventh pin +
  oracle + the 48m regression), **6892/0/4 in 70m09s** final.
- Healed Exponential campaign re-run: 150/150 convergent, both metrics prefer
  observed (100% estimator preference every regime).
- CI on #270: all six checks green; merged by the authorized watcher.

## 6. Tests of the Tests

The suite caught what my sweeps missed three times (stale-pin instance 11,
the hardcoded-Fisher oracle, the performance regression) — each fixed at
cause, no tolerance widened. The phylo-beta-xlv oracle now *tracks* the
curvature selector, so it survives future flips instead of encoding one era's
default.

## 7a. Issue Ledger

None opened; the two named residual classes are recorded in the audit
archive, check-log, and CHANGELOG "known open" language instead (they are
next-slice work, not stale issues).

## 8. Consistency Audit

CHANGELOG, response-families, parity page, census, contract, and check-log
all state the same set of defaults; the parity page's "still Fisher" list is
now three entries (Tweedie, GP-1, Binomial probit/cloglog). The capability
ledger is untouched (curvature selectors are not ledger rows).

## 9. What Did Not Go Smoothly

1. My stale-pin sweep stopped one sibling file short — the suite found
   `test_nb1_x_identity` (Rose principle: assume ten more of the kind).
2. The audit's TweedieED rider shipped without a cost estimate and burned a
   48-minute testset; caught by comparing suite wall-clocks, reverted with
   the measurement as the recorded reason.
3. A first `git add -u` violated stage-by-name; the staged list was then
   reviewed file-by-file before committing (the review is the rule's
   substance; the habit is still wrong).
4. One suite iteration was killed 40 minutes in once its two failures were
   known — deliberate triage, saving ~75 doomed minutes.

## 10. Known Residuals

- **Confint-layer curvature consistency** (audit class, Exponential + NB2
  instances): confint/bootstrap do not honor the fit's `hessian`; the
  CHANGELOG's `:fisher`-escape claim is true at fit time only. Next slice.
- **Four undamped per-site Newton loops** (NB2/Beta/Gamma/NB1 grouped sites;
  Tweedie's also lacks a cheap merit function): delegation treatment designed
  in the audit with per-loop verification lists.
- Tweedie, GP-1, Binomial probit/cloglog curvature cells: campaign cell
  types staged, unrun (D-139 gate + green-lane precondition now satisfied).
- The stranded CI.yml commit (needs maintainer's `gh auth refresh -s
  workflow`).

## 11. Team Learning

- **An audit rider is a change like any other** — it needs its own cost
  estimate before shipping. "The reviewer said so" is provenance, not
  verification.
- **Test oracles must consume the same configuration surface as the code
  they judge** (the hardcoded-Fisher oracle class); grep candidates:
  `_glm_weight(` in test/ oracles.
- Sibling-file sweeps: when a pin class is found in `test_X_identity`, the
  grep must run over `test_*_identity`, not the one file.

## 12. Cross-Product Coverage

The flip template (default + specialised weight + coupled gradient + grouped
alignment + census/contract/docs) is now executed four times and documented —
directly reusable for DRM.jl's curvature work. The campaign harness with the
hardened oracle likewise.
