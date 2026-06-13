# Non-Gaussian missing predictor — augmented-Laplace design (mi() Phase 5a)

**Status:** design + verification plan (2026-06-13), mapped by workflow
`wf_6e20ce7c-9d1`. **NOT implemented** — this is the hardest mi() phase (subtle
Laplace normalisation + an identifiability caveat); deferred for maintainer
greenlight per the design doc's "factors last". The Gaussian + phylo missing
predictors (Phase 2a/2-Z/3) ARE shipped on `coevolution-kernel`.

> **Correction to the workflow spec:** the synthesis agent confused two checkouts
> and claimed "no covariate/offset infrastructure here." Verified false for this
> worktree (`GLLVM.jl-coevolution`, consolidation trunk): `_laplace_mode` and
> `marginal_loglik_laplace` already take an `offset` kwarg (η = β + offset + Λz),
> `covariates.jl` + `laplace_grad.jl` (the implicit-gradient trick) exist, and the
> Gaussian missing-predictor work is committed here. The infrastructure to reuse
> is real.

## Model (smallest faithful slice)

Poisson-log response with ONE missing site-level continuous predictor and a
single broadcast slope:

    y[t,s] ~ Poisson(exp(η[t,s])),  η[t,s] = β_t + b_x x_s + (Λ z_s)_t
    z_s ~ N(0, I_K),   x_s ~ N(μ_x, σ_x²)   (x_s may be missing)

`b_x` is one scalar shared across all p species (gllvmTMB's mi() semantic).

## Marginal (per site)

**Observed `x_s` — reuse the existing offset path (zero new math).** Fold
`b_x x_s` into the offset (the offset-absorption identity makes this a per-species
intercept shift), Newton over `z` only:

    log p(y_s) = laplace_loglik_site(Poisson(), y_s, N_s, Λ, β; offset = b_x x_s · 1_p)
                 + logN(x_s; μ_x, σ_x²)

**Missing `x_s` — augment the latent to (z, x_s).** Minimise the per-site joint
negative log-objective

    g(z,x) = −Σ_t logpois(y_t | η_t) + ½ z'z + ½ (x−μ_x)²/σ_x²,  η_t = β_t + b_x x + (Λz)_t

Newton with the **Fisher (expected) bordered Hessian** (W_t = μ_t, the Poisson
weight):

    H = [ Λ'WΛ + I       b_x Λ'W 1     ]      (K+1 × K+1, SPD: the x-block adds the
        [ b_x 1'WΛ    b_x² Σ_t W_t + 1/σ_x² ]   prior precision 1/σ_x², so PD even as W→0)

i.e. a **rank-1 border** of the existing `A = Λ'WΛ + I`. The marginal is the
Laplace value at the joint mode `(ẑ, x̂)`:

    log p(y_s) ≈ ℓ(modes) − ½ ẑ'ẑ − ½ (x̂−μ_x)²/σ_x² − ½ log σ_x² − ½ logdet(H)

(the K-dim `2π` constants cancel against the `N(z;0,I)` normaliser exactly as in
the existing K-dim code — **verify the x-dimension constant the same way against
the complete-data oracle** before trusting missing-site values).

**AD:** reuse the implicit-function "one differentiable Newton step at the mode"
trick (`laplace_grad.jl`) on the (K+1) system, so ForwardDiff through the marginal
gives the exact gradient incl. d(mode)/dθ — no hand-coded adjoint in this slice.

## Verification oracles (the safety net — these make it trustworthy)

1. **Complete-data equivalence (pins the normalisation constant):** with ALL x
   observed, `marginal_loglik_laplace_xs` must equal
   `marginal_loglik_laplace(Poisson(), Y, N, Λ, β; offset = b_x·x broadcast)
   + Σ_s logN(x_s; μ_x, σ_x²)` to ~1e-9 (offset-absorption identity).
2. **Gauss–Hermite quadrature (pins the missing-site value):** for one missing
   site, compare against a 2-D GH quadrature (≥64 nodes/dim) of
   `∫∫ p(y_s|z,x) N(z;0,I) N(x;μ_x,σ_x²) dz dx`. Expect Laplace-approx tolerance
   (rel err ~1e-2 at these magnitudes) — confirms the mode + logdet(H), not just
   self-consistency.
3. **AD vs central FD** ≤ 1e-6 (the repo's gate; b_x/μ_x/σ_x enter the marginal).
4. **Recovery under MCAR** (≥70% observed; see caveat): recover (b_x, μ_x, σ_x).

## Caveats

- **Identifiability:** a missing x with broadcast slope b_x and a 1-column Λ both
  inject a site-level common effect; (b_x, σ_x) separate from Λ only if x is
  observed at enough sites (≥~70%). Mirrors the Gaussian missing-predictor
  condition. Document + test under MCAR with high observed fraction.
- **Continuous x only.** Categorical/count missing predictors (the "factors last"
  hard case) are explicitly out — gllvmTMB itself rejects count missing-x.
- **Smallest slice = the marginal primitive + oracle tests**, not an exported
  fitter. The user-facing `fit_*` (packing θ, warm start, SEs) and the hand-coded
  (K+1) implicit adjoint (perf) are follow-on slices.

## Plan

`_laplace_mode_xs!` + `laplace_loglik_site_xs` + `marginal_loglik_laplace_xs` in
`src/families/laplace.jl`; `test/test_missing_predictor_poisson.jl` with the 4
oracles above. Observed sites call the existing primitive with a shifted offset;
only missing sites use the augmented (K+1) Newton. Then Binomial via the same
family dispatch.
