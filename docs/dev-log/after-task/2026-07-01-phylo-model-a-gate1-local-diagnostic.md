# After Task: Phylo Model A Gate 1 Local Diagnostic

## Goal

Run the small local positive-control Gate 1 diagnostic for the bench-only
`profile_eta_realized` route against `B_eta_realized`, then decide whether Gate
2/3 compute is defensible.

## Implemented

No code or package API changes. This slice ran the existing Gate 0 bench
plumbing locally and recorded the evidence.

## Design

- Gaussian phylo Model A.
- `p = 20`, `n_sites = 300`, `K = 1`, `q_lv = 1`, `K_phy = 1`,
  `lambda = 1.0`, scenario `main`.
- `20` replicates from `seed0 = 20260701`.
- Five predeclared entries per replicate: `1, 3, 9, 11, 15`.
- Target: eta-scale realized/design-conditional `B_eta_realized`.
- Method: selected-entry one-df `profile_eta_realized` LR canary.
- Host: local only. Totoro and DRAC were not used.

## Result

```text
planned selected entries: 100
recorded detail entries: 95
covered/planned: 84/100 = 0.840
covered/recorded: 84/95 = 0.884
covered/usable: 84/87 = 0.966
fit non-convergence: task 3
profile-underconverged tasks: 9, 12, 14, 20
converged LR misses: task 7 entry 9, task 8 entry 9, task 11 entry 11
not-usable detail rows: task 9 entry 9; task 12 entry 9; task 14 entries 1, 3, 9, 15; task 20 entries 9, 11
```

Gate 1 failed. The predeclared pass rule was `20/20` fit convergence,
`100/100` selected entries usable, and zero converged LR misses.

## Checks Run

```sh
julia --project=. --startup-file=no
```

with `bench/phylo_xlv_drac_task.jl` included and `run_task(...)` called across
all 20 local rows using `methods = [:profile_eta_realized]`.

```sh
python3
```

Used the standard library `csv` module to reduce `/tmp/phylo_eta_gate1_local`
result and detail CSV files.

## R-Parity Verdict

N/A. This is bench-only local evidence. It does not change R bridge behavior or
advertise R-user support.

## JET / Allocs / Aqua Verdicts

Not run. No likelihood hot path, exported API, or dependency changed in this
slice.

## Rose Verdict

FAIL, useful failure. Gate 1 does not support a Gate 2 weak-cell diagnostic or a
Gate 3 DRAC claim run. The source-specific phylo `lv` route remains parked, PR
#127 remains closed/blocked, and no "partial support" wording should be used.

## Next Command

Do not launch Gate 2/3 from this evidence. The next valid command is a
documentation/dashboard refresh that records Gate 1 failure and no active
compute.
