# Session Handoff: Phylo Model A restart for Codex

Meta: 2026-06-30 16:35 MDT · from Codex · target Codex · new-session handoff

You are Codex, picking up the next session. Read `AGENTS.md` first; it is native
to Codex and is the source of truth for repo rules. This handoff supersedes the
optimistic 2026-06-27 phylo Model A handovers for the first next action: the
next session should start with the blocked weak-cell evidence, not with a
production sweep.

## Critical Context

The ordinary `latent(lv = ~ x)` arc in `gllvmTMB` is closed through PR #581:
`extract_lv_effects()` defaults to `axis_effect`, `trait_effect` remains
available, post-merge R-CMD-check and pkgdown passed, and @Ayumi-495 has the
main-branch install route.

The remaining first topic is **GLLVM.jl phylo Model A**, but the current route is
not ready to scale. GLLVM.jl PR #127 is now closed/parked as blocked evidence:
https://github.com/itchyshin/GLLVM.jl/pull/127. Do not reopen, push, or
advertise source-specific `lv` coverage unless the maintainer explicitly asks
for that path.

The decisive evidence is the p = 80, K = 2, lambda = 0.5 `B_lv` weak cell:

- `bootstrap_basic` valid rows covered `591/720 = 0.821`.
- Even a perfect cancelled task 1 would reach only `671/800 = 0.839`, below the
  0.92 working gate.
- The saturated direct `Y ~ X_lv` comparator tracks the fitted latent-product
  slope almost exactly, including bad task 8 (`0.536` vs `0.533` of truth).
- This looks like finite-sample realised-slope / interval-calibration behavior,
  not a simple `B_lv` extractor artifact or bootstrap convergence failure.

## Goals / Mission

Immediate mission for the new Codex session: **work on phylo Model A first**, but
as a redesign/planning slice, not by rerunning the same bootstrap route.

The right first deliverable is a small design plan answering:

1. What public estimand/regime for phylo Model A can be defended?
2. What interval target should replace the failed Wald / t-Wald / percentile /
   `bootstrap_basic` weak-cell route?
3. What minimum live-toolchain evidence would reopen source-specific
   `phylo_latent(..., lv = ~ x)` exposure?
4. Should the local diagnostic branch ever be pushed, or should the closed PR
   #127 remain retired until a new branch implements the redesigned target?

## What Was Accomplished

gllvmTMB:

- PR #581 merged to `main` as `12526a15`.
- Post-merge R-CMD-check run `28476941515` passed.
- Post-merge pkgdown run `28477809749` passed and deployed.
- Public `extract_lv_effects` docs now show `axis_effect` default,
  `conf.level`, alpha SE/CIs, and explicit `trait_effect` B_lv SE/CIs.
- @Ayumi-495 was notified with:
  https://github.com/Ayumi-495/urbanisation_map/issues/8#issuecomment-4848347523
- Mission Control at `http://127.0.0.1:8770/` shows:
  `17 covered, 3 partial, 0 ready, 0 active, 4 blocked of 24 rows`.

GLLVM.jl:

- `main` at `0e99c04` has the ordinary X_lv CI trio and related bridge routes.
- Local branch `codex/phylo-xlv-drac-launcher-20260628` at `7d6985d` records
  the phylo Model A weak-cell diagnostics and status docs.
- GLLVM.jl PR #127 was commented with blocked evidence:
  https://github.com/itchyshin/GLLVM.jl/pull/127#issuecomment-4848385172
- PR #127 title/body were changed to parked blocked state.
- PR #127 was closed/parked with:
  https://github.com/itchyshin/GLLVM.jl/pull/127#issuecomment-4848418863

## Current Working State

- Working: ordinary gllvmTMB LV extractor surface and public docs are current.
- Working: GLLVM.jl local diagnostic branch is clean and records the negative
  phylo evidence.
- In progress: deciding a defensible replacement target for phylo Model A.
- Not working / blocked: current phylo Model A interval route for `B_lv` at
  p = 80, K = 2, lambda = 0.5. Same-route bootstrap repeats are not useful.
- Closed/parked: GLLVM.jl PR #127; it is not an open merge candidate.

## Key Decisions & Rationale

