# Ultra-plan — none-dep-identity-20260818 (pointer; not a new seven-arc plan)

**Status:** G0 already approved as **parity-beyond Phase C item 1**.
**This file is a one-page pointer.** Do not expand it into a second
programme. Do not invent arcs beyond Identity → STOP.

## Parent (authoritative WHAT)

- Programme GOAL:
  `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818/LOOP/GOAL.md`
  **Phase C — covariance grammar**, cheapest first = **`none × dep()`**.
- Frozen parent plan:
  `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818/LOOP/ultra-plan.md`
  arc **C** (item 1 of the planned covariance walk).
- Gap sheet (planned, not paid):
  `docs/dev-log/plans/2026-08-16-gllvmtmb-capability-gap.md`
  — `none × dep (unstructured trait cov, no LV)` | twin exported | Julia
  **planned**.
- Live ledger row (do **not** edit this run):
  `docs/design/capability-status.md` **L47** stays **`planned`**.
  Exact quote: `| none × dep (`dep()` / unstructured trait covariance) | planned |`
  #258 / #259 own that file.

## Twin pin (read-only; CLOSED)

- Repo: `gllvmTMB` `origin/main` **`b8a1891a`** (Merge #1139).
- Blob `R/brms-sugar.R` = **`e1922dbf`**.
- L6–14 grid; **L10** `none | indep() | dep() | latent()`.
- L32 Cholesky \(\boldsymbol\Sigma = \mathbf{L}\mathbf{L}^\top\).
- **L1721** `dep <- function(formula) {`.
- **L1661–1662** \(T(T+1)/2\) via Cholesky; **L1681–1682** PSD + count.
- **L1694–1698** documents over-parameterised `dep`+`latent`; documents
  that a fit raises `cli_abort`. The abort **body is not in this file**
  (parser `.dep = TRUE` at L4193–4200; guards elsewhere / `fit-multi.R`).
- **L1787** `phylo_dep` — **not this slice**.

## Julia pin (CLOSED)

- Base: `origin/main` **`3d5acba0`**.
- `git grep -n 'dep(' 3d5acba0 -- src/` empty (exit 1).
- Packing cite only: `rr_theta_len(p,K) = p*K - K*(K-1)/2`; at \(K=p\)
  this is \(p(p+1)/2\).
- Lane: `cursor/lane-none-dep-identity-20260818`
  at `~/local-scratch/lanes/GLLVM.jl-lane-none-dep-identity-20260818`.
- This run: **docs-only Identity**. No `src/`. No engine G0.

## Arc this lane may run

1. **Identity** — ACCEPTED note + closed twin/Julia cites + check-log +
   after-task.
2. **STOP** — sibling push/PR is the OPEN GATE. No merge. No engine.
