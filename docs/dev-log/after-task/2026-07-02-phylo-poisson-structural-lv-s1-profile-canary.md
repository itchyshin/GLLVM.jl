# After Task: Phylo x Poisson Structural LV S1 Profile Canary

## 1. Goal

Prove one private selected-entry `B_eta_realized` profile-LR canary for the
phylo x Poisson structural LV route before any Totoro/DRAC compute, R grammar,
bridge, or public support claim.

## 2. Implemented

Added a private truth-startable point wrapper, selected-entry penalty-profile
helper, and bracket-then-bisect endpoint inversion on top of
`_phylo_poisson_xlv_marginal_loglik`. The canary fits a tiny deterministic
Poisson(log) phylo x `X_lv` cell and checks that one predeclared
`B_eta_realized` target has finite profile endpoints, brackets the MLE, and is
included by the one-df LR cutoff. This is route evidence only; it is not
coverage calibration, a production fitter, a source-variance recovery result,
or source-specific `lv` support.

Implemented claim: phylo x Poisson now has a private S1 selected-entry
profile-LR finite-endpoint canary for one deterministic `B_eta_realized`
target. It is not public source-specific `lv` support.

## 3a. Decisions and Rejected Alternatives

Decision: keep the route private and deterministic in S1, with profile-LR
finite endpoints as the canary statistic and bootstrap out of scope.

Rejected alternatives:

- Rejected public `fit_phylo_poisson_xlv`; this is not production evidence.
- Rejected source-specific R `phylo_latent(..., lv = ~ env)` grammar; no R
  syntax is opened by this Julia canary.
- Rejected bridge promotion; no R-to-Julia payload route is tested here.
- Rejected Totoro/DRAC launch; no S2/S3 denominator manifest exists.
- Rejected coverage wording; this is one positive-control route test.

## 3b. Mathematical Contract

The local model remains:

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 Q_cond^{-1})
a_t       = u[leaf_pos[t]]
z_s       = X_lv[s, :] alpha_lv + epsilon_s
eta[t,s]  = beta[t] + Lambda[t,:]' z_s + a_t
Y[t,s]    ~ Poisson(exp(eta[t,s]))
```

The canary target is the realized/design-conditional link-scale slope:

```text
B_eta_realized = slope_X(Lambda * Z_truth')
Z_truth        = X_lv * alpha_lv + epsilon
```

The constrained refit pins one fitted `vec(Lambda * alpha_lv')[idx]` entry to
candidate values, inverts the one-dimensional profile by bracketing and
bisection, and checks `2 * (nll_constrained - nll_mle) <= qchisq(0.95, 1)` at
the realized target while also requiring `lower < estimate < upper` and
`lower <= target <= upper`.

## 4. Files Touched

- `src/phylo_poisson_xlv.jl` - private point wrapper, packing helpers,
  selected-entry penalty-profile helper, and endpoint inversion.
- `test/test_phylo_poisson_xlv.jl` - deterministic selected-entry
  `B_eta_realized` canary and malformed-entry checks.
- `docs/design/73-predictor-informed-latent-scores.md` - S1 status and boundary
  wording.
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  - source/family matrix update.
- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md`
  - S0 page update.
- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md`
  - follow-up link to the canary.
- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`
  - new durable decision note.
- `docs/dev-log/check-log.md` - local evidence log.
- `docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`
  - this report.

External operating-board files refreshed in `gllvmTMB`:

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 5.0s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 14.1s

julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 3.8s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.6s

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no -e 'using Pkg; println(haskey(Pkg.project().dependencies, "JET") ? "JET-present" : "JET-not-in-project")'
JET-not-in-project

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json

sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

JET: not run; `JET` is not listed in this project environment.
Allocs: not run; no production hot-path performance claim is made.
Aqua: not run; no dependency, export, or package metadata changed.
Benchmarks: N/A - private S1 canary tooling, no speed claim.
R parity: N/A - no R grammar, bridge transport, or gllvmTMB parity surface.

## 6. Tests of the Tests

Added `Phylo x Poisson B_eta_realized selected-entry canary`
(`22/22` assertions) to `test/test_phylo_poisson_xlv.jl`.

Tests-of-tests clauses:

- The new test compares against a known DGP truth target.
- It exercises the combined phylo + Poisson + `X_lv` route.
- It now verifies finite endpoints, `lower < estimate < upper`, and
  `lower <= target <= upper`.
- It checks malformed selected-entry inputs for empty, duplicate,
  out-of-range, wrong truth-length, invalid iteration, and invalid
  endpoint-step cases.

The existing likelihood testset remains the independent-anchor baseline:
`sigma_phy^2 -> 0` reduces to ordinary Poisson `X_lv`, `Lambda = 0` reduces to
`phylo_glm_marginal_loglik(Poisson())`, and the augmented sparse phylo block
matches a dense leaf-covariance reference.

## 7a. Issue Ledger

No issue action taken. This slice is private/local S1 canary evidence and does
not reopen PR #127, start an R grammar slice, or launch compute.

## 8. Consistency Audit

Patterns run:

```text
rg -n "partial support|ready to expose|bootstrap rescue|Gate 3 passed|source-specific.*support|mixed-family CI|selected-entry.*pending|canary still pending|canary pending" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md

rg -n "profile-LR|B_eta_realized|No public|Totoro|DRAC|source-specific" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md
```

The first scan returned only explicit guardrail wording, not accidental support
language. The second scan confirmed the canary, Totoro/DRAC, and
source-specific guard language is present in the current design and decision
notes.

Mission Control preview at `http://127.0.0.1:8770/` was refreshed and checked
in the in-app browser after endpoint strengthening. The visible board contains
"Phylo x Poisson structural LV S1", finite-endpoint wording, `22/22`, "No
public fitter", and a no-active-compute guard.

## 9. What Did Not Go Smoothly

The deterministic canary is a route test, not a source-variance recovery test:
with this tiny positive-control count surface, species intercepts can absorb
most source-level mean variation and the fitted `sigma2_phy` may sit close to
the lower numerical edge. That is documented as a boundary rather than hidden.

## 10. Known Residuals

- The route is private and dense; production scaling is not proven.
- The canary covers one deterministic selected entry only; no ADEMP coverage
  calibration exists.
- No R bridge, source-specific R grammar, mixed-family CI, missing/mask, or
  spatial/animal/kernel transfer is implied.
- Totoro/DRAC evidence still requires a manifest with denominators, host
  provenance, MCSE, and stop rules.

## Known Limitations

No public `fit_phylo_poisson_xlv`, no public `confint_lv_effects` source route,
no `phylo_latent(..., lv = ~ env)`, no bridge transport, no bootstrap rescue,
and no coverage claim were added.

## 11. Team Learning

For structural-source non-Gaussian LV, S1 should stay tiny, deterministic, and
claim-poor until the estimand, host denominator, and failure taxonomy are
written for S2.

## Next Command

```sh
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - private S1 selected-entry finite-endpoint
routing is covered for one deterministic phylo x Poisson cell, but every
public, bridge, grammar, compute, and coverage claim remains blocked.
