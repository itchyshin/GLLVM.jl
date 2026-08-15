# Arcs — gllvmjl-capability-catchup-20260815

Status legend: `pending` | `in_progress` | `done` | `blocked` | `skipped`

| ID | Status | Gate? | Budget | Outcome |
| --- | --- | --- | ---: | --- |
| Arc0 | in_progress | OPEN GATE: await #204 merge (do not race-merge) | 30–90 min + wait | #204 merged; fresh main WT tip; board START HERE → catch-up |
| Rung1 | pending | — | 60–90 min | Bare `implemented` zip/zinb/zib Status tokens; parentheticals → Notes; MC propose text |
| Rung2 | pending | — | 90–120 min | student / REML / com_poisson promote-or-OWED |
| Rung3 | pending | Pause only at merge/publish/public claim | 90–150 min | truncated_poisson Identity ACCEPTED (docs-only); then continue to engine |
| Rung4 | pending | — | 5–7 h | truncated_poisson engine + tests + ledger flip |
| Rung5 | pending | contingent | 3–5 h | truncated_nbinom2 **or** truncated confint **or** ZIB+X Identity — only if Rung4 early |
| Close | pending | — | 45–75 min | after-task + check-log + board + Melissa + Rose; STOP |

## Dependency order

Arc0 → Rung1 → Rung2 ‖ Rung3 (Rung3 may start after Rung1) → Rung4 → Rung5? → Close

## Verify (every arc)

- Read LOG / artifact, not exit code alone.
- Ledger: Status cells parse as bare tokens (`implemented` / `planned` / `missing`).
- Rose: no invented twin Δ for cut ZIP/ZINB; no silent rtol widen; no overclaim.
