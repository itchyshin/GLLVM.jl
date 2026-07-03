# Phylo Model A realized direct-slope ADEMP gate

Date: 2026-07-01
Status: bench-only diagnostic target; no public support claim
Scope: Gaussian direct/native phylo Model A, realized/sampling-conditional target

This note follows ADEMP (Morris, White & Crowther 2019) and the Williams et al.
2024 transparent-reporting checklist for simulation studies. It is a design gate
for a changed target, not a production compute plan.

## A - Aims

Primary aim: test whether the fitted phylo Model A likelihood can include a
realized direct-slope target before any public source-specific `lv` exposure.

Secondary aim: separate a descriptive finite-sample association target from the
failed population `B_lv = Lambda * alpha_lv'` coverage claim.

## D - Data-Generating Mechanism

Use the existing Gaussian Model A generator:

```text
z_total[s, :] = X_lv[s, :] * alpha_lv + z_innovation[s, :]
eta[:, s]    = Lambda_B * z_total[s, :] + phi
phi          ~ N(0, (Lambda_phy * Lambda_phy') .* Sigma_phy)
Y[:, s]      ~ N(eta[:, s], sigma_eps^2 I)
```

Candidate diagnostic cells:

| Factor | Diagnostic levels |
| --- | --- |
| scenario | `main` first |
| lambda | `0.5` first |
| n_species | `5` smoke, then `20`, then known failed `80` rows only if smoke passes |
| n_sites | `60` smoke, then `200` |
| K | `1` smoke, then selected K = 2 failed rows only if K = 1 remains stable |
| q_lv | `1` first |
| K_phy | `1` first |

The first run is local diagnostic only. Totoro is allowed only for small
diagnostics after the target is locked. DRAC remains claim-only and seed-matched
after a local canary passes.

## E - Estimands

The changed target is the realized direct slope from a saturated per-trait
Gaussian regression of simulated responses on the realized `X_lv` design:

```text
D = [1  X_lv]
Gamma_direct = coef(D \ Y')
B_direct[t, c] = Gamma_direct[c + 1, t]
```

The vector order is the same as `vec(B_lv)`: trait-major within each `X_lv`
column. The estimator being profiled is still the fitted Model A product
`B_hat = extract_lv_effects(fit)`, but the truth for the canary is
`vec(B_direct)` rather than population `vec(Lambda_B * alpha_lv')`.

This target is sampling-conditional and descriptive. It asks whether the
structured Model A likelihood includes the realized `Y ~ X_lv` association. It
does not claim recovery of the population latent trait/loading product.

## M - Methods

Included:

- `profile_direct_slope`: bench-only method in `bench/phylo_xlv_drac_task.jl`.
  It computes `B_direct`, constrains selected `B_lv` entries to that target, and
  records one-df LR truth inclusion.
- `profile_truth`: retained for population `B_lv` canaries and negative
  evidence, not reused as support for the changed target.
- direct saturated-slope details in per-entry CSVs when `--write-details` is
  requested.

Excluded:

- bootstrap, percentile bootstrap, `bootstrap_basic`, Wald/t-Wald rescue, and
  endpoint-profile fan-out;
- source-specific R grammar exposure;
- DRAC production sweeps before a local selected-entry canary passes.

## P - Performance Measures

Diagnostic gate:

- selected-entry LR truth inclusion:
  `2 * (nll_constrained(B_lv = B_direct) - nll_mle) <= qchisq(0.95, 1)`;
- constrained-solve convergence and `ci_status`;
- absolute and RMSE distance between `B_hat` and `B_direct`;
- per-entry detail rows with `estimate`, `truth`, `lr_deviance`, and
  `lr_cutoff`;
- wall time for fit and canary.

Promotion gate, if Shinichi authorizes it later:

- predeclared selected entries including known failed task-8 entry 71;
- no converged selected-entry misses in the first diagnostic wave;
- aggregate only after the selected-entry canary passes;
- MCSE reported for every aggregate;
- host denominators not mixed unless explicitly designed.

## Current Smoke

Local bench-only smoke:

```text
output: /tmp/phylo_xlv_direct_slope_smoke
cell: main, lambda = 0.5, n_species = 5, n_sites = 60, K = 1, q_lv = 1, K_phy = 1
method: profile_direct_slope
entries: 2,4
fit: converged, 25 iterations
usable entries: 2/2
truth included: 2/2
LR values: 0.0895416648327, 1.60222512548
cutoff: 3.84145882069
target label: B_lv_direct_slope
```

Interpretation: the diagnostic method works end to end on a tiny local smoke.
It does not validate the target, does not reopen the old population route, and
does not permit source-specific `lv` exposure.

