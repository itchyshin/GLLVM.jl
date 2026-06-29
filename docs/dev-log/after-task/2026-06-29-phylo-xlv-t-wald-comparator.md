# After Task: phylo X_lv B_lv t-Wald comparator

**Date**: `2026-06-29`
**Executed by**: Codex, live toolchain lane.
**Branch**: `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

## 1. Goal

Add a Gaussian-only unit-df t-Wald comparator for phylo `X_lv` `B_lv`
intervals and use a bounded DRAC pilot to test whether it rescues the known
p=80,K=2,lambda=0.5 Wald undercoverage before production scaling.

## 2. Implemented

- Added `confint_lv_effects(...; method = :wald_t_unit)` for Gaussian
  `GllvmFit` `B_lv` intervals.
- Reused the same observed-information delta-method SE as `:wald`; only the
  critical value changes to `TDist(max(n_sites - K - 1, 1))`.
- Kept the GLM/non-Gaussian `confint_lv_effects` route rejecting
  `:wald_t_unit`.
- Added DRAC parser and submit-script support for `wald_t_unit`.
- Added ordinary and phylo Gaussian tests that `wald_t_unit` preserves
  estimates/SEs and widens intervals relative to normal Wald.
- Ran a Nibi 10-seed p=80,K=2,lambda=0.5 comparator for `B_lv`.
- Updated the check-log and local mission-control widget with the completed
  result.

## 3a. Decisions and Rejected Alternatives

The comparator is deliberately Gaussian-only. Extending t criticals to GLM
families would require a separate finite-sample derivation and family-specific
coverage evidence, so the GLM method rejects it.

The p=80,K=2,lambda=0.5 DRAC run was used as a decision gate because the
previous 10-rep normal-Wald diagnostic had undercovered there. The result did
not justify production scaling: `wald_t_unit` coverage was 0.845 versus 0.844
for normal Wald, with MCSE 0.058. The next inference rescue remains the
profile/bootstrap canary already running on Rorqual.

No duplicate production or canary arrays were launched after the Nibi result.

## 4. Files Touched

- `src/confint_family.jl`
- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `test/test_lv_ci.jl`
- `test/test_phylo_xlv.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-29-154800-codex-phylo-xlv-t-comparator.md`
- `docs/dev-log/after-task/2026-06-29-phylo-xlv-t-wald-comparator.md`

Out-of-repo local dashboard files were also updated:

- `/tmp/gllvm-dashboard/status.json`
- `/tmp/gllvm-dashboard/version.txt`

## 5. Checks Run

```sh
julia --project=. test/test_lv_ci.jl
```

Passed: `123/123` in `2m37.9s`.

Rerun after the final negative comparator result also passed: `123/123` in
`2m44.5s`.

```sh
julia --project=. test/test_phylo_xlv.jl
```

Passed: `19/19` in `57.3s`.

Rerun after the final negative comparator result also passed: `19/19` in
`1m01.7s`.

```sh
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_t_params.csv --reps 1 --lambdas 0.5 --n-species 20 --n-sites 80 --K 2 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260629 --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_t_params.csv --outdir /tmp/phylo_xlv_t_dry_results --task-id 1 --methods wald,wald_t_unit --targets none --iterations 1 --dry-run
```

Passed: shell syntax, parameter writing, and local dry-run parser acceptance for
`wald,wald_t_unit`.

```sh
ssh -o BatchMode=yes rorqual '... --methods wald,wald_t_unit --targets none --dry-run ...'
```

Passed: remote Rorqual parser accepted `wald_t_unit` after file sync.

```sh
ssh -o BatchMode=yes nibi '... bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results'
```

Passed: Nibi array `16950659` completed with `10/10` fits OK, `800` usable
entries per method, and scheduler exit code `0`. `seff 16950659` reported wall
time `00:07:37`, CPU efficiency `98.25%`, and memory `766.50 MB / 4 GB`.

```sh
git diff --check
python3 -m json.tool /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate.json
```

Passed.

## 6. Tests of the Tests

The tests check the core invariant that the t comparator changes only the
critical value: estimates, SEs, terms, level, and Hessian status match the
normal-Wald result, while interval widths increase. The ordinary Gaussian test
also checks the expected t critical directly with `TDist(max(n - K - 1, 1))`.

The GLM argument-guard test proves the comparator cannot silently become a
non-Gaussian interval claim.

The DRAC dry-runs exercised the method parser before the cluster job, and the
Nibi array exercised the production result-writing and summarising path.

## 7a. Issue Ledger

- Fixed: Gaussian `B_lv` now has a t-critical comparator in the Julia engine.
- Fixed: DRAC method parser and submit help now accept `wald_t_unit`.
- Found: unit-df t critical does not rescue the phylo p=80,K=2,lambda=0.5 weak
  cell; coverage remains about 0.845 in the 10-seed diagnostic.
- Deferred: profile/bootstrap rescue evidence is still pending on Rorqual
  task `14929297_1`.
- Deferred: production `>=500 reps/cell` coverage remains blocked.

## 8. Consistency Audit

Neighbouring method guards were checked so `wald_t_unit` appears only where it
has evidence: Gaussian `confint_lv_effects`, DRAC method parsing, submit help,
ordinary Gaussian tests, and phylo Gaussian tests. The GLM method remains
guarded.

Dashboard and check-log wording were updated to call this a negative diagnostic,
not coverage calibration. No public R grammar or gllvmTMB user-facing claim was
changed.

## 9. What Did Not Go Smoothly

Fir and Totoro still failed non-interactive SSH from this shell even though the
maintainer reported them connected. Rorqual, Nibi, and Narval were usable for
unattended `sbatch`/`squeue`.

An early duplicate Nibi t-comparator task started and was cancelled after 21s;
it wrote zero result files. Rorqual and Narval duplicate backups were cancelled
while pending. This avoided duplicate evidence directories.

The local browser tab was available and verified after the dashboard update:
the page at `http://127.0.0.1:8770/` showed the t-negative state, Nibi job
`16950659`, Rorqual profile canary `14929297`, and the `0.844` / `0.845`
coverage values.

## 10. Known Residuals

- Rorqual `14929297_1` is still running the one-seed profile/bootstrap canary
  for p=80,K=2,lambda=0.5.
- p=80,K=2 `B_lv` production coverage is blocked until an interval method
  passes a bounded rescue diagnostic.
- Phylo-signal intervals remain unusable in current one-seed diagnostics.
- No non-Gaussian, mixed-family, source-specific R grammar, or Model B claim is
  supported by this slice.
- Full `Pkg.test()` was not rerun after this narrow comparator change; the two
  focused test files covering the touched interval paths passed.

## 11. Team Learning

Fisher: t-based coverage was worth testing, but in the phylo weak cell the df is
large enough that the critical value barely differs from normal Wald. Do not
spend production budget scaling it.

Grace: Rorqual, Nibi, and Narval are the reliable unattended DRAC lanes from
this shell; use Fir/Totoro only after access is verified for the exact command
surface Codex can run.

Rose: the mission-control board needs negative evidence as much as green
evidence. This result should stay visible because it prevents the next agent
from relaunching a doomed t-Wald production grid.
