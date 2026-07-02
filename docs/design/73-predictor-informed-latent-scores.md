# Design 73 - Predictor-informed latent scores: `latent(..., lv = ~ x)`

**Status (2026-07-02):** the current LV arc is closed as operating truth.
Ordinary `X_lv` engine + CI trio shipped to `main`
(#116-#126). The original phylo Model A population-`B_lv` interval target is
retired/parked for v1 after the p=80, K=2, lambda=0.5 weak cell, the task-8
profile miss, the K=1 `98/100` diagnostic, and the direct-slope strict-gate
failure. A changed eta-scale realized/design-conditional target,
`B_eta_realized`, later passed Gate 0-3, including DRAC Gate 3
(`2495/2500 = 0.998000000`, MCSE `0.000890835`, Wilson 95 percent interval
`0.995326484` to `0.999145426`). That is strong internal evidence for the
changed target, not public source-specific `lv` support. The R
`lv = ~ x` source-specific formula grammar, PR #127 reopening, public phylo
Model A wording, and non-Gaussian/source-specific extensions remain blocked
until Shinichi explicitly authorizes a new gated slice. The paired `gllvmTMB`
closeout guard now rejects source-specific `lv = ~ env` across phylo, spatial,
animal, and kernel structural keywords and legacy aliases before desugaring can
silently drop it; this is a fail-loud boundary, not support. Mixed-family LV
remains point/postfit only, and non-Gaussian / source-specific structural LV
starts a separate derivation and ADEMP arc. Ordinary one-part non-Gaussian
selected-entry `B_lv` profile-LR route evidence is now local for Poisson,
Binomial logit, NB2, Gamma, Beta, and shared-cutpoint Ordinal logit
(`test/test_lv_ci.jl`, `196/196`, 3m57.7s); that is route evidence only, not
coverage calibration, R bridge profile transport, per-trait ordinal bridge
parity, mixed-family CI support, source-specific `lv`, or `unique=` parity.
The structural-source non-Gaussian LV Gate 0 matrix is recorded in
`docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`.
The first source/family S0 target page is phylo x Poisson, recorded in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md`;
the internal S1 combined likelihood proof is recorded in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md`.
The local S1 selected-entry route canary is recorded in
`docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`.
Together these are private Julia plumbing and canary evidence only: no public
fitter, bridge transport, R grammar, coverage calibration, or source-specific
`lv` support follows from them. A second source/family target, phylo x
Binomial logit, is recorded in
`docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md`;
its internal S1 likelihood proof and one private selected-entry canary are
recorded in
`docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md`.
This adds only private Julia route evidence: no public fitter, bridge
transport, R grammar, coverage calibration, compute, or source-specific `lv`
support follows from it.
This doc is the spec the Julia comments (`likelihood.jl:405`) reference. The
compact evidence freeze is
`docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md`;
the detailed Gate 0-3 record is
`docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md`.

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
- **Induced trait effect:** `B_lv = Λ · α_lv'` (`extract_lv_effects(type = "trait_effect")`)
  is the trait-scale slope implied by the latent model. It is not a separate per-trait fixed
  effect; it is the reduced-rank product of the loading matrix and axis coefficients. Unlike
  `α_lv`, `B_lv` is invariant under `Λ → ΛQ, α_lv → α_lv Q` for any orthogonal `Q`, so it is
  the current interval target. In the public gllvmTMB extractor, `axis_effect` is now the
  ordinary default and `trait_effect` is requested explicitly.

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

**Phylo Model A lock (2026-07-01):** do not use the full trio as a rescue for
source-specific phylo `lv`. Bootstrap is retired for the current phylo weak-cell
route, endpoint profile fan-out is retired for the old population-`B_lv` target
after the `profile_truth` miss, and K = 1 same-route profile scaling is stopped
after the 20-replicate diagnostic gate. If Model A is reopened, profile-LR is a
selected-entry truth-inclusion canary only after a genuinely different target or
regime is named. Wald output for `alpha_lv` is acceptable only as the ordinary
conditional axis/access-effect view under the fitted loading convention.

## 4. Families

Gaussian + Poisson + Binomial (logit/probit/cloglog) + NB2 + Gamma + Beta +
shared-cutpoint Ordinal logit. Exotic families (Tweedie/ZI/hurdle/Student-t)
for `X_lv` are post-v1.0.

For ordinary one-part `X_lv` fits, selected-entry `B_lv` profile-LR route
canaries are local for Poisson, Binomial logit, NB2, Gamma, Beta, and
shared-cutpoint Ordinal logit. These canaries prove finite endpoint routing and
known-DGP truth inclusion for one selected entry per family. They do not provide
coverage calibration and they do not transfer to source-specific
phylo/spatial/animal/kernel LV, mixed-family vectors, bridge profile transport,
per-trait ordinal bridge parity, missing/masked responses, or `unique=` parity.

## 5. Structured sources × `X_lv` — phylogenetic (Model A)

The headline extension: compose `X_lv` with structured latent dependence. **Two non-equivalent
models** (see `intake/2026-06-27-phylo-xlv-design.md`):

- **MODEL A (local v1 candidate, now blocked):** the predictor-informed score MEAN (unit axis) composed with the
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
materialises X_lv; `R/brms-sugar.R::.abort_source_specific_lv` fail-loudly guards `lv` on
source-specific structural keywords and aliases ("`lv` is reserved for ordinary `latent` only …");
`parse-multi-formula.R` captures the arg; `test-lv-parser-guard.R` covers the preflight (malformed
formulas, invalid predictor columns, unsupported regimes). The held R branches extend the X_lv
*families* (NB2/Gamma/Beta) on `engine = "julia"`.

**Remaining (future-only source-specific phylo reopening):** do **not** lift
the source-specific `lv` guard for `phylo_latent` (validation row LV-07) under
the current Model A population-`B_lv` interval target. Ordinary
`latent(..., lv = ~ x)` remains the supported route; source-specific
`phylo_latent(..., lv = ~ x)` remains guarded/fail-loud. Only revisit
source-specific phylo `lv` after structural redesign with a genuinely different
target/regime and fresh evidence, or explicit maintainer acceptance of v1
retirement boundaries.
Requirements for any future authorized wiring:
- Deliberately extend the current ordinary `latent()` admission to the named
  source-specific constructor only after the new gate is accepted; enforce
  inside `rewrite_canonical_aliases()` (`R/brms-sugar.R`), NOT the
  never-evaluated constructor. Validate one-sided, build `model.matrix` against
  `data`, attach as a STRUCTURED marker (`extra$.lv_formula` + materialized
  `extra$.X_lv`).
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
- **Profile-LR truth-inclusion canary (blocked, 2026-06-30):** a bench-only
  `profile_truth` diagnostic constrained task-8 entry `B_lv[71,1]` to its known
  simulation truth. With a 250-iteration constrained solve it converged and
  missed truth: `LR = 9.99181181962` versus the one-df 95% cutoff
  `3.84145882069`. Therefore endpoint profile fan-out is not an admissible next
  rescue for the old target.
- **K = 1 narrowed-regime profile gate (blocked, 2026-07-01):** a small
  positive-control path first passed a 5-seed selected-entry diagnostic
  (`25/25` truth-included), but the predeclared 20-replicate gate then failed:
  `20/20` fits converged, `100/100` selected entries were usable, and `98/100`
  included truth. The two misses were converged constrained solves, task 15
  entry 10 (`LR = 4.94199940694`) and task 19 entry 20
  (`LR = 5.14288022148`), both above the `3.84145882069` cutoff. Therefore K = 1
  same-route profile scaling is stopped.
- **Remaining gate:** do not launch or advertise the full λ x n_species x K production sweep.
  The next admissible step is a structural target redesign with a genuinely
  different estimand/regime and fresh ADEMP evidence in a future branch. For
  v1, public source-specific phylo `lv` is retired/parked and the existing seed
  harness remains local diagnostic tooling (`bench/phylo_xlv_coverage.jl`).
- **Phylo x Poisson structural LV S1 likelihood proof (local, 2026-07-02):**
  the internal `_phylo_poisson_xlv_marginal_loglik` route now jointly integrates
  site-score innovations and the augmented phylo random intercept for
  Poisson(log) with `X_lv`. It is reduction-tested against ordinary Poisson
  `X_lv`, phylo-only Poisson GLM at `Lambda = 0`, and a dense leaf-covariance
  reference. A private truth-startable point wrapper and selected-entry
  penalty-profile route now cover one deterministic `B_eta_realized`
  finite-endpoint canary (`test/test_phylo_poisson_xlv.jl`, 9/9 likelihood
  anchors + 22/22 canary assertions). This checks finite profile endpoints,
  MLE bracketing, truth inclusion, and LR below cutoff for one selected entry.
  This is local S1 route evidence, not public source-specific `lv` support,
  coverage calibration, bridge transport, R grammar, or a production scaling
  path.
- **Phylo x Binomial structural LV S1 likelihood proof (local, 2026-07-02):**
  the internal `_phylo_binomial_xlv_marginal_loglik` route now jointly
  integrates site-score innovations and the augmented phylo random intercept
  for Binomial(logit) with `X_lv` and a required trial-count matrix `N`. It is
  reduction-tested against ordinary Binomial logit `X_lv`, phylo-only Binomial
  GLM at `Lambda = 0`, and a dense leaf-covariance reference. It also guards
  trial-count dimensions, positive and integer-valued `N`, integer-valued
  successes, and `0 <= Y <= N`. A private truth-startable point wrapper and
  selected-entry penalty-profile route cover one deterministic
  `B_eta_realized` finite-endpoint canary
  (`test/test_phylo_binomial_xlv.jl`, 14/14 likelihood anchors + 22/22 canary
  assertions). This checks finite profile endpoints, MLE bracketing, truth
  inclusion, and LR below cutoff for one selected entry. This is local S1 route
  evidence, not public source-specific `lv` support, coverage calibration,
  bridge transport, R grammar, compute, or a production scaling path.
- **Realized direct-slope canary tooling (diagnostic, 2026-07-01):** the bench
  runner now has `profile_direct_slope`, which computes a saturated per-trait
  `Y ~ X_lv` slope target from the realized replicate and checks selected-entry
  LR inclusion against that descriptive target. A tiny local smoke passed `2/2`
  selected entries for `B_lv_direct_slope`; a follow-up K = 1 five-seed
  diagnostic passed `25/25` selected entries, and the old task-8 entry-71
  population-target failure row passed under the changed target. The K = 1
  20-replicate direct-slope diagnostic then returned `96/100` entry coverage
  but fired the strict no-miss stop rule with four converged selected-entry
  misses. This is mixed diagnostic evidence for the realized target, not proof
  that source-specific phylo `lv` is supported.

## 8. Honest scope

Only `B_lv` is rotation-stable, so the current promotion gate is for induced
trait-scale slopes, not for the usual CLV/axis-effect table. Treat `α_lv` as a
conditional axis/access-effect display under the fitted loading convention;
Wald output is acceptable for that display, but it is not the calibrated phylo
Model A evidence target.
Under phylo, advertise no public `B_lv` interval coverage yet: point/CI plumbing is local, interval
calibration is blocked for the weak cell, and `gllvmTMB` source-specific `lv = ~ x` grammar should
continue to fail loudly. Demote the per-axis α / Λ-vs-Ψ split to Level 3 (rank-fragile). Do not
imply non-Gaussian or bridge parity from the Gaussian Model A slice. Keep capability promotion
parked until the register/NEWS/article slice.
