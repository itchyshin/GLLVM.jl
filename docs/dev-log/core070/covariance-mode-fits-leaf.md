# Remaining Gaussian covariance-mode fits: declared contract

Reference: gllvmTMB b4d5fee64def88bc768dda1f1f77c29b295edd86.
Status before execution: UNQUALIFIED. This is fitted-model agreement, not a
recovery or coverage campaign, and does not freeze the full Core/AGHQ manifest.

OWNS: Hopper (requested Terra/high native worker) owns only
tools/core070_covariance_mode_fits.jl. Ada owns the new fixture, verifier,
launch plan, evidence and logs. No engine, foreign lane or R-source edits.

## Fixtures and model

The original core070_covariance_modes.R is unchanged and retains its pointwise
contract. Its centered three-trait sine data lie in a two-dimensional subspace;
the ordinary full-covariance likelihood can approach a singular covariance.
It was never declared as a healthy full-rank fitting fixture. New fitting IDs
FIT-MODE-* explicitly distinguish the new data from those existing MODE-* IDs.

Seven cases: ORD-DEP; ANIMAL-INDEP/COMMON/DEP; KERNEL-INDEP/COMMON/DEP.
The exact public terms remain those of the original model contract. The fixture
test/parity/fixtures/core070_covariance_fits.R freezes 36 sites, three traits,
12 groups with three replicates, beta=(.2,-.1,.3), residual SD=.35 and source
C=.7 I+.3 J. Dense R preparation adds exactly 1e-8 I. Ordinary source C=I36.
Independent trait SD=(.5,.7,.9); common SD=.7; dependent lower Cholesky diagonal
(.8,.7,.6), below-diagonal (.15,-.2,.1) in column order. Conditional sampling:

    A = L Z chol(C_effective), Z_ij ~ N(0,1)
    Y_ti = beta_t + A_t,group(i) + .35 E_ti, E_ti ~ N(0,1)
    vec(Y) ~ N(vec(beta), kron(P C_effective P', L L') + .35^2 I).

R seed=700700+mode index (INDEP1, COMMON2, DEP3), plus10 for ordinary.
Animal/kernel same-mode pairs deliberately share data. Draws are not centered,
rescaled or selected after seeing results. Require empirical centered trait rank3
as a fixture check; a failure is retained, not repaired by reseeding.
Each public R fit gets seed700710+case index and n_init1,seFALSE,aghqFALSE.
Julia uses its independent default start, g_tol1e-7, iterations2000. No best-of
selection, optimizer changes, source ridge or reference modification.

## Acceptance frozen before fitting

Every case must retain its full R fit, input data/map, exact call, warnings,
optimizer result, gradient, normalized objective and source/trait/group order.
Retain Julia parameters, convergence/stopping, gradient, Hessian diagnostic,
source covariance and residual SD. Record failures incrementally; attempt all7.

- Exact IDs/count, source/environment/fixture hashes and oracle before/after.
- R code0, finite raw max gradient<=1e-4; Julia converged and max gradient<=1e-7.
- Absolute log-likelihood difference<=1e-6; R reported objective agreement<=1e-8.
- Trait means and identifiable covariance atol/rtol1e-5.
- Structured models: compare source covariance and residual variance separately.
- ORD-DEP: compare U+sigma_eps^2 I only. Its source/residual decomposition is
  nonidentified even on full-rank data. Report both Hessian diagnostics without
  requiring a positive Hessian or claiming intervals/variance identification.
- Free counts10(dep),7(indep),5(common); native and R counts must agree.
- Same-point native objective at fitted R coordinates<=1e-6 independently of
  fit-to-fit agreement. This cross-evaluation is never the native starting point.
- Fail closed on missing case/dependency/receipt, stale pin, nonzero process or
  damaged fit values. Negative controls must demonstrate those failures.

Fixture generation/structural checks estimate<5seconds, no model fit. Totoro
paired qualification estimate2–8minutes (previous two smaller source pairs25.5s);
one Julia/BLAS thread, no installs. Per-fit driver hard cap600seconds, complete
supervisor cap660seconds. Stop on cap and retain partial results. No DRAC campaign
or full-package run is authorized by this leaf; >30minute runs remain separate.

CHECK: python3 tools/core070_verify_covariance_fits.py
EXPECT: CORE070_COVARIANCE_FITS_VERIFIED
Full programme gate remains unpaid regardless of this slice's outcome.

## Pre-run amendment after retained default-control result

Attempt01 completed all7 in35.64seconds:4cases pass, ORD-DEP and the two
structured DEP cases fail R gradient<=1e-4 (2.74e-4/2.48e-4); structured DEP
also fails matrix covariance agreement. Likelihood differences<=1.87e-9.
Hypothesis: the public default optimizer stopped early. Attempt02 uses the
same public nlminb path, seeds, data, model and gates with explicit
optArgs control rel.tol=sing.tol=1e-12, eval.max2000,iter.max1500. No warm start
or extra starts. This is an explicit numerical-control qualification; it cannot
retroactively make the default-control health failures pass. Assert all prepared
data, parameter maps and free-coordinate names equal the retained baseline.
Native default optimizer unchanged. Estimate1–3minutes; same600second cap.

Independent readback compares the exact retained responses with the TOML rows.
It does not regenerate a random matrix product on macOS and demand bit equality
to Linux BLAS: an initial such readback failed despite the within-run exact
trait/site checks passing. No numerical agreement tolerance is relaxed.
