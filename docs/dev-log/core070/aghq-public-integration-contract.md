# Public AGHQ integration — estimator identity contract

Status: REVIEWED DESIGN, IMPLEMENTATION PENDING. Full Stage1a remains required;
the internal Poisson pair is numerical evidence, not public capability completion.
Reference b4d5fee64def88bc768dda1f1f77c29b295edd86. Parent owns central API integration.

## Evidence that determines the design
The original seed44 p5K2n60 unpenalized k5 two-start comparison agrees with R:
absolute fitted loglik difference7.44e-9; R-theta/R-cache objective delta1.14e-13.
The reference's actual and stored frozen gradients agree. Its gradient1.60e-4
passes only the relative leg, not the absolute1e-4 leg. Julia's frozen gradient
passes the absolute leg. Neither stopping rule certifies the total derivative
through changing adaptation: the omitted chain term is0.0193509, FD stable to
3.70e-8. Fixed-theta k5→9 objective change+0.000269237; k9→15 -0.00000396228.
These are one-model numerical observations, not adequacy or coverage claims.

## Representation and compatibility
Extend PoissonFit with optional concrete AGHQ integration metadata. Preserve old
positional constructors with integration=nothing. Do not duplicate the complete
postfit dispatch family in a new Poisson result type. Populate integration when
AGHQ is requested, including any source-authorized Laplace fallback.

Metadata must retain requested control, actual integration, used boolean,
requested/resolved node count, k^K, normalized controls, unpenalized ridge=Inf,
observed-curvature convention, final frozen caches, gradients and their kind,
mode health/shift, repair diagnostics, stop reason, passes, every start and chosen
start, and model-input identity. Copy retained arrays; caller changes to inputs
must not mutate the fitted objective. Retain mask/offset and an input digest so
inference cannot rebuild an estimator against different observations by accident.
The existing hessian field still describes Laplace curvature; it is not enough
for quadrature metadata.

## Public controls and fallback
Direct Julia uses aghq=false by default, positive integer nodes or auto selection
(true/:auto); exact admitted compatibility adapters recorded separately. k1
routes to the existing Laplace optimizer before ineligibility warnings. Auto
uses frozen affordability/trait rules (20 TRAITS cutoff); explicit numeric k
bypasses the trait cutoff, not structural eligibility. Even k2 is valid.
Validate all controls before fitting; unknown keys and invalid values fail clearly.
No loading ridge or automatic-ridge policy is admitted.

A structurally ineligible request retains the existing Laplace route with an
explicit warning and requested-versus-actual provenance. Do not add undocumented
"safety" fallbacks. The direct Poisson route, generic family dispatcher, formula
route and R bridge each need separate reachability/fallback evidence; successful
direct Poisson coverage cannot stand in for all families or all surfaces.

## Objective, multistart and fitted methods
Warm start comes from Laplace. The second reference-compatible start sets all
raw loading coordinates to.3; both optimize independently. Converged usable
finite results rank before nonconverged ones, then lowest final objective;
first wins exact ties. All-unusable attempts return no selected result; public
fallback must be explicit. The internal multistart wrapper now owns this rule.

PoissonFit.loglik and theta_packed must come from the selected final frozen-cache
AGHQ objective, not a Laplace reconstruction. Existing loglik/AIC/BIC parameter
counting can then remain unchanged. getLV uses retained modes for the matching
fitted-input signature; new-data conditional modes are predictions, not fitted
state. Prediction/residual methods must thread mask/offset and handle missing
responses consistently. Show/summary name AGHQ nodes, observed adaptation,
unpenalized state, convergence and any fallback reason. Simulation uses the same
response law and offsets; it does not silently change integration controls on refit.

## Inference
Change default objective selector from :laplace to :fit, preserving Laplace
behavior for ordinary old fits. AGHQ :fit rebuilds the final FROZEN objective,
matching R's final tmb_obj substitution, sdreport and tmbprofile behavior.
Use its AD Hessian for Wald; verify against FD. Profile uses that same objective;
bootstrap refits with the same normalized AGHQ controls and health accounting.
VA remains excluded. An explicit alternative objective must be clearly labeled
as a sensitivity fit; it must never become the default accidentally.

Generic _family_wald currently inverts a symmetric matrix and inspects only the
inverse diagonal. That does not certify positive definiteness. Repair as its own
regression-tested numerical change: Cholesky SPD check before solving; failed
curvature returns pd_hessian=false and NaN SEs, never a pseudoinverse or a silent
ridge. This is needed before broad inference claims, not proof of recovery.

The Poisson adapter presently rejects invalid observed curvature. Its exact
H=I+Lambda'diag(mu)Lambda is mathematically positive; non-PD numeric trials require
explicit diagnosis. Generic aghq_adaptation already implements/tested frozen-R
failed-Cholesky eigenfloor and diagnostic branches. Their public reachability and
admissibility at a checked mode must be resolved visibly; do not label all repair
obligations done merely from generic helper tests or blindly repair invalid trials.

## Execution leaves and required tests
1. Parent: src/families/aghq_outer.jl multistart + named AM tests and paired runner.
2. Parent: new concrete metadata/control file, src/families/poisson.jl constructor
   compatibility/public keywords; validate no default-objective change.
3. Parent: src/confint_family.jl SPD regression and estimator-aware Poisson adapter;
   src/postfit.jl and src/simulate_fit.jl identity/mask/offset branches.
4. Parent: src/families/fit_gllvm.jl + src/formula.jl reachability/fallback cascade;
   source-bound original-fixture public tests, same-point R equality, modes,
   multistart, invalid controls, default/k1 equivalence, :fit inference identity.
5. Same public slice: docstrings, README, docs/src tutorial/reference, CHANGELOG,
   scoped check-log/after-task; executed example and strict Documenter validation.

File leases remain full-file and exclusive. No B production children dispatched
before programme checkpoint. B6 family expansion and all required cases remain
unpaid until implemented and verified. Runs >30minutes require sized pre-run and
approval; targeted tests use Totoro, large recovery/coverage/benchmark uses DRAC.