- Do not launch more DRAC/Totoro `bootstrap_basic` repeats for the current weak
  cell. Arithmetic alone blocks it: `591/720` observed cannot become >= 0.92.
- Treat Totoro as fast diagnostic compute, but do not mix Totoro Julia 1.12 RNG
  rows with DRAC Julia 1.10 rows for seed-matched evidence.
- Keep R-side `phylo_latent(..., lv = ~ x)` fail-loud until a new phylo target
  passes or a maintainer explicitly accepts a narrower public boundary.
- Keep `alpha`/axis-effect and `B_lv`/trait-effect language separate. The
  ordinary gllvmTMB user default is now axis-effect; the GLLVM.jl phylo interval
  diagnostics are for induced trait-scale `B_lv`.
- No code push to GLLVM.jl without explicit maintainer instruction. This is a
  hard repo rule in `AGENTS.md`.

## Files Created / Modified

Current local GLLVM.jl branch relative to PR #127 remote head
`origin/claude/phylo-xlv-modelA-20260627`:

- `AGENTS.md`
- `bench/phylo_xlv_coverage.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `bench/phylo_xlv_drac_summarise.jl`
- `bench/phylo_xlv_drac_task.jl`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/src/changelog.md`
- `docs/src/model.md`
- `src/confint_derived_wald.jl`
- `src/confint_family.jl`
- `src/fit.jl`
- `src/postfit.jl`
- `test/test_confint_derived_wald.jl`
- `test/test_lv_ci.jl`
- `test/test_lv_predictor.jl`
- `test/test_phylo_xlv.jl`

New / important after-task and recovery files on the local diagnostic branch:

- `docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md`
- `docs/dev-log/after-task/2026-06-28-phylo-xlv-local-full-suite.md`
- `docs/dev-log/after-task/2026-06-28-phylo-xlv-pr127-premerge-fixes.md`
- `docs/dev-log/after-task/2026-06-29-phylo-signal-batched-wald.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-iteration-cap.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-request-metadata.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-partial-result-checkpoints.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-summariser-bootstrap-denominator.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-t-wald-comparator.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-target-timing.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-aggregate.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-canary-launch.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-tooling.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap10-result.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-canary-poll.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-detail-diagnostic-tooling.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-parallel-race-expansion.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-weak-cell-mechanism-diagnosis.md`
- `docs/dev-log/recovery-checkpoints/2026-06-28-225514-codex-phylo-xlv-drac-checkpoint.md`
- `docs/dev-log/recovery-checkpoints/2026-06-30-0512-codex-phylo-xlv-bootstrap10-result.md`
- `docs/dev-log/handover/2026-06-30-codex-handover.md` (this file)

gllvmTMB Mission Control / closeout files from the current session:

- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/index.html`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/status.json`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/sweep.json`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/dashboard/version.txt`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/check-log.md`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/after-task/2026-06-30-lv-mission-control-postmerge-refresh.md`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB/docs/dev-log/recovery-checkpoints/2026-06-30-1616-codex-lv-dashboard-checkpoint.md`

## Mission-Control Table

| repo | branch / ref | current state | plan by leverage |
|---|---|---|---|
| gllvmTMB | `main` @ `12526a15` | ordinary LV arc merged, CI/pkgdown green, docs deployed | no immediate action; keep source-specific phylo `lv` fail-loud |
| GLLVM.jl | `main` @ `0e99c04` | ordinary X_lv CI trio and routes on main | use as baseline; do not conflate with phylo coverage |
| GLLVM.jl | closed PR #127, old head `b87a522` | phylo Model A route closed/parked as blocked evidence | start with redesign plan, not more compute |
| GLLVM.jl | local `codex/phylo-xlv-drac-launcher-20260628` @ `7d6985d` | clean local diagnostic branch with weak-cell closeout | read evidence; push only if maintainer explicitly asks |
| Mission Control | `http://127.0.0.1:8770/` | `17 covered, 3 partial, 0 ready, 0 active, 4 blocked` | use as orientation only; source docs/PRs are authoritative |

## Next Immediate Steps

1. Rehydrate from this handoff, `AGENTS.md`, Design 73, and the two 2026-06-30
   after-task reports.
2. Confirm external state:
   `gh pr view 127 --repo itchyshin/GLLVM.jl` should show `CLOSED`; gllvmTMB
   open PR list should be empty.
