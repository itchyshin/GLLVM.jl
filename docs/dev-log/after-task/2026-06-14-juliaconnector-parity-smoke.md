# After-Task Audit: JuliaConnectoR R gllvm Parity Smoke

Date: 2026-06-14
Branch: `codex/high-rate-poisson-safeguard`

## Goal

Turn the older JuliaConnectoR bridge transport smoke into a first real R
`{gllvm}` vs GLLVM.jl parity smoke, without over-promoting the scaffold.

## Files Changed

- `r/gllvmjl.R`
- `r/gllvmtmb_julia.R`
- `r/parity_check.R`
- `r/README_bridge.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-14-juliaconnector-parity-smoke.md`

## Implementation

- `gllvm_jl_init()` now accepts `jl_path` and defaults to `GLLVM_JL_PATH`.
- When a project path is supplied, the R bridge runs `Pkg.activate(path)` before
  importing `GLLVM`, avoiding stale default-environment imports.
- The standalone fallback in `r/gllvmtmb_julia.R` now has the same activation
  path.
- `r/parity_check.R` now scales R `{gllvm}` `params$theta` by
  `params$sigma.lv` before Procrustes comparison, matching GLLVM.jl's loading
  scale.

## Validation

```sh
JULIA_BINDIR=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin \
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(jl_path=Sys.getenv("GLLVM_JL_PATH")); set.seed(1); y <- matrix(rpois(30*4,3), nrow=30); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", row.eff="none"); stopifnot(res$diffs$logLik < 1e-6, res$diffs$beta["abs"] < 1e-5, res$diffs$loadings["abs"] < 1e-5)'
```

Result: exit code 0.

| Quantity | Difference |
| --- | ---: |
| logLik absolute diff | `2.086e-11` |
| beta max abs diff | `1.760e-07` |
| Procrustes loading max abs diff | `6.559e-07` |

## R-Parity Verdict

Partial but materially improved. The first Poisson `method="LA"` no-row-effect
cell now passes logLik, beta, and scaled-loading parity. Other families,
dispersion structures, covariates, missingness, CI payloads, and the canonical
`gllvmTMB` R bridge remain separate gates.

## JET / Allocs / Aqua Verdict

Not applicable; this slice touched R bridge scaffolding and docs only.

## Rose Verdict

PASS WITH NOTES. The old red parity smoke was a harness/activation/loading-scale
bug, not an engine mismatch for this cell. Do not claim full R bridge parity
from this single smoke row.

## Next Command

```sh
git diff --check
```
