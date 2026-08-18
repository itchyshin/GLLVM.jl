# Checkpoint — OVERWRITTEN every arc

GOAL: see GOAL.md. STATE: P1 Identity ACCEPTED + P1 engine landed on this
branch (FE softmax). Ledger stays `missing`. STOP at push to #257 — do not merge.

ARCS DONE (verified):
- Worktree `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818` on
  `cursor/lane-parity-beyond-20260818` from `origin/main` `3d5acba0`.
- LOOP kit committed `1bd38100`.
- P1-Id: `docs/dev-log/decisions/2026-08-18-multinomial-identity.md` @
  `2a5f32ea`. Pins twin fid 16, `η₁ ≡ 0`, `K ≥ 3`, no `categorical()` alias,
  no Δ. Ledger stays `missing`.
- P1-eng: `src/families/multinomial.jl` + `fit_gllvm` dispatch +
  `test/test_multinomial.jl`. Mac-light **37/37** in 2.7 s. FD ≤ 1e-6.
  After-task: `docs/dev-log/after-task/2026-08-18-multinomial-engine.md`.
- Owed chips stamped, **not started:** P2a `truncated_nbinom2` Arc1b fid 11;
  P2b `lognormal` bridge+Δ fid 3. Tweedie T6 paid; T2–T5 unpaid;
  `fit_gllvm` STOP.

ARC IN PROGRESS: none. P1-eng landed.

NEXT: push engine commits to existing #257. Do **not** `gh pr merge`.
Do **not** start P2a/P2b, P3 T2–T5, Phase E, C, or X.

OPEN GATES (need human): **Shinichi merge of #257** after CI — not from
this agent. Ledger promote is a later gate (still `missing`).

TRUTH LIVES IN:
- `cursor/lane-parity-beyond-20260818` (this worktree)
- Identity `docs/dev-log/decisions/2026-08-18-multinomial-identity.md`
- Engine after-task `docs/dev-log/after-task/2026-08-18-multinomial-engine.md`
- Twin pin `gllvmTMB origin/main af1218d8`
- Affordability still in-flight: `GLLVM.jl-aghq-a43-afford-20260818` / #255
  owns `test/test_aghq_gate.jl` + `src/families/aghq_grid.jl`

RESUME: You are **gllvmjl-parity-beyond** — RESUME. READ FIRST:
`LOOP/GOAL.md` → `LOOP/checkpoint.md` → `LOOP/ultra-plan.md` → `./AGENTS.md`.
WORKSPACE: `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818` on
`cursor/lane-parity-beyond-20260818` (reattach; do **not** recreate; do **not**
use the honesty worktree). CONTINUE FROM: P1-eng pushed / STOP. Do not start
P2, P3, E, C, or X. Do not touch `aghq_grid.jl`. Do not invent a Δ.
