# RECON — post-bb-x-capacity (S0 / cheap parallel)

Date: 2026-08-08. Base: `origin/main` @ `d7f852df` (Merge #195).

## Species-XB helper arm (S1)

- `test/parity/parity_helpers.jl` `fit_gllvmtmb_parity_loglik_species_x`
  admits **`:poisson` only** (guard ~L236; R `switch` ~L254–256).
- Twin formula already correct: `(0 + trait):x` (~L259–266).
- Shared-X binomial path exists: `fit_gllvmtmb_parity_loglik_x` +
  `stats::binomial()`; N=1 Bernoulli (no `weights`). Mirror that for species-XB.
- Julia engine already: `fit_gllvm_speciescov(...; family=Binomial())`
  (`src/families/species_covariates.jl`). No `src/` change for S1.
- Gaussian species-XB: `fit_gllvm_speciescov` is Laplace non-Gaussian only.
  Optional under-run **skip** unless a Gaussian species-B engine appears —
  do not invent one here.

## BB CI mirror map (S2)

| Piece | Path:line | Note |
|---|---|---|
| Guard (fail-loud) | `src/bridge.jl:498–503` `_bridge_ci_guard_betabinomial` | lift only after Julia `confint` smoke |
| Call sites | `src/bridge.jl:1104`, `:1208` | grouped + grouped_cov bridge arms |
| Mirror `_family_ci` | `src/confint_family.jl:538` `NB1GroupedCovFit`; `:597` `BetaGroupedCovFit` | pack `β, γ_free, Λ, log φ`; require `X` |
| BB no-X CI (exists) | `src/confint_family.jl:854` `BetaBinomialFit` | thread `N`; grouped(_cov) missing |
| Union omits BB | `src/confint_family.jl:40` `_GroupedDispersionCovFit` | add `BetaBinomialGroupedCovFit` |
| Types | `src/families/beta_binomial.jl:384+` `BetaBinomialGroupedFit`; `:544+` `…GroupedCovFit` | `getLV` needs `N` |

S2 checklist: copy NB1/Beta grouped_cov `_family_ci`; thread trials `N`;
keep FD Hessian (BB Laplace has no OH); add to unions; lift guard for
supported methods only.

## ZIP Identity cites (S3 — docs-only)

| Cite | Where | Use |
|---|---|---|
| Twin ZIP **cut** | gllvmTMB `docs/dev-log/known-limitations.md:146–148` | “Cut from the 0.2.0 family list; planned for a later phase.” |
| Twin `family_to_id` | gllvmTMB `R/fit-multi.R` (no `zip`) | no live twin Δ |
| Julia ZIP (no-X) | `src/` `fit_zip_gllvm` / `ZIPFit`; `Λz=0` | not in `_BRIDGE_X_FAMILIES` |
| Two-part estimand | `docs/superpowers/specs/2026-05-31-two-part-families-design.md:297+` §2.2 | lock `π0` (structural-zero logit) + count `η`; shared site-X on both parts is the Identity question |
| CRAN gllvm ZIP | secondary authority only | do not invent twin file:line |

S3 must be **ACCEPTED-with-fence** (Julia-forward / twin-asymmetric). Zero
`src/` ZIP engine diff.
