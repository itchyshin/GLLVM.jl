# Truncated-Poisson bridge input contract

Reference: gllvmTMB b4d5fee64def88bc768dda1f1f77c29b295edd86,
R/fit-multi.R:3265–3276 (frozen local readback pinned by the verifier).
Observed truncated counts must be positive integers. The Julia bridge previously
accepted fractional positive values and rounded them before fitting.

The bridge now checks finite, positive, integer-valued responses before Int
conversion or CI dispatch. It also requires exact equality with the original
input after Float64 conversion and an Int-safe upper bound. A Float64 rounded
up to 2^63 is rejected; representable integers below it are admitted. This is
an explicit bridge representation constraint, not an R model-domain claim.
The input is never mutated. Existing aliases and CI restrictions are unchanged.

The failing regression requests unsupported Wald intervals, so both old and new
code stop before a fitter: the old code reports CI rejection for fractional
data; the repaired code reports the invalid count first. Valid inputs still
reach CI rejection. This proves admission behavior only, not a successful fit.
148 admission assertions and 1,318 adjacent scalar/curvature assertions pass
through the actual copied module on Julia 1.10. The combined run takes 22.21 s.

Evidence: bridge-truncated-input-evidence.json; immutable process plans and logs
under .unlazy/core070-aghq/bridge-truncated-input, included in durable checkpoint.
No likelihood, identification or numerical tolerance changed. Other families'
rounding policies require their own reference admission audit. Full package
checks, fitted replay, embedding qualification, current docs rendering and
independent review remain outstanding. M1 PARTIAL; master manifest still DRAFT.
