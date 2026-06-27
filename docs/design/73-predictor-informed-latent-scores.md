# Design 73 — Predictor-informed latent scores: `latent(..., lv = ~ x)`

**Status (2026-06-27):** engine + CI trio shipped to `main` (#116–#126); the phylo Model A
extension is on `claude/phylo-xlv-modelA-20260627` (engine + trio + coverage smoke); the R
`lv = ~ x` formula grammar and the full DRAC coverage campaign are pending. This doc is the
spec the Julia comments (`likelihood.jl:405`) reference.

## 1. The model

Ordinary GLLVM latent scores are zero-mean innovations. `latent(..., lv = ~ x)` makes the
score **predictor-informed** — its mean is a regression on unit-level covariates `x`:

```
z_total[s, :] = X_lv[s, :] · α_lv + z_innovation[s, :]      z_innovation ~ N(0, I_K)
η[:, s]       = X[:, s, :] · β + Λ · z_total[s, :]
```

`X_lv` is `n_sites × q_lv`; `α_lv` is `q_lv × K` (the score-coefficient matrix). Marginally
this is an ordinary GLLVM with the same covariance and a constrained fixed mean term
`Λ · α_lv' · X_lv[s, :]`. This is **concurrent / constrained ordination** (van der Veen et al.)
— equivalently a **reduced-rank regression** of the responses on `x` through the latent space.

## 2. The estimand: `B_lv = Λ · α_lv'`

`α_lv` and `Λ` are individually rotation- and sign-dependent (the K×K orthogonal indeterminacy
`Λ → ΛQ, α_lv → α_lv Q`). **Their product `B_lv = Λ · α_lv'` (p × q_lv) is invariant** under
that transformation for any `Q` and any `K`, and is THE inferential target — the trait-scale
effect of each `x` predictor. `α_lv` alone is **diagnostic only** (`extract_lv_effects(type =
"axis_effect")`). The sole residual symmetry is a joint sign flip, pinned by the global anchor.

`B_lv` is admitted for **`K ≥ 1`** (rotation invariance), complete responses, a single ordinary
latent block.

## 3. Confidence intervals — the trio (Wald / profile / bootstrap)

All three target `vec(B_lv)` (`confint_lv_effects`):
- **Wald (delta method):** `Cov(B_lv) = J Σ Jᵀ`, `Σ = inv(H)`, `J = ∂vec(B_lv)/∂θ`. Gaussian
  uses an exact `ForwardDiff` Hessian; GLM families use the observed-information `_fd_hessian`
  (the Laplace marginal is not AD-friendly through the inner solve).
- **Profile (LR inversion):** for each entry, a constrained refit pins `B_lv[idx] = c` with an
  escalating penalty and **re-maximises all nuisances** (genuine PLR — NOT the nuisance-fixed
  "estimated likelihood" shortcut, which under-covers); invert `D(c) = 2[ℓc − ℓ̂]` vs `qchisq(level,1)`.
  Asymmetry-respecting; `se` is `NaN`. Gaussian uses AD LBFGS; GLM uses NelderMead (expensive →
  Wald/bootstrap are the practical GLM defaults, profile shines for Gaussian + small problems).
- **Bootstrap (percentile):** percentiles of derived `B_lv` over `simulate(fit; X_lv)` + refit,
  sign-aligned.

The χ²₁ profile cutoff is the interior asymptotic reference; the **boundary chi-bar-square**
correction (variance→0, |ρ|→1, loading→0) is a separate, deferred refinement.

## 4. Families

Gaussian + Poisson + Binomial (logit/probit/cloglog) + NB2 + Gamma + Beta. Exotic families
(ordinal/Tweedie/ZI/hurdle/Student-t) for `X_lv` are post-v1.0.

## 5. Structured sources × `X_lv` — phylogenetic (Model A)

The headline extension: compose `X_lv` with structured latent dependence. **Two non-equivalent
models** (see `intake/2026-06-27-phylo-xlv-design.md`):

- **MODEL A (v1, chosen):** the predictor-informed score MEAN (site axis) composed with the
  existing **trait-axis phylogenetic trait-covariance** (`Σ_phy`, species axis). The axes are
  **orthogonal and additive** — no new identifiability hazard. Reuses the J3 closed-form phylo
  marginal verbatim (the rotation trick survives the `X_lv` residual mean shift — pinned to
  7e-15 against a dense `vec(y) ~ N(μ, I_n⊗A + J_n⊗B)` Gaussian). The Gaussian CI trio extends
  mechanically (same packed vector + Hessian; the `B_lv` extractor is unchanged). Gaussian-only
  v1; non-Gaussian phylo `X_lv` is a separate later gate (new Laplace-core derivation).
- **MODEL B (post-v1.0):** the latent SCORE itself is phylo-correlated across tips
  (`z = X_lv·α + u, u ~ N(0, Σ_phy)`) — **phylogenetic factor analysis** at TMB speed. Native-TMB
  design-65 `kernel_latent` extension; carries a real mean-vs-covariance confound when `x` is
  itself heritable. Needs one-row-per-species comparative data.

Animal / spatial / kernel × `X_lv` follow the Model A pattern after phylo.

## 6. R grammar (TO IMPLEMENT — Phase 4, HIGH-RISK)

`latent(..., lv = ~ x)` (and `phylo_latent(..., lv = ~ x)`) does **not** exist on the R side
yet. Required:
- Admit `lv` as a one-sided predictor formula on `latent()` / `phylo_latent()`; enforce inside
  `rewrite_canonical_aliases()` (`R/brms-sugar.R`), NOT the never-evaluated constructor. Validate
  one-sided, build `model.matrix` against `data`, attach as a STRUCTURED marker
  (`extra$.lv_formula` + materialized `extra$.X_lv`).
- **FAIL-LOUD gate (mandatory).** `parse_covstruct_call()` captures unknown named args into
  `cs$extra` with no allow-list, and `fit-multi.R` silently drops unknown keys (the Sokal
  silent-collapse anti-pattern). An unrecognized/malformed `lv =` MUST error loudly (mirror
  `.assert_no_augmented_lhs`), never be ignored.
- **Strict separation** from the augmented-LHS reaction-norm grammar (`1 + x | sp`,
  `0 + trait + (0 + trait):x | sp` — per-trait random SLOPES, loading 2T×d). `lv = ~ x` is a
  predictor MEAN (loading stays T×d). Conflating them is the highest-risk grammar error.
- Both wide (`traits(...)`) and long (`0 + trait`) shapes; present together in examples.
- The bridge currently cannot reach phylo `X_lv` (3 new layers needed); deliver direct/native first.

## 7. Validation (gate on everything)

- **Recovery:** `B_lv` unbiased, RMSE ~1/√n. **Coverage:** ~nominal for the trio. Both done for
  the bridge X_lv families (K=1/K=2) and as a smoke for phylo Model A (coverage 0.975 + two nulls).
- **Phylo Model A gate (remaining):** full DRAC sweep λ×n_species×K × ≥500 reps + the two nulls
  (Model A is orthogonal-axes → no phylo-collinear arm; that's a Model B concern). Seed:
  `bench/phylo_xlv_coverage.jl`.

## 8. Honest scope

Only `B_lv` is rotation-stable — keep it the inferential target, `α_lv` diagnostic. Under phylo,
advertise `B_lv` at interpretation Level 2; demote the per-axis α / Λ-vs-Ψ split to Level 3
(rank-fragile). Do not imply non-Gaussian or bridge parity from the Gaussian Model A slice. Keep
capability promotion parked until the register/NEWS/article slice.
