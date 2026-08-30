# Required delta-family model contracts

Two existing required IDs now execute same-model checks rather than the preserved shared-dispersion diagnostics. Reference: gllvmTMB `b4d5fee64def88bc768dda1f1f77c29b295edd86`. This subset is qualified; the full Core contract remains DRAFT.

| Case | Original fixture | Required native call | Required wrapper |
|---|---|---|---|
| NATIVE-13-DELTA-LOGNORMAL | seed61, p5,K1,n130 | fit_delta_lognormal_gllvm(Y; K=1,predictor=:shared,disp_group=:species,hessian=:observed) | test/parity/test_delta_lognormal_required.jl |
| NATIVE-14-DELTA-GAMMA | seed62, p5,K1,n130 | fit_delta_gamma_gllvm(Y; K=1,predictor=:shared,disp_group=:species,hessian=:observed) | test/parity/test_delta_gamma_required.jl |

Owner: parent/Hopper integration. Original fixture files and response bytes are unchanged. The callable checker extracts and executes their exact DGP blocks. Required and optional developer routes are separate; neither old inequality-only diagnostic can supply a required delta receipt.

Frozen R call: `gllvmTMB(value ~ 0 + trait + latent(0 + trait | site,d=K,unique=FALSE), data=df_long,unit="site",trait="trait",family=delta_lognormal()/delta_gamma(),control=...)`. Start with public n_init=1L,se=FALSE; then public start_from plus nlminb rel.tol=1e-12,eval.max=2000,iter.max=1500. Exact TMB data/maps/parameter names are asserted unchanged between fits. No oracle-engine change.

Both parts share one predictor. Lognormal uses per-trait log-scale SD; Gamma uses per-trait shape alpha in Julia and CV phi in R, alpha=1/phi². Both retain likelihood normalization and observed joint curvature. K1 has five intercepts, five loading coordinates and five dispersion coordinates, fifteen free parameters. Sign-invariant likelihood is compared; raw loadings are not required to share sign.

## Predeclared acceptance and current evidence
Both optimizer flags, finite parameter/dispersion vectors, fifteen free parameters, absolute raw gradients<=1e-4, finite-difference stability<=1e-4, native objective reevaluation<=1e-8, and likelihood rtol1e-6. Native gradient checks use central differences at h=cbrt(eps)*max(1,abs(theta)) and2h in explicit beta/packed-loading/log-dispersion coordinates. No relaxed tolerance or replacement dataset.

| Family | Absolute logLik difference | Native max gradient | Refined R max gradient | Default R max gradient |
|---|---:|---:|---:|---:|
| Delta-lognormal | 1.3154e-10 | 7.3126e-6 | 3.6795e-5 | 6.2050e-4 (failed) |
| Delta-Gamma | 2.0009e-10 | 9.3120e-6 | 4.3240e-5 | 1.6053e-3 (failed) |

Required runner48/48 assertions PASS (24 each), Totoro Julia1.12.6/R4.5.3, one thread,30.40s process including compile; not a benchmark. Default attempt failed only R gradients in both cases. Intermediate callable-harness world-age failure occurred before fits; retained. Oracle integrity verified before/after. Evidence: delta-matched-evidence.json and raw .unlazy/core070-aghq/delta-matched/.

The Julia and Python execution inventories include the callable tool and both original DGP files in addition to required wrappers, so helper changes invalidate receipts. Seven corrupt/scope/model/data controls reject; aggregate collection eight tests pass; full programme aggregator still rejects DRAFT.

## Limits
These are two ordinary loadings-only no-X fitted likelihood cells with health checks, not all delta link/offset/covariance/data/postfit/formula/bridge combinations, recovery or coverage. No public API change, engine repair, fullsuite, speed, release or independent panel claim. Student health and the finite full manifest remain unresolved.
