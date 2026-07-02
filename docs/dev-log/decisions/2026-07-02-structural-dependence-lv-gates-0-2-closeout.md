# Structural-dependence LV truth matrix Gates 0-2 closeout

Date: 2026-07-02
Status: Gates 0-2 verified locally; no compute/API widening
Scope: source guards, structural random-slope evidence, R<->Julia bridge truth

## Decision

The structural-dependence LV truth matrix is now a verified Gate 0-2 artifact.
This closes the half-day/evening truth-lock slice only. It does not expose
source-specific `lv`, reopen PR #127, widen the package API, change likelihood
code, or launch Totoro/DRAC compute.

## Gate 0 - Truth matrix

| Route | Current truth | Evidence | Public wording |
| --- | --- | --- | --- |
| Ordinary `latent(..., lv = ~ env)` | Covered ordinary score-mean grammar. | Existing `gllvmTMB` LV arc and PR #581 closeout. | Ordinary predictor-informed LV only. |
| Source-specific `phylo_latent(..., lv = ~ env)` | Guarded/fail-loud. | `test-canonical-keywords.R` source-specific guard. | Not supported; parked/fail-loud. |
| Source-specific `spatial_latent(..., lv = ~ env)` | Guarded/fail-loud. | `test-canonical-keywords.R` source-specific guard. | Not supported; parked/fail-loud. |
| Source-specific `animal_latent(..., lv = ~ env)` | Guarded/fail-loud. | `test-canonical-keywords.R` source-specific guard. | Not supported; parked/fail-loud. |
| Source-specific `kernel_latent(..., lv = ~ env)` | Guarded/fail-loud. | `test-canonical-keywords.R` source-specific guard. | Not supported; parked/fail-loud. |
| Ordinary `latent(1 + env \| unit, d = K)` | Partial structural random-regression route. | `test-ordinary-latent-random-regression.R` plus RE-12 ledger. | Structural random slope, not `lv`. |
| `phylo_latent(1 + env \| sp, d = 1)` | Covered for the validated R allowlist, separate from `lv`. | PHY-17 register row; `test-matrix-slope-phylo-latent.R`, `test-phylo-latent-slope-gaussian.R`. | Structural random slope only. |
| `spatial_latent(1 + env \| site, d = K)` | Covered for the validated R allowlist, separate from `lv`. | SPA-09 register row; `test-matrix-slope-spatial-latent.R`, `test-spatial-latent-slope-gaussian.R`. | Structural random slope only. |
| `animal_latent(1 + env \| id, d = K)` | Gaussian structural random-slope evidence exists; no broad non-Gaussian claim from this slice. | `test-animal-latent-slope-gaussian.R`. | Gaussian structural random slope unless a later audit widens it. |
| `kernel_latent(1 + env \| id, d = K)` | No current support claim established by this audit. | No matching focused evidence found in the Gate 0 audit. | Future audit/derivation required. |
| R bridge mixed-family vector | Complete balanced point/postfit only; no fixed `X`, no `X_lv`, no masks, no CIs. | `gllvm_julia_capabilities()` and `test-julia-bridge.R`. | Point/postfit only. |
| Julia bridge mixed-family vector | Point/postfit route exists; CI requests return explicit unavailable empty payload with a "not routed" note. | `GLLVM.bridge_capabilities()` and `test/test_bridge_mixed.jl`. | Unavailable CI status, not CI support. |
| Non-Gaussian source-specific `X_lv` / Model A | New derivation and ADEMP gate required. | Existing Model A evidence-freeze notes. | No inheritance from Gaussian Gate 3 or ordinary bridge rows. |

Important separation: source-specific `lv = ~ env` is predictor-informed score
mean grammar. `source_latent(1 + env | group, d = K)` is structural
random-slope grammar. They are not interchangeable evidence.

## Gate 1 - Guards / unavailable statuses

Verified locally:

```sh
Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-canonical-keywords.R")'
# 67 pass / 3 INLA skips

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
# 380 pass / 14 GLLVM.jl-path skips

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-ordinary-latent-random-regression.R")'
# 23 pass / 7 CRAN skips

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-stage37-mixed-family.R")'
# 6 pass
```

Julia bridge focused checks:

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# 63 pass

julia --project=. --startup-file=no test/test_bridge_mixed.jl
# 18 pass

julia --project=. --startup-file=no test/test_bridge_x.jl
# 195 pass

julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
# 83 pass

julia --project=. --startup-file=no test/test_bridge_ci.jl
# 64 pass
```

Initial R `testthat::test_file()` without `pkgload::load_all()` was rejected as
evidence because it exercised the installed/namespace state rather than the
local checkout. The commands above are the accepted local evidence.

## Gate 2 - R<->Julia bridge reconciliation

The public story reconciles:

- R admits the mixed-family vector as complete balanced point/postfit only.
- Julia exposes the same mixed-family vector as no `X`, no `X_lv`, no masks,
  and no CI routing.
- R fails mixed-family CI before Julia setup with `GJL-GATE-MIXED-CI`.
- Julia returns an empty CI payload with `ci_note` containing "not routed" for
  direct mixed-family CI requests.
- Both behaviors mean "CI unavailable"; neither is mixed-family CI support.

Named bridge drift that remains acceptable for this truth-lock:

1. R's ledger intentionally keeps a stable public schema and records
   predictor-informed LV boundaries in notes; Julia has an explicit
   `predictor_informed_lv` boolean column.
2. Julia lists binomial logit/probit/cloglog bridge rows separately; R's
   capability ledger reports the R admission surface more compactly.
3. R fails mixed-family CIs with a named gate; Julia direct bridge calls return
   an unavailable empty payload. A future parity slice may align behavior, but
   the current wording is already safe.

## Mission Control

Mission Control was refreshed because the operating state changed from
"ultra-plan written" to "Gates 0-2 locally verified." Metrics are unchanged:
this is not a new support row and not a compute launch.

## Rose verdict

PASS WITH NOTES. Gates 0-2 are verified for the truth-lock objective. The
remaining notes are deliberate boundaries: no source-specific `lv` exposure, no
non-Gaussian/source-specific LV inheritance, no mixed-family CI support, and no
Totoro/DRAC compute.
