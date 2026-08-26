# GLLVM.jl release audit — synthesis of five independent lenses

Date: 2026-08-24. Sources: lens api (public API completeness), lens ledger (capability-status honesty), lens claims (user-facing claim honesty), lens release (release mechanics), lens coverage (shipped-but-untested). All findings are static; no Julia or R was run.

---

## 1. Can this package be released today?

**No.**

Single strongest reason: releasing today would publish user-facing numeric claims that the repository's own measurements contradict — "machine precision" agreement with gllvmTMB against a measured worst-case |Δ logLik| of 2.343e-07, a "~340×" headline fenced to a phylogenetic path for which no R-vs-Julia timing exists anywhere, and README agreement bounds (1e-7 / 1e-5) that the repo's own benchmark table exceeds by 2.3× and 4.4×. The mechanical state seconds the verdict: the release branch is 35 commits ahead of origin/main with two files uncommitted, and no version of this package has ever actually been tagged, released, or registered.

---

## 2. Hard blockers, ordered

Ruthlessly filtered: each item below either ships a false statement to users, ships a just-changed numerical default with no executing verification, or makes the mechanical act of releasing impossible. Everything else — docstring gaps, `warnonly`, dead exports like `fit_beta_gllvm_va`, tarball bloat, ForwardDiff 0.10 pin, the missing docs badge — is should-fix and listed in §5, not here.

**B1. The lane is unlanded.**
`git status` shows `M src/families/truncated_nbinom2.jl` and `M test/test_gamma_curvature_cross_kernel.jl` uncommitted; the branch is 35 commits ahead of origin/main.
*Clear when:* the two files are committed or reverted, the branch is merged to main, and CI is green at the merge SHA.

**B2. User-facing claims contradicted by the repo's own evidence.**
Four specific falsehoods or unfenced claims across README.md, docs/src/index.md, docs/src/gllvmtmb-parity.md, docs/src/benchmarks.md, docs/src/comparison.md:
(a) "machine precision" vs gllvmTMB (gllvmtmb-parity.md:4,73-74; changelog.md:120-121) — measured agreement is six significant digits (2.343e-07 logLik, 4.424e-05 Σ_y rel-Frobenius);
(b) ~340× fenced to "Gaussian + phylogenetic" (gllvmtmb-parity.md:73, index.md:93-95) — no R-vs-Julia phylogenetic timing exists; the grid is six all-Gaussian cells, and the benchmark compares Julia's shared-σ path against a non-default R configuration, stated nowhere near the number;
(c) README:33-36 "identical answers (matched to 1e-7 ... 1e-5)" — both bounds exceeded by the repo's own table;
(d) the internally documented "does not generalise" caveat (Gamma ≈1.6×, truncated Poisson ≈2.2× vs ≈1280× lognormal) appears in zero user-facing pages while the speed claim sits directly above a ~20-family feature list.
Also under this blocker: no standing parity check exists (test/parity/ is gated by GLLVM_PARITY_TESTS=1 which nothing sets), so any "verified twin" claim must be either downgraded or backed by one recorded manual parity run at the release SHA.
*Clear when:* the five pages state the measured numbers with correct fences (benchmarks.md:43-44 is the model sentence), one speed number with one source replaces the current four, the non-Gaussian and CI-coverage caveats reach README/pitfalls, and the parity claim is either fenced to the ~10 covered families with a recorded run or dropped.

