# GOAL — earn honest 0.7.0 parity with frozen gllvmTMB 0.7.0 before any version bump

**IMMUTABLE for this run.** Re-read this file at the top of EVERY arc, before anything else.

## Definition of done

The programme is "done enough for a joint 0.7.0 decision" — not "0.7.0 shipped" — when:

- [ ] PR [#318](https://github.com/itchyshin/GLLVM.jl/pull/318) either reaches CI-green (the
  8 failing test files' `hessian_positive_definite`/curvature defects fixed by whoever owns
  that engine work) or is split so its docs/ledger land on `origin/main` without the red
  engine code, so the Destination B (DestB) G1/G2 record stops living only on an unmerged
  branch.
- [ ] Every `planned` row in the covariance structure grid
  (`docs/design/capability-status.md` §Covariance structure grid — `phylo_dep`, `animal_dep`,
  `animal_latent`, `spatial_dep`, `kernel_indep`, `kernel_dep`, `kernel_latent`) has a named
  arc in `arcs.md`: either built-and-tested, or carries a maintainer-signed "not required for
  the 0.7.0 decision" disposition. No cell is silently dropped.
- [ ] Every open DestB numerical gate (`B1-RECOVERY`, `S4-PUBLIC-FORMULA`, plus the untouched
  `API-BOUNDARY` and `FINAL-REVIEW` rows named in the #318 G2 closeout) carries either a
  receipt or a maintainer-signed disposition — `CLOSED — INTERFACE LIMIT` (like
  `B1-JOINT-STATIONARY`/`B1-JOINT-PAIR`) counts as a valid disposition; silence does not.
- [ ] `docs/dev-log/core070/true-parity-decision-map.md`'s open questions (T5, T8, T11–T15)
  are each either closed or explicitly carried forward with a named owner.
- [ ] A single joint decision note exists (this arc's own final deliverable, NOT written yet)
  that either (a) proposes the `0.7.0` version bump with every piece of evidence above
  attached and named, or (b) states exactly what remains before that proposal can honestly be
  made. That note itself does not bump the version — it is a proposal for the maintainer.

## Invariants (never violate, even to finish faster)

- **Never bump `Project.toml`'s `version` field.** It stays `0.3.0` until the maintainer signs
  off on the final gated arc. This is a hard fence for this entire programme, not a
  preference.
- Never run the S4 public-formula probe. It requires the recorder object `97214679c` (which
  physically does not exist in this repo's git object store — it is an unpushed commit in the
  sibling `gllvmTMB` checkout) **and** a fresh maintainer authorisation. Neither exists.
  Locating/documenting that blocker is in scope; running the probe is not.
- Never edit `#318`'s (`codex/destination-b-b1-integration-20260910`) failing test or `src/`
  engine files directly — that branch has its own fix agent working the Hessian-PD/curvature
  defects. Read it, cite it, do not patch it from this lane.
- Never edit gllvmTMB's engine (`src/gllvmTMB.cpp`, TMB templates) — read-only reference.
- Never push, merge, or publish beyond opening a **draft** PR — merges are a maintainer act.
- Verification means reading the LOG and inspecting the ARTEFACT, never the exit code alone.
- A narrow or negative search is not proof. "No X exists" usually means the query missed X —
  confirmed here for the S4 recorder by `git cat-file -t 97214679c` returning exit 128 in
  *every* GLLVM.jl worktree, cross-checked against the sibling gllvmTMB repo where the commit
  actually lives (unpushed).
- Destructive or irreversible ⇒ STOP and surface, even if it feels urgent.
- Query the second brain first (`search_notes` with `search_all_projects: true`). D-183
  (vault) records the GLLVM.jl↔gllvmTMB versioning convention this goal enforces: the Julia
  package's version number communicates *parity level* with the R twin, not a race with the
  twin's own release cadence — a version bump is earned by evidence, not scheduled by
  calendar. See `docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md`.

## Pre-authorisation (copied from approved ultra-plan)

- Routine scoped edits (docs, ledger, gap-inventory, decision notes, LOOP files), local
  commands, local commits, and named checks (`graft ask`, `git log`, `gh pr view`,
  `gh api`): CONTINUE.
- Optional remote authority: push named branch `cursor/gllvm-07-parity-programme-20260913`;
  create a **draft** PR against `main`. Never mark ready-for-review, never merge.
- Must stop: any `Project.toml` version edit; running the S4 probe; editing #318's failing
  test/engine files; any `src/` engine change; merge/release/public capability-wording change;
  credentials/security changes; destructive work outside this branch; new compute/cost beyond
  a documented estimate.

## Out of scope (the fence — do NOT drift here)

- Fixing #318's 8 failing test files (Hessian-PD/curvature defects) — that is the named fix
  agent's lane; this programme reads and ranks it as arc #1 for them, does not touch it.
- Running or authorising the S4 probe.
- Bumping `Project.toml` version, tagging, or Julia General registration steps.
- Building new covariance-grid engine code inside *this* slice unless capacity remains after
  the docs/gap-inventory deliverable — if engine work starts, it is its own follow-on arc with
  its own tests, not folded into this docs slice.
- Twin (gllvmTMB) engine edits of any kind.
