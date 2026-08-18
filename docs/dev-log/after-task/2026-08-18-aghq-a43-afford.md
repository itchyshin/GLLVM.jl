# After Task: AGHQ A4(3) affordability half (docs)

## Goal

Record that this slice **closes** the A4(3) **affordability** half
(cheap `k^d` / `d ≤ 5` on dense loadings-only `z_B`) without rewriting
#255’s declared-kwargs eligibility paragraph, without porting TMB
`.aghq_gate`, and without promoting either AGHQ ledger row.

## Implemented

Docs-only on `cursor/lane-aghq-a43-afford-20260818`. New decision
addendum `docs/dev-log/decisions/2026-08-18-aghq-a43-afford.md` locks
the split: eligibility stays declared-kwargs (#253 / #255); this slice
closes affordability. Live afford GOAL lives at
`LOOP/lanes/aghq-a43-afford-20260818/GOAL.md`. Origin/main
`LOOP/GOAL.md` (overnight) was **not** edited.

Noether shipped `_aghq_kd_bound` on `src/families/aghq_grid.jl` @
`7b4ad0f3` (fail-loud at `k > 1` and `d > 5`; `k = 1` still ≡ Laplace).
This Ada commit does not edit `src/` or `test/`. Deleting the `#253`
`!isdefined` absence tests **waits** for #255 merge.

## Mathematical Contract

Twin AGHQ remains Liu & Pierce 1994 adaptive Gauss–Hermite of the joint
integrand at the Laplace mode (Identity
`docs/dev-log/decisions/2026-08-17-aghq-identity.md`). A4(3)
affordability is a **tensor-size / latent-dimension** cost bound on
dense loadings-only `z_B`, analogue of twin `tw ≤ 4` (`d ≤ 5` on a
complete graph), **not** a treewidth measurement. Hopper pin: cite
`gllvmTMB` `R/aghq-gate.R`; do not re-derive. `k = 1` still ≡ Laplace.

## Files Changed (this Ada commit)

- `LOOP/lanes/aghq-a43-afford-20260818/GOAL.md` — afford GOAL copy
- `LOOP/lanes/aghq-a43-afford-20260818/README.md` — kit pointer
- `docs/dev-log/decisions/2026-08-18-aghq-a43-afford.md` — addendum
- `docs/dev-log/after-task/2026-08-18-aghq-a43-afford.md` — this report

Not edited: `LOOP/GOAL.md`; `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`
(#255 path); `docs/dev-log/check-log.md` (#255 path); `src/`; `test/`.
`docs/design/capability-status.md` **not** edited; both AGHQ rows stay
`missing`. Honesty worktree **not** touched.

## Tests Added

None in this commit. Noether owns `test/test_aghq_gate.jl`.

## Benchmark Numbers

N/A — docs only.

## R-Parity Verdict

Parity: N/A — change does not touch the parity surface. Twin
`.aghq_gate` is cited from `R/aghq-gate.R`, not from a Julia number.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no `src/` in this commit
- Allocs: N/A
- Aqua: N/A

## Checks Run

None in this commit (docs). Mac-light of the helper is Noether’s.

## Consistency Audit

```
# this commit must not touch:
LOOP/GOAL.md
docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md
docs/dev-log/check-log.md
src/
test/
```

README / CLAUDE.md / user-facing docs not edited (no public surface).

## GitHub Issue Maintenance

No issue close. No push. No `gh pr create` / `gh pr merge` from this
worktree. OPEN GATE = sibling push/PR.

## What Did Not Go Smoothly

`LOOP/GOAL.md` on the fresh worktree is the overnight IMMUTABLE file
from `origin/main`. Afford GOAL was written under `LOOP/lanes/` so that
file stays frozen. #255 is OPEN and owns the gate-note paragraph that
still says affordability is open — this addendum does not patch it.

## Team Learning

A4(3) is two halves. Eligibility = declared-kwargs throw. Affordability
= cheap `k^d` / `d ≤ 5`. Closing the second half must not rewrite the
first half’s honesty PR.

## Remaining Risks

- `#253` `!isdefined` absence-test deletion **waits** for #255 merge
  (helper `_aghq_kd_bound` already on this branch @ `7b4ad0f3`).
- Arc 3 (`false` vs omitted kwargs) is **not** closed.
- A4(4) and A4(5) are **not** closed.
- Both AGHQ ledger rows stay `missing`.
- #255 still OPEN; do not rewrite its gate-note paragraph until it merges.
- `docs/dev-log/check-log.md` prepend **waits** for #255 merge (Opus
  sequencing). Not touched in this commit.


## Known Limitations

Not a TMB `.aghq_gate` / `spHess` / min-fill port. Not an estimator.
No public `aghq=`. No twin Δ. Tweedie `fit_gllvm` still STOP.

## Next Command

Sibling: named-path commits for `src/families/aghq_grid.jl` +
`test/test_aghq_gate.jl` (Noether). Sibling Rose: fence pass below.
Do **not** push or open a PR from this worktree.

## Rose fence (for sibling Rose — not a self-signed PASS)

Ada authored these docs. Do **not** treat this section as a Rose PASS.

Fence claims sibling Rose must verify:

1. **NOT a TMB gate port** — no `spHess`, no min-fill, no `.aghq_gate`
   name copy.
2. **NOT an estimator** — no public `aghq=`; no quadrature-fitted model
   advertised.
3. **Ledger rows stay `missing`** — `AGHQ estimator` and
   `Broad AGHQ (Julia)` are not flipped.
4. This slice closes the **affordability** half only.
5. Eligibility stays declared-kwargs (#253 / OPEN #255). This addendum
   does not rewrite #255’s paragraph.
6. A4(4) and A4(5) are not closed.
7. `LOOP/GOAL.md` (overnight) was not edited.

Rose owns PASS / PASS WITH NOTES / FAIL.
