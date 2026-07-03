# Phylo Model A narrowed-regime ADEMP gate

Date: 2026-07-01
Status: diagnostic gate failed at 20 replicates
Scope: Gaussian direct/native phylo Model A, narrowed K = 1 population `B_lv`

## Decision

The old p = 80, K = 2, lambda = 0.5 population-`B_lv` target remains blocked
and should not receive bootstrap, Wald/t-Wald, percentile, or endpoint-profile
reruns.

The next defensible non-retirement path is a narrowed Gaussian Model A regime:

```text
K = 1, q_lv = 1, Gaussian Model A, population B_lv = Lambda * alpha_lv'
```

This was not support. It was a candidate target with an ADEMP gate. The
20-replicate diagnostic gate has now fired the stop rule, so the narrowed K = 1
route should not be promoted to source-specific phylo `lv` exposure or DRAC
claim evidence.

## Local Diagnostics

One small local `profile_truth` scout was run to check whether a narrowed K = 1
target is worth specifying:

- scenario: `main`;
- lambda: `0.5`;
- n_species: `20`;
- n_sites: `200`;
- K: `1`;
- q_lv: `1`;
- K_phy: `1`;
- seed: `21280868`;
- entries: `1,5,10,15,20`;
- method: `profile_truth`;
- bootstrap: none.

Initial run:

- fit converged: `true`, 112 iterations;
- selected entries usable: `4/5`;
- usable entries covered truth: `4/4`;
- entry 5 underconverged at `--profile-opt-iterations 160`.

Entry-5 retry:

- `--profile-opt-iterations 500`;
- converged: `true`;
- `LR = 0.0686506851789 < 3.84145882069`;
- covered truth.

Combined interpretation: five selected K = 1 entries included truth after the
underconverged entry was retried. This is a feasibility diagnostic only. It has
one seed, one cell, selected entries, and no MCSE, so it cannot support exposure
or public coverage language.

The first local diagnostic wave then repeated this pattern with five seeds:

- scenario: `main`;
- lambda: `0.5`;
- n_species: `20`;
- n_sites: `200`;
- K: `1`;
- q_lv: `1`;
- K_phy: `1`;
- seeds: `21280868`, `22290878`, `23300888`, `24310898`, `25320908`;
- entries per seed: `1,5,10,15,20`;
- method: `profile_truth`;
- bootstrap: none.

Wave result:

- fits converged: `5/5`;
- selected entries usable: `25/25`;
- selected entries included truth: `25/25`;
- LR range: `2.65627995759e-05` to `2.54639208502`;
- LR cutoff: `3.84145882069`;
- mean selected-entry LR: `0.45583577218`;
- max-LR row: task 1, seed `21280868`, entry 20, `B_lv[20,1]`.

Interpretation: the positive-control K = 1 pattern repeated across five local
seeds, but this remains diagnostic evidence only. It is not a coverage claim,
has no promotion-grade MCSE, and does not unblock source-specific phylo `lv`.

The predeclared 20-replicate diagnostic wave was then run locally with the same
cell and selected entries:

- scenario: `main`;
- lambda: `0.5`;
- n_species: `20`;
- n_sites: `200`;
- K: `1`;
- q_lv: `1`;
- K_phy: `1`;
- entries per seed: `1,5,10,15,20`;
- method: `profile_truth`;
- bootstrap: none;
- output directory: `/tmp/phylo_model_a_k1_diag20_20260630_220930`.

Wave result:

- fits converged: `20/20`;
- selected entries usable: `100/100`;
- selected entries included truth: `98/100`;
- mean task coverage: `0.980` with MCSE `0.014`;
- entry coverage: `0.980`;
- LR range: `2.65627995759e-05` to `5.14288022148`;
- LR cutoff: `3.84145882069`;
- mean selected-entry LR: `0.630993528174`;
- average fit time: `3.954s`;
- average selected-entry canary time: `5.616s`.

The two misses were both usable, `ci_status = ok`, and converged:

| Task | Rep | Seed | Entry | Term | Estimate | Truth | LR |
| ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| 15 | 15 | 35421008 | 10 | `B_lv[10,1]` | -0.461291546426 | -0.355095269986 | 4.94199940694 |
| 19 | 19 | 39461048 | 20 | `B_lv[20,1]` | -0.234136406101 | -0.171615120502 | 5.14288022148 |

Interpretation: the K = 1 positive-control pattern did not survive the
20-replicate stop rule. This is still a small diagnostic wave, not calibrated
coverage evidence, but it is sufficient to stop K = 1 same-route scaling.

## ADEMP Gate

### A - Aims

Primary aim: evaluate whether a narrowed Gaussian phylo Model A regime with
`K = 1` can produce calibrated profile-LR truth inclusion and coverage for
population `B_lv`.

