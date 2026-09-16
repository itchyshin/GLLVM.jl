# Checkpoint: honest 0.7 R↔Julia true parity (`/goal` armed in Cursor)

GOAL: see [`LOOP/GOAL.md`](GOAL.md). STATE: DestB DONE; true-parity vs frozen 0.7.0; Project.toml = 0.3.0.

CreateGoal: armed in parent chat (2026-09-14). Do not mark complete.

**LANE (2026-09-15):** Mac Studio owns true-parity. START HERE: [`docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`](../docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md) (canonical plan: [`docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md`](../docs/dev-log/plans/2026-09-05-true-parity-ultra-plan.md)).

ARC IN PROGRESS: true-parity tranche. Board: [`docs/dev-log/2026-09-14-true-parity-pending-board.md`](../docs/dev-log/2026-09-14-true-parity-pending-board.md).

Rehydrate (2026-09-16): GLLVM.jl origin/main tip includes `#378` `67247f520` (Tweedie shared-power SO) on top of `#374`/`#376`; gllvmTMB origin/main @ fba20d613.

NEXT (ranked):

1. **Tweedie species estimated-power SO** (this slice / follow-on) — then only paste-gated remainder.
2. #357 bridge receipts: foreign; CONFLICTING (check-log.md only). Do not edit.
3. T4 realistic-size second-order: Totoro grid; D-139 ack before spend (Mac / paste).
4. Delta SO dispersion alignment: paste `accept delta dispersion A` (Mac / brain).
5. D3 Stage 1: `G0 Stage 1` only.
6. S4 probe: `S4 probe yes` only.
7. Project.toml stays 0.3.0.

IN FLIGHT: Tweedie species-power SO cell; #357 CONFLICTING (foreign). Skipped #363/#314.

DONE this tranche: ledger gap inventory; Delta SO wiring (#347); §2 Hessian (A); twin-bridge inventory (#353); #359 cloglog @test fix; #360 board; #358/#1284 arcG; #362 OrdinalPerTrait Wald; #356 TweedieGrouped Wald; #361 Lognormal+TruncPois+TruncNB2 Wald; #355 parity_ledger aliases; #364/#365 board tips; **#366 MultinomialFit Wald** (`c1842dd69`); **#369/#370/#371 Mac handover + goal**; **#367 Student-t fixed-ν Wald** (`9d300783c`); **#372/#373 tips**; **#374 BB shared-φ SO** (`eeb7e092`); **#376 six holdout SO cells** (`47fcb23e`); **#378 Tweedie shared-power SO** (`67247f520`); **#377/#379/#381 tips**.

DISPOSED: #323 waive; matched-θ C; §2 A; arcG Julia-only ACCOUNTED (#358).

OPEN GATES: QS4; Stage 1; version bump forbidden; foreign #357 (conflict); Delta dispersion paste.

HOLD OUTS (SO): GP-1 / Student-t free ν / Delta species dispersion / BB shared-φ **φ pairing** / Λ raw still OUT or open; Tweedie fixed+shared+species PARTIAL (native Wald + paired toy cells; option A); Ordinal+Lognormal+Trunc*+Multinomial FE+Student-t fixed-ν+BB shared-φ **cell** PARTIAL (native Wald + paired toy cells; bridge CI waits #357).

RESUME: After Tweedie species lands, remainder is paste-gated. No Stage 1 / S4 / Totoro without paste; do not edit #357; no Project.toml bump; no gllvmTMB engine.