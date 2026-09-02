# R-side defects and rough edges recorded by the Julia lane (frozen gllvmTMB 0.7.0) — 2026-09-02

Compiled at the gllvmTMB lane's request (session gllvmtmb-54, relaying the maintainer: *"talk to the
GLLVM.jl lane too"*; bar: *"an ecology grad student can use it first time with no holes"*). Read-only
extraction from this repo's ledgers by a Haiku scout; Ada corrected two misfilings before handing over:

- The cloglog curvature item was removed from group A — it was **our** (Julia) defect (decision round1 #2:
  Julia fell through to Fisher curvature where TMB differentiates the observed Hessian), not R's.
- Group F lists the eight acceptance failure classes learned from the **DRM.jl ↔ drmTMB** validation;
  they are standing *risk classes* for the gllvmTMB bridge, not defects measured on gllvmTMB.
- "R accepts PSD kernels; Julia enforces PD" (group A) is a cross-engine strictness divergence; which side
  is right is a decision, not an R bug.

Everything below is a lead for the R lane to verify against R `origin/main`; nothing here is a claim.


## A. R behaves differently from its docs / silently

- R accepts positive-semidefinite (PSD) kernels; Julia enforces strict positive-definite (PD) with no jitter | `formula-recognizer-spec.md:57`
- `sigma_student` unconditionally per-trait in R regardless of `df` argument (docs mention "per-trait default" but implementation always enforces per-trait) | `a6-studentt-notes.md:240-267`
- `residuals.gllvmTMB_multi()` returns 400-row data.frame with `$residual` column, not bare vector; documentation unclear | `wave7-conversion-notes.md:82-90`
- `latent(..., unique=TRUE)` auto-emits diagonal Ψ companion that R bridge **silently drops with cli_warn**, not refusal; semantic downgrade not documented | `bridge-coverage-matrix.md:51`, warning id `gllvmTMB-julia-auto-psi-dropped`

## B. R-adapter gate refuses what the R engine itself can fit

- `lognormal()` — not in `.GLLVM_JULIA_BRIDGE_FAMILIES` despite `src/families/lognormal.jl` existing natively | `bridge-coverage-matrix.md:35`
- `gengamma()` — not in bridge family list; `gengamma.jl` not found, likely absent on Julia side too | `bridge-coverage-matrix.md:36`
- `student()` — not in bridge family list despite `src/families/studentt.jl` existing (`NATIVE-10-STUDENT`, UNPAID) | `bridge-coverage-matrix.md:37`
- `tweedie()` — not in bridge family list despite `src/families/tweedie.jl` existing (`NATIVE-07-TWEEDIE`, UNPAID) | `bridge-coverage-matrix.md:38`
- `multinomial()` — not in `.GLLVM_JULIA_BRIDGE_FAMILIES` despite `src/families/multinomial.jl` existing; R itself fences most structured use via `R/multinomial-fence.R` regardless | `bridge-coverage-matrix.md:43`
- `delta_*()` (8 constructors: gamma/gengamma/lognormal/lognormal_mix/truncated_nbinom2/truncated_nbinom1/beta) — no delta/two-part entry in `.GLLVM_JULIA_BRIDGE_FAMILIES`; `src/families/twopart.jl` exists but unmapped | `bridge-coverage-matrix.md:44`
- Multiple `rr` (reduced-rank) blocks in one fit — unconditional hard gate `GJL-GATE-MULTI-RR` in `R/julia-bridge.R` | `bridge-coverage-matrix.md:52`
- `indep(..., common=TRUE)` — gate `GJL-GATE-STRUCTURED-TERMS`, documented rejection | `bridge-coverage-matrix.md:54`
- `dep()` ordinary (ORD-DEP) — **different, earlier, unlabeled failure**, not the named gate; classified as genuine adapter defect (unlabeled early stop) | `bridge-coverage-matrix.md:55`
- `phylo_*`/`animal_*`/`kernel_*` indep/common/dep modes (6 structures) — gates `GJL-GATE-STRUCTURED-TERMS` for each | `bridge-coverage-matrix.md:56-58`
- `offset()` terms (any structure + `offset()`) — hard-coded unconditional rejection in `R/julia-bridge.R` L1038-1047 | `bridge-coverage-matrix.md:end work-order`

## C. 0.7.0 ↔ 0.7.1 disagreements

- Total-variance formula: `V_t = (ΛΛᵀ)_tt + ψ_t` (0.7.0 docs) → `V_t = (ΛΛᵀ)_tt + ψ_t²` (0.7.1 bugfix); affects `profile_ci_total_variance()` derived CI | `gllvmtmb-071-gap-sheet.md:56-61`, CLASS-3-BUGFIX
- Interval-certificate claim surface rewritten: 0.7.0 claimed "0.94 coverage floor on total-variance profile" → 0.7.1 demotes profile route to "route-only penalty approximation" and certifies only 3 specific Wald cells; old cell `(n_units=150, d=1)` explicitly failed lower-band gate | `gllvmtmb-071-gap-sheet.md:52`, ~120 commits in "interval calibration" campaign
- `sigma_eps` parameterization: scalar `log_sigma_eps` → vector for Gaussian-only vs lognormal-only vs mixed-family fits; pure Gaussian (`expected_sigma_slots == 1`) unchanged, no impact on GLLVM.jl's oracle | `gllvmtmb-071-gap-sheet.md:53`

## D. R health/convergence assertions fragile on rebuilt oracle

