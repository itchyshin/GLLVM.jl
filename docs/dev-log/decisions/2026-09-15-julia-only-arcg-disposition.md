# Decision — Julia-only arcG / DRAC Wald coverage diagnostics (parity_ledger disposition)

**Date:** 2026-09-15  
**Status:** **ACCEPTED** (AGENT-APPLIED Ada default for inventory rank 7)  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Reverse:** paste `reject arcG disposition` in chat.

## Question

The R twin tool `gllvmTMB/tools/parity_ledger.R` prints **`CLOSURE: FAIL`** because one
Julia-only capability row has no `PORT` / `ACCOUNTED` / `DIVERGENCE` disposition:

> `Julia-only arcG / DRAC Wald coverage diagnostics`

## Decision

**ACCOUNTED** — Julia-beyond diagnostic programme; **not** an R capability to port;
**not** the twin-join DIFFER row *Simulation-validated coverage certificate*
(Julia `missing`; out of R↔Julia parity — already fenced in `gllvmtmb-parity.md`).

## Reason

- Coverage *calibration certificates* are out of the true-parity claim (reader scoreboard).
- arcG / DRAC rows record **undercoverage evidence** on Julia's dense path (e.g. 0.932–0.958),
  not a production coverage certificate and not R's withdrawn total-variance floor.
- Leaving the row undispositioned blocks tool CLOSURE while changing no scientific claim.

## Implementation

- R tool: `ACCOUNTED` key
  `"julia-only arcg / drac wald coverage diagnostics"` in
  `gllvmTMB/tools/parity_ledger.R` (tools hygiene; **≠** engine surgery).
- Julia: this decision + after-task; capability row stays `partial` (honest).

## Rose fence

≠ covered promotion · ≠ Stage 1 / S4 / Totoro · ≠ programme §7 · ≠ claiming arcG calibrated.
