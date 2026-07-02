# After Task: Phylo x NB2 Structural LV S1 Likelihood

## 1. Goal

Prove a private phylo x NB2(log) x predictor-informed LV S1 likelihood and one
selected-entry `B_eta_realized` profile-LR canary before any compute, R grammar,
bridge, or public support claim.

## 2. Implemented

Added `_phylo_nb_xlv_marginal_loglik`, a truth-startable private point wrapper,
and selected-entry penalty-profile helper for the combined phylo + NB2(log) +
`X_lv` route. The likelihood jointly integrates site-score innovations and the
augmented phylo random intercept, while the point wrapper estimates shared NB2
dispersion `r` as a nuisance. The test proves the ordinary NB2 `X_lv` limit, the
phylo-only NB2 GLM limit, dense/sparse phylo equality, malformed count guards,
and one deterministic finite-endpoint `B_eta_realized` canary. Nothing was
exported.

Implemented claim: phylo x NB2 now has private S1 route evidence for one
deterministic selected-entry `B_eta_realized` profile canary. It is not public
source-specific `lv` support.

## 3a. Decisions and Rejected Alternatives

Decision: estimate `r` jointly as a nuisance parameter with packed layout
`[beta; alpha_lv; Lambda_rr; log_r; log_sigma2_phy]`, and use profile-LR for
the selected `B_eta_realized` entry.

Rejected alternatives:

- Rejected fixed-`r` S1 evidence; the NB2 row needed an explicit dispersion
  treatment.
- Rejected a public `fit_phylo_nb_xlv`; this is not production evidence.
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
Y[t,s]    ~ NB2(mu = exp(eta[t,s]), dispersion = r)
```

The canary target is the realized/design-conditional link-scale slope:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

`r` and `sigma2_phy` are nuisance parameters. The canary checks a loose
interior fitted-`r` guard, but it does not claim source-variance recovery.

## 4. Files Touched

- `src/GLLVM.jl` - includes the private NB2 S1 source file.
- `src/phylo_nb_xlv.jl` - private NB2 structural-source likelihood, point
  wrapper, and selected-entry profile helper.
- `test/test_phylo_nb_xlv.jl` - reduction anchors, count guards, and
  deterministic profile canary.
- `docs/design/73-predictor-informed-latent-scores.md` - S1 status and public
  boundary wording.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  - structural-source matrix update.
- `docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s0-target.md`
  - new S0 target note.
- `docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s1-likelihood.md`
  - new durable S1 decision note.
- `docs/dev-log/check-log.md` - local evidence log.
- `docs/dev-log/after-task/2026-07-02-phylo-nb2-structural-lv-s1-likelihood.md`
  - this report.

## 5. Checks Run

```text
julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.6s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 19.0s

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.3s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 24.3s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.9s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.7s

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-nb2-structural-lv-s1-likelihood.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed
```

JET: not run; no package-wide type-stability gate was part of this private S1
slice.
Allocs: not run; no production hot-path or speed claim is made.
Aqua: not run; no dependency, export, or package metadata changed.
Benchmarks: N/A - private S1 proof tooling, no speed claim.
R parity: N/A - no R grammar, bridge transport, or gllvmTMB parity surface.
Full `Pkg.test()`: not run; focused structural-source tests were run.

## 6. Tests of the Tests

Added `test/test_phylo_nb_xlv.jl`.

Tests-of-tests clauses:

- The likelihood test compares to two neighbouring route limits: ordinary NB2
  `X_lv` as `sigma_phy^2 -> 0`, and phylo-only NB2 GLM when `Lambda = 0`.
- The likelihood test compares the augmented sparse phylo block to an
  independent dense leaf-covariance reference.
- The malformed-input checks cover dimension, positive finite `r`,
  integer-valued non-negative counts, `X_lv`, `alpha_lv`, and link-family
  guards.
- The canary checks finite profile endpoints, MLE bracketing, truth inclusion,
  LR below cutoff, constrained error, fitted-`r` interior status, and malformed
  selected-entry inputs.

## 7a. Issue Ledger

No issue action taken. This is private/local S1 evidence and does not reopen
PR #127, start an R grammar slice, or launch compute.

## 8. Consistency Audit

Patterns run:

```text
rg -n "partial support|ready to expose|bootstrap rescue|source-specific.*support|mixed-family CI|NB2.*Gate 0 only|no S1 likelihood proof|not S1-ready" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s1-likelihood.md docs/dev-log/check-log.md

rg -n "phylo x NB2|_phylo_nb_xlv|B_eta_realized|No public|Totoro|DRAC|source-specific|coverage" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s1-likelihood.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/check-log.md
```

The scan returned expected guardrail phrases and historical command lines only:
no new "ready", "covered", active-compute, source-specific support, bridge, or
mixed-family CI wording was introduced by the NB2 slice.

## 9. What Did Not Go Smoothly

A source-effect DGP with interior fitted `sigma2_phy` made the NB2 endpoint
profile too slow for the focused local suite. The banked S1 cell therefore uses
the cheaper route canary whose fitted source variance can sit near the lower
boundary. That limitation is explicit and blocks any source-variance recovery
claim.

## 10. Known Residuals

- The route is private and dense; production scaling is not proven.
- The canary covers one deterministic selected entry only; no ADEMP coverage
  calibration exists.
- The S1 canary is not source-variance recovery evidence.
- No R bridge, source-specific R grammar, mixed-family CI, missing/mask, or
  spatial/animal/kernel transfer is implied.
- Totoro/DRAC evidence still requires an approved manifest with denominators,
  host provenance, MCSE, and stop rules.
- Gamma, Beta, and Ordinal structural-source LV remain Gate 0 only.

## Known Limitations

No public `fit_phylo_nb_xlv`, no public `confint_lv_effects` source route, no
`phylo_latent(..., lv = ~ env)`, no bridge transport, no bootstrap rescue, and
no coverage claim were added.

## 11. Team Learning

For dispersion families, S1 can prove route geometry with a cheap profile
canary, but source-variance recovery needs a separate design because endpoint
profiles become expensive quickly.

## Next Command

```sh
julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - private S1 selected-entry finite-endpoint
routing is covered for one deterministic phylo x NB2 cell, but every public,
bridge, grammar, compute, source-variance recovery, and coverage claim remains
blocked.
