# After-task — Live Gaussian gllvmTMB logLik oracle (catch-up A2)

**Date:** 2026-08-01  
**Lane:** `catchup/loglik-oracle-20260801`  
**Worktree:** `.worktrees/gllvmjl-catchup-loglik-20260801`  
**Base:** `origin/main` @ `05210eca`  
**Twin:** gllvmTMB `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`

## Goal

Make the first live Gaussian gllvmTMB logLik parity cell green on an
`origin/main`-based lane (replace DRAFT RCall scaffold).

## What landed

- LOOP kit under `LOOP/` + frozen plan + scout notes under
  `docs/dev-log/plans/scratch/` and `LOOP/notes/`.
- A0 drift probe on lane tip: `n_drift=0`, `unregistered=0`.
- Rewrote `test/parity/test_gaussian_parity.jl` and README to call
  **gllvmTMB** (not CRAN gllvm), with `unique=FALSE`, per-trait centred Y,
  and correct extractors.

## Evidence (log, not exit code)

```text
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl

Julia logLik          = -501.450700343274
gllvmTMB logLik       = -501.45070035305673
Δ logLik (jl − r)     = 9.78275238594506e-9
Julia σ_eps           = 0.6906550063860128
gllvmTMB σ_eps        = 0.6906556682823224
Δ σ_eps               = -6.618963095395003e-7
Test Summary: Gaussian GLLVM parity | Pass 30 / Total 30
```

Tolerances: logLik rtol 1e-6; σ_eps rtol 1e-4; Σ_y atol 1e-4 — all held.
No silent widening.

## Recon citations

- `docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md`
- `docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md`

## Not covered

- Binomial / Poisson cells (A3 next)
- #132 / #148 / #133 param alignment (OPEN GATE)
- #129 / #128 (fenced)
- ADEMP, coverage, Totoro/DRAC
- README/board public claim upgrade (Rose before that)

## Rose claim fence

OK to say: “live ordinary Gaussian no-X logLik cell vs gllvmTMB green on
this lane tip with cited Δ.” Not OK: “parity done,” “ledger proves fits,”
or family-wide coverage.

## Next

A3 Binomial then Poisson logLik cells; pause at OPEN GATE before
NB2/Beta/Ordinal param work.
