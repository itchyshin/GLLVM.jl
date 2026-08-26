# HANDOVER — GLLVM.jl (2026-08-26, supersedes the 2026-08-25 file)

Resume: read `AGENTS.md`, then this, then reconcile against live `git`/`gh` before touching
anything. **Verify every claim here against the code.** This session refuted three of its
own conclusions and two of an adversarial reviewer's — confident-but-wrong records are the
documented failure mode of this repo, and I added to the pile before catching it.

## Lane

`PLATFORM: claude` · `BRANCH: claude/lane-beyond-20260824` ·
`WORKTREE: /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824`
**7 commits ahead of `origin/main`, 0 behind. All pushed. All docs + tests — no `src/` change.**
**The Dropbox checkout is a STALE FORK — never commit there.**

## State: verified, not asserted

- **PR #265 MERGED** → `main` @ `c9605077`, all six checks green.
- **Full suite: 6784 pass / 1 broken / 0 fail, 71m20s, exit 0.** Baseline 6774; +10 is the
  new guard. Log: `scratchpad/pkgtest-census3.log`.
- **Docs build: exit 0**, 41 invalid-link warnings (established baseline, single cause —
  see check-log).
- **gh-pages is fresh** (`525c331c`, built from the merge) and carries the non-Gaussian
  warning. An earlier "stale docs" report was wrong; do not re-raise it.

## What actually shipped tonight

1. `test/test_curvature_census.jl` — a structural guard that reflects over the method table
   (never greps) so the curvature fault class cannot be **extended** silently. 10 tests,
   every check falsifiability-proven with negative controls.
2. `docs/src/pitfalls.md` — the six-verb name clash under StatsBase **and** MixedModels.
3. Ledger + claim corrections throughout `check-log.md`; README speedup claim fixed to the
   measured 161–698×.
4. `gllvmTMB#488` — the bridge-drift audit that issue asked for, posted with measurements.

## THE DECISIONS WAITING ON YOU

Nothing below is blocked on effort. Each is a maintainer call.

1. **`hessian` kwarg on the family fitters.** *Highest leverage.* No public fitter exposes
   it, so the plan's own rule — *check by fitting, not evaluating* — **cannot be followed**,
   and flipping any `_default_hessian` silently changes what every fit optimises with no way
   to A/B it. Additive, backward-compatible, needed whichever way the flips go.
2. **The curvature flips themselves.** 6 `_glm_weight` cells + 7 `_tp_pieces` cells still
   open. Measured: this is a **parity change that costs accuracy** (Beta observed is farther
   from the exact marginal in 10/12 cells; the flip moves the marginal down 0.8–4.5 loglik).
   The catastrophic PD-guard risk I once claimed was **measured and refuted — 0 of 20.**
3. **StatsAPI re-rooting** — API change + full convention cascade.
4. **The bridge drift** — R mirror is 6 families and 6 X-families behind the engine. R users
   silently cannot reach zip/zinb/zib/lognormal/betabinomial/truncated_poisson.
5. **Ledger: 1 confirmed overstatement, 8 understatements** (audit of all 80 rows). Includes
   two self-contradictions: bridge mixed-family `implemented` vs native `planned`;
   kernel×indep `planned` vs phylo/animal/spatial `implemented` off the same path.
   `none × dep` needs the `fit_dep_gllvm` identifiability check first.
6. **CI duplication** — `push:[main]` + `pull_request` re-tests an identical tree, ~25
   Linux-equivalent hours per merge.
7. **Version bump 0.3.0 → 0.4.0**, the four `rejected` rows, AGHQ unpark, Tweedie STOP #234.

## DO NOT

- Do not merge to `main` without explicit per-PR authorisation.
- Do not re-raise: S18 cross-validation (twin has no exported CV), the 0.7.0/0.7.1 target
  (0.7.1 adds no capability), stale gh-pages (it is fresh).
- **Do not treat S24 as withdrawn.** It was TRUE and was **closed by `3958210e`**. I recorded
  it as never-needed by reading the tree without checking history. See the correction.
- Do not trust a line-anchored grep's empty result. Three false negatives today
  (`^_glm_weight(`, a `src/families/*.jl` sweep, `^export`). Parse or reflect.
- Do not trust one isolated test run. The guard passed standalone and errored under
  `Pkg.test()` on an undeclared `InteractiveUtils`.

## The honest bottom line

**None of the goal's four clauses is met.** Parity ≈ 73% by the ledger's self-report, and
that figure is provisional — the audit says it understates. The headline fault class is
open on 13 cells across two substrates. What this session actually produced was a smaller,
truer map: five plan slices withdrawn as phantom, one restored, one real defect found, one
guard built, and one risk retired by measurement.
