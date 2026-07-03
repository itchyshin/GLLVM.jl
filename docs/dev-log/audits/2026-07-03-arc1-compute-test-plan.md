# 2026-07-03 - Arc 1 profile-first compute/test plan

## Verdict

Use a profile-first, source-specific Gate 1 -> 3 ladder with strict host
separation. Local Gate 1 is route evidence only. Totoro is diagnostic only.
DRAC/Nibi is the only claim-bearing denominator. Do not use bootstrap as the
primary engine.

Live evidence from this worktree:

- HEAD `2fdd7a6` on `codex/phylo-xlv-drac-launcher-20260628`.
- `bench/phylo_xlv_drac_task.jl` already supports `profile_eta_realized`,
  `--write-details`, `--truth-init`, dry runs, partial result files, and DRAC
  array reduction inputs.
- The earlier Gaussian Model A gate precedent is complete: local Gate 1
  corrected to `97/100 = 0.970`, Totoro Gate 2 diagnostic `100/100`, and
  DRAC/Nibi Gate 3 `2495/2500 = 0.998` with MCSE `0.000890835`.
- The current source-specific non-Gaussian structural arc is not at that level:
  `test/test_phylo_poisson_xlv.jl` has S1 likelihood and a selected-entry
  `B_eta_realized` canary; `bench/phylo_poisson_xlv_s2_manifest.jl` is
  manifest-only and explicitly performs no fit.
- Current `test/test_phylo_*_xlv.jl` files still use `Random.seed!`; any new
  recovery tests added later should switch to `StableRNGs.StableRNG(seed)`.

## Minimal Local Gate

Aim: prove the profile route is wired for the source/family target before any
remote diagnostic.

Required local evidence:

- Re-run the focused source-specific tests, not the full suite first:
  `test/test_phylo_poisson_xlv.jl`, then the sibling `test/test_phylo_*_xlv.jl`
  files if the arc claims more than Poisson.
- For Poisson, keep the S1 claim narrow: likelihood cross-checks, selected-entry
  finite profile endpoints, finite LR at `B_eta_realized`, constraint error
  below tolerance, and truth covered.
- Treat the S2 manifest as a predeclared design, not a result. A dry run may
  confirm row parsing, selected entries, seed stream, and budgets, but it
  creates no denominator.
- If new recovery tests are added in a later PR, write ADEMP comments above
  each `@testset`, use `using Test`, seed with `StableRNGs.StableRNG(seed)`,
  simulate from known parameters, fit with the relevant private/public driver,
  and report bias/RMSE/coverage/convergence diagnostics in failure messages.

Promotion rule from local to Totoro:

- All focused tests pass in isolation.
- The selected-entry profile canary covers the known `B_eta_realized` target.
- No platform-sensitive optimizer aggregate such as `pd_hessian` is promoted to
  a scientific gate unless the route definition explicitly requires it.
- No source-specific grammar, bridge transport, public support wording, or
  coverage claim is made from local Gate 1.

## Totoro Diagnostic Gate

Aim: expose cheap stability failures before spending DRAC queue time.

Use Totoro only after explicit authorization. Keep it diagnostic even if it is
large enough to be persuasive. The current Poisson S2 manifest predeclares:

```text
family/source: Poisson(log) x augmented phylogeny
target: B_eta_realized
method: private _phylo_poisson_xlv_profile_eta_realized
cell: p=6, n_sites=28, K=1, q_lv=1, K_phy=1, sigma2_phy=0.35
replicates: 20
selected entries: 1,2,5
denominator: 20 x 3 = 60 selected-entry profiles
fit/profile budgets: 250 / 700
host role: Totoro diagnostic only
```

Diagnostic pass rule:

- `20/20` fits converge.
- `60/60` selected-entry profile rows are present and usable.
- Coverage, MCSE, Wilson interval, all LR misses, max LR by entry, fit time,
  and CI time are reduced and recorded.
- Any miss or non-usable profile row triggers inspection before DRAC promotion;
  do not "average it away" with a larger DRAC denominator.

Totoro provenance:

- Record source path, source commit, Julia version, depot, thread caps, command,
  result root, seed0, selected entries, and exact denominator.
- Use single-threaded workers: `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`,
  `OMP_NUM_THREADS=1`, `MKL_NUM_THREADS=1`.
- Cap total workers well below the shared-host limit; Totoro is not a queue and
  should not be treated as claim-bearing replication.

## DRAC Claim Gate

Aim: produce the only claim-bearing coverage denominator for the arc.

Use DRAC/Nibi-style SLURM arrays only after local Gate 1 and Totoro diagnostic
Gate 2 pass. For a first source-specific Poisson claim gate, mirror the Gaussian
Model A precedent but do not inherit its result:

