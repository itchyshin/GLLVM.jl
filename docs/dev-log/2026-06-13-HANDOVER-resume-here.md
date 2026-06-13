# HANDOVER — resume here (2026-06-13)

A fresh thread reads **this file + the repo state** and continues cleanly.
Nothing is lost by restarting. Two packages were advanced to feature-complete,
verified, deployment-ready states on local branches; **nothing is pushed** (the
maintainer's no-push rule held throughout).

## UPDATE (2026-06-13, post-push — deployment authorized by the maintainer)

The branches below are now **PUSHED** with PRs open (the maintainer explicitly
authorized the push, overriding the no-push rule):

- **GLLVM.jl** `coevolution-kernel` → `origin`; **PR #99** (base `integration`):
  https://github.com/itchyshin/GLLVM.jl/pull/99
  CI: the **Documenter** check FAILED — but it was **already red on `main`
  (9406e22)** before this branch (a pre-existing dead `@ref` to `_code_grouping`
  in `src/families/random_slopes.jl:66`, surfaced in `docs/src/api.md`'s
  `@autodocs`). This branch ALSO adds one new doctest issue to fix (see TODO).
  GLLVM.jl PRs don't run the Julia test suite on CI — the local 3479/0 +
  per-slice greens are the gate.
- **gllvmTMB** `cran-bridge-docs` → `origin`; **PR #487** (base `main`):
  https://github.com/itchyshin/gllvmTMB/pull/487
  CI: **ubuntu-latest R-CMD-check PASSED** ✅.

**STILL HELD (need a separate maintainer go-ahead):** CRAN submission and the
Julia General registry PR (public/irreversible).

**Small open TODO (my doc cleanup for PR #99 — not yet done):** in
`src/cross_kernel.jl` change the `jldoctest` block (lines ~48-59) to a plain
` ```julia ` block (the repo has no `DocTestSetup`, so `make_cross_kernel` is
undefined in the doctest's `Main`); and neutralise the 4 new `@ref`s to undocumented
new functions (`src/{cross_kernel,extract_gamma,coevolution_kronecker,missing_predictor_poisson}.jl`)
→ plain code style. That removes THIS branch's contribution to the Documenter
failure; the pre-existing `_code_grouping` dead link is the maintainer's to fix
(it's red on `main` independently). Net: cosmetic docstring edits, no code change.

## TL;DR

- **GLLVM.jl** (Julia): cross-lineage coevolution ("PGLLVM two lineages") and the
  missing-predictor `mi()` axis were implemented end-to-end and verified.
  Branch `coevolution-kernel`, **21 commits**, tree clean, unpushed.
- **gllvmTMB** (R): the two CRAN gating items (PDF-manual Unicode + invalid DOIs)
  were fixed and verified. Branch `cran-bridge-docs`, **6 commits**, tree clean,
  unpushed. CRAN submit-ready bar the maintainer's final `--as-cran` + submit.
- The remaining work to literally "finish" is **maintainer-gated** (push, merge,
  tag, Julia-registry, CRAN submit) — an agent cannot do it under the no-push rule.

## Exact state (verified from the repos)

### GLLVM.jl
| | |
|---|---|
| Work branch / worktree | `coevolution-kernel` @ `9deecad` — `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-coevolution` |
| Based on | `consolidation-candidate` @ `8690e8f` (tracks `origin/integration`; the PR #95 trunk) |
| Ahead by | 21 commits, **unpushed**, tree clean |
| Main checkout | `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on `codex/non-gaussian-fitter-gradients` @ `6d8e158`; `main` = `9406e22` |
| Julia binary | `~/.juliaup/bin/julia` (not on PATH) |
| Run a focused test | `~/.juliaup/bin/julia --project=<worktree> <worktree>/test/test_X.jl` |

### gllvmTMB (R) — "work on both" override is in effect (its CLAUDE.md read-only note is superseded)
| | |
|---|---|
| CRAN branch / worktree | `cran-bridge-docs` @ `c1dfb3e` — `/Users/z3437171/gllvm-cranbridge` |
| Ahead by | 6 commits over `origin/main`, **unpushed**, tree clean |
| Main checkout | `/Users/z3437171/Dropbox/Github Local/gllvmTMB` on `engine-julia` |

### Environment caveat
The maintainer's **power-pilot simulation** (`dev/m3-pilot-local-loop.R`, ~10
PSOCK workers) is still running and pins most cores — it **starved the last full
`runtests.jl`** (killed by SIGTERM at `test_zero_inflated.jl`, an existing test,
NOT a failure of new code). Re-run the full suite when the machine is freer.

## What was delivered (GLLVM.jl, all TDD)

New files: `src/{cross_kernel, extract_gamma, coevolution_kronecker,
coevolution_blockna, missing_predictor_fiml, missing_predictor_phylo,
missing_predictor_poisson}.jl` (+ includes/exports in `src/GLLVM.jl`); tests
`test/test_{cross_kernel, extract_gamma, cross_kernel_fit, coevolution_kronecker,
coevolution_blockna, missing_predictor_fiml, missing_predictor_phylo,
missing_predictor_z, missing_predictor_poisson, mi_fitter}.jl` (wired into
`test/runtests.jl`).

**Cross-lineage coevolution — COMPLETE**
- `make_cross_kernel(A_H, A_P, W; rho)` → K* = [A_H, C_HP; C_HPᵀ, A_P]. Byte-identical to the R twin (`max|K_jl−K_R| = 5.6e-17`).
- `extract_Gamma(fit; row_traits, col_traits)` → Γ = (Λ_phy Λ_phyᵀ)[host,partner].
- Hadamard fit-contrast (`test_cross_kernel_fit.jl`): K* beats the block-diagonal null. (Engine note: GLLVM.jl's phylo marginal is Hadamard single-realisation, so this path can't recover Γ tightly — that's why the Kronecker fitters below exist.)
- `fit_coevolution_gaussian(Y, K_star; d)` — **faithful** matrix-normal (Kronecker) recovery: `Y (T×n) ~ MN(0, ΛΛᵀ+σ²I, K*)`, recovers Γ to **|cor|>0.9**. Eigentrick marginal validated to 1.1e-14.
- `fit_coevolution_blockna(Y_HH, Y_PP, A_H, A_P, K_HP; d)` — the realistic data structure (each lineage measures only its own traits). M = 2×2 block-of-Kroneckers, verified == selection from full K*⊗Σ_T (to 0). **Caveat:** block-NA Γ identifiability is limited (single shared W = one replicate, Boettiger 2012); recovery *scales with association strength* (probed median |cor| 0.50 at ρ=0.5/n=20 → 0.96 at ρ=0.9/n=60).

**Missing-predictor `mi()` axis — COMPLETE for the tractable scope**
- `fit_gaussian_mi_fiml(y, x; K, Z=nothing)` — site-level continuous predictor, closed-form FIML (Phase 2a); optional `Z` covariate-model `x ~ N(μ_x+Zγ, σ_x²)`. Beats complete-case under MAR.
- `fit_gaussian_mi_phylo(y, x, A; K)` — species-level predictor with a phylo prior `x ~ N(α1, σ_x²A)` (Phase 3, the high-value evolutionary case). Marginal validated vs brute-force to 3.6e-15.
- `fit_gllvm_mi(family, Y, x; K, N)` — **non-Gaussian** (Poisson/Binomial) via an augmented (z,x) Laplace (Phase 5a). Each verified against 3 oracles (complete-data equivalence, 2-D Gauss-Hermite quadrature, AD-vs-FD ≤1e-6). Recovers b_x; beats complete-case under MAR.

**Verification:** an earlier full `runtests.jl` passed **3479 / 0 fail** (covering
most new work). Every slice is green individually and in combined runs: **~71
tests fast / 77 with `GLLVM_SLOW_TESTS=1`**. All marginals AD-clean ≤1.7e-7. The
*latest* full re-run (covering block-NA + Binomial-mi + the fitter together) was
SIGTERM-killed by the power-pilot, so the grand-total combined number is the one
thing not yet confirmed — re-run `~/.juliaup/bin/julia --project=. test/runtests.jl`.

## What was delivered (gllvmTMB)

- PDF-manual Unicode (#486) — fixed (`93640b7`); `R CMD Rd2pdf` builds the
  145-page manual clean (no inputenc/LaTeX errors).
- DOI notes (`c1dfb3e`), all checked vs doi.org/CrossRef:
  - bioRxiv DOI `10.1101/2025.12.20.695312` → **`10.64898/2025.12.20.695312`** (the 10.1101 prefix 404s; the new prefix resolves).
  - Felsenstein (2005) reference **corrected** to *Phil. Trans. R. Soc. B* **360**:1427-1434, `10.1098/rstb.2005.1669` — the cited `Genetics 169:925-942 / 10.1534/genetics.104.025262` is the wrong journal AND a non-resolving DOI. **⚠ Maintainer: please sanity-check this citation correction.**
  - 3 `\url{https://doi.org/...}` → `\doi{}` in `diag_re.Rd` / `spde.Rd`.
- `cran-comments.md` updated. State: 0 errors, 1 environmental install-warning, "New submission" note + a tolerated NEWS.md note.

## Key findings / decisions banked

1. **The plan was stale on coevolution:** gllvmTMB ships C0–C3 of the kernel
   coevolution on `origin/main` already; GLLVM.jl was the green-field. So the
   Julia mirror *was* the recorded next step.
2. **Hadamard vs Kronecker:** GLLVM.jl's existing phylo marginal is a Hadamard
   single-index form, which can't recover R-style trait⊗species Γ — hence the new
   standalone Kronecker fitters (`fit_coevolution_gaussian` / `_blockna`).
3. Block-NA + dense-Σ_phy is NOT supported by the in-place Gaussian/mixed fitters
   — the coevolution fitters are standalone (no surgery to `fit_gaussian_gllvm`).

## Maintainer-gated finish line (cannot be done by an agent)

- **GLLVM.jl:** push `coevolution-kernel`; reconcile/merge into the trunk + `main`
  (note open PR #95 = the consolidation hub); tag; Julia General registry PR.
- **gllvmTMB:** final `rcmdcheck(args="--as-cran")` (machine freer); confirm the
  Felsenstein DOI fix; CRAN submit; decide reorganise-vs-accept on the NEWS note.

## Remaining autonomous follow-ons (lower priority)

- Non-canonical mi families (NB / Gamma / Beta) — need the observed-weight implicit
  step (see `src/laplace_grad.jl` for the per-family pattern). Canonical
  Poisson/Binomial are done.
- block-NA Schur/Woodbury fast path (current fit is a direct O(dim³) cholesky).
- Executed-`@example` docs / tutorials for the new functions.
- (Out of scope: categorical/count *missing predictors* — gllvmTMB rejects them too.)

## Disciplines (carry forward)

Stage by name (never `git add -A`); one concern per commit; **no push without an
explicit maintainer instruction** (both repos); verify before claiming (paste the
real tally). Commit trailer used in both repos:
`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

## Anchors (deeper detail)

`docs/dev-log/2026-06-13-{coevolution-mirror-jl, coevolution-kronecker-design,
mi-predictor-fiml-jl, nongaussian-mi-design, session-handover-coevolution-mi}.md`
and `after-task/2026-06-13-coevolution-mirror-c0c2.md`. R reference for the
coevolution math: `gllvmTMB/R/kernel-helpers.R`, `R/extract-sigma.R`,
`docs/design/65-cross-lineage-coevolution-kernel.md`.
