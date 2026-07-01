# Phylo Model A next-target design, no compute

Date: 2026-07-01
Status: Gate 0 implemented locally; Gate 1 amended and passed as an MCSE-aware diagnostic; Gate 2 passed on Totoro diagnostic evidence; Gate 3 claim evidence pending
Scope: future non-v1 Gaussian phylo Model A only

## 2026-07-01 Gate 0 Update

Gate 0 is now implemented in the handover worktree. The internal helper
`GLLVM._eta_realized_lv_effects(X_lv, Z_truth, Lambda)` computes the
trait-by-predictor eta-scale realized target from the noiseless
latent-mediated trait surface, and `bench/phylo_xlv_drac_task.jl` can run the
bench-only `profile_eta_realized` selected-entry LR canary.

Local checks were deliberately small:

- `test/test_phylo_eta_realized.jl`: `7/7` passed, including centering,
  orientation, observed-response separation, and malformed-input guards.
- Bench include smoke: `bench-include-ok`, with `profile_eta_realized` listed
  in command help.
- Tiny local one-seed canary: `p=12`, `n_sites=50`, `K=1`, `lambda=1.0`,
  entry `1`, truth-start, fit converged, constrained solve converged, and
  `LR = 0.415558111946 < 3.84145882069`.
- `git diff --check` passed for the Gate 0 code/test files.

This is not Gate 1, Gate 2, Gate 3, source-specific `lv` support, or an R
grammar change. The broad `test/runtests.jl` sweep was interrupted after about
31 minutes while still CPU-bound inside the unrelated zero-inflated/two-part
test path, so the full-suite tally is not available from this slice.

## 2026-07-01 Gate 1 Update

Shinichi approved continuing from Gate 0 into the small local Gate 1
positive-control diagnostic. The run stayed local and did not use Totoro or
DRAC.

Gate 1 design:

- `p = 20`, `n_sites = 300`, `K = 1`, `q_lv = 1`, `K_phy = 1`,
  `lambda = 1.0`, scenario `main`;
- `20` replicates from `seed0 = 20260701`;
- five predeclared entries per replicate: `1, 3, 9, 11, 15`;
- target `B_eta_realized`;
- method `profile_eta_realized`, truth-started, penalty profile engine.

Gate 1 result:

```text
planned selected entries: 100
recorded detail entries: 95
covered/planned: 84/100 = 0.840
covered/recorded: 84/95 = 0.884
covered/usable: 84/87 = 0.966
fit non-convergence: task 3
profile-underconverged tasks: 9, 12, 14, 20
converged LR misses: task 7 entry 9, task 8 entry 9, task 11 entry 11
not-usable detail rows: task 9 entry 9; task 12 entry 9; task 14 entries 1, 3, 9, 15; task 20 entries 9, 11
```

Gate 1 therefore failed its own rule: `20/20` fits converged, `100/100`
selected entries usable, and zero converged LR misses. The failure is
informative because strong entries were mostly stable while weak/near-zero
entries and constrained profile convergence were not.

Operational consequence: Gate 2 and Gate 3 remain held. No Totoro diagnostic
fan-out, DRAC claim run, source-specific R grammar, package API widening, or PR
#127 reopen follows from this evidence.

### Corrected Gate 1 Optimizer-Budget Diagnostic

A follow-up local diagnostic reran the same 20 seeds and same five selected
entries with a larger optimizer budget:

- fit `iterations = 1000`;
- profile truth refit `profile_opt_iterations = 1000`.

This resolved the fit/profile usability failures:

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

The three misses persisted from the first run and are therefore real LR misses,
not an optimizer-budget artifact. They are concentrated in the weak/near-zero
entries: entry 9 covered `18/20`, entry 11 covered `19/20`, and entries 1, 3,
and 15 each covered `20/20`.

Quantitative interpretation: the old zero-miss rule is much stricter than a
nominal 95 percent coverage diagnostic. Under true 95 percent selected-entry
coverage, zero misses among 100 entries has probability `0.95^100 =
0.00592053`, while observing at least `97/100` included truths has probability
`0.25783866`. The corrected run is consistent with nominal selected-entry
coverage, but it does not satisfy the predeclared no-miss canary.

Operational consequence: Gate 2 and Gate 3 remain held until Shinichi approves
an amended Gate 1 rule. The defensible amendment is not to drop weak entries or
claim support; it is to replace the no-miss canary with an MCSE-aware
selected-entry coverage gate and to require the corrected optimizer budget.

### Gate 1 Rule Amendment

Shinichi's 2026-07-01 goal to finish Phylo Model A gates authorizes replacing
the over-strict no-miss canary with the following MCSE-aware diagnostic rule:

