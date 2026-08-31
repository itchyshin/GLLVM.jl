# Ordinary NB2 precision: diagnosis and pending repair contract

Status: diagnosis verified; engine repair NOT IMPLEMENTED. Original seed45,
p5,K2,n80, per-trait dispersion and observed Laplace curvature are frozen.

For integer count y>=0, mean mu>0 and size r>0,

\[
\log p(y)=\sum_{k=0}^{y-1}\log(1+k/r)+y\log\mu-\log\Gamma(y+1)
 -(r+y)\log(1+\mu/r).
\]

The empty sum for y=0 is zero. This is the existing NB2 distribution with
variance mu+mu^2/r, including its likelihood constant. It avoids first forming
p=r/(r+mu), whose rounding loses mean information near the Poisson limit.
The log-mean score is (y-mu)/(1+mu/r); observed negative second derivative is
mu*(1+y/r)/(1+mu/r)^2. These give independent derivative checks.

The retained actual native fit has size664216145.86 for trait1; R estimates
2695508420.58. On the declared scalar grid, the former size gives up to6.611e-5
density error and2.122 central log-mean-score error. Across96 declared cells,
independent Float64 rising-factorial evaluation matches256-bit density within
2.843e-14 and analytic score within1.332e-9. This is not a repaired-engine run.

Pending implementation leaf:

1. Add a stable mean-based NB2 primitive in src/families/negbin.jl, preserving
   integer support including y=0, likelihood constants and AD behavior.
2. Use the existing truncated-NB2 bounded rising-factorial series as a design
   reference, with y<=1 handled explicitly. Do not introduce O(y) work for large
   counts. Keep moderate-r logbeta evaluation where justified by error bounds.
3. Check scalar density/first/second derivatives at moderate and large size,
   near the series branch, y=0 and large counts; include a negative mutation.
4. Inspect direct shared and grouped observed-weight products for overflow;
   use reviewed scale-free algebra if changed. Audit NB1 and two-part neighbours
   for the same probability-conversion pattern; record separate model obligations.
5. Replay the unchanged original fitted target with native/R gradients<=1e-4,
   FD stability<=1e-4 and paired logLik rtol1e-6. R is healthy here: no new R
   optimizer policy is justified by the current evidence.
6. Tighten the required fixture's old1e-3 gate only with tested repair and updated
   required-run receipts. Revalidate affected truncated-NB2 and other shared-kernel
   evidence, then independent numerical review. Full recovery remains unpaid.

Provenance: direct source inspection of src/families/negbin.jl and the existing
in-repo stable truncated-NB2 implementation; algebra derived from the NB2 mass
function. Raw paired/source/runtime evidence is bound by
../core070/nb2-health-evidence.json. No R source or estimator change authorized
or performed by this diagnostic.
