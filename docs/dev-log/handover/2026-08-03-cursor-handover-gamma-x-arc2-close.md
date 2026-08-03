# Session Handoff: Gamma+X Arc 1–2 close → land + Ordinal+X next (Cursor)

Meta: 2026-08-03 ~09:57 MDT · from Cursor (Ada) · target Cursor · AUTHOR=cursor · context N/A

You are Cursor, picking up GLLVM.jl after the **Gamma+X identity → engine →
light RCall** cycle. You inherit **no chat context**. Read files, then classify
every item below `OWED` · `DONE` · `RETRACTED` · `PROTECTED` and execute **only
OWED**.

Sibling handovers / pointers (do not orphan — read the board, not just this doc):

- Multi-lane board: `docs/dev-log/coordination-board.md` (**rehydrate pointer**,
  Active-Lane-Split)
- Gamma+X identity Arc 0: `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`
- Gamma+X engine Arc 1: `docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md`
- Gamma+X light RCall Arc 2: `docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md`
- NB2/Beta+X Arc 2 (still OPEN): PR [#177](https://github.com/itchyshin/GLLVM.jl/pull/177) ·
  handover `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md`
- Windows NA budget (MERGED #176): `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md`
- NB2/Beta+X engine (MERGED #175): `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md`
- Phylo Model A deferred: `docs/dev-log/handover/2026-06-30-codex-handover.md`
- Dropbox stale checkout: **PROTECTED** (see Landing State)

## Mission-control summary

| Repo | Branch / tip | CI | Shipped | Next (leverage) |
|---|---|---|---|---|
| GLLVM.jl | `main` @ `0e241215` (#176) | green | #172–#176 on main; #175 NB2/Beta engine | Land Gamma stack + #177 |
| GLLVM.jl | `parity/gamma-x-arc2-20260803` (handover tip; ≥`44e5f801`) | **not pushed** | Gamma identity + engine + Arc 2 + this handover | **Preferred** push/PR |
| GLLVM.jl | `fix/gamma-x-grouped-cov-20260803` @ `bcd48513` | **not pushed** | Duplicate Arc 2 (parallel agent) | **CARRIED-OVER** — discard; do not dual-PR |
| GLLVM.jl | PR #177 `parity/nb2-beta-x-arc2-20260802` | OPEN · MERGEABLE · Julia CI IN_PROGRESS | NB2+X/Beta+X light cells | Merge when Julia CI green |

## Critical Context

1. **Wrong tree hazard:** Dropbox checkout
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on
   `claude/jl-bridge-capabilities-20260619` is **PROTECTED / stale** — never
   write there. Prefer worktrees under `.worktrees/`.
2. **Twin rule:** GLLVM.jl mirrors gllvmTMB on **API/capabilities**, not engine
   code. RCall = opt-in (`GLLVM_PARITY_TESTS=1`).
3. **Gamma+X stack is LOCAL-DONE, not on `origin`:** preferred tip is
   `parity/gamma-x-arc2-20260803` (Arc 2 content @ `44e5f801` plus this
   handover commit). A parallel agent also finished Arc 2 on
   `fix/gamma-x-grouped-cov-20260803` @ `bcd48513` — **same claim, duplicate
   commits**. Push **only** the `parity/` branch; ignore/drop the `fix/`
   Arc 2 duplicate when landing.
4. **OH unblocker:** first Arc 2 attempt had systematic Δ≈0.2–1 because grouped
   Gamma Laplace was Fisher-only. Fix: default `hessian=:observed` with
   `W = α y / μ` (LogLink). Identity G=1 vs `fit_gllvm_cov` forces
   `hessian=:fisher`. Do not silently widen rtol.
5. **Rose fence:** OK = “Gamma+X light logLik under per-trait α + shared γ.”
   **Not OK:** full family parity; Ordinal+X; X_lv; ADEMP/coverage; Option B
   no-X flip; Phylo Model A; claiming NB2/Beta+X from the Gamma tip (#177 owns
   those cells).

## Goals / Mission

- Package: Julia twin of R `gllvmTMB` — honest parity, speed, no claim inflation.
- This marathon (closing): Gamma+X Arc 0 identity → Arc 1 engine → Arc 2 light
  RCall (local) + keep #177 landing lane alive.
- Beyond: Ordinal+X identity-first cycle; then deferred shared-φ vs per-trait
  comparison questions.

## Plans / Roadmap (beyond immediate next)

1. **Land Gamma stack** — push `parity/gamma-x-arc2-20260803`, open PR (engine +
   parity; or split if review prefers), ask before push if policy requires.
2. **Land #177** when CI green (self-merge OK — test/docs only).
3. **Next capability arc (fresh chat):** Ordinal+X **dispersion/cutpoint
   identity decision doc** only (~1–2h), mirroring
   `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`. No
   engine until that doc is ACCEPTED.
4. Fence ADEMP, coverage, Totoro/DRAC grids, X_lv, Phylo Model A unless a
   dedicated lane owns them.

## What Was Accomplished (this session)

| Item | Result |
|---|---|
| Gamma+X identity Arc 0 | ACCEPTED decision on branch (bundled in stack) |
| Gamma+X engine Arc 1 | `fit_gamma_gllvm_grouped_cov` + bridge/`@formula`; identity 7/7; bridge_x 204/204 |
| Gamma+X Arc 2 OH fix | `hessian=:observed` default on grouped Gamma Laplace |
| Gamma+X Arc 2 light cell | Δ ≈ **3.03e-8** at rtol 1e-6 (seed=46); X cohort green |
| #176 | MERGED earlier → `main` @ `0e241215` |
| #177 | Still OPEN / MERGEABLE / CI UNSTABLE — **not** merged this session |

Detail: `docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md`,
`docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md`.

## Current Working State

- Working: `parity/gamma-x-arc2-20260803` (handover committed on tip; verify with
  `git rev-parse --short HEAD`).
- In progress: nothing in this lane — **STOP** until push/PR ask or #177 land.
- Not working / deferred: Ordinal+X; Option B no-X Gamma flip; ADEMP.

## Key Decisions & Rationale

- Public/bridge Gamma under X = **per-trait α + shared site-X γ** (API B).
- Arc 2 R-oracle uses default **`hessian=:observed`** (TMB); identity uses
  **`:fisher`** vs shared `fit_gllvm_cov`.
- Prefer **`parity/gamma-x-arc2-20260803`** over the duplicate `fix/` Arc 2 tip
  for the single PR.

## Landing State

`handoff_gate.sh` **FAIL** (expected): unpushed Gamma branches + Dropbox dirt +
many pre-existing unpushed branches. Annotated:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `parity/gamma-x-arc2-20260803` (incl. this handover) | y | **n** | none | **CARRIED-OVER** — finished; waiting maintainer push/PR ask. Resume: worktree below; `git push -u origin HEAD` then `gh pr create` **only after ask**. |
| `fix/gamma-x-grouped-cov-20260803` @ `bcd48513` | y | **n** | none | **CARRIED-OVER** — **duplicate** Arc 2 from parallel agent; OH formula equivalent under LogLink. Resume: **do not push**; leave or delete after `parity/` PR lands. |
| `docs/gamma-x-identity-20260803` | y | **n** | none | **CARRIED-OVER** — content already cherry-picked into the stack; optional discard. |
| PR #177 | y | y | [#177](https://github.com/itchyshin/GLLVM.jl/pull/177) open | **CARRIED-OVER** — MERGEABLE; merge when Julia CI green. |
| Dropbox `claude/jl-bridge-capabilities-20260619` (31 uncommitted + unpushed) | n | n | none | **PROTECTED** — never write. |
| Long-stale local branches (`fam-zip`, `viz-plots2`, …) | n/a | n | none | **PRE-EXISTING, OUT OF SCOPE** |

## Files Created / Modified (Gamma stack vs `origin/main` @ `0e241215`)

Preferred branch `parity/gamma-x-arc2-20260803` includes (non-exhaustive):

```
src/families/grouped_dispersion.jl          # fit_gamma_*_grouped_cov + OH
src/GLLVM.jl / bridge.jl / formula.jl / confint_family.jl / covariates.jl
test/test_gamma_x_identity.jl
test/parity/parity_helpers.jl
test/parity/test_x_covariate_parity.jl
test/parity/README.md
docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md
docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md
docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md
docs/dev-log/plans/2026-08-03-gamma-x-*.md
lanes/gamma-x-*/LOOP/*
docs/design/capability-status.md
docs/dev-log/check-log.md
docs/dev-log/coordination-board.md
docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md  (this file)
AGENTS.md  (phase snapshot pointer)
```

## Next Immediate Steps (OWED only after classify)

1. **Rehydrate:** read `AGENTS.md`, this doc, `docs/dev-log/coordination-board.md`;
   run `tools/lane_preflight.sh` if present; `git fetch origin`; confirm
   preferred branch tip (`git rev-parse --short HEAD` on the worktree) and
   `gh pr view 177`.
2. **When Shinichi asks:** push `parity/gamma-x-arc2-20260803` and open PR
   (identity+engine+Arc2). Do **not** also push the duplicate `fix/` Arc 2 tip.
3. **When #177 CI green:** merge #177 (test+docs only). Do not force-merge red.
4. **Then STOP — fresh chat** for Ordinal+X identity decision doc (Arc 0 only;
   no engine). Mirror Gamma/NB2 identity docs.
5. **Never** write the Dropbox PROTECTED checkout; never `git add -A`.

## Blockers / Open Questions

- Push/PR requires explicit maintainer ask (AGENTS hard boundary).
- #177 Julia CI may still be running / UNSTABLE — wait for green.
- Which next arc after landings: Ordinal+X identity (Ada default) vs other.

## Gotchas & Failed Approaches

- Comparing Fisher Julia Gamma to TMB looks like “parity failure” with Δ≈0.2–1 —
  that was OH missing, not DGP. Do not widen rtol.
- Duplicate Arc 2 on two branches — push one only (`parity/`).
- Mid-run board/handover pushes cancel CI (`cancel-in-progress`) — avoid
  thrashing `check-log`/`coordination-board` while #177 matrix runs.
- Identity cells: `hessian=:fisher`; R-oracle cells: default `:observed`.

## How to Resume (Cursor live env)

Preferred working directory:

```text
/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-gamma-x-arc2-20260803
```

Branch: `parity/gamma-x-arc2-20260803` (verify tip after handover commit).

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-gamma-x-arc2-20260803"
git status -sb; git rev-parse --short HEAD; git log -3 --oneline
# smoke (optional; Arc 2 already verified)
julia --project=. -e 'include("test/test_gamma_x_identity.jl")'
# live R oracle only if R + gllvmTMB present:
# GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
```

Do not stage: Dropbox protected dirt, `.claude/preview/*`, or the duplicate
`fix/gamma-x-grouped-cov-20260803` Arc 2 tip for a second PR.

Classify then act only on OWED:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
