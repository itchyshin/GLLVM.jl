# Phylo x Poisson Structural LV S2 Manifest

Date: 2026-07-02
Status: manifest and dry-run only; no compute launched
Scope: first replicated diagnostic plan after the private S1 finite-endpoint route canary

## Decision

Predeclare the next possible phylo x Poisson structural LV diagnostic as a
small Totoro-only S2 run, not a claim run and not an R/API exposure step. The
run is permitted only after explicit maintainer authorization. This note and
`bench/phylo_poisson_xlv_s2_manifest.jl` define the denominator, selected
entries, host role, stop rules, and failure taxonomy before any new outcomes
are generated.

The S2 target remains the link-scale realized/design-conditional estimand:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

The route uses the private Julia helper
`_phylo_poisson_xlv_profile_eta_realized`. It does not create a public fitter,
does not widen `confint_lv_effects`, does not add R bridge transport, and does
not expose source-specific `lv = ~ env`.

## ADEMP Contract

### Aim

Check whether the S1 finite-endpoint selected-entry profile-LR route survives a
small replicated Poisson(log) phylogenetic structural-LV diagnostic. This aims
only to decide whether S3/DRAC claim-evidence planning is worth discussing.

### Data-Generating Mechanism

```text
source: augmented phylogeny, six leaves
family: Poisson(log)
p: 6
n_sites: 28
K: 1
q_lv: 1
K_phy: 1
X_lv: equally spaced from -1 to 1
alpha_lv: 0.45
Lambda: [0.22, -0.18, 0.20, -0.16, 0.14, -0.12]
beta: log.([8.0, 7.5, 7.0, 6.5, 7.2, 6.8])
sigma2_phy: 0.35
epsilon_sd for truth generation: 0.08
replicates: 20
seed0: 20260702
```

This keeps the S2 denominator close to the local S1 canary while adding
replicate variation. It is not a new source-variance recovery design.

### Estimand

The estimand is `B_eta_realized`, computed from the simulated latent-mediated
link-scale surface for each replicate. The selected entries are flattened
`vec(B_eta_realized)` entries:

```text
selected entries: 1, 2, 5
```

The selected entries are predeclared before any S2 outcome is observed. They
cover the strongest positive loading, a negative loading, and a smaller
positive loading in the six-species S1/S2 cell.

### Methods

For each replicate:

1. Simulate `Z_truth = X_lv * alpha_lv + epsilon` and Poisson counts from the
   phylo x Poisson structural LV DGP.
2. Fit the private `_fit_phylo_poisson_xlv` route with truth-started values.
3. Profile the three selected `B_eta_realized` entries with
   `_phylo_poisson_xlv_profile_eta_realized`.
4. Record convergence, endpoint status, finite lower/upper bounds,
   LR-at-truth, truth inclusion, interval width, fitted `sigma2_phy`, and every
   warning/error.

Bootstrap is out of scope for S2. Wald intervals are not the S2 uncertainty
engine.

### Performance Measures

The denominator is:

```text
20 replicates x 3 selected entries = 60 selected-entry profiles
```

The diagnostic can be called green only if all of the following hold on the
single Totoro denominator:

- `20/20` point fits converge;
- `60/60` selected-entry profiles are usable with finite endpoints;
- at least `55/60` selected entries include the realized target;
- MCSE and Wilson interval are reported;
- every miss is retained with task id, entry, LR, endpoint status, and interval;
- no repeated same-entry failure pattern suggests a deterministic route bug;
- if more than half of fitted `sigma2_phy` values are near the boundary
  (`< 1e-8`), S3 planning is held until that behaviour is diagnosed.

Failure does not trigger bootstrap rescue or same-route reruns. It parks this
structural-source non-Gaussian LV route until the estimand, optimiser, or DGP is
redesigned.

## Manifest Preflight

Commands run locally from `/private/tmp/gllvmjl-phylo-xlv`:

```sh
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --reps 20 --seed0 20260702 --selected-entries 1,2,5 --profile-iterations 700 --iterations 250
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --task-id 1 --dry-run
```

Preflight output:

```text
wrote 20 S2 manifest tasks to /tmp/phylo_poisson_xlv_s2_manifest_params.csv
S2 dry-run task 1 / 20
family=poisson_log source=augmented_phylo host=Totoro-diagnostic-only
seed=20260702 p=6 n_sites=28 K=1 q_lv=1
sigma2_phy=0.35 alpha_lv=0.45 epsilon_sd=0.08
Lambda=0.22;-0.18;0.20;-0.16;0.14;-0.12
selected_entries=1;2;5 level=0.95
future budgets: iterations=250 profile_iterations=700 newton=120/1e-10
target=B_eta_realized; method=private _phylo_poisson_xlv_profile_eta_realized
dry-run only: no model fit, no random draw, no Totoro/DRAC launch
```

## Host Policy

Totoro may be used only as the diagnostic host for S2 after explicit
authorization. Use single-threaded workers and keep the host denominator
separate. Do not pool Totoro rows with any future DRAC rows unless a later run
design explicitly permits it. DRAC remains the only candidate for later
seed-matched claim evidence, and only after S2 is green and separately approved.

## Williams-Style Reporting Checklist

1. Aims: covered by this S2 diagnostic aim.
2. DGP: recorded above, including phylogeny/source/family and truth parameters.
3. Estimand: `B_eta_realized`, not population `B_lv` or `alpha_lv`.
4. Methods: private profile-LR selected-entry route; bootstrap excluded.
5. Performance measures: convergence, usability, coverage, LR, interval width,
   and boundary flags.
6. Factors: one tiny weak structural-source cell only.
7. Randomness: `seed0 = 20260702`, 20 deterministic seed rows.
8. Repetitions: 20 x 3 selected-entry profiles.
9. Software: current GLLVM.jl handover worktree; no R bridge.
10. Computational details: Totoro diagnostic only; no current launch.
11. Full results: not applicable yet; no outcome-producing run exists.

## Council Notes

- Ada: S2 is a diagnostic planning gate, not a support claim.
- Fisher: the uncertainty engine is profile-LR; bootstrap cannot rescue a failed
  S2 route.
- Curie: the denominator and selected entries are now auditable before compute.
- Gauss: keep the S2 cell tiny because the current route uses dense/private
  machinery.
- Grace: Totoro is economical for this diagnostic, but DRAC remains separate
  claim-evidence infrastructure.
- Hopper/Boole: no R grammar or bridge transport follows.
- Rose: block "phylo x Poisson supported" and allow only "S2 manifest
  predeclared; no compute launched".

## Rose Verdict

Rose verdict: PASS WITH NOTES - the S2 manifest is specific enough to prevent
outcome-driven drift and keeps compute/public claims blocked. It authorizes no
launch by itself.
