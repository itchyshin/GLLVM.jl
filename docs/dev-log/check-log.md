# Check Log

## 2026-05-31 — Dense-Laplace Mode Workspace For Scalar-Aux Fits

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `646d02b`.

### Scope

- Added an internal `_LaplaceModeWorkspace` for the Fisher-scoring mode finder
  to reuse `η`, `μ`, `dμ/dη`, score, weight, Hessian, RHS, and Newton-step
  buffers.
- Reused packed `β`, `Λ`, and scalar auxiliary views once per aggregate
  objective call instead of reconstructing them at every site.
- Enabled the workspace only for scalar-auxiliary Beta/Gamma paths. A broader
  canonical Poisson/Binomial workspace variant caused an isolated
  `fit_poisson_gllvm` convergence failure under `Pkg.test()`, so that path was
  deliberately backed out.
- Kept NegativeBinomial on the old BLAS-heavy mode solve because the workspace
  loop reduced allocations but slowed the medium NB fit.
- No public API changes. No edits to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`,
  or the PR #59 non-Gaussian CI / two-part lane.

### Verification

Gradient gate:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
```

All non-Gaussian recovery command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2214 pass, 3 broken
placeholders, 0 fail, 0 error.

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2226 pass, 1 existing broken sparse-phy
precision check, 0 fail, 0 error.

### Allocation Probes

Probe shape: `p = 30`, `n = 120`, `K = 2`; one warmed aggregate value/gradient
call measured with `@allocated`.

| family/path | before bytes | after bytes | allocation reduction |
| --- | ---: | ---: | ---: |
| Gamma scalar-aux | 8,650,448 | 1,974,224 | 4.38x |
| Beta scalar-aux | not recorded before this slice | 1,920,752 | reported as after-only |
| Negative-binomial scalar-aux | 6,145,616 | 6,020,016 | intentionally near unchanged |

### Benchmarks

Julia-only warmed medium-cell benchmark:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=negbin,beta,gamma --iterations=120 --warmups=2 --reps=3 --julia-only
```

| family | p | n | K | median seconds | convergence |
| --- | ---: | ---: | ---: | ---: | --- |
| negbin | 30 | 500 | 2 | 0.8786 | 3/3 |
| beta | 30 | 500 | 2 | 2.2930 | 3/3 |
| gamma | 30 | 500 | 2 | 1.1868 | 3/3 |

For comparison with immediately prior logged medians on this branch:
negative-binomial remains near the previous `0.8803s`; Beta improves from the
previous logged `2.5687s`; Gamma improves from the previous logged `1.5403s`.

### Hygiene

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Gamma Scalar-Aux Implicit Fitter

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `f3564b1`.

### Scope

- Added closed-form Gamma log-link scalar-auxiliary observation derivatives for
  the dense-Laplace implicit-gradient helper: log density, score, expected
  weight, and derivatives with respect to `η` and `log α`.
- Switched `fit_gamma_gllvm` from `Optim` ForwardDiff over the dense Laplace
  objective to the existing scalar-auxiliary implicit-gradient route.
- Kept the public API unchanged and did not widen tolerances.
- Tested a cache-backed Gamma variant and rejected it because it slowed the
  medium benchmark cell; the committed path is the simpler stateless implicit
  gradient.
- Did not edit `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or the open
  non-Gaussian CI / two-part PR lane.

### Verification

Gradient gate:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
```

Targeted Gamma recovery:

```sh
julia --project=. --startup-file=no -e 'include("test/test_gamma_fit.jl")'
```

Result:

```text
fit_gamma_gllvm | 7/7 pass
```

All non-Gaussian recovery command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2214 pass, 3 broken
placeholders, 0 fail, 0 error. The touched blocks included:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
fit_gamma_gllvm                                      | 7/7 pass
post-fit Gamma fits                                  | 215/215 pass
quality                                              | 2 broken placeholders
```

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2226 pass, 1 existing broken sparse-phy
precision check, 0 fail, 0 error.

