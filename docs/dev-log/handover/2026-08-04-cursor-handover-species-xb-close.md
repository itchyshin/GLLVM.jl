# Session Handoff: Species-XB Arc 0 LOCAL DONE → push/PR (Cursor)

Meta: 2026-08-04 · from **Cursor** · AUTHOR = cursor · TARGET = **cursor**  
Rehydrate via Active-Lane-Split (not a single orphaned pointer).

## Critical Context

1. **Species-XB light RCall Arc 0 is LOCAL DONE** on
   `parity/species-xb-light-20260804` @ `49f8ca87` — Poisson
   `(0 + trait):x` vs `fit_gllvm_speciescov`, live **Δ ≈ 4.20e-9** at rtol
   `1e-6`. **Not pushed; no PR.** Push/PR only when Shinichi asks.
2. **`main` already has** Ordinal+X stack through [#181](https://github.com/itchyshin/GLLVM.jl/pull/181)
   @ `a92c5040`. Do not redo #179–#181 or the Poisson species-XB cell.
3. **Dropbox checkout** `claude/jl-bridge-capabilities-20260619` is
   **PROTECTED** — never write there. Prefer
   `.worktrees/gllvmjl-species-xb-arc0-20260804` or a fresh worktree from
   `origin/main`.

## Goals / mission

Keep the R↔Julia light logLik surface honest and expanding without claiming
full family parity. Species-XB Arc 0 opens the per-trait slope cohort after
shared-γ (#170–#181).

## What Was Accomplished (this session)

- Under-run hygiene: board/AGENTS/#181 MERGED; parity README Ordinal+X claimed;
  ROADMAP §1 “B next” → engine landed / light RCall next.
- `fit_gllvmtmb_parity_loglik_species_x` + `test_species_x_parity.jl` (Poisson).
- Live focused verify: Δ ≈ 4.20e-9; no `src/` B-engine redesign; no rtol widen.
- LOOP kit `lanes/species-xb-light-20260804/LOOP/`; after-task
  `docs/dev-log/after-task/2026-08-04-species-xb-light-rcall.md`.
- Prior in-thread (already on `main`): #180 / #181 Ordinal+X landings.

## Current Working State

- **Working:** Species-XB Poisson light cell; tip clean after arc-card actuals commit.
- **In progress:** none (goal finished).
- **Blocked / gated:** push/PR of `parity/species-xb-light-20260804` until Shinichi asks.

## Landing State

`handoff_gate.sh` failed on this tip (unpushed) + many stale sibling branches.
This lane only owns Species-XB tip. Other unpushed branches are **not** this
lane’s CARRIED-OVER work — do not push them from this handover.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `parity/species-xb-light-20260804` @ `49f8ca87` (Species-XB Arc 0) | yes | **no** | none | **CARRIED-OVER** — finished; push gated on ask. Resume: see Next Immediate Steps. |
| `main` @ `a92c5040` (#181) | yes | yes | merged | **LANDED** |
| Dropbox `claude/jl-bridge-capabilities-20260619` | n/a | n/a | n/a | **PROTECTED** |
| Stale unpushed branches (`fix/gamma-x-*`, `codex/*`, locked agent worktrees, …) | varies | no | n/a | **IGNORE** for this handover — do not land from here |

**Resume command (Species-XB tip):**
```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-species-xb-arc0-20260804"
git status -sb && git log origin/main..HEAD --oneline
# Only when Shinichi asks:
git push -u origin HEAD
gh pr create --base main --title "test(parity): Poisson species-XB light logLik" --body "…"
# Merge only when CI green + ask.
```

## Key Decisions & Rationale

- Species-specific `B` **engine already exists** (`fit_gllvm_speciescov`); do
  **not** rebuild. Arc 0 = light RCall only.
- Separate helper `fit_gllvmtmb_parity_loglik_species_x` (not a flag on shared-X
  helper) — keeps `(0+trait):x` vs bare `+ x` hard to confuse.
- Arc 0 = **Poisson only**; other families need separate G0 (dispersion identity
  may apply for NB/Beta/Gamma).
- Next **capability** arc → **fresh chat / new lane** after push/PR; do not stack
  Binomial species-XB or X_lv on this conductor.

## Files Created / Modified (tip vs `origin/main`)

```
AGENTS.md
ROADMAP.md
docs/design/capability-status.md
docs/dev-log/after-task/2026-08-04-species-xb-light-rcall.md
docs/dev-log/check-log.md
docs/dev-log/coordination-board.md
docs/dev-log/plans/2026-08-04-species-xb-light-rcall-arc-card.md
docs/dev-log/handover/2026-08-04-cursor-handover-species-xb-close.md  # this file
lanes/species-xb-light-20260804/LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md
test/parity/README.md
test/parity/parity_helpers.jl
test/parity/runparity.jl
test/parity/test_species_x_parity.jl
```

## Next Immediate Steps (OWED only)

1. **Classify** every item in this doc against live `git` / `gh` as OWED / DONE /
   RETRACTED / PROTECTED. Do not redo the Poisson cell if tip still has Δ evidence.
2. **If Shinichi asks push/PR:** push `parity/species-xb-light-20260804`, open PR,
   watch CI, merge when green **and** asked. Stage by path; never `git add -A`.
3. **If Shinichi asks next capability:** fresh chat — `/arc-creation` then G0 →
   `/goal` (candidates: Binomial/Gaussian species-XB; X_lv light; registration).
   Prefer new worktree from post-merge `main`.
4. **Do not** expand species-XB cohort or start X_lv in the push/PR lane without
   a new G0.

## Plans / roadmap (beyond immediate)

- Expand species-XB light cohort (Bin/Gauss first; NB/Beta/Gamma only with identity).
- X_lv light RCall (separate gates; already partially implemented Julia-side).
- Phylo Model A remains parked (`docs/dev-log/handover/2026-06-30-codex-handover.md`).
- Registration / Rose pre-publish when aiming at General registry.

## Blockers / Open Questions

- Push authority: maintainer must ask (hard boundary).
- Sibling unpushed branches clutter `handoff_gate` — ignore unless Shinichi
  names one.

## Gotchas / Failed Approaches

- Parity `test/parity/Project.toml` must **not** list GLLVM (runtime
  `Pkg.develop`); restore if `Pkg.develop` dirties it.
- Use `GLLVM.Poisson()` in parity tests (no Distributions dep in parity project).
- Never confuse shared-X helper (`+ x`) with species-XB helper (`(0+trait):x`).

## How to Resume (Cursor)

**Working directory:**
`/Users/z3437171/Dropbox/Github Local/GLLVM.jl/.worktrees/gllvmjl-species-xb-arc0-20260804`

**Toolchain:**
```sh
export PATH="$HOME/.juliaup/bin:$PATH"
# optional live RCall:
# GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
```

**Safe verify (do not treat as redo of Arc 0 unless tip changed):**
```sh
GLLVM_PARITY_TESTS=1 julia --project=test/parity --startup-file=no -e '
using Pkg; Pkg.develop(path="."); using RCall, Random, GLLVM
include("test/parity/parity_helpers.jl")
# focused cell: see after-task seed=48
'
```

**Must not stage:** Dropbox protected checkout; foreign untracked files;
`test/parity/Manifest.toml` (gitignored); never `git add -A`.

**Multi-lane pointer:** `docs/dev-log/coordination-board.md` Active-Lane-Split.
Parked sibling: Phylo Model A handover `2026-06-30-codex-handover.md`.

### Paste-ready resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-04-cursor-handover-species-xb-close.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
