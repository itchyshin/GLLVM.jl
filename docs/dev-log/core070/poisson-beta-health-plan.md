# Original Poisson and Beta qualification

The original fit tests contain a likelihood comparison but omit several required
fit-health checks. This slice retains their complete data-generating code,
seeds, shapes, native calls, R controls and likelihood tolerances. It qualifies
those same models; it does not create easier replacement fixtures.

For site s and trait t, eta_ts = beta_t + lambda_t' z_s, z_s ~ N(0,I).
Poisson: Y_ts ~ Poisson(exp(eta_ts)). Beta: Y_ts ~ Beta(mu_ts phi_t,
(1-mu_ts) phi_t), mu_ts = logistic(eta_ts). Neither model has a unique variance,
fixed covariates, offsets or missing cells. Poisson uses K=2, Beta K=1.

| Quantity | Original DGP | Native/R fit | Check |
|---|---|---|---|
| Intercepts | Original beta, seeds44/45 | Five free beta | Raw parameter count and objective |
| Loadings | Original mild loadings, standard normal scores | Reduced-rank triangular packing, no unique component | Same-point NLL after mapping R parameters |
| Poisson rate | exp(beta + Lambda Z) | Log link, no dispersion | Canonical observed = Fisher curvature |
| Beta precision | phi_true=12 shared in DGP | Five free trait precisions in both fits | Positive length-five vectors and 15 free parameters |
| Integration | Conditional sampling | Laplace; Beta observed curvature | Native objective rebuild; R fn re-evaluation |
| Normalization | Poisson counts / continuous Beta density | Full family likelihood constants | Same-point NLL tolerance1e-6 |

Original fixtures stay byte-identical. The qualification script executes their
original sampler and pre-fit source block, saves realized responses before
fitting, then runs the exact original calls. Contract and source bytes are pinned
before transfer. No native or R engine edits and no tuning in this slice.

Acceptance: both optimizers report convergence, finite objectives and parameters;
raw gradients <=1e-4 in both engines; native central finite differences at scaled
cbrt(eps) and twice that agree within1e-4. Native and R objective re-evaluations
must agree with reports within1e-8; R cached objective uses1e-10. Same-point NLL
agreement <=1e-6. Existing logLik rtol1e-6 is unchanged. Poisson14 and Beta15 free
parameters. Retain raw R opt/gradient/parameters/report/data/map/random metadata.

Files: tools/core070_poisson_beta_health.jl, contract JSON, scoped verifier and
negative-control tool, this plan and closure records. The parent owns all writes.
No production children. Runtime leaf: .unlazy/core070-aghq/poisson-beta-health-01/GATES.md.
Estimate2–4min on Totoro, one BLAS/Julia thread, stop after300s. Large recovery
and performance campaigns remain on DRAC after a separately sized pre-run.

These checks can discover fit or harness failures. A failed required fixture is
retained and blocks its qualification; no tolerance change, new seed, or
boundary relabeling removes it. Formula/R bridge, recovery, covariance and
full-family completion remain separate work. The full manifest is still draft.

## Diagnosed default stopping and explicit refinement

The original run retained28 passing checks and two failed R raw-gradient checks.
It exited1 and emitted no success marker. Native gradients and same-point
objectives passed for both original models. R's public start_from refinement is
predeclared separately in poisson-beta-refinement-contract.json: default nlminb,
rel.tol1e-12, eval.max2000, iter.max1500, all original parameters still free.
Both initial and refined R opt/gradient/data/map states are retained. The gate
checks exact data/map/free-name preservation and byte-identical native estimates
across attempts. This changes the R stopping policy, not its likelihood or model.

Noether's source review confirmed the parameter mapping and public refinement
route. His initial concern about failed checks producing success was withdrawn
after inspecting finish_run!, which already rejects failed cells. The useful
pre-run concern is addressed with fixed contract, fixture and DGP SHA locks before
loading the fit toolchain. --check exercises those locks without any fits.
The complete health runner remains a separate qualification packet; integration
into the default required17-family runner is the next step, not implied here.
