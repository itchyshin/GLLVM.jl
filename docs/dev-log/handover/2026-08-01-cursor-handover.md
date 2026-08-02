# Session Handoff: Catch-up logLik oracle → Cursor (next R-parity lane)

Meta: 2026-08-01 ~15:45 MDT · from Cursor (Ada) · target Cursor · context N/A (docs closeout)

You are Cursor, picking up GLLVM.jl after the **catch-up light gllvmTMB logLik
oracle** arc. You inherit **no chat context**. Read files, then classify every
item below `OWED` · `DONE` · `RETRACTED` · `PROTECTED` and execute **only OWED**.

## Critical Context

1. **GOAL DONE** on branch `catchup/loglik-oracle-20260801` @ **`def576c6`**
   (pushed to `origin`). Full opt-in parity suite **63/63**. Do not re-open
   NB2/Beta/ordinal observed-Hessian curvature work.
2. **Claim boundary (Rose):** named-route light logLik oracles only — **not**
   “full family parity.” `n_drift=0` is ledger hygiene only and **≠** this work.
3. **Wrong tree hazard:** Dropbox checkout
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` may still be on stale
   `claude/jl-bridge-capabilities-20260619` @ `6694f43d`. Authoritative write
   lane for finished work is the worktree below — never code catch-up follow-ons
   on that fork.
4. **Recommended next lane (Shinichi asked about continuing toward R parity):**
   make **default-route** NB2/Beta per-trait φ match the twin (parity entry today
   is **grouped** `1:p` only), then X-cells / further surface. Prefer a **fresh
   Cursor `/goal` task**, not reopening this closed GOAL.

## Goals / Mission

- Package mission: Julia twin of R `gllvmTMB` — honest parity, speed, no silent
  claim inflation (`AGENTS.md` / `CLAUDE.md`).
- This arc’s mission (closed): live light logLik/objective oracles vs gllvmTMB
  for Gauss → Bin → Pois → NB2(grouped) → Beta(grouped) → ordinal_probit.
- Beyond this handoff: continue R-parity catch-up without ADEMP/coverage/Totoro–
  DRAC campaigns and without promoting fenced CI issues (#129/#128).

## Plans / Roadmap (beyond immediate next)

- Default shared-dispersion NB2/Beta → per-trait φ alignment with R public surface
  (today’s cells use `fit_*_gllvm_grouped(...; group=1:p)`).
- Optional: ordinal-logit twin cell (R oracle cell is **probit-only**).
- Later: X / covariate cells; keep #129 (CI scale) / #128 (H² denom) fenced until
  a dedicated inference lane.
- Phylo Model A redesign remains a **deferred sibling menu** (not this arc) —
  see Active-Lane-Split below; do not orphan it.

## What Was Accomplished

Live light gllvmTMB logLik oracles green on named routes (evidence log
`/tmp/gllvmjl-catchup-full-parity-20260801.log`):

| Family | Route | ΔlogLik (jl − r) | Pass |
|---|---|---:|---|
| Gaussian | centred, `unique=FALSE` | ≈ 9.78e-9 | 30/30 |
| Binomial | Bernoulli logit | ≈ 1.82e-10 | 6/6 |
| Poisson | log | ≈ 6.75e-9 | 6/6 |
| NB2 | `fit_nb_gllvm_grouped` `group=1:p` + **observed** Hess. | ≈ −2.50e-4 | 8/8 |
| Beta | `fit_beta_gllvm_grouped` `group=1:p` + **observed** Beta/logit Hess. | ≈ +5.97e-9 | 8/8 |
| Ordinal | **`ordinal_probit`** + **observed** Hess. (not logit) | ≈ 5.48e-9 | 5/5 |
| **Total** | | | **63/63** |

Also: A0 drift `n_drift=0` / `unregistered=0`; A2b JuliaCall bridge transport
smoke PASS; Melissa plan-actual CLOSED; LOOP GOAL marked COMPLETE.

Honest route boundaries:

- NB2/Beta parity entries are **grouped per-trait** dispersion — not shared-`r` /
  shared-`φ` defaults.
- Ordinal twin cell is **cumulative probit** with observed Laplace curvature;
  ordinal-logit is not claimed.
- Observed-Hessian Laplace for NB2/Beta/ordinal (Fisher scoring ≠ TMB AD).

## Current Working State

- Working: catch-up branch clean at tip except one untracked attach scratch
  (CARRIED-OVER below). Tip matches `origin/catchup/loglik-oracle-20260801`.
- Working: twin R `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`.
- In progress: **none** on this GOAL — closed.
- Not working / blocked for *this* arc: N/A (complete). Next parity work is a
  **new** lane.
- Dropbox main checkout: dirty stale-fork tree + stashes — **leave alone**
  (PROTECTED / out of lane).

## Key Decisions & Rationale

- Align Julia dispersion/cuts toward R public surface via **parity routes**
  (grouped 1:p; ordinal_probit) rather than claiming default fitters.
- Use **observed** Laplace Hessian for NB2/Beta/ordinal to match TMB curvature;
  closeout restored NB2 `hessian=:observed` after an earlier bank omitted the
  engine hunk (suite had regressed to Δ≈+0.218).
- Fence #129/#128, ADEMP, coverage, Totoro/DRAC, and “full family parity.”
- Platform for this arc was Cursor; next default executor remains Cursor unless
  a slice truly needs isolated live-toolchain elsewhere.

## Landing State

Gate (`~/shinichi-brain/tools/handoff_gate.sh` on the catch-up worktree) reported
FAIL before this handoff (untracked scratch + other-branch unpushed noise).
Annotated ledger:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| GLLVM.jl `catchup/loglik-oracle-20260801` @ `def576c6` (engine + docs close) | y | y (`origin`) | none | **LANDED** |
| This handover + coordination/phase-snapshot + AGENTS snapshot pointer (this commit) | y (with this commit) | y (push-as-you-go) | none | **LANDED** (docs) |
| `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md` (untracked attach note) | n | n | none | **CARRIED-OVER** — local attach scratch only; do not stage. Resume: leave untracked or delete locally; never `git add` it into a parity commit. |
| Dropbox checkout `claude/jl-bridge-capabilities-20260619` dirty + stashes (`stash@{0}` preserve-before-Beta-attach; `stash@{1}` temp) | n | n | none | **CARRIED-OVER / PROTECTED** — not this lane. Resume: ignore; do not pop/apply into catch-up worktree. |
| Other local unpushed historical branches (gate “29 UNPUSHED…”) | mixed | n | various | **CARRIED-OVER** — out of scope for catch-up closeout; do not land from this handoff. |

## Files Created / Modified

From `git diff --name-only origin/main...catchup/loglik-oracle-20260801` plus
this handoff’s docs:

- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`
- `LOOP/notes/A0-bridge-transport-inventory.md`, `A1-correctness-inventory.md`,
  `A2-rcall-callshape-audit.md`, `A2b-bridge-smoke-prep.md`,
  `optional-cran-gllvm-extractors.md`
