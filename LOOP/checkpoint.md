GOAL: see GOAL.md.   STATE: A0–A3 green; **NB2 (A4) logLik GREEN** @ `5ad55877`; **Ordinal logLik GREEN** @ `3a84d8b6` (Δ≈5.48e-9); Beta logLik **NOT green**.

ARCS DONE (verified):
- A0 — lane + drift `n_drift=0` `unregistered=0`. Twin `cee55a07`.
- A1 — correctness inventory banked (Bin/Pois clear; #132/#148/#133 gate; #129/#128 fenced).
- A2 — Gaussian ΔlogLik = **9.78275238594506e-9** (30/30).
- A2b — bridge drift smoke PASS.
- A3 — Binomial + Poisson live green (`/tmp/gllvmjl-a3-binpois-parity-20260801.log`):
  - Binomial Julia = **-194.681986234064** · R = **-194.68198623424576** · Δ = **1.8175683180743363e-10** · **6/6**
  - Poisson Julia = **-634.171284410425** · R = **-634.1712844171735** · Δ = **6.748564373992849e-9** · **6/6**
- A4 **#132 NB2 logLik** — GREEN @ `5ad55877`. Route: `fit_nb_gllvm_grouped` · `group=1:p`. ΔlogLik = **−2.50e-4** (oracle cell banked).
- A5 **#133 Ordinal logLik** — GREEN @ `3a84d8b6` (impl `10fcd484`). Route: `ordinal_probit` + **observed Hessian** Laplace determinant. ΔlogLik = **5.48e-9** (oracle cell banked).

A4/A5 STATUS (OPEN GATE approved; live oracle partial):
- **#133 Ordinal param** — LANDED at `b7c2cdb8` (per-trait β, τ₁=0, K−2 free cuts; `fit_gllvm(Ordinal)` → pertrait; bridge df/`alpha` wired; focused ordinal tests 123 pass).
  - **Ordinal logLik** — **GREEN** via `ordinal_probit` + observed Hessian; Δ = **5.48e-9**; SHAs **`10fcd484`** / **`3a84d8b6`**.
- **#148 Beta** — grouped `group=1:p` drafted (uncommitted). Live cell BLOCKED: Julia = **135.68642413930405** · R = **133.9582599708042** · Δ = **+1.728164168499859** (6 pass / 1 fail). Same class: Fisher vs observed Hessian in Laplace determinant (material ~2.27 at fitted θ).

**Still green (logLik oracle):** Gauss / Bin / Pois / NB2 / Ordinal.

ARC IN PROGRESS: A5 Beta logLik — **no Beta logLik claim**.

NEXT:
1. **Beta** — Laplace observed-Hessian green (grouped `group=1:p`).
2. Keep #129/#128 fenced.

OPEN GATES (need human only if direction changes):
- None new — OPEN GATE already approved. Remaining work is Beta/Ordinal oracle repair, not a fresh policy gate.
- Still fenced: #129 / #128.

TRUTH LIVES IN:
- Write lane: `.worktrees/gllvmjl-catchup-loglik-20260801` / `catchup/loglik-oracle-20260801` @ `3a84d8b6`
- Twin R: `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`
- Scratch: `docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md`, `…/2026-08-01-correctness-inventory.md`
- After-tasks: `docs/dev-log/after-task/2026-08-01-gaussian-gllvmtmb-loglik-oracle.md`, `…/2026-08-01-binomial-poisson-gllvmtmb-loglik-oracle.md`, `…/2026-08-01-a4a5-nbbeta-ordinal-loglik-blocked.md`
- Parity drafts (uncommitted): `test/parity/test_negbin_parity.jl`, `test/parity/test_beta_parity.jl` + helper/runparity/README edits
- Parity log (A3): `/tmp/gllvmjl-a3-binpois-parity-20260801.log`

PARALLEL CHILDREN (banked):
- Ordinal impl [Ordinal](1a530f6e-522a-4b14-896e-069489c330af) → `b7c2cdb8`
- Ordinal logLik [Debug→banked] → GREEN @ `3a84d8b6` (Δ≈5.48e-9)
- NB [NB](d4df947f-83e6-4e11-acf5-8f17873e45f9) → NB2 logLik green @ `5ad55877`
- Beta [Beta](c37ce19e-1d51-4f0d-bc9b-fe67467c887e) blocked receipt

RESUME:
```
You are gllvm-jl-catchup-loglik — RESUME.
READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md -> AGENTS.md.
WORKSPACE: .worktrees/gllvmjl-catchup-loglik-20260801 on catchup/loglik-oracle-20260801 @ 3a84d8b6.
CONTINUE FROM: A5 — Ordinal logLik GREEN (Δ≈5.48e-9, ordinal_probit + observed Hessian, SHAs 10fcd484/3a84d8b6); Beta logLik still open; do NOT claim Beta green.
A0–A5 Ordinal DONE (Gauss/Bin/Pois/NB2/Ordinal logLik green). #129/#128 fenced. No ADEMP. No push.
```

CONTINUE HERE vs START A FRESH TASK: **CONTINUE HERE** for Beta Laplace observed-Hessian logLik oracle — lane tip `3a84d8b6` + uncommitted parity drafts.
