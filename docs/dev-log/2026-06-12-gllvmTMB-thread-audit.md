# Read-only audit of GLLVM.jl — handoff from the gllvmTMB Claude thread

**Date:** 2026-06-12 · **Auditor:** Claude (gllvmTMB thread), 3 parallel review
agents + a figure pass · **Scope:** docs text + figures, source + docstrings,
tests + API. **Read-only — nothing was modified.** Audited the **working-tree**
state (branch `codex/non-gaussian-fitter-gradients`, with the in-flight docs-polish
edits on disk). Untracked handoff note — read, action what you agree with, delete.

Lenses: Rose (consistency), Pat (reader-path), Darwin (bio framing),
Boole/Noether (terminology), Karpinski (Julia quality), Hopper (R-parity),
Curie (test coverage), Emmy (API), Florence (figures).

## Two corrections to your own assumptions (verify these first)

- **`Pkg.test()` is NOT broken.** It runs **green** here — `quality | Pass 12`,
  Aqua + JET included. The "can't merge projects / use `julia --project=. test/runtests.jl`"
  note (AGENTS.md ~§161) is **stale**. Decide which command is canonical, because
  it matters (next point).
- **Aqua + JET only run under `Pkg.test()`**, not under the documented
  `julia --project=. test/runtests.jl` (there they report `Broken 2`,
  `test_quality.jl:21,34`). So the "Engine Quality Battery" is invisible on the
  command your docs tell people to use.

## Executive summary — four themes

1. **The headline parity claim outruns its evidence** (BLOCKING). README/AGENTS
   assert machine-precision agreement with R `gllvmTMB` on the Gaussian **and
   phylogenetic** paths. The only parity test is `test/parity/test_gaussian_parity.jl`
   — Gaussian-only, self-described DRAFT, loose (`logL rtol=1e-3`, `Σ_y atol=1e-2`),
   gated behind `GLLVM_PARITY_TESTS=1`, and **never run by CI**. No phylogenetic and
   no non-Gaussian R-parity exists. (Found independently by the code and test audits.)
2. **A unified-API bug**: `fit_gllvm` throws "Delta-lognormal not implemented"
   though `fit_delta_lognormal_gllvm` exists and is exported
   (`families/fit_gllvm.jl:37-39`).
3. **A large body of in-tree work is compiled out and tested only by orphans** —
   ~220 assertions across 9 test files (phylo EM, SQUAREM, edge-incidence,
   contrasts, relaxed-clock, transformed-Wald CIs, sparse-phy gradient) are not
   wired into `runtests.jl`.
4. **Doc ↔ code drift** at a few reader-facing spots (a shipped feature listed as
   PLANNED; examples that error; a single-trait model presented as the multivariate
   phylo path).

The **core engine** (Gaussian + 6 one-part + 3 two-part families) is genuinely
well-built and well-tested — recovery + FD-gradient + post-fit + CI all green. The
risk is concentrated at the **edges**: parity claims, orphaned phylo work, and the
unified dispatcher.

## Consolidated priority list

### BLOCKING
1. **Parity claim vs evidence** — soften the README/AGENTS "machine precision,
   Gaussian + phylogenetic" wording to "verified locally, opt-in, Gaussian-only,"
   **or** wire a small frozen-expected-value parity check into `runtests.jl` and add
   ≥1 Poisson + ≥1 phylo case. (`README.md:31-33`, `test/parity/`)
2. **`fit_gllvm` rejects an implemented family** — Delta-lognormal (and the other
   two two-part fitters are omitted from the dispatcher). (`families/fit_gllvm.jl:28-39`)
3. **`changelog.md:17` lists `fit_phylo_gaussian` as PLANNED** though it's shipped
   and exported (`src/fit_phylo.jl:105`, `src/GLLVM.jl:56`). Self-contradiction.

