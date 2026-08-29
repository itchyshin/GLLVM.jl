# After-task — post-#273 work: Tweedie grouped alignment, ν design, and a lane collision (2026-08-28/29)

Ada reporting. Covers everything after PR #273 merged (`66fc8eaa`, 00:41Z).
Companion to `2026-08-28-full-parity-campaign-day.md`, which covers the merged
work itself.

## 1. Goal

Continue toward full 0.7.0 parity after #273 landed: close the Tweedie
grouped/shared curvature inconsistency that today's own flip introduced, and
scope cell 9's remaining half (ν estimation).

## 2. Implemented

- **Tweedie grouped curvature alignment** (branch
  `tweedie-grouped-align-20260828`, commit `b7c8d790`, LOCAL — see §7):
  `_tweedie_grouped_laplace_weight` added on the NB1/Beta/NB2 precedent;
  `hessian` threaded through `_tweedie_grouped_loglik_site`, the grouped
  marginal and `fit_tweedie_gllvm_grouped`; `TweedieGroupedFit` records the
  selector; the RECORDED DEFECT comment rewritten to describe the shipped
  state; two stale `:fisher` pins restored to default-vs-default.
- **Student-t ν estimation DESIGN** (branch `nu-estimation-design-20260828`,
  commit `93977039`, LOCAL): deliberately a design, not a build — see §3.

## 3a. Decisions and Rejected Alternatives

- **Did NOT build ν estimation.** `studentt.jl:11` records that it needs a
  SECOND auxiliary, breaking the scalar-aux implicit-gradient path — a core
  SHARED by every family on it, i.e. exactly the cross-family blast radius
  this campaign existed to eliminate. Starting it at session end, in a repo
  with another live lane, would have handed the next session a half-built
  estimator touching shared machinery. Wrote the design instead, naming the
  gradient-route decision (extend the core / FD-only for that configuration /
  profile ν out) with FD recommended on blast-radius grounds.
- **Did NOT push either branch.** Lane ownership became contested mid-session
  (§9); D-87 says overlap is the maintainer's call, never resolved
  unilaterally. Asked twice; no answer by session end. Work is committed and
  branch-anchored instead.
- **Overrode my own "do not commit" instruction** for the Tweedie sub-agent
  after the collision. Rationale: that rule exists so the orchestrator reviews
  before anything lands, and review still happened — but "uncommitted" stopped
  being a safe holding state once concurrent actors were moving HEAD in the
  shared worktree. Losing verified work twice is worse than reviewing a local
  commit.

## 4. Files Touched

Tweedie branch: `src/families/grouped_dispersion.jl`,
`test/test_grouped_dispersion_tweedie_nb1.jl`,
`test/test_tweedie_grouped_engine_health.jl`,
`test/test_grouped_hessian_consistency.jl`, `docs/src/response-families.md`,
`docs/src/gllvmtmb-parity.md`, `CHANGELOG.md`, `docs/dev-log/check-log.md`.
ν branch: `docs/dev-log/plans/2026-08-29-student-nu-estimation-design.md`.
This report.

## 5. Checks Run

- Tweedie: 406/406 across nine targeted files (builder), **plus an independent
  orchestrator re-measurement on a fresh seed (31337, builder used 702):
  grouped vs shared |Δ| = 0.0 under BOTH selectors, and default-vs-default
  |Δ| = 0.0** — the defect is closed exactly, not approximately. The two
  selectors give genuinely different values (−300.738 vs −301.129), so the
  selector is real rather than decorative.
- JET exposure of the one deviation (untyped family argument, forced by
  include order) checked explicitly: JET's gate targets only the Takahashi
  selinv kernels, so this path is not covered — no CI risk; and Julia
  specialises on concrete argument types regardless of annotation, so no
  performance cost either. Documented rather than "fixed" by churning the
  include order.
- Full-suite coverage for the merged work: Totoro run D **7143 / 0 / 4,
  exit 0, 88m40.7s** — cleared the last "coverage owed" markers.

## 6. Tests of the Tests

The independent re-verification pattern paid again: I re-ran the Tweedie
reduction on a seed the builder never used before believing its 406/406.
Standing rule reaffirmed — the agent that builds a thing is not its only
judge.

## 7a. Issue Ledger / Landing State

**CARRIED-OVER, both branch-anchored and durable, neither pushed:**
- `tweedie-grouped-align-20260828` @ `b7c8d790` — verified, awaiting the
  maintainer's lane-ownership word (push as its own PR / hand to
  `overnight-parity-closure-20260828` / park).
- `nu-estimation-design-20260828` @ `93977039` — same.
FINDINGS-OF-RECORD: the lane-collision incident (§9) and the detached-HEAD
near-loss (§9.2).

## 8. Consistency Audit

The Tweedie branch updates CHANGELOG, check-log, and both docs pages together,
so no surface still claims the grouped route lacks a selector. The STOP #234
ADMIT fence was NOT touched (grep-confirmed) — the curvature flip and the
`fit_gllvm` admit remain separate, as the maintainer's decision scoped them.

## 9. What Did Not Go Smoothly

1. **A lane collision destroyed verified work.** Another actor checked out my
   active worktree (`hessian-kwarg-20260827` → `overnight-parity-closure-
   20260828`, landing #273) and silently discarded a sub-agent's uncommitted
   edits across seven files, AFTER it had verified them at 26/26. Recovered by
   giving that agent a dedicated worktree and authorising local commits. The
   lane-check hook warns about precisely this: *"never `git checkout` their
   branch — that moves HEAD under them."* If several lanes will be live under
   `local-scratch/lanes/`, each needs its own worktree.
2. **A commit sat on a detached HEAD with no branch pointing at it**
   (`93977039`, the ν design). Removing that worktree would have made it
   unreachable and eventually garbage-collected. Caught by explicitly checking
   `git branch --contains` rather than assuming "committed" means "safe";
   anchored to a branch immediately.
3. My first independent Tweedie verification used a wrong call signature
   (invented a `group` kwarg the function does not take) — the failure was
   mine, not the code's. Read the real signature, re-ran, got the exact result.
4. Earlier in the day I nearly published a false "duplicate with drift"
   finding from a `diff` of an empty extraction; corrected in the note rather
   than deleted.

## 10. Known Residuals

Ladder 15/17 paid + 1 conditional (cell 9 at fixed ν); cell 6 tweedie still
unmeasured (its grouped route is now self-consistent, which REMOVES one
obstacle to measuring it, but the admit fence and the remaining recorded
defects stand). Package not releasable: Arcs 4 and 6 untouched. Four
maintainer decisions outstanding (speedup figure, uninstalled phylo subsystem,
AGHQ Slices 2–4, upstream bug-report posting) plus the two landing calls above.

## 11. Team Learning

- **"Committed" is not "safe" — check `git branch --contains`.** A detached
  HEAD commit is one `worktree remove` from oblivion.
- **A shared worktree is a shared mutable resource.** Concurrent lanes need
  separate worktrees, not etiquette.
- **Know when to write the design instead of the code.** ν estimation touches
  a shared core; the right deliverable at session end was a design naming the
  decision, not a partial estimator.

## 12. Cross-Product Coverage

The grouped-alignment template is now executed five times (NB2, Beta, NB1,
Gamma, Tweedie) and is mechanical — directly reusable for DRM.jl. The
detached-HEAD durability check belongs in any multi-worktree workflow.
