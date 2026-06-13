# Finish-line definition of done — GLLVM.jl (registry) + gllvmTMB (CRAN)

Living checklist for finishing the twin pair. Honest scope: this is **weeks of focused
work**, not a session — breadth + integration + proof + docs, not "wire a few features".
GPU is explicitly **post-release (v2)**; CPU only for the finish line. Last updated 2026-06-12.

## DONE + verified (committed, gate-checked)
- **Canonical JuliaCall bridge** on main v0.3.0 (`bridge_fit`, 8 one-part families) — TMB↔Julia loglik 3.91e-12.
- **Cross-family VCV**: single-family (a1-parity 6e-8/2e-8) + **mixed-family** (`fit_mixed_gllvm`, bit-for-bit a1-parity; bridge mixed path end-to-end).
- **Gaussian REML** + bridge wiring (`bridge_fit(reml=true)` → `engine="julia",REML=TRUE`) — a1-parity bit-for-bit.
- **χ̄² boundary inference** (chibar2 / variance_lrt / profile_ci_variance).
- **Gaussian random slopes** (correlated Σ_b, q≥1) — 12/12.
- **Taxonomy**: `latent(specific=)` ≡ `latent+unique` (bit-for-bit) + `unique()` deprecation message (one-shot).
- **gllvmTMB `engine="julia"`** PR #473 — R-CMD-check CI green.
- **Integration**: bridge+VCV+boundary+REML+mixed+slopes merged into one tree, loads + smokes OK (full `Pkg.test()` gate running).

## P0 — Integrate + green (the elephant)
- [~] Merge GLLVM.jl feature branches into one tree — DONE (smoke OK); **full `Pkg.test()` (Aqua/JET + all suites) green — IN PROGRESS**.
- [ ] Merge plotting (`viz-plots`) in additively once it lands.
- [ ] Wire tests for the salvaged features (VCV / REML / boundary / mixed) into `runtests.jl` (currently parity-gated, not in-suite).
- [ ] gllvmTMB: merge `engine-julia` + `deprecate-unique`; full `R CMD check --as-cran` green.

## P1 — Core capability completeness
- [ ] **Two-level (between/within-individual) inference** — communality + **repeatability** + both-level correlation matrices (the behavioural-syndromes paper's headline; not yet built).
- [ ] **VA/EVA completeness** — extend to all families (ordinal, two-part, Tweedie?), verify vs Laplace, SEs everywhere.
- [ ] **Ordination uncertainty** — CIs/procrustes on scores; residual ordination; verify constrained/concurrent/quadratic.
- [ ] Non-Gaussian random slopes (q≥2) — stage 2 of the slopes track.
- [ ] Uniform inference across fit types (profile/bootstrap/variance-partition/prediction-intervals).
- [ ] gllvmTMB: deprecation `man/` badges + backward-compat test; blocked-family lift decision (mixture/gengamma, delta/hurdle).

## P2 — Structured dependence + bridge breadth + missing data
- [ ] Structured RE coverage: animal/pedigree, AR1/temporal, correlated LVs (phylo + SPDE present).
- [ ] **Bridge expansion**: expose Gaussian Xβ, structured/grouped/phylo/spatial RE, random slopes, ordination types, NA/unbalanced through `engine="julia"` (currently only ordination + correlation core + REML).
- [ ] Missing-data NA-FIML completeness on main.

## P3 — Speed headline + validation (CPU)
- [ ] **ASReml-beating REML** (#40): analytic Takahashi REML gradient + AI-REML Fisher scoring; benchmark vs ASReml-R (measured, never claimed). Design panel in flight.
- [ ] ADEMP recovery: cross-family correlation (exact-vs-approximate caveat), RE-variance, ordination.
- [ ] Hermetic gllvmTMB↔GLLVM.jl parity harness across the feature set.
- [ ] Honest benchmarks vs gllvm 2.0 / sjSDM (CPU).

## P4 — Release mechanics + docs + papers
- [ ] GLLVM.jl: Project.toml [compat] for all deps+julia, Aqua/JET in-suite, CI, Documenter site, version, registry submission.
- [ ] gllvmTMB: `--as-cran` clean, `\value`/examples in every `.Rd`, vignettes, cran-comments, power/coverage calibration study, pkgdown (maintainer lane).
- [ ] Cross-package **consistency**: identical covariance grammar (latent/specific/indep/dep) across R + Julia engine + bridge contract.
- [ ] Polish: S3/print/summary, fit serialization, error messages, threading, reproducibility.
- [ ] The two companion papers' analyses fully runnable on the shipped software.

## Cross-cutting risks
- Clean git-merges ≠ loads (the integration gate caught a real env issue) — always run the full suite on the merged tree.
- The covariance grammar is formal in R (gllvmTMB) but fit-function-based in Julia — aligning the vocabulary + the bridge contract is real work, not cosmetic.
