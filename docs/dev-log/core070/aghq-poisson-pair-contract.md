# APP — frozen R Poisson AGHQ comparison (predeclared)

Case APP-POISSON-SEED44-K5. Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86.
Execute the exact original test/parity/test_poisson_parity.jl DGP bytes: seed44,
p5K2n60. No replacement fixture, likelihood penalty, parameter fixing, or R edits.
Use explicit public R gllvmTMBcontrol(aghq=5,aghq_ridge=Inf,
aghq_multistart=TRUE,aghq_n_adapt=400,n_init=1,se=FALSE), standard formula
value~0+trait+latent(0+trait|site,d=2,unique=FALSE). Reference starts from Laplace
and a constant-.3 raw-loading second start. Julia uses its own Laplace fit and
same alternate loading policy. Both starts run independently; converged usable
results outrank nonconverged usable results, then lower final objective wins.
No truth-based start for this comparison. Original helper/API source unchanged.

Require: explicit AGHQ used, k5, 14 free parameters, unpenalized, finite objective;
both engines' freshly evaluated frozen gradients satisfy absolute1e-4 OR
relative1e-6. Both report converged. Absolute fitted loglik difference <=1e-3.
At the R fitted theta AND R frozen mode/B/logjac, Julia and R objectives agree
within1e-6. Record separately re-adapted Julia objective at R theta, identifiable
Lambda*Lambda' difference and predicted marginal means exp(beta+diag(LL')/2).
Diagnostics do not silently replace the required same-model fit tests.

Record actual versus stored R gradient; R metadata and objective data are saved
in an RDS (including starts/trace) before tests. Retain both Julia starts/traces,
full responses and source/DGP pins, even if comparisons fail. Compare Julia
frozen gradients with two-step FD of the RE-ADAPTED k5 objective at its winner;
record the omitted adaptation-chain discrepancy without falsely asserting zero.
Also evaluate fixed winner at k9 and k15 as refinement diagnostics, not new fits
or universal numerical adequacy. Required public Julia route remains unpaid.

Totoro one Julia/BLAS thread. Estimate1–3minutes, main cap300s, oracle checks
before/after. No DRAC compute, R source modifications, shared fixture changes,
public API edits or recovery/coverage claim in this measurement leaf.
Acceptance evidence and failure artifacts must be source-bound, independently
reviewable and verified by Unlazy. The public integration design must use these
results and preserve fitted-object estimator identity through inference.

## Multistart integration leaf (before implementation)

Promote the measured two-start policy from the comparison script into the Julia
engine as internal aghq_multistart_optimize(starts,adapt,objective;kwargs...).
It runs every supplied start independently through aghq_outer_optimize, retains
all results, and returns runs/winner/selected/usable. A converged usable finite
result outranks every nonconverged result; then lower objective wins, ties retain
the first start. If every attempt is unusable, winner/selected are nothing, not
a fabricated successful fit. Public fitting later handles explicit fallback.
Validate nonempty, equal-length finite start vectors before any run. A real
interrupt propagates; ordinary adaptation failures remain recorded by the driver.

AM01 pure ranking guards: converged-above-lower-nonconverged, objective order,
tie order, no usable result and malformed nonfinite candidates.
AM02 actual two-start normalized Gaussian quadrature fit, input immutability,
all attempts retained, invalid input and interruption semantics.
APP then uses this engine wrapper, not duplicate ranking logic. Re-run exact
paired original-data acceptance with fresh source pins. Parent owns new helper,
tests and module/test includes; no public export or API completion claim.
