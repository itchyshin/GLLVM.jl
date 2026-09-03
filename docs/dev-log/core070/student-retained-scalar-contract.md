# Student-t scalar checks at retained fitted parameter ranges

No new scalar defect was found on this declared grid. The native engine is unchanged.
900 assertions pass through the actual GLLVM module on local Julia1.10 using the
separately qualified offline dependency environment. This narrows a diagnostic
hypothesis; it does not resolve the original Student-t fitted-health failure.

## Frozen inputs and independent reference

`test/fixtures/core070_student_scales.toml` contains the exact five scale/df pairs
from the retained native fit and each of the two R refinements. Each array is
verified against its checksummed original result. The native first pair is
sigma7.587768040815475e-5, nu3.034232245769893e31. Standardized residuals are
-3,-0.5,0,0.5,3. These75 scalar evaluations are not a regenerated/replaced data set
and do not change seed71 or its required absolute likelihood difference<=0.001.

Coordinates are location, log(scale), log(df-1). An independent768-bit direct
gamma-ratio formula supplies density and finite-difference derivatives with
h=1e-25. That precision matters: gamma subtraction at df≈1e31 and second differences
would consume a substantial part of a256-bit reference. Native Float64 evaluation
uses the existing stable normalizer series at large df. For each point the test
checks density, three gradient entries, six unique Hessian entries, analytic
location score and analytic observed curvature:12 assertions per scalar point.

Derivative comparisons are dimensionless: multiply location gradients by sigma
and Hessian rows/columns by their corresponding sigma factors. Log-scale/log-df
coordinates need no rescaling. This handles units; it does not change a fit-health
tolerance. Predeclared density tolerance is1e-12 absolute/1e-13 relative; gradient
1e-10 absolute/1e-9 relative; Hessian1e-8 absolute/relative. Near-zero df derivatives
are checked absolutely and do not establish strong df identification.

## Evidence and limits

Actual positive process:900pass,11.82s including module compilation. A disposable
copy adding1e-4 to log-density produces825pass/75fail, exit1: every density check
catches the introduced normalization defect. Production source stays byte-identical.
Six metadata negative controls also reject false health, false engine changes,
wrong counts, corrupt receipt, stale fixture and premature health completion.
Both process logs retain an existing Multinomial import-name warning; no full-suite
or warning-free package claim is made. The regression is registered after the
normalizer tests; the full test runner has not been run.

This grid covers the retained scale/df ranges at selected standardized residuals.
It does not replay actual latent residuals, optimize a mode, evaluate the full
marginal objective, compare frozen R derivatives, prove all floating-point ranges,
or show calibrated intervals. A passing scalar check cannot explain away failed
R convergence or elevate the original fitted case to PASS. The next decisive
check remains same-point R/native joint objective and latent-mode comparisons,
with original data and initialization retained, on qualified compute after
remote observation is restored. No Student-t engine change is justified by this
slice alone. Full manifest DRAFT; M1 PARTIAL; independent review unpaid.
