# GLLVM.jl ↔ DRM ecosystem — cross-pollination hand-off (2026-06-11)

Audience: the DRM.jl / drmTMB team. Source: a read-only audit of DRM.jl + drmTMB
against GLLVM.jl + gllvmTMB. The flow so far has been mostly DRM → GLLVM (Workflow
framework, bridge pattern, parity-harness discipline, Takahashi selected-inverse).
GLLVM.jl now has several capabilities DRM has scoped but not built — here is the
reciprocal flow, ranked.

## 1. What DRM can borrow from GLLVM.jl (gifts)

1. **NA-aware FIML missing-data engine — highest value.** DRM has a design (issue
   #49) but no code; GLLVM.jl has imputation-free FIML across *all* non-Gaussian
   families on the dense-Laplace path (a missing cell drops from its site's product:
   0 score, 0 working weight, skipped in the ℓ sum; site mode from observed cells;
   Rubin 1976 ignorable likelihood), plus NA threaded through confint / predict /
   getLV / bootstrap (the bootstrap re-imposes the original missingness mask per
   replicate). Byte-equivalent on dense data. → Port the mask-detection + the
   family-dispatched observed-subvector loglik + the masked-bootstrap pattern. Start
   with the Gaussian bivariate slice; q=4 phylo after.

2. **Mixed-family cross-family latent engine** (`src/families/mixed.jl`). drmTMB
   explicitly lacks mixed-response bivariate; GLLVM.jl drives traits of *different*
   families through one shared latent block and reports a true cross-family
   correlation on the latent/link scale (Laplace exact for the Gaussian piece). →
   Maps onto DRM's q=4 location–scale latent; design phase must resolve identifiability
   (one Λ vs four axes) before coding.

3. **Smaller gifts**: GenPoisson / COM-Poisson families; the two-part/delta Laplace
   substrate; transformed-scale Wald CIs for bounded derived quantities (Fisher-z /
   logit, one-Hessian cost).

## 2. Shared engine — co-develop once, use in both (by leverage)

1. **VA / EVA — the headline.** BOTH ecosystems want it: DRM has a `variational.jl`
   scaffold + an ELBO design doc (#136); GLLVM.jl chose to add VA/EVA (plan SP2; the
   field's fast+universal estimator, Korhonen et al. 2023, arXiv:2107.02627). →
   Build ONE shared VA/ELBO core (closed-form ELBO for Poisson/Gamma/Delta;
   Gauss–Hermite for Binomial/NB/Beta; variance→0 + lower-bound anchors), DRM-first
   (smaller latent spaces) then ported to GLLVM.jl.

2. **Unified sparse-phylo Laplace module.** Both use augmented-state precision
   (Hadfield–Nakagawa) + CHOLMOD + Takahashi selected-inverse with different
   per-observation likelihood pieces. → Extract a shared `sparse_phylo_laplace.jl`
   (per-obs loglik/score/weight + tree precision in, marginal + O(p) gradient +
   BLUPs out); one test suite catches bugs in both.

3. **Shared ADEMP / FD-gradient / parity harness** — a lean shared utility (or
   scripts) so both packages stop reinventing the same quality gates.

## 3. What GLLVM.jl is borrowing back from DRM (already in the plan)

- **MoreThuente** line search (DRM measured ~2.2× vs BackTracking) — adopted in the
  RE fitters.
- **Robust fast-path→LM-fallback mode-finder** (DRM `sparse_aug_plsm.jl`) — for EVA /
  structured-RE robustness at variance boundaries.
- **Static TOML-fixture parity harness** (GPL-safe, no live RCall).
- **Boundary-safe inference** (Inf not NaN for unidentified directions; χ̄² / Self–Liang).
- **drmTMB grammar**: `miss_control` / `impute_model` (→ missing predictors) and the
  `spatial()/animal()/phylo()/relmat()` structured-marker syntax (→ the RE/structured
  front-end).

## 4. Concrete first deliverables (proposed)

| # | Deliverable | Owner | Size |
|---|---|---|---|
| 1 | NA-FIML design memo for DRM (bivariate slice + q=4 phylo) | GLLVM→DRM | ~1 KB |
| 2 | Mixed-family engine memo + API sketch | GLLVM→DRM | ~1.5 KB |
| 3 | Shared-sparse-phylo-Laplace audit (line-by-line map of the two engines) | both | ~0.5 KB |
| 4 | Shared VA/ELBO core scaffold (DRM-first) | both | ~800 LOC |

> Note (process): filing these as issues on the DRM repo is the maintainer's call
> (outward-facing). This memo is the draft to share.
