# After-task: censored_poisson Identity→Engine (Julia-forward)

**Date:** 2026-08-15  
**Lane:** `cursor/censored-poisson-catchup-20260815`  
**WT:** `.worktrees/gllvmjl-censored-poisson-20260815`  
**Perspectives:** Ada (slice), Opus ceiling (Identity APPROVED), Composer (mechanical engine)

## Goal

Ship Wave2 censored_poisson engine under the ceiling-amended Identity, twin-fenced
(no light Δ), on owned files only.

## Done

- Absorbed Identity + ENGINE-GATES tip from `cursor/censored-poisson-engine-20260815`
  (`73d3a1bc`) rather than forking the decision doc.
- Added `src/families/censored_poisson.jl`: stable `logcdf(Gamma(C,1),μ)` survival,
  hand-coded η derivatives `G` / `G(C−μ−G)`, interval-ready `(lower,upper)` API,
  Bool `censored` convenience, Poisson packing, FD outer fit.
- Added `test/test_censored_poisson.jl` with local `Base.include` until conductor wires.
- Conductor ADMIT fragment at
  `docs/dev-log/handover/2026-08-15-censored-poisson-ADMIT.md` (shared ADMIT.md untouched).

## Opus BLOCKED verdict — remediation (2026-08-15, second pass)

Opus blocked the first engine pass on three counts. All three are now closed on
owned files (`src/families/censored_poisson.jl`, `test/test_censored_poisson.jl`):

1. **Missing link guard.** `censored_poisson_marginal_loglik_laplace` accepted any
   `Link` while `_glm_score` / `_glm_weight` hardcode `μ = exp(η)` and drop the
   `dμ/dη` chain-rule factor. It now throws `ArgumentError` unless
   `link isa LogLink`, matching the guard already present on
   `fit_censored_poisson_gllvm`. Covered by a new `IdentityLink` rejection test.

2. **Vacuous ENGINE-GATE 3 replaced.** The old gate compared central FD of the
   packed NLL at `h = 1e-6` against the same FD at `h = 1e-5` — a truncation
   self-consistency check that re-tests the very kernels under audit and passes
   even when the score or weight is wrong. It is replaced by an **independent
   Laplace oracle** built from `_glm_logpdf` alone: derivative-free
   golden-section coordinate ascent for the conditional mode, then a
   Richardson-extrapolated finite-difference Hessian for the curvature, giving
   `q(ẑ) − ½logdet(−∇²q)` per site. Cell is censored-dominated (75% of cells have
   `N ≠ 0`), `p = 4`, `n = 12`, `K = 2`. Gate: `worst ≤ 1e-6`.

   Mutation check (perturbing the kernels in place, no source edit) confirms the
   gate discriminates rather than merely passing:

   | Engine state | worst \|Δℓ_site\| | Gate ≤ 1e-6 |
   | --- | --- | --- |
   | unmodified | 2.46e-9 | PASS |
   | `_glm_score` censored arm ×1.001 | 2.19e-5 | FAIL |
   | `_glm_weight` censored arm ×1.0001 | 1.58e-5 | FAIL |

   The oracle also asserts the FD gradient of the log-joint vanishes at the
   derivative-free mode (≤ 1e-6, observed 5.9e-8) and that the `max(W, 0)` floor
   is inactive on this cell (min weight 1.04), so the comparison is not
   accidentally testing a clamped path.

3. **Second-derivative check tightened.** The old scalar gate used a single
   central second difference and an absolute tolerance of
   `max(5e-4, 5e-3·|g2|)`, which is loose enough to hide a real error on the
   small-`|g2|` deep-tail cells. Both η-derivatives are now checked against
   **Richardson-extrapolated** finite differences on a *relative* scale, with the
   step chosen per derivative order (roundoff in the second difference scales as
   `1/h²`, so it needs the larger step):

   | Derivative | Step | Tolerance | Worst observed over the 5 cells |
   | --- | --- | --- | --- |
   | `dℓ/dη = G` | `h = 1e-3` | rel ≤ 1e-8 | 4.9e-11 |
   | `d²ℓ/dη² = G(C−μ−G)` | `h = 5e-3` | rel ≤ 1e-6 | 4.0e-8 |

   No tolerance was widened anywhere; the loose absolute bound is gone.

## Evidence

Focused run (`julia --project=. -e 'using GLLVM, Test; include("test/test_censored_poisson.jl")'`):

```
Test Summary:                           | Pass  Total  Time
censored_poisson family (Julia-forward) |   46     46  6.9s
```

First pass was 43/43 under the vacuous gate.

## Opus re-review required

**ENGINE-GATE 4 must be re-CLEARed by Opus.** This pass changed the public entry
`censored_poisson_marginal_loglik_laplace` (added the link guard, so its accepted
argument domain narrowed) and rewrote the gate-3 test. Gate 4 is the
interval-ready `(lower, upper)` encoding / forward-compatibility gate, and its
verdict was issued against the previous entry-point signature — it does not carry
over automatically. Gates 1, 2, 3, 5 evidence is above and unchanged in scope.

## Twin fence (unchanged)

Constructor-only; no dens; FAM-16 blocked. No RCall Δ. Claim wording:
**Julia-forward / twin constructor-only**. Rose public claim **PENDING**.

## Not done (conductor)

`GLLVM.jl` include/export, `fit_gllvm` dispatch, `runtests.jl`, ledger, check-log.

## Rose

Engine slice OK for owned files. Public README/capability claim **blocked** until
Rose pre-publish after admit wiring.
