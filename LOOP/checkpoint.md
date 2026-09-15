# Checkpoint: honest 0.7 R↔Julia true parity (`/goal` armed in Cursor)

GOAL: see [`LOOP/GOAL.md`](GOAL.md). STATE: DestB DONE; true-parity vs frozen 0.7.0; Project.toml = 0.3.0.

CreateGoal: armed in parent chat (2026-09-14). Do not mark complete.

**LANE (2026-09-15):** Mac Studio owns true-parity; cloud babysit-only for in-flight #367 (+ #369 MERGED); do not start new ungated slices from cloud. **Active goal + ultra-plan (#291)** live in START HERE: [`docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`](../docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md) (canonical plan: [`docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`](../docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md)).

ARC IN PROGRESS: true-parity tranche. Board: [`docs/dev-log/2026-09-14-true-parity-pending-board.md`](../docs/dev-log/2026-09-14-true-parity-pending-board.md).

Rehydrate (2026-09-15): GLLVM.jl origin/main @ c00e9345 (#369 Mac handover MERGED); gllvmTMB origin/main @ fba20d613.

NEXT (ranked):

1. Cloud babysit: land #367 Student-t fixed-ν Wald when green (no new ungated slices).
2. #357 bridge receipts: foreign; CONFLICTING (check-log.md only). Do not edit.
3. T4 realistic-size second-order: Totoro grid; D-139 ack before spend (Mac / paste).
4. Delta SO dispersion alignment: paste `accept delta dispersion A` (Mac / brain).
5. D3 Stage 1: `G0 Stage 1` only.
6. S4 probe: `S4 probe yes` only.
7. Project.toml stays 0.3.0.

IN FLIGHT: #367 Student-t fixed-ν (cloud babysit); #357 CONFLICTING (foreign). Skipped #363/#314.

DONE this tranche: ledger gap inventory; Delta SO wiring (#347); §2 Hessian (A); twin-bridge inventory (#353); #359 cloglog @test fix; #360 board; #358/#1284 arcG; #362 OrdinalPerTrait Wald; #356 TweedieGrouped Wald; #361 Lognormal+TruncPois+TruncNB2 Wald; #355 parity_ledger aliases; #364/#365 board tips; **#366 MultinomialFit Wald** (`c1842dd69`); **#369 Mac handover** (`c00e9345`); native Wald PARTIAL.

DISPOSED: #323 waive; matched-θ C; §2 A; arcG Julia-only ACCOUNTED (#358).

OPEN GATES: QS4; Stage 1; version bump forbidden; foreign #357 (conflict); Delta dispersion paste.

HOLD OUTS (SO): GP-1 / Student-t free ν / Delta species dispersion / BB shared-φ pairing / Λ raw still OUT; Ordinal+Lognormal+Trunc*+Multinomial FE PARTIAL (native Wald; bridge CI waits #357); Student-t fixed-ν pending #367.

RESUME: Mac owns programme. Cloud = #367 babysit only; no new ungated cloud slices. No Stage 1 / S4 / Totoro without paste; no Project.toml bump; no gllvmTMB engine surgery; do not edit #357.
