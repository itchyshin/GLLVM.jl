# After Task: Phylo x Shared-Cutpoint Ordinal Structural LV S1 Likelihood

## 1. Goal

Prove a private phylo x shared-cutpoint Ordinal(logit) x predictor-informed LV
S1 likelihood and one selected-entry `B_eta_realized` profile-LR canary before
any compute, R grammar, bridge, or public support claim.

## 2. Implemented

Added `_phylo_ordinal_xlv_marginal_loglik`, a truth-startable private point
wrapper, and selected-entry penalty-profile helper for the combined phylo +
shared-cutpoint Ordinal(logit) + `X_lv` route. The likelihood jointly
integrates site-score innovations and the augmented phylo random intercept,
while the point wrapper estimates shared ordered cutpoints as nuisance
parameters. The test proves the ordinary shared-cutpoint Ordinal `X_lv` limit,
dense/sparse phylo equality, malformed category/cutpoint guards, and one
finite-endpoint `B_eta_realized` canary. Nothing was exported.

Implemented claim: phylo x shared-cutpoint Ordinal now has private S1 route
evidence for one selected-entry `B_eta_realized` profile canary. It is not
public source-specific `lv` support and it is not per-trait ordinal bridge
parity.

## 3a. Decisions and Rejected Alternatives

Decision: estimate shared ordered cutpoints jointly as nuisance parameters with
packed layout `[alpha_lv; Lambda_rr; psi_cutpoints; log_sigma2_phy]`, and use
profile-LR for the selected `B_eta_realized` entry.

Rejected alternatives:

- Rejected per-trait ordinal bridge parity; this slice is native Julia
  shared-cutpoint evidence only.
- Rejected a per-trait intercept; shared cutpoints carry the category levels in
  `OrdinalFit`.
- Rejected public `fit_phylo_ordinal_xlv`; this is not production evidence.
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
eta[t,s]  = Lambda[t,:]' z_s + a_t
P(Y[t,s] <= c | eta[t,s]) = logistic(tau[c] - eta[t,s])
```

The canary target is the realized/design-conditional link-scale slope:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

`tau` and `sigma2_phy` are nuisance parameters. The canary checks ordered
cutpoints, but it does not claim source-variance recovery.

## 4. Files Touched

- `src/GLLVM.jl` - includes the private shared-cutpoint Ordinal S1 source file.
- `src/phylo_ordinal_xlv.jl` - private Ordinal structural-source likelihood,
  point wrapper, and selected-entry profile helper.
- `test/test_phylo_ordinal_xlv.jl` - reduction anchors, category/cutpoint
  guards, and selected-entry profile canary.
- `docs/design/73-predictor-informed-latent-scores.md` - S1 status and public
  boundary wording.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  - structural-source matrix update.
- `docs/dev-log/decisions/2026-07-02-phylo-ordinal-structural-lv-s0-target.md`
  - new S0 target note.
- `docs/dev-log/decisions/2026-07-02-phylo-ordinal-structural-lv-s1-likelihood.md`
  - new durable S1 decision note.
- `docs/dev-log/check-log.md` - local evidence log.
- `docs/dev-log/after-task/2026-07-02-phylo-ordinal-structural-lv-s1-likelihood.md`
  - this report.

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_ordinal_xlv.jl
Phylo x shared-cutpoint Ordinal predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 4.6s
Phylo x shared-cutpoint Ordinal B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 21.5s

julia --project=. --startup-file=no test/test_phylo_beta_xlv.jl
Phylo x Beta predictor-informed LV S1 likelihood: 13 passed, 0 failed, 0 errored, 5.7s
Phylo x Beta B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 28.8s

julia --project=. --startup-file=no test/test_phylo_gamma_xlv.jl
Phylo x Gamma predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.5s
Phylo x Gamma B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 53.4s

julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.8s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 24.3s

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.6s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 25.0s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 5.0s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 14.1s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 196 passed, 0 failed, 0 errored, 4m18.4s

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-ordinal-structural-lv-s1-likelihood.md")'
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

Added `test/test_phylo_ordinal_xlv.jl`.

Tests-of-tests clauses:

- The likelihood test compares to the ordinary shared-cutpoint Ordinal `X_lv`
  route as `sigma_phy^2 -> 0`.
- The likelihood test compares the augmented sparse phylo block to an
  independent dense leaf-covariance reference, including the `Lambda = 0`
  phylo-only shared-cutpoint route.
- The malformed-input checks cover dimension, finite strictly increasing
  cutpoints, valid categories, `X_lv`, `alpha_lv`, and link-family guards.
- The canary checks finite profile endpoints, MLE bracketing, truth inclusion,
  LR below cutoff, constrained error, ordered cutpoints, and malformed
  selected-entry inputs.

## 7a. Issue Ledger

No issue action taken. This is private/local S1 evidence and does not reopen
PR #127, start an R grammar slice, promote per-trait ordinal bridge parity, or
launch compute.

## 8. Consistency Audit

Patterns run:

```text
rg -n "partial support|ready to expose|bootstrap rescue|Gate 3 passed|source-specific.*support|mixed-family CI" docs/dev-log/decisions docs/design src test README.md AGENTS.md CLAUDE.md 2>/dev/null || true

rg -n "per-trait ordinal.*support|ordinal bridge.*covered|phylo_latent\(.*lv =" docs/dev-log/decisions docs/design src test README.md AGENTS.md CLAUDE.md 2>/dev/null || true

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
```

Result: guardrail phrases and historical command lines only. The current S0/S1
notes say shared-cutpoint/native Julia evidence and keep per-trait ordinal
bridge parity blocked. Rose pattern scan passed.

## 9. What Did Not Go Smoothly

The ordinal route cannot use the generic `phylo_glm_marginal_loglik` anchor
because ordinal uses vector category probabilities and shared cutpoints rather
than a scalar-mean Distributions family. The proof therefore uses ordinary
shared-cutpoint reduction and an independent dense leaf-covariance reference
instead.

## 10. Known Residuals

- The route is private and dense; production scaling is not proven.
- The canary covers one selected entry only; no ADEMP coverage calibration
  exists.
- The S1 canary is not source-variance recovery evidence.
- Shared-cutpoint native Julia evidence does not imply per-trait ordinal bridge
  parity.
- No R bridge, source-specific R grammar, mixed-family CI, missing/mask, or
  spatial/animal/kernel transfer is implied.
- Totoro/DRAC evidence still requires an approved manifest with denominators,
  host provenance, MCSE, and stop rules.

## Known Limitations

No public `fit_phylo_ordinal_xlv`, no public `confint_lv_effects` source route,
no `phylo_latent(..., lv = ~ env)`, no bridge transport, no per-trait ordinal
CI, no bootstrap rescue, and no coverage claim were added.

## 11. Team Learning

For ordinal structural LV, the shared-cutpoint/no-intercept decision has to be
written before code; otherwise it is too easy to overclaim per-trait ordinal
bridge parity from a native Julia canary.

## Next Command

```sh
julia --project=. --startup-file=no test/test_phylo_ordinal_xlv.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - private S1 selected-entry finite-endpoint
routing is covered for one stochastic phylo x shared-cutpoint Ordinal cell, but
every public, bridge, grammar, compute, per-trait parity, source-variance
recovery, and coverage claim remains blocked.
