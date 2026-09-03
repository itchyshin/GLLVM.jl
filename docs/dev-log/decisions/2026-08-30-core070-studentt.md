# CORE-070 Student-t parity: preserve the health boundary

## Decision

Keep the original seed-71 fixture unchanged and make its estimated-ν
acceptance explicit: the public `nu = nothing, disp_group = :species` call
must have finite likelihoods, both engines must report healthy optimization,
and the absolute log-likelihood difference must be at most `0.001`. The
fixed-ν, per-trait-scale call is a control, not a replacement for the public
estimated-ν target. A near-Gaussian ν is a flat-boundary diagnosis; matching
the numerical ν values across engines is neither an identification condition
nor an acceptance criterion.

## Symbolic/API alignment

For trait `j`, the fitted conditional model is

\[
y_{ij} \mid z_i \sim t_{\nu_j}(\eta_{ij}, \sigma_j),\qquad
\eta_{ij}=\beta_j+\lambda_j^\top z_i,
\]

where `σ_j = exp(θσ,j) > 0`. A numeric `nu` fixes `ν`; the public default
`nu = nothing` estimates `ν_j = 1 + exp(θν,j) > 1`. Under
`disp_group = :species`, both free quantities have one coordinate per trait.
`StudentTFamily(ν, σ)` represents one evaluated likelihood; estimation policy
is stored separately on `StudentTFit.estimated_nu`, so a fixed vector of ν
cannot be mistaken for an estimated vector by AIC/BIC parameter counting.

## Frozen oracle

The reference is gllvmTMB commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86`, loaded through RCall from
`/home/snakagaw/core070-aghq-20260830/oracle-build-01/library/gllvmTMB`.
`CORE070_SOURCE_PIN.toml` records source-tree SHA-256
`f83545faa6543dbb1f64d64bbf5a9498adcdf036cc3da5851f269912698b1cc7`
and installed-tree SHA-256
`b25f5b8838d1d476a95f4e79133a5c72fad2496d648ef97cd9422acd39bc5bb5`.
The final qualified receipt is
`/home/snakagaw/core070-aghq-20260830/A6/receipts-final2/run.toml`.

## Evidence, 2026-08-30

The unmodified original fixture is `_ST_SEED = 71`, `p=5`, `K=1`, `n=130`,
`σ_true=0.7`, `ν_true=4.0`.

| Cell | Δ logLik (Julia - R) | Julia health | R health | Verdict |
| --- | ---: | --- | --- | --- |
| fixed ν=4, per-trait σ control | `+4.30e-9` | converged | code 0 | passes control |
| estimated ν, per-trait σ public target | `-7.31e-4` | converged | code 1, `false convergence (8)` | **blocked** |
| interior estimated-ν diagnostic | `+3.14e-8` | converged | code 0 | diagnostic healthy |
| near-Gaussian diagnostic | recorded only | converged | code 0 | diagnostic only |

The public target satisfies the absolute likelihood rule, but it does **not**
satisfy the mandatory both-engine health rule. In that target, the first trait
is on the Gaussian-limit boundary (Julia ν about `3.1e6`, R ν about
`2.3e10`), which explains why ν values must not be mechanically equalised.
It does not permit relabelling the original fixture or accepting R code 1.

## Minimal correction completed

`StudentTFit` now records `estimated_nu::Bool`; all legacy positional
constructors default it to `false`, and `fit_studentt_gllvm` sets it from
`nu === nothing`. The new `test/test_studentt_core070.jl` first failed because
the field and estimated-policy constructor were absent, then passed 8/8 on
Totoro after the field and the parent-owned `_nparams` update.

No numerical likelihood, latent-mode, curvature, tolerance, or ν-equality
change was made. The remaining original-target failure is an R-oracle health
blocker and needs a separately approved reference-control/design decision.
