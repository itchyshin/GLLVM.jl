# After-task: honest-0.7 parity programme scaffold + gap inventory

**Date:** 2026-09-13
**Branch:** `cursor/gllvm-07-parity-programme-20260913` (fresh from `origin/main` @ `57ff35c5`)
**Requested scope:** build the durable programme to earn honest 0.7.0 parity with frozen
`gllvmTMB` 0.7.0, without bumping `GLLVM.jl`'s own version yet; do not conflict with PR #318's
fix agent.

## What landed

1. `LOOP/GOAL.md` — immutable goal for this programme: the joint 0.7.0 decision, not the bump
   itself. Hard fence: never edit `Project.toml`'s version, never run the S4 probe, never edit
   #318's failing test/engine files.
2. `LOOP/arcs.md` — 24 ranked arcs across three groups: DestB numerical gates (8 arcs),
   covariance-grid gaps (7 arcs, one per `planned` cell), second-order/real-workflow gaps
   (8 arcs), and the final gated version-bump arc.
3. `LOOP/checkpoint.md` — current state snapshot, resume pointers.
4. `LOOP/ultra-plan.md` — full gap inventory with sources cited, DONE/NEXT/BLOCKED
   classification, and a ranked-next-5 list for whoever picks this up after #318 is green.
5. `docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md` — decision note: aim 0.7.0 (not
   a marketing bump), `Project.toml` stays `0.3.0`, cites vault D-183 for the "versions are
   independent of the twin's release cadence" convention.
6. `docs/dev-log/check-log.md` — dated entry recording all of the above.

## Method

Evidence-first (`git status`, `git rev-parse`, `gh run list`, `gh pr list`) before any write.
Discovered the working tree had drifted onto an unrelated, already-pushed docs-only branch
(`cursor/s4-recorder-pointer-20260913`, apparently a separate concurrent session) — left it
untouched and created a fresh branch from `origin/main` per the task's own instruction, rather
than building on it or on #318.

Gap inventory was built by reading `docs/design/capability-status.md`,
`docs/src/gllvmtmb-parity.md`, and `docs/dev-log/core070/true-parity-decision-map.md` directly on
`main`, plus PR #318's own G1 audit matrix and G2 closeout — fetched (`git fetch origin
codex/destination-b-b1-integration-20260910`) and read via `git show FETCH_HEAD:<path>`, which
never touches this branch's working tree or HEAD. This was the only way to see #318's DestB
findings without merging, checking out, or waiting on its own CI to resolve.

## Key finding surfaced (not caused) by this slice

PR #318's DestB record shows real, dated progress (G1 static audit: 16 DONE items; G2 closeout:
B1 → `CLOSED — INTERFACE LIMIT`, S3b consumer → qualified/fenced, S4 → `HELD`) — but **none of it
is on `main`**, and the branch's first-ever CI run (triggered by a same-day merge-with-`main`) is
genuinely red: 7 of 10 checks fail across 8 test files exercising real Hessian-PD/curvature
defects that had simply never been exercised by CI before today. This is the single highest-
leverage blocker for the whole honest-0.7 programme — nothing downstream of DestB's numerical
gates can be evaluated from `main` until it clears — hence it is ranked arc #1 in the "next 5"
list, explicitly assigned to #318's own fix agent, not touched here.

## Covariance-grid gap, independently confirmed

`docs/design/capability-status.md`'s covariance structure grid (15 cells: 5 sources × 3 modes)
has 7 `planned` cells: `phylo_dep`, `animal_dep`, `animal_latent`, `spatial_dep`, `kernel_indep`,
`kernel_dep`, `kernel_latent`. This is the "covariance-grid gaps" half of the task's immutable
goal — recorded, ranked (`phylo_dep`/`animal_latent` first, kernel row as one 3-cell unit second),
but not built in this slice (explicitly out of scope: engine work is its own follow-on arc with
its own tests, per `AGENTS.md`'s family-addition rule).

## Forbidden-actions checklist (self-audit)

- [x] No `Project.toml` edit.
- [x] No S4 probe run or authorised.
- [x] No edit to #318's failing test/engine files or any `src/` file.
- [x] No twin (gllvmTMB) engine edit.
- [x] No merge, no `gh pr ready` — a draft PR only, per the task's explicit ask.
- [x] No `git add -A` — every commit stages named paths only.

## Needs Shinichi / next steps

See `LOOP/arcs.md` and `LOOP/ultra-plan.md` §3 for the full ranked list. In one line: fix #318's
CI-red engine defects first (arc owner already assigned), then this programme's covariance-grid
and DestB-gate arcs become buildable against a clean `main`.
