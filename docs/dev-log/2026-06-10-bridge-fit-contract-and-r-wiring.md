# R→Julia bridge: `bridge_fit` contract + `engine="julia"` wiring (handoff to the R side)

Date: 2026-06-10. Author: Claude (GLLVM.jl / Julia side). For: Codex (gllvmTMB / R side).

## Status

- **Julia side DONE:** `src/bridge.jl` `GLLVM.bridge_fit` on branch `a1-nongaussian-ci`
  (commit `4304056`). 227/227 focused tests; **exact** parity vs direct `fit_*_gllvm`
  (Δloglik 0.0, Δloadings 0.0 for Gaussian/Poisson; mixed ≤1e-7). Exposes all 9 families
  + mixed through one flat, JuliaCall-safe contract.
- **R→Julia round-trip: VERIFIED.** Standalone JuliaCall demo ran R→Julia→R end-to-end:
  Poisson fit returned to R (loglik −1886.5196, **exact** match to a direct Julia fit, |Δ|=0);
  mixed [gaussian,poisson,binomial] fit returned with its cross-family latent correlation
  matrix received in R (ρ₁₂=−0.426, ρ₁₃=0.206, ρ₂₃=−0.279). R runs the Julia engine for
  non-Gaussian + mixed families.
- **R-side `engine="julia"` wiring for non-Gaussian:** REMAINING — Codex's lane (see below).

## `bridge_fit` contract (Julia side)

`GLLVM.bridge_fit(; y, family, d, N=nothing, X=nothing, trait_names=nothing, unit_names=nothing, options=Dict())`

- `y`: p×n matrix (Int for count families: poisson/binomial/nb*; Float for gaussian/beta/gamma/lognormal).
- `family`: String — `gaussian`/`normal`, `poisson`, `binomial`/`bernoulli`, `negbinomial`/`nbinom2`/`nb2`,
  `nb1`/`nbinom1`, `beta`, `gamma`, `ordinal`, `lognormal`; OR a `Vector{String}` (one per trait → mixed).
- `d`: latent dim K. `N`: Binomial trials (p×n or scalar). `X`: Gaussian-only covariates.
- `options["derived_ci"]=true` → adds bootstrap CIs for `correlation`.

Returns a flat `NamedTuple` (JuliaCall → R list), primitives only:
`family, families, model, d, n_traits, n_units, trait_names, unit_names, loadings (p×d),
alpha (p), dispersion (p), sigma_eps, Sigma (p×p), correlation (p×p), communality (p),
scores (n×d), loglik, aic, bic, df, nobs, converged, iterations, message, link (p), note`.
With `derived_ci`: `+ correlation_ci_lower, correlation_ci_upper, correlation_ci_level, correlation_ci_n_boot`.

## R wiring spec (`gllvmTMB(..., engine="julia")`)

```r
# 1. point JuliaCall at the GLLVM.jl that has bridge_fit (branch a1-nongaussian-ci):
JuliaCall::julia_setup()
JuliaCall::julia_command('import Pkg; Pkg.activate("<path-to-a1-nongaussian-ci>"); using GLLVM')
# 2. call the primitive (R family -> bridge family string; family=list(...) -> Vector{String}):
res <- JuliaCall::julia_call("GLLVM.bridge_fit", y = Y, family = fam_str, d = K, N = N)
# 3. res is an R list with the contract keys; reconstruct a gllvmTMB_julia object:
#    report = list(Lambda_B = res$loadings, sigma_eps = res$sigma_eps, alpha = res$alpha,
#                  Sigma = res$Sigma, correlation = res$correlation, dispersion = res$dispersion)
#    logLik = res$loglik; aic = res$aic; bic = res$bic; opt = list(convergence = res$converged)
```

Family mapping: `gaussian()→"gaussian"`, `poisson()→"poisson"`, `binomial()→"binomial"`,
`nbinom2()→"nbinom2"`, `nbinom1()→"nb1"`, `beta()→"beta"`, `Gamma()→"gamma"`,
`ordinal()→"ordinal"`, lognormal→`"lognormal"`; `family=list(...)` → `Vector{String}`.

## Caveats to carry into the R object

- **Non-Gaussian X deferred** — `bridge_fit` errors on `X` for any non-Gaussian family (and for mixed).
  Gaussian-with-X works; `alpha` is then the per-trait fitted mean of Xβ (since β has length q≠p).
- **`derived_ci` skipped** for Gaussian/NB1/Lognormal (no `bootstrap_ci_derived` method) — returned with a `note`, not an error.
- **NB1 / Lognormal** lack latent-scale extractors; `Sigma`/`correlation` come from the shared ΛΛᵀ block (flagged in `note`); `scores` empty.
- **aic/bic df** computed via a local uniform parameter count for fits lacking `_nparams` (NB1/Lognormal/Mixed).

## Coordination needs (R side / Codex)

1. ⚠️ **The R bridge bundle (`R/julia-bridge.R`) is on a DETACHED HEAD** in the bridge worktree —
   commit it to a real branch so the work isn't orphaned.
2. **Reach `bridge_fit`:** merge `a1-nongaussian-ci` into the GLLVM.jl the R side targets, or point
   `GLLVM_JL_PATH` / `options(gllvmTMB.GLLVM.jl.path=)` at the `a1-nongaussian-ci` worktree.
3. **Extend the R `engine="julia"` family guard** to admit non-Gaussian + `family=list(...)`
   (it currently rejects everything but Gaussian before JuliaCall setup).
4. **Engine-constant blocker** (design 73) remains for the *sparse-phylo* logLik/AIC parity — it is
   independent of these new one-part/mixed families, which bridge clean (exact parity).
