# After-task — Binomial + Poisson gllvmTMB logLik oracle (catch-up A3)

**Date:** 2026-08-01  
**Lane:** `catchup/loglik-oracle-20260801`  
**Worktree:** `.worktrees/gllvmjl-catchup-loglik-20260801`  
**Prior tip:** `5d0cd93f`  
**Twin:** gllvmTMB `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`

## Goal

Live Binomial then Poisson light logLik oracle cells vs gllvmTMB, same bar as
the green Gaussian cell. No NB2/Beta/Ordinal; no #132/#148/#133 work.

## What landed

- `test/parity/parity_helpers.jl` — shared gllvmTMB long-data fit + logLik extract
- `test/parity/test_binomial_parity.jl` — Bernoulli, seed 43
- `test/parity/test_poisson_parity.jl` — Poisson, seed 44
- `runparity.jl` / README updated (family order + gates)

## Evidence (log, not exit code)

From `/tmp/gllvmjl-a3-binpois-parity-20260801.log`:

```text
Binomial  Julia=-194.681986234064  R=-194.68198623424576  Δ=1.8175683180743363e-10  Pass 6/6
Poisson   Julia=-634.171284410425  R=-634.1712844171735   Δ=6.748564373992849e-9   Pass 6/6
Gaussian  (regression) Δ=9.78275238594506e-9  Pass 30/30
```

logLik rtol 1e-6 held; no silent widening.

## Not covered

- NB2 / Beta / Ordinal cells (**OPEN GATE** #132 / #148 / #133)
- #129 / #128 (fenced)
- ADEMP / coverage / Totoro-DRAC
- Public README/board claim upgrade (Rose)

## Next

Pause at OPEN GATE before Julia→R param alignment for NB2/Beta/Ordinal.
Optional: Melissa reconcile row for catch-up close.
