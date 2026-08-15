# GOAL — gllvmjl-parallel-family-catchup-20260815 (IMMUTABLE — re-read at the top of EVERY arc)

Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then `checkpoint.md`, then continue.

## Mission

Solo platform: **Cursor**. Land Identity → engine → focused FD/tests for **three active**
families (**lognormal**, **ZIB+X**, **censored_poisson**) under the ownership matrix, with
merge-conductor sequential admit for shared choke points. **truncated_nbinom2** is in the
Ada 4-set but **OWNED elsewhere** — never double-own, never interrupt its keep-going agent
beyond checking #205 / nbinom2 merge state.

## Headline

Identity docs || on 3 worktrees, then engines || on disjoint kernels, then one
merge-conductor admit — ~11–13 h wall vs ~28–36 h serial — without inventing ZIP/ZINB Δ
and without touching the Dropbox protected fork.

## Invariants

- One programme lane: WT `.worktrees/gllvmjl-parallel-family-catchup-20260815` on
  `cursor/parallel-family-catchup-20260815`; family Identity/engine WTs as named in the plan.
- Base at launch = catch-up tip `b2b99463` because **#205 OPEN**; rebase to `origin/main`
  after #205 merges before Wave2 if needed.
- **FORBIDDEN:** coding on Dropbox fork `claude/jl-bridge-capabilities-20260619`; editing
  truncated_nbinom2 WT/branch/files; inventing ZIP/ZINB twin Δ; ADEMP/coverage unless
  Totoro/DRAC asked; Phylo Model A; silent rtol; `git add -A`.
- Compute = **local** tiny + FD; light RCall **only when twin admits**.
- Identity posture = **Julia-forward OK** where twin cut/absent; fence claims explicitly.
- Shared choke points (`src/GLLVM.jl`, `fit_gllvm.jl`, `bridge.jl`, `capability-status.md`,
  `test/runtests.jl`) = **merge-conductor only**.
- Fan-out ≤6 / checkpoint; Rose fences bind.
- Push/PR when a wave is green (autonomy); merge only on full CI green.
- Stage by name only.

## Authoritative WHAT

→ `LOOP/ultra-plan.md` and
`docs/dev-log/plans/2026-08-15-parallel-family-catchup-3to5.md`.
Detail wins there; this file wins on “what must never be lost.”

## Definition of done

1. Three Identity decisions ACCEPTED with Rose fence language (PRs landed or ready).
2. Three engines on owned files with FD ≤1e-6 + focused tests green.
3. Conductor admits shared choke points; ledger honest; full `Pkg.test` + CI green before merge.
4. truncated_nbinom2 never edited by this programme.
5. After-task + check-log + board + Melissa at close.
