# After Task: phylo X_lv bootstrap-basic aggregate and direct-slope diagnosis

**Date**: `2026-06-30`
**Executed by**: Codex, live DRAC/Totoro lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Finish the weak-cell interval-rescue diagnostic for phylo Model A `B_lv` before
moving the LV arc toward public `gllvmTMB` source-specific `lv = ~ x` coverage.

## 2. Implemented

Recorded the final `bootstrap_basic` aggregate from the valid DRAC rows, stopped
redundant jobs, and documented the direct saturated-slope comparator. Updated
the phase snapshot and Design 73 so the project now says the truth plainly:
phylo Model A direct/native plumbing exists locally, but the p=80, K=2,
lambda=0.5 `B_lv` interval gate is blocked.

## 3a. Decisions and Rejected Alternatives

I rejected `bootstrap_basic` as a rescue path. It covered `591/720 = 0.821`
across 9 valid DRAC seeds, and even a perfect cancelled task 1 would only reach
`671/800 = 0.839`, below the 0.92 working gate.

I treated the Totoro direct-slope output as a broad stress check only, because
Julia 1.12 produced a different RNG stream than the DRAC Julia 1.10 rows. The
Narval Julia 1.10.10 direct-slope job is the seed-matched evidence.

I did not submit a Trillium job. Trillium was available, but its relevant
partitions reserve whole 192-core nodes, which would violate the maintainer's
current shared-core cap for this diagnostic.

## 4. Files Touched

