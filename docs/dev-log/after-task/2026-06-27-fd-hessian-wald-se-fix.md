# After Task: fix the `2f0` Float32-literal bug in `_fd_hessian` (all Wald SEs)

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), juliaup Julia 1.10.
**Branch**: `claude/fd-hessian-wald-fix-20260627`, off `main` (`2396380`).

## 1. Severity

Every non-Gaussian **Wald** confidence interval in GLLVM.jl was wrong. This is a
shipped, exported, documented feature (`confint(fit, Y; method=:wald)`, changelog
"IN: Wald / profile / bootstrap"). Found while building Wald CIs for the `X_lv`
latent-score path; the same shared helper backs the whole family CI layer.

## 2. Root cause

`src/confint_family.jl`, `_fd_hessian` diagonal:

```julia
H[i, i] = (f(xp) - 2f0 + f(xm)) / h[i]^2
```

`2f0` is **not** `2 * f0` — Julia lexes `2f0` as the Float32 literal `2.0f0`. So
the diagonal second difference was computed as `(f(x+h) - 2.0 + f(x-h)) / h²`,
silently discarding the cached centre value `f0`. Every log-likelihood carries a
large constant (e.g. `f0 ≈ 2489` for a 5×200 Poisson), so the diagonal inflated
by ≈ `2·f0 / h² ≈ 3e11`, dominating `inv(H)` and driving all SEs to ~1e-6
(falsely certain near-point intervals).

Verified directly: `2f0 === 2.0f0` (Float32) while `2 * f0 == 2*f0`; a clean
manual central difference at the same step gives the correct curvature
(`H_alpha ≈ 82.9`, `H_Λ ≈ 1131`) where `_fd_hessian` returned `3.3e11`; the
existing `confint(poisson_fit; method=:wald)` returned `se ≈ 3e-6`, post-fix
`se ≈ 0.04–0.07`.

## 3. Scope of impact

- **Affected:** `_family_wald` for Poisson, Binomial, NB, NB1, GP1, Beta, Gamma,
  Exponential, Tweedie, BetaBinomial, RowRandom, grouped-dispersion, Ordinal,
  two-part families; `confint_spde_latent`, `confint_speciescov`,
  `confint_fourthcorner`, `confint_rrr`, `confint_constrained`; the structural /
  derived Wald tables that build on this Hessian.
- **Unaffected:** the `_fd_hessian` **off-diagonals** (no `2f0` term); the
  **profile** route (LRT-based — it only used the SEs to seed brackets, so it
  converged anyway) and the **bootstrap** route; the Gaussian Wald path
  (`confint.jl`, a separate analytic Hessian).

## 4. Fix

One line: `2f0 → 2 * f0`, plus a comment documenting the lexing trap.

## 5. Why it survived

The CI test suite checks CI **structure** and `pd_hessian`, never SE **magnitude**
or interval width. `test/test_fd_hessian.jl` (new) closes that gap: it pins
`_fd_hessian` to a known analytic Hessian — a diagonal quadratic with a large
constant offset (the exact trigger) and a general symmetric quadratic — and adds
an end-to-end SE-sanity assertion on a Poisson Wald fit.

## 6. Checks Run

- `test/test_fd_hessian.jl` → PASS `5/5`.
- `test/test_confint_family.jl` → PASS `122/122` (4m45s) with the fix.
- `test/test_structural_confint.jl` → PASS `45/45`; `test/test_confint_profile.jl`
  → PASS `4/4`; `test/test_bridge_ci.jl` → PASS `64/64`.
- No existing test encoded the broken values (all pass unchanged), confirming the
  suite never checked SE magnitude.

## 7. Follow-up / Needs maintainer

- **This changes published Wald CI output across the package** (from garbage to
  correct). It is an inference change → maintainer review before merge; I did not
  self-merge. It is independent of the `X_lv` stack and lands off `main`.
- Recommend a full `Pkg.test()` before merge (local suite ~45 min).
- Any prior numbers/figures quoting non-Gaussian Wald SEs/intervals should be
  regenerated.
