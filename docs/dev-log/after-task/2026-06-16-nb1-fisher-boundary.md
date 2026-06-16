# After Task: NB1 Tiny-Phi Fisher Boundary Fix

## Goal

Remove the false reduced-rank NB1 bridge gap caused by unstable expected
information near the Poisson boundary.

## Implemented

- Added a Poisson-limit branch to `_nb1_fisher_mu(mu, phi)` for
  `phi <= 1e-6`.
- Added regression coverage in `test/test_nb1.jl` for `phi = 1e-8`, `1e-9`,
  and a near-boundary `1e-5` check.

## Mathematical Contract

NB1 keeps the same parameterisation:

```text
Var(y | mu, phi) = mu * (1 + phi)
```

As `phi -> 0`, NB1 tends to Poisson. The Fisher information with respect to
`mu` therefore tends to `1 / mu`; the stable near-boundary branch uses
`1 / (mu * (1 + phi))`, matching the exact summed expression before the
trigamma subtraction becomes numerically unsafe.

## Files Changed

- `src/families/negbin1.jl`
- `test/test_nb1.jl`

## Checks Run

- `julia --project=. test/test_nb1.jl` -> `34/34 pass`.
- `julia --project=. test/test_bridge_grouped_dispersion.jl` -> `49/49 pass`.
- `julia --project=. test/test_grouped_dispersion_tweedie_nb1.jl` -> `15/15 pass`.
- Paired live R bridge check:
  `GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'`
  -> completed cleanly from the R twin.
- `git diff --check` -> clean.

## Evidence

Before this fix, `_nb1_fisher_mu(10, 1e-9)` returned `1e-12` instead of the
Poisson-limit value near `0.1`, making the Laplace log-determinant too
favourable for boundary NB1 fits.

After the fix, the paired R reduced-rank NB1 fixture reports:

```text
native logLik = -52.4618425767
Julia logLik  = -52.4619219625
df            = 6 on both sides
delta         = -7.9386e-05
```

At the native fitted fixed parameters, Julia now evaluates
`-52.4618425607`, matching native TMB to about `1.6e-08`.

## Claim Boundary

Covered: the small complete balanced reduced-rank NB1 bridge fixture now has
point-objective parity.

Still partial: NB1 CIs, masks, fixed-effect covariates, structured terms, and
broad simulation recovery remain future work.

## Review Notes

- Gauss/Karpinski: boundary numerical fix in Fisher information only.
- Rose: no full-parity wording; keep the promotion scoped to the small bridge
  fixture.
