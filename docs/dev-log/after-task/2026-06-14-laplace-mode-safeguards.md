# After Task: Laplace Mode Safeguards

## Goal

Fix GLLVM #96 by adding regression-tested safeguards to the shared
non-Gaussian Laplace latent-mode finder.

## Implemented

`_laplace_mode!` now evaluates the conditional log-posterior for the latent
mode and backtracks large Fisher-scoring steps that would lower it. Near the
mode, it still takes the full step to avoid line-search stalls. If the
factorization fails or the step is non-finite, it restarts once from `z = 0`
instead of returning a loosely converged or non-finite mode. The non-workspace
helper now delegates to the workspace implementation so both paths share the
same safeguard logic.

## Mathematical Contract

For one site, the mode finder targets

```math
q(z) = \sum_t \log f(y_t \mid \mu_t(z)) - \frac{1}{2} z^\top z,
\qquad \mu_t(z) = g^{-1}(\beta_t + \Lambda_t z).
```

The Fisher-scoring step solves

```math
(I + \Lambda^\top W \Lambda)\Delta = \Lambda^\top s - z
```

and is accepted directly only when it is already in-basin. Otherwise the step is
halved until `q(z + a Delta) >= q(z)` or the step is rejected. This preserves
the Laplace approximation described by Kristensen et al. (2016) while making
the inner mode solve less brittle.

## Files Changed

- `src/families/laplace.jl`
- `test/test_laplace_mode_safeguards.jl`
- `test/runtests.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-14-laplace-mode-safeguards.md`
- dashboard/status docs updated in the same local operating slice

## Tests Added

- A deterministic hard Poisson cell where the old full Fisher step lowered the
  conditional mode objective. The guarded one-step update must not lower it.
- A non-finite warm-start test where `z = [Inf, -Inf]` must restart to a finite
  mode.

## Checks Run

- `/Users/z3437171/.juliaup/bin/julia --project=. test/test_laplace_mode_safeguards.jl`
  - `Laplace mode safeguards | 5/5 pass`
- Adjacent tests:
  - `test/test_poisson_laplace.jl` -> `4/4 pass`
  - `test/test_gamma_laplace.jl` -> `2/2 pass`
  - `test/test_beta_laplace.jl` -> `2/2 pass`
  - `test/test_family_forwarddiff_gradients.jl` -> `92/92 pass`
  - `test/test_poisson_fit.jl` -> `7/7 pass`
  - `test/test_gamma_fit.jl` -> `7/7 pass`
  - `test/test_beta_fit.jl` -> `7/7 pass`
  - `test/test_postfit.jl` -> `1092/1092 pass`
- `/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl`
  - Exit code 0; new safeguard test passed 5/5 inside the suite.
- `/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
  - `Testing GLLVM tests passed`; quality battery `12/12` pass.
- `/Users/z3437171/.juliaup/bin/julia --project=docs docs/make.jl`
  - Exit code 0. Known local warnings remain: deployment auto-detection is
    skipped outside CI, optional Vitepress assets/package files are substituted
    or missing, and npm audit reports 4 vulnerabilities in the local docs
    toolchain.
- `git diff --check`
  - clean.

## R-Parity Verdict

Parity: N/A -- this changes the Julia inner mode solver safeguard, not the
R-facing bridge parameter map. R/TMB-vs-Julia parity remains a separate gate.

## JET / Allocs / Aqua Verdicts

- JET: package quality battery passed under `Pkg.test()`.
- Aqua: package quality battery passed under `Pkg.test()`.
- Allocs: not run; this is a robustness change and adds conditional objective
  evaluation on guarded large-step paths. A hot-loop allocation pass should be
  part of the later speed/gradient-default slice.

## Stale-Wording Scan

Current operating docs and dashboard were scanned for #96 / mode-finder queued
wording. Historical after-task and check-log entries from earlier dates were
left intact because they were true at the time. Current files were updated to
say #96 is locally fixed, issue reconciliation still open.

## GitHub Issue Ledger

- Relevant issue: GLLVM.jl #96. The local code/test gate is satisfied, but the
  GitHub issue was not commented or closed because remote mutation is
  maintainer-gated in this session.

## Remaining Risks

- The Gamma analytic-gradient default is not automatically promoted by this
  fix. It still needs the benchmark/logLik-delta gate.
- This safeguard can add work on large rejected steps; no public speed claim is
  attached to the change.
- Existing duplicate-include warnings in phylo/edge tests remain and are
  unrelated to this slice.

## Next Command

```sh
/Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Run only after deciding whether to benchmark from this dirty operating branch
or a clean reconciled branch.

Rose verdict: PASS WITH NOTES -- #96 is locally fixed and full-suite green, but
GitHub issue reconciliation and Gamma default benchmarking remain open.
