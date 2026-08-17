# Arcs — G0-approved estimator+covariance HEADLINE (this `/goal` only)

Status: todo / doing / done / blocked / deferred. Gate = needs a human before it can proceed.

| # | arc | dep | status | gate? |
|---|-----|-----|--------|-------|
| A0 | Wait/recon PR #251 (`17857481`). `git fetch origin main`; `gh pr view 251` / `gh pr checks 251`. This lane does **not** merge. Read-only recon allowed while waiting. | — | blocked | OPEN GATE: this lane does not merge #251. CI still IN_PROGRESS (not fully SUCCESS). Do not merge. |
| A1 | After `17857481` is an ancestor of `origin/main`: merge/rebase `origin/main` into `claude/lane-aghq-stage1b`. Implement Hopper A4(2): extend `aghq_stage1a_loglik_site`; `z_ij = ẑᵢ + Lᵢ^{-T} uⱼ` (no √2); `log Lᵢ = logdet_i + logsumexp(logw + inner_ll)`; k=1 remains the template golden; fail-loud `_aghq_stage1a_reject_extra`; `test/test_aghq_adapt.jl`. No public `aghq=`; ledger rows stay `missing`; no `_gauss_hermite`. | A0 | todo | Blocked until #251 is on `origin/main`. |
| A2 | Verify Mac-light: `export PATH="$HOME/.juliaup/bin:$PATH"`; `julia --project=. --startup-file=no test/test_aghq_adapt.jl` (and `test/test_aghq_grid.jl` if present). Paste tally. k=1 still ≡ Laplace. | A1 | todo | — |
| A3 | check-log + after-task. A4(2) PR-ready. Overwrite checkpoint with RESUME. | A2 | todo | OPEN GATE: push/PR. `lane_launch` DENIES `git push` and `gh pr merge`. STOP. |

## Deferred / not this run (Q1 STOP)

| # | arc | status | note |
|---|-----|--------|------|
| A4(3) | Structural-gate Identity then engine | deferred | Later `/goal`. Q2: no disjoint worktree now. |
| A4(4) | Adaptation loop + convergence verdict | deferred | After A4(3). |
| A4(5) | Report honesty (`used`, `k`, engine label) | deferred | Earliest public `aghq=` discussable. |
| leftover-1 | `none × dep()` Identity then engine | deferred | Q3: first leftover after A4(5). |
| leftover-2 | CV Identity (no `crossval=` stub) | deferred | Q3: after `none × dep()`. |

Do **not** execute the frozen 2026-08-01 logLik-oracle LOOP notes under `LOOP/notes/`.
