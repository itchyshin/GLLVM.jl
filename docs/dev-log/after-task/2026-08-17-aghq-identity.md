# After Task: AGHQ estimator Identity (docs-only STOP)

## Goal

Lock that Julia has no AGHQ estimator, that VA Gauss–Hermite is not AGHQ,
and that the next engine is a campaign — without opening `src/` or inventing
a twin Δ.

## Implemented

Docs-only Identity + ledger honesty. `docs/dev-log/decisions/2026-08-17-aghq-identity.md`
records A1–A5 (status stays `missing`; VA GH ≠ AGHQ; no stub knob; campaign
not admit; no bridge / no Δ). `docs/design/capability-status.md` keeps both
AGHQ tokens as `missing` and adds the twin-file citation plus an evidence
pointer. Check-log entry written. No family-row token flipped. Tweedie
`fit_gllvm` not opened.

## Mathematical Contract

Twin AGHQ (read-only at `gllvmTMB` @ `114a227e`) is Liu & Pierce 1994
adaptive Gauss–Hermite of the full joint integrand at the Laplace mode.
Julia VA `_gauss_hermite` evaluates an ELBO expectation. This slice
implements neither integral; it forbids conflating them.

## Files Changed

- `docs/dev-log/decisions/2026-08-17-aghq-identity.md` — new Identity
- `docs/design/capability-status.md` — AGHQ note + evidence pointer
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/after-task/2026-08-17-aghq-identity.md` — this report

## Tests Added

None. Docs-only Identity, matching #239 / #242 / #243. `rg -n -i aghq src test`
on `51ffa320` is empty (the absence check).

## Benchmark Numbers

N/A — no hot-path change.

## R-Parity Verdict

Parity: N/A — change does not touch the parity surface. Twin AGHQ is cited
from files, not from a Julia number. A light Δ would be invented.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no `src/` change
- Allocs: N/A — no `src/` change
- Aqua: N/A — no Project.toml change

## Checks Run

```
rg -n -i aghq src test
# empty (only ledger rows under docs/design/)

git rev-parse --short HEAD   # 51ffa320 before this commit
```

Mac-light: no `Pkg.instantiate`, no local `Pkg.test`. Full suite = GitHub CI.

## Consistency Audit

```
rg -n -i 'aghq' src test docs/src docs/design
# src/test empty; docs/design tokens stay missing; new Identity + notes
rg -n 'fit_gllvm.*[Tt]weedie|_fit_gllvm\(::Tweedie' src
# not opened
```

README / CLAUDE.md / `gllvmtmb-parity.md` not edited (user-facing API
unchanged; estimation-method row there is gllvm-VA vs Julia-Laplace, not
this twin-AGHQ lock).

## GitHub Issue Maintenance

No issue action. This is a fence, not a close.

## What Did Not Go Smoothly

Worktree branch name already existed at `51ffa320` (empty); reused.
`using GLLVM` probe skipped: worktree depot not instantiated (Mac-light).
Lane-check warned about stale merged feature branches on
`capability-status.md` / `check-log.md` (COM-Poisson / Student-t / ZIB
bridge) — those commits are already on `origin/main`; #247 owns only the
overnight handoff file.

## Team Learning

Identity-STOP for a *missing estimator* is the same shape as Tweedie #234
(lock before a public knob), not the Hurdle-NB #242 shape (lock then admit).

## Remaining Risks

- Twin AGHQ is opt-in experimental even on the R side; a later Julia
  campaign must not over-claim past the twin's own Rd fence.
- `scalar()` mode and cross-validation remain cheap missing ledger rows
  (explicitly out of this Identity).

## Known Limitations

No Julia AGHQ. No stub keyword. No twin Δ. Tweedie `fit_gllvm` still STOP.

## Next Command

Wait full Julia + Documenter SUCCESS, then `gh pr merge N --merge`
(never `--auto`). Do not open Tweedie `fit_gllvm`.

## Rose Verdict

Rose verdict: PASS WITH NOTES — docs-only lock; both AGHQ rows stay
`missing`; no engine, no Δ, no Tweedie admit; local full-suite not run
(Mac-light, CI is the verifier).
