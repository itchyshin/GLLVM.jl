# Engine gates — Wave2 open conditions

Pinned from the ceiling-amended Identity at
`docs/dev-log/decisions/2026-08-15-censored-poisson-identity.md` (`b7027845`,
Opus APPROVED). This file is the short Wave2 checklist for engine lanes.
Do **not** start engine work from the Identity docs PR; open an owned engine
lane when ready.

## `censored_poisson` Wave2

Identity: ACCEPTED / APPROVED (Julia-forward; twin constructor-only).
Owned engine files (when opened): `src/families/censored_poisson.jl`,
`test/test_censored_poisson.jl`.

| # | Gate | Pass criterion |
| --- | --- | --- |
| 1 | Stable μ≪C evaluation | Evaluate right-censored contrib as `logcdf(Gamma(C,1), μ)`, **not** naive `log(1−F)`. Focused test at e.g. `μ=0.3, C=30` that **fails** under the naive survival form and **passes** under the dual. |
| 2 | Hand-coded η-derivatives | First/second η-derivatives hand-coded from §5 of the Identity amendment. **No** AD through `logcdf` / `_gammalogcdf` (ForwardDiff Dual → MethodError). |
| 3 | FD at censored-row-dominated cell | Central FD ≤ 1e-6 on a cell dominated by censored rows (not only uncensored). |
| 4 | Interval-ready encoding | Response / censor encoding forward-compatible with per-row `(L, U)` without a breaking API change (twin interval spec). |
| 5 | Ledger / public claim | Claim stays **Julia-forward / twin constructor-only** (FAM-16 blocked). No twin Δ, no ADEMP, no ledger flip to `implemented` beyond that wording. |

### Explicit non-gates (this Identity)

- Light RCall / twin Δ — **forbidden** until twin dens + runtime admission exist.
- `docs/dev-log/check-log.md` — **conductor-owned** shared choke; engine/identity
  lanes do not edit it under parallel Wave-1 traffic.

### Twin fence (load-bearing)

Twin `gllvmTMB` @ `114a227e`: constructor + written interval-censoring spec only;
no enum id, no cpp dens arm, absent from fit-multi supported list, FAM-16
blocked, fail-loud admission test. No inventable light Δ.
