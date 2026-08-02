# After-task — default-route NB2/Beta per-trait φ

**Date:** 2026-08-01  
**Lane:** `default-route-phi-20260801`  
**Branch:** `parity/default-route-phi-20260801`  
**Base:** `catchup/loglik-oracle-20260801` @ `bbf5d7d8`  
**Twin:** gllvmTMB `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`  
**Tip:** `5f1dfe77` (engine COMPLETE @ `ccd55f1f`; tip-align docs)
**Rose verdict:** **PASS WITH NOTES** — default-route per-trait φ light logLik for NB2+Beta only; not “full family parity.”

## Goal

Public `fit_gllvm(NegativeBinomial/Beta)` defaults to per-trait φ
(`disp_group=:species` → grouped fits), matching gllvmTMB; keep named
`fit_nb_gllvm` / `fit_beta_gllvm` as shared-φ engines; retarget light parity
cells to the public default path.

## What landed

| Slice | Change |
|---|---|
| S1 | `src/families/fit_gllvm.jl` — API B coerce `nothing`→`:species` for NB/Beta only; docstring |
| S2 | `test/parity/test_{negbin,beta}_parity.jl` + README — plain `fit_gllvm` default |
| S3 | Core type expects → `NBGroupedFit`/`BetaGroupedFit`; postfit NB/Beta on named shared fitters; tutorial + response-families honesty |
| S4 hygiene | Postfit Ordinal block retargeted to named `fit_ordinal_gllvm` (shared-cutpoint surface; public `fit_gllvm(Ordinal)` stays per-trait) — pre-existing red cell exposed while verifying the suite |

## Evidence (read Δ from log, not exit code)

Log: `/tmp/default-route-phi-parity.log`

```text
Gaussian  Δ=9.78275238594506e-9     Pass 30/30
Binomial  Δ=1.8175683180743363e-10  Pass 6/6
Poisson   Δ=6.748564373992849e-9    Pass 6/6
NB2       Δ=-0.00024989924941110075 Pass 8/8   (fit_gllvm default)
Beta      Δ=5.968587402094272e-9    Pass 8/8   (fit_gllvm default)
Ordinal   Δ=5.475669695442775e-9    Pass 5/5
Total                               63/63
```

Prior catch-up bands unchanged (NB2 ~1e-4, Beta ~1e-8); no tolerance widen.

Cascade core (`test_fit_gllvm` / `test_nb_fit` / `test_beta_fit` / `test_unified_api`):
**51/51** pass. Full `test_postfit.jl` green after named-fitter retargets
(NB/Beta/Ordinal shared surfaces).

Core `test/runtests.jl` (`/tmp/default-route-phi-runtests.log`):

```text
5063 passed, 1 failed, 0 errored, 3 broken
```

The single failure is `test_grouped_dispersion.jl:61`
(`fit_nb_gllvm_grouped` one-group ≈ `fit_nb_gllvm`, ΔlogLik≈0.94 at seed 503).
**Not introduced by this lane** — `grouped_dispersion.jl` / `negbin.jl` byte-identical
to base tip `bbf5d7d8`. No tolerance widen; left as a pre-existing engine/optima gap
outside the default-route flip.

## Not covered / fenced

- #129 / #128, ADEMP, coverage, Totoro/DRAC  
- “full family parity”  
- Gamma default flip; X_lv shared path; ordinal-logit; Phylo Model A  
- Observed-Hessian rework (grouped path stayed green)  
- No push (maintainer ask required)

## Rose claim fence

**OK:** “Public `fit_gllvm(NB/Beta)` defaults to per-trait φ; light gllvmTMB
logLik oracles green on that default path (NB2 Δ≈−2.5e-4, Beta Δ≈6e-9), with
named shared-φ fitters retained.”

**Not OK:** “full family parity,” ADEMP/coverage done, or Gamma/X_lv included.

## Next

Lane DONE locally. Optional: maintainer push/PR; then Phylo Model A redesign
menu remains deferred on the coordination board.
