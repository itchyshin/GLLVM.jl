# GLLVM.jl — Handover Report for Codex

## 0. TL;DR
A cloud-agent session (with **no Julia/R runtime**) brought GLLVM.jl to **full
gllvmTMB parity and beyond**, all CI-green on `main`. Everything that needs a
**runtime to measure or numerically validate** was deliberately left for a local
agent with a Julia + R toolchain (Codex). Your job: run the bench, decide the
gradient default, validate the R↔Julia bridge, land the exact algorithmic
speedups, and tag a release.

**Accuracy bar (non-negotiable):** every change must be anchored by an
exact-equality or gradient-vs-finite-difference test, and the full `Pkg.test()`
suite must stay green. Branch off the latest `main`; one concern per commit.

## 1. State of the package (on `main`)
- **Families:** Gaussian, Poisson, NB2, NB1, Binomial, Beta, Gamma, Exponential,
  Ordinal (logit **and** probit), Tweedie, ZIP/ZINB/ZIB, Hurdle-Poisson/NB,
  Delta-lognormal/-Gamma, beta-hurdle, ordered-beta, **beta-binomial**, and
  **Conway–Maxwell–Poisson** (under/over-dispersion — beyond gllvmTMB).
- **Dispersion:** per-species/grouped for NB/Beta/Gamma/NB1/Tweedie
  (`fit_*_gllvm_grouped`); **Gaussian per-species variance**
  (`fit_gaussian_pervar_gllvm`).
- **Structure:** fixed **and random** row effects; phylogenetic GLM
  (`fit_phylo_glm`); SPDE spatial latent field; covariates / fourth-corner / RRR /
  constrained / quadratic.
- **Inference & post-fit:** Wald / profile / parametric-bootstrap CIs, aic/bic,
  Dunn–Smyth residuals, `coef_table`, ordination — across the family set.
- **API:** unified `fit_gllvm(Y; family, K/num_lv, row_eff, disp_group, pervar,
  link, N)`; `@formula` front-end (v1).
- **R bridge scaffold:** `r/gllvmtmb_julia.R`, `r/parity_check.R`,
  `r/README_bridge.md`; parameterization map in `docs/src/gllvmtmb-parity.md`.
- **Speed (already done, bit-exact):** allocation reductions in the Laplace
  mode-finder (`src/families/laplace.jl`), the two-part mode-finder
  (`src/families/twopart.jl`), and the Poisson/NB fit objective + FD-grad fallback.
  No result change — the suite's machine-precision anchors are the guard.

**Read first:** this file, `bench/SPEED_NOTES.md`, `docs/src/gllvmtmb-parity.md`
(the R↔Julia "bridge map"), `CHANGELOG.md` (Unreleased).

## 2. Runtime-gated work (prioritized)

### P1 — Decide the gradient default (biggest single speed win)
```
julia --project=. bench/speed_bench.jl
```
Times each GLM fitter `gradient=:finite` vs `:analytic` and prints the **logLik
delta**. If `:analytic` is faster across the grid AND the deltas are ≤1e-6, flip
the default to `:analytic` in `fit_poisson_gllvm`, `fit_nb_gllvm`,
`fit_binomial_gllvm`, `fit_gamma_gllvm`, `fit_beta_gllvm` (analytic path is in
`src/laplace_grad.jl`, gated to no-mask/no-offset with a finite-difference
fallback). Then `Pkg.test()` → if green, commit. ≈ `2·nparams → 1`
marginal-evaluations per L-BFGS step; kept opt-in only because the cloud session
could not measure it.

### P2 — Validate the R↔Julia bridge (proves the parity claim end-to-end)
Fix the `## VERIFY:` spots in `r/gllvmtmb_julia.R` (JuliaConnectoR access to
Unicode struct fields `β`/`φ`/`α`/`φ²`, zero-arg family constructors, Symbol
marshaling), then run `r/parity_check.R` against R `{gllvm}`. Acceptance: logLik /
β / loadings (Procrustes-aligned) / dispersion agree after the conversions
(NB `r = 1/φ`, Gamma `α → φ`, …). Pin matching `method` (gllvm defaults to VA,
GLLVM.jl to Laplace).

### P3 — Exact algorithmic speedups (north star: "Recipe 1" below)
- **Takahashi / selected-inverse O(p) log-det gradient** for the sparse-phylo
  path: `src/node_gradient.jl` (`node_grad`) is already O(p) and documented to
  match `sparse_phy_grad` (the O(p²) path currently wired) to ≤1e-13 for
  `K_aug==1`. Wire `node_grad` where verified; validate equality + speedup.
- **Reverse-mode / implicit-function-theorem Laplace adjoint** for the general
  non-Gaussian marginal (TMB/RTMB design; `ImplicitDifferentiation.jl` or Enzyme)
  to replace the finite-difference outer gradient. Validate `grad ≈ FD` to 1e-6,
  then `Pkg.test()`. Biggest exact non-Gaussian win.
- **Gaussian closed-form path** (`src/likelihood.jl`) allocation reduction —
  AD-entangled (ForwardDiff Duals flow through the marginal), so it needs a runtime
  to confirm AD-compatibility + bit-exactness.

### P4 — Tag a release
The `CHANGELOG.md` Unreleased section is ready; bump `Project.toml` to v0.3.0 and
tag. (Note: do NOT register to the General registry yet — the maintainer wants it
kept unpublished while testing.)

## 3. Do NOT redo
The bit-exact Laplace/two-part mode-finder buffer reuse and the Poisson/NB
allocation hoists already landed and are CI-validated. Don't re-optimize those.

## 4. Coordination
- The open `codex/*` PRs **#60** and **#67** (phylo-Poisson gradient) are still
  open — reconcile them: the engine files they reference (`node_gradient.jl`,
  `sparse_phy_grad.jl`, `takahashi_selinv.jl`) are already on `main`, so check what
  is genuinely new vs superseded.
- Keep every change accuracy-anchored; run the full `Pkg.test()` before proposing
  a PR.

## 5. The "unique combination" speed recipe (north star, from the literature)
**Exact-preserving Laplace turbocharge** (same optimum, only faster):
reverse-mode / implicit-function Laplace adjoint **+** Takahashi selected-inverse
log-det gradient **+** Fisher-scoring inner Newton **+** PPCA warm start **+**
Woodbury low-rank-plus-diagonal. GLLVM.jl already has Woodbury
(`src/lowrank_cholesky.jl`), PPCA (`src/ppca_init.jl`), SQUAREM
(`src/em_squarem.jl`), and the sparse-phylo path; P3 closes the rest. Secondary:
Fisher-scoring + SQUAREM/Anderson acceleration for the EM/VA paths.

Refs: Kristensen et al. 2016 (TMB, *JSS*); Takahashi 1973 / Erisman & Tinney 1975;
Korhonen, Hui, Niku, Taskinen 2023 (EVA, *Stat & Comp*); Niku et al. 2019 (gllvm,
*MEE* / *PLOS One*); Kidziński et al. 2022 (GMF, *JMLR*); Varadhan & Roland 2008
(SQUAREM); Walker & Ni 2011 (Anderson). Full table in `bench/SPEED_NOTES.md`.
</content>
