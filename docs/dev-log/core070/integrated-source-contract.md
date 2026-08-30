# Integrated-source admission: frozen R source findings

Status: **source-inspected, executable cases not yet frozen or validated**.
Reference: `b4d5fee64def88bc768dda1f1f77c29b295edd86`, extracted from the retained
oracle archive. This is a required data/model contract question, not permission
to import the separate R0.7.1 or article lane.

The public exports `isdm_source()` and `isdm_sources()` are called by the actual
fit path. The experimental interface label does not make them part of the
user-excluded variational/MSPL/automatic-ridge estimation policies. Their Julia
equivalent should expose the same model and information without copying R
syntax. Implementation and live paired evidence remain unpaid.

## Model and call path

All sources share a trait's ecological linear predictor. For known support
`a > 0`, count rows use `Poisson(a exp(eta))`; detection rows use
`Bernoulli(1 - exp(-a exp(eta)))`, so `log(a)` is an offset on the log/cloglog
scale. Source-specific observation predictors can contribute masked fixed
effects. This yields relative intensity, not identified absolute abundance,
occupancy, detectability or a causal effect.

- `R/isdm-sources.R:15`: only Poisson-log and binomial-cloglog laws.
- `:48`: `isdm_source` checks family-object type and one-sided formula. It does
  **not** itself enforce the admitted law; `isdm_sources` does that later.
- `:116`: at least two unique nonempty named sources; at least one count arm;
  preserves source observation formulas as attributes.
- `R/fit-multi.R:204`: named family alignment reorders the laws and observation
  formulas together and rejects partial, duplicate or nonmatching names.
- `:279`, `:983`: rebuilds declared laws from names and family objects, then
  applies the common validator. Constructor metadata is not the admission key.
- `R/isdm-sources.R:253`: mixed count/detection exception requires exact row-law
  mapping, every declared source present, and every trait represented in every
  source. Source presence is not a balanced design or an observed-response check.
- `R/fit-multi.R:1009`: varying families within a trait are rejected unless the
  exact integrated-source exception holds. An all-count declaration does not
  need this exception; `FALSE` from its predicate is **not** a fit rejection.
- `:2712`: build source-masked observation columns after ecological fixed effects.
- `:2732`, `R/offset.R:157`: admit nonzero cloglog support offsets only through
  the integrated exception. Nonfinite offsets always reject.
- `R/fit-multi.R:2793`: mixed integrated fits reject any supplied weights and
  detection trial counts other than one. Repeated visits use separate rows.

## Cases to expand into the full executable manifest

These stable draft IDs distinguish constructor, structural and fit-stage gates.
None currently counts as a numerical PASS.

| Draft ID | Required case and acceptance boundary |
|---|---|
| DATA-ISDM-01 | Two count sources: constructor succeeds; mixed-exception predicate false; ordinary count path remains eligible. |
| DATA-ISDM-02 | One count and one detection source for every trait: shared-intensity exception succeeds. |
| DATA-ISDM-03 | Three or more sources, each represented within each trait: same contract; no hardcoded two-source restriction. |
| DATA-ISDM-04 | All-detection declaration: constructor rejection. |
| DATA-ISDM-05 | Logit/probit detection or dispersion-carrying law: source-list constructor rejection, even when `isdm_source` accepted the family object. |
| DATA-ISDM-06 | Fewer than two, unnamed, partially named or duplicate source labels: constructor rejection. |
| DATA-ISDM-07 | Reordered source factor/list levels: laws and observation formulas stay attached to their named source. |
| DATA-ISDM-08 | Missing/extra selector labels or a declared source with no rows: exception rejects. |
| DATA-ISDM-09 | Every source globally present but not within every trait: exception rejects. |
| DATA-ISDM-10 | Row family/link mapping inconsistent with source declaration: exception rejects. |
| DATA-ISDM-11 | Unbalanced source counts within a trait: presence criterion alone admits; do not assert balanced information. |
| DATA-ISDM-12 | Response-masked source arm: structural presence can hold with no observed response; exercise actual masking and fit health separately. |
| DATA-ISDM-13 | Source observation covariates absent/NA outside their own rows: no contamination; generated columns zero elsewhere. |
| DATA-ISDM-14 | Missing observation variable or NA within its own source: design construction rejects. |
| DATA-ISDM-15 | Two-sided observation formula/non-family descriptor: wrapper rejects. |
| DATA-ISDM-16 | Aliased source intercept/factor columns: preserve ecological columns first, add only rank-increasing source columns, report omissions. |
| DATA-ISDM-17 | Top-level source fixed effects plus wrapped observation formulas: reject duplicate ownership. |
| DATA-ISDM-18 | Known positive support changes count/detection means coherently; compare paired likelihood and predictions, not raw alias-dependent coefficients. |
| DATA-ISDM-19 | Nonfinite support offset: reject; ordinary non-count offset must not inherit integrated exemption. |
| DATA-ISDM-20 | Mixed integrated weights or multi-trial detection: reject; all-count ordinary weights retain their separate weighted-objective restrictions. |
| DATA-ISDM-21 | Legacy named two-source route: compatibility adapter to the same core, retaining its source-column checks. |
| DATA-ISDM-22 | Source-specific spatial latent slope: intersect covariance admission with exact `isdm_gbif` name and actual 0/1 values (`fit-multi.R:1544`); arbitrary renamed continuous covariates must fail. |

Next work must supply reference/Julia calls, deterministic fixtures, identified
quantities, numerical rules, owners and receipts for these rows, deduplicating
them against general mixed-family, covariance, weights, offset and missing-data
obligations. A pure source predicate replay can verify admission branches, but
cannot substitute for design-matrix, fitted-model, native/formula/bridge or
recovery evidence. The separate article prior repair is a risk lead for later
covariance validation, not a reason to change this frozen R reference.
