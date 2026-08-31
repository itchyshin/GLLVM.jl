# Default Gaussian unique variance — direct native contract

The pre-implementation math/ownership contract is
../decisions/2026-08-31-fixed-residual-unique-gaussian.md, with initial executable
regression/gates under .unlazy/core070-aghq/default-unique-red-01.

Model: Gaussian p4/n120/K1, zero-column X, original retained admission seed81031
realization. R formula `value ~ 0 + latent(0 + trait | site, d=1)` uses default
unique=TRUE. Its residual SD is fixed at max(.001*sd(vec(Y)),1e-6), not estimated.
Native `fit_gaussian_pervar_gllvm(...;fixed_residual_sd=c,X=zeros(p,n,0),K=1)`
estimates four raw loadings and four unique log variances. R's theta_rr_B is raw
loadings; theta_diag_B is unique log SD, so the native log variance is twice it.
Report phi2=psi2+c² with both psi2 and c retained. Eight free parameters in both.

Reference is b4d5fee64def88bc768dda1f1f77c29b295edd86. Public BFGS controls are
identical to the previously qualified Gaussian admission runner. The R helper
is copied verbatim from its embedded R block; no R engine or fixture change.
Reference provenance checks run before/after fitting and inside RCall loading.

Acceptance before paired execution: normalized NLL/gradient at independent
fixed coordinates <=1e-6; native at R endpoint NLL <=1e-6; R at native endpoint
NLL <=1e-6; fitted absdeltaLL<=1e-3; convergence plus absolute gradient<=1e-4 OR
relativegradient<=1e-6 in each engine (the original admission health rule).
This observed pair passes the stricter absolute gradient criterion in both.
No threshold was changed after observing a fit.

Reproduction uses tools/core070_default_unique_pair.jl with prepared fixture.toml
(the saved admission fixtures), reference.R (tools/core070_default_unique_reference.R),
and the same pinned R/parity environment. The successful run executed byte-identical
copies under run.jl/reference.R. All commands/inputs/source hashes are retained.
Unit tests live in test/test_gaussian_fixed_residual.jl and the central runner.

Implementation slice owns src/families/gaussian_pervar.jl, named tests and
associated docs; existing has_diag/shared-sigma engines stay unchanged. Native
formula/bridge/AGHQ metadata and calibrated inference remain required future work.
Independent Noether review dispatch was rejected by the safety gate; no review
verdict or alternative dispatch is claimed. Specific payload approval was requested.
