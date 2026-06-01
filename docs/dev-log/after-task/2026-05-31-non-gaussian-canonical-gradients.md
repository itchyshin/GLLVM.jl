# After Task: Non-Gaussian Canonical Gradients

## Goal

Push the non-Gaussian fast-gradient track beyond the generic implicit
ForwardDiff Jacobian and toward the 100x algorithmic regime.

## Implemented

Poisson-log and Binomial-logit now use hand-coded implicit dense-Laplace
gradients. The derivation uses the canonical identity `∂s/∂η = -W`, giving
`F_z = -(I + Λ'WΛ)` and reducing each site's adjoint to the same K by K
curvature solve already needed by the Laplace approximation. These two fitters
also keep a per-site latent-mode cache inside the optimizer closure, so repeated
objective/gradient probes do not cold-start every Fisher-scoring solve from
zero. Negative Binomial and Beta now use a scalar-auxiliary implicit gradient:
per-observation derivatives are taken only with respect to `(η, log r)` or
`(η, log φ)`, then the packed `[β; vec(Λ); aux]` gradient is assembled by chain
rule. Gamma's scalar-auxiliary helper is tested, but Gamma fitting remains on
direct ForwardDiff until its mode convergence is hardened.

## Mathematical Contract

The Laplace contribution remains

```text
q_s(θ) = ℓ(y_s | zhat_s, θ) - 0.5 zhat_s'zhat_s
         - 0.5 logdet(I + Λ'W_sΛ),
```

with `zhat_s` solving `F(z, θ) = Λ's - z = 0`. For canonical Poisson and
Binomial, `F_z = -(I + Λ'WΛ)`. For scalar-auxiliary families, the code computes
`ℓ_η`, `s_η`, `W_η`, and the auxiliary derivatives locally at each observation,
then applies `dq/dθ = q_θ - F_θ'F_z^{-T}q_z`. This preserves the same likelihood
surface as the previous implicit helper.

## Files Changed

- `src/families/laplace.jl`
- `src/families/binomial.jl`
- `src/families/poisson.jl`
- `src/families/negbin.jl`
- `src/families/beta.jl`
- `test/test_family_forwarddiff_gradients.jl`
- `bench/non_gaussian_gllvmtmb_bench.jl`
- `CLAUDE.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-non-gaussian-canonical-gradients.md`

No edits were made to `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'`
  passed: 74/74 in 26.3s.
- Targeted gradient + recovery command passed for Binomial, Poisson, Negative
  Binomial, and Beta.
- `julia --project=. --startup-file=no test/runtests.jl` passed with exit code
  0; the direct core environment reported only the expected Aqua/JET
  placeholders.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed:
  quality 12/12 in 8.6s and `Testing GLLVM tests passed`. Manual tally from emitted
  summaries: 1806 pass, 1 existing broken sparse-phy precision check, 0 fail,
  0 error.

The expanded gradient test checks direct ForwardDiff, generic implicit,
canonical hand-coded, cached canonical, and scalar-auxiliary gradients against
central finite differences or the stateless canonical reference.

## Benchmarks

Poisson finite-difference baseline vs canonical gradient:

| p | n | K | params | finite-diff gradient (s) | canonical gradient (s) | speedup |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 100 | 1 | 20 | 0.0154 | 0.0004 | 35.4x |
| 30 | 200 | 2 | 89 | 0.2693 | 0.0017 | 160.7x |

Generic implicit vs fast gradient at p = 80, n = 400, K = 3:

| family | generic implicit (s) | fast gradient (s) | speedup |
| --- | ---: | ---: | ---: |
| binomial | 0.4542 | 0.0064 | 70.8x |
| poisson | 0.3374 | 0.0057 | 58.8x |
| negative-binomial | 0.4073 | 0.0379 | 10.7x |
| beta | 0.7635 | 0.0642 | 11.9x |

Against R `gllvmTMB`, same-data Binomial and Poisson benchmark rows now show:

| cell | family | Julia (s) | gllvmTMB (s) | speedup |
| --- | --- | ---: | ---: | ---: |
| small | binomial | 0.0235 | 0.5040 | 21.5x |
| small | poisson | 0.0189 | 0.5060 | 26.8x |
| medium | binomial | 0.2590 | 2.0170 | 7.8x |
| medium | poisson | 0.4000 | 3.8250 | 9.6x |
| large | binomial | 5.9188 | 64.1420 | 10.8x |
| large | poisson | 5.7804 | 147.9730 | 25.6x |

The 100x claim is now true for the algorithmic gradient comparison against the
original finite-difference-gradient route on the medium Poisson cell, but not
yet for end-to-end fits against R `gllvmTMB`.

## R-Parity Verdict

Binomial and Poisson rows match the same-data `gllvmTMB` log-likelihood surface
within the existing comparable-family tolerance. Negative Binomial and Beta
fitters still need the separate R-side parameterisation audit before their
speed numbers can be interpreted as strict likelihood parity.

## JET / Allocs / Aqua

JET: clean under the `Pkg.test()` quality block.

Aqua: clean under the `Pkg.test()` quality block.

Allocs: not run; `Allocs` is not installed in the active project.

## Hygiene Scans

- `git diff --check`: clean.
- `rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md`:
  one existing hit remains in `AGENTS.md` line 9. It was not edited because
  repository instructions require maintainer approval for `AGENTS.md` edits.
- Private-provenance guard scan: clean.

## Remaining Risks

- End-to-end speedup against R is now 8x to 26x on the measured
  Binomial/Poisson grid, not 100x.
- Poisson large hit the 80-iteration cap while matching the R log-likelihood;
  the next speed lane is optimizer stopping/convergence, not the gradient
  formula itself.
- NB and Beta scalar-auxiliary gradients still use tiny ForwardDiff calls per
  observation; hand-coding their dispersion derivatives is the next local
  constant-factor win.
- Gamma remains on direct ForwardDiff until mode convergence is reliable.
- The canonical mode cache is intentionally not used for NB/Beta because the NB
  recovery fixture lost the convergence flag with a cached aux-gradient path.

## Rose Verdict

Rose verdict: PASS WITH NOTES — the canonical and scalar-auxiliary fast-gradient
algorithms are implemented and gradient-verified, but the end-to-end R speedup
is still below 100x and the remaining bottleneck has moved to optimizer probes
and repeated site-mode solves.
