# Session Handoff: Default-route NB2/Beta φ → Cursor (push/PR or next parity)

Meta: 2026-08-01 ~17:52 MDT · from Cursor (Ada) · target Cursor · AUTHOR=cursor · context N/A (docs closeout)

You are Cursor, picking up GLLVM.jl after the **default-route NB2/Beta per-trait φ**
lane closed locally. You inherit **no chat context**. Read files, then classify
every item below `OWED` · `DONE` · `RETRACTED` · `PROTECTED` and execute
**only OWED**. Do **not** reopen the φ routing implementation.

Sibling handovers (do not orphan):

- Catch-up logLik closeout (DONE): `docs/dev-log/handover/2026-08-01-cursor-handover.md`
- Phylo Model A deferred: `docs/dev-log/handover/2026-06-30-codex-handover.md`
- Multi-lane board: `docs/dev-log/coordination-board.md`

## Critical Context

1. **Lane COMPLETE locally** on `parity/default-route-phi-20260801` @ **`ccd55f1f`**
   (verified at handoff writing). Public `fit_gllvm(NB/Beta)` defaults to
   per-trait φ (API B / Curie: `disp_group === nothing` → `:species`). Named
   `fit_nb_gllvm` / `fit_beta_gllvm` remain shared-φ engines. **Do not reopen
   φ implementation.**
2. **Live parity 63/63** on the public default path (`/tmp/default-route-phi-parity.log`):
   NB2 Δ≈−2.50e-4, Beta Δ≈+5.97e-9 (prior catch-up bands; no tol widen).
3. **Unpushed / no PR.** Branch has **no upstream**. Gate FAIL is expected until
   maintainer asks to push + open PR. **Do not push or auto-merge** without
   explicit instruction.
4. **Rose fence:** default-route / named-route **light logLik only** — **not**
   full family parity. Catch-up GOAL earlier DONE @ `bbf5d7d8` / engine close
   `def576c6` (pushed) — do not overwrite closed catch-up LOOP.