- `20/20` fits must converge;
- `100/100` selected-entry profile truth solves must be usable;
- selected-entry truth inclusion must be at least `0.92` at this `n = 100`
  diagnostic denominator;
- MCSE and a Wilson interval must be reported beside the point estimate;
- all converged LR misses must be listed and retained in the denominator;
- host denominators must not be mixed.

Under this amended Gate 1 rule, the corrected optimizer-budget diagnostic
passes locally: `20/20` fits converged, `100/100` selected entries were usable,
and `97/100 = 0.970` selected entries included truth with MCSE `0.0171`
and Wilson interval `0.9155` to `0.9897`. This still does not authorize R
grammar exposure, PR #127 reopening, public source-specific support, or a DRAC
claim run. It only allows the predeclared Gate 2 diagnostic.

### Gate 2 Manifest

Gate 2 is a weak-cell diagnostic, not claim evidence:

```text
family: Gaussian
scenario: main
target: B_eta_realized
method: profile_eta_realized
p: 80
n_sites: 200
K: 2
q_lv: 1
K_phy: 1
lambda: 0.5
replicates: 20
seed0: 20260701
fit iterations: 1000
profile_opt_iterations: 1000
selected entries: 14,41,71,8,44
host: Totoro diagnostic only, unless run locally for a tiny smoke
```

Entry `71` is the sentinel from the old weak-cell canary. The other four
entries are deterministic representatives of fixed population `|B_lv|` ranks
for the p = 80, K = 2 DGP, chosen before any Gate 2 outcome is seen:

| entry | population `B_lv` | absolute-rank note |
| ---: | ---: | --- |
| 14 | -0.0613253653105 | low-effect representative |
| 41 | 0.149014398266 | lower-mid representative |
| 71 | -0.572911690134 | old weak-cell sentinel entry |
| 8 | -0.298707930331 | upper-mid representative |
| 44 | -0.522744674442 | high-effect representative |

The dry-run manifest check read task 8 as p = 80, n_sites = 200, K = 2,
lambda = 0.5, seed `28381215`, and `B_lv` length `80`.

Gate 2 pass rule mirrors amended Gate 1 at this diagnostic denominator:
`20/20` fits converged, `100/100` selected entries usable, selected-entry truth
inclusion at least `0.92`, MCSE reported, all misses listed, and one host
denominator only. Failure parks the arc again. Passing Gate 2 permits planning
Gate 3 DRAC claim evidence, but does not expose source-specific R grammar.

### Gate 2 Result

Gate 2 ran as a Totoro-only diagnostic from clean source commit `41a4120`.
The worktree-local code edits in `src/confint_family.jl` and
`test/test_phylo_xlv.jl` were not part of this run.

Remote result root:

```text
/home/snakagaw/hsq_work/phylo_model_a_gate2_20260701-160537
```

Final reducer:

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

Gate 2 therefore passes the amended diagnostic rule. This is the first
weak-cell evidence that the eta-scale realized/design-conditional
`B_eta_realized` target behaves differently from the retired population-`B_lv`
route. It is still diagnostic evidence only. It does not expose
source-specific R grammar, reopen PR #127, or make a public package support
claim. The only authorized next step is Gate 3 DRAC claim-evidence planning
with seed-matched denominators and MCSE/Wilson reporting.

## Decision

The LV arc should not continue by rerunning the old population-`B_lv` route.
Public source-specific phylo `lv` remains parked for v1. The next defensible
non-v1 design target, if Shinichi chooses to reopen the arc later, is an
eta-scale realized/design-conditional slope target:

```text
B_eta_realized(r) = slope_X(eta_lv_truth(r))
```

where `eta_lv_truth(r)` is the noiseless latent-mediated trait surface in
replicate `r`, and `slope_X(.)` is the multivariate least-squares slope against
the realized centered `X_lv` design for that replicate. This target is
finite-sample and conditional. It is not the old population
`B_lv = Lambda * alpha_lv'` claim, and it is not the observed-response
saturated `Y ~ X_lv` shortcut that already failed the strict direct-slope
canary.

The original version of this note was planning only. The later Gate 0, Gate 1,
and Gate 2 sections above record the approved local/Totoro diagnostics that
followed. The note still does not authorize package API widening, R grammar
exposure, source-specific `lv` support, PR #127 reopening, or a public support
claim.

## Why This Target

The old target failed enough times to close the v1 public route:

- p = 80, K = 2, lambda = 0.5 `bootstrap_basic`: `591/720 = 0.821`.
- Optimistic cancelled-task bound: `671/800 = 0.839`, below the `0.92` gate.
- Task-8 entry-71 `profile_truth`: `LR = 9.99181181962 > 3.84145882069`.
- K = 1 population profile gate: `98/100` selected entries truth-included.
- Observed-response direct-slope target: early positive canaries, then the
  strict K = 1 20-replicate gate failed at `96/100`.

