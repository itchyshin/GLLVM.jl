# Family model catalogue reconciliation

This source audit corrects the **existing smoke catalogue**, not the frozen
programme contract. No fixtures, seeds, likelihood tolerances or engines changed.
Numerical evidence was not regenerated. Exact fixture/helper hashes are in
`family-model-catalogue.json`; every record remains NOT_REEXECUTED.

| Family smoke ID | Seed | Traits | Units | Latent factors | Existing likelihood check |
|---|---:|---:|---:|---:|---|
| NATIVE-01-GAUSSIAN | 42 | 5 | 80 | 2 | relative 1e-06 |
| NATIVE-02-BINOMIAL | 43 | 5 | 60 | 2 | relative 1e-06 |
| NATIVE-03-POISSON | 44 | 5 | 60 | 2 | relative 1e-06 |
| NATIVE-04-LOGNORMAL | 52 | 5 | 60 | 2 | relative 1e-06 |
| NATIVE-05-GAMMA | 54 | 5 | 120 | 1 | relative 1e-06 |
| NATIVE-06-NB2 | 45 | 5 | 80 | 2 | relative 0.001 |
| NATIVE-07-TWEEDIE | 82 | 5 | 150 | 1 | absolute 1e-06 |
| NATIVE-08-BETA | 45 | 5 | 60 | 1 | relative 1e-06 |
| NATIVE-09-BETABINOMIAL | 56 | 5 | 120 | 1 | relative 1e-06 |
| NATIVE-10-STUDENT | 71 | 5 | 130 | 1 | absolute 0.001 |
| NATIVE-11-TRUNCATED-POISSON | 53 | 5 | 60 | 2 | relative 1e-06 |
| NATIVE-12-TRUNCATED-NB2 | 58 | 5 | 120 | 1 | relative 1e-06 |
| NATIVE-13-DELTA-LOGNORMAL | 61 | 5 | 130 | 1 | relative 1e-06 |
| NATIVE-14-DELTA-GAMMA | 62 | 5 | 130 | 1 | relative 1e-06 |
| NATIVE-15-ORDINAL-PROBIT | 46 | 5 | 60 | 1 | relative 1e-06 |
| NATIVE-16-NB1 | 55 | 5 | 120 | 1 | relative 1e-06 |
| NATIVE-17-MULTINOMIAL-FIXED | 57 | 1 | 400 | 0 | relative 1e-06 |

The multinomial response has four categories, one response trait and zero latent
factors. Its analytic multinomial anchor is useful, but cannot stand in for the
required structured model. Gaussian also compares residual scale and covariance;
lognormal checks the Jacobian and scale shifts. Ordinal uses three categories
and per-trait cutpoints with the first threshold fixed at zero. Beta-binomial
uses eight trials. Three Tweedie power contracts and the five Student test roles
are kept explicit in the JSON; they are not independent successful receipts.

## Blocking findings

- **FAMILY-LINK-PROBIT** (A3/B2/B5): R binomial probit admitted; 17-ID smoke uses logit only. Native/formula/bridge and actual observed curvature need paired model fixture.
- **FAMILY-LINK-CLOGLOG** (A3/B2/B5): R binomial cloglog admitted. Julia Fisher default versus R observed curvature and saturation health need explicit estimator contract; no logit substitution.
- **NB2-TOLERANCE** (A3): Current seed45 test uses rtol1e-3, weaker than project R-parity1e-6. Do not promote the current passing smoke. Diagnose original case at tighter requirement; no tolerance edit or fit performed in this audit.
- **BINOMIAL-TRIALS** (A3/B4/B5): Base binomial fixture is Bernoulli. Shared R helper accepts N but currently supplies weights only for betabinomial, so passing N to binomial does not implement trials parity.
- **FAMILY-MODEL-VARIANTS** (A3): Default smoke does not cover all admitted dispersion grouping, masks, offsets, X, mixed family, missing data or covariance interactions. Do not form an unreviewed Cartesian product.
- **MULTINOMIAL-STRUCTURED** (B3): Current row is n=400,C=4,K=0 exact fixed-effects likelihood. It pays no latent, animal or structured multinomial obligation.
- **HEALTH-AND-INTERFACES** (A3/B4/B5): Converged flags and likelihood-only checks do not discharge original fit-health, inference, formula or public bridge requirements. Per-case numerical gates and independent review still needed.

The family admission subset proves 19 distinct family/link descriptors, whereas
the 17 smoke IDs omit binomial probit and cloglog. Descriptor admission alone
cannot determine all cross-combinations. Covariance, modifiers, data, postfit,
formula, bridge and AGHQ expansions remain separately required.

The draft previously assigned generic p=5,n=60,K=1 metadata to many cases and a
latent R formula to the fixed multinomial case. Corrected the existing obligation
rows in place, retaining IDs. In particular NB2's existing rtol=1e-3 is now a
visible acceptance gap; a passing historical NB2 smoke does not establish the
project's 1e-6 parity bar. No assertion has been weakened or tightened here.

The R helper currently sets weights only when family is betabinomial despite
accepting N for other families. Bernoulli is unaffected. A future binomial
multi-trial test must first repair/qualify transport instead of passing N and
assuming it worked. This finding is source-grounded in parity_helpers.jl.

Next required work: implement the trial-aware/link-specific oracle adapters and
paired model fixtures, diagnose NB2 at the required tolerance, and finish finite
covariance/data/interface cases. These gates need the frozen R runtime; source
cataloguing does not discharge them. Recover the previously launched Totoro job
before any restart. Full manifest remains DRAFT; M1 PARTIAL; independent review
outstanding. No campaign, fit, push, merge, release or cleanup in this slice.

## Binomial transport repair checkpoint

The previously recorded no-X/shared-X trial omission is repaired in the local candidate: supplied N becomes R weights, omitted N retains weights=NULL, and binomial_link is explicit.127 R argument captures and80 Julia preparation assertions pass; no fit or RCall embedding ran. Probit/cloglog, multi-trial numerical fixtures and complete parity remain unpaid. See [transport evidence](binomial-transport-contract.md). The earlier catalogue findings remain the pre-repair audit record.

## Prepared binomial paired cases

[Six predeclared cases](binomial-paired-plan.md) now cover three links × Bernoulli/varying trials as executable definitions.26 preflight assertions pass; no datasets or fits ran. Explicit observed cloglog does not establish default Fisher equivalence. Full paired evidence remains unpaid.
