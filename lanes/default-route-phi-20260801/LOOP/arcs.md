# Arcs — default-route-phi-20260801

Order: S0 → S1 → (S2 ∥ S3 after S1) → S4.

| Arc | Status | Gate | Summary |
| --- | --- | --- | --- |
| S0 | DONE | none | Call-site inventory → `docs/dev-log/plans/scratch/2026-08-01-default-route-phi-callsites.md` |
| S1 | PENDING | none | Edit `src/families/fit_gllvm.jl` (+ docstring): NB/Beta `nothing`→`:species` |
| S2 | PENDING | after S1 | Retarget `test/parity/test_negbin_parity.jl`, `test_beta_parity.jl`, helpers/README |
| S3 | PENDING | after S1 | Cascade core tests/docs Fit-type + shared-default wording |
| S4 | PENDING | after S2+S3 | Live parity; core tests; check-log; after-task; Rose fence; board pointers |
| CLOSE | PENDING | L2 pause only for push/PR | Checkpoint COMPLETE; no push unless asked |

## Notes

- Do not overwrite closed root `LOOP/GOAL.md` or catch-up LOOP files.
- Never stage `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md`.
- One concern per commit; stage by name.
