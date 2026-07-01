# Phylo Model A next-target design, no compute

Date: 2026-07-01
Status: Gate 0 implemented locally; no Gate 1/2/3 compute authorized
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

This note is planning only. It does not authorize Totoro, DRAC, package API,
R grammar exposure, source-specific `lv` support, PR #127 reopening, or any
large compute.

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

First weak-cell challenge, only if the positive-control regime has no converged
misses:

| factor | level |
| --- | --- |
| family | Gaussian |
| target | `B_eta_realized` |
| p | 80 |
| K | 2 |
| n_sites | 200 |
| lambda | 0.5 |
| selected entries | task-8 entry-71 plus four predeclared entries |
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
- zero converged LR misses;
- no mixed host denominators.

Gate 2 - weak-cell diagnostic:

- task-8 entry-71 is included;
- at least four additional entries are predeclared;
- zero converged LR misses in the 20-replicate selected-entry canary.

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
- Grace: keep compute idle; Totoro diagnostic only after Gate 1 sign-off, DRAC
  only after Gate 2 and maintainer approval.
- Rose: block "partial support" wording.
- Boole/Hopper: stay on standby; no R grammar or bridge widening until evidence
  passes.

## Current Operating Rule

No compute follows from this note. The next legitimate task is to review this
target design, then, only if Shinichi approves, implement the truth extractor
and its small unit test. Totoro and DRAC remain idle for this arc until then.
