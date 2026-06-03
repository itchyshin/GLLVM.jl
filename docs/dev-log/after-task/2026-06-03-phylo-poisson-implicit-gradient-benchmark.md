# After Task: Phylogenetic Poisson Implicit Gradient Benchmark

## Goal

Replace the slow finite-difference outer-gradient route in the internal
augmented-tree phylogenetic Poisson fitter and rerun the `gllvmTMB` speed
comparison on the same benchmark cells.

## Implemented

The internal `_fit_phylo_poisson_laplace` route now accepts
`gradient = :implicit` and uses an exact dense implicit-gradient scaffold for
`β`, lower-triangular `Λ`, and log scalar phylogenetic variance. The
`bench/phylo_poisson_gllvmtmb_bench.jl` driver passes its parsed `--gradient`
argument into the Julia `bm-tree` fit and defaults to `--gradient=implicit`.
The older `--gradient=finite` path remains available for baseline reruns.

No public API was exported or promoted.

## Mathematical Contract

For the benchmark path, the model remains the augmented-tree Poisson Laplace
approximation:

```text
y[t, i] ~ Poisson(exp(beta[t] + u_leaf[t] + Lambda[t, :] z[:, i]))
u ~ Normal(0, sigma2 * C_tree)
z[:, i] ~ Normal(0, I)
```

The optimizer sees `log(sigma2)` when scalar variance is estimated. The
fixed-mode gradient uses the implicit-function theorem for the Laplace mode,
with the log-sigma coordinate checked against a dense Hessian-inverse
derivative on the small augmented-tree fixture. The public-comparison target is
R `gllvmTMB`'s closest available model:

```r
value ~ 0 + trait +
  phylo_scalar(species, vcv = Cphy) +
  latent(0 + trait | site, d = K)
```

## Files Changed

- `src/families/structured_poisson.jl`
- `test/test_structured_poisson_laplace.jl`
- `bench/phylo_poisson_gllvmtmb_bench.jl`
- `bench/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-03-phylo-poisson-implicit-gradient-benchmark.md`

## Tests Added

The `augmented phylogenetic Poisson Laplace prototype` testset now checks:

- fixed-sigma `_phylo_poisson_implicit_value_grad` against central finite
  differences;
- dense and CG mode-solve agreement for the implicit gradient;
- combined `[β, Λ, log(sigma2)]` implicit gradient against central finite
  differences;
- implicit-vs-finite fitted log-likelihood agreement for the internal fitter;
- implicit scalar-variance fitter smoke behavior;
- malformed `gradient` argument rejection.

These tests exercise independent finite-difference comparisons and a failure
path.

## Checks Run

Focused structured Poisson test:

```sh
julia --project=. test/test_structured_poisson_laplace.jl
```

Result:

```text
structured Poisson Laplace prototype | 13/13 pass
structured Poisson implicit gradient | 23/23 pass
structured Poisson internal fitter | 31/31 pass
structured Poisson sigma-to-zero reduction | 1/1 pass
augmented phylogenetic Poisson Laplace prototype | 38/38 pass
```

Core suite:

```sh
julia --project=. test/runtests.jl
```

Result: exit code 0. The direct core environment emitted the expected two
quality placeholders as broken because Aqua/JET are loaded through
`Pkg.test()`.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
structured Poisson implicit gradient | 23/23 pass
structured Poisson internal fitter | 31/31 pass
augmented phylogenetic Poisson Laplace prototype | 38/38 pass
quality | 12/12 pass
Testing GLLVM tests passed
```

`Pkg.test()` emitted the pre-existing duplicate-include warnings from
`src/takahashi_selinv.jl`; no test failed.

Docs build:

```sh
julia --project=docs docs/make.jl
```

Initial result: failed because the temp worktree docs environment was not
instantiated and expected registered `GLLVM`.

Rerun setup and result:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

Result: exit code 0. Existing warnings remain for absolute local links, missing
`logo.png` / `favicon.ico`, missing `docs/package.json`, and npm audit reporting
4 moderate vulnerabilities. No tracked docs project files changed; generated
`docs/Manifest.toml`, `docs/build/`, and `docs/node_modules/` are ignored.

## Benchmark Numbers

R availability:

```sh
Rscript --vanilla -e 'suppressPackageStartupMessages(library(gllvmTMB)); cat(as.character(utils::packageVersion("gllvmTMB")), "\n")'
```

Result: `gllvmTMB` 0.2.0.

Finite-difference scalar-variance baseline:

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=small,medium --structures=bm-tree --estimate-julia-sigma2 --iterations=200 --warmups=1 --reps=3 --out=bench/results/phylo-poisson-augmented-estimate-small-medium-reps3-2026-06-03.csv
```

