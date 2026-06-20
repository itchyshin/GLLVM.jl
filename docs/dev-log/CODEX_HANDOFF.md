# GLLVM.jl — Handover Report for Codex

## Current Note (2026-06-15)

This report is historical context from an engine-first handoff. The current
finish sequence is **R-first**: native `gllvmTMB` functionality and the R user
workflow define the oracle; `GLLVM.jl` mirrors admitted rows, supplies parity
evidence, and accelerates them only after point estimates, logLik/objective,
CI or CI-status, docs, tests, issue rows, and Rose audit agree.

Do not read "full parity" below as a release claim. Treat those rows as
engine-side implemented/planned claims that still need R-side admission,
bridge parity, documentation, and issue-led evidence. REML remains Gaussian-only;
HSquared-style AI-REML is future design input for exact Gaussian cells, not a
name for non-Gaussian Laplace acceleration.

## 0. TL;DR
A cloud-agent session (with **no Julia/R runtime**) brought GLLVM.jl to a broad
engine-side parity candidate, all CI-green on `main`. Everything that needs a
**runtime to measure or numerically validate** was deliberately left for a local
agent with a Julia + R toolchain (Codex). Your job: run the bench, decide the
gradient default, validate the R↔Julia bridge, land the exact algorithmic
speedups, and prepare the release ledger for maintainer signoff.

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
Measured 2026-06-07, then re-opened on 2026-06-14 after the high-rate Poisson
Laplace-mode safeguard. `:analytic` is now faster and likelihood-stable for
Poisson, NB2, Binomial, Beta, and Gamma on the no-mask/no-offset path, so all
five one-part GLM fitters default to `:analytic` with finite-difference fallback.
The 2026-06-14 Gamma gate showed `|ΔlogLik| ≈ 1e-12` and about 10-14x speedups
on quick and medium benchmark cells. ≈ `2·nparams → 1` marginal-evaluations per
L-BFGS step for the defaulted families.

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

### P4 — Release/tag signoff ledger
`Project.toml` and `CHANGELOG.md` now carry the v0.3.0 capstone state, but the
tag is **not automatic**. Do not tag, register, or imply publication until main
CI, docs, GitHub issues, the R bridge parity ledger, and Rose's public-claim
audit agree. The maintainer decides whether and when to tag; keep General
registry submission separate from package-health evidence.

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
