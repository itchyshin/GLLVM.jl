# Checkpoint — honest-0.7 parity programme (2026-09-13, G0/gap-inventory slice)

- DONE this slice: `LOOP/GOAL.md` + `arcs.md` + `checkpoint.md` (this file) + `ultra-plan.md`
  written for the honest-0.7 parity programme; gap inventory built by reading
  `docs/design/capability-status.md` (main) + the DestB G1 audit matrix / G2 closeout (read from
  `codex/destination-b-b1-integration-20260910` via `git fetch` + `git show FETCH_HEAD:…`, never
  merged/checked out) + `docs/src/gllvmtmb-parity.md` (main) +
  `docs/dev-log/core070/true-parity-decision-map.md` (main). Decision note
  `docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md` written.
- CI: none run this slice (docs-only; no `src/`/`test/` touched).
- **GOAL_COMPLETE: no** — this slice is the programme scaffold + gap inventory + decision note,
  not the programme itself. The programme's own definition of done (in `GOAL.md`) needs #318's
  CI fixed, the 7 `planned` covariance-grid cells dispositioned, and the DestB numerical gates
  closed or signed-off — all future arcs.
- **Branch:** `cursor/gllvm-07-parity-programme-20260913`, created fresh from `origin/main`
  @ `57ff35c5` (post-#319 merge). Does **not** build on #318 (`codex/destination-b-b1-integration-20260910`,
  currently CI-red on 7/10 checks, being fixed by another agent) — only reads it via
  `git fetch origin codex/destination-b-b1-integration-20260910` + `git show FETCH_HEAD:<path>`,
  which touches nothing in this branch's working tree.
- **Blocking state observed, not caused by this slice:** PR #318 is open/draft. Prior CI
  (run `34790377224`) failed shard 3 on `test_destination_b_joint_other_families.jl:107`
  (`hessian_positive_definite` on NB2-log). Fix agent landed `89235578` (relax PD assertion at
  known collapsed-variance boundary); CI re-run `34791694556` queued/in progress at last check.
  Not edited from this lane.
- **Main moved:** PR #320 merged (`d30a92bc`) — S4 recorder rehydrate pointer on `origin/main`.
- **WHERE TRUTH LIVES:** DestB numerical evidence + ledger reconciliation live only on #318 today
  (`docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`,
  `docs/dev-log/2026-09-13-destination-b-g2-closeout.md`, `.unlazy/destination-b-programme/GATES.md`
  gitignored) — none of it is on `origin/main` yet. The gap inventory in `ultra-plan.md` cites that
  branch by commit/file, not by merging it.
- **RESUME:** read `LOOP/GOAL.md` → this file → `docs/dev-log/decisions/2026-09-13-honest-070-parity-aim.md`
  → `LOOP/arcs.md` (ranked) → `LOOP/ultra-plan.md` (full gap inventory + rationale).
- **NEXT (ranked, for whoever picks this up after #318 is green):** see `arcs.md` #4, #8, #9–15,
  #5; summarised in the after-task report and the final chat reply.
