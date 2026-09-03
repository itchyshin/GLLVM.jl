# Truncated NB2 explicit dispersion and formula checkpoint

## 1. Goal
Expose the existing per-trait truncated-NB2 model through the unified and formula
interfaces, preserving the shared default and frozen R model contract.

## 2. Implemented
Explicit disp_group=:species or distinct positive IDs select the existing
per-trait fitter. Repeated/nonpositive/wrong-length group vectors reject. Wide
and complete reordered long intercept-only formula calls match the named fitter.
No likelihood arithmetic, optimizer, default, or free parameter count changed.

## 3a. Decisions and Rejected Alternatives
Keep the documented shared-r default; do not silently coerce all calls to per-trait.
Partial grouping is not implemented by the existing fitter and is rejected.
Mathematical contract: decisions/2026-08-31-truncated-nb2-formula-dispatch.md.
The original R default failure remains recorded; public BFGS continuation is the
declared reference policy, not evidence that the original optimizer converged.

## 4. Files Touched
src/families/fit_gllvm.jl; test/test_truncated_formula.jl and central runner;
response-family docstring/reference/example, docs/Project.toml, README/CHANGELOG;
scoped verifier, immutable evidence summary and developer-log/checkpoint records.
Only the isolated codex/core070-aghq-20260830 checkout changed.

## 5. Checks Run
One-core Totoro: corrected baseline fails on unsupported dispatch in21.36s;
identical test passes29/29 in39.96s after routing change. Adjacent dispatch/API
regressions pass11+24 assertions in60.15s. Seven registered R/native/interface
cases pass121 assertions across6executions in81.90s; registry28checks3.42s;
frozen oracle before/after PASS. Truncated NB2 absolute deltaLL8.6731e-8 with
recorded fit health. Strict Documenter plus executed new example pass135.70s;
rendered output (5,true) confirms per-trait count and convergence. Source pins,
process exits/log hashes and unchanged original DGP checked by
python3 tools/core070_verify_truncated_formula.py --self-test.
JET/Aqua/full core/full Pkg.test: NOT RUN in this slice, fullsuite approval pending.
Allocs/performance: NOT RUN; no hot-loop or speed claim.

## 6. Tests of the Tests
The same regression fails before and passes after the sole src dispatch edit.
Five corrupted process receipts reject;22 registered model negative controls
reject missing cases, stale provenance, changed data/controls and failed health.
Unlazy full-suite/review gate remains unpaid, so this is not complete acceptance.

## 7a. Issue Ledger
New formula route is tested but its separate required-case ID is not yet bound
into the master manifest. Add that binding alongside Poisson/Beta formula cases.
The7registered IDs/710other unmapped nonexcluded source facts are unchanged;
no full-family or frozen-programme claim. Public bridge remains separate.

## 8. Consistency Audit
Docstring, README, CHANGELOG and response-family page describe explicit per-trait
selection and unchanged shared default. Example executes during Documenter build.
No covariance/AGHQ/interval or covariate support implied. Default R failed attempt
retained. Existing VitePress asset/bundle/environment warnings remain; no deployment,
zero-warning, visual-polish or full-site approval claim.

## 9. What Did Not Go Smoothly
First test setup lacked the pure loading helper; retained setup-failure receipt,
then embedded the original pure DGP and reproduced the real dispatch rejection.
First docs build failed because its project omitted Distributions; declared the
example dependency and reran successfully. First Unlazy run lacked explicit CWD;
fixed the ledger working directory and reverified rather than treating it as PASS.

## 10. Known Residuals
Full package checks and independent review remain pending. Formal Rose review
NOT REQUESTED for this interim checkpoint; no reviewer sign-off is claimed.
Full AGHQ/family/covariance/data/postfit contracts, R bridge, recovery/coverage,
performance and final Documenter inspection remain incomplete. The formula test
qualifies y~1; it does not establish general no-intercept or covariate semantics.

## 11. Team Learning
Ada parent implemented and verified this bounded change; no child model/effort/
agent-hours receipt invented. Executing a public example caught a real docs
project dependency omission that a decorative code fence would have missed.

## 12. Cross-Product Coverage
This checkpoint does NOT cover full-family parity, public R bridge, general
formula grammar, calibrated intervals, recovery/coverage or performance.
Totoro and8DRAC login sessions independently responded to hostname probes;
Totoro uses passwordless SSH directly, no Duo. No DRAC allocation or scientific
campaign started; max5DRAC computers authorization unchanged. R0.7.1/article/
Cursor/Claude lanes untouched. No push, merge, release or destructive cleanup.
Next: source-bind retained truncated-NB2 formula and qualify Poisson/Beta formula
cases, then continue required model/interface work. No new hours forecast.
