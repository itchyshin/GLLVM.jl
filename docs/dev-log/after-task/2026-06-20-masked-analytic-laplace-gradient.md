# After Task: Masked Poisson/Binomial analytic Laplace gradient (J1 follow-on)

## Goal

After confirming J1 (analytic Laplace gradients as the production default) is
already on `main`, close the one genuine follow-on the J1 status report flagged:
the production fitters fell back to the finite-difference gradient whenever a
response **mask** was present, even though `poisson_laplace_grad` and
`binomial_laplace_grad` already accept a mask and that masked gradient is
finite-difference-verified. Use the analytic gradient for masked Poisson/Binomial
fits too.

## Mathematical Contract

The masked per-site Laplace marginal zeroes the score and Fisher weight of any
unobserved cell, so it neither moves the conditional mode nor enters the log-det
Hessian `A = Λ'WΛ + I`, and the cell is skipped in the log-pmf sum. The analytic
gradient (`*_laplace_grad(...; mask)`) applies exactly these semantics, so it is
the exact gradient of the masked marginal. `test/test_missing_response.jl` already
finite-difference-verifies this to ≤1e-6 (re-confirmed here:
`maxdiff_poisson = 5.4e-8`, `maxdiff_binomial = 2.4e-8`). The offset path is
unchanged (the analytic gradient does not carry an offset → still FD).

## Implemented

- `src/families/poisson.jl`: relaxed the analytic-gradient guard from
  `gradient === :analytic && msk === nothing && offset === nothing` to
  `gradient === :analytic && offset === nothing`, and pass `mask = msk` into
  `poisson_laplace_grad`. Corrected the now-outdated "no mask/offset" comment.
- `src/families/binomial.jl`: same guard relaxation; pass `mask = msk` into
  `binomial_laplace_grad`.
- Net effect: masked Poisson/Binomial fits now use the analytic gradient **by
  default** (was finite-difference). Unmasked fits are byte-unchanged
  (`mask = nothing` reproduces the previous call); offset fits still use FD;
  NB/Gamma/Beta are untouched (their `*_laplace_grad` do not yet accept a mask).

## Files Changed

- `src/families/poisson.jl`, `src/families/binomial.jl` (guard + mask pass-through).
- `test/test_laplace_grad.jl` (+1 testset, masked analytic-vs-FD gate).
- `docs/dev-log/after-task/2026-06-20-masked-analytic-laplace-gradient.md`.

## Checks Run

- `julia --project=. test/test_laplace_grad.jl` →
  `Poisson … 26/26` + new `Masked analytic-gradient fits (issue #65) 6/6` = **32/32**.
  The masked gate asserts, for Poisson and Binomial: masked analytic fit logLik
  ≈ masked FD fit logLik (atol 1e-3), and the **default** masked fit == the
  analytic masked fit (atol 1e-8, i.e. the default now uses analytic).
- `julia --project=. test/test_missing_response.jl` → **23/23** (no regression;
  masked-objective analytic-vs-FD maxdiff ~1e-8).
- `git diff --check` → clean.
- Not run locally: full `test/runtests.jl` (CI covers it). Unmasked path is
  byte-equivalent, so the change is confined to masked Poisson/Binomial fits.

## Status / Next

- Build + verified on `claude/j1-masked-analytic-20260620`. Engine behaviour
  change to the default masked path → **merge held for maintainer sign-off**.
- NB/Gamma/Beta masked analytic gradients are a possible further follow-on (their
  `*_laplace_grad` would need a `mask` argument first).
