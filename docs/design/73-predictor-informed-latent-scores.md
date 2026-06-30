# Design 73 — Predictor-informed latent scores: `latent(..., lv = ~ x)`

**Status (2026-06-30):** ordinary `X_lv` engine + CI trio shipped to `main`
(#116-#126). The phylo Model A extension has local engine and CI plumbing on the
draft PR branch, but its interval calibration is **blocked** by the p=80, K=2,
lambda=0.5 `B_lv` weak cell. The R `lv = ~ x` source-specific formula grammar
and any public phylo Model A capability promotion remain pending. This doc is
the spec the Julia comments (`likelihood.jl:405`) reference.

## 1. The model

Ordinary GLLVM latent scores are zero-mean innovations. `latent(..., lv = ~ x)` makes the
score **predictor-informed** — its mean is a regression on unit-level covariates `x`
(GLLVM.jl often calls these rows "sites"; in `gllvmTMB` language they are units):

```
z_total[s, :] = X_lv[s, :] · α_lv + z_innovation[s, :]      z_innovation ~ N(0, I_K)
η[:, s]       = X[:, s, :] · β + Λ · z_total[s, :]
```

`X_lv` is `n_units × q_lv`; `α_lv` is `q_lv × K` (the score-coefficient matrix). Marginally
this is an ordinary GLLVM with the same covariance and a constrained fixed mean term
`Λ · α_lv' · X_lv[s, :]`. This is **concurrent / constrained ordination** (van der Veen et al.)
— equivalently a **reduced-rank regression** of the responses on `x` through the latent space.

## 2. Axis effects and induced trait effects

`α_lv` and `Λ` are individually rotation- and sign-dependent (the K×K orthogonal indeterminacy
`Λ → ΛQ, α_lv → α_lv Q`). That gives two useful but different summaries:

- **Axis effect / CLV view:** `α_lv` (`extract_lv_effects(type = "axis_effect")`) is the
  familiar GLLVM-style answer: how a predictor moves units along LV1, LV2, and so on. This is
  usually the first user-facing constrained-ordination view, but for `K > 1` it is tied to the
  chosen loading orientation, rotation, sign convention, or explicit loading constraint.
- **Induced trait effect:** `B_lv = Λ · α_lv'` (`extract_lv_effects(type = "trait_effect")`,
  currently the default) is the trait-scale slope implied by the latent model. It is not a
  separate per-trait fixed effect; it is the reduced-rank product of the loading matrix and
  axis coefficients. Unlike `α_lv`, `B_lv` is invariant under `Λ → ΛQ, α_lv → α_lv Q` for any
  orthogonal `Q`, so it is the current interval target.

`B_lv` is admitted for **`K ≥ 1`** (rotation invariance), complete responses, a single ordinary
latent block. Axis-effect SEs are **not** currently admitted; they need a declared
rotation/constraint convention before their uncertainty can be interpreted honestly.

## 3. Confidence intervals — the trio (Wald / profile / bootstrap)

All three target `vec(B_lv)` (`confint_lv_effects`). They do **not** attach to the raw
axis-effect table `α_lv`:
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

- **MODEL A (v1, chosen):** the predictor-informed score MEAN (unit axis) composed with the
  existing **trait-axis phylogenetic trait-covariance** (`Σ_phy`, species axis). The axes are
  **orthogonal and additive** — no new identifiability hazard. Reuses the J3 closed-form phylo
  marginal verbatim (the rotation trick survives the `X_lv` residual mean shift — pinned to
  7e-15 against a dense `vec(y) ~ N(μ, I_n⊗A + J_n⊗B)` Gaussian). The Gaussian CI trio can be
  routed through the same packed vector + Hessian shape, and the `B_lv` extractor is unchanged,
  but coverage is not yet calibrated: the p=80, K=2, lambda=0.5 `B_lv` weak cell under-covers
  under Wald, t-Wald, percentile bootstrap, and the bench-only `bootstrap_basic` candidate.
  Gaussian-only v1; non-Gaussian phylo `X_lv` is a separate later gate (new Laplace-core
  derivation).
- **MODEL B (post-v1.0):** the latent SCORE itself is phylo-correlated across tips
  (`z = X_lv·α + u, u ~ N(0, Σ_phy)`) — **phylogenetic factor analysis** at TMB speed. Native-TMB
  design-65 `kernel_latent` extension; carries a real mean-vs-covariance confound when `x` is
  itself heritable. Needs one-row-per-species comparative data.

Animal / spatial / kernel × `X_lv` follow the Model A pattern after phylo.

## 6. R grammar

**Status: the ordinary case IS wired** (verified 2026-06-27). `latent(..., lv = ~ x)` for ordinary
unit-tier **Gaussian + binomial** (logit/probit/cloglog) is implemented: `R/lv-predictor.R`
materialises X_lv; `R/brms-sugar.R::.abort_unsupported_lv_keyword` fail-loudly guards `lv` on
non-ordinary covstructs ("`lv` is reserved for ordinary `latent` only … remove until LV-07 moves");
`parse-multi-formula.R` captures the arg; `test-lv-parser-guard.R` covers the preflight (malformed
formulas, invalid predictor columns, unsupported regimes). The held R branches extend the X_lv
*families* (NB2/Gamma/Beta) on `engine = "julia"`.

**Remaining (the phylo extension):** lift `.abort_unsupported_lv_keyword` for `phylo_latent`
(validation row LV-07) and wire `phylo_latent(..., lv = ~ x)` to the phylo×X_lv route once the engine
Model A + the bridge phylo plumbing land. Requirements for that wiring:
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

- **Ordinary bridge `X_lv`:** `B_lv` recovery and CI coverage are covered for the bridge
  X_lv families (K=1/K=2) by #116-#126.
- **Phylo Model A point plumbing:** the engine admits the Gaussian direct/native Model A route,
  and small smoke rows plus the two nulls exercise that path. These are plumbing checks only,
  not a public coverage claim.
- **Phylo Model A interval gate (blocked, 2026-06-30):** the p=80, K=2, lambda=0.5 `B_lv`
  weak cell fails current interval calibration. The 10-seed capped percentile bootstrap
  aggregate covered `675/800 = 0.844`; detailed rows showed the same miss side as Wald and
  narrower bootstrap intervals. The bench-only `bootstrap_basic` candidate covered
  `591/720 = 0.821` across 9 valid DRAC seeds; even a perfect cancelled task 1 would only reach
  `671/800 = 0.839`. A saturated direct-mean comparator showed ordinary `Y ~ X_lv` slopes track
  the fitted latent-product slopes almost exactly, including the bad task 8 (`0.536` vs `0.533`
  of truth), so the block is finite-sample realised-slope/interval calibration rather than a
  simple `B_lv` extractor artifact.
- **Remaining gate:** do not launch or advertise the full λ×n_species×K production sweep until
  the weak cell has a defensible interval target or an explicit blocked/public-boundary decision.
  The existing seed harness remains `bench/phylo_xlv_coverage.jl`.

## 8. Honest scope

Only `B_lv` is rotation-stable, so the current SE/CI work is for induced trait-scale slopes, not
for the usual CLV/axis-effect table. Treat `α_lv` as the primary constrained-ordination display
only after naming the rotation or loading-constraint convention, and do not report SEs for it yet.
Under phylo, advertise no public `B_lv` interval coverage yet: point/CI plumbing is local, interval
calibration is blocked for the weak cell, and `gllvmTMB` source-specific `lv = ~ x` grammar should
continue to fail loudly. Demote the per-axis α / Λ-vs-Ψ split to Level 3 (rank-fragile). Do not
imply non-Gaussian or bridge parity from the Gaussian Model A slice. Keep capability promotion
parked until the register/NEWS/article slice.
