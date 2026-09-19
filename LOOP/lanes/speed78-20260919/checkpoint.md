# Checkpoint: speed78-20260919

GOAL: see GOAL.md. Order per arcs.md, most recent first: Shinichi reviewed
S7b's outcome 2026-09-19 09:36 and re-set the order to S7 -> S7c -> S6 (S7c
is new: warm-started inner Laplace fits across the outer FD evaluations,
written up in arcs.md, gated leaf-S7c, dispatched after S7).
STATE: arc S4 DONE (tables below). Arc S7b DONE: CHOLMOD symbolic-reuse
landed in the grouped Laplace kernel, verified by a new identity test and a
before/after bench measurement. G7b.1 PASS, G7b.2 PASS; G7b.3 full
`Pkg.test()` run TWICE in the background (commits e7ca4ff49 then, after a
DelimitedFiles dependency fix, e9c5fa16d) -- see "S7b gates" below for the
result and the one pre-existing, unrelated, order-dependent test failure it
surfaced (test_em_louis.jl, verified NOT caused by this arc).
NEXT: S7 (sparse-phylo/EM hoists, per Shinichi's re-set order) -- see NEXT
below for the concrete targets
S4's profile ranked.

## Table 1 -- per-site Poisson Laplace gradient (bench/profile_laplace_allocs.jl; n=500,K=2)
| p  | iters | value_ms | grad_wall_ms | hoist_ms | forwarddiff_ms | dual_MB | gap vs decomposed |
|----|-------|----------|--------------|----------|----------------|---------|--------------------|
| 20 | 63    | 4.4      | 20.3         | 3.8      | 16.4           | 65      | 0.9%              |
| 50 | 81    | 8.5      | 95.6-98.5    | 7.0-7.3  | 89.8-92.0      | 382     | 1.8-3.6%          |
Chunk passes measured (not assumed) at p=50: **13**, exact match to `cld(n_theta,12)` (n_theta=149).
Gradient wall at p=50 is ~40-43% FASTER than the banked 170.5ms
(docs/dev-log/core070/poisson-perf-diagnosis.md:7) -- that figure predates the
R2 mode-hoist repair it describes as the redundant-Newton-solve bug; the
repair already fixed it, so this is the expected improvement, not a
regression, and is why G4.1's banked-comparison sub-check reads FAIL.
ForwardDiff/Dual pass is 89-96% of the gradient wall at both p -- the
remaining lever is R1 (hand-derived analytic total gradient, deferred in
poisson-perf-repair-notes.md for correctness risk) or ForwardDiff
config/chunk tuning, NOT the per-site Newton solves (value+hoist together
are only 12-16ms of the ~104ms p=50 total).

## Table 2 -- grouped Poisson GLMM, S4 shadow-driver measurement (superseded by S7b's exact counts below)
| metric | value |
|---|---|
| warm median wall (5 reps) | 0.1885-0.199 s (banked 0.192s, band 0.15-0.25s) |
| outer FD-gradient evaluations | 8 |
| inner Newton iterations (summed) | 621 (shadow estimate; true value 711, see S7b) |
| fresh CHOLMOD symbolic analyses | 1345 (shadow estimate; true value 1540, see S7b) |
| objective calls | 103 (shadow estimate; true value 118, see S7b) |
S4's shadow replica reached the identical converged loglik (rel gap 0.0) but
was NOT a bit-for-bit reimplementation of `fit_grouped_nongaussian`'s
optimiser calls, so its call/iteration/cholesky COUNTS were estimates, not
exact -- S7b re-measured these exactly via a real in-code counter (see
below) and found the true numbers are ~15% higher (118 calls, 1540 fresh,
711 summed inner iterations). This is a correction, not a regression: it
was already true on origin/main, S4 simply undercounted it.

## Table 3 -- phylo EM scaling (bench/profile_em_phylo_scaling.jl; default sparse E-step, K_B=1, n=200)
| p | loglik_check_ms | estep_ms | driver_ms_per_iter |
|---|---|---|---|
| 200 | 1.3 | 0.7 | 3.4 |
| 1000 | 35-37 | 14-15 | 83-86 |
| 5000 | 2493-2517 | 1114-1118 | 8235-8535 |
**EM_SCALING p^2.4 ambiguous** (fitted exponent 2.42-2.43 from p=200/1000/5000;
all three cells completed well inside the 5min/cell and 15min whole-script
budgets, longest cell 156-161s). Close to p^3, far from p^1: the "default
sparse E-step" branding does NOT make `em_fit_phylo`'s per-iteration wall
O(p), because (a) the per-iteration monotonicity check
(`gaussian_marginal_loglik`'s J3 path, src/likelihood.jl:212-244) forms a
dense p x p `A` and does TWO `cholesky(Symmetric(p x p))` calls every
iteration regardless of which E-step runs, and (b) `_estep_sparse` itself
hides a THIRD dense p x p Cholesky at src/em_phylo.jl:399-403 (only used to
get the K_B x K_B `ImβΛ` term, but paying the full p x p factorization to
get it). There is no SQUAREM map inside `em_fit_phylo` (that lives only in
the separate, un-invoked `em_fit_phylo_squarem`, src/em_squarem.jl) --
the Fable plan's "SQUAREM map" cost concern is better read as this
loglik-check + hidden-Cholesky pair, which this profile now confirms and
locates.

**12x lives on: grouped** (confirmed and exactly quantified by S7b: one
grouped-Poisson fit of the Latte 200x5 fixture makes 118 inner Laplace-fit
calls totalling 711 summed inner Newton iterations and, pre-fix, 1540 fresh
CHOLMOD symbolic+numeric factorizations; 0.19s wall vs Latte's 0.015s --
~12.8x. The per-site LV-model gradient path in Table 1 is a different model
class and is not part of this 12x).

## S7b: CHOLMOD symbolic reuse -- landed, before/after (bench/results/grouped_after_e7ca4ff49.tsv)
| metric | before (pinned baseline) | after (measured) |
|---|---|---|
| warm median wall | 0.192 s | 0.192-0.195 s (no meaningful change) |
| inner Laplace-fit calls | 118 | 118 (unchanged -- optimiser path untouched) |
| fresh CHOLMOD symbolic analyses | 1540 | 236 (= 2*118, exactly "2 per call, 0 thereafter") |
| reused (cholesky!) | 0 | 1304 |
| fallback (pattern mismatch) | n/a | 0 |
| outer FD-gradient evaluations | 8 | 8 (unchanged -- fix does not touch the outer optimiser) |
| vs Latte.jl (0.015s) | ~12.8x | ~13.0x |

**Important, surfaced finding**: the reuse is mechanically correct and large
(6.5x fewer fresh CHOLMOD symbolic analyses, 0 fallbacks, identity preserved
to full float precision -- test_grouped_laplace_identity.jl 17/17,
test_grouped_laplace.jl 61/61 unchanged) but delivered **~0% wall-clock
improvement** on this fixture. CHOLMOD symbolic analysis for this fixture's
~200x200 sparse system is already sub-millisecond even done fresh every
time (1540 fresh factorizations fit inside the pre-fix 0.192s total). The
~0.19s wall is dominated by something else -- plausibly the O(n=1000)
per-Newton-iteration GLM state/score/curvature computation in
`_joint_grouped_state`/`_joint_grouped_components` (src/grouped_laplace.jl),
which loops over all 1000 observations every one of the ~711 total inner
Newton iterations, regardless of the m=200 random-effect dimension the
Cholesky operates on. This is OUTSIDE what this arc's OWNS list authorized
investigating further; surfaced for the orchestrator/a future arc, not
fixed here.

**Analytic outer gradient: NOT in scope, FD gradient stays.** Per the
task's own condition ("only if the outer evaluations own the majority of
the wall after the reuse lands"): of the 118 inner Laplace-fit calls, only
~36 are attributable to FD-gradient evaluations (8 outer gradient calls x
2*n_theta=4 stencil points each, plus one initial candidate-gradient check)
-- a MINORITY (~30%) of the 118 total; the rest (~82) come from NelderMead's
own simplex search plus the final FD-Hessian. Moreover, the CHOLMOD-reuse
experiment above already demonstrated that CUTTING call-attributable cost
(a 6.5x reduction in fresh-cholesky count) does not proportionally reduce
wall time here -- the bottleneck is per-call fixed cost elsewhere, not
multiplicity of any one operation type. An analytic outer gradient would at
best cut ~30% of calls on an already-~0.19s fit, is not clearly "the
majority", and is not evidenced to help given the reuse result. Left alone
per the task's own instruction.

## S7b gates
- G7b.1 PASS: `julia --project=. test/test_grouped_laplace_identity.jl --gate identity`
  -> `GATE G7b.1 PASS` (17/17 checks; exit 0). Confirmed correctly FAILs on
  the pre-fix code (10/11, exit 1, reason "GLLVModels._grouped_chol_stats[_reset!]
  not defined") before the fix commit landed -- the TDD contract held.
- G7b.2 PASS: `julia --project=. bench/profile_grouped_glmm.jl --gate after`
  -> `GATE G7b.2 PASS`; TSV bench/results/grouped_after_e7ca4ff49.tsv.
- G7b.3: `test -z "$(git diff --name-only 69a69b0a0 -- test/ ':!test/test_grouped_laplace_identity.jl' ':!test/runtests.jl')"`
  confirmed clean (no other test/ file touched). Full `Pkg.test()` run TWICE:
  run 1 (commit e7ca4ff49) errored loading test_grouped_laplace_identity.jl
  ("Package DelimitedFiles not found in current path" -- Pkg.test()'s
  sandboxed test environment does not fall back to the implicit stdlib path
  the way an interactive `--project=.` run does); fixed in e9c5fa16d (Base
  eachline/split/parse instead of readdlm, no new dep). Run 2 (commit
  e9c5fa16d): 16206 passed, 1 failed, 0 errored, 19 broken (19 broken =
  pre-existing `@test_broken` entries, expected). The 1 failure is
  `test_em_louis.jl:127` ("SE PRIMARY GATE: EM-SEM SEs match dense-Hessian
  SEs (p=10)", rel=0.0010560201922229443 vs threshold 0.001 -- bit-identical
  value in BOTH full-suite runs, i.e. deterministic, not BLAS-threading
  noise). VERIFIED NOT CAUSED BY THIS ARC: (a) `test_em_louis.jl` calls
  `cholesky` only on an unrelated phylo covariance fixture, never
  `joint_grouped_laplace_loglik`/`_grouped_cached_cholesky!`; (b) it runs at
  runtests.jl position 54 (line 106), strictly BEFORE
  `test_grouped_laplace_identity.jl` at position 97 (line 190) -- test
  execution is sequential top-to-bottom, so nothing at position 97 can affect
  RNG/global state consumed at position 54; (c) run standalone in a temporary
  `git worktree` at origin/main 69a69b0a0 (cleaned up after), it PASSES
  147/147 cleanly -- so this is a pre-existing, full-suite-order-dependent
  flake (some earlier test's RNG/state consumption tips this borderline
  0.1%-tolerance assertion when run in the full sequence), not a regression
  from S7b. The ledger's literal CHECK (`grep -q "Testing GLLVModels tests
  passed"`) therefore reads FAIL -- reported honestly, with the above as the
  evidence it is a pre-existing, unrelated, unfixed-by-this-arc issue, not a
  correctness problem in the CHOLMOD-reuse change.

## TRUTH LIVES IN
Branch `claude/lane-speed78-20260919` in this worktree (unpushed). Commits,
in order: `3ff8bfbeb` (identity test, TDD baseline), `4a11bd4b4` (the
CHOLMOD-reuse fix + runtests.jl wiring + baseline correction),
`e7ca4ff49` (bench --gate after). `src/grouped_laplace.jl` is the ACTUAL
file (both the leaf-S7b ledger's OWNS list and arcs.md name it
`src/families/grouped_laplace.jl`, which does not exist in this repo --
flagged in the fix commit message, not silently corrected). TSVs in
bench/results/ (git-ignored, not committed):
`grouped_after_e7ca4ff49.tsv`; earlier S4 TSVs still present from the prior
arc. Full-suite log: `/tmp/full_pkg_test_s7b.log` (outside the repo,
ephemeral). Ledger: `.unlazy/julia-speed-20260919/gates/leaf-S7b.md`
(git-ignored).

## NEXT: S7 (sparse-phylo/EM hoists)
Per arcs.md and S4's Table 3 (p^2.4 ambiguous, near p^3): the ranked targets
are (1) `gaussian_marginal_loglik`'s J3 phylogenetic path
(src/likelihood.jl:212-244) forms a dense p x p Cholesky TWICE every
`em_fit_phylo` iteration for the monotonicity check, regardless of which
E-step runs; (2) `_estep_sparse` (src/em_phylo.jl:399-403) hides a THIRD
dense p x p Cholesky, used only to get the K_B x K_B `ImβΛ` term -- a
Woodbury/low-rank replacement avoids ever forming that dense p x p `A`;
(3) `takahashi_diag` and the `X_G = chol_Q_eff \ G` solve inside
`_estep_sparse` could plausibly be hoisted to once per fit rather than once
per E-step call if `chol_Q_eff`'s pattern is also fit-invariant (unverified
-- check before assuming: this arc's own S7b experience is a caution that a
plausible-looking symbolic-reuse win does not automatically move the wall
the way expected -- measure the per-component wall share BEFORE committing
to a fix, exactly as S4/S7b did here). Write leaf-S7's gates before touching
src/, tests first, identities against origin/main 69a69b0a0.