- `docs/dev-log/plans/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`
- `docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md`,
  `2026-08-01-gaussian-rcall-shape.md`
- `docs/dev-log/plan-actual/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`
- `docs/dev-log/after-task/2026-08-01-gaussian-gllvmtmb-loglik-oracle.md`,
  `…-binomial-poisson-…`, `…-a4a5-nbbeta-ordinal-loglik-blocked.md` (interim),
  `…-a4a5-catchup-loglik-oracle-close.md`
- `docs/dev-log/check-log.md`
- `src/bridge.jl`, `src/families/fit_gllvm.jl`, `src/families/grouped_dispersion.jl`,
  `src/families/ordinal.jl`, `src/postfit.jl`
- `test/parity/*` (helpers, runparity, Gaussian/Bin/Pois/NB2/Beta/ordinal_probit)
- `test/test_ordinal_fit.jl`, `test/test_ordinal_pertrait.jl`
- **This handoff:** `docs/dev-log/handover/2026-08-01-cursor-handover.md`,
  `docs/dev-log/coordination-board.md`, `docs/dev-log/phase-snapshot.md`,
  `AGENTS.md` (Phase-state snapshot pointer only)

Detail lives in after-tasks — do not duplicate long numbers; cite them.

## Next Immediate Steps (OWED)

Ordered; classify before acting:

1. **DONE (do not redo):** catch-up logLik GOAL; observed-Hessian NB2/Beta/ordinal;
   63/63 suite on tip `def576c6`.
2. **OWED — fresh lane (recommended default):** plan + execute **default-route
   per-trait φ** for NB2 and Beta so shared-dispersion public fitters can be
   twin-parity entries (today only grouped routes are green). Start from
   `origin/main` or rebase/merge catch-up branch when maintainer wants it on
   main; keep Rose claim fence.
