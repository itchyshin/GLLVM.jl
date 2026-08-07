# Session Handoff: Post-#192 → next capacity programme (Cursor)

**Meta:** 2026-08-07 · from Cursor (this session) · to **Cursor** (fresh chat)  
**Repo:** GLLVM.jl · `origin/main` @ `f56befc1` (Merge #192)

## Critical Context

1. **BetaBinomial+X engine Arc 1+2 is MERGED** (#192 → `main` @ `f56befc1`). Live light
   RCall Δ abs ≈ **1.50e-8** (seed=49). Do **not** redo engine/bridge/parity cell.
2. **Board/AGENTS on `main` are stale** — still say “PR pending / open PR.” This hygiene
   PR lands the truth + this handover. Treat leftover “awaiting PR” text as fiction.
3. Owner wants the **next three rungs as one capacity programme** (not three chats), but
   **handover first** then fresh `/ultra-plan` (G0) — do **not** start engine in the
   planning chat.

## Goals / mission

Clear the post-#192 desk, then plan one programme that (1) widens Species-XB light
cells, (2) adds BetaBinomial grouped CI, (3) locks the **next** +X Identity Arc 0
(docs-only). Theme remains **R–Julia light-parity ladder**. Fence: ≠ full family
parity ≠ ADEMP ≠ Tweedie-by-default ≠ second-family engine in the same execute run.

## Plans / roadmap (beyond immediate)

After the capacity programme lands: pick next ladder family / Phylo Model A only via
fresh arc-creation. Parked Phylo #127 — do not orphan, do not resume here.

## What Was Accomplished (this session chain)

| Landing | Evidence |
|---|---|
| Post-NB1 closeout packaging A | #187 hygiene, #190 Species-XB Poisson, #191 BB Identity |
| BetaBinomial+X engine + bridge + light | #192 @ `f56befc1`; Δ ≈ 1.50e-8; identity 12/12; capabilities 128/128 |
| Documenter fix on #192 | stripped ambiguous `@ref` → VitePress green (`a43323fd`) |
| Owner intent for next | **all 3 at one go** as capacity programme; **handover first** |

## Current Working State

- **Working:** `main` green tip `f56befc1`; open PRs empty at handoff cut (before this hygiene PR).
- **In progress:** this docs PR — board/AGENTS truth + handover.
- **Not working / blocked:** none for #192. BB grouped **CI** still fail-loud by design
  (`_bridge_ci_guard_betabinomial`) — future programme slice, not a regression.

## Key Decisions & Rationale

- Identity-before-engine (#191 before #192).
- BB Laplace stays in `beta_binomial.jl` (custom FD + trials `N`); not `_beta_grouped_*`.
- FD-first for BB grouped_cov; OH only if R Δ needs it (G0 on engine arc).
- Next programme: Species-XB widen → BB grouped CI → next Identity (Ada order); Identity
  family needs **new G0** (Tweedie rejected as default earlier).
- Handover before ultra-plan (owner, 2026-08-07).

## Landing State

`handoff_gate.sh` (pre-handover): FAIL — uncommitted LOOP checkpoint on engine worktree
(discarded; programme DONE on `main`) + many **stale unpushed foreign branches** not
owned by this lane.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `main` @ `f56befc1` (#192) | y | y | #192 MERGED | **LANDED** |
| Engine branch `cursor/betabinomial-x-engine-arc12-20260805` | y | y | merged/deleted remote tip | **LANDED** (via #192) |
| This hygiene: `docs/post-bb-x-handover-20260807` | y (this PR) | OWED push | this PR | **landing with handoff** |
| Local LOOP `checkpoint.md` dirty pre-handover | n | n | — | **CARRIED-OVER / discarded** — DONE state only; resume from `main` |
| Foreign unpushed branches (gamma-x, phylo, fam-*, codex/*, …) | mixed | n | — | **CARRIED-OVER / ignore** — not this lane; do not rebase or delete |

## Files Created / Modified (this hygiene commit)

- `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x.md` (this file)
- `docs/dev-log/coordination-board.md` — #192 MERGED; START HERE → ultra-plan next programme
- `AGENTS.md` — Phase state snapshot prepend
- `docs/dev-log/check-log.md` — one-line close of #192 MERGED

## Next Immediate Steps (OWED only)

1. **Merge this hygiene PR** when Documenter/CI green (docs-only; self-merge OK).
2. **Fresh Cursor chat** — `/ultra-plan` the capacity programme:
   - S0 board already fixed by this PR
   - S1 Species-XB Binomial (+ optional Gaussian) light cells
   - S2 BetaBinomial grouped CI (engine)
   - S3 next +X Identity Arc 0 (docs-only; **G0 must pick family**)
3. G0 locks to collect in ultra-plan: programme yes; Gaussian in/out; Identity family;
   merge-on-green; packaging A (serial landings).
4. After G0 → `/goal` on a **fresh worktree from `origin/main`**. Do not Phase-3 in the
   planning chat.

## Blockers / Open Questions

- Identity family for S3 — **unset** (Ada will propose; owner G0).
- Whether Gaussian Species-XB is in scope with Binomial — **unset** (Ada default: Binomial
  required, Gaussian optional under-run).

## Gotchas & Failed Approaches

- VitePress fails on unresolved Documenter `@ref` left as `./@ref` in `api.md` — prefer
  plain backticks for ambiguous multi-method refs (`getLV`, `rotation`).
- `gh pr merge` can exit non-zero on local `main` worktree conflict while still merging
  remotely — always verify with `gh pr view --json state,mergeCommit`.
- Do not invent Tweedie+X as next Identity default (twin user path fail-loud).
- Dropbox checkout PROTECTED; never `git add -A`.

## How to Resume (Cursor)

**Environment:** fresh worktree from `origin/main` after this hygiene merges (or work on
this docs branch until merge). Julia: `~/.juliaup/bin/julialauncher` if `julia` not on
PATH. Parity: `GLLVM_PARITY_TESTS=1` needs local R + gllvmTMB. Never stage Dropbox
protected tree.

**Read order:** `AGENTS.md` → this handover → `docs/dev-log/coordination-board.md` →
after-task `docs/dev-log/after-task/2026-08-05-betabinomial-x-engine-arc12.md`.

**Classify** each Next Immediate Step `OWED` / `DONE` / `RETRACTED` / `PROTECTED` against
live `git` before acting. Execute only `OWED`.

**Paste-ready:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
