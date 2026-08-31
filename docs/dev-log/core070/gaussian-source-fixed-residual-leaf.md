# Gaussian source fixed residual implementation leaf

Frozen R b4d5fee ordinary independent modes fix residual SD to
max(0.001*sd(y),1e-6); current native source fitter estimates it. Preserve the
exact R model by adding sigma_eps_fixed=nothing (existing free default) or a
strictly positive finite Float64-representable real, excluding Bool.

OWNS: worker src/source_fit.jl only after parent captures the failing regression;
parent test/test_gaussian_sources_fixed_residual.jl, central test runner,
README/CHANGELOG/Documenter/math/logs and runtime verification. Other lanes
untouched. Worker must not alter other edits or run local numerical fits.

Model: vec(Y)~N(vec(beta),V), V=sigma_fixed^2 I+sum kron(P C P',B).
Optimize beta and covariance parameters only; evaluate full normalized likelihood.
Gradient and Hessian exclude the fixed coordinate. parameters/start contain
only free coordinates. Retain residual_fixed provenance; dof counts free
coordinates. Old13-field fit construction defaults to free residual. Constant
responses are admitted with positive fixed noise, but remain rejected under
free residual variance. No ridge, suppression heuristic, zero-noise boundary,
reparameterization or changed default. User supplies exact reference noise.

CHECK: test_gaussian_sources_fixed_residual.jl first fails unsupported keyword;
then analytic mean-only and ordinary common/independent Gaussian ML controls,
constant-data, parameter-count, copied-start, invalid-input and old-constructor
checks pass. Existing test_gaussian_sources.jl remains unchanged and passes.
EXPECT: no analytic tolerance relaxation; actual source snapshot and runtime pins.

Totoro one Julia/BLAS thread. Red estimate<1minute, green1–3minutes, each main
cap240s and supervisor300s. Qualified current Manifest, no installs. Documentation
strict build later estimate3–8minutes with590second cap; no deployment. Exact
frozen-R mode comparisons remain separate from analytic validation and full
Core/AGHQ/recovery completion.


Paired addendum before execution: the same frozen fixture MODE-ORD-INDEP and
MODE-ORD-COMMON runs through actual public R fitting; exact fixed residual map,
free counts6/4, same normalized likelihood<=1e-6, means/covariance<=1e-5 and
both-engine health are required. New native unit checks plus the existing117
unit assertions and six nonspatial fitted source pairs run as regressions.
Strict Documenter executes the fixed-noise tutorial on the same snapshot.
Combined Totoro estimate4–11minutes,15minute supervisor cap; no installs.
