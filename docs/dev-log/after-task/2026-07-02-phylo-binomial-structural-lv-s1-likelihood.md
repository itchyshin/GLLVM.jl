# After Task: Phylo x Binomial Structural LV S1 Likelihood

## 1. Goal

Prove a private phylo x Binomial(logit) x predictor-informed LV S1 likelihood
and one selected-entry `B_eta_realized` profile-LR canary before any compute,
R grammar, bridge, or public support claim.

## 2. Implemented

Added `_phylo_binomial_xlv_marginal_loglik`, a truth-startable private point
wrapper, and selected-entry penalty-profile helper for the combined phylo +
Binomial(logit) + `X_lv` route. The likelihood jointly integrates site-score
innovations and the augmented phylo random intercept, and the test proves the
ordinary Binomial `X_lv` limit, the phylo-only Binomial GLM limit, dense/sparse
phylo equality, malformed `N`/`Y` guards, and one deterministic
finite-endpoint `B_eta_realized` canary. Nothing was exported.

Implemented claim: phylo x Binomial now has private S1 route evidence for one
deterministic selected-entry `B_eta_realized` profile canary. It is not public
source-specific `lv` support.

## 3a. Decisions and Rejected Alternatives

Decision: keep the route private and tiny, using profile-LR as the main
uncertainty engine and keeping bootstrap out of the S1 proof.

Rejected alternatives:

- Rejected a public `fit_phylo_binomial_xlv`; this is not production evidence.
- Rejected R `phylo_latent(..., lv = ~ env)` grammar; source-specific `lv`
  remains fail-loud.
- Rejected bridge promotion; no R-to-Julia payload route is tested here.
- Rejected Totoro/DRAC launch; no S2 denominator manifest was authorized.
- Rejected response-probability slope targets; the target is link-scale
  `B_eta_realized`.

## 3b. Mathematical Contract

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' z_s + a_t
Y[t,s]    ~ Binomial(N[t,s], logistic(eta[t,s]))
```

The canary target is the realized/design-conditional link-scale slope:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

The constrained refit pins one fitted `vec(Lambda * alpha_lv')[idx]` entry to
candidate values, inverts the one-dimensional profile by bracketing and
bisection, and checks `2 * (nll_constrained - nll_mle) <= qchisq(0.95, 1)` at
the realized target while also requiring `lower < estimate < upper`,
`lower <= target <= upper`, and constrained error below `1e-3`.

## 4. Files Touched

- `src/GLLVM.jl` - includes the private Binomial S1 source file.
- `src/phylo_binomial_xlv.jl` - private Binomial structural-source likelihood,
  point wrapper, and selected-entry profile helper.
- `test/test_phylo_binomial_xlv.jl` - reduction anchors, `N`/`Y` guards, and
  deterministic profile canary.
- `docs/design/73-predictor-informed-latent-scores.md` - S1 status and public
  boundary wording.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  - structural-source matrix update.
- `docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md`
  - S0 page updated to point to the S1 follow-up.
- `docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md`
  - new durable decision note.
- `docs/dev-log/check-log.md` - local evidence log.
- `docs/dev-log/after-task/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md`
  - this report.

## 5. Checks Run

```text
julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.2s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 19.7s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.5s

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md")'
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

Added `test/test_phylo_binomial_xlv.jl`.

Tests-of-tests clauses:

- The likelihood test compares to two neighbouring route limits:
  ordinary Binomial `X_lv` as `sigma_phy^2 -> 0`, and phylo-only Binomial GLM
  when `Lambda = 0`.
- The likelihood test compares the augmented sparse phylo block to an
  independent dense leaf-covariance reference.
- The malformed-input checks cover dimension, positive trial counts,
  integer-valued `N`/`Y`, `Y <= N`, `X_lv`, `alpha_lv`, and link-family guards.
- The canary checks finite profile endpoints, MLE bracketing, truth inclusion,
  LR below cutoff, constrained error, and malformed selected-entry inputs.

## 7a. Issue Ledger

No issue action taken. This is private/local S1 evidence and does not reopen
PR #127, start an R grammar slice, or launch compute.

## 8. Consistency Audit

Patterns run:

```text
rg -n "partial support|ready to expose|bootstrap rescue|Gate 3 passed|source-specific.*support|mixed-family CI|S1 still requires|no S1 likelihood proof|symbolic alignment only" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md docs/dev-log/check-log.md

rg -n "phylo x Binomial|_phylo_binomial_xlv|B_eta_realized|No public|Totoro|DRAC|source-specific|coverage" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/check-log.md
```

The first scan returned expected guardrail phrases and initially found the
older S0 check-log wording that could be read as current status. That entry
was updated to mark itself as historical and superseded by the S1 entry.
The second scan confirmed the Binomial S1 route and no-public/no-compute
boundaries are present.

## 9. What Did Not Go Smoothly

The first test pass exposed namespace/broadcast mistakes in the test harness
(`linkinv` and the `LogitLink` object), not the likelihood. After that, the
integer-valued `N`/`Y` guard was added because the Binomial logpdf casts to
`Int`; silently accepting fractional inputs would have been too brittle.

## 10. Known Residuals

- The route is private and dense; production scaling is not proven.
- The canary covers one deterministic selected entry only; no ADEMP coverage
  calibration exists.
- No R bridge, source-specific R grammar, mixed-family CI, missing/mask, or
  spatial/animal/kernel transfer is implied.
- Totoro/DRAC evidence still requires an approved manifest with denominators,
  host provenance, MCSE, and stop rules.
- NB2, Gamma, Beta, and Ordinal structural-source LV remain Gate 0 only.

## Known Limitations

No public `fit_phylo_binomial_xlv`, no public `confint_lv_effects` source route,
no `phylo_latent(..., lv = ~ env)`, no bridge transport, no bootstrap rescue,
and no coverage claim were added.

## 11. Team Learning

For bounded-response structural-source LV, input admissibility is part of the
statistical proof: `N` and `Y` guards need to be banked before any profile
canary is treated as evidence.

## Next Command

```sh
julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - private S1 selected-entry finite-endpoint
routing is covered for one deterministic phylo x Binomial cell, but every
public, bridge, grammar, compute, and coverage claim remains blocked.
