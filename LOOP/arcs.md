# Arcs — G0-approved estimator+covariance HEADLINE (this `/goal` only)

Status: todo / doing / done / blocked / deferred. Gate = needs a human before it can proceed.

This `/goal` is **DONE**. Q1 held: wait #251 + A4(2) only; STOP when A4(2) is PR-ready. That landed as PR #252 (`17f4a415`, 2026-08-17T22:48:06Z). Do **not** start A4(3) or leftover Identity from these files.

| # | arc | dep | status | gate? |
|---|-----|-----|--------|-------|
| A0 | Wait/recon PR #251 (`17857481`). `git fetch origin main`; `gh pr view 251` / `gh pr checks 251`. This lane does **not** merge. Read-only recon allowed while waiting. | — | done | Closed: `17857481` is an ancestor of `origin/main` (merge `fc845404`). This lane did not merge #251. |
| A1 | After `17857481` is an ancestor of `origin/main`: merge/rebase `origin/main` into `claude/lane-aghq-stage1b`. Implement Hopper A4(2): extend `aghq_stage1a_loglik_site`; `z_ij = ẑᵢ + Lᵢ^{-T} uⱼ` (no √2); `log Lᵢ = logdet_i + logsumexp(logw + inner_ll)`; k=1 remains the template golden; fail-loud `_aghq_stage1a_reject_extra`; `test/test_aghq_adapt.jl`. No public `aghq=`; ledger rows stay `missing`; no `_gauss_hermite`. | A0 | done | Closed: A4(2) landed as PR #252 merge `17f4a415`. Head `c3670cec`. Mac-light 17/17 + 70/70; independent review PASS; full CI SUCCESS. |
| A2 | Verify Mac-light: `export PATH="$HOME/.juliaup/bin:$PATH"`; `julia --project=. --startup-file=no test/test_aghq_adapt.jl` (and `test/test_aghq_grid.jl` if present). Paste tally. k=1 still ≡ Laplace. | A1 | done | Closed with A1: adapt 17/17; grid 70/70; k=1 ≡ Laplace. |
| A3 | check-log + after-task. A4(2) PR-ready. Overwrite checkpoint with RESUME. | A2 | done | Closed: after-task `2026-08-17-aghq-stage1b-adapt.md`; #252 merged. This `/goal` STOP. |

## Deferred / not this run (Q1 STOP)

Q2 sequential: no disjoint worktree for leftovers or A4(3). Do **not** start leftover-1 / leftover-2 in this closed `/goal`. Do **not** write Identity decision files from this run.

After **this** `/goal` STOP (A4(2) now on `origin/main`), the next leftover Identities need a **new `/goal`**:

| # | arc | status | note |
|---|-----|--------|------|
| leftover-1 | `none × dep()` Identity then engine | todo | **First leftover after A4(2) STOP. New `/goal`, not this run.** Twin `dep()` at `R/brms-sugar.R` ~1653. Julia `docs/design/capability-status.md` row is `planned`. No `dep` symbol under `src/`. Do **not** confuse with slope Σ_b. |
| leftover-2 | CV Identity | todo | After leftover-1, later `/goal`. Twin internals `.cv_run` / `.cv_score` — **not** a NAMESPACE `crossval` export. Julia has no `crossval` symbol. No `crossval=` stub. |

Later AGHQ rungs (not leftovers; still not this run):

| # | arc | status | note |
|---|-----|--------|------|
| A4(3) | Structural-gate Identity then engine | deferred | Later `/goal`. **Out of this run.** Q1 STOP. Q2: no disjoint worktree now. |
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