- R's own `r_gradient_max = 0.002432304517354068` (negbin parity cell) fails 1e-4 health gate across three CI rounds; identical value across CRAN/R versions/BLAS threading — build-sensitive at these tolerances | `ci-oracle-reproducibility-finding.md`
- R's free-nu Student-t fit reports `converged = false` / `optimizer_code = 1` across CI rebuilds; same behavior on retained pinned build (18/18 pass) vs CI (16/18 pass) | `ci-oracle-reproducibility-finding.md`
- **Oracle is a specific BUILD artifact, not a version pin** (`installed_tree_sha256` differs with same source `source_tree_sha256`); R's optimizer trajectory is toolchain-sensitive at these tolerances | `ci-oracle-reproducibility-finding.md:root-cause`

## E. API-alignment collisions that are R inconsistencies

- `getREsd(fit, block=)` — R reads auxiliary RE blocks (diag_unit, phylo, re_int); Julia computes latent factor-score conditional SDs (routes to `getLV(se=TRUE)`) | **different quantity entirely** | `wave7-conversion-notes.md` tab/`api-rename-notes.md:19`
- `compare_Sigma_table(x, truth, ...)` — R compares fit vs supplied ground-truth matrix; Julia is two-fit bridge | **different signature/purpose** | `wave7-conversion-notes.md` tab/`api-rename-notes.md:20`
- `compare_dep_vs_two_psi(fit_two_psi, ...)` — R is phylo-specific one-fit-with-refit; Julia is generic two-fit bridge; no "two-ψ" model exists in Julia | **different model class** | `wave7-conversion-notes.md` tab/`api-rename-notes.md:21`
- `diagnostic_table(x, table=)` — R requires `x` to carry pre-attached `gllvmTMB_diagnostic` metadata (from `predictive_check()`/`residuals()`); Julia computes on raw fit | **different call shape** | `wave7-conversion-notes.md` tab/`api-rename-notes.md:23`
- `compare_loadings(Λ_a, Λ_b)` — R uses Procrustes frobenius; Julia uses tcrossprod frobenius on two fits; quantities not cross-comparable but each engine's self-pair must report ~0 | `wave7-conversion-notes.md` tab/`api-rename-notes.md` (not renamed, own-consistency resolvable)
- `fitted.gllvmTMB_multi()` / `predict.gllvmTMB_multi()` — R returns data.frame with `est` column and row order matching fit's data; Julia returns matrix; undocumented shape difference | `wave7-conversion-notes.md` lines 79-90

## F. R-side acceptance classes (DRM bridge validation lessons)

- Non-interactive session gate: CRAN-check safety gate blocked `Rscript` batch execution; undocumented opt-out variable required | `real-workflow-acceptance-lessons.md` class 1
- Data-shape strictness: Julia requires strictly binary phylogeny; real trees carry ~200 polytomies; user required undocumented `multi2di + epsilon` preprocessing | `real-workflow-acceptance-lessons.md` class 2
- String/serialization fragility: species/site names with spaces broke bridge; no round-trip guarantee for unicode/R-syntactic-invalid identifiers | `real-workflow-acceptance-lessons.md` class 3
- Coefficient-name translation: transformed terms (e.g. `I(temp_z^2)`) returned bridge names needing manual R-side matching; documented mapping absent | `real-workflow-acceptance-lessons.md` class 4
- Optimizer/control asymmetry: TMB `robust` preset had no documented Julia-bridge equivalent; formal comparisons carried uncontrolled difference | `real-workflow-acceptance-lessons.md` class 5
- Diagnostics not exposed: R's gradient (convergence health) not returned through bridge; GLLVM.jl's own `public_r_bridge.gradient_max = null` confirms gap | `real-workflow-acceptance-lessons.md` class 6
- Computational-feasibility cliffs: whole-tree Profile CI through bridge ran >2h vs TMB completion; claimed capability impractical at production scale | `real-workflow-acceptance-lessons.md` class 7
- Wrong claimed limits: documented size/shape limits carry no measurement receipt; overstated limits steer users away, understated ones break them | `real-workflow-acceptance-lessons.md` class 8

## Summary counts

- **A (silent behavior):** 5
- **B (adapter gate):** 10
- **C (0.7.0 vs 0.7.1):** 3
- **D (fragile oracle health):** 3
- **E (API collisions that are R inconsistencies):** 6
- **F (R-side ACC classes):** 8

**Total: 35 findings**

---

## Three most user-facing for an ecology grad student

1. **Offset terms rejected unconditionally** (F/B): `offset()` in any formula causes bridge failure with no fallback path; major regression from base R. Users working with exposure covariates, sampling effort, or habitat area-scaling have no Julia-bridge alternative. | `bridge-coverage-matrix.md`, hard gate in `R/julia-bridge.jl` L1038-1047

2. **Polytomous phylogenies require undocumented preprocessing** (F): real phylogenetic data carry polytomies; Julia-bridge requires manual `multi2di()` + epsilon conversion with no warning or clear documentation. Ecological datasets involving inferred phylogenies almost always contain unresolved nodes. | `real-workflow-acceptance-lessons.md` class 2

3. **Student-t family unavailable through bridge** (B, E): Student-t is not exported in `.GLLVM_JULIA_BRIDGE_FAMILIES`, only Gaussian; ecology often uses Student-t for heavy-tailed trait variation (arthropod body-size, wing asymmetry). Workaround requires returning to base TMB engine. | `bridge-coverage-matrix.md:37`
