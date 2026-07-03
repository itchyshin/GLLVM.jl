# After Task: Phylo x Poisson Structural LV S0 Target

## 1. Goal

Write the first source/family structural-source LV S0 target page so any future
phylo x Poisson work starts from symbolic math, an estimand, and explicit stop
rules rather than inheriting ordinary Poisson or Gaussian phylo evidence.

## 2. Implemented

Added a phylo x Poisson S0 decision note with the symbolic model, estimand,
symbolic-alignment table, candidate S1 cell, implementation boundary, and Rose
claim guard. Updated the broader Gate 0 matrix and Design 73 to point to the
new S0 target. Refreshed Mission Control with a guard row and fixed an isolated
test hygiene issue in `test/test_phylo_glm.jl` by importing
`Distributions: Poisson`.

Implemented claim: phylo x Poisson now has an S0 target page only; it does not
have an S1 canary or combined model implementation.

## 3a. Decisions and Rejected Alternatives

Decision: the first structural-source non-Gaussian target is a Model A-style
additive composition,

```text
z_s = X_lv[s, :] * alpha_lv + epsilon_s
epsilon_s ~ Normal(0, I_K)
u ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t = u[leaf_pos[t]]
eta[t, s] = beta[t] + dot(Lambda[t, :], z_s) + a_t
Y[t, s] ~ Poisson(exp(eta[t, s]))
```

The first profile-LR canary target is
`B_eta_realized = slope_X(Lambda * Z_truth')` on the link scale.

Rejected alternatives:

- Rejected treating ordinary Poisson `X_lv` plus `fit_phylo_glm` as support;
  the combined likelihood does not exist yet.
- Rejected old population `B_lv = Lambda * alpha_lv'` as the S1 truth target;
  the phylo weak-cell evidence already parked that route.
- Rejected observed-response `Y ~ X_lv` slopes as the target; they include
  response noise and already failed the strict direct-slope path in Gaussian
  diagnostics.

## 4. Files Touched

GLLVM.jl:

- `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md`
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s0-target.md`
- `test/test_phylo_glm.jl`

External operating-board files refreshed in `gllvmTMB`:

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 4.0s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.5s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null

git diff --check
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s0-target.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed

sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

JET: not run - no implementation path changed.
Allocs: not run - no hot-path implementation changed.
Aqua: not run - no dependency/export/project metadata changed.
Benchmarks: N/A - no optimizer or likelihood code changed.
R parity: N/A - no R bridge behavior changed.

## 6. Tests of the Tests

No new behavioral test was added. The existing `test/test_phylo_glm.jl`
contains two independent anchors for the source component: near-zero
`sigma_phy^2` reduction to the independent Poisson marginal and sparse
augmented-state equality to a dense phylo random-effect Laplace reference.
`test/test_phylo_eta_realized.jl` independently checks centering/orientation of
the realized eta target and failure paths for malformed inputs.

The only test edit was an import fix so `test/test_phylo_glm.jl` runs in
isolation.

## 7a. Issue Ledger

No GitHub issue or PR action. PR #127 remains closed/parked; no push, PR
reopen, R grammar exposure, bridge promotion, or compute launch was attempted.

## 8. Consistency Audit

Claim scan:

```sh
rg -n "partial support|ready to expose|inherits ordinary|inherits Gaussian|source-specific.*covered|active compute|grammar exposure|unique=.*parity|bootstrap rescue|mixed-family CI|ordinary Poisson plus phylo_glm equals support" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md
```

Hits were guard wording only: no `unique=` parity, no bootstrap rescue, no
inherited support, no active compute, and no source-specific grammar exposure.

Symbolic alignment audit: every symbol in the S0 model has a keyword/future
route, DGP draw, recovery/check, and truth-value column. The missing item is
implementation of the combined likelihood, which is explicitly named as the S1
blocker.

Browser preview check at `http://127.0.0.1:8770/` confirmed the visible board
contains "Phylo x Poisson structural LV S0", the combined-likelihood blocker,
and no-source-specific-grammar/no-compute wording.

## 9. What Did Not Go Smoothly

The focused `test/test_phylo_glm.jl` initially failed in isolation with
`UndefVarError: Poisson not defined`. That was an old test hygiene issue; adding
`using Distributions: Poisson` made the existing test runnable and green.

## 10. Known Residuals

- No combined phylo + Poisson + `X_lv` likelihood exists yet.
- No S1 selected-entry canary exists.
- No Totoro/DRAC denominator is authorized for this source/family.
- R source-specific `phylo_latent(..., lv = ~ env)` remains fail-loud.
- R bridge profile/bootstrap transport, mixed-family CIs, masks,
  missing-response support, and `unique=` parity remain blocked.

## 11. Team Learning

Symbolic alignment did its job: it exposed that the next implementation is not
"turn on phylo_glm with X_lv", but a new combined likelihood with reduction
tests before any profile canary.

## Rose Verdict

Rose verdict: PASS WITH NOTES - S0 is banked and the anchor tests pass, but S1
is blocked until the combined likelihood and reduction tests are implemented.
