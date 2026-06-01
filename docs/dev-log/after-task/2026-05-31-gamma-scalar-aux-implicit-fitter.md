# After Task: Gamma Scalar-Aux Implicit Fitter

## Goal

Move `fit_gamma_gllvm` off direct ForwardDiff through the dense Laplace
objective and onto the faster scalar-auxiliary implicit-gradient path, while
preserving the existing likelihood target and recovery tests.

## Implemented

- Added closed-form Gamma log-link scalar-auxiliary observation derivatives in
  `src/families/laplace.jl`.
- Replaced the Gamma conditional `logpdf` call with the equivalent closed-form
  log density.
- Switched `fit_gamma_gllvm` to `Optim.only_fg!` with
  `marginal_loglik_laplace_aux_value_grad`, matching the NB/Beta scalar-auxiliary
  fitter pattern.
- Rejected a cache-backed Gamma variant after a local benchmark showed it slowed
  the medium cell; the committed fitter is the stateless implicit-gradient path.

No public API changed. No edits were made to `src/sparse_phy_grad.jl`,
`src/em_phylo.jl`, or the non-Gaussian CI / two-part PR lane.

## Mathematical Contract

For `Gamma(α, μ/α)` with log link `μ = exp(η)` and packed auxiliary parameter
`log α`, the per-observation terms now use:

```text
ℓ = α log α - loggamma(α) - α log μ + (α - 1) log y - α y / μ
s = ∂ℓ/∂η = α(y / μ - 1)
W = α
```

The scalar-auxiliary derivatives are closed form:

```text
∂ℓ/∂logα = α(log α + 1 - digamma(α) - log μ + log y - y / μ)
∂s/∂η    = -α y / μ
∂s/∂logα = s
∂W/∂η    = 0
∂W/∂logα = α
```

The site-mode equation remains `Λ's - z = 0`; the outer gradient is the same
implicit/envelope dense-Laplace gradient already verified for the scalar-aux
helper.

## Files Changed

- `src/families/laplace.jl`
- `src/families/gamma.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-gamma-scalar-aux-implicit-fitter.md`

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'`
  passed: 92/92.
- `julia --project=. --startup-file=no -e 'include("test/test_gamma_fit.jl")'`
  passed: 7/7.
- All six non-Gaussian family recovery tests passed: 45/45.
- `julia --project=. --startup-file=no test/runtests.jl` passed with exit code
  0. Manual tally from emitted summaries: 2214 pass, 3 broken placeholders, 0
  fail, 0 error.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed:
  quality 12/12 and `Testing GLLVM tests passed`. Manual tally from emitted
  summaries: 2226 pass, 1 existing broken sparse-phy precision check, 0 fail, 0
  error.

## Benchmarks

Julia-only warmed Gamma benchmark, same command before and after:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small,medium --families=gamma --iterations=120 --warmups=1 --reps=1 --julia-only
```

| cell | p | n | K | before Julia (s) | after Julia (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 10 | 100 | 1 | 0.0884 | 0.0723 | 1.22x |
| medium | 30 | 500 | 2 | 18.7340 | 1.5403 | 12.16x |

R comparator smoke:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small,medium --families=gamma --iterations=120 --warmups=1 --reps=1
```

| cell | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| small | 0.0723 | 0.5260 | 7.28x | same_data_parameterization_audit_needed |
| medium | 1.5403 | 3.5810 | 2.32x | same_data_parameterization_audit_needed |

The R rows are not yet strict parity claims because the harness marks Gamma as
`same_data_parameterization_audit_needed`.

## R-Parity Verdict

Timing verdict: PASS WITH NOTES. Gamma is faster than R `gllvmTMB` in the
small/medium one-rep smoke, including 2.32x on the medium cell.

Likelihood-parity verdict: PENDING. The Gamma benchmark row still needs a
parameterisation audit before we claim same-surface equality against R.

## JET / Allocs / Aqua

JET: clean under the `Pkg.test()` quality block.

Aqua: clean under the `Pkg.test()` quality block.

Allocs: not run separately; allocation work remains a next-slice target for the
dense-Laplace site-mode workspace.

## CI / Bootstrap Status

This slice did not edit confidence intervals. The full suite confirms the
current Wald, profile-likelihood, parametric-bootstrap, and derived-CI tests are
green. Broader non-Gaussian CI catch-up remains in PR #59's lane.

## Hygiene Scans

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## Remaining Risks

- The 12.16x medium Julia-only speedup is strong, but not the final 100x-class
  path. The next candidates are an allocation-stable dense-Laplace workspace and
  the scalable structured-determinant algorithm.
- Gamma R parity still needs a parameterisation audit.
- The rejected cache-backed Gamma path should stay out unless a future line
  search strategy makes mode reuse monotone enough to help medium/large cells.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the Gamma fitter is materially faster, gradients
remain finite-difference verified, all suites are green, and public evidence is
carefully limited to what the benchmarks prove.
