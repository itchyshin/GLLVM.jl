# After Task: Masked analytic Laplace gradient for NB / Gamma / Beta (J1 follow-on)

## Goal

Complete the masked-analytic story begun in #103 (Poisson/Binomial): make the
three dispersion families (NB2 / Gamma / Beta) use the analytic Laplace gradient
for masked (missing-response) fits too, instead of falling back to finite
differences. This serves the R-side model-based missing-data layer, which fits
overdispersed counts / positive-continuous / proportion responses with NA cells.

## Mathematical Contract

The masked per-site marginal zeroes the score and Hessian/Fisher weight of every
unobserved cell (so it neither moves the conditional mode nor enters the log-det
`A = Λ'WΛ + I`) and skips the masked log-pmf. Each family's analytic gradient now
applies exactly this:

- **NB2** (non-canonical): zero the score `r(y−μ)/(r+μ)`, the observed weight
  `μr(r+y)/(r+μ)²`, and the Fisher weight `μ/(1+μ/r)` for masked cells.
- **Gamma** (non-canonical): zero the score `α(y−μ)/μ` and observed weight `αy/μ`;
  the previously-constant Fisher weight `α` becomes a per-cell vector (`α` for
  observed, `0` for masked) so the log-det drops masked cells. Unmasked is
  algebraically identical (`Λ'(α·Λ) = αΛ'Λ`).
- **Beta**: zero the AD-derived concrete observed weight, the differentiable
  score, and the Fisher weight `φ²ν(μφ,(1−μ)φ)(μ(1−μ))²` for masked cells.

The offset path is unchanged (the analytic gradients carry no offset → still FD).

## Implemented

- `src/laplace_grad.jl`: `mask` keyword added to `_nb_/_gamma_/_beta_site_diffable`
  and `nb_/gamma_/beta_laplace_grad` (mask passed to `_laplace_mode` and threaded
  per site).
- `src/families/{negbin,gamma,beta}.jl`: relaxed the analytic guard from
  `gradient===:analytic && msk===nothing && offset===nothing` to
  `gradient===:analytic && offset===nothing`, and pass `mask = msk` to the
  gradient. Masked NB/Gamma/Beta fits now use the analytic gradient by default.
- Unmasked fits are algebraically unchanged (the `if mask !== nothing` branches
  are skipped; Gamma's vector Fisher reduces to the old `αΛ'Λ`).

## Files Changed

- `src/laplace_grad.jl`, `src/families/negbin.jl`, `src/families/gamma.jl`,
  `src/families/beta.jl`.
- `test/test_masked_dispersion_grad.jl` (new) + `test/runtests.jl` (wired in).
- `docs/dev-log/after-task/2026-06-20-masked-nb-gamma-beta-analytic.md`.

## Checks Run

- `julia --project=. test/test_masked_dispersion_grad.jl` → **9/9**: per family
  (NB/Gamma/Beta) masked analytic fit logLik ≈ masked FD fit (atol 2e-2), and the
  default masked fit == the analytic masked fit (atol 1e-8, i.e. the default now
  uses analytic for masked).
- `julia --project=. test/test_laplace_grad.jl` → **26/26** (unmasked regression
  clean — the gradient-function edits don't change unmasked behaviour).
- `julia --project=. test/test_missing_response.jl` → **23/23** (masked
  Poisson/Binomial regression clean; masked analytic-vs-FD maxdiff ~1e-8).
- `git diff --check` → clean.

## Status / Next

- Build + verified on `claude/j1-masked-nb-gamma-beta-20260620`. Engine
  behaviour change to the default masked path for NB/Gamma/Beta →
  **merge HELD for maintainer sign-off**. Pairs with #103 (Poisson/Binomial);
  together they make the analytic gradient the default across all five
  non-Gaussian families, masked and unmasked.
- Note: GLLVM.jl Windows CI is currently timing-out/cancelling at ~1h18m on main
  (infra, not a test failure — ubuntu×2 + macOS pass); the relevant gate evidence
  is the local runs above plus the ubuntu/macOS matrix jobs.
