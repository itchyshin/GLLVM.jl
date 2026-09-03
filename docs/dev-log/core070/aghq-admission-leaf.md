# Matched public AGHQ admission cases

OWNS: tools/core070_aghq_admission_run.jl, tools/core070_aghq_admission_verify.py,
test/parity/core070_aghq_admission_cases.toml and associated developer contracts,
receipts/check-log/checkpoint. No numerical source or frozen R changes.

Goal: bind public k1 routing for Gaussian, Poisson and binomial to actual
same-model R/native/formula fits, and qualify the R default-unique fallback.
This does not substitute these new fixtures for original seed43/k5 or seed71.

Fixture: p4, n120, K1; MersenneTwister81031/81032/81033. Loadings
[0.8,0.55,-0.45,0.3]. Gaussian zero mean and common residual SD0.7; Poisson
trait intercepts[0.2,0.5,-0.1,0.3]; binomial same intercepts and8 trials per cell.
Each engine sees the identical realized matrix. Record all fixture bytes before
fitting. Native Gaussian uses X=nothing, Julia formula y~0; R formula has no
fixed terms. Discrete native trait intercepts correspond to R0+trait and Julia
no-covariate y~1, whose existing public route retains trait intercepts.

Required routing checks: default-off/explicit-false/k1 within each engine have
identical objective and coefficients; k1 metadata says Laplace/one node, no
ignored-request warning. Formula must reproduce native result and metadata.
Independent numerical checks: both convergence flags true; finite parameters;
max gradient<=1e-4 OR relative<=1e-6 in both engines; absolute deltaLL<=1e-3 and
relative<=1e-6. Report routing and numerical verdict separately; a failed
numerical check cannot disappear behind routing success.

R default unique: same Gaussian realization, default unique versus explicit
unique=FALSE source/model distinction. Compare default-unique aghq=3 and aghq=FALSE
with the same seed: unchanged Laplace objective/parameters, used=false,
warning and reason naming the extra random block. Retain R's residual-suppression
and random-vector metadata. Julia has_diag=true is NOT a matched parameter
contract (two diagonal components plus free shared residual): leave the native
case explicitly BLOCKED, do not run it as a substitute or claim fallback parity.

Totoro estimate2–5min, main cap300s plus oracle verification20s before/after.
One Julia/BLAS thread; existing socket only. No DRAC campaign or >30min run.
Failure: retain full results including failed cases, diagnose within frozen
scope; never remove cases, change tolerances, or silently alter estimator policy.

CHECK: python3 tools/core070_aghq_admission_verify.py
EXPECT: CORE070_AGHQ_ADMISSION_EVIDENCE_VERIFIED
This check verifies retained evidence and reports per-case status. It is not
itself the all-required-case numerical parity gate. That gate requires every
numerical comparison and every required interface, including the blocked bridge.

## Pre-run repair qualification
First paired attempt: routing3/3; numerical2/3. Gaussian R default gradient
0.0023748152 fails unchanged health rule despite LLdelta8.49e-9. Retain that
attempt. Second attempt applies public nlminb optArgs rel.tol1e-12,eval.max2000,
iter.max1500 to every Gaussian R baseline/request, same seed/data/map/model.
Poisson/binomial controls unchanged. Both attempts stay in evidence; this does
not imply Gaussian default optimizer met the health threshold. Estimate2–5min
again, same300s main cap. Add explicit R design/trial identity checks.

## Discriminating check before the next repair
Second attempt48.451s retains the same Gaussian point with nlminb singular
convergence7. Exact Gaussian marginal finite-difference gradient agrees with
TMB to about4e-8: this is optimizer stopping, not a reason to alter the
likelihood/derivative. R design values match exactly; identical() was comparing
assign/contrasts attributes too. Compare dimensions and numerical entries.
Third attempt uses public optim/BFGS reltol1e-14 maxit2000 for RGaussian only;
all model/fixture/acceptance constants unchanged, prior attempts retained.
Estimate2–5min with the same300s cap. If it fails, retain the numerical gap
rather than replacing the fixture or weakening health.
