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
Test Summary:                           | Pass  Total
censored_poisson family (Julia-forward) |   46     46
```

ENGINE-GATES 1–4 exercised: stable `μ≪C` via `logcdf(Gamma(C,1),μ)`; hand-coded
η score/weight checked against Richardson-extrapolated FD on a relative scale
(first derivative ≤ 1e-8, second ≤ 1e-6); censored-dominated cell checked against
an **independent Laplace oracle** rebuilt from `_glm_logpdf` alone
(derivative-free mode + Richardson FD Hessian, worst site Δ = 2.46e-9 ≤ 1e-6);
`(lower,upper)` interval-ready encoding with v1 right-censored only.

## Opus re-review required — ENGINE-GATE 4

The second pass (Opus BLOCKED remediation) narrowed the accepted argument domain
of `censored_poisson_marginal_loglik_laplace` by adding a `LogLink`-only guard,
and replaced the gate-3 test. **Opus must re-CLEAR ENGINE-GATE 4** (interval-ready
`(lower, upper)` encoding / forward-compatibility) against the new entry-point
signature — the earlier verdict was issued pre-guard and does not carry over.
Detail and per-gate numbers: `docs/dev-log/after-task/2026-08-15-censored-poisson-engine.md`.

`docs/dev-log/ENGINE-GATES.md` is **not** edited from this lane — it is on the
shared `73d3a1bc` tip also carried by PR #209 (identity lane). The gate-3 wording
there still describes the superseded plain-FD form; conductor or the identity lane
should refresh it after Opus re-clears.

## Packing lock

`θ = vcat(β, pack_lambda(Λ))` — no dispersion; `C` is data not a parameter.
