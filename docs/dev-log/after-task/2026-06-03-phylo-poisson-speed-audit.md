# After Task: Phylogenetic Poisson Speed Audit

Follow-up note: this speed-audit report records the first fixed-sigma benchmark
harness. The next implementation target named here was completed later on
2026-06-03 in
`docs/dev-log/after-task/2026-06-03-augmented-phylo-poisson-laplace.md`, which
adds the augmented-tree Poisson path and scalar-variance smoke comparison.

## Goal

Answer whether GLLVM.jl has evidence for a fast phylogenetic non-Gaussian path,
using Poisson counts as the first focused comparison against R `gllvmTMB`.

## Implemented

Added `bench/phylo_poisson_gllvmtmb_bench.jl`, a row-level benchmark that fits
the same simulated Poisson matrix with the internal Julia fixed-covariance
structured Poisson prototype and the closest public R `gllvmTMB` model:
`phylo_scalar(species, vcv = Cphy) + latent(0 + trait | site, d = K)`.

The benchmark keeps `bm-tree` and `ar1-sparse` structures separate. `bm-tree`
uses a true Brownian-tree VCV but dense tip precision on the Julia side;
`ar1-sparse` is a sparse-precision relatedness proxy. This is speed-audit
evidence, not likelihood parity.

## Mathematical Contract

The Julia prototype fits a Poisson log-link model with a structured row effect
and site-level latent factors:

```text
y[t, i] ~ Poisson(exp(beta[t] + u[t] + Lambda[t, :] z[:, i]))
u ~ Normal(0, sigma2 * C)
```

The current Julia benchmark fixes `sigma2 = 0.35`; the R `gllvmTMB` comparator
estimates the scalar phylogenetic variance. Therefore log-likelihoods are not
expected to match and are not interpreted as parity evidence.

## Files Changed

- `bench/phylo_poisson_gllvmtmb_bench.jl`
- `bench/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-03-phylo-poisson-speed-audit.md`

## Checks And Benchmarks

R availability:

```sh
Rscript --vanilla -e 'suppressPackageStartupMessages(library(gllvmTMB)); cat(as.character(utils::packageVersion("gllvmTMB")), "\n")'
```

Result: `gllvmTMB` 0.2.0.

Benchmark commands:

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --smoke --julia-only
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --smoke --iterations=25 --reps=1 --warmups=1 --out=bench/results/phylo-poisson-smoke-2026-06-03.csv
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=small,medium --iterations=80 --reps=1 --warmups=1 --out=bench/results/phylo-poisson-small-medium-80it-2026-06-03.csv
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=large --iterations=80 --reps=1 --warmups=1 --out=bench/results/phylo-poisson-large-80it-2026-06-03.csv
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --cells=large --iterations=200 --reps=1 --warmups=1 --julia-only --out=bench/results/phylo-poisson-large-julia-200it-2026-06-03.csv
```

Converged same-run R/J evidence:

| cell | structure | p | n | K | Julia CG (s) | gllvmTMB (s) | R / Julia CG |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| smoke | bm-tree | 5 | 8 | 1 | 0.0011 | 0.4720 | 423.2x |
| smoke | ar1-sparse | 5 | 8 | 1 | 0.0008 | 0.4700 | 575.5x |
| small | bm-tree | 8 | 20 | 1 | 0.0029 | 0.4840 | 165.5x |
| small | ar1-sparse | 8 | 20 | 1 | 0.0025 | 0.4720 | 186.3x |
| medium | bm-tree | 16 | 40 | 2 | 0.0161 | 0.7840 | 48.8x |
| medium | ar1-sparse | 16 | 40 | 2 | 0.0203 | 0.8920 | 43.9x |

Large-cell combined evidence:

| structure | p | n | K | Julia CG converged (s) | gllvmTMB converged (s) | R / Julia CG |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| bm-tree | 32 | 80 | 2 | 0.3634 | 2.8530 | 7.9x |
| ar1-sparse | 32 | 80 | 2 | 0.3328 | 3.7240 | 11.2x |

Large caveat: R converged in the 80-iteration R/J run, while Julia hit the
80-iteration cap. The Julia large timings above come from a separate
200-iteration Julia-only run where both structures converged.

Quality scans:

```sh
git diff --check
rg -n "phylo_poisson_gllvmtmb_bench|fixed_sigma2|likelihood parity|Brownian-tree|ar1-sparse|gllvmTMB" bench/README.md bench/phylo_poisson_gllvmtmb_bench.jl docs/dev-log/check-log.md -g '!docs/node_modules/**'
rg -n "340.?x|same_data_loglik_comparable|machine precision|speedup|phylogenetic variance" bench/README.md bench/phylo_poisson_gllvmtmb_bench.jl docs/dev-log/check-log.md -g '!docs/node_modules/**'
```

Result: whitespace clean. Wording scans find the new benchmark and caveats plus
expected historical benchmark records; no new public likelihood-parity or 100x
phylogenetic non-Gaussian claim was added.

Cross-project issue log:
<https://github.com/itchyshin/GLLVM.jl/issues/13#issuecomment-4609911289>.

## Tests Added

No `test/` file was added because this slice adds a benchmark driver, not a
package behavior change. The executable benchmark itself was smoke-tested in
Julia-only and R/J modes.

## R-Parity Verdict

Parity: N/A. This benchmark intentionally compares the closest public R model
to the current Julia prototype. The Julia path fixes `sigma2`; R estimates the
scalar phylogenetic variance.

## JET, Allocs, Aqua

JET: not run; no `src/` hot path changed.

Allocs: not run; no `src/` hot path changed.

Aqua: not run; no package metadata or exported API changed.

## Remaining Risks

- True non-Gaussian phylogenetic parity still requires an augmented-tree sparse
  Poisson Laplace path that estimates the scalar structured variance.
- Large cells need higher Julia optimizer budgets than small/medium cells.
- `ar1-sparse` is a relatedness proxy, not a Brownian-tree parity model.

## Next Command

```sh
julia --project=. bench/phylo_poisson_gllvmtmb_bench.jl --full --reps=3 --warmups=1 --out=bench/results/phylo-poisson-full-reps3.csv
```

Rose verdict: PASS WITH NOTES - repeatable speed-audit evidence exists, but the
public parity-complete phylogenetic non-Gaussian path is still future work.
