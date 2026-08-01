GOAL: see GOAL.md.   STATE: A0–A3 landed; Gaussian + Binomial + Poisson logLik cells GREEN.

ARCS DONE (verified):
- A0 — lane + drift `n_drift=0` `unregistered=0`. Twin `cee55a07`.
- A1 — correctness inventory banked (Bin/Pois clear; #132/#148/#133 gate; #129/#128 fenced).
- A2 — Gaussian ΔlogLik = **9.78275238594506e-9** (30/30).
- A2b — bridge drift smoke PASS.
- A3 — Binomial + Poisson live green (`/tmp/gllvmjl-a3-binpois-parity-20260801.log`):
  - Binomial Julia = **-194.681986234064** · R = **-194.68198623424576** · Δ = **1.8175683180743363e-10** · **6/6**
  - Poisson Julia = **-634.171284410425** · R = **-634.1712844171735** · Δ = **6.748564373992849e-9** · **6/6**

ARC IN PROGRESS: none.

NEXT: **OPEN GATE** — A4/A5 Julia→R param alignment (#132/#148/#133) before any NB2/Beta/Ordinal logLik cell. Do not start A6 without Shinichi gate approval.

OPEN GATES (need human):
- **A4/A5** — Align Julia dispersion/cuts toward R public surface (#132 NB2 φ, #148 Beta φ, #133 ordinal intercepts/cuts). Until then, gate default NB2/Beta/Ordinal same-model claims (grouped routes noted in inventory for #132/#148 only).

TRUTH LIVES IN:
- Write lane: `.worktrees/gllvmjl-catchup-loglik-20260801` / `catchup/loglik-oracle-20260801` @ `6cde1da2`
- Twin R: `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`
- Scratch: `docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md`, `…/2026-08-01-correctness-inventory.md`
- After-tasks: `docs/dev-log/after-task/2026-08-01-gaussian-gllvmtmb-loglik-oracle.md`, `…/2026-08-01-binomial-poisson-gllvmtmb-loglik-oracle.md`
- Parity log: `/tmp/gllvmjl-a3-binpois-parity-20260801.log`

PARALLEL CHILDREN (banked):
- [A1 inventory](85dadef3-3cd1-4c8f-a9b1-15a13989351f), [Bridge inventory](ea7bda98-79e2-4853-b0d4-bf535f8935a4), [CRAN extractors](55501097-727c-4cd6-bf30-5be0888b92a1), [A2b smoke](d7723adf-f44c-4da0-94e4-9eeff074e43c), note-banker [notes](10cda540-a618-431e-8c49-07d8ea23af17)

RESUME:
```
You are gllvm-jl-catchup-loglik — RESUME.
READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md.
WORKSPACE: .worktrees/gllvmjl-catchup-loglik-20260801 on catchup/loglik-oracle-20260801.
CONTINUE FROM: OPEN GATE A4/A5 (#132/#148/#133) — do NOT open NB2/Beta/Ordinal cells before approval.
A0–A3 DONE (Gauss/Bin/Pois logLik green; cite checkpoint numbers).
No ADEMP. No push.
```

CONTINUE HERE vs START A FRESH TASK: **START A FRESH TASK** for OPEN GATE / A4 (param API) — batch barrier after A3.
