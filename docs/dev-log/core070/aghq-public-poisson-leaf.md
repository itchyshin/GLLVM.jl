# PU — public Poisson AGHQ implementation leaf

Implements the reviewed aghq-public-integration-contract.md for ordinary log-link
Poisson first. This does not qualify other families, structured routes or the R
bridge. Formula intercept-only route must forward controls to the same fitter.
No change to default Laplace numeric path or old PoissonFit positional constructors.

Public call: fit_poisson_gllvm(Y;K,aghq=false,aghq_control=(;),kwargs...).
aghq accepts false/nothing (off), true/:auto, or positive non-Bool integer nodes;
valid even2, k1 actual Laplace. Controls are a strictly validated NamedTuple:
outer-loop names plus multistart and mode_gradient_tol. Default unpenalized only.
Requested ineligible direct routes (X_lv, K0, K>5, auto p>=20, non-log link)
retain Laplace with explicit warning/reason except k1. No new implicit ridge.

PoissonFit gains optional concrete integration metadata containing requested
and actual integration, node count, controls, selected run/all start outcomes,
final observed caches, input identity and copies of observed counts/mask/offset.
Default old constructors have integration=nothing. AGHQ loglik/theta_packed use
the selected frozen objective. getLV/predict/residuals on matching data use
retained modes and offsets, new data requires explicit offsets where necessary.

Inference defaults to objective=:fit. AGHQ uses its final fixed caches for AD
Wald and profile; bootstrap simulates/refits the same controls and keeps failures.
Explicit objective=:laplace sensitivity may be rejected initially rather than
mislabelled; :va cannot be applied to AGHQ. Generic Wald must reject indefinite
H even with a positive inverse diagonal. No pseudoinverse, ridge or tolerance
widening. Failed PD returns all NaN standard errors and pd_hessian=false.

Checks before implementation:
PU01 old constructor/default/k1 equivalence; public controls and direct warnings.
PU02 actual public k5 original seed44 paired R fit (existing APP thresholds),
metadata/loglik/caches/inputs/trace, generic and intercept-only formula reachability.
PU03 exact-data latent modes/predictions/offsets/masks and input immutability;
invalid shape/foreign input/mismatched inference rejected; simulation law preserved.
PU04 frozen-objective inference identity; AD Hessian versus FD; beta Wald SEs
versus the same-point R frozen Hessian; one profile interval and ten bootstrap
refits retained as a functional smoke, not coverage. Generic indefinite/SPD guards.
PU05 docs updated atomically (README, quickstart/reference, CHANGELOG, docstrings),
existing relevant tests and strict Documenter build attempted with source pins.

Parent owns full files src/families/poisson.jl,aghq_poisson.jl,new metadata/fit
files, src/GLLVM.jl,postfit.jl,simulate_fit.jl,confint_family.jl and central test
includes; named PU tests/runner, Project.toml for SHA stdlib identity, docs/records.
No foreign writers. No new B production child; independent numerical review.
Totoro one Julia/BLAS thread, fit test estimate2–5minutes, hard300s cap; split
if needed before launching. Full package85–100min remains separately gated.
