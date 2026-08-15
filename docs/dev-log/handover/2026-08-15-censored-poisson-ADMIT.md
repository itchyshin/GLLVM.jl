# ADMIT fragment — censored_poisson (conductor paste)

**Lane:** `cursor/censored-poisson-catchup-20260815`  
**Date:** 2026-08-15  
**Do not** merge this file into shared `ADMIT.md` from this lane — conductor owns the shared admit surface.

## Identity

- **Status:** ACCEPTED (Opus ceiling APPROVED; amendment in
  `docs/dev-log/decisions/2026-08-15-censored-poisson-identity.md`)
- **Twin fence:** constructor-only; no cpp dens; FAM-16 blocked; fail-loud
  enum test. Light RCall Δ **FORBIDDEN**. Public wording:
  **Julia-forward / twin constructor-only**. Rose public claim **PENDING**.

## Engine (this PR)

| Path | Action |
| --- | --- |
| `src/families/censored_poisson.jl` | **ADD** (owned) |
| `test/test_censored_poisson.jl` | **ADD** (owned; self-includes until wired) |
| `docs/dev-log/decisions/2026-08-15-censored-poisson-identity.md` | already on tip |
| `docs/dev-log/ENGINE-GATES.md` | already on tip |

## Conductor wiring checklist (NOT done here)

1. `include("families/censored_poisson.jl")` in `src/GLLVM.jl` (after poisson)
2. Export `CensoredPoisson`, `fit_censored_poisson_gllvm`, `CensoredPoissonFit`
   (and optionally `censored_bounds_to_YN`) if public
3. Optional: `fit_gllvm` dispatch on `CensoredPoisson`
4. `include("test_censored_poisson.jl")` in `test/runtests.jl`
5. Ledger row → Julia-forward / twin constructor-only (not twin-parity)
6. Shared `docs/dev-log/check-log.md` entry
7. Rose pre-publish before README / capability claim

## Verification (local focused)

```
Test Summary: censored_poisson family (Julia-forward) | Pass  Total
                                                     |   43     43
```

ENGINE-GATES 1–4 exercised: stable `μ≪C` via `logcdf(Gamma(C,1),μ)`;
hand-coded η score/weight FD-checked; censored-dominated packed NLL finite;
`(lower,upper)` interval-ready encoding with v1 right-censored only.

## Packing lock

`θ = vcat(β, pack_lambda(Λ))` — no dispersion; `C` is data not a parameter.