### SHOULD-FIX
4. **~220 orphan test assertions unrun** — wire the 9 functional orphan files into
   `runtests.jl` (or document why they're parked). `test_sparse_phy_grad.jl:8` also
   double-includes an already-loaded module.
5. **`getLV(fit)` examples omit the required `y` arg** → they error.
   (`index.md:53`, `response-families.md:193`; correct form `getLV(fit, Y)` at
   `working-with-a-fit.md:26`.)
6. **`fit_phylo_gaussian` scope** — it's a **single-trait univariate** phylo model
   (`PhyloGaussianFit` holds only `μ, σ²_phy, σ²_eps`, `fit_phylo.jl:26-32`), but
   `pitfalls.md:35-38` / `roadmap` / `changelog` present it as the scalable
   multivariate-GLLVM phylo fitter. State the scope explicitly.
7. **Mirror the `latent`/`unique` fold** (ties to the R-side change in the inbox
   note) — `covariance-correlation.md:46-51` "When you need `unique`" should become
   "`latent` already includes Ψ by default"; also `model.md:40-49`,
   `gllvmtmb-parity.md:35`, `structured-dependence.md`.
8. **Five exported link types undocumented** (`LogitLink`, `ProbitLink`,
   `CLogLogLink`, `IdentityLink`, `LogLink` — `families/links.jl:11-15`).
9. **Broad `catch` blocks (23)** swallow everything incl. `InterruptException`
   (`fit.jl:111,116,123`; `families/laplace.jl:27-31,123-127`) → narrow to
   `SingularException`/`PosDefException`.
10. **Public-intent functions not exported** — `proportions`,
    `bootstrap_ci_derived`, `profile_ci_derived` (`confint_derived.jl:226,484,909`).
11. **`StatsAPI` collision** — `predict`/`fitted`/`residuals`/`aic`/`bic`/`confint`
    are fresh package-local generics shadowing the ecosystem owners; depend on
    `StatsAPI` and extend them instead of forcing `GLLVM.`-qualification.
12. **Stale compat** — `ForwardDiff = "0.10"` (current major 1.x) will block
    downstream resolution (`Project.toml`).
13. **Alloc on the gradient hot path** — `_CinvM` builds a fresh `p×K_B` via
    `reduce(hcat, …)` every gradient call (`sparse_phy_grad.jl:276-277`);
    preallocate.
14. **Docs name a non-existent CI function** — `confint_derived`
    (`covariance-correlation.md:58`); the real API is `bootstrap_ci_derived` /
    `profile_ci_derived` (not exported).
15. **cloglog link renders as `1 − exp(−eη)`** (LaTeX artifact for
    `exp(-exp(η))`), `response-families.md:58`.
16. **"340× on the phylogenetic path" overstates** — the benchmark grid is
    Gaussian-only; `changelog.md:34` says it correctly ("Gaussian grid").
    (`gllvmtmb-parity.md:64`)
17. **Figures (Florence)** — see the figure section below; biplot label collision +
    non-1:1 aspect ratio, and the three headline figures use inconsistent example
    data (T1–T8 vs Sp1–Sp8 vs Sp1–Sp6).

### NICE-TO-HAVE
- `index.md:79` "benchmark grid" link points at `comparison.md` (LMM-context page)
  instead of `benchmarks.md`.
- Headline speedup reported two ways (`~340×` vs per-bin `~190/280/520×`) with no
  bridging sentence (they reconcile: 340 is the grand median).
- Covariance-scale extractors (`communality`/`correlation`/`sigma_y_site`/
  `phylo_signal`) are Gaussian-only → non-Gaussian `extract_*` parity gap (honestly
  disclosed in README).
- `simulate.jl` is a one-line stub but README "Features" implies simulation exists.
- Low-level gradient kernels (`node_grad`, `NodePerSpecies`, …) exported into the
  top namespace — implementation surface as public API.
- `structured_schur.jl` / `families/structured_poisson.jl` are well-built but
  dormant/un-exported — mark "experimental / not wired" so reviewers know.
- `takahashi_selinv.jl:113-260` duplicates ~45 lines of recursion; `linkfun`
  unguarded at μ∈{0,1} (`links.jl:45-48`); `structured_cov` slice allocs.
- CI runs on every push to `main` and tri-OS on every stable run — prefer
  `workflow_dispatch` + PR-only, reserve macOS/Windows for releases (`CI.yml:2-23`).
- `structured-dependence.md:14-16` model block uses a plain fence (renders
  monospace) with an unbalanced paren — convert to a `math` block.

## Figures (Florence)

Three assets in `docs/src/assets/` — all clean, publication-leaning, honest
(y-axes from 0, correlation colormap diverging-at-0 which correctly shows all
correlations are positive). Findings:

- **`ordination_biplot.png` [SHOULD-FIX]** — the upper loading arrows collide:
  `Sp5`/`Sp6`/`Sp7` labels overlap into "S Sp6 / S Sp7." Repel the labels.
- **`ordination_biplot.png` [SHOULD-FIX]** — the panel is **not 1:1 aspect**
  (x≈−3..3, y≈−2..2.4). For a biplot, unequal aspect distorts the angle/length
  reading of loading arrows. Lock equal aspect.
- **`ordination_biplot.png` [NICE]** — grey points (sites) are unexplained; a
  one-line caption ("points = sites, arrows = response loadings") would orient Pat.
- **Cross-figure [SHOULD-FIX]** — the three headline figures use **different
  example data and label schemes**: communality uses `T1–T8` (8 traits), the
  heatmap `Sp1–Sp6` (6 responses), the biplot `Sp1–Sp8`. If they share a page, run
  them off one consistent example.
- **`communality_bars.png` [NICE]** — the dashed reference line (~0.83) is
  unlabeled; annotate it (mean communality?).
- **All three [NICE]** — point estimates only; communality/correlation CIs exist in
  the engine (`confint_derived`). For report-grade versions, consider the
  uncertainty/Confidence-Eye treatment.

## Notes

- Repo policy respected: no policy-violating attributions found in any file read;
  edge-incidence provenance is cited via Bolker's `phylog.rmd`.
- Honest-scope language elsewhere is strong (`gllvmtmb-parity.md:71-78` "Honest
  gaps", `comparison.md:49-63` "Honest caveats") — keep that discipline.
- `Σ = ΛΛᵀ + Ψ`, `psi`/`Psi`, and `communality = (ΛΛᵀ)ₜₜ/Σₜₜ` are used consistently
  across pages and match the code — the only terminology risk is the `latent`/`unique`
  fold (#7).
