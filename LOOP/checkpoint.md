# Checkpoint: honest 0.7 R↔Julia true parity (`/goal` armed in Cursor)

GOAL: see [`LOOP/GOAL.md`](GOAL.md). STATE: DestB DONE; true-parity vs frozen 0.7.0; Project.toml = 0.3.0.

CreateGoal: armed in parent chat (2026-09-14). Do not mark complete.

**LANE (2026-09-15):** Mac Studio owns true-parity. START HERE: [`docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`](../docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md) (canonical plan: [`docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`](../docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md)).

ARC IN PROGRESS: true-parity tranche. Board: [`docs/dev-log/2026-09-14-true-parity-pending-board.md`](../docs/dev-log/2026-09-14-true-parity-pending-board.md).

Rehydrate (2026-09-15): GLLVM.jl origin/main @ 9d300783c (#367 Student-t fixed-ν Wald MERGED); gllvmTMB origin/main @ fba20d613.

NEXT (ranked):

1. BB shared-φ SO cell/test only (already in `_CIFit`; plan [`docs/dev-log/plans/2026-09-15-betabinomial-shared-phi-so.md`](../docs/dev-log/plans/2026-09-15-betabinomial-shared-phi-so.md)). No `confint_family.jl` edits.
2. #357 bridge receipts: foreign; CONFLICTING (check-log.md only). Do not edit.
3. T4 realistic-size second-order: Totoro grid; D-139 ack before spend (Mac / paste).
4. Delta SO dispersion alignment: paste `accept delta dispersion A` (Mac / brain).
5. D3 Stage 1: `G0 Stage 1` only.
6. S4 probe: `S4 probe yes` only.
7. Project.toml stays 0.3.0.

IN FLIGHT: tip docs PR post-#367; #357 CONFLICTING (foreign). Skipped #363/#314.

DONE this tranche: ledger gap inventory; Delta SO wiring (#347); §2 Hessian (A); twin-bridge inventory (#353); #359 cloglog @test fix; #360 board; #358/#1284 arcG; #362 OrdinalPerTrait Wald; #356 TweedieGrouped Wald; #361 Lognormal+TruncPois+TruncNB2 Wald; #355 parity_ledger aliases; #364/#365 board tips; **#366 MultinomialFit Wald** (`c1842dd69`); **#369/#370/#371 Mac handover + goal**; **#367 Student-t fixed-ν Wald** (`9d300783c`) → **PARTIAL (native Wald)**.

DISPOSED: #323 waive; matched-θ C; §2 A; arcG Julia-only ACCOUNTED (#358).

OPEN GATES: QS4; Stage 1; version bump forbidden; foreign #357 (conflict); Delta dispersion paste.

HOLD OUTS (SO): GP-1 / Student-t free ν / Delta species dispersion / BB shared-φ pairing / Λ raw still OUT; Ordinal+Lognormal+Trunc*+Multinomial FE+Student-t fixed-ν PARTIAL (native Wald; bridge CI waits #357).

RESUME: Mac owns programme. Next ungated = BB shared-φ cell/test. No Stage 1 / S4 / Totoro without paste; no Project.toml bump; no gllvmTMB engine surgery; do not edit #357.
