# Codex Recovery Checkpoint - live interval rescue canaries

Date: 2026-06-29 16:28 MDT

## Branch and Status

Branch: `codex/phylo-xlv-drac-launcher-20260628`

Recent commits:

```sh
49cd1ee docs: record bootstrap canary launch
1526827 docs: add t comparator after-task report
ec57a59 feat: add Gaussian B_lv t comparator
64ff1ef docs: record p80 k2 blv diagnostic
5564430 docs: record p80 k2 canary result
```

## Live Jobs

### Nibi bootstrap-only canary

Keep this job:

```text
cluster: nibi
job: 16951694
out: /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606
shape: scenario=main, lambda=0.5, n_species=80, n_sites=80, K=2, q_lv=1, K_phy=1
targets: B_lv
methods: bootstrap
n_boot: 30
latest state: running at 00:18:40 at the 16:28 MDT checkpoint
```

Cancelled duplicate:

```text
cluster: nibi
job: 16951692
out: /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap-nibi-lambda05-rep1-nboot30-20260629-1608
state: CANCELLED by 3143783 after 00:18:38
reason: duplicate bootstrap-only canary
```

### Rorqual profile/bootstrap canary

```text
cluster: rorqual
job: 14929297
out: /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525
shape: scenario=main, lambda=0.5, n_species=80, n_sites=80, K=2, q_lv=1, K_phy=1
targets: B_lv
methods: wald,profile,bootstrap
n_boot: 30
latest state: running in profile CI; no result file yet
known progress:
  fit converged in 178 iterations / 230.94s
  Wald CI started 2026-06-29T21:30:11Z
  Wald CI done 2026-06-29T21:32:55Z
  profile CI started 2026-06-29T21:32:55Z
```

## Commands Still Needed

Poll the active bootstrap canary:

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/logs/phylo_xlv-16951694-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results/result_000001.csv 2>/dev/null || true; seff 16951694 2>/dev/null || true'
```

Poll the profile canary:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/logs/phylo_xlv-14929297-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results/result_000001.csv 2>/dev/null || true; seff 14929297 2>/dev/null || true'
```

## Next Safest Action

Wait for `16951694` first. It is the cleaner one-task bootstrap-only timing
canary. Do not launch production. Do not relaunch duplicate bootstrap jobs.

If `14929297` remains in profile for multiple hours or times out, treat
full-vector profile as computationally impractical for p=80,K=2 unless the
profile implementation is narrowed or batched.

## Claim Boundary

No interval-rescue claim yet. Current evidence says:

- normal Wald undercovers for p=80,K=2,λ=0.5;
- unit-df t-Wald does not rescue it;
- bootstrap and profile are live timing canaries only.
