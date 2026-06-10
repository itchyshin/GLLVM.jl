# After Task: Non-Gaussian inference + cross-family correlation (A1-CI, A2a, A2b)

Date: 2026-06-10. Branch: `a1-nongaussian-ci` (worktree `…/GLLVM.jl-a1-ci`).
Local commits only — **not pushed** (per maintainer policy).

## Goal

Close the headline "non-Gaussian" gaps against `gllvmTMB`: confidence intervals
for the non-Gaussian families, and **cross-family trait correlation** (the
capability neither sibling package has natively), built on GLLVM.jl's native
shared-latent mechanism. Executed via the `ultracode` (Workflow) orchestration
with adversarial verification and live gllvmTMB parity.

## Implemented (3 slices, all additive — no `src/families/*.jl` fitter edits)

1. **A1-CI — Wald CIs for the 6 one-part non-Gaussian families** (`5febfc9`).
   New `src/confint_families.jl`: a shared `_nongaussian_wald_ci` core (mirrors
   `src/confint.jl`: ForwardDiff Hessian → `inv(symmetrize)` → SE → Wald;
   non-PD → NaN + `pd_hessian=false`; `:linear` β/Λ, `:log_sd` dispersion) plus
   `confint(::PoissonFit|BinomialFit|NBFit|BetaFit|GammaFit|OrdinalFit; …)`.
2. **A2a — link-residual table + latent-scale extractors** (`4aafbc6`).
   New `src/link_residual.jl` (per-family σ²_d: logit π²/3, probit 1, cloglog
   π²/6, Poisson `log(1+1/μ̂)`, NB2/Gamma `trigamma(·)`, Beta
   `trigamma(μ̂φ)+trigamma((1−μ̂)φ)`); `sigma_y_site`/`communality`/`correlation`
   generalised to the non-Gaussian fit types (`Σ_latent = ΛΛᵀ + diag(σ²_d)`).
   Gaussian methods left unchanged (`confint_derived.jl` is +127/−0).
3. **A2b — mixed-family model + cross-family correlation** (`43fbaa1`, headline).
   New `src/families/mixed.jl`: `fit_mixed_gllvm(Y; families, K, …)` +
   `MixedFamilyFit` — per-trait family over ONE shared latent block, reusing the
   per-observation `_glm_*` dispatch in `laplace.jl`; family-aware PPCA init;
   direct-ForwardDiff gradient (v1). Per-trait σ²_d assembler feeds the
   (family-agnostic) latent extractors → `correlation(::MixedFamilyFit)`.
4. **CI-gate fix** (`f15ae2f`): added `SpecialFunctions` to `test/Project.toml`
   (A2a's link-residual test imports `trigamma`; the canonical `Pkg.test()` env
   lacked it).

## Tests Added

`test/test_confint_families.jl` (147), `test/test_link_residual.jl` (200),
`test/test_mixed_family.jl` (86), wired into `test/runtests.jl`.

## Checks Run

`julia --project=. -e 'using Pkg; Pkg.test()'` → **exit 0**, full suite green
including `quality` 12/12 (**Aqua + JET**). Key testsets: confint non-Gaussian
147/147, link-residual+extractors 200/200, mixed-family 86/86.

## R-Parity Verdict

- **A2a link-residual formulas** match `gllvmTMB R/extract-sigma.R`
  (`link_residual_per_trait`) to the last ULP (worst R-vs-Julia rel diff 5.7e-16,
  20 cases). Gaussian-reduction reproduces `correlation(::GllvmFit)` to rtol 1e-12.
- **A2b cross-family** vs gllvmTMB `family=list(gaussian,poisson,binomial)`:
  loglik matches to 7 digits (−1333.3057 both), max abs correlation diff ~2e-7,
  **under the latent+unique (variant-B) Σ convention** — GLLVM.jl always puts σ²
  on a Normal trait's diagonal, matching gllvmTMB's `Σ = ΛΛᵀ + Ψ + link_resid`
  (NOT its bare latent-only default). Documented, not a numerical disagreement.

## FD / Aqua / JET Verdicts

- **FD**: A1 CIs FD-Hessian-verified per family (Poisson 4.6e-8, Ordinal 6.3e-9,
  Binomial 2.5e-7, NB 2.5e-7, Beta 5.8e-7); A2b mixed gradient FD rel err 1.17e-9.
- **Aqua + JET**: pass (`quality` testset 12/12 under `Pkg.test()`).

## Honest caveats (not defects)

- **Gamma CIs** correct at K=1; at K≥2 the loadings are rotation-unidentified →
  indefinite Hessian → the CI correctly returns NaN/`pd_hessian=false`.
  Follow-up: extend the lower-triangular anchor into Gamma's K≥2 path.
- **Per-entry Λ loading SEs are gauge-dependent** (reported in the
  lower-triangular anchor; no rotation-invariance claimed). Rotation-invariant
  inference is the job of the derived-quantity CIs (next).
- **Derived-quantity CIs** (Fisher-z/bootstrap/profile for correlation,
  communality, …) for the non-Gaussian + mixed estimands are **not yet
  implemented** — these slices ship POINT estimates. Design is in flight.

## Remaining / deferred

- A2 derived-quantity CIs; real `simulate()` (bootstrap + ADEMP depend on it).
- A1-Xβ fixed-effect covariates (deferred until PR #89's family-fitter rewrite
  merges — it edits the same files).
- Two-part (delta/hurdle) CIs + extractors; analytic mixed-gradient kernels
  (perf); `@formula` exposure.

## Provenance

Link-residual closed forms cross-checked against `gllvmTMB R/extract-sigma.R`
and Nakagawa & Schielzeth (2010); no GPL source vendored (formula + generated-
output parity only).
