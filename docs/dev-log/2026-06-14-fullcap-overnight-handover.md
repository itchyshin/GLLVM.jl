# HANDOVER — full-capability overnight build (2026-06-14)

A fresh thread reads **this file + the repo state** and continues cleanly. All
work is on branch `full-capability` (worktree
`/Users/z3437171/Dropbox/Github Local/GLLVM.jl-fullcap`), **pushed**, open as
**[PR #100](https://github.com/itchyshin/GLLVM.jl/pull/100)** (base `integration`).
**Nothing merged; nothing irreversible done** — the no-push-to-release rule held.

## Mission

Take GLLVM.jl to **full capability** on four tracks the maintainer asked for:

1. **T1 — missing RESPONSES** (NA in Y), all families
2. **T2 — missing PREDICTORS** (`mi()`) for NB / Gamma / Beta (was canonical-only)
3. **T3 — MULTIPLE missing predictors**, jointly integrated
4. **T4 — CROSS-FAMILY (non-Gaussian) coevolution** (`K*` as the latent prior)

**All four are built, verified on Julia 1.10 AND 1.12, and pushed.**

## Exact state

| | |
|---|---|
| Branch / worktree | `full-capability` @ `e6e8f6f` — `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-fullcap` |
| Based on | `origin/integration` @ `9e02c93` (post-#99 merge) |
| PR | #100 → `integration` (WIP, awaiting maintainer review). |
| Julia | local default **1.10.0**; CI primary **1.12.6** — both installed via juliaup. Verify on 1.12 with `~/.juliaup/bin/julia +1.12 --project=. test/<f>.jl`. |

### Commits (5)
```
e6e8f6f feat(coevolution): cross-family (non-Gaussian) coevolution via K* Laplace (T4)
0d26398 feat(mi): multiple missing predictors, jointly integrated (T3)
a24d443 feat(mi): missing-predictor mi() for NB / Gamma / Beta (T2)
9e3a79e test(twolevel): robust MC-recovery tolerances across Julia versions
1884b41 feat(laplace): masked analytic gradient for missing responses (T1 fast path)
```

## What was delivered, per track (with verification)

### T1 — missing responses (`1884b41`)
The per-observation NA mask **already existed** through the shared dense-Laplace
path for all six per-site families + Ordinal (`src/families/laplace.jl`,
`test_missing_data.jl`). The gap was the **fast analytic gradient**: masked fits
fell back to finite differences. Added the mask to the analytic gradients in
`src/laplace_grad.jl`. New `test/test_missing_response.jl` (23/23): independent-
oracle contract (masked marginal == hand-dropped-rows marginal), Poisson+Binomial
recovery, **AD-vs-FD ≤ 1e-6** (poisson 5.4e-8, binomial 2.4e-8). Full suite on
1.10: **3517 / 0 / 3-broken**.

### T2 — `mi()` for NB / Gamma / Beta (`a24d443`)
Extended the augmented-(z,x) missing-predictor Laplace from canonical-only to the
dispersion families (`src/missing_predictor_poisson.jl`: per-family `_xs_glm` with
the observed-vs-Fisher weight split, dispersion-aware kernels, ForwardDiff primal
helpers). `test/test_missing_predictor_dispersion.jl`: **NB/Gamma/Beta 5/5 each on
both Julia versions** — 2-D Gauss–Hermite quadrature oracle (90 nodes), AD-vs-FD
< 1e-6, MAR recovery beats complete-case. Canonical Poisson/Binomial mi unchanged.

### T3 — multiple missing predictors (`0d26398`)
New `src/missing_predictor_multi.jl` (`fit_gllvm_mi_multi`, exported): vector
`x_s ∈ R^q`, predictor model `x_s ~ N(μ, Σ_x)` (`Σ_x = Lx Lxᵀ` in θ), observed
coords conditioned on, missing subset integrated jointly with z via a
`(K + #missing)` bordered Laplace. `test/test_missing_predictor_multi.jl`: **7/7
on both versions** — q=1 reduces to the scalar path EXACTLY (|diff|=0), Gaussian ==
brute-force FIML EXACTLY, AD-vs-FD ~1.2e-7, q=2 marginal == 3-D GH quadrature
(rel 1e-4), MAR recovery with correlated predictors. 5 existing mi suites green.
**Deviation:** the Gaussian path is a self-contained closed form verified against
brute-force FIML (not wired into `missing_predictor_fiml.jl`'s Z-axis, which is a
different construct and was left untouched).

### T4 — cross-family (non-Gaussian) coevolution (`e6e8f6f`)
New `src/coevolution_glm.jl` (`fit_coevolution_glm`, `coevolution_glm_marginal_loglik`,
`CoevolutionGLMFit`, `coevolution_gamma`, all exported): `K*` as the latent prior
precision through a `phylo_glm`-style joint Laplace, reusing the family dispatch so
GLM families come through. Kronecker per-species-factor orientation; dense path;
FD-outer gradient (matches `fit_phylo_glm`). `test/test_coevolution_glm.jl`:
**14/14 on both versions.**

**⚠ Important honest finding (read this):** Gate 1 (Gaussian reduction) does **NOT**
hold to machine precision against `fit_coevolution_gaussian` — and that is correct,
not a bug. That oracle is the **matrix-normal** `K*⊗Σ_T` model whose noise
`σ²(K*⊗I)` is itself K\*-correlated, whereas any real family's noise is iid (gap
measured: 3.49 nats). The genuine machine-precision reduction (|diff|=0, since
Laplace is exact for linear-Gaussian) is against the **same-model** dense closed
form `N(0, σ²_phy K*⊗ΛΛᵀ + σ²I)`; `fit_coevolution_gaussian` is recovered only as
the `σ_fam → 0` limit (diff 1e-2 → 1e-4 → 1e-6). Documented in source + test.

Other gates: σ²_phy→0 reduces to the independent per-cell marginal (1.4e-8);
**Γ recovery — Poisson |cor|=0.981, Binomial |cor|=0.971**; block-NA Poisson runs
(|cor|=0.543, single-replicate identifiability caveat); existing coevolution +
phylo-glm suites unchanged.

**Caveats:** `σ²_phy` is fixed at 1 in the fitter (folded into Λ as a scale ridge —
the same fold the Gaussian Kronecker oracle uses; a free σ²_phy is a flat ridge
against Λ's scale). **Dense path only** — O((nd)³) per Newton step, fine for
moderate p; the large-p determinant path is future work.

## Verification basis

- Every track verified on **both Julia 1.10 and 1.12** (CI's primary is 1.12).
- Full canonical `Pkg.test()` on 1.10 (run during T4): **3605 pass / 1 broken /
  0 fail / 0 error**. A final `runtests.jl` on **1.12** was running at handover
  time — re-run `~/.juliaup/bin/julia +1.12 --project=. test/runtests.jl` to
  confirm the grand total if not already banked.
- Also fixed a **pre-existing** Julia-1.12-only CI flake: `test_twolevel`'s MC
  recovery tolerances were tighter than cross-version LAPACK scatter (estimates
  were accurate to ~3.6%). `9e3a79e` raises nrep 10→30 and widens the smoke-test
  atols (with rationale). **75/75 on both 1.10 and 1.12.** This is why
  `integration`'s own CI was red on 1.12; the fix rides in via #100.

## Maintainer-gated finish line (NOT done overnight — your call)

1. **Review + merge PR #100** (`full-capability` → `integration`). The big new
   statistical code (esp. T4) deserves your eyes.
2. **CI note:** GLLVM.jl's Julia test **matrix only runs on `main`-targeted PRs**,
   so #100 (→ integration) only ran **Documenter** on CI. The local 1.10+1.12
   verification above is the gate; the full 3-OS matrix runs when integration→main.
3. **`integration` → `main`** (PR #95, still draft/UNSTABLE independently) — the
   `test_twolevel` fix in #100 unblocks the 1.12 failure once merged.
4. **Version bump** (`0.1.0 → next`) + `[compat]` refresh (ForwardDiff→1).
5. **Tag** + **Julia General registry PR** (public/irreversible).
6. **gllvmTMB → CRAN**: final `rcmdcheck(args="--as-cran")`, **sanity-check the
   Felsenstein DOI correction** (flagged earlier), then submit.

## Follow-ons (autonomous, lower priority)

- Large-p determinant path for T4 (dense O((nd)³) → sparse/low-rank K*).
- Free `σ²_phy` in T4 (currently a folded scale ridge).
- T2/T3 dispersion families exercised mainly via the Poisson headline + q=1-exact
  reduction; could add per-family multi-predictor gates.
- Export + document the older coevolution/mi internals (still `GLLVM.`-qualified).

## Disciplines (carried throughout)

Stage by name (never `git add -A`); one concern per commit; **no push to release /
no merge / no tag / no registry / no CRAN without explicit maintainer go-ahead**;
verify before claiming (every number above was re-run locally, not taken from the
build agents' self-reports); honest reporting (see the T4 Gaussian-reduction note).
Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

## Anchors

`docs/dev-log/2026-06-13-HANDOVER-resume-here.md` (prior session, on `integration`).
Key source: `src/{laplace_grad, missing_predictor_poisson, missing_predictor_multi,
coevolution_glm, phylo_glm, cross_kernel, extract_gamma}.jl`. Tests:
`test/test_{missing_response, missing_predictor_dispersion, missing_predictor_multi,
coevolution_glm, twolevel}.jl`.
