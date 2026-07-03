# Codex Recovery Checkpoint - p80 K2 B_lv Wald diagnostic

Date: 2026-06-29 15:20 MDT

## Branch and Status

Branch: `codex/phylo-xlv-drac-launcher-20260628`

Recent committed head before this checkpoint edit:

```sh
5564430 docs: record p80 k2 canary result
4d72e93 docs: record k2 fit-only result
f0513ef docs: record k2 fit-only diagnostic
984dbb4 docs: record k2 canary results
0995f22 docs: checkpoint live k2 canaries
```

Open PR coordination check before editing shared docs:

```sh
gh pr list --state open
# 127 [WIP] feat(phylo): Model A -- predictor scores under phylogenetic trait-covariance + session handover
```

## Changed Files

This checkpoint records the completed p=80,K=2 B_lv-only Wald diagnostic and
should be committed with:

- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-29-152000-codex-phylo-xlv-p80-blv-wald.md`

Dashboard-only files under `/tmp/gllvm-dashboard` were updated to build `r112`
but are not part of this repository commit.

## Commands Already Run

```sh
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=10 PHYLO_XLV_LAMBDAS=0,0.5,1 PHYLO_XLV_N_SPECIES=80 PHYLO_XLV_N_SITES=80 PHYLO_XLV_K=2 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=52384100 PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=wald PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-00:45 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=10 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit'
ssh -o BatchMode=yes rorqual 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455/results'
ssh -o BatchMode=yes rorqual 'seff 14926656 2>/dev/null || true'
```

## Outcomes

Rorqual array `14926656` completed `30/30` p=80,K=2 B_lv-only Wald rows.

| λ | tasks | fit ok | usable entries | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | CI status |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 0 | 10 | 10 | 800 | 0.945 (0.013) | 0.945 | 0.077 | 80.065 | 127.585 | ok |
| 0.5 | 10 | 10 | 800 | 0.870 (0.037) | 0.870 | 0.097 | 199.906 | 118.577 | ok |
| 1 | 10 | 10 | 800 | 0.972 (0.010) | 0.973 | 0.066 | 269.809 | 137.769 | ok |

The run shows compute viability but blocks Wald production. The λ=0.5 cell
undercovers in this diagnostic.

The DRAC task parser currently accepts `wald`, `profile`, and `bootstrap` only.
There is no t-based method wired into `bench/phylo_xlv_drac_task.jl` yet.

## Commands Still Needed

```sh
git diff --check
git add docs/dev-log/check-log.md docs/dev-log/recovery-checkpoints/2026-06-29-152000-codex-phylo-xlv-p80-blv-wald.md
git commit -m "docs: record p80 k2 blv diagnostic"
```

If continuing immediately, inspect the existing CI implementation before
launching more arrays:

```sh
rg -n "confint_lv_effects|profile|bootstrap|wald|level|quantile" src test bench --glob '!docs/node_modules/**'
```

## Next Safest Action

Do not launch production Wald coverage. The next bounded action is one of:

- run a λ=0.5 p=80,K=2 profile/bootstrap comparator with small reps and a small
  bootstrap count to test interval rescue;
- implement a t-style calibration comparator in the B_lv CI path and run the
  same λ=0.5 diagnostic against Wald;
- inspect why λ=0.5 undercovers before adding more compute.

## Maintainer Blocking Question

No immediate blocker for recording this diagnostic. Before production, the
maintainer should decide whether the V1 Model A evidence bar accepts:

- B_lv production only after an interval-rescue method fixes λ=0.5; and
- phylo-signal remaining gated as a separate non-production target.