| cell | Julia CG | gllvmTMB median | R / Julia |
| --- | ---: | ---: | ---: |
| small | 0.15719425 s | 0.515 s | 3.2762x |
| medium | 2.415410666 s | 0.814 s | 0.3370x |

Fixed-sigma implicit-gradient speed isolation:

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --structures=bm-tree --iterations=200 --warmups=1 --reps=3 --out=bench/results/phylo-poisson-augmented-fixed-implicit-full-reps3-2026-06-03.csv
```

| cell | Julia CG | gllvmTMB median | R / Julia |
| --- | ---: | ---: | ---: |
| small | 0.004019 s | 0.479 s | 119.1839x |
| medium | 0.022607208 s | 0.778 s | 34.4138x |
| large | 0.473812541 s | 2.774 s | 5.8546x |

These rows isolate engine speed only. Their log-likelihoods are not comparable
because Julia fixes `sigma2 = 0.35` while R estimates scalar phylogenetic
variance.

Estimated-sigma implicit-gradient R comparison:

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=small,medium --structures=bm-tree --estimate-julia-sigma2 --iterations=200 --warmups=1 --reps=3 --out=bench/results/phylo-poisson-augmented-estimate-implicit-small-medium-reps3-2026-06-03.csv
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=large --structures=bm-tree --estimate-julia-sigma2 --iterations=400 --warmups=1 --reps=1 --out=bench/results/phylo-poisson-augmented-estimate-implicit-large-400it-rep1-2026-06-03.csv
```

| cell | Julia CG | gllvmTMB | R / Julia | abs loglik diff |
| --- | ---: | ---: | ---: | ---: |
| small | 0.035451375 s | 0.485 s median | 13.6807x | 3.30e-8 |
| medium | 0.128251625 s | 0.762 s median | 5.9414x | 8.36e-8 |
| large | 2.092373333 s | 2.772 s | 1.3248x | 2.44e-7 |

Large-cell note: with `--iterations=200`, Julia reached the same log-likelihood
but reported `converged=false`. Raising the cap to `--iterations=400` gave
`converged=true`.

## R-Parity Verdict

Parity: within tolerance for this benchmark harness, not public API parity.
When Julia estimates `sigma2`, the same-data benchmark log-likelihoods match
R `gllvmTMB` within `1e-6` on small, medium, and large cells. This remains an
internal route until ADEMP recovery and Workflow Q pass.

## JET / Allocs / Aqua Verdicts

- JET: passed through the `Pkg.test()` quality block.
- Aqua: passed through the `Pkg.test()` quality block.
- Allocs: not run as a dedicated Allocs.jl gate. This remains a Workflow Q
  blocker before public promotion.

## Stale-Wording And Rose Checks

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs CLAUDE.md AGENTS.md bench/README.md src/families/structured_poisson.jl -g '!docs/node_modules/**'
rg -n "finite-difference|implicit|phylo.*Poisson|Workflow Q|gllvmTMB" bench/README.md src/families/structured_poisson.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-03-phylo-poisson-implicit-gradient-benchmark.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-provenance scan over tracked public files: clean.
- Stale-wording scan: expected hits only, dominated by historical check-log and
  after-task command text plus the user-provided AGENTS.md "Gaussian only"
  snapshot. This slice adds no public support claim.
- Performance/claim scan: expected hits only in `bench/README.md`, the internal
  engine source, the new check-log entry, and this after-task report. The new
  wording labels the route internal and keeps fixed-sigma speed rows separate
  from estimated-sigma likelihood comparison.

Cross-project tracking issue #13 was updated:
<https://github.com/itchyshin/GLLVM.jl/issues/13#issuecomment-4611326362>.

## Remaining Risks

- The implicit phylogenetic Poisson route still uses dense exact trace pieces;
  it is correct for the benchmark cells but not the final large-`p` Workflow Q
  route.
- Large estimated-sigma fits need a 400-iteration optimizer cap for a clean
  convergence flag.
- No ADEMP recovery test exists yet for the augmented phylogenetic Poisson
  fitted model.
- No dedicated Allocs.jl check was run on the inner loop.
- No public docs or exported API should advertise this as supported user-facing
  phylogenetic Poisson fitting yet.

## Next Command

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=large --structures=bm-tree --estimate-julia-sigma2 --iterations=400 --warmups=1 --reps=3 --out=bench/results/phylo-poisson-augmented-estimate-implicit-large-400it-reps3.csv
```

Rose verdict: PASS WITH NOTES - the internal benchmark route is now much faster
and likelihood-comparable to `gllvmTMB` on the tested cells, but public
promotion still requires ADEMP recovery, Workflow Q, and allocation evidence.