3. **OWED — optional later:** X / covariate light logLik cells; ordinal-logit
   twin cell only if R surface warrants it.
4. **PROTECTED / fenced:** #129, #128; ADEMP; coverage campaigns; Totoro/DRAC
   for this parity track; advertising “full family parity.”
5. **PROTECTED:** Dropbox stale-fork dirty tree + stashes; untracked
   `2026-08-01-worktree-attach.md`.
6. **Deferred sibling (carry forward):** Phylo Model A redesign —
   `docs/dev-log/handover/2026-06-30-codex-handover.md` (not next for R logLik
   catch-up; listed on Active-Lane-Split so it is not orphaned).

## Blockers / Open Questions

- Maintainer: merge/PR timing for `catchup/loglik-oracle-20260801` onto
  `origin/main` (no auto-merge from this handoff).
- Whether default-route φ work should land as a new branch from `origin/main`
  cherry-picking catch-up commits, or by opening a PR from this catch-up tip.

## Gotchas & Failed Approaches

- Do **not** use Dropbox `claude/jl-bridge-capabilities-20260619` as restart base.
- Do **not** treat `n_drift=0` as fit/logLik parity.
- Do **not** compare raw loadings Λ (rotation); use logLik / Σ_y / σ_eps.
- Do **not** run full `devtools::test(filter="julia-bridge")` with
  `GLLVM_JL_PATH` set — file continues into heavy `engine="julia"` fits after
  the drift smoke.
- Shared-dispersion NB2/Beta defaults and ordinal-logit are **not** the green
  twin entries — re-claiming them without new cells will fail Rose.
- Earlier NB2 green bank without the engine `hessian=:observed` hunk looked
  green then regressed — always verify live Δ, not only prior check-log text.

## Multi-lane / snapshot

Active-Lane-Split: `docs/dev-log/coordination-board.md`.  
Phase pointer: `docs/dev-log/phase-snapshot.md` → board (not a single-lane
orphan). Phylo Model A deferred menu carried forward on the board and in
`AGENTS.md` snapshot history.

## Mission-control summary

| Repo | Branch / tip | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| GLLVM.jl | `catchup/loglik-oracle-20260801` @ `def576c6` | not claimed this closeout; verify before merge | Light gllvmTMB logLik oracles 63/63 on named routes | Next: default-route NB2/Beta per-trait φ parity lane |
| gllvmTMB (twin, read-only engine) | `/tmp/…` @ `cee55a07` | — | Oracle partner | Keep main tip; no R engine surgery |

## How to Resume

### Live environment

```sh
# Worktree (authoritative for catch-up tip)
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
git status -sb && git rev-parse --short HEAD   # expect catchup/… @ def576c6

export PATH="$HOME/.juliaup/bin:$PATH"         # julia 1.10.x (local: 1.10.0)
export JULIA_HOME="${JULIA_HOME:-$HOME/.juliaup/bin}"
export GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"

# Twin R (bridge / oracle partner)
# /tmp/gllvmtmb-parity-restart-20260801 @ cee55a07
# R ≥ 4.2 on PATH (local: R 4.6.0 at /usr/local/bin/R)
```

### Safe verification (catch-up tip)

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
# expect 63/63; compare ΔlogLik numbers, not exit codes alone
# optional core: julia --project=. test/runtests.jl
# full CI suite: julia --project=. -e 'using Pkg; Pkg.test()'
```

### Preflight / rehydrate order

1. `bash ~/shinichi-brain/tools/lane_preflight.sh` (or repo equivalent when present).
2. `git status` + `git rev-parse --short HEAD` + `gh run list --limit 3`.
3. Read `AGENTS.md` → this handoff → `docs/dev-log/coordination-board.md` →
   `LOOP/GOAL.md` + `LOOP/checkpoint.md` (GOAL COMPLETE) →
   `docs/dev-log/after-task/2026-08-01-a4a5-catchup-loglik-oracle-close.md`.
4. Classify OWED/DONE/RETRACTED/PROTECTED; continue **only OWED** (prefer fresh
   `/goal` for default-route φ).

### Do not stage

- `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md`
- Anything under Dropbox stale-fork dirty tree / `.claude/preview/*` churn
- Foreign untracked agent mirrors unless the lane owns them
- Never `git add -A` / `git add .`

### Paste-ready resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-01-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
