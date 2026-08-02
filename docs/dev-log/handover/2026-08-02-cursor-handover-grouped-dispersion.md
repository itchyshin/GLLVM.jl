# Session Handoff: Next lane → `test_grouped_dispersion.jl:61` (Cursor)

Meta: 2026-08-02 ~06:53 MDT · from Cursor (Ada) · target Cursor · AUTHOR=cursor · context N/A

You are Cursor, picking up GLLVM.jl after the **X/covariate light logLik** cohort
landed on `main` via PR #170. You inherit **no chat context**. Read files, then
classify every item below `OWED` · `DONE` · `RETRACTED` · `PROTECTED` and execute
**only OWED**. Do **not** reopen the closed X-cell or φ routing implementations.

Sibling handovers (do not orphan):

- X/covariate light logLik (DONE / MERGED #170): this closeout + after-task below
- Default-route NB2/Beta φ (MERGED #169): `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`
- Catch-up logLik closeout (DONE): `docs/dev-log/handover/2026-08-01-cursor-handover.md`
- Phylo Model A deferred: `docs/dev-log/handover/2026-06-30-codex-handover.md`
- Multi-lane board: `docs/dev-log/coordination-board.md`

## Critical Context

1. **X cohort MERGED** — PR [#170](https://github.com/itchyshin/GLLVM.jl/pull/170)
   → `main` merge commit **`d60d90e2`** (branch tip `e87ec7a4`). Shared site-X
   light logLik for Gaussian / Binomial / Poisson green at rtol `1e-6`
   (Δ ≈ 1e-9). Twin was gllvmTMB `/tmp/gllvmtmb-parity-x-loglik-20260802` @
   `910ebd54`. **Do not reopen X cells** unless they regress.
2. **Next OWED lane (chosen):** diagnose and fix
   `test/test_grouped_dispersion.jl:61` — one-group `fit_nb_gllvm_grouped` ≈
   `fit_nb_gllvm` logLik gap (pre-existing; fenced out of φ and X PRs).
3. **Wrong tree hazard:** Dropbox checkout
   `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` on
   `claude/jl-bridge-capabilities-20260619` is **PROTECTED** / stale — never
   write there. Start a **new worktree from `origin/main`**.
4. **Rose fence for next lane:** fix the one-group identity / optimiser gap;
   do **not** claim full family parity, do **not** silently widen the
   `atol=1e-2` / `rtol=1e-4` test band without fixing the cause.
5. **NB2/Beta+X remains fenced** (shared φ in `fit_gllvm_cov` ≠ public
   per-trait φ default) — separate later ultra-plan, not this bug lane.

## Goals / Mission

- Package mission: Julia twin of R `gllvmTMB` — honest parity, speed, no silent
  claim inflation (`AGENTS.md` / `CLAUDE.md`).
- Closed this session: first shared-X light logLik cohort on `main` (#170).
- Next mission: make `fit_nb_gllvm_grouped` with `group = ones(Int, p)` match
  `fit_nb_gllvm` at the existing test tolerances (or document a precise
  engine reason and replace the assertion with an honest contract — prefer
  **fix the cause**).

## Plans / Roadmap (beyond immediate next)

- **Primary OWED:** grouped-dispersion one-group bug lane (~1–2 h).
- **Deferred:** second X cohort / NB2–Beta+X (needs shared-vs-per-trait identity
  design first).
- Fence #129/#128, ADEMP, coverage, Totoro/DRAC unless a dedicated lane owns them.
- Phylo Model A redesign remains a deferred sibling menu on the board.

## What Was Accomplished

| Item | Result |
|---|---|
| X light logLik cohort | 3/3 cells; LOG `docs/dev-log/x-covariate-parity-full-20260802.log` |
| Helper | `fit_gllvmtmb_parity_loglik_x` + `parity_site_design`; no-X helper intact |
| Landing | Pushed branch; PR #170 opened and **merged** (`d60d90e2`) |
| Default-route φ | Already on `main` via #169 |

Detail: `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`.

## Current Working State

- Working: `main` @ `d60d90e2` includes X parity cells + φ default-route.
- In progress: none for X lane (COMPLETE / MERGED).
- Not working: `test_grouped_dispersion.jl:61` still the known core-suite red
  (or flaky) one-group NB identity check — **next lane**.

## Key Decisions & Rationale

- R formula for shared X: `value ~ 0 + trait + x + latent(..., unique=FALSE)` —
  **not** `(0+trait):x` (that is per-trait slopes).
- Julia X: `X[t,s,1] = x_s` broadcast; Gaussian `fit_gaussian_gllvm(; X=)`;
  Bin/Pois `fit_gllvm_cov`.
- Next lane pick: **grouped_dispersion:61** over NB2/Beta+X because the latter
  is an identity/design problem; the former is a bounded bug with an existing
  failing assertion.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| GLLVM.jl `parity/x-covariate-light-loglik-20260802` @ `e87ec7a4` | y | y | [#170](https://github.com/itchyshin/GLLVM.jl/pull/170) **MERGED** → `d60d90e2` | **LANDED** |
| This handover + board/AGENTS pointer refresh | with this commit | with this PR | (docs PR) | **OWED land with this docs PR** |
| Dropbox `claude/jl-bridge-capabilities-20260619` dirty + stashes | n | n | none | **CARRIED-OVER / PROTECTED** — ignore; do not pop into new worktree |
| Other historical unpushed local branches (handoff_gate noise) | mixed | n | various | **CARRIED-OVER** — out of scope |
| Optional later: NB2/Beta+X light cells | n | n | none | **CARRIED-OVER** — fenced; fresh ultra-plan later |
| Phylo Model A | parked | — | #127 closed | **CARRIED-OVER** — sibling deferred menu |

### Resume commands for CARRIED-OVER rows

```sh
# Protected Dropbox fork — do not use as write base
# cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"   # NO

# New lane worktree (preferred)
REPO="/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git -C "$REPO" fetch origin main
git -C "$REPO" worktree add -b fix/grouped-dispersion-one-group-20260802 \
  "$REPO/.worktrees/gllvmjl-grouped-dispersion-20260802" origin/main
```

## Files Created / Modified (X lane → main via #170)

- `test/parity/parity_helpers.jl`
- `test/parity/test_x_covariate_parity.jl`
- `test/parity/runparity.jl`
- `test/parity/README.md`
- `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md` (updated again in this handover commit)
- `docs/dev-log/plan-actual/2026-08-02-gllvm-x-covariate-light-loglik.md`
- `docs/dev-log/plans/2026-08-02-gllvm-x-covariate-light-loglik-ultra-plan.md`
- `docs/dev-log/x-covariate-parity-full-20260802.log`
- `lanes/x-covariate-light-loglik-20260802/LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`
- This file: `docs/dev-log/handover/2026-08-02-cursor-handover-grouped-dispersion.md`
- `AGENTS.md` (phase snapshot pointer → board + this handover)

## Next Immediate Steps

Ordered; classify before acting:

1. **OWED (primary):** New worktree from `origin/main` (≥ `d60d90e2`). Reproduce
   `test/test_grouped_dispersion.jl` failure at the one-group ≈ shared assertion
   (~line 61). Diagnose whether optimiser tolerance, packing/identity, or
   objective mismatch. Fix cause; **no silent tol widen**.
2. **DONE (do not redo):** X shared-site light logLik cohort; φ default-route
   (#169); catch-up named-route logLik.
3. **OWED (optional later):** NB2/Beta+X light cells — only after a written
   identity design (shared vs per-trait φ under X).
4. **PROTECTED:** Dropbox stale fork; #129/#128; ADEMP; coverage; Totoro/DRAC;
   “full family parity”; Phylo Model A deferred menu; closed X/φ LOOPs overwrite.

## Blockers / Open Questions

- None for starting the grouped-dispersion lane. Live Julia + `Pkg.test` / focused
  `test/test_grouped_dispersion.jl` is enough (local laptop).

## Gotchas & Failed Approaches

- Do not use Dropbox coverage-branch gllvmTMB for parity; recreate twin from
  gllvmTMB `origin/main` if re-running X cells.
- Binomial+X needed a milder DGP (seed/n) to avoid R runaway-loading warnings —
  see after-task; rtol was never widened.
- Stale multitask “9 Working” forks from the planning chat are noise — Stop All;
  do not resume them for this lane.

## How to Resume

### Environment

- **Write base:** new worktree from `origin/main` (command above).
- **Julia:** `~/.juliaup/bin/julialauncher` / `julia --project=.`
- **Safe verify (X regression, optional):**  
  `GLLVM_PARITY_TESTS=1 GLLVM_PARITY_R_LIBS=/tmp/R-gllvmtmb-x-parity-20260802 \
    julia --project=test/parity test/parity/runparity.jl`  
  (recreate twin/R lib if `/tmp` cleaned).
- **Safe verify (next lane):**  
  `julia --project=. -e 'using Pkg; Pkg.test("GLLVM"; test_args=`["test_grouped_dispersion"]`)'`  
  or run the focused testset via `include` after `using GLLVM, Test`.
- **Do not stage:** Dropbox-fork dirt; unrelated historical branches; any
  `docs/dev-log/plans/scratch/*` attach notes unless explicitly in scope.

### Preflight / rehydrate order

1. `git fetch origin main && git rev-parse origin/main` (expect ≥ `d60d90e2`)
2. Create/attach the grouped-dispersion worktree
3. Read `AGENTS.md` → **this** handoff → `docs/dev-log/coordination-board.md`
4. Skim after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`
5. Classify OWED/DONE/RETRACTED/PROTECTED; continue **only OWED**

### Paste-ready resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-cursor-handover-grouped-dispersion.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
