# After-Task Report: 2026-08-30 Road to 0.7.0 Tracks 1 to 6 Verification & Pre-Publish Audit

## Executive Summary
This after-task report documents the completed verification and audit for Tracks 1 through 6 of the **Road to 0.7.0 Parity & Release** campaign for `GLLVM.jl`:
1. **Track 1 (Student-t Estimated-ν Parity):** Verified joint per-trait degrees-of-freedom estimation $\nu_j = 1 + \exp(\theta_{\nu, j})$ matching `gllvmTMB`'s exact default parameterisation ($\Delta \text{logLik} = 6.8 \times 10^{-10}$, relative $7.3 \times 10^{-13}$). Parity Cell 9 marked fully PAID.
2. **Track 2 (Phylogenetic Subsystem Reconnection):** Reconnected 5 phylogenetic core files (`phylo_contrasts.jl`, `edge_incidence.jl`, `em_phylo.jl`, `em_squarem.jl`, `relaxed_clock.jl`) and 7 test suites into the main runner `test/runtests.jl`. Duplicate `takahashi_selinv.jl` include removed.
3. **Track 3 (CI Keystone & RCall Parity Runner):** Resolved headless RCall execution in GitHub Actions via `LD_PRELOAD` pointing to Julia's `libunwind.so.8`. The `Parity Tests (RCall + gllvmTMB)` CI workflow is active on PR #274.
4. **Track 4 (StatsAPI & Documentation Consistency):** Verified StatsAPI implementations (`coef`, `vcov`, `nobs`, `dof`, `loglikelihood`, `stderror`, `coeftable`, `summary`) and synchronized headline speedup citations (`median 265.1× (range 161–698×)` on the Gaussian closed-form profile grid) across `README.md`, `CLAUDE.md`, and `AGENTS.md`.
5. **Track 5 (Documenter & Ecological Vignettes Verification):** Built the full documentation site locally via `julia --project=docs docs/make.jl` under DocumenterVitepress v1.6.4 with 0 errors. Verified ecological vignettes (`vignettes/community-abundance.md`, `vignettes/phylogenetic-gllvm.md`), guides, and categorized API references. GitHub Actions Documenter run `33291940784` passed (2m33s) and deployed preview to `https://itchyshin.github.io/GLLVM.jl/previews/PR274/`.
6. **Track 6 (Rose Pre-Publish Consistency Audit):** Conducted a comprehensive Rose pre-publish audit. Verified that all public claims, response family listings, phylogenetic methods, formula syntax, and speedup boundaries accurately reflect codebase reality without ungrounded overstatements.

---

## Detailed Track Breakdown

### Track 1: Student-t Joint ν-Estimation & Parity Cell 9
- **Implementation:** `StudentTFamily` defaults to estimating $\nu$ (`\nu === nothing`), packing $\log(\nu_j - 1)$ parameters alongside dispersion parameters $\log(\sigma_j)$ under both `:shared` and `:species` dispersion groupings (`disp_group`).
- **Parity Result:** Tested against `gllvmTMB 0.7.1` in `test/parity/test_studentt_parity.jl`:
  - $\Delta \text{logLik} = 6.8 \times 10^{-10}$ (relative difference $7.3 \times 10^{-13}$).
  - Point estimates $\hat{\beta}$, $\hat{\Lambda}$, $\hat{\sigma}$, and $\hat{\nu}$ agree to 4–5 significant figures.

### Track 2: Phylogenetic Subsystem Reconnection
- **Files Reconnected in `src/GLLVM.jl`:**
  - `src/phylo_contrasts.jl` (Felsenstein independent contrasts)
  - `src/edge_incidence.jl` (Edge-node incidence representation)
  - `src/em_phylo.jl` (Gradient-free EM phylogenetic solver)
  - `src/em_squarem.jl` (SQUAREM extrapolation accelerator)
  - `src/relaxed_clock.jl` (Relaxed-clock per-branch rates)
- **Test Suites Reconnected in `test/runtests.jl`:**
  - `test/test_phylo_contrasts.jl`
  - `test/test_edge_incidence.jl`
  - `test/test_phylo_branch_re.jl`
  - `test/test_em_phylo.jl`
  - `test/test_em_squarem.jl`
  - `test/test_em_squarem_safety.jl`
  - `test/test_relaxed_clock.jl`

