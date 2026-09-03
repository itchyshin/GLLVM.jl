# M3 benchmark pre-run findings (D-139 probe, 2026-09-01)

Totoro, 1 thread both engines, frozen gllvmTMB 0.7.0 oracle library, paired
canonical model (0+trait means, d=2 latent, unique=FALSE; n_init=1, se off),
3 reps, median wall seconds. Retained: .unlazy/core070-aghq/bench-prerun-01.

| p | n | family | R (s) | Julia (s) | speedup | logLik agree |
|---|---|--------|-------|-----------|---------|--------------|
| 5 | 200 | gaussian | 0.070 | 0.0012 | 59x | 2.2e-9 |
| 20 | 200 | gaussian | 0.299 | 0.0100 | 30x | 1.0e-7 |
| 5 | 500 | gaussian | 0.208 | 0.0020 | 103x | 8.7e-8 |
| 20 | 500 | gaussian | 1.123 | 0.0222 | 51x | 4.3e-7 |
| 50 | 500 | gaussian | 2.760 | 0.1360 | 20x | 1.0e-6 |
| 5 | 200 | poisson | 0.092 | 0.1154 | 0.80x | 1.3e-8 |
| 20 | 200 | poisson | 0.814 | 0.8932 | 0.91x | 1.2e-7 |
| 5 | 500 | poisson | 0.250 | 0.3659 | 0.68x | 4.3e-8 |
| 20 | 500 | poisson | 1.245 | 2.1337 | 0.58x | 1.9e-7 |
| 50 | 500 | poisson | 6.678 | 14.988 | 0.45x | 1.2e-6 |

## Honest read
- Gaussian: 20-103x on this grid (closed-form profile path), consistent with
  the headline claim's single-sigma^2 support cell.
- Poisson: GLLVM.jl is SLOWER than the frozen TMB engine, and the gap WIDENS
  with p (0.80x -> 0.45x). The dense-Laplace hand-coded gradient path loses
  to TMB's sparse AD at moderate p. This is the concrete M3 performance
  target; matches the CLAUDE.md "large-p non-Gaussian" open track.
- All 10 cells: logLik agreement 1e-6..1e-9 — incidental fresh Tier-A
  likelihood-level evidence on sizes well beyond the p<=5 qualification
  fixtures (NOT a parity claim: point estimates/curvature not compared here).

## Full-campaign estimate (D-139)
Full grid (3-4 families x ~12 cells x 10 reps, both engines) extrapolates to
~30-60 min single-threaded on Totoro — above the 30-min line once families
beyond Poisson join, so the full campaign goes to maintainer approval with
this pre-run as its test. Poisson performance diagnosis proceeds now
(read-only profiling).
