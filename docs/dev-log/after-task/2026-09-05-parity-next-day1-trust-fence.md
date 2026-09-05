# After-task — parity-next day-1 trust fences (2026-09-05)

## Scope

Day-1 trust slice under G0 (3-day package; wedge A deferred): surgical doc fences
for contract §7 / matched-coordinates honesty (S4) and advisory smoke fail
disposition (S5). No code, no wedge scout, no register promotion.

## Outcome

| Slice | Status | Deliverable |
|---|---|---|
| S4 — claim boundary | **DONE** | §7 **NOT DONE** + matched-coords **3 pass / 2 blocked** + tier **NOT implemented** in contract §7 and `gllvmtmb-parity.md` |
| S5 — advisory fails | **DONE** | `advisory-smoke-fail-disposition-2026-09-05.md` — three cells **advisory-red** |

Receipts cited on main (Option D, no rebuild):

- #284 advisory R smoke — `advisory-r-smoke-nb2-studentt-2026-09-05.md` (15/3/18)
- #285 matched-coords pilot — `second-order-matched-pilot-batch1-20260905.md` (3/0/2/0)

## Checks run

```sh
git fetch origin main && git checkout -B cursor/parity-next-day1-trust-20260905 origin/main
rg -n 'NOT DONE|3 pass / 2 blocked|advisory-red' \
  docs/dev-log/core070/second-order-parity-contract.md \
  docs/src/gllvmtmb-parity.md \
  docs/dev-log/core070/advisory-smoke-fail-disposition-2026-09-05.md
test -f docs/dev-log/core070/advisory-smoke-fail-disposition-2026-09-05.md
```

## Files touched

- `docs/dev-log/core070/second-order-parity-contract.md`
- `docs/src/gllvmtmb-parity.md`
- `docs/dev-log/core070/advisory-smoke-fail-disposition-2026-09-05.md` (new)
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-09-05-parity-next-day1-trust-fence.md` (this note)
- `.unlazy/parity-next-20260905/gates/leaf-s4-claim-boundary.md`
- `.unlazy/parity-next-20260905/gates/leaf-s5-advisory-fails.md`

## Not claiming

- True parity or contract §7 programme completion
- Matched-coordinates tier shipped (pilot only; 2/5 θ-blocked)
- CI oracle replacement or §6 holdout clearance for NB2 / truncated NB2 / Student-t
- Wedge A bridge ACC scout (day 2+)

## Follow-up

- Day 2 thin wedge A (bridge ACC scout on Ayumi / urbanisation_map) — separate agent per G0-2
- S3 #286 bundle closeout if not already on main
- V1 ledger re-run after wedge deliverable

Branch: `cursor/parity-next-day1-trust-20260905` · base `753a0173`.