### Benchmarks

Julia-only warmed Gamma benchmark, same command before and after the change:

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

The R rows are timing evidence only until the Gamma parameterisation audit is
closed; the likelihood values differ by more than the comparable Gaussian /
Binomial / Poisson rows and are therefore not used as a strict parity claim.

### CI Status

The interval layer was not changed in this slice. The current full suite passed
the existing Wald, profile-likelihood, parametric-bootstrap, and derived-CI
tests. The broader non-Gaussian CI catch-up remains in PR #59's lane.

### Hygiene

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Beta Cache-Then-Polish Fitter

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `9a731e3`.

### Scope

- Updated `fit_beta_gllvm` to run a cache-backed scalar-auxiliary dense-Laplace
  pass first, then use the existing stateless value/gradient as a final polish
  whenever the cached pass does not satisfy Optim's convergence criteria.
- The final `BetaFit.converged` flag is still based on the stateless polish when
  polishing is needed; the cache is used only to get close quickly.
- No public API changes.
- Did not edit `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or the open
  non-Gaussian CI PR lane.

### Verification

Targeted command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_beta_fit.jl")'
```

Result:

```text
fit_beta_gllvm | 7/7 pass
```

All non-Gaussian recovery command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2214 pass, 3 broken
placeholders, 0 fail, 0 error. The touched blocks included:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
fit_beta_gllvm                                        | 7/7 pass
post-fit Beta fits                                    | 215/215 pass
```

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2226 pass, 1 existing broken sparse-phy
precision check, 0 fail, 0 error.

### Benchmarks

Julia-only warmed Beta benchmark, medium cell:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=beta --iterations=120 --warmups=1 --reps=3 --julia-only
```

