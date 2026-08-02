# After-task: NB2/Beta+X engine Arc 1 (per-trait φ + shared site-X)

**Date:** 2026-08-02  
**Lane:** `fix/nb2-beta-x-grouped-cov-20260802`  
**Base:** `origin/main` @ `c4c46293` (after #172/#173/#174)  
**Decision:** `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`

## Goal

Twin API B under X: stop routing public/bridge NB2/Beta+X through shared-φ
`fit_gllvm_cov`. Ship per-trait φ + shared site-X fitters, route bridge/formula,
and lock Julia-only identity tests. Arc 2 RCall cells deferred.

## Gate 0 (prerequisites)

| Item | Result |
|---|---|
| Arc 0 design PR | #174 merged |
| #172 one-group Fisher identity | merged (Documenter re-run green) |
| #173 MC capability-status | merged |

## What shipped

1. `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` +
   `NBGroupedCovFit` / `BetaGroupedCovFit` in `src/families/grouped_dispersion.jl`
2. Offset threaded through `_grouped_getLV` + `getLV(..., X)` for scores
3. Wald/profile/bootstrap CI adapters in `confint_family.jl`
4. Bridge `_bridge_fit_onepart_cov` routes `negbinomial`/`beta` to grouped_cov
5. `@formula` NB/Beta+X dispatch to grouped_cov; other families stay on
   `fit_gllvm_cov`
6. Identity tests `test/test_nb_beta_x_identity.jl`; bridge oracle updates
7. Docs cascade: response-families, gllvmtmb-parity, capability-status fence,
   coordination board

## Verification

| Check | Result |
|---|---|
| `test/test_nb_beta_x_identity.jl` | **14/14 pass** |
| `test/test_bridge_x.jl` | **201/201 pass** |
| `test/test_formula.jl` | **11/11 pass** |
| Tolerance widen | **none** |

## Rose verdict

**OK** to claim: public/bridge NB2/Beta+X use per-trait φ + shared site-X;
Julia identity vs shared `fit_gllvm_cov` under G=1+fisher holds in the #172
band.

**Not OK:** light RCall NB2+X/Beta+X parity (Arc 2); full family parity;
Gamma+X default flip; ADEMP/coverage.

## Next

Arc 2 `/goal`: opt-in RCall light cells for NB2+X and Beta+X at rtol `1e-6`
against gllvmTMB, only after this PR lands.
