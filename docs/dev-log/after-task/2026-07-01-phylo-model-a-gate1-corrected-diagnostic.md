# After Task: Phylo Model A Gate 1 Corrected Diagnostic

## Goal

Separate optimizer-budget failures from real selected-entry LR misses after the
first Gate 1 `B_eta_realized` local diagnostic failed.

## Implemented

No code, package API, likelihood, or grammar changes. This slice reran the same
local Gate 1 seeds and selected entries with a larger optimizer budget and
recorded the evidence.

## Design

- Gaussian phylo Model A.
- `p = 20`, `n_sites = 300`, `K = 1`, `q_lv = 1`, `K_phy = 1`,
  `lambda = 1.0`, scenario `main`.
- `20` replicates from `seed0 = 20260701`.
- Five predeclared entries per replicate: `1, 3, 9, 11, 15`.
- Target: eta-scale realized/design-conditional `B_eta_realized`.
- Method: selected-entry one-df `profile_eta_realized` LR canary.
- Corrected budget: fit `iterations = 1000`; profile truth refit
  `profile_opt_iterations = 1000`.
- Host: local only. Totoro and DRAC were not used.

## Result

```text
planned selected entries: 100
recorded detail entries: 100
fit convergence: 20/20
profile status: 20/20 ok rows
usable profile truth solves: 100/100
covered/planned: 97/100 = 0.970
MCSE: 0.0171
Wilson 95% interval for selected-entry coverage: 0.9155 to 0.9897
converged LR misses: task 7 entry 9, task 8 entry 9, task 11 entry 11
```

The old no-miss Gate 1 rule still fails. The corrected diagnostic shows the
problem is no longer fit/profile usability; it is the statistical choice of a
zero-miss canary for a nominal 95 percent interval.

## Quantitative Interpretation

For a nominal 95 percent interval, zero misses among 100 entries has probability
`0.95^100 = 0.00592053`. Observing at least 97/100 included truths has
probability `0.25783866` when true coverage is 0.95. The corrected result is
compatible with nominal selected-entry coverage, but it is not compatible with
the predeclared strict no-miss rule.

## Checks Run

```sh
julia --project=. --startup-file=no
```

with `bench/phylo_xlv_drac_task.jl` included and `run_task(...)` called across
all 20 local rows using `methods = [:profile_eta_realized]`,
`iterations = 1000`, and `profile_opt_iterations = 1000`.

```sh
python3
```

Used the standard library `csv` module to reduce
`/tmp/phylo_eta_gate1_corrected` result and detail CSV files.

## R-Parity Verdict

N/A. This is bench-only local evidence. It does not change R bridge behavior or
advertise R-user support.

## JET / Allocs / Aqua Verdicts

Not run. No likelihood hot path, exported API, or dependency changed in this
slice.

## Rose Verdict

PASS WITH NOTES as a diagnostic; FAIL as a strict no-miss gate. The next
defensible step is a maintainer decision on replacing the no-miss Gate 1 canary
with an MCSE-aware selected-entry coverage gate and corrected optimizer budget.
Gate 2/3, Totoro/DRAC, source-specific grammar, and PR #127 remain held.

## Next Command

Do not launch Gate 2/3 from this evidence alone. The next valid action is a
Mission Control refresh that says the corrected local diagnostic is `97/100`
but the original Gate 1 no-miss rule failed.