| family | p | n | K | before median (s) | after median (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| beta | 30 | 500 | 2 | 2.9037 | 2.5687 | 1.13x |

Julia-only warmed Beta benchmark, small cell:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small --families=beta --iterations=80 --warmups=3 --reps=5 --julia-only
```

| family | p | n | K | before median (s) | after median (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| beta | 10 | 100 | 1 | 0.0524 | 0.0362 | 1.45x |

The larger 100x target still needs a workspace-based site-mode implementation
or a structured sparse/operator Laplace path; cache-then-polish is a safe
constant-factor improvement, not the final algorithm.

### Hygiene

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Scalar-Aux Analytic Derivatives

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `8165059`.

### Scope

- Replaced per-observation ForwardDiff Jacobians in the scalar-auxiliary
  dense-Laplace gradient with analytic derivatives for the production
  Negative Binomial log-link (`log r`) and Beta logit-link (`log φ`) paths.
- Replaced the corresponding NB/Beta per-observation `logpdf(...)`
  distribution-object calls with closed-form `loggamma` log densities.
- Added an in-place Laplace mode helper and a cache-backed scalar-auxiliary
  value/gradient helper for benchmark/future fitter experiments.
- Left NB/Beta production fitters on the stateless scalar-auxiliary gradient:
  the cache-backed helper is faster but the NB recovery fixture can lose the
  Optim convergence flag through line-search behaviour.
- Public model APIs are unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Confidence-Interval Lane Check

- Current branch already has Gaussian Wald/profile/bootstrap and derived CI
  tests passing.
- Non-Gaussian CIs are not part of this speed slice. Open draft PR #59
  (`claude/package-work-catchup-mQiZM`) owns Delta-Gamma / ZIP-ZINB /
  non-Gaussian CI work, so this branch avoids those files.

### Gradient And Recovery Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
```

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2214 pass, 3 broken placeholders, 0 fail, 0 error. The broken entries are the
existing sparse-phy precision check plus the direct-run Aqua/JET placeholders
that are exercised by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
post-fit NB fits                                      | 160/160 pass
post-fit Beta fits                                    | 215/215 pass
Hurdle-Poisson                                        | 166/166 pass
Hurdle-NB                                             | 15/15 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2226 pass, 1 existing broken
sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Production scalar-auxiliary value/gradient kernel, p = 80, n = 400, K = 3,
24 reps:

| family | median (s) | min (s) | mean allocations |
| --- | ---: | ---: | ---: |
| negative-binomial | 0.0180 | 0.0173 | 43.9 MB |
| beta | 0.0429 | 0.0417 | 44.0 MB |

Compared with the earlier generic-observation-AD scalar-aux path in this same
branch, the production kernel is now about 2.5x faster for NB and 1.7x faster
for Beta on this cell.

Cache-backed scalar-auxiliary helper, same cell:

| family | median (s) | mean allocations | verdict |
| --- | ---: | ---: | --- |
| negative-binomial | 0.0134 | 21.1 MB | verified as value/gradient-equivalent, not production-wired |
| beta | 0.0296 | 21.1 MB | verified as value/gradient-equivalent, not production-wired |

R comparator smoke, small cell only, warmed with 3 warmup fits and 3 measured
reps:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small --families=negbin,beta --iterations=80 --warmups=3 --reps=3
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| negative-binomial | 0.0488 | 1.1510 | 23.58x | same_data_parameterization_audit_needed |
| beta | 0.0524 | 0.9980 | 19.04x | same_data_parameterization_audit_needed |

The earlier zero-warmup smoke included Julia compilation cost and is not a
per-fit engine comparison. Strict likelihood interpretation still needs the
NB/Beta parameterisation audit.

Medium warmed smoke, one warmup and one measured repetition:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=negbin,beta --iterations=120 --warmups=1 --reps=1
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| negative-binomial | 0.8803 | 27.7240 | 31.49x | same_data_parameterization_audit_needed |
| beta | 2.9037 | 10.3560 | 3.57x | same_data_parameterization_audit_needed |

Medium Beta is now the named scalar-aux bottleneck; NB is comfortably ahead
against the R comparator on the warmed small and medium cells.

### Hygiene

- `git diff --check`: clean.
- `rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md -g '!docs/node_modules/**'`:
  existing `AGENTS.md` status snapshot hit only; not edited.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Structured Fast-Algorithm Scout

Branch: `codex/non-gaussian-fitter-gradients`

Head after rebase onto `origin/main`: `f442b78`.

### Scope

- Rebased the local non-Gaussian gradient branch onto current `origin/main`,
  which now includes the structured-dependence design spec.
- Added a public-source-only strategy memo:
  `docs/dev-log/2026-05-31-structured-fast-algorithm-scout.md`.
- The memo synthesizes two scout passes and ranks the 100x path as sparse
  precision / node-frame / operator-based structured Laplace, with warm mode
  reuse, profiling, Kronecker/SPDE/Vecchia extensions, and determinant tiers.
- No `src/` files were edited.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Verification

- Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. The direct core run retained the expected direct-run
quality placeholders because Aqua/JET are loaded by `Pkg.test()`. Key
post-rebase touched blocks included:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 74/74 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
Hurdle-Poisson                                        | 166/166 pass
Hurdle-NB                                             | 15/15 pass
```

- Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  8.8s
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks after the rebase: 2208 pass,
1 existing broken sparse-phy precision check, 0 fail, 0 error.
- Benchmarks: not run; the memo records existing benchmark evidence from the
  canonical-gradient slice and labels 100x structured speedups as unproven
  targets.
- Provenance: public citations only; no non-public source path or metadata was
  added.

## 2026-05-31 — Canonical And Scalar-Aux Non-Gaussian Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `e1a971f`.

### Implementation Checks

- Added hand-coded implicit dense-Laplace gradients for canonical Poisson-log
  and Binomial-logit objectives.
- Added per-fitter latent-mode caches for the canonical Binomial and Poisson
  paths; non-canonical Binomial links still use the generic implicit fallback.
- Added a scalar-auxiliary implicit gradient for one dispersion-like parameter
  after `[β; vec(Λ)]`; wired Negative Binomial (`log r`) and Beta (`log φ`) to
  it.
- Left Gamma on direct ForwardDiff for fitting; its scalar-auxiliary helper is
  tested but not production-wired until mode convergence is hardened.
- Added `--cells=` to `bench/non_gaussian_gllvmtmb_bench.jl` so small/medium
  benchmark cells can run without entering the long large R cell.
- Kept public model APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: AD/implicit gradients |   74     74  26.3s
```

The test now checks direct ForwardDiff-through-objective, generic implicit
gradients, canonical hand-coded gradients, cached canonical gradients, and
scalar-auxiliary gradients against central finite differences or the stateless
canonical reference.

### Targeted Recovery Tests

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl"); include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 62/62 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
```

The standalone gradient test was then rerun after adding the cache-equivalence
checks and passed 74/74.

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. The direct core environment reported only the expected
quality-tool placeholders because Aqua/JET are loaded by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 74/74 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
post-fit residuals                                    | 10/10 pass
structured_cov                                        | 31/31 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  8.6s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1806 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Poisson finite-difference baseline vs canonical hand-coded gradient:

| p | n | K | params | finite-diff gradient (s) | canonical gradient (s) | speedup |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 100 | 1 | 20 | 0.0154 | 0.0004 | 35.4x |
| 30 | 200 | 2 | 89 | 0.2693 | 0.0017 | 160.7x |

Generic implicit gradient vs fast hand-coded / scalar-auxiliary gradient:

| family | p | n | K | params | generic implicit (s) | fast gradient (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| binomial | 80 | 400 | 3 | 317 | 0.4542 | 0.0064 | 70.8x |
| poisson | 80 | 400 | 3 | 317 | 0.3374 | 0.0057 | 58.8x |
| negative-binomial | 80 | 400 | 3 | 318 | 0.4073 | 0.0379 | 10.7x |
| beta | 80 | 400 | 3 | 318 | 0.7635 | 0.0642 | 11.9x |

R-vs-Julia full-grid subset command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small,medium --families=binomial,poisson --iterations=80 --warmups=1 --reps=1
```

| cell | family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | --- | ---: | ---: | ---: | --- |
| small | binomial | 0.0235 | 0.5040 | 21.5x | same_data_loglik_comparable |
| small | poisson | 0.0189 | 0.5060 | 26.8x | same_data_loglik_comparable |
| medium | binomial | 0.2590 | 2.0170 | 7.8x | same_data_loglik_comparable |
| medium | poisson | 0.4000 | 3.8250 | 9.6x | same_data_loglik_comparable |

Large-cell command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=large --families=binomial,poisson --iterations=80 --warmups=0 --reps=1
```

| cell | family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status | note |
| --- | --- | ---: | ---: | ---: | --- | --- |
| large | binomial | 5.9188 | 64.1420 | 10.8x | same_data_loglik_comparable | Julia converged |
| large | poisson | 5.7804 | 147.9730 | 25.6x | same_data_loglik_comparable | Julia hit 80-iteration cap but matched logLik |

## 2026-05-31 — Non-Gaussian Implicit Dense-Laplace Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: rebased on `origin/main` at `7e4c64b`, with previous
ForwardDiff slice at `6481e95`.

### Implementation Checks

- Added an implicit dense-Laplace value/gradient helper for scalar families.
- Added an ordinal implicit-gradient helper for the cumulative-logit mode
  equation.
- Switched Binomial, Poisson, Negative Binomial, Beta, and Ordinal fitters to
  `Optim.only_fg!` with explicit objective/gradient callbacks.
- Kept Gamma on direct ForwardDiff through the dense Laplace objective after a
  post-fit fixture exposed non-converged Gamma site modes where the implicit
  mode-equation assumption is not yet reliable.
- Kept public APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: AD/implicit gradients |   42     42  25.4s
```

The test now checks both direct ForwardDiff-through-objective and the implicit
gradient against central finite differences for all six non-Gaussian families.
Gamma's implicit helper is verified on the stable small objective, but the Gamma
fitter still uses direct ForwardDiff pending mode convergence hardening.

### Targeted Recovery Tests

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. The direct core environment again reported the expected
quality-tool placeholders as broken because Aqua/JET are loaded only by
`Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 42/42 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
post-fit residuals                                    | 10/10 pass
structured_cov                                        | 31/31 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  9.5s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1774 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Poisson gradient-evaluation benchmark:

| p | n | K | params | ForwardDiff-through-Newton (s) | implicit (s) | speedup |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 | 60 | 1 | 10 | 0.0003 | 0.0004 | 0.72x |
| 10 | 100 | 1 | 20 | 0.0021 | 0.0015 | 1.42x |
| 30 | 200 | 2 | 89 | 0.1733 | 0.0197 | 8.80x |

R-vs-Julia warmed smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --iterations=80 --reps=1 --warmups=1
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0002 | 0.4690 | 1898.8x | same_data_loglik_comparable |
| binomial | 0.0180 | 0.4990 | 27.7x | same_data_loglik_comparable |
| poisson | 0.0182 | 0.4910 | 27.0x | same_data_loglik_comparable |
| negative-binomial | 0.0300 | 0.6540 | 21.8x | same_data_parameterization_audit_needed |
| beta | 0.0317 | 0.6040 | 19.0x | same_data_parameterization_audit_needed |
| gamma | 0.0405 | 0.5000 | 12.3x | same_data_parameterization_audit_needed |
| ordinal | 0.0463 | 0.5200 | 11.2x | non_equivalent_link |

Representative Poisson full-grid attempt:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --families=poisson --iterations=80 --warmups=1 --reps=1
```

Result: stopped after several minutes because the large R cell exceeded the
interactive budget. No CSV was written.

## 2026-05-31 — Non-Gaussian ForwardDiff Fitter Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `a9a860f`

### Implementation Checks

- Switched `fit_binomial_gllvm`, `fit_poisson_gllvm`, `fit_nb_gllvm`,
  `fit_beta_gllvm`, `fit_gamma_gllvm`, and `fit_ordinal_gllvm` from
  `autodiff = :finite` to `autodiff = :forward`.
- Made dense Laplace accumulators and ordinal scratch arrays element-type
  generic so ForwardDiff Dual values survive the inner Fisher-scoring path.
- Kept public APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: ForwardDiff gradients |   18     18  14.5s
```

The test compares `ForwardDiff.gradient` to a central finite-difference
gradient for the packed objective of each non-Gaussian fitter. Gate: max
absolute difference ≤ 1e-6.

Observed one-off maxima before adding the test:

| family | maximum absolute gradient difference |
| --- | ---: |
| binomial | 5.857e-9 |
| poisson | 1.029e-8 |
| negative-binomial | 6.298e-9 |
| beta | 2.943e-9 |
| gamma | 5.118e-9 |
| ordinal | 2.646e-9 |

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Functional tests passed; the direct core environment
reported the expected quality-tool placeholders as broken because Aqua/JET are
loaded only by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: ForwardDiff gradients | 18/18 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  12.0s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1750 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Julia version: 1.10.0.
R comparator: R 4.5.2, `gllvmTMB` 0.2.0.

Fixed-iteration Julia before/after smoke, p = 5, n = 60, K = 1,
6 L-BFGS iterations, `g_tol = 0.0`. The finite-difference numbers were recorded
immediately before the code change on the same branch; the ForwardDiff numbers
were recorded immediately after.

| family | finite diff (s) | ForwardDiff (s) | speedup |
| --- | ---: | ---: | ---: |
| binomial | 0.0916 | 0.0049 | 18.7x |
| poisson | 0.0696 | 0.0052 | 13.4x |
| negative-binomial | 0.0808 | 0.0093 | 8.7x |
| beta | 0.0896 | 0.0148 | 6.1x |
| gamma | 0.0926 | 0.0131 | 7.1x |
| ordinal | 0.0514 | 0.0105 | 4.9x |

R-vs-Julia warmed smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --iterations=80 --reps=1 --warmups=1
```

Cell: p = 5, n = 60, K = 1.

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0003 | 0.5120 | 1640.6x | same_data_loglik_comparable |
| binomial | 0.0142 | 0.5150 | 36.2x | same_data_loglik_comparable |
| poisson | 0.0339 | 0.5060 | 14.9x | same_data_loglik_comparable |
| negative-binomial | 0.0195 | 0.6400 | 32.9x | same_data_parameterization_audit_needed |
| beta | 0.0331 | 0.6100 | 18.4x | same_data_parameterization_audit_needed |
| gamma | 0.0219 | 0.5070 | 23.1x | same_data_parameterization_audit_needed |
| ordinal | 0.1083 | 0.5570 | 5.1x | non_equivalent_link |

Log-likelihood spot checks on comparable smoke rows:

| family | Julia logLik | gllvmTMB logLik | absolute difference |
| --- | ---: | ---: | ---: |
| gaussian | -328.9497618208953 | -328.949761826271 | 5.38e-9 |
| binomial | -199.02063720298568 | -199.020637206598 | 3.61e-9 |
| poisson | -557.3922590332276 | -557.392259036326 | 3.10e-9 |

The full small/medium/large grid is implemented in
`bench/non_gaussian_gllvmtmb_bench.jl` but was not run in this slice.

### Quality And Audit Scans

Commands:

```sh
rg -n "autodiff\\s*=\\s*:finite|Finite-difference gradient|finite-difference gradient" src/families test bench README.md docs/src CLAUDE.md AGENTS.md
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md
<private-source trace scan over tracked repo content>
```

Results:

- No remaining `autodiff = :finite` or obsolete finite-difference fitter
  wording under `src/families`.
- No private-source trace in tracked repo content.
- `AGENTS.md` still contains the user-provided stale "Gaussian only" snapshot;
  not edited because AGENTS edits require maintainer approval under that file's
  own rules.
- Allocs.jl was not run: `Package Allocs not found in current path`.

Open PR / collision check:

```text
gh pr list --limit 10 --json number,title,headRefName,updatedAt
[]
```

## 2026-05-31 — Structured Schur/SLQ Substrate

### Scope

Added the first internal substrate for the large-`p` non-Gaussian structured
dependence path: a Schur-complement operator for the latent structured response
block plus deterministic stochastic-Lanczos quadrature (SLQ) log-determinant
estimation over supplied probes. The substrate also includes an internal
determinant selector that uses exact dense `logdet` for small `p` and frozen-probe
SLQ for large `p`. This is not yet wired into public fitters.

The implemented operator applies

```text
S_u x = σ⁻² Qx + (sum_s w_s) .* x
        - sum_s D_s Λ (I + Λ' D_s Λ)⁻¹ Λ' D_s x
```

where `D_s = diag(w_s)`. Sparse precision matrices are preserved rather than
densified, and the internal dense-reference / SLQ paths reuse multiply scratch.

### Targeted Tests

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

Result:

```text
structured Schur operator | 22/22 pass
structured Schur SLQ logdet | 9/9 pass
```

The tests cover dense and sparse precision storage, `mul!` agreement with the
independent dense Schur matrix, SPD checks, malformed dimensions / boundary
`sigma2`, exact-basis SLQ agreement with dense `logdet`, deterministic
repeatability with frozen Rademacher probes, dense/SLQ selector branches, and
invalid selector inputs.

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from the emitted `Test Summary` blocks:
2257 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Key touched blocks:

```text
structured Schur operator     | 22/22 pass
structured Schur SLQ logdet   | 9/9 pass
quality                       | 2 broken placeholders
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
structured Schur operator     | 22/22 pass
structured Schur SLQ logdet   | 9/9 pass
quality                       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 2257 pass, 1 existing
broken sparse-phy precision placeholder, 0 fail, 0 error.

### Allocation / Timing Smoke

Command:

```sh
julia --project=. --startup-file=no -e 'using GLLVM, Random, LinearAlgebra, SparseArrays; p=80; n=12; K=2; Random.seed!(804); Λ=0.2 .* randn(p,K); W=0.1 .+ rand(p,n); main=fill(2.2,p); off=fill(-0.4,p-1); Q=spdiagm(-1=>off,0=>main,1=>off); op=GLLVM._SchurUOperator(Symmetric(Q), Λ, W; sigma2=1.1); probes=GLLVM._rademacher_probes(MersenneTwister(805), p, 8); GLLVM._slq_logdet(op, probes; lanczos_steps=20); bytes=@allocated GLLVM._slq_logdet(op, probes; lanczos_steps=20); t=@elapsed GLLVM._slq_logdet(op, probes; lanczos_steps=20); println("slq_p80_n12_K2_steps20_probes8 elapsed=", t, " allocated=", bytes)'
```

Result:

```text
slq_p80_n12_K2_steps20_probes8 elapsed=0.001644 allocated=103552
```

This is a smoke number for the new substrate, not a before/after fitter
speedup. The next meaningful benchmark is dense `logdet(S_u)` vs sparse/SLQ
inside the structured non-Gaussian Laplace objective.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds existing Gaussian / benchmark wording only; no
  new user-facing speed claim was added.

Open PR / collision check:

```text
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Schur Logdet Benchmark Harness

### Scope

Added a Julia-only benchmark harness for the structured non-Gaussian determinant
lane. The script compares exact dense `logdet(S_u)` against frozen-probe SLQ on
the internal `_SchurUOperator`, records the dense/SLQ speedup and SLQ relative
error, and can write row-level CSV output. This does not change package source
or public APIs.

### Commands

Smoke run:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=3
```

Result:

```text
Structured Schur logdet benchmark (smoke); reps=3, warmups=3
smoke    p=  80 n=  12 K=2 dense=  0.0008 s  slq=  0.0009 s  speedup=   0.95x  relerr=5.371e-03
```

Full local grid:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --reps=3
```

Result:

| cell | p | n | K | probes | steps | dense (s) | SLQ (s) | dense / SLQ | relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 80 | 20 | 2 | 4 | 20 | 0.0013 | 0.0013 | 0.96x | 4.382e-3 |
| medium | 160 | 40 | 2 | 4 | 20 | 0.0083 | 0.0043 | 1.94x | 2.776e-3 |
| large | 320 | 80 | 3 | 4 | 20 | 0.0743 | 0.0189 | 3.92x | 3.018e-3 |
| frontier | 640 | 160 | 3 | 4 | 20 | 0.5886 | 0.0734 | 8.02x | 2.825e-4 |

Accuracy-oriented probe sweep:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --cells=large,frontier --reps=3 --nprobes=8 --lanczos-steps=20
```

Result:

| cell | p | n | K | probes | steps | dense (s) | SLQ (s) | dense / SLQ | relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| large | 320 | 80 | 3 | 8 | 20 | 0.0764 | 0.0375 | 2.04x | 4.717e-4 |
| frontier | 640 | 160 | 3 | 8 | 20 | 0.5849 | 0.1440 | 4.06x | 6.225e-4 |

CSV smoke path:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=1 --out=/tmp/structured-schur-smoke.csv
head -2 /tmp/structured-schur-smoke.csv
```

Result: CSV file written with the expected header and one smoke row.

### Test Suites

Focused structured test:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

Result:

```text
structured Schur operator     | 22/22 pass
structured Schur SLQ logdet   | 9/9 pass
```

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2257 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2257 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds this new benchmark entry plus existing Gaussian /
  non-Gaussian speedup records. The new claim is local to the structured Schur
  determinant benchmark and is not a fitted-model speed claim.

Open PR / collision check:

```text
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.
