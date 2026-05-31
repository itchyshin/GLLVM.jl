# After Task: Non-Gaussian Implicit Gradients

## Goal

Move beyond direct ForwardDiff-through-Newton for the non-Gaussian fitters by
using an implicit dense-Laplace gradient that avoids differentiating through the
inner Fisher-scoring iterations.

## Implemented

The scalar-family dense Laplace path now has an internal
`marginal_loglik_laplace_implicit_value_grad` helper. For each site it finds the
latent mode once, builds the local Laplace contribution and mode equation, and
computes the packed gradient using

```text
dz/dθ = -F_z^{-1} F_θ,
dq/dθ = q_θ - F_θ' F_z^{-T} q_z.
```

Binomial, Poisson, negative-binomial, and Beta fitters now pass this explicit
objective/gradient pair to `Optim.only_fg!`. The ordinal fitter has the same
implicit-gradient pattern through its cumulative-logit mode equation. Gamma
keeps direct ForwardDiff through the dense Laplace objective for now because a
post-fit fixture exposed non-converged Gamma site modes where the implicit
mode-equation assumption is not yet reliable.

## Mathematical Contract

The marginal approximation is unchanged:

```text
q_s(θ) = ℓ(y_s | zhat_s, θ) - 0.5 zhat_s'zhat_s
         - 0.5 logdet(I + Λ'W_sΛ),
```

where `zhat_s` solves the site mode equation `F(z, θ) = 0`. Unlike a pure
envelope shortcut, this implementation also carries the logdet contribution's
mode dependence via `q_z dz/dθ`, so it matches finite differences of the full
Laplace objective.

## Files Changed

- `src/families/laplace.jl`
- `src/families/binomial.jl`
- `src/families/poisson.jl`
- `src/families/negbin.jl`
- `src/families/beta.jl`
- `src/families/gamma.jl` (documented direct-AD fallback)
- `src/families/ordinal.jl`
- `test/test_family_forwarddiff_gradients.jl`
- `CLAUDE.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-non-gaussian-forwarddiff-gradients.md`
- `docs/dev-log/after-task/2026-05-31-non-gaussian-implicit-gradients.md`

No edits were made to `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'`
  passed: 42/42 in 25.4s.
- Targeted recovery tests for all six non-Gaussian fitters passed:
  binomial 8/8, Poisson 7/7, negative-binomial 7/7, Beta 7/7, Gamma 7/7,
  ordinal 9/9.
- `julia --project=. --startup-file=no test/runtests.jl` passed with exit code
  0; key touched blocks included the 42/42 gradient test, all six recovery
  tests, post-fit residuals 10/10, and structured covariance 31/31. The direct
  core environment reported only the expected Aqua/JET placeholders as broken.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed:
  quality 12/12 and `Testing GLLVM tests passed`. Manual tally from emitted
  summaries: 1774 pass, 1 existing broken sparse-phy precision check, 0 fail,
  0 error.

The expanded gradient test now checks direct ForwardDiff-through-objective and
the new implicit gradient against central finite differences for every
non-Gaussian packed objective. Gamma's implicit helper is verified on the stable
small objective but is not yet the production Gamma fitter gradient.

## Benchmarks

Gradient-evaluation benchmark, Poisson:

| p | n | K | params | ForwardDiff-through-Newton (s) | implicit (s) | speedup |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 | 60 | 1 | 10 | 0.0003 | 0.0004 | 0.72x |
| 10 | 100 | 1 | 20 | 0.0021 | 0.0015 | 1.42x |
| 30 | 200 | 2 | 89 | 0.1733 | 0.0197 | 8.80x |

The tiny smoke cell is not the target scale for the implicit method, but the
medium cell shows the intended algorithmic win.

R-vs-Julia warmed smoke, p = 5, n = 60, K = 1:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0002 | 0.4690 | 1898.8x | logLik comparable |
| binomial | 0.0180 | 0.4990 | 27.7x | logLik comparable |
| poisson | 0.0182 | 0.4910 | 27.0x | logLik comparable |
| negative-binomial | 0.0300 | 0.6540 | 21.8x | parameterisation audit needed |
| beta | 0.0317 | 0.6040 | 19.0x | parameterisation audit needed |
| gamma | 0.0405 | 0.5000 | 12.3x | parameterisation audit needed |
| ordinal | 0.0463 | 0.5200 | 11.2x | non-equivalent link |

A representative Poisson `--full --families=poisson --warmups=1 --reps=1`
attempt was stopped after several minutes because the large R cell exceeded the
interactive budget. Full-grid runs should be launched as a longer benchmark job
and written to CSV.

## R-Parity Verdict

The implicit gradient does not change the likelihood surface. The warmed smoke
again matched Gaussian, binomial, and Poisson log-likelihoods against
`gllvmTMB` to the same comparable-family tolerance as the previous slice.
Negative-binomial, Beta, and Gamma still need the named dispersion
parameterisation audit. Ordinal remains non-equivalent-link against
`gllvmTMB::ordinal_probit()`.

## JET / Allocs / Aqua

JET: clean under `Pkg.test()` quality block.

Aqua: clean under `Pkg.test()` quality block.

Allocs: not run; `Allocs` is not installed in the active project.

## Hygiene Scans

- `git diff --check`: clean.
- `rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md`:
  one existing hit remains in `AGENTS.md` line 9. It was not edited in this
  slice because repository instructions require maintainer approval for
  `AGENTS.md` edits.
- Private-provenance guard scan: clean. The exact local guard pattern is not
  transcribed here by design.

## Remaining Risks

- The new implicit helper allocates per-site Jacobian work; this is algorithmic
  progress at medium scale but still leaves room for a lower-allocation
  hand-coded derivative kernel.
- Small cells can be slower than direct ForwardDiff-through-Newton, so a future
  heuristic fallback may be useful.
- Gamma needs mode-convergence hardening before switching its fitter from direct
  ForwardDiff to implicit gradients.
- Full small/medium/large R-vs-Julia benchmarks still need to be run outside the
  interactive loop.
- Negative-binomial, Beta, and Gamma parity interpretation remains blocked on
  R-side parameterisation audit.
- `AGENTS.md` still carries an older Gaussian-only status line; updating it
  should be a maintainer-approved metadata follow-up.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the implicit-gradient algorithm is implemented
and gradient-verified, and is production-wired for Binomial, Poisson, Negative
Binomial, Beta, and Ordinal; Gamma remains on the direct-AD fallback, and the
full-grid R benchmarks remain to be refreshed as a longer benchmark job.
