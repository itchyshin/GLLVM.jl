# GLLVM.jl parity suite (`test/parity/`)

Opt-in comparison tests between GLLVM.jl (Julia) and R's `gllvmTMB`
(primary twin), using RCall.jl to drive R from within Julia. Optional light
CRAN `gllvm` cross-checks are secondary and must not block the twin cell.

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
2. The **`gllvmTMB`** twin package (local checkout / GitHub), not only CRAN `gllvm`.
3. RCall built against that R:
   ```sh
   julia --project=test/parity -e 'using Pkg; Pkg.build("RCall")'
   ```

## What is compared and why

Raw loadings `Λ` are **not** compared (rotation / sign non-identifiability).

Only **rotation-invariant** quantities are tested:

| Quantity | Invariance |
|---|---|
| Marginal log-likelihood | Fully invariant (scalar objective) |
| Fitted covariance `Σ_y = ΛΛᵀ + σ²I` | Invariant under `Λ → ΛQ`, `Q'Q = I` |
| Residual SD `σ_eps` | Invariant |

## Live call shape

Primary oracle path (see
`docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md` and
`test/parity/parity_helpers.jl`):

- Fit with **`gllvmTMB::gllvmTMB`**, formula
  `value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE)`.
- **`unique = FALSE`** so Ψ is off (Gaussian: `Σ = ΛΛᵀ + σ²I`).
- **Gaussian only:** centre Y per trait (Julia zero-mean J1 vs R `0+trait`).
- **Binomial / Poisson:** do **not** centre — Julia already estimates per-trait `β`.
- Extractors: `as.numeric(logLik(fit))` (= `-opt$objective`); Gaussian also
  compares `report$sigma_eps` and `extract_Sigma(..., part="shared")`.

Cells today: Gaussian, Binomial (Bernoulli), Poisson. NB2 / Beta / Ordinal
are gated until #132 / #148 / #133 alignment.

## Tolerances

| Quantity | Target |
|---|---|
| logLik | rtol ≤ 1e-6 |
| σ_eps (Gaussian) | rtol ≤ 1e-4 |
| Σ_y (Gaussian) | atol ≤ 1e-4 |

Do not silently widen. If a live cell fails, fix call shape / model identity.
