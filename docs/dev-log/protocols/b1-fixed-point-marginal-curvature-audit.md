# B1 fixed-point marginal-curvature audit — pre-run only

Status: `PRE_RUN_ONLY`. This is a static contract, not authority to run it.
Fresh authorization is required before the single future diagnostic.

The future diagnostic is exactly one `TMB::sdreport()` call at the retained
11-coordinate `raw_opt_par` vector recorded in
`b1-fixed-point-marginal-curvature-audit.toml`. It must use
`getJointPrecision = FALSE`, `getReportCovariance = FALSE`, and
`skip.delta.method = TRUE`. The contract pins the retained source archive,
frozen installed `gllvmTMB` shared library, runner and fixture hashes, formula,
data MD5, dimensions, raw-coordinate order and values, and the installed TMB
1.9.21 package provenance (DESCRIPTION, NAMESPACE, and shared-library hashes).
Before either calculation, the evaluator also rejects a captured data/DLL/map
fingerprint mismatch, a TMB version/DESCRIPTION/DLL hash mismatch, or a
reconstructed fixed-coordinate name/length mismatch.

The canonical capture RDS pin is intentionally **unresolved** in this
pre-run-only revision: no serialized capture existed, and materializing one
would require a separately authorized TMB capture action. The evaluator no
longer trusts capture-supplied fingerprints. When authority is granted, it must
hash the canonical RDS bytes, freshly serialize-and-hash its actual data and
map objects, resolve-and-hash the DLL loaded for `MakeADFun`, and replace all
three unresolved pins plus the evaluator hash in one reviewed revision. Until
then, `execution_ready = false` makes any attempted run fail before the RDS is
read or an objective is evaluated.

This asks for **marginal outer Laplace curvature for fixed effects**, expressed
through `cov.fixed`; it is not the conditional fixed-and-random-effect joint
precision. `getJointPrecision = FALSE` prevents forming or retaining that
conditional joint precision. `getReportCovariance = FALSE` and
`skip.delta.method = TRUE` also exclude report covariance and delta-method
work. Retain only `cov.fixed`, `pdHess`, and `gradient.fixed`.

The one `sdreport` call may make multiple internal objective/gradient (`fn`/`gr`)
evaluations. That is expected and is distinct from an outer optimization: outer
optimizer calls and restarts are both zero. No source, data, formula,
coordinate, or tolerance change is permitted. No Julia or R fit is permitted.

The pinned evaluator reconstructs a frozen captured TMB object directly with
`TMB::MakeADFun`; it cannot call a `gllvmTMB` fitter, an outer optimizer, or a
restart. It reserves a new output name before the call, applies an actual
60-second elapsed-time limit, never retries, and writes exactly once. Its
receipt schema keeps only `cov.fixed`, `pdHess`, and `gradient.fixed` under
outputs, together with provenance, data, formula, vector, and failure metadata.
The sole `sdreport` call explicitly uses the retained `theta_star` as
`par.fixed`, after the single preceding `obj$fn(theta_star)` call. Failed
receipts must contain exactly empty outputs, rather than a null/ambiguous
output-name representation.

The pre-registered estimate is 30 seconds: 20 times the recorded 1.1-second
direct fixed-point diagnostic, rounded up from 22 seconds because `sdreport`
may make multiple internal `fn`/`gr` evaluations. It is an estimate, distinct
from the 60-second hard stop and no-retry rule. The static verifier can be run
now without loading R or TMB; it fails if any pin, execution gate, provenance
field, evaluator hash, or output-retention rule drifts.