### Track 3: CI Keystone & Headless RCall Environment
- Dedicated GitHub Actions CI job `test-parity` configured in `.github/workflows/CI.yml`:
  - Automated detection of `libunwind.so.8` from Julia's private library directory.
  - Exported `LD_PRELOAD` prevents SIGSEGV when R loads Julia within the same process.
  - Running on PR #274 (`gh pr checks 274`).

### Track 4: StatsAPI Standard Methods & Speedup Synchronization
- Standard StatsAPI extractor methods verified on all `GllvmFit` types:
  - `coef(fit)`, `vcov(fit)`, `stderror(fit)`
  - `nobs(fit)`, `dof(fit)`, `loglikelihood(fit)`, `aic(fit)`, `bic(fit)`
  - `predict(fit)`, `residuals(fit)`, `fitted(fit)`
  - `coeftable(fit)`, `summary(fit)`
- Documented speedup claim unified to:
  > **Median 265.1× (range 161–698×) on the published Gaussian closed-form profile grid** over R/`gllvmTMB`.

### Track 5: Documenter & Vignettes Verification
- **Local Documentation Build:**
  ```sh
  julia --project=docs docs/make.jl
  ```
  - Output: Compiled successfully in 6.01s (Vitepress bundle + SSR HTML rendering).
  - Cleaned `docs/src/api.md` to qualify internal unexported functions (`GLLVM.*`), eliminating unresolved binding warnings.
- **Vignettes Validated:**
  - `docs/src/vignettes/community-abundance.md` (JSDM overdispersed counts, site covariates, ordination biplots, species correlation networks).
  - `docs/src/vignettes/phylogenetic-gllvm.md` (Phylogenetic GLLVM, $H^2$ estimation, transformed-Wald CIs, evolutionary covariance decomposition).
  - `docs/src/morphometrics.md` (Gaussian morphometrics & allometry).
- **CI Documenter Status:**
  - Workflow run `33291940784` status: **PASS** (2m33s).
  - Preview deployed to: `https://itchyshin.github.io/GLLVM.jl/previews/PR274/`.

---

## Track 6: Rose Pre-Publish Consistency Audit

| Audit Lens | Checked Artifacts | Verdict | Notes |
| :--- | :--- | :--- | :--- |
| **Speedup Claims** | `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/src/benchmarks.md` | **PASS** | Accurately scoped to Gaussian closed-form profile grid (`median 265.1× (range 161–698×)`). Non-Gaussian Laplace speedups explicitly noted as modest (~1.6×–2.2×). |
| **Response Family Surface** | `src/GLLVM.jl`, `docs/src/response-families.md`, `docs/src/api.md` | **PASS** | All 20+ response families (Poisson, NB2, NB1, Binomial, Beta, Gamma, Exponential, Ordinal, Tweedie, Student-t, Lognormal, Multinomial, Truncated Poisson, Truncated NB2, Censored Poisson, GP-1, COM-Poisson, Beta-binomial, Ordered Beta, Two-part / Hurdle / Delta, ZIP/ZINB/ZIB, VA approximations) documented with accurate status. |
| **Phylogenetic Solvers** | `src/sparse_phy.jl`, `src/phylo_contrasts.jl`, `src/edge_incidence.jl`, `src/em_phylo.jl`, `src/relaxed_clock.jl` | **PASS** | Exact mathematical equivalences across all three representations (sparse CHOLMOD, contrasts, edge-incidence) preserved. |
| **Formula & StatsAPI Syntax** | `src/formula.jl`, `src/postfit.jl`, `docs/src/working-with-a-fit.md` | **PASS** | `@formula(Y ~ X + lv(K))` and standard StatsAPI extractor signatures match documentation and test behavior. |
| **CI & Quality Gates** | `.github/workflows/CI.yml`, `docs/dev-log/check-log.md` | **PASS** | Aqua, JET, standard platform matrix (macOS, Ubuntu, Windows, Julia 1.10 & 1-latest), plus RCall parity workflow active. |

---

## Conclusion & Next Steps
- **Rose Audit Verdict: OK / SIGN-OFF GRANTED.**
- Tracks 1 through 6 are fully verified and reproducible.
- Branch `overnight-parity-closure-20260828` on PR #274 is clean, documented, and ready for maintainer review.
