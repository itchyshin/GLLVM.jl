# After-task: JuliaConnectoR Bridge Smoke Repair

Date: 2026-06-14
Branch: `codex/high-rate-poisson-safeguard`

## Goal

Validate and repair the older R `JuliaConnectoR` bridge scaffold enough to run a
live R -> Julia -> R smoke check, without promoting an unsupported parity claim.

## Files Changed

- `r/gllvmjl.R`
- `r/gllvmtmb_julia.R`
- `r/README_bridge.md`
- `docs/dev-log/check-log.md`

## Implementation

- `gllvm_jl_init()` now loads `Distributions`, so bridge family constructors such
  as `Distributions.Poisson()` exist in the Julia session.
- Added `.jl_value()` to handle JuliaConnectoR fields that may already be
  converted to R vectors/scalars rather than `JuliaProxy` objects.
- Routed scalar/vector field extraction for `β`, `loglik`, coefficient tables,
  ordination fields, and Unicode dispersion fields through `.jl_value()`.
- Constructed family markers with `juliaEval("Distributions.<Family>()")`.
- Updated bridge documentation from "not executed" to "transport smoke-tested;
  numerical parity open."

## Validation

```sh
JULIA_BINDIR="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin" \
JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(); set.seed(11); y <- matrix(rpois(30*4, 3), nrow=30); rownames(y) <- as.character(seq_len(nrow(y))); colnames(y) <- paste0("sp", seq_len(ncol(y))); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", disp.formula=~1, iterations=80L); stopifnot(is.finite(res$julia_fit$logLik), all(is.finite(res$julia_fit$coefficients))); print(res$diffs)'
```

Result: command exited `0`; Julia returned finite `logLik` and coefficients.

Live parity smoke result:

| Quantity | Difference |
| --- | ---: |
| logLik absolute diff | 0.6194035 |
| beta max abs diff | 0.04862639 |
| beta max rel diff | 0.05738996 |
| Procrustes loading max abs diff | 2.8625220 |
| Procrustes loading max rel diff | 0.9535611 |

## R Parity Verdict

PARTIAL. Transport is repaired for the smoke cell, but R `{gllvm}` numerical
parity is not yet established.

## JET / Allocs / Aqua

Not applicable: this slice touched only the R scaffold and docs.

## Rose Verdict

PARTIAL. The bridge no longer fails at the JuliaConnectoR mechanics checked here,
but the parity harness exposes a real remaining gap. Do not use this scaffold as
evidence for full R `gllvm` parity until the likelihood target, optimizer starts,
centering, and parameterization are reconciled.

## Next Command

```sh
JULIA_BINDIR="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin" \
JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(); set.seed(11); y <- matrix(rpois(30*4, 3), nrow=30); rownames(y) <- as.character(seq_len(nrow(y))); colnames(y) <- paste0("sp", seq_len(ncol(y))); compare_gllvm(y, family="poisson", num.lv=1, method="LA", disp.formula=~1, iterations=80L)'
```
