# Six retained Gaussian source models — paired fitting leaf

OWNS: parent tools/core070_gaussian_source_pair.R, launcher/records;
Hopper Terra/high tools/core070_gaussian_source_pair.jl exclusively until return.
No numerical engine, reference R, foreign worktree, or tolerance changes.

IDs (all required, no success-only subset): STRUCT-PHY-TREE-RR,
STRUCT-PHY-DENSE-RR, STRUCT-PHY-TREE-PROPTO, STRUCT-ANI-PED-SPARSE,
STRUCT-KER-SINGLE-PSI, STRUCT-KER-MULTI. Use retained36responses and source
objects from structured-input-03; fixture and input RDS hashes frozen in
execution plan before launch. Reference b4d5fee64def88bc768dda1f1f77c29b295edd86.
Full programme manifest remains DRAFT; these receipts cannot freeze it.

R executes original public call with unchanged control and seed700. Also build
the originally captured TMB model and compare public versus captured objectives
at fitted coordinates. No post-hoc R optimizer repair. Julia fits the typed
fixed-source binding from identical retained starts, g_tol1e-6,iterations500.
Parameter order maps by names; R loglambda=2*Julia logSD. Both likelihoods are
normalized Gaussian marginal ML (Laplace exact for Gaussian random effects).
Raw loadings can differ by sign; compare implied covariance and means instead.
No standard-error, coverage, performance or source-parser claim.

CHECK: frozen scripts through core070_targeted_run.py, oracle verification
before/after. Every input, script, source, environment and log is retained.
EXPECT: six complete case receipts; common-start NLL/gradient<=1e-6;
R-endpoint native NLL<=1e-6/gradient<=1e-5; fitted absolute deltaLL<=1e-3;
both convergence codes/flags successful, finite maxabsolute gradient<=1e-4;
R objective/report disagreement<=1e-6. Record covariance/mean differences and
curvature; Hessian positivity alone cannot prove identification or recovery.
R evaluation at Julia endpoint is an additional cross-check,<=1e-6 NLL.
Failures stay failures and do not remove a required ID.

Estimate first batch3–5min, total cap300s; R cap120s,Julia cap120s,remaining
budget for oracle verification and cross-evaluation. Stop/re-report an overrun.
Totoro one Julia/BLAS/OMP thread. No DRAC allocation/campaign yet.
Invalid or missing output must produce nonzero gate status. Logs remain even
when a model throws; do not count export completion as numerical parity.
