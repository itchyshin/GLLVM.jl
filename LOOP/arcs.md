# Arcs — G0-approved estimator+covariance HEADLINE (this `/goal` only)

Status: todo / doing / done / blocked / deferred. Gate = needs a human before it can proceed.

| # | arc | dep | status | gate? |
|---|-----|-----|--------|-------|
| A0 | Wait/recon PR #251 (`17857481`). `git fetch origin main`; `gh pr view 251` / `gh pr checks 251`. This lane does **not** merge. Read-only recon allowed while waiting. | — | blocked | OPEN GATE: this lane does not merge #251. CI still IN_PROGRESS (not fully SUCCESS). Do not merge. |
| A1 | After `17857481` is an ancestor of `origin/main`: merge/rebase `origin/main` into `claude/lane-aghq-stage1b`. Implement Hopper A4(2): extend `aghq_stage1a_loglik_site`; `z_ij = ẑᵢ + Lᵢ^{-T} uⱼ` (no √2); `log Lᵢ = logdet_i + logsumexp(logw + inner_ll)`; k=1 remains the template golden; fail-loud `_aghq_stage1a_reject_extra`; `test/test_aghq_adapt.jl`. No public `aghq=`; ledger rows stay `missing`; no `_gauss_hermite`. | A0 | todo | Blocked until #251 is on `origin/main`. |
| A2 | Verify Mac-light: `export PATH="$HOME/.juliaup/bin:$PATH"`; `julia --project=. --startup-file=no test/test_aghq_adapt.jl` (and `test/test_aghq_grid.jl` if present). Paste tally. k=1 still ≡ Laplace. | A1 | todo | — |
| A3 | check-log + after-task. A4(2) PR-ready. Overwrite checkpoint with RESUME. | A2 | todo | OPEN GATE: push/PR. `lane_launch` DENIES `git push` and `gh pr merge`. STOP. |

## Deferred / not this run (Q1 STOP)

Q2 sequential: no disjoint worktree for leftovers or A4(3). Do **not** start leftover-1 / leftover-2 in this `/goal`. Do **not** write Identity decision files now.

After **this** `/goal` STOP (A4(2) PR-ready), the next leftover Identities are:

| # | arc | status | note |
|---|-----|--------|------|
| leftover-1 | `none × dep()` Identity then engine | deferred | **First leftover after A4(2) STOP.** Twin `dep()` at `R/brms-sugar.R` ~1653. Julia `docs/design/capability-status.md` row is `planned`. No `dep` symbol under `src/`. Do **not** confuse with slope Σ_b. |
| leftover-2 | CV Identity | deferred | After leftover-1. Twin internals `.cv_run` / `.cv_score` — **not** a NAMESPACE `crossval` export. Julia has no `crossval` symbol. No `crossval=` stub. |

Later AGHQ rungs (not leftovers; still not this run):

| # | arc | status | note |
|---|-----|--------|------|
| A4(3) | Structural-gate Identity then engine | deferred | Later `/goal`. **Out of this run.** Q2: no disjoint worktree now. |
| A4(4) | Adaptation loop + convergence verdict | deferred | After A4(3). |
| A4(5) | Report honesty (`used`, `k`, engine label) | deferred | Earliest public `aghq=` discussable. |

## Out of the leftover inventory (do not start)

- Tweedie `fit_gllvm` admit
- multinomial campaign
- AGHQ public knob (`aghq=`)
- invented twin Δ
- A4(3) in this run
- coverage certificate / Totoro (only if Shinichi sizes it later)

Do **not** execute the frozen 2026-08-01 logLik-oracle LOOP notes under `LOOP/notes/`.
