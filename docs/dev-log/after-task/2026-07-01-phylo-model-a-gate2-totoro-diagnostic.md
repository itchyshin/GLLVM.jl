# After Task: Phylo Model A Gate 2 Totoro Diagnostic

## Goal

Run the predeclared weak-cell Gate 2 diagnostic for the eta-scale
realized/design-conditional `B_eta_realized` target before any DRAC claim
evidence or R grammar exposure.

## Scope

Diagnostic-only Totoro run from clean source commit `41a4120`.

No source-specific `phylo_latent(..., lv = ~ x)` exposure, package API
widening, PR #127 reopening, likelihood change, bootstrap rescue, or DRAC claim
run happened in this slice.

## Design

```text
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 20
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
host: Totoro only
```

Remote result root:

```text
/home/snakagaw/hsq_work/phylo_model_a_gate2_20260701-160537
```

## Result

```text
result files: 20
detail files: 20
fit convergence: 20/20
profile status: 20/20 ok rows
selected entries: 100
usable profile truth solves: 100/100
covered/planned: 100/100 = 1.000
MCSE: 0.0000
Wilson 95% interval: 0.9630 to 1.0000
LR misses: 0
max LR: 2.67333858328 at task 5 entry 14
LR cutoff: 3.84145882069
```

Per-entry detail:

```text
entry 14: 20/20 covered, max LR 2.67333858328
entry 41: 20/20 covered, max LR 2.26827350234
entry 71: 20/20 covered, max LR 0.414283414571
entry 8:  20/20 covered, max LR 0.47645991293
entry 44: 20/20 covered, max LR 0.273812631152
```

Runtime summary:

```text
fit seconds mean: 467.59, min 298.46, max 664.29
CI seconds mean: 1210.85, min 867.55, max 1921.61
```

## Verdict

Gate 2 passes the amended diagnostic rule. This is positive weak-cell evidence
for the `B_eta_realized` target, not public source-specific `lv` support.

## Rose Audit

PASS WITH NOTES. The result may be described as a passed Totoro diagnostic
gate. Do not call it public support, R parity, a source-specific grammar
contract, or DRAC claim evidence. Gate 3 must use seed-matched DRAC
denominators with MCSE/Wilson reporting before any stronger claim.

## Next Command

Refresh Mission Control, then prepare Gate 3 DRAC claim-evidence design if
Shinichi keeps the goal as all gates 0-3.
