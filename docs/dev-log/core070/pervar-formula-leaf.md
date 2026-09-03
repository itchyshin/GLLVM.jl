# Per-variance Gaussian formula route

OWNS: parent Ada, src/formula.jl; test/test_formula_pervar.jl; central runner,
associated docs and receipts. Existing numerical kernel is unchanged. Canonical
GLLVM.jl lease codex:core070-aghq-20260830. No foreign lane edits.

Contract before implementation: Normal() with pervar=true routes through the
existing fit_gllvm pervar dispatcher, using a complete p-by-n-by-q design.
An explicit 0 or -1 removes trait intercepts; 1 or the omitted intercept marker
includes one intercept per trait. Site covariates retain shared coefficients.
Constant/intercept columns from categorical coding must not create a duplicate
intercept. Contrast options are honored. Complete long tables use the same route.
Other-family pervar and explicit X conflicting with formula design reject clearly.
Existing shared-variance Gaussian and other-family routes are unchanged.
Explicit fixed_residual_sd is passed through, with no automatic R scale choice.
No new likelihood or parameterization: fixed-residual math contract is unchanged.

CHECK: exact baseline regression must fail at unsupported pervar keyword. Same
regression bytes then pass on candidate; matrix/formula likelihood differences
<=1e-7, parameters <=1e-6 and correct mean dimension. A shifted-data zero-mean
case must distinguish removing vs retaining trait intercepts. Categorical coding
and long/wide round trips plus negative inputs are required. Existing formula
suite and fixed-residual regression must pass without widening tolerances.
Re-run original retained R fixture via direct and formula routes, preserving
fixture/source/environment hashes and original fit-health/likelihood gates.

COMPUTE: Totoro, one Julia/BLAS/OMP thread, bounded baseline and green <=3minutes
each (240second batch cap), expected20-90seconds from earlier qualification.
Paired R follow-up expected30-60seconds,180second command cap. Stop on timeout,
retain every failure, no automatic full-suite run. Full suites >30minutes and
external numerical review remain awaiting their separate approvals.

EXPECT: failing baseline then candidate formula/native equality, original R
paired health and likelihood pass, strict documentation execution. These do NOT
prove bridge, AGHQ fallback, intervals, recovery/coverage or complete parity.