## Local Diagnostic Canaries

K = 1 positive-control canary:

```text
output: /tmp/phylo_xlv_direct_slope_k1_5seed
cell: main, lambda = 0.5, n_species = 20, n_sites = 200, K = 1, q_lv = 1, K_phy = 1
method: profile_direct_slope
entries: 1,5,10,15,20
fits: 5/5 converged
usable entries: 25/25
truth included: 25/25
max LR: 3.65953749216
cutoff: 3.84145882069
target label: B_lv_direct_slope
```

Known failed-row canary under the changed target:

```text
output: /tmp/phylo_xlv_direct_slope_task8_entry71_20260701
cell: main, lambda = 0.5, n_species = 80, n_sites = 80, K = 2, q_lv = 1, K_phy = 1
task: 8, seed = 202614420856
method: profile_direct_slope
entry: 71, term = B_lv[71,1]
fit: converged, 235 iterations
estimate: -0.212294346248
direct-slope target: -0.220447386197
LR: 0.00569099997301
cutoff: 3.84145882069
truth included: yes
```

K = 1 20-replicate promotion diagnostic:

```text
output: /tmp/phylo_xlv_direct_slope_k1_20rep_20260701
cell: main, lambda = 0.5, n_species = 20, n_sites = 200, K = 1, q_lv = 1, K_phy = 1
seed0: 20260702
method: profile_direct_slope
entries: 1,5,10,15,20
fits: 20/20 converged
usable entries: 100/100
truth included: 96/100
entry coverage: 0.960 (MCSE 0.0196)
misses: 4 converged selected entries
max LR: 6.66143949118
cutoff: 3.84145882069
target label: B_lv_direct_slope
```

Misses:

| task | rep | seed | entry | term | estimate | direct-slope target | LR |
| ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| 7 | 7 | 27340929 | 5 | `B_lv[5,1]` | -0.141132756958 | -0.0896177522692 | 5.65080204201 |
| 10 | 10 | 30370959 | 5 | `B_lv[5,1]` | -0.144284593088 | -0.0888739640536 | 6.66143949118 |
| 16 | 16 | 36431019 | 5 | `B_lv[5,1]` | -0.139598210616 | -0.0894642329239 | 5.43956667108 |
| 17 | 17 | 37441029 | 20 | `B_lv[20,1]` | -0.110154156887 | -0.0654424555058 | 5.62375223457 |

Interpretation: the realized/sampling-conditional target passed the tiny smoke,
the K = 1 five-seed selected-entry canary, and the old failed task-8 entry-71
row, but the K = 1 20-replicate promotion diagnostic fired the predeclared
stop rule with four converged selected-entry misses. Aggregate coverage
`96/100` is compatible with nominal 95% coverage at this small denominator, but
the stricter no-miss canary was not met. This is not public support for
source-specific phylo `lv` and not recovery of population `B_lv`.

## Williams 11-Item Self-Audit

| Item | Covered here? | Note |
| --- | --- | --- |
| 1. Aims | yes | Primary and secondary aims stated. |
| 2. DGP | yes for diagnostic | Existing Gaussian Model A DGP stated. |
| 3. Estimands | yes | `B_direct` and fitted `B_hat` are separated from population `B_lv`. |
| 4. Methods | yes | `profile_direct_slope` named; bootstrap and grammar excluded. |
| 5. Performance measures | yes | LR inclusion, convergence, RMSE, details, wall time. |
| 6. Software/session | partial | Local output path recorded; no production session bundle. |
| 7. Code availability | partial | Bench runner path recorded; branch remains local. |
| 8. Results availability | partial | Smoke output is in `/tmp`, not durable claim evidence. |
| 9. Applied example | no | Not required for this diagnostic gate. |
| 10. Results reporting | yes for diagnostics | Smoke, K = 1 five-seed, task-8 entry-71, and K = 1 20-replicate counts/LR values recorded. |
| 11. MCSE | partial | K = 1 20-replicate entry coverage was 0.960 with MCSE 0.0196; no promotion-grade aggregate claim. |

## Stop Rules

- Any converged selected-entry miss in the first promotion diagnostic wave stops
  the realized-target route.
- Any attempt to describe `B_direct` as population `B_lv` support fails Rose's
  wording gate.
- Any request to run DRAC before local canaries pass returns to the council.

## Next Minimal Action

The realized-target route is not promoted under the strict canary. The next
defensible options are either (a) retire public source-specific phylo `lv` from
v1, or (b) explicitly revise the estimand/gate before any more compute, for
example a magnitude-qualified realized-slope target or a larger nominal-coverage
simulation with MCSE justification. Do not start bootstrap, endpoint profile,
source-specific R grammar, or production compute.
