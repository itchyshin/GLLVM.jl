# GLLVM.jl parity suite (`test/parity/`)

Opt-in comparison tests between GLLVM.jl (Julia) and R's `gllvmTMB` / `gllvm`
package, using RCall.jl to drive R from within Julia.

## Why isolated from the default test suite

`RCall.jl` requires a working R installation to precompile.  CI runners that
lack R would fail at `Pkg.instantiate()` if RCall appeared in
`test/Project.toml`.  To keep `julia --project=. test/runtests.jl` always
runnable — on any machine, with or without R — this directory is a
**completely separate Julia project**.  The default suite never includes or
references any file here.

## How to run

```sh
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
```

Running without `GLLVM_PARITY_TESTS=1` exits cleanly with a skip notice.

## R prerequisites

1. R ≥ 4.2 installed and on `PATH` (or `R_HOME` set).
2. The `gllvm` CRAN package (and/or the `gllvmTMB` development version):
   ```r
   install.packages("gllvm")
   # or for the TMB dev version:
   remotes::install_github("JenniNiku/gllvmTMB")
   ```
3. RCall built against that R:
   ```sh
   julia --project=test/parity -e 'using Pkg; Pkg.build("RCall")'
   ```

## What is compared and why

Raw loadings `Λ` are **not** compared.  Two correct implementations of a
rank-K Gaussian factor model can return completely different `Λ` matrices that
are related by an orthogonal rotation — both are exact global optima with
identical likelihoods.  Additionally, each column has a sign non-identifiability.

Only **rotation-invariant** quantities are tested:

| Quantity | Invariance |
|---|---|
| Marginal log-likelihood | Fully invariant (scalar objective) |
| Fitted covariance `Σ_y = ΛΛᵀ + σ²I` | Invariant under `Λ → ΛQ`, `Q'Q = I` |
| Residual SD `σ_eps` | Invariant |

## DRAFT status of the R call

The R call in `test_gaussian_parity.jl` is a **best-effort draft** based on
the published `gllvm` / `gllvmTMB` API documentation.  It has **not** been
executed against a live R environment.  Before treating any parity assertion
as authoritative, a human (or agent with R access) must:

1. Confirm the `gllvm()` / `gllvmTMB()` function name and argument names
   match the installed version.
2. Confirm the extractor field names (`fit_r$logL`, `fit_r$params$theta`,
   `fit_r$params$sigma`) are correct — these vary between `gllvm` 1.x and
   the TMB development branch.
3. Confirm the loadings matrix orientation (p × K vs K × p) returned by R.
4. Confirm that the R log-likelihood is the same marginal quantity as
   `gaussian_marginal_loglik` in GLLVM.jl (not a VA lower bound or a
   Laplace approximation evaluated at a different point).

All four items are marked `# DRAFT` in `test_gaussian_parity.jl`.

## Tolerances

Current tolerances (`logL` rtol ≤ 1e-3, `Σ_y` atol ≤ 1e-2, `σ_eps` rtol ≤
5e-2) are **provisional**.  The package headline claims machine-precision
log-likelihood agreement vs `gllvmTMB`.  Once the R call is validated, these
should tighten to at least `logL` rtol ≤ 1e-6 / `Σ_y` atol ≤ 1e-4.
