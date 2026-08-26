# HANDOVER — GLLVM.jl curvature programme (2026-08-25)

Resume prompt: read `AGENTS.md`, then this file, then reconcile against live `git`/`gh`
before touching anything. **Verify claims here against the code — this repo has a
documented history of confident-but-wrong records, including several corrected today.**

## Lane

`PLATFORM: claude` · `BRANCH: claude/lane-beyond-20260824` ·
`WORKTREE: /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824` ·
39 commits pushed, 0 behind `origin/main`.
**The Dropbox checkout `/Users/z3437171/Dropbox/Github Local/GLLVM.jl` is a STALE FORK —
never commit there.**

## THE ONE ACTION THAT MATTERS

**PR #265 is open with CI running on `a5dc84a0`.**

    gh pr checks 265

- **All four Julia jobs green → `gh pr merge 265 --merge`** (Shinichi authorised the merge;
  never `--auto`).
- **Any job red → DO NOT MERGE.** Diagnose and report. A red cross-platform job is real
  information: local runs are macOS/Julia-1.10 only, and CI runs 1.12 on macOS/Windows.

## State

**On `main`:** 4 of 13 curvature instances — truncNB2, Exponential, NB1-grouped (#263),
DeltaGamma (#264).

**In the lane, awaiting #265:** instance 8 fixed (`fit_gllvm(Y; family = Gamma())` — the
public default path); role-separation contract in **12 kernels**; a live pre-existing
defect fixed (grouped fitters ran an unguarded indefinite Newton); three
one-model-two-answers route defects closed; claim-honesty corrections; the ledger now
discloses the curvature class.

**Local gate:** `Pkg.test()` 6774 pass / 1 broken (pre-existing) / 0 fail, exit 0.
**Docs:** `docs/make.jl` exit 0, 41 invalid-link warnings (pre-existing baseline, a
Vitepress/Documenter checker mismatch across 11 of 17 pages — NOT dead links).

## Read these before deciding anything

`docs/dev-log/pending/` (untracked — commit after #265 merges):
- `2026-08-25-parity-ladder-decision-brief.md` — **the ladder cannot reach 17/17.** Three of
  four unpaid cells would need the Julia MODEL changed to match the twin. Honest ceiling:
  **13 unqualified + 4 RESTRICTED**, two payable with zero code today.
- `2026-08-25-release-readiness-audit.md` — verdict **No**, 7 blockers (several now cleared).
- `2026-08-25-final-kernel-audit.md`, `2026-08-25-after-task-curvature-phase2.md`.

## DO NOT

- **Do not describe the fault class as closed.** 12 kernels of 13; `aghq_grid.jl` FENCED.
- **Do not flip Beta / NB2 / NB1 / Tweedie / Student-t / GP-1 to `:observed`.** Measured
  evidence is against or absent: observed is closer for Gamma 12/12, but only 2/12 for Beta
  and measurably WORSE for GP-1 (α 0.879 vs truth 0.4). Only Gamma had a case.
- **Do not call this an accuracy improvement.** It is a PARITY change.
- Do not touch the fenced items: AGHQ unpark, Tweedie admit (STOP #234), L47.
- Do not update `test_phylo_gamma_xlv.jl:123` — that oracle needs a reviewer who did not
  change the code it judges.
- Do not re-wire `test_phylo_binomial_xlv` / `_nb_xlv` / `_ordinal_xlv` /
  `test_sparse_phy_grad` without stabilising them first (see below).

## Two traps that cost a CI cycle today

1. **A literal pinned from a `Random.seed!` fixture is NOT portable.** `randn` differs
   between Julia 1.10 and 1.12; the local machine has only 1.10. Never `@test x === <float>`
   on generated data.
2. **"Passes locally" is not evidence a numerically sensitive test is stable.** Four
   orphaned tests passed locally and failed on *different platform subsets*
   (`pd_hessian`, profile-CI endpoints, NaN bounds). That is almost certainly why they were
   orphaned. Stabilising them is its own slice.

## Next work, in order

1. Land #265 (above).
2. Commit `docs/dev-log/pending/*` after the merge.
3. **Ledger correction (verified, unrecorded):** the student cell's recorded blocker "the
   twin estimates ν" is FALSE — `gllvmTMB R/families.R:362` says `student()` estimates df
   *"unless `df` is supplied"*. The real blocker is the Fisher curvature at
   `studentt.jl:75`, which is recorded nowhere.
4. The two zero-code RESTRICTED parity cells from the ladder brief.
5. Release blockers that are Shinichi's: version bump 0.3.0 → 0.4.0, first-tag mechanics.