5. **Wrong tree hazard:** Dropbox checkout
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` may still be on stale
   `claude/jl-bridge-capabilities-20260619` — **PROTECTED**; never code here.

## Goals / Mission

- Package mission: Julia twin of R `gllvmTMB` — honest parity, speed, no silent
  claim inflation (`AGENTS.md` / `CLAUDE.md`).
- This arc’s mission (closed locally): public NB2/Beta default route matches
  twin per-trait φ; light parity cells retargeted to plain `fit_gllvm`.
- Beyond this handoff: land the branch on GitHub when asked; optional later
  X/covariate light logLik cells via a **fresh** `/goal` after ultra-plan.

## Plans / Roadmap (beyond immediate next)

- **Primary:** push + PR for `parity/default-route-phi-20260801` (no auto-merge).
- **Optional later:** X / covariate light logLik cells (new ultra-plan + `/goal`).
- **Optional separate bug lane:** `test_grouped_dispersion.jl:61` one-group NB ≈
  shared fail (engines unchanged on φ lane — do **not** fold into φ PR claim).
- Keep #129/#128, ADEMP, coverage, Totoro/DRAC fenced until a dedicated lane.
- Phylo Model A redesign remains a **deferred sibling menu** on the board.

## What Was Accomplished

API B routing + honesty cascade + live default-path parity. Detail:
`docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md`.

| Slice | Result |
|---|---|
| S0 | Call-site inventory |
| S1 | `fit_gllvm.jl` NB/Beta `nothing`→`:species` |
| S2 | Parity NB2/Beta cells → plain `fit_gllvm` default |
| S3 | Cascade Fit types + docs; postfit NB/Beta/Ordinal named-fitter honesty |
| S4 | Live parity **63/63**; core runtests **5063 passed / 1 failed / 0 errored / 3 broken** |
| CLOSE | LOOP `STATE=COMPLETE`; checkpoint RESUME=DONE; no push |

Parity headline (default path):

| Family | Route | ΔlogLik (jl − r) | Pass |
|---|---|---:|---|
| Gaussian | centred | ≈ 9.78e-9 | 30/30 |
| Binomial | Bernoulli logit | ≈ 1.82e-10 | 6/6 |
| Poisson | log | ≈ 6.75e-9 | 6/6 |
| NB2 | **`fit_gllvm` default** (per-trait φ) | ≈ −2.50e-4 | 8/8 |
| Beta | **`fit_gllvm` default** (per-trait φ) | ≈ +5.97e-9 | 8/8 |
| Ordinal | ordinal_probit | ≈ 5.48e-9 | 5/5 |
| **Total** | | | **63/63** |

Sole core-suite red cell: `test_grouped_dispersion.jl:61` (pre-existing;
`grouped_dispersion.jl` / `negbin.jl` unchanged vs base `bbf5d7d8`).

## Current Working State

- Working: φ lane **COMPLETE** locally @ `ccd55f1f`; LOOP checkpoint
  `STATE=COMPLETE`, RESUME=DONE.
- Working: catch-up tip `def576c6` remains **pushed** on
  `catchup/loglik-oracle-20260801` (ancestor of this branch).
- In progress: **none** on φ implementation.
- Not working / blocked for *landing*: **push/PR gated on maintainer ask**
  (branch has no `origin` tracking; `gh pr list --head` empty).
- Twin R (read-only): `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`.

## Key Decisions & Rationale

- **API B (Curie):** only NB/Beta coerce `disp_group === nothing` → `:species`;
  Gamma untouched; named shared-φ fitters retained.
- Parity cells retarget to **public** `fit_gllvm` default — not a second private
  grouped-only claim.
- Observed-Hessian work from catch-up **not reopened** (grouped path stayed green).
- Pre-existing one-group NB red cell stays out of the φ PR narrative.
- Platform: Cursor; next executor Cursor unless maintainer routes elsewhere.

## Landing State

Gate (`~/shinichi-brain/tools/handoff_gate.sh` on this worktree) **FAIL** before
this handoff: 1 untracked attach scratch; 12 unpushed commits on HEAD; other
historical branches unpushed (noise). Annotated ledger:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| GLLVM.jl `parity/default-route-phi-20260801` @ `ccd55f1f` (φ COMPLETE tip) | y | **n** (no upstream) | **none** | **CARRIED-OVER** — finished locally; maintainer must ask before push/PR. Resume: see Next Immediate Steps #1. |
| This handover + board/phase-snapshot/AGENTS pointer + checkpoint tip stamp (handover commit on same branch) | y (with this commit) | **n** until #1 | none | **CARRIED-OVER** with branch tip until push |
| GLLVM.jl `catchup/loglik-oracle-20260801` @ `def576c6` | y | y (`origin`) | none | **LANDED** (ancestor; closed — do not reopen) |
| `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md` | n | n | none | **CARRIED-OVER / PROTECTED** — leave untracked; never stage into parity/φ commits. |
| Dropbox `claude/jl-bridge-capabilities-20260619` dirty + stashes | n | n | none | **CARRIED-OVER / PROTECTED** — ignore; do not pop into this worktree. |
| Other local unpushed historical branches (gate “29 UNPUSHED…”) | mixed | n | various | **CARRIED-OVER** — out of scope; do not land from this handoff. |
| Optional bug: `test_grouped_dispersion.jl:61` | n (no fix) | n | none | **CARRIED-OVER** — separate lane only; do not mix into φ PR claim. |

### Resume commands for CARRIED-OVER rows

```sh
# φ branch (authoritative worktree)
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
git status -sb && git rev-parse --short HEAD   # expect parity/default-route-phi-20260801

# ONLY after explicit maintainer ask:
git push -u origin HEAD
gh pr create --base main --head parity/default-route-phi-20260801 \
  --title "feat: default-route NB2/Beta per-trait φ (API B)" \
  --body "$(cat <<'EOF'
## Summary
- Public `fit_gllvm(NB/Beta)` defaults to per-trait φ (`disp_group=:species`).
- Light gllvmTMB logLik oracles 63/63 on that default path (NB2 Δ≈−2.5e-4, Beta Δ≈6e-9).
- Named shared-φ fitters retained; Rose fence: light logLik only, not full family parity.

## Test plan
- [ ] `GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` → 63/63
- [ ] Confirm claim fence in PR body (not full family parity)
- [ ] Do not auto-merge

