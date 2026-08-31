# DRAC recovery/coverage campaign — sized draft (AWAITING APPROVAL, not launched)

Status: DRAFT for maintainer sign-off (D-139 gate). Nothing here has run on DRAC.
Owner lane: codex/core070-aghq-20260830 (Claude cycle). Reference frozen at
gllvmTMB 0.7.0 `b4d5fee6`.

## Why DRAC (and why not Totoro alone)

M2's qualification cells are single fits — Totoro handles those queue-free and
stays the default. What Totoro should not absorb is the replicated evidence the
programme still owes: ADEMP recovery and interval-coverage campaigns per
qualified family/structure (AGENTS.md: "gated multi-seed evidence" via SLURM
job arrays; Totoro also carries the ≤150-core courtesy cap, D-143).

## Estimand and design (ADEMP sketch)

- Aims: parameter recovery-to-truth and Wald/profile CI coverage for each
  correctness-qualified family (bridge-matrix PASS set to start: Gaussian,
  Binomial, Poisson, Beta, NB2; extend as M2 qualifies more) under the ordinary
  rank-1 latent structure, p in {5, 25}, n in {50, 200}.
- Data-generating process: the package simulator at true parameters drawn once
  per cell and pinned (StableRNG seeds recorded in the plan file).
- Methods: GLLVM.jl native fit at g_tol=1e-7 (post-c2a93d6d Hager-Zhang path).
- Performance measures: bias, empirical SE, RMSE, CI coverage at 0.95,
  convergence-health rate (fit-health failures reported, never dropped).
- Monte Carlo size: 500 seeds per cell -> 5 families x 4 (p,n) cells x 500
  = 10,000 fits, one seed per `$SLURM_ARRAY_TASK_ID`, arrays of 500.

## Sizing estimate (to be validated by the pre-run test)

Single small fit ~2-10 s, large cell (p=25, n=200) ~1-3 min. Worst-case cell:
500 x 3 min = 25 core-hours; full campaign approx. 60-120 core-hours total.
CPU-only, one core per task, `OPENBLAS_NUM_THREADS=1`. Target cluster: any
approved CPU DRAC system (Fir/Rorqual/Narval class); `sbatch` with
`--time=00:20:00 --mem=2G` per task; outputs to `/project` (never `/scratch`
keepers); Julia depot on `/project`.

## PRE-RUN TEST (the D-139 gate; must run and be shown before the campaign)

One array of 10 tasks, smallest cell (Gaussian p=5 n=50), on the chosen
cluster: validates the sbatch invocation, module/depot setup, non-empty
non-NA per-seed output, and gives a measured per-fit time to re-size the full
submission. Abort criteria: any empty/NA output file, or measured time > 3x
estimate.

## What is NOT authorized by this draft

No DRAC submission of any kind; no login-node compute; no change to frozen
contracts. Approval needed on: target cluster, seed count (500 vs less),
family set, and whether coverage (CI) cells run in the same campaign or after
profile-CI qualification.
