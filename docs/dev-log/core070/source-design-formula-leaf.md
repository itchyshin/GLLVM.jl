# Gaussian source means and formula leaf

OWNS: Gauss owns src/source_fit.jl only. Boole owns src/formula.jl only.
Ada owns tests, module/reference integration, docs, README, CHANGELOG, evidence
and launchers. All in isolated codex/core070-aghq-20260830; foreign lanes protected.
Shared reviewed contract: decisions/2026-08-31-source-mean-design.md.

Before workers implement, capture unsupported-X/unsupported-sources regression
on Totoro. Native checks: analytic OLS with fixed/free noise and no sources;
complete design tensor/matrix equivalence; fixed zero-dimensional likelihood;
full/saturated/rank-deficient/invalid design controls; input/name copies; legacy
constructors; predeclared known-DGP coefficient/covariance recovery regression.
Formula checks: explicit matrix equality, intercept/no-intercept/shared slopes,
categorical contrasts, long row permutation, source-row alignment and rejected
conflicting keywords. No tolerance or source parameterization changes.

The first red process estimate<1minute; green unit/formula checks2–8minutes,
one Julia/BLAS thread, each driver cap600seconds. Re-run existing source-mode
and fixed-noise gates on the integrated candidate. R paired covariate route
must be frozen before running; no claim from formula/matrix equality alone.
Strict docs estimate2–5minutes,600second cap, existing qualified docs environment.
No package installs, DRAC campaign, full-suite run or release. Full suite and
specific external-review approval boundaries unchanged.

CHECK: python3 tools/core070_verify_source_design.py
EXPECT: CORE070_SOURCE_DESIGN_FORMULA_VERIFIED
Until actual numerical and documentation evidence passes this leaf is partial.

Before paired execution: SOURCE-MEAN-KERNEL-INDEP-X extends the existing declared
kernel-independent fitting data with shared slope .65*sin(site_index/5).
Exact source/seed/call/controls in fixtures/core070_source_mean_design.R. Compare
direct X, wide formula and reversed-long formula against one actual public R fit,
not the R bridge. Require all8 free coordinates, exact design/maps, both engines'
health (R1e-4, Julia1e-7), normalized likelihood<=1e-6, beta/covariance/variance
atol/rtol1e-5 and same-point objective<=1e-6. Retain whole fit and source pins.
Estimate1–3minutes on Totoro,600second driver cap. No new seed selection.
