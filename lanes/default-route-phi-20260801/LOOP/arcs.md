# Arcs — default-route-phi-20260801

Order: S0 → S1 → (S2 ∥ S3 after S1) → S4.

| Arc | Status | Gate | Summary |
| --- | --- | --- | --- |
| S0 | DONE | none | Call-site inventory |
| S1 | DONE | none | `fit_gllvm.jl` NB/Beta `nothing`→`:species` |
| S2 | DONE | after S1 | Parity retarget to default `fit_gllvm` |
| S3 | DONE | after S1 | Cascade tests/docs Fit-type + wording |
| S4 | IN_PROGRESS | after S2+S3 | Live parity 63/63 green; closeout docs; core runtests in flight |
| CLOSE | PENDING | L2 pause only for push/PR | Checkpoint COMPLETE; no push unless asked |

## Notes

- Do not overwrite closed root `LOOP/GOAL.md` or catch-up LOOP files.
- Never stage `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md`.
- One concern per commit; stage by name.
