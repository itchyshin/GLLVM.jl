GOAL: see GOAL.md.   STATE: **COMPLETE** — all ordered logLik oracle cells green (Gauss → Bin → Pois → NB2 grouped → Beta grouped → Ordinal probit). Tip includes Beta `387d267a`.

ARCS DONE (verified):
- A0 — lane + drift `n_drift=0` `unregistered=0`. Twin `cee55a07`.
- A1 — correctness inventory banked (Bin/Pois clear; #132/#148/#133 via parity routes; #129/#128 fenced).
- A2 — Gaussian ΔlogLik = **9.78275238594506e-9** (30/30).
- A2b — bridge drift smoke PASS.
- A3 — Binomial + Poisson live green:
  - Binomial Julia = **-194.681986234064** · R = **-194.68198623424576** · Δ = **1.8175683180743363e-10** · **6/6**
  - Poisson Julia = **-634.171284410425** · R = **-634.1712844171735** · Δ = **6.748564373992849e-9** · **6/6**
- A4 **#132 NB2 logLik** — GREEN. Route: `fit_nb_gllvm_grouped` · `group=1:p` + **observed NB2/log** Laplace Hessian (parity cell `5ad55877`; curvature default restored at closeout — earlier bank omitted the engine hunk). ΔlogLik ≈ **−2.50e-4** (rtol 1e-6).
- A4 **#148 Beta logLik** — GREEN @ `387d267a`. Route: `fit_beta_gllvm_grouped` · `group=1:p` + **observed Beta/logit** Laplace Hessian. ΔlogLik ≈ **+5.97e-9**.
- A5 **#133 Ordinal logLik** — GREEN @ `3a84d8b6` (impl `10fcd484`). Route: **`ordinal_probit`** (not logit) + **observed Hessian** Laplace. ΔlogLik ≈ **5.48e-9**.

**Family oracle bank (lane close):**

| Family | Status | Route / note | Δ order |
|---|---|---|---|
| Gaussian | green | closed-form marginal | ~1e-8 |
| Binomial | green | Bernoulli logit | ~1e-10 |
| Poisson | green | log | ~1e-8 |
| NB2 | green | grouped `1:p` | ~2.5e-4 |
| Beta | green @ `387d267a` | grouped `1:p` + observed Hess. | ~6e-9 |
| Ordinal | green | **probit** + observed Hess. | ~5e-9 |

A4/A5 STATUS: **CLOSED** for light logLik oracles on the routes above. Default shared-dispersion NB2/Beta fitters and ordinal-logit are **not** the twin parity entries.

OPEN GATES / FENCED:
- #129 / #128 still fenced (CI scale / H² denom — not this arc).
- No ADEMP / coverage / Totoro-DRAC.
- `n_drift=0` ≠ fit parity (ledger hygiene only).

NEXT:
1. Rose claim fence holds on public boards (no “full family parity”).
2. Melissa plan-actual CLOSED (this closeout).
3. Optional maintainer: PR / push when instructed — **no push from this lane**.

TRUTH LIVES IN:
- Write lane: `.worktrees/gllvmjl-catchup-loglik-20260801` / `catchup/loglik-oracle-20260801` @ `387d267a` (+ closeout docs tip after commit)
- Twin R: `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`
- Full parity log: `/tmp/gllvmjl-catchup-full-parity-20260801.log`
- After-tasks: `docs/dev-log/after-task/2026-08-01-gaussian-gllvmtmb-loglik-oracle.md`, `…/2026-08-01-binomial-poisson-gllvmtmb-loglik-oracle.md`, `…/2026-08-01-a4a5-nbbeta-ordinal-loglik-blocked.md` (interim), `…/2026-08-01-a4a5-catchup-loglik-oracle-close.md`
- Melissa: `docs/dev-log/plan-actual/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`

PARALLEL CHILDREN (banked):
- Ordinal impl → `b7c2cdb8`; Ordinal logLik → `10fcd484` / `3a84d8b6`
- NB2 → `5ad55877` (+ docs `b74b91f4`)
- Beta → `d666a09c` (cell) + `387d267a` (observed-Hessian green)
- Ignore confused Curvature child claiming stale-fork Beta untested — lane repaired; Beta authoritative via Beta child.

RESUME:
```
You are gllvm-jl-catchup-loglik — DONE (closeout).
READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md.
WORKSPACE: .worktrees/gllvmjl-catchup-loglik-20260801 on catchup/loglik-oracle-20260801 @ 387d267a (+ closeout commit if present).
GOAL COMPLETE: Gauss/Bin/Pois/NB2-grouped/Beta-grouped/ordinal_probit logLik oracles green.
Fenced: #129/#128; ADEMP; coverage; “full family parity”; n_drift≠parity.
No push unless maintainer instructs. Prefer FRESH TASK for next work.
```

CONTINUE HERE vs START A FRESH TASK: **FRESH TASK** — catch-up logLik oracle goal is complete; do not re-open Beta curvature.
