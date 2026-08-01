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
- **NB2:** per-trait dispersion — Julia uses `fit_gllvm(...; disp_group=:species)` /
  `fit_nb_gllvm_grouped(...; group=1:p, hessian=:observed)` to match R's
  `log_phi_nbinom2[p]` (#132) and TMB's observed Laplace curvature; do not use
  the shared-`r` `fit_nb_gllvm` default fitter.
- **Beta:** per-trait precision `φ` — Julia uses
  `fit_beta_gllvm_grouped(...; group=1:p, hessian=:observed)` to match R's
  `log_phi_beta[p]` (#148); do not use the shared-φ default fitter.
- Extractors: `as.numeric(logLik(fit))` (= `-opt$objective`); Gaussian also
  compares `report$sigma_eps` and `extract_Sigma(..., part="shared")`.

Cells **green** (light logLik oracles, named routes):
Gaussian; Binomial (Bernoulli); Poisson; NB2 (`group=1:p`); Beta (`group=1:p` +
observed Beta/logit Laplace Hessian, tip `387d267a`); Ordinal **probit** +
observed Hessian (`10fcd484` / `3a84d8b6`).

**Not claimed here:** shared-dispersion NB2/Beta defaults; ordinal-logit;
ADEMP; coverage; “full family parity.” `n_drift=0` ≠ these cells.

## Tolerances

| Quantity | Target |
|---|---|
| logLik | rtol ≤ 1e-6 |
| σ_eps (Gaussian) | rtol ≤ 1e-4 |
| Σ_y (Gaussian) | atol ≤ 1e-4 |

Do not silently widen. If a live cell fails, fix call shape / model identity.
