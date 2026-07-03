# After-task: phylo X_lv bootstrap-basic parallel race expansion

## Purpose

Use available compute efficiently, including Totoro, to shorten the decision
time for the p=80, K=2, lambda=0.5 `B_lv` weak-cell `bootstrap_basic`
diagnostic while respecting the user's shared-core cap.

## Files changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-parallel-race-expansion.md`

## What changed

No package code changed. I expanded compute only:

- Narval: full 10-seed valid-source diagnostic running across jobs `64432230`,
  `64432317`, and `64435762`.
- Nibi: six-seed valid-source race job `16988973`.
- Totoro: 10 local one-core race processes, pids `1065793`-`1065851`, pinned to
  cores 200-209 with `taskset` and `nice -n 5`.
- Rorqual: first race job `14967092` invalidated because the source checkout was
  stale; fixed-source race job `14967239` queued.

## Validation

Totoro loaded the staged package successfully:

```sh
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes totoro 'cd /home/snakagaw/codex/GLLVM.jl-phylo-xlv-totoro-20260630 && export JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/home/snakagaw/.julia:/home/snakagaw/codex/julia_depot && /home/snakagaw/.juliaup/bin/julia --project=. -e "using Pkg; Pkg.instantiate(); using GLLVM; println(\"totoro GLLVM load ok\")"'
```

Source audit:

```sh
grep -n "function _lv_boot_fns\\|_lv_boot_fns(" src/confint_family.jl bench/phylo_xlv_drac_task.jl
ssh -o BatchMode=yes narval 'grep -n "function _lv_boot_fns\\|_lv_boot_fns(" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/src/confint_family.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl | tail -20'
ssh -o BatchMode=yes nibi 'grep -n "function _lv_boot_fns\\|_lv_boot_fns(" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/src/confint_family.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl | tail -20'
ssh -o BatchMode=yes rorqual 'grep -n "function _lv_boot_fns\\|_lv_boot_fns(" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/src/confint_family.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl | tail -20'
```

Narval, Nibi, and Totoro had the current 5-argument `_lv_boot_fns` definitions.
Rorqual initially had stale 4-argument definitions; I synced `src/`, verified
the 5-argument definitions, and relaunched as fixed-source job `14967239`.

## Claim Boundary

IN: compute parallelization for a diagnostic decision. OUT: no production
coverage claim, no exported API change, no PR #127 push, and no public
gllvmTMB source-specific LV claim. Totoro rows are fast diagnostics because
Totoro uses Julia 1.12.6; DRAC Julia 1.10 rows remain the primary cross-check.

## Next Action

Wait for the first valid complete 10-seed set, summarize with
`bench/phylo_xlv_drac_summarise.jl`, compare against the previous Wald and
percentile-bootstrap detail rows, and update mission control plus this check-log.
