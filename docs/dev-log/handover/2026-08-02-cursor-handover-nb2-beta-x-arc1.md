# Session Handoff: NB2/Beta+X Arc 1 → land #175, then Arc 2 (Cursor)

Meta: 2026-08-02 ~11:41 MDT · from Cursor (Ada) · target Cursor · AUTHOR=cursor · context N/A

You are Cursor, picking up GLLVM.jl after **Gate 0 + Arc 1** for NB2/Beta+X.
You inherit **no chat context**. Read files, then classify every item below
`OWED` · `DONE` · `RETRACTED` · `PROTECTED` and execute **only OWED**.

Sibling handovers / lanes (do not orphan):

- Multi-lane board: `docs/dev-log/coordination-board.md` (**rehydrate pointer**)
- Grouped one-group bug (MERGED #172): `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md`
- MC Julia capability-status (MERGED #173): `docs/design/capability-status.md`
- Design Arc 0 (MERGED #174): `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`
- X light logLik (MERGED #170): `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`
- Default-route φ (MERGED #169): `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`
- Phylo Model A deferred: `docs/dev-log/handover/2026-06-30-codex-handover.md`
- Dropbox stale checkout: **PROTECTED** (see Landing State)

## Mission-control summary

| Repo | Branch / tip | CI | Shipped | Next (leverage) |
|---|---|---|---|---|
| GLLVM.jl | `fix/nb2-beta-x-grouped-cov-20260802` @ `39995d8b` | #175 Documenter green; Julia pending | Gate 0 (#172/#173/#174) + Arc 1 engine | Land #175 → Arc 2 RCall cells (new `/goal`) |

## Critical Context

1. **Wrong tree hazard:** Dropbox checkout
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on
   `claude/jl-bridge-capabilities-20260619` is **PROTECTED / stale** — never
   write there. Work only from a worktree off `origin/main` (or this Arc 1
   worktree while #175 is open).
2. **Twin rule:** GLLVM.jl mirrors gllvmTMB on **API/capabilities**, not engine
   code. Bridge execution is **R→Julia only** (JuliaCall); RCall = opt-in oracle.
3. **Arc 1 shipped, not yet on `main`:** public/bridge NB2/Beta+X now route to
   per-trait `fit_*_gllvm_grouped_cov`; `fit_gllvm_cov` remains shared-φ + X
   opt-in. Julia identity green. **Do not claim Arc 2 light RCall parity.**
4. **Rose fence:** Arc 1 ≠ full family parity; ≠ Gamma+X flip; ≠ ADEMP/coverage;
   ≠ Phylo Model A.

## Goals / Mission

- Package: Julia twin of R `gllvmTMB` — honest parity, speed, no claim inflation.
- This session: Gate 0 land + Arc 1 engine (per-trait φ + shared site-X).
- Beyond: Arc 2 light RCall NB2+X / Beta+X cells at rtol `1e-6` after #175 merges.

## Plans / Roadmap (beyond immediate next)

- **Arc 2** (separate `/goal`): `test/parity/test_x_covariate_parity.jl` NB2+Beta
  cells via `fit_gllvmtmb_parity_loglik_x`; twin at fresh `origin/main` (not
  Dropbox fork). Plan: `docs/dev-log/plans/2026-08-02-nb2-beta-x-identity-ultra-plan.md`.
- Fence #129/#128, ADEMP, coverage, Totoro/DRAC unless a dedicated lane owns them.
- Phylo Model A redesign remains parked (sibling menu).

## What Was Accomplished

| Item | Result |
|---|---|
| Gate 0: #172 one-group Fisher | **MERGED** |
| Gate 0: #173 capability-status | **MERGED** |
| Gate 0: #174 design Arc 0 | **MERGED** |
| Arc 1 engine | `fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` |
| Bridge + formula route | NB/Beta+X → grouped_cov |
| Identity tests | **14/14** (`test/test_nb_beta_x_identity.jl`) |
| Bridge X / formula | **201/201** · **11/11** |
| Engine PR | [#175](https://github.com/itchyshin/GLLVM.jl/pull/175) open |

Detail: `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md`.

## Current Working State

- Working: Arc 1 tip `39995d8b` pushed; PR #175 open and mergeable; Documenter
  green; Julia CI in progress at handoff time.
- In progress: CI on #175 (watch → merge when green).
- Not working / deferred: Arc 2 RCall cells (by design).

## Key Decisions & Rationale

- Public/bridge default under X for NB2/Beta = **per-trait φ + shared site-X γ**
  (API B under X). Decision note on `main` via #174.
- Identity must force `hessian=:fisher` when comparing to `fit_gllvm_cov`
  (shared path is Fisher-Laplace; grouped default is `:observed` / TMB).
- Tolerances: G=1 fit identity `atol=1e-2`/`rtol=1e-4`; constant rvec/φvec ll
  `atol=1e-10` — **no silent widen**.

## Landing State

Gate (`tools/handoff_gate.sh`) **FAIL** on Dropbox checkout dirty state — declared
below. Arc 1 worktree itself is clean vs its remote tip after this handover commit.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `fix/nb2-beta-x-grouped-cov-20260802` @ `39995d8b` (+ this handover) | y | y (push with this commit) | [#175](https://github.com/itchyshin/GLLVM.jl/pull/175) open | **LANDED** on feature branch; await CI merge to `main` |
| `main` @ `c4c46293` (#172/#173/#174) | y | y | merged | **LANDED** |
| Dropbox `claude/jl-bridge-capabilities-20260619` (dirty + unpushed history) | n | n | none | **PROTECTED / CARRIED-OVER** — never write; leave alone. Resume: ignore; always `git worktree add` from `origin/main`. |
| Stale `index.lock` under Dropbox `.git` | — | — | — | **CARRIED-OVER** — report to Shinichi; do **not** `rm` (harness blocks `.git` deletions) |
| Phylo Model A / PR #127 | parked | — | closed | **CARRIED-OVER** deferred menu — `docs/dev-log/handover/2026-06-30-codex-handover.md` |

## Files Created / Modified (Arc 1 vs `origin/main`)

```
src/families/grouped_dispersion.jl
src/families/covariates.jl
src/bridge.jl
src/formula.jl
src/confint_family.jl
src/GLLVM.jl
test/test_nb_beta_x_identity.jl
test/test_bridge_x.jl
test/runtests.jl
docs/src/response-families.md
docs/src/gllvmtmb-parity.md
docs/design/capability-status.md
docs/dev-log/check-log.md
docs/dev-log/coordination-board.md
docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md
docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md
docs/dev-log/plans/2026-08-02-nb2-beta-x-identity-ultra-plan.md
docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md  (this file)
AGENTS.md  (phase snapshot pointer)
```

## Next Immediate Steps (OWED only after classify)

1. **Rehydrate:** read `AGENTS.md`, this doc, `docs/dev-log/coordination-board.md`;
   `git fetch origin`; confirm #175 tip and CI.
2. **Land Arc 1:** when Julia CI green on [#175](https://github.com/itchyshin/GLLVM.jl/pull/175),
   self-merge (engine + identity tests; no tol widen). Do **not** merge if red —
   diagnose first.
3. **Stop before Arc 2 in the same Agent marathon** unless Shinichi starts a
   dedicated `/goal`. Arc 2 = new worktree from post-merge `origin/main`, light
   RCall NB2+X/Beta+X cells, rtol `1e-6`, twin at fresh `origin/main`.
4. **Never** write the Dropbox PROTECTED checkout; never `git add -A`.

## Blockers / Open Questions

- #175 Julia CI still pending at handoff write time — wait, don't force-merge.
- Arc 2 needs live R + gllvmTMB twin; ask *"Totoro or DRAC?"* before large grids
  (light cells OK on Totoro/laptop).

## Gotchas & Failed Approaches

- Comparing grouped default (`hessian=:observed`) to shared Fisher is a different
  Laplace objective (#172 lesson) — identity cells must force `:fisher`.
- Bridge tests must oracle against `fit_*_grouped_cov` for NB/Beta, not
  `fit_gllvm_cov`, after the route flip.
- Documenter deploy can flake on `gh-pages` push race; re-run Documenter job
  before treating as content failure (#172).

## How to Resume (Cursor live env)

Working directory (preferred while #175 open):

```text
/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-nb2-beta-x-grouped-cov-20260802
```

After #175 merges, cut a **new** worktree from `origin/main` for Arc 2.

Toolchain:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
julia --project=. -e 'using Pkg; Pkg.instantiate()'
# focused smoke
julia --project=. -e 'using Test; include("test/test_nb_beta_x_identity.jl")'
# full CI-equivalent
julia --project=. -e 'using Pkg; Pkg.test()'
```

Do not stage: Dropbox checkout dirt, `.claude/preview/*` churn, foreign
untracked agent files outside this lane. Stage by explicit path only.

Classify then act only on OWED:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-cursor-handover-nb2-beta-x-arc1.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
