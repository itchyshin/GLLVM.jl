# Gamma+X Arc 2 — light RCall parity cell — Ultra Plan

> **G0:** Shinichi approved this known follow-on (mirror NB2/Beta Arc 2) in the
> same turn as `/ultra-plan then /goal`. Do **not** redo Arc 1 engine.
> Execute immediately after this plan lands.

```text
🎯 GOAL
PLATFORM = Cursor (Ada executing this approved Arc 2 in the gamma engine
worktree — not a fresh planning-only chat).
DELIVERABLE = one Gamma+X light gllvmTMB logLik parity cell green at rtol
1e-6 in test/parity/test_x_covariate_parity.jl, calling Arc 1
fit_gamma_gllvm_grouped_cov (group=collect(1:p), default hessian=:observed —
NOT :fisher).
HEADLINE = Prove Julia per-trait α + shared site-X agrees with live
gllvmTMB ordinary Gamma under shared +x (stats::Gamma(link="log") /
log_phi_gamma).
IN PARALLEL = LOOP scaffold · extend fit_gllvmtmb_parity_loglik_x for :gamma ·
confirm R + gllvmTMB 0.6.0.
DEFER = Arc 1 engine redesign; Option B no-X flip; Ordinal+X; X_lv; ADEMP;
Phylo Model A; #177 merge/conflict resolve; Dropbox checkout writes;
git add -A; push without ask; "full family parity"; NB2/Beta X cells on
this tip (owned by #177).
DISCIPLINE = rtol 1e-6 fixed · prefer DGP/seed repair · verify by printed
Δ logLik · laptop compute · stage by path · after-task + surgical
check-log · Rose fence ≠ full family parity.
```

**ARC PROGRAM:** size mode. Recommended **1–2 h**. Analogue: NB2/Beta Arc 2
after-task (2 cells + DGP repair); Gamma is one cell on an unpushed engine tip.

---

## Phase 0.25 — Prior-work sweep receipt

| Surface | Evidence | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb` + `rev-parse` in `.worktrees/gllvmjl-gamma-x-grouped-cov-20260803` → `fix/gamma-x-grouped-cov-20260803` @ `ca2b2c0b`; `branch_drift_check.sh` → **5 ahead / 0 behind** `origin/main`; `git worktree list` shows Arc 1 wt + `gllvmjl-nb2-beta-x-arc2-20260802` @ #177 tip; `gh pr list` → #177 OPEN | Arc 1 engine + identity + docs local-done, not pushed; #177 CONFLICTING — fence | **resume** engine tip; **build-the-gap** = Gamma+X light cell only; **do not** merge #177 |
| **twin** | `Rscript` → gllvmTMB **0.6.0** at `~/Library/R/arm64/4.6/library/gllvmTMB`; `/tmp/R-gllvmtmb-x-parity-20260802` present; twin docs: `stats::Gamma(link="log")` + `PARAMETER_VECTOR(log_phi_gamma)` | Live oracle available; ordinary Gamma = per-trait shape | **reuse** R install; family switch = `stats::Gamma(link="log")` |
| **sister pattern** | Read `#177` worktree `test_x_covariate_parity.jl` NB2/Beta cells + after-task `2026-08-02-nb2-beta-x-arc2-parity.md`; gamma tip X helper still `(:gaussian,:binomial,:poisson)` only | Exact cell shape + DGP-repair lesson (rtol never widened) | **co-opt** NB2/Beta Arc 2 pattern for **one** Gamma cell |
| **brain** | `search_notes("Gamma+X Arc 2 RCall light logLik parity", search_all_projects=true)` + grep `AGENT_LOG`/`DECISIONS` for gamma.?x / nb2.?beta.?x | No conflicting vault lock; load-bearing truth is in-repo after-tasks + decision | **reuse** repo docs; gap = RCall cell |
| **Verdict** | — | Genuinely new = (a) `:gamma` in `fit_gllvmtmb_parity_loglik_x`, (b) one `@testset`, (c) live Δ evidence, (d) narrow docs. No `src/` unless bug blocks. | **build-the-gap** |

**Gate cleared.** G0 granted by owner for this follow-on.

---

## Phase 0.3 / 0.3b

Cursor execution on **Cursor Models** for helper/cell/run; Rose/Melissa judgment
light. No multi-agent fan-out. **LUNA SUITABILITY: no** — live RCall likelihood
judgment + DGP repair.

**Totoro or DRAC?** Neither — one light cell (p≈5, n≈80–120, K=1), laptop.

---

## Phase 1 — Decomposition

| # | Slice | Output | Dep |
|---|---|---|---|
| S0 | Continue on `fix/gamma-x-grouped-cov-20260803` (unpushed tip OK) + scaffold `lanes/gamma-x-arc2-20260803/LOOP/` | LOOP kit | none |
| S1 | Confirm R + gllvmTMB | SHA/version note | none |
| S2 | Extend `parity_helpers.jl` X helper for `:gamma` | `stats::Gamma(link="log")` | S0 |
| S3 | Add Gamma+X `@testset` | `group=collect(1:p)`, default hessian | S1,S2 |
| S4 | Live `GLLVM_PARITY_TESTS=1 … runparity.jl` | pasted Δ | S3 |
| S5 | DGP repair if needed | seed/K/n/α — **not** rtol | S4 cond. |
| S6 | Docs: README, capability-status, surgical check-log, board (fence #177 hunks), after-task | closeout | S4/S5 |
| S7 | Rose + Melissa light reconcile | plan-actual | S6 |
| S8 | Commit by path; **no push** | local SHA | S7 |

**Parallel:** S1 ∥ S2. Sequential: S0 → {S1,S2} → S3 → S4 → (S5) → S6 → S7 → S8.

---

## Phase 2 — Slice table

| Slice | Member | Model / Bar | Time | Dep |
|---|---|---|---|---|
| S0–S5 | Ada/Hopper/Curie | Cursor Models | ~90 min | as above |
| S6–S7 | Rose/Melissa | judgment light | ~20 min | S4/S5 |
| S8 | Ada | Cursor Models | 5 min | S7 |

**ESTIMATE:** ~1.5–2 h, one session. Fits `/goal` now.

---

## DEFER fence

- No Arc 1 engine redesign / Option B flip / Ordinal+X / X_lv / ADEMP / Phylo A.
- No #177 merge or conflict resolution; avoid colliding check-log/board hunks.
- No Dropbox `claude/jl-bridge-capabilities-20260619` writes.
- No `git add -A`; no push without ask.
- No “full family parity” claim — only light Gamma+X logLik under per-trait α.

---

## Members plan-review

**Rose** — Scope correct: light cell only; #177 fenced; claim must stay ≠ full
parity. **OK.**  
**Hopper** — R family = `stats::Gamma(link="log")` (not `gllvmTMB::Gamma`); Julia
=`fit_gamma_gllvm_grouped_cov(...; group=1:p)` default `:observed`. **OK.**  
**Fisher** — Budget DGP repair (NB2/Beta Heywood lesson); never widen 1e-6. **OK.**

---

## LANE RECEIPT

`LANE: CONTINUE HERE` for execution in this session (G0 + `/goal` already
requested). After close: `START A FRESH TASK` for push/PR.

## RECONCILE

Melissa light plan-vs-actual at
`docs/dev-log/plan-actual/2026-08-03-gamma-x-arc2.md` after execution.