3. Draft a **small Phylo Model A redesign plan** before coding. Minimum sections:
   "what worked", "what failed", "candidate next target", "minimal evidence
   gate", "what not to rerun".
4. Likely candidate directions to evaluate:
   - narrower public regime: avoid p=80, K=2, lambda=0.5 until a known finite-
     sample rule is established;
   - estimand reframing: direct realised-slope or prediction-scale target rather
     than treating the latent-product `B_lv` CI as calibrated in the weak cell;
   - interval redesign: simulation-calibrated/profile-style route or
     parametric-bootstrap target with explicit finite-sample shrinkage;
   - route retirement for v1: keep phylo Model A point plumbing local and leave
     source-specific `lv` grammar blocked.
5. Only after the maintainer chooses a direction, implement on a fresh branch.
   Do not reopen PR #127 as-is.

## Blockers / Open Questions

- Which public target does Shinichi want for phylo Model A: narrow supported
  regime, prediction-scale target, redesigned interval, or v1 retirement?
- Should the local diagnostic branch `7d6985d` ever be pushed, or should its
  evidence remain local/documented while a new clean redesign branch starts?
- What minimum coverage threshold and cell grid should gate a redesigned route?
- Is source-specific `phylo_latent(..., lv = ~ x)` still desired for v1, or
  should it be explicitly post-v1?

## Gotchas & Failed Approaches

Failed / do not repeat without a changed method:

- Same-route Wald, t-Wald, percentile bootstrap, and `bootstrap_basic` for the
  p = 80, K = 2, lambda = 0.5 `B_lv` weak cell.
- More `bootstrap_basic` cores. The optimistic bound is already too low.
- Truth-start as an explanation for task 8. It did not fix task 8.
- Treating the failure as an extractor artifact. Direct `Y ~ X_lv` slopes track
  the latent-product slopes.
- Mixing Totoro Julia 1.12 diagnostic rows with DRAC Julia 1.10 seed-matched
  evidence.

Worked / keep:

- J3 rotation trick with X_lv mean shift was pinned to dense Gaussian
  correctness at about `7e-15`.
- The local runner/submitter/summariser tooling is useful for targeted
  diagnostics.
- Narval/Nibi/Rorqual one-core array tasks and Totoro pinned one-core workers
  are effective for fast diagnostics when there is a real method to test.
- The direct saturated-slope comparator is a good mechanism check.
- Mission Control is useful for keeping "covered", "partial", and "blocked"
  rows distinct.

## How to Resume

Start the new Codex session in the GLLVM.jl diagnostic worktree:

```sh
cd /private/tmp/gllvmjl-phylo-xlv
```

Then paste this to Codex:

```text
Rehydrate from docs/dev-log/handover/2026-06-30-codex-handover.md + the AGENTS.md snapshot. First task: make a small Phylo Model A redesign plan that starts from the failed p=80,K=2,lambda=0.5 weak-cell evidence, names what worked and what did not, and proposes the next defensible target without rerunning the same bootstrap route.
```

Codex live-toolchain environment:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
export JULIA_NUM_THREADS=1
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
julia --project=. -e 'using Pkg; Pkg.instantiate(); using GLLVM; println("GLLVM load ok")'
```

DRAC route, only after a new method target exists:

```sh
# DRAC clusters: Narval/Nibi/Rorqual/Trillium/Fir as appropriate.
# Never run compute on login nodes; use sbatch/salloc.
# Put depot/results on /project, not /scratch.
module load StdEnv/2023 >/dev/null 2>&1 || true
module load julia/1.10.10 >/dev/null 2>&1 || true
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
```

Totoro route, only for quick diagnostics and under the shared cap:

```sh
SOCK="$HOME/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22"
ssh -S "$SOCK" -o ControlMaster=no -o BatchMode=yes totoro 'hostname; nproc'
# keep <= 100 total user cores, usually much lower; pin OPENBLAS_NUM_THREADS=1
```

Important: this handoff and the AGENTS snapshot edit are local in
`/private/tmp/gllvmjl-phylo-xlv`. The handover protocol normally asks for a
commit + PR, but GLLVM.jl has a stricter rule: no code or branch push without
explicit maintainer instruction. Push/open a PR only if Shinichi explicitly asks.