The direct-slope diagnostics were still useful: they showed the finite-sample
realized slope mechanism. But using observed `Y` as the target bakes observation
noise into the truth. The eta-scale realized target is a cleaner non-v1
candidate because it keeps the finite-sample conditional interpretation while
removing sampling noise from the truth definition.

## Mathematical Target

For replicate `r`, let:

- `X_r` be the `n_sites x q` realized predictor matrix used in `X_lv`;
- `Xc_r` be column-centered `X_r`;
- `Z_r` be the latent score truth under the simulated phylo Model A;
- `Lambda_r` be the loading truth under the simulation convention;
- `Eta_lv_r = Z_r * Lambda_r'` be the noiseless latent-mediated trait surface,
  with rows as sites and columns as traits;
- `Etac_lv_r` be column-centered `Eta_lv_r`.

Define the realized eta-scale target as:

```text
Beta_eta_realized_r = (Xc_r' Xc_r)^(-1) Xc_r' Etac_lv_r
```

The stored target should use the same trait-by-predictor orientation as the
existing `B_lv` payload:

```text
B_eta_realized_r = Beta_eta_realized_r'
```

For a selected entry `(trait t, predictor q)`, the profile-LR canary constrains
the fitted `B_lv[t, q]` entry to `B_eta_realized_r[t, q]` and checks whether:

```text
2 * (nll_constrained - nll_mle) <= qchisq(0.95, df = 1)
```

This is a conditional/descriptive target. It should be described as the
eta-scale realized association between `X_lv` and the latent-mediated trait
surface, not as population recovery.

## ADEMP Design

This section follows the ADEMP framework of Morris, White, and Crowther (2019)
and the simulation-reporting checklist of Williams et al. (2024).

### A - Aims

Primary aim: determine whether Gaussian phylo Model A selected-entry profile-LR
intervals can include the eta-scale realized/design-conditional target before
any future non-v1 source-specific `lv` exposure.

Secondary aim: separate three quantities that were previously easy to conflate:
conditional `alpha_lv`, population `B_lv = Lambda * alpha_lv'`, and realized
eta-scale slopes.

Secondary aim: decide whether the realized eta-scale target is scientifically
useful enough to justify a future non-v1 branch, even if it cannot support v1.

### D - Data-Generating Mechanism

Use the existing Gaussian phylo Model A generator and keep the phylogenetic VCV,
latent-loading convention, and seed stream recorded per replicate.

First positive-control regime, only after maintainer approval:

| factor | level |
| --- | --- |
| family | Gaussian |
| target | `B_eta_realized` |
| p | 20 |
| K | 1 |
| n_sites | 300 |
| lambda | 1.0 |
| selected entries | 5 predeclared entries spanning weak and strong loadings |
| diagnostic replicates | 20 |
| host | local or Totoro diagnostic only |

First weak-cell challenge, only after the amended Gate 1 rule passes:

| factor | level |
| --- | --- |
| family | Gaussian |
| target | `B_eta_realized` |
| p | 80 |
| K | 2 |
| n_sites | 200 |
| lambda | 0.5 |
| selected entries | `14,41,71,8,44`; entry 71 is the old sentinel |
| diagnostic replicates | 20 |
| host | Totoro diagnostic only |

DRAC claim evidence is not part of this design slice. If a later diagnostic
passes, use DRAC for seed-matched claim evidence with denominators kept separate
from Totoro unless a future run design explicitly permits pooling.

### E - Estimands

Target in: `B_eta_realized_r`, stored per replicate before fitting and computed
from the noiseless latent-mediated trait surface.

Diagnostics only:

- `alpha_lv`: conditional axis/access-effect output under the fitted loading
  convention; Wald display is acceptable but not the Model A target.
- population `B_lv`: old target; remains blocked for v1 and is not reopened by
  this note.
- observed-response direct slope: diagnostic comparator only, not the target.

### M - Methods

Included:

- unconstrained Gaussian phylo Model A point fit;
- selected-entry profile-LR constrained to `B_eta_realized_r[t, q]`;
- direct saturated `Y ~ X_lv` and eta-scale slope comparators for diagnostics.

Excluded:

- bootstrap, Wald, t-Wald, percentile, endpoint profile repeats for the old
  target;
- source-specific R grammar;
- non-Gaussian families;
- mixed-family vectors;
- any Totoro/DRAC production fan-out before a target/gate sign-off.

### P - Performance Measures

Canary-level measures:

- fit convergence;
- constrained convergence;
- selected-entry truth inclusion under the one-df LR cutoff;
- maximum LR among selected entries;
- count of converged misses;
- fit time and host provenance.

