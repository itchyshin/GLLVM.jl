# Codex Recovery Checkpoint - phylo X_lv p80 K2 canary

Date: 2026-06-29 14:50 MDT

## Branch and Status

Branch: `codex/phylo-xlv-drac-launcher-20260628`

Status before this checkpoint edit:

```sh
git status --short
# clean
```

Recent commits before this checkpoint edit:

```sh
4d72e93 docs: record k2 fit-only result
f0513ef docs: record k2 fit-only diagnostic
984dbb4 docs: record k2 canary results
0995f22 docs: checkpoint live k2 canaries
eddb252 bench: export drac depot before params
```

Open PR coordination check before editing shared docs:

```sh
gh pr list --state open
# 127 [WIP] feat(phylo): Model A -- predictor scores under phylogenetic trait-covariance + session handover
```

## Changed Files

This checkpoint records the p=80,K=2 all-target canary and should be committed
with:

- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-06-29-145000-codex-phylo-xlv-p80-k2-canary.md`

## Commands Already Run

```sh
ssh -o BatchMode=yes rorqual 'seff 14925925 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-all-rorqual-lambda05-1-20260629-1432/results'
ssh -o BatchMode=yes rorqual 'cd /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-all-rorqual-lambda05-1-20260629-1432/results; cat result_*.csv'
```

## Outcomes

Rorqual array `14925925` completed the p=80,K=2 all-target canary in
`00:05:16` representative wall time with exit code `0`.

B_lv rows:

- λ=0.5, seed `42384144`: fit converged in `182` iterations, fit seconds
  `227.259`, B_lv CI seconds `118.293`, usable `80/80`, coverage `1.000`,
  RMSE `0.045`, `pd_hessian=true`.
- λ=1, seed `43384147`: fit converged in `134` iterations, fit seconds
  `173.663`, B_lv CI seconds `117.792`, usable `80/80`, coverage `1.000`,
  RMSE `0.044`, `pd_hessian=true`.

Phylo-signal rows:

- λ=0.5: transformed-Wald usable `0/80`, `ci_status=partial_or_failed`,
  `pd_hessian=false`.
- λ=1: transformed-Wald usable `0/80`, `ci_status=partial_or_failed`,
  `pd_hessian=false`.

Dashboard `/tmp/gllvm-dashboard` is build `r105` and reports the p=80,K=2
result as a B_lv-only candidate. The in-app browser was already pointed at
`http://127.0.0.1:8770/`.

## Commands Still Needed

After this checkpoint:

```sh
git diff --check
git add docs/dev-log/check-log.md docs/dev-log/recovery-checkpoints/2026-06-29-145000-codex-phylo-xlv-p80-k2-canary.md
git commit -m "docs: record p80 k2 canary result"
```

If continuing the DRAC lane, the next bounded diagnostic should be p=80,K=2
B_lv-only, not all-target, and not production scale.

Suggested next diagnostic shape:

- cluster: Rorqual or Narval, depending on queue state;
- `n_species=80`, `n_sites=80`, `K=2`;
- λ grid `{0, 0.5, 1}`;
- `reps=10`;
- `targets=B_lv`;
- `iterations=400`, `time=0-00:45`, `mem=4G`, throttle around `10`.

## Next Safest Action

Commit this record, poll DRAC queue state, then launch at most the bounded
p=80,K=2 B_lv-only diagnostic. Do not launch `>=500 reps/cell` production until
the B_lv-only diagnostic has a multi-seed denominator and the phylo-signal row
has a separate plan.

## Maintainer Blocking Question

No immediate blocking question. The maintainer decision point is whether V1
Model A can split the DRAC claim into:

- B_lv coverage evidence for a bounded p=80,K=2 regime; and
- phylo-signal marked as gated until a different interval target or transform is
  validated.
