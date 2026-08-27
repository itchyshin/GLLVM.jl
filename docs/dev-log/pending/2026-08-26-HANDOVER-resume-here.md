# HANDOVER — GLLVM.jl (2026-08-26, supersedes the 2026-08-25 file)

Resume: read `AGENTS.md`, then this, then reconcile against live `git`/`gh` before touching
anything. **Verify every claim here against the code.** This session refuted three of its
own conclusions and two of an adversarial reviewer's — confident-but-wrong records are the
documented failure mode of this repo, and I added to the pile before catching it.

## Lane

`PLATFORM: claude` · `BRANCH: claude/lane-beyond-20260824` ·
`WORKTREE: /Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824`
**MERGED.** PR #266 landed at `ba3587b1`, all six checks green (macOS 1h33m, ubuntu-1.10
1h56m, ubuntu 2h14m, windows 2h17m, Documenter + deploy). 18 commits, including the
session's only `src/` changes.

**One commit is stranded locally: `a28fb865`** (drops `push:[main]` from `CI.yml`). The
push is rejected — *"refusing to allow an OAuth App to create or update workflow ... without
`workflow` scope"*. Fix: `gh auth refresh -s workflow -h github.com`, then push. Until it
lands, every merge still burns ~25 Linux-equivalent hours re-testing an identical tree.
**The Dropbox checkout is a STALE FORK — never commit there.**

## LANDED ON MAIN — two user-facing bugs are fixed for real users

Both reproduced on live fits before being touched, both the same pattern: a large FINITE
penalty on a failure path that downstream code read as a real value.

1. **`fit_phylo_gaussian` reported `converged = true` on a fit containing `NaN`**, with
   `negll = 1.0e12` flowing into `aic`/`bic`/`select_lv`. Fixed by `_phylo_verdict`
   (`src/fit_phylo.jl:92`), mirroring `_tweedie_verdict`.
2. **Wald intervals collapsed toward false certainty** — `se = 1.22e-10` against an
   estimate of `1.66e-3`, `pd_hessian` still `true`. Fixed by `_fd_failed`
   (`src/confint_family.jl:1867`); "no interval" now replaces a confidently wrong one.

## THE BIGGEST REMAINING CORRECTNESS LEVER

`_tweedie_verdict` is the correct pattern and is applied at **3 of 268 sentinel sites**
across 51 files. The two fixed above were the two I could reproduce; the rest are
unaudited. An audit was running at hand-over — check
`docs/dev-log/check-log.md` for its result before assuming anything about it.

**The discriminator matters and is easy to get wrong:** a sentinel INSIDE an objective
closure is *correct* — it is a barrier keeping the line search out of a bad region. It is a
defect only when it ESCAPES into a user-visible field (a `converged` flag, a returned
loglik, an SE, a CI bound). `Optim.minimum(res)` carrying the value out is the classic
escape, and is exactly how both confirmed bugs worked. Do not "fix" the barriers.

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

## Rose audit — RAN, and found four defects (all fixed)

The goal's DISCIPLINE requires `closure = after-task report + Rose audit`. Both are done.
Rose found four citable defects, **three of them inside artifacts written to fix earlier
sloppiness** — including the drift fence undercounting the engine's own X surface by one
(the fence making the error the fence exists to prevent). That wrong number had gone public
at `gllvmTMB#488`; corrected there too.

**Rose confirmed clean:** the `14 _glm_weight + 8 _tp_pieces` census and every bucket
assignment, independently re-enumerated; README's 161–698× against the benchmarks table;
the guard's assertions non-vacuous, each traceable to an invariant that fails under a
concrete mutation.

**Rose's two carried-forward pre-tag blockers:**

1. **`~340×`** — fenced on `docs/src/gllvmtmb-parity.md`, left alone in `changelog.md`
   (already corrected there), and **NOT touched in `CLAUDE.md:7` / `AGENTS.md:13`, which
   need your approval.** The repo therefore states the claim two ways right now.
2. **These 11 commits have never been through CI.** The workflow triggers only on
   `push:[main]` / `pull_request` and no PR is open. The suite tally below is
   self-reported. **Opening a PR is the fix and I did not do it — every PR so far was
   authorised individually.**

## THE DECISIONS WAITING ON YOU

Nothing below is blocked on effort. Each is a maintainer call.

1. **`hessian` kwarg on the family fitters.** *Highest leverage.* No public fitter exposes
   it, so the plan's own rule — *check by fitting, not evaluating* — **cannot be followed**,
   and flipping any `_default_hessian` silently changes what every fit optimises with no way
   to A/B it. Additive, backward-compatible, needed whichever way the flips go.
2. **The curvature flips themselves. The class is 11, not 13 — measured.**
   6 `_glm_weight` cells + **5** `_tp_pieces` cells. DeltaLogNormal and HurdlePoisson have
   Fisher ≡ observed **exactly** (0.0 % gap) and were never open; they are now
   machine-verified as exempt.

   The five open two-part families are **not** marginal, and they are a different case from
   the single-part ones:

   | family | worst rel gap | negative-observed cells |
   |---|---|---|
   | ZINB | **1223 %** | 3 |
   | ZIPoisson | 280 % | 3 |
   | HurdleNB | 251 % | 0 |
   | ZIB | 214 % | **6 of 18** |
   | BetaHurdle | 127 % | 2 |

   **ZIB is the one to look at first** — negative observed curvature in a third of probe
   cells is a genuine PD-guard risk, where the same risk for Beta measured **0 of 20**.

   For the **single-part** cells the earlier finding stands: a **parity change that costs
   accuracy** (Beta observed is farther from the exact marginal in 10/12 cells; the flip
   moves the marginal down 0.8–4.5 loglik). Those still need the `hessian` kwarg first.
   The two-part kernel already has one (`twopart.jl:105`), so that substrate is testable
   today.
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
