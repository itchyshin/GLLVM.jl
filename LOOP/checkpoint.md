GOAL: see GOAL.md.   STATE: A0+A1+A2 landed; Gaussian logLik cell GREEN.

ARCS DONE (verified):
- A0 — write lane `.worktrees/gllvmjl-catchup-loglik-20260801` branch `catchup/loglik-oracle-20260801` @ `1a0b9dc5` (from `05210eca`; commits `8ae8a640` LOOP, `b86ba7ea` A2 cell, `1a0b9dc5` evidence). Drift probe: `n_drift=0` `unregistered=0` (log `/tmp/gllvmjl-a0-drift-20260801.log`). Twin `cee55a07`.
- A1 — correctness inventory folded from scout note (no re-inventory). Citations below.
- A2 — live Gaussian cell green.
- A2b — live bridge capabilities drift smoke PASS (3 expectations; nrow(drift)==0). Numbers from `/tmp/gllvmjl-a2-gaussian-parity-verify.log`:
  - Julia logLik = **-501.450700343274**
  - gllvmTMB logLik = **-501.45070035305673**
  - Δ = **9.78275238594506e-9**
  - σ_eps Δ = **-6.618963095395003e-7**
  - Test Summary: **30 pass / 30 total**

ARC IN PROGRESS: none. A2b bridge smoke DONE (see LOOP/notes/A2b-bridge-smoke-prep.md; 3 expectations pass, nrow(drift)==0).

NEXT: A3 — Binomial then Poisson fixed-seed logLik cells (call-shape risk only; no model-identity bugs per inventory). Do **not** open NB2/Beta/Ordinal until OPEN GATE #132/#148/#133.

OPEN GATES (need human): none yet for Bin/Pois. Next irreversible: A4/A5 Julia→R API/param (#132/#148/#133).

TRUTH LIVES IN:
- Write lane: `.worktrees/gllvmjl-catchup-loglik-20260801` / `catchup/loglik-oracle-20260801`
- Twin R: `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`
- Scratch notes:
  - `docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md`
  - `docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md`
- LOOP notes: `LOOP/notes/A1-correctness-inventory.md`, `LOOP/notes/A2-rcall-callshape-audit.md`
- After-task: `docs/dev-log/after-task/2026-08-01-gaussian-gllvmtmb-loglik-oracle.md`
- Parity log: `/tmp/gllvmjl-a2-gaussian-parity-verify.log`

PARALLEL CHILDREN THIS BATCH:
- [A1 issue inventory](85dadef3-3cd1-4c8f-a9b1-15a13989351f) — superseded by scout note `32200ce6` / scratch inventory
- [RCall call-shape](f3ec0dd3-d130-4fdb-ad70-e34d66daf7b7) — superseded by scout `c508c495` scratch shape note (consumed)
- [Bridge transport inventory](ea7bda98-79e2-4853-b0d4-bf535f8935a4)
- [CRAN gllvm extractors](55501097-727c-4cd6-bf30-5be0888b92a1)
- [Bridge smoke prep](d7723adf-f44c-4da0-94e4-9eeff074e43c) — A2b parallel
- External scouts consumed: [RCall shape](c508c495-b21c-431f-a5d8-5c6b39e97cb9), [correctness inventory](32200ce6-1ebb-4534-b462-37ed3ae709b4)

RESUME:
```
You are gllvm-jl-catchup-loglik — RESUME.
READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md.
WORKSPACE: .worktrees/gllvmjl-catchup-loglik-20260801 on catchup/loglik-oracle-20260801 (reattach; do NOT recreate; do NOT use stale jl-bridge fork).
CONTINUE FROM: A3 Binomial then Poisson logLik cells (after A2 Gaussian green: ΔlogLik≈9.8e-9).
Pause at: OPEN GATE A4/A5 (#132/#148/#133) before NB2/Beta/Ordinal.
Citations: docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md ; 2026-08-01-correctness-inventory.md
No ADEMP. No push. Verify by logLik numbers.
```

CONTINUE HERE vs START A FRESH TASK: **CONTINUE HERE** for A3 if context healthy; else paste RESUME into a fresh chat.
