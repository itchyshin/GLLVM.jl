# Checkpoint: speed78-20260919

GOAL: see GOAL.md.
STATE: arc S4 (profile first) DONE. leaf-S4 gates G4.2/G4.3/G4.4/G4.5 PASS;
G4.1 FAILs only its stale-baseline sub-check (see table 1) -- the
decomposition-sums-to-measured-wall sub-check itself is <=3.4% at both p.
NEXT: S6 (per-site) and S7b (grouped) -- both triggered by this profile; see NEXT below.

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

## Table 2 -- grouped Poisson GLMM (bench/profile_grouped_glmm.jl; Latte 200x5 fixture)
| metric | value |
|---|---|
| warm median wall (5 reps) | 0.1885-0.199 s (banked 0.192s, band 0.15-0.25s) |
| outer FD-gradient evaluations | 8 |
| inner Newton iterations (summed) | 621 |
| fresh CHOLMOD symbolic analyses | 1345 |
| objective calls | 103 (0 failed) |
| shadow-vs-real loglik | exact match (rel gap 0.0) |
Shadow replica calls the real, unmodified `joint_grouped_laplace_loglik`
(src/grouped_laplace.jl) directly, so these are measured counts, not
estimates; CHOLMOD count = 2*iterations+1 per `:ok` inner call, derived from
reading src/grouped_laplace.jl:208-291 (each non-terminal Newton pass does
2 fresh `cholesky(Symmetric(sparse))` calls, the terminal pass 1 more; no
symbolic factor is ever reused across calls).

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

**12x lives on: grouped** (evidence: one grouped-Poisson fit of the Latte
200x5 fixture pays 1345 fresh CHOLMOD symbolic+numeric factorizations and
621 summed inner Newton iterations across 103 inner Laplace-fit calls,
0.19s wall vs Latte's 0.015s -- ~12.6x; the per-site LV-model gradient path
profiled in Table 1 is a different model class (multi-trait LV, not the
1-trait grouped GLMM Latte was compared against) and is not part of this
12x).

TRUTH LIVES IN: branch claude/lane-speed78-20260919 in this worktree
(unpushed), commit eb8b868acd6fb41e42237dda2f7c8b7b8cd7516f (bench scripts +
fixture only, no src/ diff vs 69a69b0a0 -- G4.5 PASS); ledger
.unlazy/julia-speed-20260919/gates/leaf-S4.md (git-ignored, G4.2-G4.5 marked
met with EVIDENCE, G4.1 pending/failed); TSVs in bench/results/
(git-ignored via .git/info/exclude, not committed) --
laplace_allocs_d56bccea4.tsv, grouped_glmm_d56bccea4.tsv,
em_phylo_scaling_d56bccea4.tsv, each carrying git SHA/Julia
version/BLAS config/threads/OS/CPU/peak RSS in its header; vault plan copy
LOOP/lanes/speed78-20260919/ultra-plan.md.

NEXT:
- **S6 (per-site, per GOAL order)**: this profile ranks the ForwardDiff/Dual
  pass (89-96% of the p=20/50 gradient wall) as the dominant remaining cost,
  NOT the per-site Newton solves (already fixed by R2/R3/R4). The lowest-risk
  next step is reusing a `ForwardDiff.GradientConfig` across gradient calls
  (currently rebuilt every call); the higher-payoff, higher-risk lever is R1
  (the hand-derived analytic total gradient sketched but deliberately not
  attempted in docs/dev-log/core070/poisson-perf-repair-notes.md, for
  correctness risk on the log-det implicit term) -- if S6 attempts R1, it
  needs its own FD-vs-analytic gate at MANY theta, not just the fitted
  optimum, per that note's own warning.
- **S7b (grouped) IS TRIGGERED**: Table 2 puts the Latte 12x squarely in the
  grouped route's repeated CHOLMOD symbolic refactorization (1345 fresh
  factorizations for one fit of a 200x5 table, no symbolic reuse across the
  103 inner Laplace-fit calls or the 8 outer FD-gradient evaluations). A
  symbolic-factorization-reuse lever (cache the CHOLMOD symbolic analysis
  across calls with the same sparsity pattern, e.g. `cholesky!` on a stored
  factor) is the concrete, evidence-ranked target.
- **S7 (phylo EM) IS TRIGGERED**: Table 3's p^2.4 (ambiguous, near p^3)
  verdict means the sparse E-step alone does not deliver the advertised O(p)
  driver cost. Two independent dense p x p Choleskys (the loglik check) plus
  a third hidden one (`_estep_sparse`'s `ImβΛ` term) are evidence-ranked
  targets; a low-rank/Woodbury replacement for the K_B x K_B `ImβΛ` solve at
  src/em_phylo.jl:399-403 avoids ever forming the dense p x p `A` there.
- Both S7b and S7 need their own gates written before starting (per
  GOAL.md's "written before each starts"), and both are src/ edits, so each
  needs the full identity gate (gradient rtol 1e-8, fitted params/logLik
  rtol 1e-6 vs origin/main, frozen gllvmTMB parity, Optim f/g/iteration
  ceilings) from GOAL.md's invariants -- never widen a tolerance.

RESUME: read LOOP/lanes/speed78-20260919/GOAL.md -> this file -> ultra-plan.md
-> repo AGENTS.md; then write the leaf-S6 and leaf-S7b gates (leaf-S7 only if
S7b's outcome still leaves phylo EM as the priority) before starting either.
