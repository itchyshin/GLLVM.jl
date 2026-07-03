# After Task: Phylo x Beta Structural LV S1 Likelihood

## 1. Goal

Prove a private phylo x Beta(logit) x predictor-informed LV S1 likelihood and
one selected-entry `B_eta_realized` profile-LR canary before any compute, R
grammar, bridge, or public support claim.

## 2. Implemented

Added `_phylo_beta_xlv_marginal_loglik`, a truth-startable private point
wrapper, and selected-entry penalty-profile helper for the combined phylo +
Beta(logit) + `X_lv` route. The likelihood jointly integrates site-score
innovations and the augmented phylo random intercept, while the point wrapper
estimates shared Beta precision `phi` as a nuisance. The test proves the
ordinary Beta `X_lv` limit, the phylo-only Beta GLM limit, dense/sparse phylo
equality, malformed interior-response guards, and one finite-endpoint
`B_eta_realized` canary. Nothing was exported.

Implemented claim: phylo x Beta now has private S1 route evidence for one
selected-entry `B_eta_realized` profile canary. It is not public
source-specific `lv` support.

## 3a. Decisions and Rejected Alternatives

Decision: estimate `phi` jointly as a nuisance parameter with packed layout
`[beta; alpha_lv; Lambda_rr; log_phi; log_sigma2_phy]`, and use profile-LR for
the selected `B_eta_realized` entry.

Rejected alternatives:

- Rejected fixed-precision S1 evidence; the Beta row needed an explicit
  precision treatment.
- Rejected public `fit_phylo_beta_xlv`; this is not production evidence.
- Rejected R `phylo_latent(..., lv = ~ env)` grammar; source-specific `lv`
  remains fail-loud.
- Rejected bridge promotion; no R-to-Julia payload route is tested here.
- Rejected Totoro/DRAC launch; no S2 denominator manifest was authorized.

## 3b. Mathematical Contract

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' z_s + a_t
mu[t,s]   = logistic(eta[t,s])
Y[t,s]    ~ Beta(mu[t,s] * phi, (1 - mu[t,s]) * phi)
```

The canary target is the realized/design-conditional link-scale slope:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

`phi` and `sigma2_phy` are nuisance parameters. The canary checks a loose
interior fitted-`phi` guard, but it does not claim source-variance recovery.

## 4. Files Touched

- `src/GLLVM.jl` - includes the private Beta S1 source file.
- `src/phylo_beta_xlv.jl` - private Beta structural-source likelihood, point
  wrapper, and selected-entry profile helper.
- `test/test_phylo_beta_xlv.jl` - reduction anchors, response guards, and
  selected-entry profile canary.
- `docs/design/73-predictor-informed-latent-scores.md` - S1 status and public
  boundary wording.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  - structural-source matrix update.
- `docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s0-target.md`
  - new S0 target note.
- `docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md`
  - new durable S1 decision note.
- `docs/dev-log/check-log.md` - local evidence log.
- `docs/dev-log/after-task/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md`
  - this report.

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_beta_xlv.jl
Phylo x Beta predictor-informed LV S1 likelihood: 13 passed, 0 failed, 0 errored, 5.2s
Phylo x Beta B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 28.2s

julia --project=. --startup-file=no test/test_phylo_gamma_xlv.jl
Phylo x Gamma predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.2s
Phylo x Gamma B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 52.8s

julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.4s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 24.3s

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.3s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 24.5s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.9s

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed
```

JET: not run; no package-wide type-stability gate was part of this private S1
slice.
Allocs: not run; no production hot-path or speed claim is made.
Aqua: not run; no dependency, export, or package metadata changed.
Full `Pkg.test()`: not run; focused structural-source tests were run.
Benchmarks: N/A - private S1 proof tooling, no speed claim.
R parity: N/A - no R grammar, bridge transport, or gllvmTMB parity surface.

## 6. Tests of the Tests

Added `test/test_phylo_beta_xlv.jl`.

Tests-of-tests clauses:

- The likelihood test compares to two neighbouring route limits: ordinary Beta
  `X_lv` as `sigma_phy^2 -> 0`, and phylo-only Beta GLM when `Lambda = 0`.
- The likelihood test compares the augmented sparse phylo block to an
  independent dense leaf-covariance reference.
- The malformed-input checks cover dimension, positive finite `phi`, finite
  strictly interior responses, `X_lv`, `alpha_lv`, and link-family guards.
- The canary checks finite profile endpoints, MLE bracketing, truth inclusion,
  LR below cutoff, constrained error, fitted-`phi` interior status, and
  malformed selected-entry inputs.

## 7a. Issue Ledger

No issue action taken. This is private/local S1 evidence and does not reopen
PR #127, start an R grammar slice, or launch compute.

## 8. Consistency Audit

Patterns run:

```text
rg -n "partial support|ready to expose|bootstrap rescue|source-specific.*support|mixed-family CI|Beta.*Gate 0 only|no S1 likelihood proof|not S1-ready" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md docs/dev-log/check-log.md

rg -n "Beta \| Gate 0 only|Beta.*Gate 0 only|ready to expose|active compute|source-specific.*covered|no S1 likelihood proof|not S1-ready" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md

rg -n "reprecision|Beta\(phi, exp|link = LogLink|LogLink\(\)|positive for Beta|precision = phi|scale = exp|alpha_shape" src/phylo_beta_xlv.jl test/test_phylo_beta_xlv.jl docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md

rg -n "phylo x Beta|_phylo_beta_xlv|B_eta_realized|No public|Totoro|DRAC|source-specific|coverage" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/check-log.md
```

Result: guardrail phrases and historical command lines only. The current-file
stale-status scan returned only the Gate 0 matrix line saying Rose blocks
"ready to expose" wording. The Beta mechanical-mismatch scan returned no hits.
No new "ready", active-compute, source-specific covered, bridge, or
mixed-family CI wording was introduced by the Beta slice.

## 9. What Did Not Go Smoothly

The first copied Beta canary still used Gamma/log-link assumptions; the
likelihood test caught the mismatch. After switching to `LogitLink`, interior
Beta responses, and `mu = logistic(eta)`, the reduction anchors passed.

The first endpoint profile was too slow. Entry 6 gives a small-LR, target-close
canary, and bounded endpoint search keeps the focused test under a minute. The
private Beta helper also accepts constrained refits when the selected-entry
constraint error is below `1e-3`, because Nelder-Mead can satisfy the constraint
before setting the generic convergence flag.

## 10. Known Residuals

- The route is private and dense; production scaling is not proven.
- The canary covers one selected entry only; no ADEMP coverage calibration
  exists.
- The S1 canary is not source-variance recovery evidence.
- No R bridge, source-specific R grammar, mixed-family CI, missing/mask, or
  spatial/animal/kernel transfer is implied.
- Totoro/DRAC evidence still requires an approved manifest with denominators,
  host provenance, MCSE, and stop rules.
- Ordinal structural-source LV remains Gate 0 only.

## Known Limitations

No public `fit_phylo_beta_xlv`, no public `confint_lv_effects` source route,
no `phylo_latent(..., lv = ~ env)`, no bridge transport, no bootstrap rescue,
and no coverage claim were added.

## 11. Team Learning

For bounded-response structural LV, mechanical reuse is helpful only after the
link and support are re-derived; the symbolic table is the guard against a
Gamma-shaped Beta bug.

## Next Command

```sh
julia --project=. --startup-file=no test/test_phylo_beta_xlv.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - private S1 selected-entry finite-endpoint
routing is covered for one stochastic phylo x Beta cell, but every public,
bridge, grammar, compute, source-variance recovery, and coverage claim remains
blocked.
