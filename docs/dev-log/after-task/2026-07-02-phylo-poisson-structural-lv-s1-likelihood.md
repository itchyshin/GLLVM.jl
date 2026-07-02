# After Task: Phylo x Poisson Structural LV S1 Likelihood

## 1. Goal

Implement the first internal combined likelihood proof for phylo x Poisson x
predictor-informed LV so the next structural-source step can be a real
selected-entry `B_eta_realized` canary rather than an inherited ordinary or
Gaussian claim.

## 2. Implemented

Added private `_phylo_poisson_xlv_marginal_loglik`, a Poisson(log) Laplace
surface that jointly integrates site-score innovations and the augmented
phylogenetic random intercept. Added focused reduction tests and updated the
S0/Gate 0 notes so the new boundary is clear: S1 likelihood plumbing exists,
but no fitter, profile canary, bridge route, R grammar, compute launch, or
coverage claim exists.

Implemented claim: phylo x Poisson now has an internal S1 likelihood proof with
reduction tests. It is not public source-specific `lv` support.

## 3a. Decisions and Rejected Alternatives

Decision: implement a private likelihood first, not a public fitter. The next
scientific gate is a selected-entry `B_eta_realized` profile-LR canary after
the point surface is stable.

Rejected alternatives:

- Rejected exposing `fit_phylo_poisson_xlv` in this slice; there is no profile
  canary yet.
- Rejected source-specific R `phylo_latent(..., lv = ~ env)` grammar; this is
  internal Julia plumbing only.
- Rejected treating ordinary Poisson `X_lv` plus phylo-only Poisson GLM as
  support; the useful evidence is the new combined likelihood and its
  reduction tests.
- Rejected Totoro/DRAC launch; no denominator or stop-rule manifest exists for
  this source/family yet.

## 3b. Mathematical Contract

```text
epsilon_s ~ Normal(0, I_K)
u         ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t       = u[leaf_pos[t]]
eta[t,s]  = beta[t] + Lambda[t,:]' * (X_lv[s,:] * alpha_lv + epsilon_s) + a_t
Y[t,s]    ~ Poisson(exp(eta[t,s]))
```

The Laplace approximation is evaluated over `[vec(epsilon); u]`:

```text
log p(Y) ~= log p(Y | epsilon_hat, u_hat)
           - 0.5 ||epsilon_hat||^2
           - 0.5 u_hat' Q u_hat
           + 0.5 logdet(Q)
           - 0.5 logdet(H_joint)
```

where `Q = Q_cond / sigma_phy^2` and `H_joint` is the negative Hessian of the
joint log posterior at the mode. This matches the existing ordinary Poisson
Laplace constant convention for the iid score block and the existing
`phylo_glm_marginal_loglik` convention for the augmented phylo block.

## 4. Files Touched

GLLVM.jl implementation and tests:

- `src/phylo_poisson_xlv.jl`
- `src/GLLVM.jl`
- `test/test_phylo_poisson_xlv.jl`
- `test/runtests.jl`

GLLVM.jl planning/docs:

- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md`
- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md`
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md`

External operating-board files refreshed in `gllvmTMB`:

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.8s

julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 3.8s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.5s

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

git diff --check

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

Attempted broader core run:

```text
julia --project=. --startup-file=no -e 'include("test/runtests.jl")'
```

This was interrupted after a long active run, while inside
`test/test_zero_inflated.jl`, with no failure output before termination. It is
not counted as a pass.

JET: not run - `JET` is not installed in the current project environment.
Allocs: not run - no stable baseline for this new private dense S1 proof.
Aqua: not run - no dependency/export/project metadata changed.
Benchmarks: N/A - the dense joint Hessian is an S1 proof surface, not the
production scaling path.
R parity: N/A - no R bridge behavior changed.

## 6. Tests of the Tests

`test/test_phylo_poisson_xlv.jl` would fail without the new likelihood. It
checks three independent anchors:

- `sigma_phy^2 -> 0` reduces to ordinary Poisson `X_lv`;
- `Lambda = 0` reduces to `phylo_glm_marginal_loglik(Poisson())`;
- augmented sparse phylo integration matches a dense leaf-covariance reference.

It also checks failure paths for invalid phylo dimensions, `X_lv` dimensions,
`alpha_lv` dimensions, nonpositive `sigma_phy^2`, and non-log links.

## 7a. Issue Ledger

No GitHub issue or PR action. PR #127 remains closed/parked; no push, PR
reopen, R grammar exposure, bridge promotion, or compute launch was attempted.

## 8. Consistency Audit

Claim scan:

```sh
rg -n "partial support|ready to expose|inherits ordinary|inherits Gaussian|source-specific.*covered|active compute|grammar exposure|unique=.*parity|bootstrap rescue|mixed-family CI|phylo x Poisson support|combined likelihood missing|combined.*not implemented|S1 remains blocked|no S1 until" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md src/phylo_poisson_xlv.jl test/test_phylo_poisson_xlv.jl
```

Hits were guard wording only: no inherited ordinary/Gaussian claim, no active
compute, no public source-specific grammar exposure, no `unique=` parity claim,
and no stale "combined likelihood missing" wording.

Mission Control preview at `http://127.0.0.1:8770/` was refreshed and checked
in the in-app browser. The visible board contains "Phylo x Poisson structural
LV S1", "combined likelihood proof", "selected-entry B_eta_realized profile-LR
canary", "No public fitter", "Totoro/DRAC compute", and
`test_phylo_poisson_xlv.jl 9/9`.

## 9. What Did Not Go Smoothly

The broad `test/runtests.jl` include run was too long for this narrow slice and
was terminated explicitly after it reached `test/test_zero_inflated.jl`.
Focused tests were rerun afterward and passed.

## 10. Known Residuals

- No public fitter exists.
- No selected-entry `B_eta_realized` profile-LR canary exists.
- No source-specific `phylo_latent(..., lv = ~ env)` R grammar exists.
- No R bridge transport exists.
- No Totoro/DRAC denominator is authorized.
- Dense joint Hessian is acceptable for S1 proof cells only; production scaling
  would need a sparse/block implementation.

## 11. Team Learning

The reduction-test ladder worked: ordinary Poisson `X_lv`, phylo-only Poisson,
and dense phylo reference checks give a narrow but real route proof before any
profile or compute story.

## Rose Verdict

Rose verdict: PASS WITH NOTES - internal S1 likelihood plumbing is
reduction-tested, but all interval, public API, bridge, R grammar, and compute
claims remain blocked.
