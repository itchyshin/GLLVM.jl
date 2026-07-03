# After Task: Ordinary Ordinal LV Profile Gate

## 1. Goal

Finish the ordinary non-Gaussian `X_lv` Gate 1 canary set by adding native
Julia shared-cutpoint Ordinal selected-entry profile-LR support for the
rotation-stable `B_lv = Lambda * alpha_lv'` estimand.

## 2. Implemented

`fit_ordinal_gllvm(...; X_lv=...)` now fits a predictor-informed latent-score
mean for the shared-cutpoint ordinal route, stores `alpha_lv` and the packed
working vector, and routes `B_lv` point extraction plus Wald/profile/bootstrap
intervals through `confint_lv_effects`. The ordinal Laplace mode and marginal
likelihood accept a link-scale offset so the conditional score innovation stays
zero-mean while the predictor mean enters as `Lambda * alpha_lv' * X_lv[s, :]`.

## 3a. Decisions and Rejected Alternatives

The admitted target is native Julia shared-cutpoint Ordinal logit only. I did
not promote per-trait ordinal `X_lv`, R bridge ordinal parity, source-specific
`lv = ~ env`, mixed-family `X_lv`, response-mask `X_lv`, or any structural
Ordinal route. Bootstrap remains available as a secondary diagnostic; the gate
claim is selected-entry profile-LR route evidence.

## 3b. Mathematical Contract

For site `s`, the shared-cutpoint ordinal model uses
`Pr(Y[t,s] <= c | z_s) = F(tau[c] - eta[t,s])`, with
`eta[:,s] = Lambda * (X_lv[s,:]' * alpha_lv + epsilon_s)`,
`epsilon_s ~ Normal(0, I_K)`. The interval target is the rotation-stable
trait-effect matrix `B_lv = Lambda * alpha_lv'`; raw `alpha_lv` remains an
axis/access-effect table and is not the inferential target.

## 4. Files Touched

- `src/families/ordinal.jl`
- `src/postfit.jl`
- `src/simulate_fit.jl`
- `src/confint_family.jl`
- `test/test_lv_ci.jl`
- `README.md`
- `docs/src/model.md`
- `docs/src/confidence-intervals.md`
- `docs/src/changelog.md`
- `docs/src/response-families.md`
- `docs/src/tutorial.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/src/roadmap.md`
- `docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```text
julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no test/test_ordinal_fit.jl
fit_ordinal_gllvm: 9 passed, 0 failed, 0 errored, 14.8s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 196 passed, 0 failed, 0 errored, 3m57.7s

julia --project=. --startup-file=no test/test_ordinal_probit.jl
Ordinal cumulative-link selection (logit default + probit): 10 passed, 0 failed, 0 errored, 3.7s

julia --project=. --startup-file=no test/test_ordinal_pertrait.jl
Ordinal per-trait cutpoints: 96 passed, 0 failed, 0 errored, 0.5s
bridge ordinal payload uses per-trait cutpoints: 15 passed, 0 failed, 0 errored, 6.8s

julia --project=. --startup-file=no test/test_confint_family.jl
Non-Gaussian confidence intervals: 124 passed, 0 failed, 0 errored, 4m13.4s
```

Focused canary evidence:

```text
p=2, n=60, K=1, q_lv=1, C=4
truth B_lv[1,1]=0.275
estimate=0.27757861344530577
profile interval=[-0.4920852132652146, 1.1235356474682392]
fit converged in 19 iterations
```

JET: not run; this slice uses finite-difference outer gradients and no new
performance claim. Allocs: not run; no allocation budget claim. Aqua: not run;
no Project.toml, exports, or dependency changes. Full `Pkg.test()`: not run;
this was a targeted Gate 1 profile canary slice.

## 6. Tests of the Tests

The new `test/test_lv_ci.jl` canary checks a known-DGP selected `B_lv` truth,
requires finite profile endpoints, requires the MLE inside the interval, checks
truth inclusion, confirms all ordinal categories are observed, and uses the
existing per-trait ordinal tests to ensure the bridge parity route was not
silently rewritten.

## 7a. Issue Ledger

No GitHub issue or PR was opened. This is local handover-worktree evidence for
the LV arc and does not reopen GLLVM.jl PR #127 or expose R/source-specific
grammar.

## 8. Consistency Audit

Docs now distinguish native shared-cutpoint Ordinal `X_lv` support from
per-trait ordinal bridge parity. The ADEMP note and check-log include Ordinal
Gate 1 constants and keep source-specific, mixed-family, mask/missing-response,
bridge-profile, coverage, `unique=`, Totoro, and DRAC claims blocked.

## 9. What Did Not Go Smoothly

The first local Ordinal smoke had finite intervals but did not converge cleanly.
The final canary uses `n=60`, seed `20260744`, and explicit `Lambda` /
`alpha_lv_init`, giving convergence in 19 iterations and stable selected-entry
profile endpoints.

## 10. Known Residuals

Coverage calibration remains unclaimed. Per-trait ordinal `X_lv`, R bridge
profile/bootstrap transport, source-specific structural `lv`, mixed-family
`X_lv`, response masks, missing responses, and `unique=` Julia parity are still
separate gates. Mission Control was not refreshed in this slice because the
`gllvmTMB` checkout was heavily dirty from parallel/user work.

## 11. Team Learning

Ada kept the gate ordinary and local. Fisher kept the profile-LR target on
`B_lv`, not `alpha_lv`. Hopper kept shared-cutpoint native Julia evidence
separate from per-trait R bridge parity. Curie kept the test as route evidence,
not coverage evidence. Rose blocks any wording that turns this into
source-specific or bridge support.

Rose verdict: PASS WITH NOTES - targeted Gate 1 evidence is coherent, but full
suite, Documenter, Mission Control, and bridge parity remain out of scope.