Aggregate measures, only after the canary passes:

- selected-entry coverage with MCSE;
- bias and RMSE of fitted `B_lv` against `B_eta_realized`;
- failed-fit and failed-profile rates;
- host-separated denominators.

Coverage MCSE target: for a later claim run, use at least `n = 500` replicates
per cell if the endpoint is coverage, giving MCSE near 1 percent for nominal
95 percent coverage. A 20-replicate diagnostic is only a stop/go canary, not a
coverage estimate.

## Minimal Evidence Gate

Gate 0 - design complete and locally implemented:

- this note exists;
- truth formula is implemented in `src/lv_targets.jl` and wired to the bench
  `profile_eta_realized` helper;
- `test/test_phylo_eta_realized.jl` checks orientation and centering against an
  independent dense calculation.

Gate 1 - positive-control diagnostic:

- 20/20 fits converge;
- 100/100 selected entries usable if five entries are selected per replicate;
- selected-entry coverage at least 0.92 at the n = 100 diagnostic denominator;
- MCSE and Wilson interval reported;
- all converged LR misses listed, with no denominator pruning;
- no mixed host denominators.

Status on 2026-07-01: failed locally with `84/100` planned entries covered,
one fit non-convergence, four profile-underconverged tasks, and three
converged LR misses. This failure blocks Gate 2/3.

Corrected optimizer-budget status on 2026-07-01: same seeds and entries with
`iterations = 1000` and `profile_opt_iterations = 1000` produced `20/20` fit
convergence, `100/100` usable profile solves, and `97/100` selected-entry
coverage. Under the amended MCSE-aware rule above, Gate 1 is passed for the
limited purpose of running Gate 2.

Gate 2 - weak-cell diagnostic:

- task-8 entry-71 is included;
- entries are locked as `14,41,71,8,44`;
- 20/20 fits converge;
- 100/100 selected entries are usable;
- selected-entry coverage is at least 0.92 at the n = 100 diagnostic denominator;
- MCSE and Wilson interval are reported;
- all misses are listed, with no denominator pruning.

Gate 3 - claim evidence, not authorized here:

- DRAC seed-matched run only;
- `n >= 500` per approved cell for coverage claim;
- MCSE reported beside every aggregate;
- Rose wording audit before any R grammar discussion.

Failure at Gate 1 or Gate 2 returns the arc to v1 parking and no grammar
exposure. Passing Gate 1 or Gate 2 does not itself expose anything.

## Williams 11-Item Self-Audit

| item | status | note |
| --- | --- | --- |
| 1. Aims | covered | Aims are named above. |
| 2. Data-generating mechanism | covered for design | DGP factors are listed; exact generator is the existing bench generator. |
| 3. Estimands | covered | `B_eta_realized` is defined; excluded targets are explicit. |
| 4. Methods | covered | Included and excluded methods are listed. |
| 5. Performance measures | covered | Canary and aggregate measures are defined. |
| 6. Software details | deferred | Must be recorded by the future runner; no compute here. |
| 7. Code availability | Gate 0 covered | `src/lv_targets.jl`, `test/test_phylo_eta_realized.jl`, and the bench `profile_eta_realized` route are recorded; future Gate 1 run manifests still need exact paths/seeds. |
| 8. Execution details | deferred | Host, Julia version, seeds, and paths belong to the future run manifest. |
| 9. Worked example | not applicable yet | No public example until the target passes gates. |
| 10. Results reporting | deferred | Future tables must include failures and host-separated denominators. |
| 11. MCSE | covered for planning | MCSE target is defined; not estimated in this no-compute slice. |

## Council Roles

- Ada: hold v1 parking and prevent scope creep.
- Fisher: own the eta-scale realized target and profile-LR interpretation.
- Curie: own Gate 1/2 selected-entry diagnostics after the Gate 0
  orientation/centering unit test.
- Grace: keep compute idle after the Gate 1 failure; Totoro/DRAC only return
  after a new method decision and maintainer approval.
- Rose: block "partial support" wording.
- Boole/Hopper: stay on standby; no R grammar or bridge widening until evidence
  passes.

## Current Operating Rule

No further compute follows from this note. Gate 0 target plumbing exists, and
the corrected local Gate 1 diagnostic is promising at `97/100`, but the
predeclared no-miss Gate 1 failed. The next legitimate task is not Gate 2/3
scale-up; it is a maintainer decision on whether to amend Gate 1 to an
MCSE-aware selected-entry coverage gate with the corrected optimizer budget, or
to keep Phylo Model A source-specific `lv` parked. Totoro and DRAC remain idle
for this arc until that decision.
