# After Task: AGHQ A4(3) honesty follow-up (declared-kwargs)

## Goal

Record Opus MIXED on merged #253 without rewriting the eligibility lock
as unpaid: declared-kwargs fail-loud is landed; affordability (`k^d` /
`d ≤ 5`) stays open; omitted kwargs and the `false`-vs-`nothing`
inconsistency are later engine.

## Implemented

Docs/comment honesty on `cursor/a43-honesty-20260818` from
`origin/main` @ `3d5acba0`. Decision
`docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md` now names the
helper as the A4(3) **eligibility** gate: it rejects **declared** extras
and does not inspect the model. `LOOP/arcs.md` / `LOOP/checkpoint.md`
record #253 MERGED and fence affordability. Two comments on the
`!isdefined` absence tests in `test/test_aghq_gate.jl` say those tests
are not a closed affordability claim. No `src/` change. No public
`aghq=`. Both AGHQ ledger rows stay `missing`.

## Mathematical Contract

Unchanged from #253. Twin AGHQ remains Liu & Pierce 1994 adaptive
Gauss–Hermite of the joint integrand at the Laplace mode (Identity
`docs/dev-log/decisions/2026-08-17-aghq-identity.md`). Hopper pin:
`gllvmTMB` `R/aghq-gate.R` @ `b926f47f`; do not re-derive. A4(3)
affordability is still the optional dense `k^d` / `d ≤ 5` cost analogue,
not a TMB treewidth measurement, and not present as an engine helper.

## Files Changed

- `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md` — declared-kwargs
  contract; affordability still open; `false` inconsistency later
- `LOOP/arcs.md` — A3 MERGED; eligibility done; affordability open
- `LOOP/checkpoint.md` — overnight /goal DONE on eligibility only
- `test/test_aghq_gate.jl` — two comments on the absence tests
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/after-task/2026-08-18-aghq-a43-honesty.md` — this report

`src/families/aghq_grid.jl` unchanged. `docs/design/capability-status.md`
**not** edited; both AGHQ rows stay `missing`. Tweedie / Dropbox
checkout **not** touched. `LOOP/GOAL.md` left IMMUTABLE.

## Tests Added

None. Comment-only on existing `!isdefined` tests. Gate behavior
unchanged.

## Benchmark Numbers

N/A — no hot-path change.

## R-Parity Verdict

Parity: N/A — docs/comments only. Twin `.aghq_gate` is cited from
`R/aghq-gate.R` @ `b926f47f`, not from a Julia number.

## JET / Allocs / Aqua Verdicts

- JET: not run locally (Mac-light; CI is the verifier)
- Allocs: N/A
- Aqua: N/A — no Project.toml change

## Checks Run

```
julia --project=. --startup-file=no test/test_aghq_gate.jl
# Test Summary: AGHQ A4(3) fail-loud gate | Pass 34  Total 34  Time 3.0s
```

Mac-light: no local `Pkg.test`. Full suite = GitHub CI.

## Consistency Audit

```
rg -n 'function aghq_gate|_aghq_kd_bound|_aghq_d_bound' src
# empty — affordability helper still not invented

rg -n 'aghq=' src/families/fit_gllvm.jl
# not added
```

README / CLAUDE.md / user-facing docs not edited (no public surface).
`capability-status.md` AGHQ prose from the #248 era is still stale
after #251 (`src/families/aghq_grid.jl`); both status cells stay
`missing`. That prose chip is **not** this PR.

## GitHub Issue Maintenance

No issue close. Do **not** treat #253 as unpaid. Do **not**
`gh pr merge --auto`. Handover PR #254 stays unmerged by the agent.

## What Did Not Go Smoothly

Moving the Cursor agent root into this worktree briefly stole
`cursor/handover-20260818` (handover worktree went detached). Restored
before commit: honesty @ `3d5acba0` with the four dirty files; handover
worktree back on `edc74bd7`.

## Team Learning

`!isdefined` absence tests record that a helper was **not** invented;
they do not close the unpaid half of the same clause. Declared
`false` is not the same as an omitted kwarg on this gate.

## Remaining Risks

- A4(3) affordability (`k^d` / `d ≤ 5`) is **open**.
- Omitted-kwargs detection and the `false`-vs-`nothing` fence remain
  later engine. Blast radius is zero today — nothing public calls the
  site evaluator.
- A4(4) / A4(5) are **not** closed. Identity §A3 still forbids a stub
  `aghq=`.
- Seven-arc ultra-plan G0 is unpaid. Do not start arcs 2–5 together.
- Full suite not run locally (Mac-light; CI is the verifier).

## Known Limitations

Not a TMB `.aghq_gate` / `spHess` / min-fill port. No public `aghq=`.
No estimator. No twin Δ. Optional `k^d` / `d ≤ 5` helper not added.
Tweedie `fit_gllvm` still STOP. Overnight LOOP/GOAL.md left IMMUTABLE.

## Next Command

Push this branch and open a docs/comment PR. Do **not** start A4(4),
A4(5), leftover-1, or a TMB gate port. Do **not** execute the seven
arcs. Wait G0 on the cited ultra-plan. Do **not** merge handover #254
from the agent.

## Rose Verdict

Rose verdict: not claimed here. This report records Mac-light 34/34
and the declared-kwargs / affordability-open fences only. Rose owns
PASS / PASS WITH NOTES / FAIL.
