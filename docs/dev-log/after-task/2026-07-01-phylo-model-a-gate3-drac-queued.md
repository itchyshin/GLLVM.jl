# After Task: Phylo Model A Gate 3 DRAC Queued

## Goal

Submit the Gate 3 DRAC claim-evidence array after the Gate 2 Totoro diagnostic
passed.

## Scope

Queued DRAC/Nibi claim-evidence run only. No source-specific R grammar exposure,
PR #127 reopening, package API widening, likelihood change, bootstrap rescue, or
public support claim happened in this slice.

## Design

```text
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 500
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
truth_init: yes
write_details: yes
host denominator: DRAC/Nibi only
```

## Remote Locations

```text
source:  /scratch/snakagaw/GLLVM.jl-phylo-model-a-gate3
results: /scratch/snakagaw/phylo_model_a_gate3_20260701-1122
depot:   /scratch/snakagaw/julia_depot_gllvm_gate3
```

The remote source is a clean archive from local commit `97082bd`; local dirty
`src/confint_family.jl` and `test/test_phylo_xlv.jl` edits were not included.

## SLURM

```text
job id: 17049809
array: 1-500%100
host: Nibi
account: def-snakagaw_cpu
state at submission: PENDING (Priority)
time limit: 03:00:00
cpus per task: 1
memory per task: 8G
Julia: 1.10.10
```

## Validation

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(); using GLLVM; println("GLLVM gate3 load ok")'
bash bench/phylo_xlv_drac_submit.sh --out /scratch/snakagaw/phylo_model_a_gate3_20260701-1122
bash bench/phylo_xlv_drac_submit.sh --out /scratch/snakagaw/phylo_model_a_gate3_20260701-1122 --submit
scontrol show job 17049809
```

The write-only manifest produced `500` tasks and the submitted SLURM job showed
`ArrayTaskId=1-500%100`, `Account=def-snakagaw_cpu`, and `Reason=Priority`.

## Rose Audit

PASS WITH NOTES. It is accurate to say Gate 3 is queued. It is not accurate to
say Gate 3 passed, DRAC claim evidence exists, or source-specific phylo `lv` is
supported.

## Next Command

Poll:

```sh
ssh nibi 'squeue -j 17049809 -o "%.30i %.12P %.20j %.8u %.2t %.12M %.6D %R"'
```

When result files appear, reduce only
`/scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results` and keep the
DRAC denominator separate from Totoro Gate 2.
