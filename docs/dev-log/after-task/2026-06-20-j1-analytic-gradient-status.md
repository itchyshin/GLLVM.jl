# After Task: J1 — analytic Laplace gradient status (already wired; docstring truth-fix)

## Goal

The inherited handover (gllvmTMB `2026-06-20-handover-post-101-landing.md`, DO
NEXT #2) scoped "J1" as: wire issue-#65's analytic Laplace gradient into the
production `fit_*` (poisson/nb/gamma/beta/binomial) behind a logLik-Δ ≤ 1e-6 vs
FD gate. Confirm the true state on GLLVM.jl `main` and close honestly.

## Finding — J1 is already implemented on `main`

The repository is authoritative. On `origin/main` (`186af2d`) the analytic
gradients are not standalone — they are the **production default**:

- All five analytic gradients exist and are FD-verified:
  `poisson_/nb_/gamma_/beta_/binomial_laplace_grad` in `src/laplace_grad.jl`.
- Every production fitter defaults to `gradient::Symbol = :analytic`
  (`src/families/poisson.jl:71`, `negbin.jl:73`, `gamma.jl:68`, `beta.jl:83`,
  `binomial.jl:90`) and drives `_optimize_with_analytic` with the analytic
  closure, a central-FD fallback for non-finite probes, and an automatic
  `autodiff = :finite` fall-back when a response mask or offset is present.
- The analytic-vs-FD agreement of the fitted optimum is already gated by
  `test/test_laplace_grad.jl` (in `runtests.jl`): per family it asserts
  `default.loglik ≈ analytic.loglik` (atol 1e-8) and `fd.loglik ≈ analytic.loglik`
  (atol 1e-3 poisson/binomial, 2e-2 nb/gamma/beta), plus standalone
  gradient-vs-FD agreement (~1e-4).

The handover's "NOT yet wired" claim came solely from **stale docstrings** inside
`src/laplace_grad.jl`, which still said "standalone … not yet wired into the
fitter". No engine wiring was needed; the only honest deliverable is correcting
those docstrings.

## Implemented

- Corrected the file header + the five per-function docstrings in
  `src/laplace_grad.jl` to describe the wired/default reality (default gradient
  of each `fit_*_gllvm`; FD fallback; `autodiff = :finite` under mask/offset;
  agreement gated by `test/test_laplace_grad.jl`). Docstring-only; no code change.

## Files Changed

- `src/laplace_grad.jl` (docstrings only; 20 insertions / 14 deletions).
- `docs/dev-log/after-task/2026-06-20-j1-analytic-gradient-status.md` (this report).

## Checks Run

- `julia --project=. test/test_laplace_grad.jl` → **26/26 pass** on `main`
  (`186af2d`) and again on this branch after the docstring edit — confirms the
  analytic path is the default + FD-equivalent across all five families, and that
  the doc edit does not break the build.
- `git diff --check` → clean (no whitespace errors).
- Not run here: the full `test/runtests.jl` (heavy Julia matrix; the post-#101
  `main` CI run was still in progress at write time; Documenter is green). A
  doc-only change cannot affect test outcomes.

## Status / Next

- J1 (analytic-gradient wiring) is **DONE on `main`** — verified, gated, default.
  This is verification + doc-truth evidence; no register/status promotion.
- Genuinely-new *extensions* of J1 (not done): the analytic gradient falls back
  to FD whenever a response **mask** or **offset** is present, even for Poisson /
  Binomial whose `*_laplace_grad` already accept `mask`. Relaxing the fitter
  guard to use the analytic gradient on masked Poisson/Binomial fits (with a
  masked analytic-vs-FD gate) is a real follow-on slice — flagged, not done.
