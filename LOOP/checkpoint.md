# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see LOOP/GOAL.md.   STATE: helper + call site landed; STOP at tests.

ARCS DONE (verified):
- 2a LOOP kit on this worktree (not overnight/honesty).
- 2b `_aghq_kd_bound(d, k)` + call site on `src/families/aghq_grid.jl`.
  Contract log (not `test/test_aghq_gate.jl`): throw iff `k>1` and `d>5`;
  `phylo=true` still wins; k=1 K=6 ≈ Laplace (absdiff 1.78e-15);
  no `_aghq_d_bound` / `aghq_gate`. Neighbours from the log:
  `test/test_aghq_grid.jl` **70/70** in 4.3s;
  `test/test_aghq_adapt.jl` **17/17** in 3.2s.

ARC IN PROGRESS: none. 2c/2d blocked.

NEXT: **STOP at tests.** Do not edit `test/test_aghq_gate.jl` until
**#255 MERGED**. Then rebase onto `origin/main` and do 2c/2d.

OPEN GATES (need human):

- **wait #255 MERGED.** Do not edit `test/test_aghq_gate.jl` until then.
  https://github.com/itchyshin/GLLVM.jl/pull/255 is OPEN. That PR owns
  the comment lines on the `!isdefined` tests. Racing is bleed-through.
  Do **not** run `test/test_aghq_gate.jl` on this branch until those
  absence tests are deleted — they will fail because `_aghq_kd_bound`
  now exists.
- After tests + addendum: sibling **push/PR**. This worktree does not
  `gh pr merge` / `--auto`. Not PR-ready while #255 is OPEN (CI would
  fail the `#253` `!isdefined` tests).

Pending tests (notes only — do not land them while #255 is OPEN):

- delete three `!isdefined` absence tests (`_aghq_kd_bound`,
  `_aghq_d_bound`, `aghq_gate`) and #255 comments
- bound(6,3) and (6,2) throw; site k=3 d=6 throws
- phylo=true still wins (phylogenetic ArgumentError before the bound)
- bound(5,3), (1,3), (6,1), (20,1) return nothing
- k=1 K=6 still ≈ Laplace; k=3 K=2 adapt golden still passes
- k=3 d=5 does not throw
- optional: `!isdefined(:aghq_gate)` in a renamed not-a-TMB-port testset

TRUTH LIVES IN:

- worktree `/Users/z3437171/local-scratch/lanes/GLLVM.jl-aghq-a43-afford-20260818`
- branch `cursor/lane-aghq-a43-afford-20260818` from `origin/main` @ `3d5acba0`
- helper: `src/families/aghq_grid.jl` (`_aghq_kd_bound`)
- this worktree’s `LOOP/` (not honesty overnight LOOP)

RESUME: You are **aghq-a43-afford-20260818**. RESUME. READ FIRST:
LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
WORKSPACE: `/Users/z3437171/local-scratch/lanes/GLLVM.jl-aghq-a43-afford-20260818`
on `cursor/lane-aghq-a43-afford-20260818` (reattach; do NOT recreate; do
NOT use the honesty worktree). CONTINUE FROM: if #255 still OPEN, do not
touch `test/test_aghq_gate.jl` or the A4(3) decision note. If #255 MERGED,
rebase onto `origin/main`, land 2c/2d (delete `!isdefined` tests; add
fail-loud bound tests; decision addendum). Pause at sibling push/PR.
Never merge from this worktree.
