# Frozen family facts and Julia entry points

Status: **entry checks only; full capability manifest remains DRAFT**.

All69 frozen-R family facts are accounted for:21 required admissions,1 alias,33 rejections and14 constructor-only exclusions. Frozen R69 descriptor checks pass. All22 candidate Julia calls reach the deliberate response-read exception, with no response values or fits. This proves that each call gets as far as data access; validation later in the fitter, convergence and same-model parity remain unpaid.

The first run retained21passes/1failure from a misspelled Julia link name in this catalogue. Correcting it to `CLogLogLink()` gave22passes in9.388s. Expectations did not change. Six contract corruption controls pass.

## Candidate admitted routes

| Frozen fact | Native call | Model boundary |
|---|---|---|

| FAMILY-00-IDENTITY | `fit_gaussian_gllvm(Y; K=1)` | Shared residual SD; existing fixture centres traits to align the zero-mean Julia route. Per-trait variance and nonzero means require separate cases. |

| FAMILY-01-LOGIT | `fit_binomial_gllvm(Y; K=1, link=LogitLink())` | Bernoulli control N=1; varying trials, links and curvature require separate model cases. |

| FAMILY-02-LOG | `fit_poisson_gllvm(Y; K=1, link=LogLink())` | Log mean; counts; no dispersion. |

| FAMILY-03-LOG | `fit_lognormal_gllvm(Y; K=1, link=LogLink())` | Shared scalar sigma_eps, not per-trait delta sigma; log-response Gaussian likelihood includes minus sum(log(y)). |

| FAMILY-04-LOG | `fit_gamma_gllvm_grouped(Y; K=1, group=[1,2,3], link=LogLink())` | Per-trait Gamma shape; generic Gamma default shared shape is not the default-R comparison. |

| FAMILY-05-LOG | `fit_gllvm(Y; family=GLLVM.NegativeBinomial(), K=1, link=LogLink())` | Per-trait NB2 size r on the generic route; original smoke tolerance1e-3 is weaker than required1e-6. |

| FAMILY-06-LOG | `fit_tweedie_gllvm_grouped(Y; K=1, power_group=:species, link=LogLink())` | R default has per-trait estimated power and dispersion. Fixed common and shared estimated power remain distinct contracts. |

| FAMILY-07-LOGIT | `fit_gllvm(Y; family=GLLVM.Beta(), K=1, link=LogitLink())` | Per-trait Beta precision, not shared precision. |

| FAMILY-08-LOGIT | `fit_beta_binomial_gllvm_grouped(Y; K=1, N=N, group=[1,2,3], link=LogitLink())` | Per-trait precision with explicit trial matrix N; binomial trials are not a disposable presentation detail. |

| FAMILY-09-IDENTITY | `fit_studentt_gllvm(Y; K=1, nu=nothing, disp_group=:species, link=IdentityLink())` | Per-trait estimated df>1 and scale; original required fixture still fails R fit-health. |

| FAMILY-10-LOG | `fit_truncated_poisson_gllvm(Y; K=1, link=LogLink())` | Zero-truncated Poisson normalization retained; counts strictly positive. |

| FAMILY-11-LOG | `fit_truncated_nbinom2_gllvm_pertrait(Y; K=1, link=LogLink())` | Per-trait NB2 size, zero-truncation normalization; original fitted-health gate unpaid. |

| FAMILY-12-LOGIT-LOG | `fit_delta_lognormal_gllvm(Y; K=1, predictor=:shared, disp_group=:species, hessian=:observed)` | Logit presence/log positive component, shared predictor and per-trait positive scale. |

| FAMILY-13-LOGIT-LOG | `fit_delta_gamma_gllvm(Y; K=1, predictor=:shared, disp_group=:species, hessian=:observed)` | Logit presence/log positive component, shared predictor and per-trait Gamma shape. |

| FAMILY-14-PROBIT | `fit_ordinal_gllvm_pertrait(Y; K=1, link=ProbitLink())` | Probit link and per-trait cutpoints; do not substitute native default logit. |

| FAMILY-15-LOG | `fit_nb1_gllvm_grouped(Y; K=1, group=[1,2,3], link=LogLink())` | Per-trait NB1 linear-variance dispersion. |

| FAMILY-16-LOGIT | `fit_multinomial_gllvm(labels; n_categories=3)` | Existing native fixed-effects categorical-label adapter only; latent/structured multinomial remains a required gap. |

| FAMILY-01-PROBIT | `fit_binomial_gllvm(Y; K=1, link=ProbitLink())` | Bernoulli control N=1; varying trials, links and curvature require separate model cases. |

| FAMILY-01-CLOGLOG | `fit_binomial_gllvm(Y; K=1, link=CLogLogLink())` | Bernoulli control N=1; varying trials, links and curvature require separate model cases. Explicit observed curvature is required by the qualified six-model comparison; this entry probe does not choose a fitted estimator. |

| FAMILY-BETA-ALIAS | `fit_gllvm(Y; family=GLLVM.Beta(), K=1, link=LogitLink())` | Per-trait Beta precision, not shared precision. |

| FAMILY-06-FIXED-SHAPE | `fit_tweedie_gllvm_grouped(Y; K=1, power=1.5, link=LogLink())` | Fixed common power1.5, per-trait dispersion; not the default estimated-power model. |

| FAMILY-09-FIXED-SHAPE | `fit_studentt_gllvm(Y; K=1, nu=4.0, disp_group=:species, link=IdentityLink())` | Fixed common df4, per-trait scales; not the required estimated-df fixture. |


## Remaining work

- Bind each admitted row to full fitted cases, diagnostics and estimands, using the linked existing seeded fixtures only where their model and acceptance contract match. A whole family requires more than its default no-X model.

- Keep fixed/shared/per-trait Tweedie power separate, preserve Student fixed/free df, compare Gaussian means/dispersion explicitly, and retain delta predictor/dispersion choices.

- Design equivalent native/formula/bridge rejection or extension checks for the33 R rejected descriptors. R syntax alone does not define an obligation to reject a valid Julia extension.

- Multinomial fixed effects cannot satisfy required latent/structured support. Formula and bridge execution remain unpaid for every row in this catalogue.

- Original Student/truncated-NB2 fitted health and the NB2 smoke tolerance gap remain open. No full-fitted completion or required-case promotion occurred.


The authoritative row-by-row contract is `family-route-contract.json`; its source hashes include the current Julia engine and frozen family source inventory. Verify with `python3 tools/core070_family_routes.py --verify`. Full source-to-case coverage still requires the separate `required-source-case-map.json` and independent scope review.
