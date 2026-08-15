# Arcs — gllvmjl-capability-catchup-20260815

Status legend: `pending` | `in_progress` | `done` | `blocked` | `skipped`

| ID | Status | Gate? | Budget | Outcome |
| --- | --- | --- | ---: | --- |
| Arc0 | done | — | 30–90 min + wait | #204 @ `2914cc18`; board START HERE → catch-up |
| Rung1 | done | — | 60–90 min | Bare `implemented` zip/zinb/zib; 0 non-bare Status |
| Rung2 | done | — | 90–120 min | student+com_poisson implemented; REML OWED |
| Rung3 | done | — | 90–150 min | truncated_poisson Identity ACCEPTED |
| Rung4 | done | — | 5–7 h | engine + 10/10 tests + ledger flip |
| Rung5 | skipped | contingent | — | not early; leave truncated_nbinom2 / confint / ZIB+X |
| Close | done | OPEN GATE: push/PR + full Pkg.test before merge | 45–75 min | after-task + check-log + board + Melissa + Rose |

## Verify (every arc)

- Read LOG / artifact, not exit code alone.
- Ledger: Status cells parse as bare tokens (`implemented` / `planned` / `missing`).
- Rose: no invented twin Δ for cut ZIP/ZINB; no silent rtol widen; no overclaim.