- `AGENTS.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/src/changelog.md`
- `docs/src/model.md`
- `src/postfit.jl` (docstring only)
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-aggregate.md`

## 5. Checks Run

Pre-edit and rule checks:

```sh
sed -n '1,220p' /Users/z3437171/shinichi-brain/AGENTS.md
sed -n '1,220p' /Users/z3437171/shinichi-brain/memory/00-INDEX.md
sed -n '1,260p' /Users/z3437171/shinichi-brain/protocols/after-task.md
git status --short --branch
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- AGENTS.md CLAUDE.md README.md ROADMAP.md CHANGELOG.md docs/design docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl
```

Cluster state and result checks:

```sh
ssh -o BatchMode=yes nibi 'squeue -u "$USER" -j 16988973 -o "%.18i %.9P %.20j %.8T %.10M %.6D %R"'
ssh -o BatchMode=yes narval 'squeue -u "$USER" -j 64435762,64442542 -o "%.18i %.9P %.20j %.8T %.10M %.6D %R"'
ssh -o BatchMode=yes rorqual 'squeue -u "$USER" -j 14967239 -o "%.18i %.9P %.20j %.8T %.10M %.6D %R"'
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o ControlMaster=no -o BatchMode=yes totoro 'pgrep -af "phylo_xlv|direct_mean|direct-mean|bootstrap_basic" || true'
ssh -o BatchMode=yes narval 'sacct -j 64435762 --format=JobID,JobName%30,State,Elapsed,ExitCode -P'
ssh -o BatchMode=yes nibi 'sacct -j 16988973 --format=JobID,JobName%30,State,Elapsed,ExitCode -P'
ssh -o BatchMode=yes nibi 'find /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-remaining10-nibi-20260630-164931/results -name "result_*.csv" -maxdepth 1 | sort'
ssh -o BatchMode=yes narval 'find /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-detail367-narval-20260630-160111/results /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-task8-narval-20260630-155803/results -name "result_*.csv" -maxdepth 1 | sort'
ssh -o BatchMode=yes narval 'head -n 3 /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results/direct_result_000001.csv'
git diff --check
rg -n "moves sites|site score|site axis|n_sites|site" docs/design/73-predictor-informed-latent-scores.md docs/src/model.md src/postfit.jl AGENTS.md docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-aggregate.md --glob '!docs/node_modules/**'
julia --project=. -e 'using GLLVM; println("GLLVM load ok")'
```

Direct comparator summary:

```sh
ssh -o BatchMode=yes narval 'for f in /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results/direct_result_*.csv; do tail -n 1 "$f"; done | awk -F, "{printf(\"task %s rep %s mle_slope %.3f ols_slope %.3f mle_rmse %.3f ols_rmse %.3f truth_mean %.3f\\n\",$1,$2,$7,$8,$9,$10,$15)}"'
ssh -o BatchMode=yes narval 'for f in /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results/direct_result_*.csv; do tail -n 1 "$f"; done | awk -F, "BEGIN{n=0; min=999; max=-999} {n++; sm+=$7; so+=$8; rm+=$9; ro+=$10; cm+=$11; co+=$12; if($7<min)min=$7; if($7>max)max=$7} END{printf(\"n=%d mle_slope_mean=%.6f ols_slope_mean=%.6f mle_rmse_mean=%.6f ols_rmse_mean=%.6f mle_corr_mean=%.6f ols_corr_mean=%.6f mle_slope_min=%.6f mle_slope_max=%.6f\\n\",n,sm/n,so/n,rm/n,ro/n,cm/n,co/n,min,max)}"'
```

Results: no active worker jobs remained. Valid `bootstrap_basic` rows covered
`591/720 = 0.821`; all valid rows had `30/30` bootstrap refits converged.
The Narval direct comparator found `mle_slope_mean=1.000455` and
`ols_slope_mean=1.000468`, with task 8 at `0.536` and `0.533` of truth.
`git diff --check` passed. The terminology scan confirmed Design 73's
gllvmTMB-facing prose now says unit; remaining `site` hits are pre-existing
GLLVM.jl-native terminology or literal variable names such as `n_sites`.
The lightweight Julia load check printed `GLLVM load ok`, confirming the
docstring edit parses.

## 6. Tests of the Tests

The diagnostic would have accepted `bootstrap_basic` only if the aggregate could
plausibly clear the 0.92 working gate. The early-stop arithmetic is decisive:
with 9 rows observed at `591/720`, the last row cannot lift the final aggregate
above `0.839`.

The direct comparator tests the mechanism rather than the interval width. If the
problem were only the `B_lv` extractor, the saturated `Y ~ X_lv` slopes would not
track the latent-product slopes so closely. They do track, including the bad
task 8.

## 7a. Issue Ledger

- Found: `bootstrap_basic` is not an interval rescue for the weak cell.
- Found: the direct saturated slope and latent-product slope agree closely,
  making a simple extractor artifact unlikely.
- Found: Totoro is useful for fast stress checks, but Julia-version RNG drift
  means seed-matched public evidence must stay on the same Julia stream as the
  DRAC rows.
- Deferred: choose a new interval target, narrower public boundary, or explicit
  blocked decision for phylo Model A `B_lv`.

## 8. Consistency Audit

Updated Design 73 and the AGENTS phase snapshot so they no longer imply that
phylo Model A has coverage smokes ready to scale. `CLAUDE.md`, `README.md`,
`ROADMAP.md`, `CHANGELOG.md`, and `docs/src` were scanned for the same stale
phrases; the stale public claim was confined to Design 73 and the AGENTS phase
snapshot.

Ayumi's issue comment also exposed a wording risk around `axis_effect` versus
`trait_effect`. I updated the model docs, changelog, and `extract_lv_effects`
docstring to say that `confint_lv_effects()` supplies uncertainty for the
induced trait-scale product `B_lv`, not for raw CLV/axis-effect coefficients
`alpha_lv`. I did not change the API default in this diagnostic closeout,
because switching `extract_lv_effects()` to default to `axis_effect` is a real
user-facing and internal-call cascade decision.

No likelihood, parser, exported API, or default test behavior changed.

## 9. What Did Not Go Smoothly

The first Totoro direct-slope run finished quickly but was not seed-matched
because Julia 1.12 generated different truth values from the DRAC Julia 1.10
stream. I reran the comparator on Narval with Julia 1.10.10.

Some redundant DRAC tasks were still completing when the route became blocked.
I cancelled the remaining Narval, Nibi, Rorqual, and Totoro workers to keep
resource use under the shared cap.

## 10. Known Residuals

The LV arc is not done. The next decision is statistical and product-facing:
either design a defensible interval/regime rule for the phylo Model A weak cell,
or record the block and move public `gllvmTMB` source-specific `lv = ~ x`
exposure to a later arc.

Axis-effect SEs remain a separate gap. Users who want the familiar GLLVM CLV
coefficient table can extract `type=:axis_effect`, but uncertainty for that
table needs a declared loading constraint or rotation convention before it can
be reported honestly. Separately, the API default should likely become
`axis_effect` for user-facing intuition, with the induced trait effect requested
explicitly; that is not part of this closeout patch.

Full `Pkg.test()` was not rerun because this closeout changed documentation and
status only. `git diff --check` and the lightweight Julia package load both
passed.

## 11. Team Learning

Fisher: when a fitted effect is a realised-data slope with large finite-sample
variation, changing bootstrap centering does not create coverage. Grace: fast
Totoro stress checks are valuable, but Julia-version RNG drift must be labelled
before evidence enters a public claim. Rose: mission-control and phase snapshots
must say "blocked" as soon as the arithmetic proves a route cannot clear the
gate.
