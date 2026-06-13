# Correctness code-review of GLLVM.jl — companion to the audit

**Date:** 2026-06-12 · **Reviewer:** Claude (gllvmTMB thread), 2 adversarial
correctness agents · **Read-only.** Companion to
`2026-06-12-gllvmTMB-thread-audit.md` (that one is quality/structure; this one is
**correctness only** — actual bugs and example runnability). Untracked handoff.

## 1. Engine math — VERIFIED CLEAN (the headline)

An adversarial bug-hunt over the math-heavy engine — `likelihood.jl`,
`sparse_phy_grad.jl`, `node_gradient.jl`, `takahashi_selinv.jl`,
`families/laplace.jl`, `packing.jl`, `lowrank_cholesky.jl`, and every family
fitter — looking for sign/index/transpose/parameterisation/edge-case bugs. The
reviewer didn't just read; it **numerically verified** the suspect derivations
(ForwardDiff, brute-force `(p·n)`-dim MvNormal logpdf, exact truncated-distribution
moments) and re-ran the repo's own gradient gates on this checkout.

**Result: zero confirmed bugs, zero surviving suspects.** Specifically verified
correct (with evidence):

- **Gaussian marginal** (`likelihood.jl`): exact vs brute-force MvNormal logpdf to
  ≤3e-16 across J1 / J2 (W-tier + per-trait diag REs) / J3 (phylo), with and
  without fixed effects, and the degenerate cases **K=1, p=1, n=1**. Woodbury
  Σ⁻¹/logdet (185–205) and the rotation-trick identities (232–248) are correct;
  the un-guarded `cholesky` at line 234 is provably SPD on any real parameter path
  (Schur product theorem), so it is not a latent bug.
- **Family aux derivatives** (`families/laplace.jl`): `s, qaux, sη, saux, Wη, Waux`
  match ForwardDiff to ≤2e-14 for Beta (trigamma/polygamma) and NB2; Gamma by
  hand; binomial/poisson canonical weights correct for any link.
- **Two-part** (`families/twopart.jl`): hurdle-Poisson and hurdle-NB working
  variances equal the exact zero-truncated moments (≤1.6e-14); presence×positive
  assembly correct.
- **Ordinal** (`families/ordinal.jl`): score and Fisher weight are the true
  derivative / observed information; cutpoints stay ordered by construction.
- **Analytic phylo gradients**: the repo's gates pass on this checkout —
  `sparse_phy_grad` 36/36 (≤1e-11), `node_gradient` 58/58 (≤1e-13, balanced +
  caterpillar), `takahashi_selinv` 8/8 (≤1e-14). The two opposite sign conventions
  are internally consistent and both FD-verified. The reviewer added **K=2** FD
  checks the suite omitted (Poisson/Binomial canonical, NB aux) — all agree ~1e-8.

**One caveat:** the `structured_schur.jl` / `families/structured_poisson.jl` Schur
adjoint was confirmed only via its 85 passing tests, not independently re-derived
(it's an unexported prototype).

**Why this matters:** it substantiates the engine's correctness *independently of*
the weak R-parity tests flagged in the audit. The math is right; what's missing is
the *parity evidence layer*, not parity itself.

## 2. Documentation example runnability — 3 FAIL, 4 SUSPECT of 43 blocks

Systematic check of every code example (37 in `docs/src/*.md` + 6 in `src/*.jl`
docstrings) against the real API. **39 of 43 PASS.** The failures share one root
cause: **a fit object stores no data**, so the extractors need the response matrix
passed back in. `working-with-a-fit.md` does this correctly everywhere;
`quickstart.md §4` and `response-families.md "Extractors"` do not.

| page:line | example | verdict | fix |
|---|---|---|---|
| `quickstart.md:71` | `confint(fit)` | **FAIL** — `confint` requires `y` (`confint.jl:245`) | `confint(fit; y = y)` |
| `quickstart.md:72` | `profile_ci(fit, "sigma_eps")` | **FAIL** — requires `y` (`confint_profile.jl:476`); the name itself is valid | `profile_ci(fit, "sigma_eps"; y = y)` |
| `response-families.md:193` | `getLV(fit)` | **FAIL** — no zero-arg method; all `getLV(fit, Y)` require the matrix | `getLV(fit, Y)` |
| `response-families.md:191-192` | `communality(fit)` / `correlation(fit)` | **FAIL in context** — the in-scope `fit` is a `GammaFit`; these are `GllvmFit`-only (`confint_derived.jl:186,203,275`), and the page's own prose (line 187) says "Gaussian-only" | precede with a Gaussian `fit`, or split the block |
| `working-with-a-fit.md:94` | `fit_gllvm(Yb; …)` | SUSPECT — `Yb` undefined placeholder (must be an integer 0/1 matrix) | define `Yb`, or label as illustrative |
| `structured-dependence.md:76` | prose `sigma_phy_dense(...)` | SUSPECT — exists but not exported (`sparse_phy.jl:370`) | `GLLVM.sigma_phy_dense(...)` |
| `index.md:53` | prose `getLV(fit)` | SUSPECT — same missing-`Y` pattern | `getLV(fit, Y)` |

## 3. Meta-finding — CI cannot catch any of §2

The docs use **MarkdownVitepress** with **zero** `@example` / `@repl` / `jldoctest`
blocks — every ```julia block is **static** (not executed at doc-build). So a
broken example never fails CI; it only fails for the reader who copy-pastes it.
**Recommendation:** convert the headline tutorial paths (quickstart, morphometrics,
working-with-a-fit) to executed `@example` blocks, or add a doctest pass, so this
entire class of bug is caught automatically. This is the single highest-leverage
fix — it would have caught all three FAILs above.
