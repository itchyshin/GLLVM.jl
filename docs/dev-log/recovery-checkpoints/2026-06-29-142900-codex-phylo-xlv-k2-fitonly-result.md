# Codex Recovery Checkpoint - K2 fit-only diagnostic result

Date: 2026-06-29 14:29 MDT

## Branch and State

- Worktree: `/private/tmp/gllvmjl-phylo-xlv`
- Branch: `codex/phylo-xlv-drac-launcher-20260628`
- HEAD before this checkpoint commit: `f0513ef docs: record k2 fit-only diagnostic`
- Open PR state: only draft PR #127 is open.
- Dashboard: `/tmp/gllvm-dashboard`, browser URL `http://127.0.0.1:8770/`,
  build `r100`.

## Completed Evidence

The p=125,K=2 all-target canaries completed and are recorded in
`docs/dev-log/check-log.md`:

- Nibi `16933194_1`, lambda=1: not converged after 400 iterations.
- Narval `64343216_1`, lambda=1: fit converged, B_lv usable 125/125, B_lv
  entry coverage 0.808, phylo-signal usable 0/125.
- Rorqual `14916246_1`, lambda=0.5: fit converged, B_lv usable 125/125, B_lv
  entry coverage 0.592, phylo-signal usable 0/125.

The follow-up Rorqual fit-only array `14918100` completed all 20 rows:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258`;
- lambda=0.5: 10/10 fit ok, mean fit seconds 2040.328, max 2627.965;
- lambda=1: 8/10 fit ok, mean fit seconds 2245.286, max 2774.134;
- non-converged lambda=1 rows:
  - task 18, rep 8, seed 49476879, 400 iterations, fit seconds 2623.152;
  - task 20, rep 10, seed 51496899, 400 iterations, fit seconds 2763.200.

## Commands Already Run

```sh
ssh -o BatchMode=yes rorqual '... julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258/results ...'
ssh -o BatchMode=yes rorqual 'seff 14918100 ...'
```

## Next Safest Action

Do not launch the planned `>=500 reps/cell` K=2 production grid at p=125 under
the current all-target design. The evidence supports one of these next slices:

1. smaller K=2 design canary (for example reduce the large-cell boundary);
2. fit robustness work for lambda=1 before intervals;
3. CI-engine work for B_lv Hessian cost and phylo-signal non-PD Hessian before
   any all-target production claim.

K=1 production planning may continue separately if its fit/interval evidence is
already adequate, but K=2 large-cell Model A remains gated.

## Claim Boundary

IN: DRAC launcher and fit-only array mechanics work; p=125,K=2 lambda=0.5 fits
10/10 in this diagnostic; lambda=1 fits 8/10. PARTIAL: K=2 p=125 remains a
diagnostic regime, not a production coverage regime. OUT: no K=2 production
coverage, no phylo-signal coverage, no public full Model A claim.