EOF
)"
# Do NOT `gh pr merge` from the agent unless maintainer explicitly asks.
```

## Files Created / Modified

φ lane vs catch-up base (`git diff --name-only bbf5d7d8...HEAD`) plus this handoff:

- `src/families/fit_gllvm.jl`
- `test/parity/README.md`, `test/parity/runparity.jl`,
  `test/parity/test_negbin_parity.jl`, `test/parity/test_beta_parity.jl`
- `test/test_fit_gllvm.jl`, `test/test_nb_fit.jl`, `test/test_beta_fit.jl`,
  `test/test_unified_api.jl`, `test/test_postfit.jl`
- `docs/src/tutorial.md`, `docs/src/response-families.md`
- `docs/dev-log/plans/2026-08-01-default-route-nb2-beta-pertrait-phi.md`
- `docs/dev-log/plans/scratch/2026-08-01-default-route-phi-callsites.md`
- `docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md`
- `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`
- `lanes/default-route-phi-20260801/LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`
- **This handoff:** `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`,
  `docs/dev-log/phase-snapshot.md`, `docs/dev-log/phase-snapshot-archive.md`,
  `AGENTS.md` (Phase-state snapshot pointer only), checkpoint tip stamp

Do not clobber `docs/dev-log/handover/2026-08-01-cursor-handover.md` (catch-up).

## Next Immediate Steps

Ordered; classify before acting:

1. **OWED (primary):** When maintainer asks — **push** `parity/default-route-phi-20260801`
   and **open PR** to `main` (no auto-merge). Prefer this as the next action.
2. **DONE (do not redo):** default-route φ API B; cascade; live 63/63 on default
   path; LOOP COMPLETE; catch-up logLik GOAL @ `def576c6`.
3. **OWED (optional later):** X / covariate light logLik cells — fresh `/goal`
   after ultra-plan; not a reopen of this LOOP.
4. **OWED (optional separate bug lane):** investigate
   `test_grouped_dispersion.jl:61` one-group NB ≈ shared — **not** part of φ PR.
5. **PROTECTED:** #129 / #128; ADEMP; coverage; Totoro/DRAC; “full family parity”;
   Dropbox stale fork; attach scratch; closed catch-up LOOP overwrite; Phylo
   Model A deferred sibling (carry forward on board).

## Blockers / Open Questions

- Maintainer must explicitly authorize **push + PR** (and later merge).
- Whether φ PR base should be `main` directly or wait for catch-up PR merge
  order — branch already contains catch-up commits; PR will include them unless
  rebased/split. Ask before rewriting history.

## Gotchas & Failed Approaches

- Do **not** reopen φ routing or observed-Hessian work “to be safe.”
- Do **not** claim full family parity or mix the grouped-dispersion red cell
  into the φ success narrative.
- Do **not** use Dropbox `claude/jl-bridge-capabilities-20260619` as write base.
- Do **not** stage `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md`.
- Do **not** overwrite root `LOOP/` catch-up files or closed catch-up GOAL.
- Unpushed branch is fragile across machines — until push, only this worktree
  holds the tip.

## Multi-lane / snapshot

Active-Lane-Split: `docs/dev-log/coordination-board.md` (catch-up DONE +
default-route-phi DONE/local + Phylo Model A deferred).  
Phase pointer: `docs/dev-log/phase-snapshot.md` → board (not a single-lane orphan).

## Mission-control summary

| Repo | Branch / tip | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| GLLVM.jl | `parity/default-route-phi-20260801` @ `ccd55f1f` (local, unpushed) | none yet (no PR) | Public NB/Beta default → per-trait φ; light parity 63/63 on default path | **OWED #1:** push + PR on maintainer ask |
| GLLVM.jl | `catchup/loglik-oracle-20260801` @ `def576c6` (pushed) | — | Named-route light logLik 63/63 | Closed; do not reopen |
| gllvmTMB (twin, read-only) | `/tmp/…` @ `cee55a07` | — | Oracle partner | No R engine surgery |

## How to Resume

### Live environment

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
git status -sb && git rev-parse --short HEAD
# expect: parity/default-route-phi-20260801 @ ccd55f1f or later handover tip

export PATH="$HOME/.juliaup/bin:$PATH"
export GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"

# Twin R (read-only oracle partner)
# /tmp/gllvmtmb-parity-restart-20260801 @ cee55a07
```

### Safe verification

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-catchup-loglik-20260801"
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
# expect 63/63; read ΔlogLik from log, not exit code alone
# optional: julia --project=. test/runtests.jl
#   known pre-existing fail: test_grouped_dispersion.jl:61
```

### Preflight / rehydrate order

1. `bash ~/shinichi-brain/tools/lane_preflight.sh`
2. `bash ~/shinichi-brain/tools/handoff_gate.sh "$(pwd)"` — declare any new unlanded rows
3. `git status` + `git rev-parse --short HEAD` + `gh pr list --head parity/default-route-phi-20260801`
4. Read `AGENTS.md` → **this** handoff → `docs/dev-log/coordination-board.md` →
   `lanes/default-route-phi-20260801/LOOP/{GOAL,checkpoint}.md` →
   `docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md`
5. Also skim catch-up handover (sibling DONE) and Phylo Model A deferred pointer
6. Classify OWED/DONE/RETRACTED/PROTECTED; continue **only OWED**

### Do not stage

- `docs/dev-log/plans/scratch/2026-08-01-worktree-attach.md`
- Dropbox stale-fork dirty tree / foreign agent mirrors
- Never `git add -A` / `git add .`

### Paste-ready resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