Secondary aim: determine whether any success is robust to phylogenetic signal,
species count, and selected trait-entry magnitude rather than depending on one
easy seed.

### D - Data-Generating Mechanism

Use the existing Gaussian direct/native Model A generator:

```text
z_total[s, 1] = X_lv[s, 1] * alpha_lv[1, 1] + z_innovation[s, 1]
eta[:, s]    = Lambda[:, 1] * z_total[s, 1]
Y            ~ Gaussian Model A with trait-axis phylogenetic covariance
```

Candidate cells:

| Factor | Levels |
| --- | --- |
| K | 1 only |
| q_lv | 1 only |
| n_species | 20, 80 |
| n_sites | 200, 400 |
| Pagel lambda | 0, 0.5, 1 |
| scenario | main only for the first gate |

Replicates must be chosen by MCSE target. For promotion-grade coverage, a
future redesigned target would need at least 500 valid replicates per final cell
for coverage MCSE near 1 percentage point at nominal 0.95. This K = 1 candidate
does not reach that stage because the 20-replicate diagnostic wave already
missed truth on converged selected-entry canaries.

### E - Estimands

Primary estimand:

```text
B_lv[t, 1] = Lambda[t, 1] * alpha_lv[1, 1]
```

Estimator output:

- point estimate from the fitted Gaussian Model A route;
- selected-entry `profile_truth` LR diagnostic at known simulation truth;
- later, profile-LR endpoint intervals only if truth-inclusion canaries pass.

Non-estimand:

- `alpha_lv` remains an axis/access-effect coefficient with conditional Wald
  output only. It is not the narrowed-regime coverage target.

### M - Methods

Included:

- `profile_truth` selected-entry canary;
- profile-LR endpoint intervals only after canary pass on a future redesigned
  target;
- Wald as a comparator, not a promotion route.

Excluded:

- bootstrap, percentile bootstrap, `bootstrap_basic`, t-Wald as rescue routes;
- source-specific R grammar exposure;
- K = 2 promotion under this gate.

### P - Performance Measures

Gate diagnostics:

- constrained-solve convergence rate;
- truth-inclusion rate for selected profile canaries;
- LR deviance distribution relative to `qchisq(0.95, 1)`;
- point-estimate bias and RMSE for `B_lv`;
- wall time per fit and per canary.

Promotion diagnostics:

- coverage of profile-LR intervals with MCSE reported;
- failure/convergence rate reported in denominators;
- host provenance separated: local/Totoro diagnostics versus DRAC claim
  evidence.

## Williams 11-Item Self-Audit

| Item | Covered Here? | Note |
| --- | --- | --- |
| 1. Aims | yes | Primary and secondary aims stated. |
| 2. DGP | partial | Model and candidate factors stated; parameter magnitudes remain inherited from the runner. |
| 3. Estimands | yes | Population `B_lv` named; `alpha_lv` excluded from coverage target. |
| 4. Methods | yes | `profile_truth` canary first; bootstrap excluded. |
| 5. Performance | yes | Convergence, truth inclusion, LR, bias/RMSE, wall time, coverage. |
| 6. Software/session | partial | Local command path and temporary output directory recorded; no production session bundle. |
| 7. Code availability | partial | Existing bench runner path named by repo context. |
| 8. Data/results availability | partial | Local diagnostic output path recorded; not a durable claim artifact. |
| 9. Applied example | no | Not required for this gate. |
| 10. Results reporting | yes for diagnostic | Local scout, 5-seed wave, and 20-replicate stop-rule wave recorded. |
| 11. MCSE | partial | Diagnostic mean-coverage MCSE recorded; no promotion-grade coverage MCSE. |

## Stop Rules

- Fired: the first 20-replicate diagnostic wave produced two converged
  selected-entry truth-inclusion misses. Stop K = 1 same-route scaling.
- If a selected-entry canary in the first 20-replicate diagnostic wave misses
  truth after a converged constrained solve, stop and return to v1 retirement or
  structural redesign.
- If constrained-solve convergence is below 90% in the diagnostic wave, stop and
  fix the profile machinery before any coverage claim.
- If K = 1 passes but K = 2 remains failed, advertise only the narrowed K = 1
  regime after full evidence and keep K = 2 fail-loud.

## Next Minimal Action

Do not launch production compute. Do not scale K = 1 selected-entry profile,
bootstrap, Wald, t-Wald, percentile, or endpoint-profile reruns. The next
admissible action is a structural decision: either name a different estimand or
regime with a fresh ADEMP gate, or retire source-specific phylo `lv` from v1
while keeping point/diagnostic plumbing local.
