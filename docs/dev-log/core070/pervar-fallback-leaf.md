# Default-unique Gaussian AGHQ fallback

OWNS: Ada parent, src/families/gaussian_pervar.jl, named fallback tests,
central runner and associated docs/evidence. Canonical GLLVM.jl lease
codex:core070-aghq-20260830; no foreign checkout or R engine edits.

Frozen reference b4d5fee64def88bc768dda1f1f77c29b295edd86, R/fit-multi.R
6321-6408: aghq=false means no quadrature; k=1 precedes structural rejection,
retains Laplace without ignored-request warning. Other requests with random
blocks z_B,s_B retain Laplace and warn; this rejection precedes affordability
and auto trait-count policy. Default Gaussian auto starting nodes=5 from
R/aghq-control.R:157-158. No automatic loading ridge is permitted here.

Native contract: fixed_residual_sd>0 gives the explicit residual+unique model;
all AGHQ requests retain its exact Gaussian likelihood and fitted coordinates.
Expose requested, actual=:laplace, actual k=1, requested k, reason and no-ridge
provenance. Default off retains integration=nothing and old constructors.
The existing fitter's convergence remains authoritative, no fake quadrature
mode gradient or adaptation result. Show and summary must reveal fallback.
Validate malformed requests/controls before optimization. Formula inherits route.

A c=0 per-variance fit is not automatically the reference's z_B+s_B model;
requests>1 must retain exact fitting with distinct :pervar_aghq_unimplemented
reason, without falsely claiming a reference structural rejection. This is an
unpaid adapter, not parity or a new scope exclusion. k=1 remains Laplace.

CHECK: identical final regression bytes fail at missing aghq keyword in baseline;
candidate default/k1/numeric/auto/formula fits keep identical objective and free
coordinates; warnings only for non-k1 requests. Six/eight-argument constructors
remain supported. Bad controls fail, no silent ridge. Replay original retained
R fixture with numeric, k1 and auto requests, keeping R and native health and
absdeltaLL<=1e-3; request must not change either engine's baseline coordinates.
Strict documentation examples and truthfully scoped reports required.

COMPUTE: Totoro, one thread per run. Baseline expected20-45s,180s command cap; new+
adjacent checks expected1-3minutes,180s command cap. Paired R requests expected30-90s,
180s cap. Stop on cap and retain all attempts. No full-suite or >30minute run.
No inference, calibrated recovery, R bridge or full AGHQ-domain claim.
