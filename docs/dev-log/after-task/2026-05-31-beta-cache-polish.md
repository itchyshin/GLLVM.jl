# After Task: Beta Cache-Then-Polish

## Goal

Reduce Beta fitter wall time while preserving the existing convergence contract.

## Implemented

`fit_beta_gllvm` now runs the cache-backed scalar-auxiliary dense-Laplace
objective first. If that cached pass does not satisfy Optim's convergence
criteria, the fitter immediately polishes from the cached minimizer using the
existing stateless scalar-auxiliary value/gradient. The returned `BetaFit`
therefore still uses a normal Optim convergence flag; cache state is only a
warm path to a good starting point.

## Mathematical Contract

The likelihood and gradient target are unchanged from the scalar-auxiliary
Laplace objective:

```text
q_s(θ) = ℓ(y_s | zhat_s, θ) - 0.5 zhat_s'zhat_s
         - 0.5 logdet(I + Λ'W_sΛ),
```

where `zhat_s` solves `Λ's - z = 0`. This slice changes only the optimization
route for Beta: cached mode reuse for the first pass, stateless implicit
gradient for final convergence.

## Files Changed

- `src/families/beta.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-beta-cache-polish.md`

No edits were made to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or the
non-Gaussian CI PR lane.

## Tests

- `julia --project=. --startup-file=no -e 'include("test/test_beta_fit.jl")'`
  passed: 7/7.
- All six non-Gaussian family recovery tests passed: 45/45.
- `julia --project=. --startup-file=no test/runtests.jl` passed with exit code
  0. Manual tally from emitted summaries: 2214 pass, 3 broken placeholders, 0
  fail, 0 error.
- `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'` passed:
  quality 12/12 and `Testing GLLVM tests passed`. Manual tally from emitted
  summaries: 2226 pass, 1 existing broken sparse-phy precision check, 0 fail, 0
  error.

The existing Beta recovery test is the important guard here: it failed during
the first implementation attempt when the cached result's false convergence flag
was returned. The final implementation passes because the stateless polish is
used as the convergence authority.

## Benchmarks

Julia-only warmed Beta benchmark, medium cell:

| family | p | n | K | before median (s) | after median (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| beta | 30 | 500 | 2 | 2.9037 | 2.5687 | 1.13x |

Julia-only warmed Beta benchmark, small cell:

| family | p | n | K | before median (s) | after median (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| beta | 10 | 100 | 1 | 0.0524 | 0.0362 | 1.45x |

## R-Parity Verdict

Parity unchanged. This slice changes the optimization route, not the likelihood
surface. Strict NB/Beta likelihood parity against `gllvmTMB` still needs the
parameterisation audit recorded in the previous report.

## JET / Allocs / Aqua

JET: clean under the `Pkg.test()` quality block.

Aqua: clean under the `Pkg.test()` quality block.

Allocs: not run separately; allocation work remains a next-slice target for the
site-mode workspace.

## Hygiene Scans

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## Remaining Risks

- The speedup is modest: 1.13x on medium Beta and 1.45x on small Beta.
- This is not the 100x algorithmic path. The next serious Beta improvement is
  an in-place workspace for site modes and per-site derivative arrays, or a
  structured sparse/operator Laplace path.

## Rose Verdict

Rose verdict: PASS WITH NOTES — Beta fitting is faster with convergence
preserved, but the gain is a constant-factor bridge rather than the final
structured fast algorithm.