- predeclare a DRAC manifest separately from the Totoro manifest;
- use `profile_eta_realized` as the primary engine;
- keep `truth_init=yes` and `write_details=yes` for reducer auditability;
- use selected entries fixed before seeing DRAC outcomes;
- choose `n = 500` tasks if making a coverage claim, giving coverage MCSE near
  1% at nominal 95% and matching the previous Gate 3 evidence class;
- use one row/seed per SLURM array task, one CPU per task, and no login-node
  fitting.

DRAC pass rule:

- expected result files and detail files all present;
- fit convergence denominator reported;
- profile status denominator reported;
- usable selected-entry denominator reported;
- coverage, MCSE, Wilson interval, misses, max LR by entry, bias/RMSE, fit
  time, and CI time reduced from DRAC files only;
- non-empty error logs counted;
- `sacct`/`seff` recorded for the job;
- no Totoro rows pooled into the denominator.

## Denominators And Provenance

Keep these denominators separate:

- Local Gate 1: route/canary evidence only; no coverage denominator for claims.
- Totoro Gate 2: diagnostic denominator only, e.g. `20 x 3 = 60`; useful for
  promotion decisions, not for public support claims.
- DRAC Gate 3: claim denominator only, e.g. `500 x selected_entries`; this is
  the denominator used in coverage statements.

Minimum provenance fields for every denominator:

- repo path, branch, `git rev-parse HEAD`, and `git status --short`;
- host, Julia version, depot, BLAS/thread variables, and account/queue where
  relevant;
- manifest command, seed0, selected entries, family/source, target, method,
  budgets, and result root;
- reducer command and exact file counts;
- final pass/fail verdict with claim boundary.

Never combine Totoro and DRAC denominators unless a future design explicitly
predeclares a mixed-host analysis. This plan does not allow such pooling.

## Commands

Local evidence commands:

```sh
git status --short
git rev-parse --short HEAD
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
julia --project=. --startup-file=no test/test_phylo_gamma_xlv.jl
julia --project=. --startup-file=no test/test_phylo_beta_xlv.jl
julia --project=. --startup-file=no test/test_phylo_ordinal_xlv.jl
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --reps 20 --seed0 20260702 --selected-entries 1,2,5 --profile-iterations 700 --iterations 250
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --task-id 1 --dry-run
```

Totoro diagnostic command shape, not to run without authorization:

```sh
SOCK=/Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22
ssh -S "$SOCK" -o ControlMaster=no -o BatchMode=yes totoro 'cd /home/snakagaw/codex/GLLVM.jl-phylo-xlv-totoro-20260703 && export JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 && /home/snakagaw/.juliaup/bin/julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /home/snakagaw/codex/phylo_poisson_xlv_s2_manifest_params.csv --task-id 1 --dry-run'
```

DRAC write-only command shape, not to submit in this planning task:

```sh
PHYLO_XLV_REPS=500 \
PHYLO_XLV_LAMBDAS=0.5 \
PHYLO_XLV_N_SPECIES=80 \
PHYLO_XLV_N_SITES=200 \
PHYLO_XLV_K=2 \
PHYLO_XLV_Q_LV=1 \
PHYLO_XLV_K_PHY=1 \
PHYLO_XLV_SCENARIOS=main \
PHYLO_XLV_TARGETS=B_lv \
PHYLO_XLV_METHODS=profile_eta_realized \
PHYLO_XLV_B_LV_ENTRIES=14,41,71,8,44 \
PHYLO_XLV_PROFILE_OPT_ITERATIONS=1000 \
PHYLO_XLV_ITERATIONS=1000 \
PHYLO_XLV_WRITE_DETAILS=1 \
PHYLO_XLV_TRUTH_INIT=1 \
PHYLO_XLV_TIME=0-03:00 \
PHYLO_XLV_MEM=8G \
PHYLO_XLV_CPUS=1 \
PHYLO_XLV_THROTTLE=100 \
bash bench/phylo_xlv_drac_submit.sh --out /scratch/snakagaw/phylo_model_a_gate3_REPLACEME
```

Submission, if later authorized, is a separate command with `--submit` and a
valid `PHYLO_XLV_ACCOUNT`; this audit does not authorize it.

## Stop Rules

- Stop before Totoro if focused local tests fail, the S2 manifest dry run does
  not reproduce the predeclared cell, or the local profile canary fails truth
  inclusion.
- Stop before DRAC if Totoro has any fit failure, missing detail file,
  non-usable selected-entry profile row, unexplained LR miss cluster, or source
  provenance mismatch.
- Stop immediately if a run would use bootstrap as the primary engine for this
  arc.
- Stop if a command would run model fits on a DRAC login node.
- Stop if Totoro and DRAC outputs are being pooled, compared under one
  denominator, or summarized without host labels.
- Stop if a public claim would say source-specific `lv` support, R bridge
  transport, package API support, or coverage calibration before DRAC Gate 3 is
  reduced and audited.
