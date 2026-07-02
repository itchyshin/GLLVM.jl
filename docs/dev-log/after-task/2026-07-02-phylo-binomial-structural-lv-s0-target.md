# After Task: Phylo x Binomial Structural LV S0 Target

## 1. Goal

Open the next non-Gaussian structural-source LV gate only at S0 by writing a
symbolic phylo x Binomial logit target and its required proof obligations.

## 2. Implemented

Added the phylo x Binomial S0 target page and linked it from the structural
Gate 0 matrix and Design 73. The page explicitly says this target is not
S1-ready: it needs Binomial-specific combined-likelihood reduction tests,
trial-count guards, and a private selected-entry `B_eta_realized` canary before
any compute or support claim.

## 3a. Decisions and Rejected Alternatives

I did not implement a combined phylo x Binomial likelihood and did not infer
support from ordinary Binomial `X_lv` plus the generic `fit_phylo_glm` surface.
The right next action, if this lane is opened later, is a local S1 proof with
Binomial-specific anchors.

## 3b. Mathematical Contract

The S0 model is:

```text
z_s = X_lv[s, :] * alpha_lv + epsilon_s
epsilon_s ~ Normal(0, I_K)
u ~ Normal(0, sigma_phy^2 * Q_cond^{-1})
a_t = u[leaf_pos[t]]
eta[t,s] = beta[t] + dot(Lambda[t, :], z_s) + a_t
Y[t,s] ~ Binomial(N[t,s], logistic(eta[t,s]))
```

The future canary target is link-scale
`B_eta_realized = slope_X(Lambda * Z_truth')`, not the response-probability
slope and not raw `alpha_lv`.

## 4. Files Touched

- `docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md`
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 3.6s
```

JET: not run - no implementation change. Allocs: not run - no hot path changed.
Aqua: not run - no dependency/export/project metadata changed. Full
`Pkg.test()`: not run for this S0 documentation slice.

## 6. Tests of the Tests

No new tests were added because this is S0 only. The page lists the exact tests
needed before S1: `sigma_phy^2 -> 0`, `Lambda = 0`, dense/sparse equality,
trial-count guards, and a deterministic selected-entry profile canary.

## 7a. Issue Ledger

No GitHub issue or PR action. PR #127 remains closed/parked, and no public
source-specific grammar was exposed.

## 8. Consistency Audit

The target page, Gate 0 matrix, and Design 73 all agree that phylo x Binomial is
symbolic S0 only. It does not inherit support from ordinary Binomial or phylo x
Poisson.

## 9. What Did Not Go Smoothly

The tempting shortcut would be to treat generic `fit_phylo_glm` dispatch as
enough. The current dedicated phylo GLM test is Poisson-only, so the S0 page
keeps Binomial-specific reduction tests as a hard S1 prerequisite.

## 10. Known Residuals

No combined phylo x Binomial likelihood exists yet. No selected-entry profile
canary, Totoro diagnostic, DRAC claim run, R bridge, source-specific grammar, or
coverage calibration exists for this target.

## 11. Team Learning

Ada kept the gate symbolic. Fisher kept the target on link-scale
`B_eta_realized`. Curie made the missing S1 tests explicit. Grace kept compute
unlaunched. Rose blocks any wording that says ordinary Binomial plus phylo GLM
equals support.

Rose verdict: PASS WITH NOTES - S0 is now banked, with all support and compute
claims still blocked behind Binomial-specific S1 evidence.
