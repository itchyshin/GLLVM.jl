# GU — Public Gaussian Stage1a integration

Programme ACTIVE/M1 PARTIAL; full manifest remains DRAFT_NOT_FROZEN.
Parent OWNS src/fit.jl, src/families/aghq_fit_info.jl, new
src/families/aghq_gaussian_fit.jl, central module/test include, Gaussian postfit
and interval dispatch, named tests/runners/verifier and coordinated docs.
No foreign/R engine changes. Frozen R b4d5fee64def88bc768dda1f1f77c29b295edd86.

Preserve legacy seven-argument GllvmFit constructor and exact fitter numeric body.
aghq=false remains exact Gaussian (Laplace is exact here), default X=nothing
means ZERO mean. Complete X[p,n,q] includes all fixed effects; preserve beta-fixed
zero restrictions and use only free columns in numerical theta. Shared sigma.
Requested/actual nodes and integration, stopping reason, both starts, controls,
data identity and checked observed caches are retained in integration metadata.

Positive nodes or auto accepted; k1 exact/Laplace. Eligible ordinary loadings-only
block K<=5; auto at p>=20 and structured/predictor-latent requests fall back to
existing exact/Laplace with warning and visible provenance. Invalid controls fail.
No ridge. Genuine aghq_multistart_optimize runs on both starts; shared-SD exact fit
may initialize but must never be returned with a fabricated AGHQ label. Convergence
uses the declared frozen-surrogate gradient, not derivatives through moving nodes.

Masks and offsets must define the actual Gaussian objective. For ordinary masked
or offset fitting, optimize the independent observed-submatrix exact marginal as
baseline; imputation is allowed only for warm initialization, never the target.
Unsupported structured+mask/offset combinations must fail clearly until their
separate contract is implemented, not fit an imputed model. Missing-predictor
models remain outside Stage1a; finite complete X is required.

Postfit: retained X/mask/offset and original response identity; correct trait
shape checked before zero-score returns. New X and offsets must be explicit when
needed for changed data. Scores are checked conditional modes; Gaussian prediction
identity link, residuals reflect omitted cells, simulation retains original design
and offsets. Inference must bind observed-data identity and differentiate the
fitted frozen objective; preserve fixed coefficient packing. Full covariance
requires a positive-definite Hessian, not diagonal inverse positivity alone.
Wald/profile/bootstrap and existing Gaussian named aliases must not silently use
a different estimator. Failed bootstrap rows retained with matching fit controls.

GU01 legacy constructor/off/k1 equality, generic and formula forwarding; auto and
structured rejection/fallbacks, invalid controls, retained estimator metadata.
GU02 zero mean vs explicit intercept X, fixed beta masks, heterogeneous X/offset,
missing responses and masks, original identity and new-data errors, copied data.
GU03 original seed42 Gaussian fixture k5 public paired R run: no DGP/threshold
change, both health rules, absolute deltaLL<=1e-3, samepoint<=1e-6, covariance and
sigma<=1e-4. Every start retained; no narrowing original case.
GU04 same-objective inference, AD vs FD Hessian, profile and bounded bootstrap,
malformed/changed input refusal, no silent fallback to ordinary inference.
GU05 strict docs, source/log/env/fixture artifact pins, failing gate controls.

Totoro targeted runs estimate2–5min capped300s; docs3–8min capped590s. Retain
oraclebefore/after. No >30min campaign, fullsuite or DRAC submission in this leaf.
Large recovery/coverage and fullsuite remain explicit programme requirements.
