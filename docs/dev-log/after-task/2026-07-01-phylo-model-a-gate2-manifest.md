# After Task: Phylo Model A Gate 2 Manifest

## Goal

Convert the corrected Gate 1 result into a defensible Gate 2 diagnostic plan
without launching source-specific grammar, PR #127, DRAC claim evidence, or a
same-route bootstrap rescue.

## Implemented

- Amended Gate 1 from a strict no-miss canary to an MCSE-aware selected-entry
  diagnostic.
- Recorded that corrected Gate 1 passes the amended diagnostic rule:
  `97/100 = 0.970`, MCSE `0.0171`, Wilson interval `0.9155` to `0.9897`.
- Locked Gate 2 as a weak-cell diagnostic with entries `14,41,71,8,44`.
- Recorded the Gate 2 dry-run manifest before outcome-producing compute.

## Gate 2 Manifest

```text
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 20
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
host: Totoro diagnostic only unless a tiny local smoke is needed
```

Entry `71` is the old weak-cell sentinel. Entries `14,41,8,44` are deterministic
population-`|B_lv|` rank representatives chosen before any Gate 2 outcomes were
observed.

## Checks

```sh
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_eta_gate2_manifest_params.csv --reps 20 --lambdas 0.5 --n-species 80 --n-sites 200 --K 2 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --params /tmp/phylo_eta_gate2_manifest_params.csv --outdir /tmp/phylo_eta_gate2_dryrun --task-id 8 --methods profile_eta_realized --targets B_lv --b-lv-entries 14,41,71,8,44 --profile-opt-iterations 1000 --iterations 1000 --write-details --truth-init --dry-run
```

Result: parameter writer produced `20` tasks. Dry-run task 8 read
`scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=200`, `K=2`,
`q_lv=1`, `K_phy=1`, `seed=28381215`, and `B_lv` length `80`.

```sh
git diff --check -- docs/dev-log/check-log.md docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/after-task/2026-07-01-phylo-model-a-gate2-manifest.md
```

Result: no whitespace errors.

## Claim Boundary

Gate 2 is still unrun. This manifest authorizes only the Totoro diagnostic. It
does not authorize source-specific `phylo_latent(..., lv = ~ x)`, public support,
PR #127 reopening, package API widening, likelihood changes, DRAC claim evidence,
or non-Gaussian extension.

## Rose Verdict

Rose verdict: PASS WITH NOTES -- the manifest keeps Gate 2 auditable and
prevents silent entry switching.
