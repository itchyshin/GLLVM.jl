# GOAL — nb2-beta-x-arc2 (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Solo platform: **Cursor**. NB2+X and Beta+X light gllvmTMB logLik parity cells
green at rtol 1e-6 in `test/parity/test_x_covariate_parity.jl`, using Arc 1
`fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` (group=1:p, default
`hessian=:observed` — no engine changes expected).

## Headline

Close the twin gap: shared site-X parity exists for G/Bin/Pois (#170) and
per-trait+X fits in Julia (#175, merged to `main` @ `9f5133a7`) — Arc 2 proves
agreement vs live gllvmTMB.

## Invariants

- One write lane: worktree `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802` on
  branch `parity/nb2-beta-x-arc2-20260802` from post-merge `origin/main`
  (tip at plan time `9f5133a7`).
- R twin lib reuse: `/tmp/R-gllvmtmb-x-parity-20260802/gllvmTMB` (SHA recorded
  in checkpoint.md).
- **FORBIDDEN:** Gamma+X, Ordinal+X, species-specific XB, X_lv, ADEMP/coverage,
  Phylo Model A, shared-φ-Julia-vs-per-trait-R comparisons, "full family
  parity" claims, Dropbox protected-checkout writes, `git add -A`, push/PR
  without a further ask after Arc 2 local commits.
- rtol 1e-6 fixed — no silent widen. If DGP/R warning (Heywood etc.), repair
  seed/loadings/n, not tol.
- Julia call: `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` with
  `X`, `K`, `group=collect(1:p)`, **DEFAULT hessian (`:observed`)** — NOT
  `:fisher` (that was only for the Arc 1 identity tests vs shared
  `fit_gllvm_cov`, a different estimand).
- Verify by reading the printed Δ logLik, not exit codes.
- Light cells run on laptop/Totoro-class compute (no DRAC/large grid).

## Authoritative WHAT

→ `LOOP/ultra-plan.md` (frozen copy of the approved plan:
`docs/dev-log/plans/2026-08-02-nb2-beta-x-arc2-ultra-plan.md`). Detail wins
there; this file wins on "what must never be lost."

## Definition of done

1. `test/parity/parity_helpers.jl` `fit_gllvmtmb_parity_loglik_x` extended for
   `:negbinomial` and `:beta`.
2. Two new `@testset`s in `test/parity/test_x_covariate_parity.jl`: "NB2 +
   shared X (q=1)" and "Beta + shared X (q=1)", both green at rtol 1e-6.
3. Live run evidence: `GLLVM_PARITY_TESTS=1 julia --project=test/parity
   test/parity/runparity.jl` — Δ logLik printed and Pass for both cells.
4. Full suite green: `julia --project=. -e 'using Pkg; Pkg.test()'`.
5. Docs closed out: `test/parity/README.md`, `docs/design/capability-status.md`,
   `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`.
6. After-task at `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`
   (Rose verdict + Δ numbers) and plan-actual at
   `docs/dev-log/plan-actual/2026-08-02-nb2-beta-x-arc2.md`.
7. Staged by explicit path only; committed locally. Push/PR is an OPEN GATE —
   stop after commit and ask.
