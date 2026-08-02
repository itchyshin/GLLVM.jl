# After-task — A4/A5 catch-up logLik oracle CLOSE

**Date:** 2026-08-01  
**Lane:** `catchup/loglik-oracle-20260801`  
**Worktree:** `.worktrees/gllvmjl-catchup-loglik-20260801`  
**Tip (engine):** `387d267a` (Beta observed-Hessian)  
**Twin:** gllvmTMB `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`  
**Rose verdict:** **PASS WITH NOTES** — light logLik oracles green on named routes only; not “full family parity.”

## Goal

Close the catch-up GOAL: live light gllvmTMB logLik oracle cells for the
locked family order, with honest route boundaries (#132/#148/#133).

## What landed (final bank)

| Family | Route (parity entry) | ΔlogLik (jl − r) | SHA / note |
|---|---|---:|---|
| Gaussian | centred unique=FALSE | 9.78e-9 | A2 |
| Binomial | Bernoulli logit | 1.82e-10 | A3 |
| Poisson | log | 6.75e-9 | A3 |
| NB2 | `fit_nb_gllvm_grouped(...; group=1:p)` + observed Hess. | ≈ −2.50e-4 | cell `5ad55877`; curvature restored at closeout |
| Beta | `fit_beta_gllvm_grouped(...; group=1:p)` + observed Beta/logit Hess. | ≈ +5.97e-9 | `387d267a` |
| Ordinal | **`ordinal_probit`** + observed Hess. (not logit) | ≈ 5.48e-9 | `10fcd484` / `3a84d8b6` |

Interim blocked receipt kept for history:
`docs/dev-log/after-task/2026-08-01-a4a5-nbbeta-ordinal-loglik-blocked.md`.

## Honest route boundaries

- **NB2 / Beta:** twin cells use **grouped per-trait** dispersion (`group=1:p` /
  `disp_group=:species`). Shared-`r` / shared-`φ` defaults are **not** the
  parity entry.
- **Ordinal:** twin cell is **cumulative probit** with observed Laplace
  curvature. Ordinal-logit is **not** claimed here (gllvmTMB public surface is
  probit for this oracle).
- Param wiring #133 (`b7c2cdb8`) + curvature fixes unlocked Ordinal/Beta/NB2.

## Evidence (full suite, not exit codes alone)

Log: `/tmp/gllvmjl-catchup-full-parity-20260801.log`

```text
Gaussian  Δ=9.78275238594506e-9     Pass 30/30
Binomial  Δ=1.8175683180743363e-10  Pass 6/6
Poisson   Δ=6.748564373992849e-9    Pass 6/6
NB2       Δ=-0.00024989924941110075 Pass 8/8
Beta      Δ=5.968587402094272e-9    Pass 8/8
Ordinal   Δ=5.475669695442775e-9    Pass 5/5
Total                               63/63
```

Closeout also restored grouped NB2 `hessian=:observed` (earlier green bank at
`5ad55877` had omitted the engine hunk; live suite had regressed to Δ≈+0.218).

## Not covered / fenced

- No ADEMP recovery grids  
- No empirical coverage campaigns  
- No Totoro/DRAC  
- #129 / #128 still fenced  
- `n_drift=0` is ledger hygiene only — **≠** this logLik work  
- No push  

## Rose claim fence

**OK:** “Light gllvmTMB logLik oracles green for Gaussian, Binomial, Poisson,
NB2 (grouped 1:p), Beta (grouped 1:p), and ordinal_probit on
`catchup/loglik-oracle-20260801` @ `387d267a`, with cited Δ.”

**Not OK:** “full family parity,” “all response families match R,” “coverage
done,” “ADEMP recovery,” or “`n_drift=0` proves fits.”

## Next

Lane DONE. Prefer a **FRESH TASK**. Optional: PR when maintainer asks to push.