**B3. The Gamma curvature default flip is unverified on both phylogenetic Gamma kernels.**
The just-flipped `hessian` default changes reported loglik and Wald SEs. src/phylo_glm.jl:101-107 states the two phylo Gamma kernels "must take the SAME curvature" and names test/test_phylo_gamma_xlv.jl:116 as the pin — but that test is deliberately excluded from runtests.jl because its in-file oracle still computes the Fisher log-det, and the wired phylo test exercises Poisson only. The one place the coupling constraint is written as an assertion is inert.
*Clear when:* the oracle in test/test_phylo_gamma_xlv.jl is updated (by someone other than the author of the flip, per runtests.jl's own note), the file is wired into runtests.jl, and the suite passes.

**B4. Version and changelog bookkeeping owed before any tag.**
Project.toml says 0.3.0, equal to the newest released CHANGELOG heading, but Unreleased carries a user-facing numerical change (the Gamma curvature flip) and a new export (`confint_lv_effects`) — 0.x SemVer forces 0.4.0. Separately, docs/src/changelog.md (the page users read) never received the v0.3.0 cut and mentions neither the Gamma flip nor the Tweedie converged-flag fixes: two changelogs disagreeing over a change that moves reported likelihoods, a cascade blocker under AGENTS.md rule 3.
*Clear when:* Project.toml is bumped, both changelogs agree, and the Gamma numerical change is stated in the user-facing one.

**B5. The Laplace curvature fault class is undisclosed where users and the ledger would look.**
docs/design/capability-status.md contains no row, fence line, or deferred entry for the 13-instance Fisher-vs-observed class, while certifying "ML default", "Wald intervals", and the affected family rows as `implemented`. Six shipped families (ordinal, Tweedie, Student-t, COM-Poisson, lognormal, GP-1) expose no `hessian` selector at all — a user cannot reach TMB's objective even deliberately — plus the mixed and covariates kernels. The lane's own design doc instructs "do not let any after-task report record the class as closed."
*Clear when:* the ledger carries a curvature row or fence clause naming the selector-less families, and the user docs carry the matching support cell (gllvmtmb-parity.md:195-224 already has the honest prose — it needs to be load-bearing, not buried).

**B6. src/boundary_inference.jl ships three exported inference functions with zero tests and zero docs.**
`chibar2_pvalue`, `variance_lrt`, `profile_ci_variance` — boundary LRT and boundary-aware profile CIs are precisely where a plausible implementation is silently wrong, and nothing would notice.
*Clear when:* the three symbols are either unexported (minutes) or tested against a known χ̄² reference and documented (a day). Unexport is the release-viable path.

**B7. First-release mechanics have never been exercised and the first registered version needs a deliberate decision.**
No v* tag has ever existed (only backup/wip tags); TagBot and the Documenter tag trigger have never fired; gh-pages has only `dev`. RegistryCI AutoMerge restricts a new package's first registered version to 0.0.1, 0.1.0, or 1.0.0 — a first registration at 0.4.0 needs a manual registry-maintainer merge (verify against the live guideline before submitting).
*Clear when:* the first registered version is chosen deliberately, the tag is pushed at a CI-green SHA, and the README install block flips to `Pkg.add("GLLVM")` in the registration PR.

---

## 3. The honest release note

> GLLVM.jl v0.4.0 is a from-scratch Julia implementation of generalised linear latent variable models, built alongside R's gllvmTMB and checked against it. On a six-cell Gaussian benchmark grid (n = 20–200, p = 5–20), fits agree with gllvmTMB to at least six significant digits in log-likelihood (worst |Δ logLik| 2.3e-07; Σ_y relative Frobenius difference ≤ 4.5e-05), with a grid-wide median per-fit speedup of roughly 340×. That comparison uses Julia's closed-form shared-σ Gaussian path against a matched (non-default) R configuration; R's per-species Gaussian default has not been benchmarked head-to-head. For a full inference pipeline including confidence intervals, the median speedup across a 28-cell ADEMP simulation grid is 8.1× (IQR 5.4–29×). The per-fit headline does not generalise across families: informal small-fixture checks range from ~1000× (lognormal) down to ~2× (Gamma, truncated Poisson). The fast O(p) phylogenetic path scales to p = 10⁴ in Julia-side gradient benchmarks; no R-vs-Julia phylogenetic timing exists yet. Twenty-plus response families are implemented with single-replicate recovery tests; numerical parity with gllvmTMB is verified for about ten of them via a manually run parity suite, and should not be assumed elsewhere. Six families (ordinal, Tweedie, Student-t, COM-Poisson, lognormal, GP-1) and the mixed and covariate kernels still use the Fisher curvature in the Laplace log-determinant, so their log-likelihoods will not exactly match gllvmTMB's observed-curvature objective. Wald, profile, and bootstrap intervals are implemented; in phylogenetically active simulation cells, measured coverage for β is far below nominal in both engines (Wald 0.20, profile 0.22, bootstrap 0.61 against 0.95) — treat fixed-effect intervals in phylogenetic models with caution, and prefer the bootstrap. Monte-Carlo coverage evidence currently covers the Gaussian path and latent-loading routes for eight families; other families' interval calibration is untested.

## 4. What must NOT be claimed

- **"Machine-precision agreement with gllvmTMB."** Measured: 2.3e-07 / 4.4e-05 — nine orders of magnitude short. (The phrase is only true of the three phylogenetic representations agreeing with each other.)
- **"~340× on the phylogenetic path"** or any phylo speedup vs R. No R-vs-Julia phylogenetic timing exists in this repo or the bench repo.
- **"10–100× faster"** (README) alongside 340× elsewhere. Four numbers for one quantity; the README figure matches no table. One number, one fence, one source.
- **Speedups for non-Gaussian families by implication.** The internal record states verbatim that nothing licenses restating ~340× outside the verified Gaussian cell; Gamma measured ≈1.6×.
- **"Verified twin" / general gllvmTMB parity.** The parity suite runs nowhere automatically and covers ~10 of ~80 exported fitters.
- **"Fits p = 10,000 in sub-millisecond time."** benchmarks.md compares a Julia gradient *evaluation* to an R full *fit*; the Julia fitting path's own source says its wall-clock climbs steeply.
- **Validated confidence intervals across the family list.** One measured cell has Wald β coverage 0.20 against nominal 0.95, and ~30 shipped families have no recovery or coverage evidence at all. "A converged fit is not a validated fit" is this project's own rule.
- **Boundary inference (χ̄² tests, variance profile CIs) as a capability.** Zero tests, zero docs (unless B6 is cleared by testing rather than unexporting).
- **Universal post-fit verbs.** `predict`/`residuals`/`show` are absent on the grouped-dispersion fits that `fit_gllvm` routes NB/Beta/NB1 to by documented default; working-with-a-fit.md currently promises them universally.

## 5. Cheapest path to releasable (ordered, rough effort)

1. **Land the lane** — commit/resolve the 2 dirty files, merge 35 commits to main, confirm CI green. (hours)
2. **Claims sweep** over README, index, benchmarks, comparison, gllvmtmb-parity: six-significant-digits phrasing everywhere, one speed number with fence and source commit, add the non-Gaussian caveat and the CI-coverage caveat, fix the stale Gamma "stays conservative" paragraph, name gradient-vs-fit in the scaling section. (half a day)
3. **Fix and wire test_phylo_gamma_xlv.jl** (fresh oracle, independent author) to close the phylo Gamma curvature gap. (half a day–1 day)
4. **Unexport the three boundary_inference symbols** and mark the file experimental. (minutes)
5. **Ledger update**: curvature fence/row naming the six selector-less families; promote or re-annotate the four understated rows (mi(), none×dep, random slopes, mixed-family) and re-date the AGHQ rationale. (1–2 h)
6. **Changelog + version**: apply the v0.3.0 cut to docs/src/changelog.md, add Unreleased items including the Gamma flip, bump Project.toml to 0.4.0. (1 h)
7. **Docstring pass** (should-fix but minutes): move the orphaned bridge_fit docstring below `_bridge_lv_ci_fields`, add the 4–6 missing docstrings, set `checkdocs = :exports` and narrow `warnonly` so the rule is enforced; add a support-cell note or the missing verbs for the grouped-dispersion fits; add ZIPoisson/ZINegBin rows and export `TweedieED`. (2–3 h)
8. **One recorded verification run**: full `Pkg.test()` plus one `GLLVM_PARITY_TESTS=1` parity run at the release SHA, output stored in the after-task report. (hours, mostly wall-clock)
9. **Decide the first registered version** against the live AutoMerge new-package rule (0.1.0 / 1.0.0 / manually merged 0.4.0), add the docs badge, flip the README install block, tag, register, let TagBot fire for the first time. (decision + 1 h)

Total: roughly 3–5 focused days. Steps 2 and 3 are the substance; everything else is bookkeeping the release machinery has simply never exercised.
