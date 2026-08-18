# After Task: AGHQ A4(3) affordability close after #255 merge

## Goal

After #255 MERGED @ `81866b1a`, delete the three `!isdefined` absence
tests plus their #255 comments, and lock the decision addendum:
affordability half **closed** by `_aghq_kd_bound`; eligibility still
declared-kwargs.

## Implemented

On `cursor/lane-aghq-a43-afford-20260818` (affordability worktree only;
honesty worktree not written). `origin/main` already at `81866b1a`
(`git merge origin/main` = already up to date). The three `#253`
`!isdefined` rows (`_aghq_kd_bound`, `_aghq_d_bound`, `aghq_gate`)
were deleted in `c9fbba47`; this closeout drops the leftover
eligibility-helper testset / #255 comments from
`test/test_aghq_gate.jl`. `test/test_aghq_kd_bound.jl` kept (29/29).
Addendum `docs/dev-log/decisions/2026-08-18-aghq-a43-afford.md` now
records #255 MERGED and closes the wait-language. A short pointer on
the gate note marks the historical "affordability remains open"
sentences as superseded. No `aghq_gate` invented. No public `aghq=`.
Ledger AGHQ rows stay `missing`.

## Mathematical Contract

Twin AGHQ remains Liu & Pierce 1994 adaptive Gauss–Hermite of the joint
integrand at the Laplace mode (Identity
`docs/dev-log/decisions/2026-08-17-aghq-identity.md`). A4(3)
affordability is a **tensor-size / latent-dimension** cost bound on
dense loadings-only `z_B`, analogue of twin `tw ≤ 4` (`d ≤ 5` on a
complete graph), **not** a treewidth measurement. Hopper pin: cite
`gllvmTMB` `R/aghq-gate.R`; do not re-derive. `k = 1` still ≡ Laplace.
Eligibility remains declared-kwargs.

## Files Changed

- `test/test_aghq_gate.jl` — leftover `#255` comments / redundant
  testset removed (absence rows already gone)
- `test/test_aghq_kd_bound.jl` — header only; suite kept
- `docs/dev-log/decisions/2026-08-18-aghq-a43-afford.md` — addendum
  lock after #255 MERGED
- `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md` — pointer
  addendum; eligibility still declared-kwargs
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/after-task/2026-08-18-aghq-a43-afford-close.md` — this
  report
- `LOOP/checkpoint.md`, `LOOP/arcs.md`,
  `LOOP/lanes/aghq-a43-afford-20260818/README.md` — 2c/2d done

Not edited: `LOOP/GOAL.md` (overnight IMMUTABLE); `src/`;
`docs/design/capability-status.md` (both AGHQ rows stay `missing`).
Honesty worktree and Dropbox checkout not touched.

## Tests Added

None new. Absence-row deletion is the test change. Bound coverage
already in `test/test_aghq_kd_bound.jl` (boundary + independent
Laplace golden at `k=1` `d=6`; eligibility still wins over the bound).

## Benchmark Numbers

N/A — no hot-path change in this closeout (helper already on the
branch).

## R-Parity Verdict

Parity: N/A — change does not touch the parity surface. Twin
`.aghq_gate` is cited from `R/aghq-gate.R`, not from a Julia number.

## JET / Allocs / Aqua Verdicts

- JET: N/A — Mac-light only; full suite = GitHub CI
- Allocs: N/A
- Aqua: N/A

## Checks Run

```
~/.juliaup/bin/julia --project=. -e 'include("test/test_aghq_gate.jl"); include("test/test_aghq_kd_bound.jl")'
# cwd = affordability worktree
# Test Summary: AGHQ A4(3) fail-loud gate | 30  30  3.1s
# Test Summary: AGHQ A4(3) k^d / d≤5 affordability bound | 29  29  0.1s
```

## Consistency Audit

```
rg '!isdefined' test/test_aghq_gate.jl
# empty

rg 'function aghq_gate|_aghq_d_bound|spHess|min.?fill' src
# comment only: `_aghq_d_bound` and `aghq_gate` stay undefined

rg 'aghq=' src/families/fit_gllvm.jl
# empty

rg 'AGHQ estimator|Broad AGHQ' docs/design/capability-status.md
# both rows `missing`
```

README / CLAUDE.md / user-facing docs not edited (no public surface).

## GitHub Issue Maintenance

No issue close. PR #256 already OPEN — push this closeout; do **not**
`gh pr merge`. Honesty worktree not written.

## What Did Not Go Smoothly

A sandboxed first run resolved `test/` against the honesty workspace
and reported the #255 `34/34` tally. Re-ran from the affordability
worktree with absolute paths: **30/30** and **29/29**. Do not quote
the honesty-tree 34/34 as this slice.

## Team Learning

#255 merge unblocks the absence-test delete. Eligibility and
affordability stay two halves — closing the second must not rewrite
the first as model inspection.

## Remaining Risks

- Arc 3 (`false` vs omitted kwargs) is **not** closed.
- A4(4) and A4(5) are **not** closed.
- Both AGHQ ledger rows stay `missing`.
- Rose fence is for sibling Rose — not a self-signed PASS.

## Known Limitations

Not a TMB `.aghq_gate` / `spHess` / min-fill port. Not an estimator.
No public `aghq=`. No twin Δ. Tweedie `fit_gllvm` still STOP.

## Next Command

Sibling: push onto open PR #256. Do **not** merge.

## Rose fence (for sibling Rose — not a self-signed PASS)

Ada authored this closeout. Do **not** treat this section as a Rose PASS.

Fence claims sibling Rose must verify:

1. **NOT a TMB gate port** — no `spHess`, no min-fill, no `.aghq_gate`
   name copy.
2. **NOT an estimator** — no public `aghq=`; no quadrature-fitted model
   advertised.
3. **Ledger rows stay `missing`** — `AGHQ estimator` and
   `Broad AGHQ (Julia)` are not flipped.
4. This slice closes the **affordability** half only
   (`_aghq_kd_bound`).
5. Eligibility stays declared-kwargs (#253 / #255).
6. A4(4) and A4(5) are not closed.
7. `LOOP/GOAL.md` (overnight) was not edited.
8. Honesty worktree was not written.

Rose owns PASS / PASS WITH NOTES / FAIL.
