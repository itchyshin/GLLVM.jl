# After Task: none × dep() Identity (docs-only ACCEPTED)

## Goal

Lock the twin estimand for standalone `dep(0 + trait | g)` before any
Julia `dep()` sugar, without opening `src/` or promoting the ledger.

## Implemented

Docs-only Identity. `docs/dev-log/decisions/2026-08-18-none-dep-identity.md`
is **ACCEPTED**. Twin cites are the closed `git show` pin only. Ledger
`docs/design/capability-status.md` was **not** edited (L47 stays
`planned`). Check-log appended. No engine G0.

## Mathematical Contract

Standalone `dep()` fits unstructured \(T \times T\) \(\boldsymbol\Sigma\) with
\(T(T+1)/2\) free parameters, PSD via Cholesky
\(\boldsymbol\Sigma = \mathbf{L}\mathbf{L}^\top\) (twin L1661–1662, L1681–1682,
L32). Same estimand as standalone `latent(..., d = T)`. `dep` + `latent`
on the same grouping is documented as over-parameterised (L1694–1698);
the `cli_abort` **body is not** in `R/brms-sugar.R`.

## Files Changed

- `docs/dev-log/decisions/2026-08-18-none-dep-identity.md` — new Identity
- `docs/dev-log/check-log.md` — this slice (append-only)
- `docs/dev-log/after-task/2026-08-18-none-dep-identity.md` — this report
- `LOOP/GOAL.md`, `LOOP/ultra-plan.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`

## Tests Added

None. Docs-only Identity. Mac-light N/A. `git grep -n 'dep(' 3d5acba0 -- src/`
empty (exit 1).

## Benchmark Numbers

N/A — no hot-path change.

## R-Parity Verdict

Parity: N/A — Julia cannot evaluate `dep()`. A light Δ would be invented.

## JET / Allocs / Aqua Verdicts

- JET: N/A — no `src/` change
- Allocs: N/A — no `src/` change
- Aqua: N/A — no Project.toml change

## Checks Run

```
git show origin/main:docs/design/capability-status.md   # L47 planned (not edited)
git grep -n 'dep(' 3d5acba0 -- src/                     # empty, exit 1
git diff --name-only origin/main -- src                 # empty
```

Mac-light: N/A. Full suite = GitHub CI if a sibling opens the docs-only PR.

## Consistency Audit

```
rg -n 'capability-status' docs/dev-log/decisions/2026-08-18-none-dep-identity.md
# cited, not edited
rg -n 'cli_abort' docs/dev-log/decisions/2026-08-18-none-dep-identity.md
# documented as NOT in R/brms-sugar.R
```

`docs/design/capability-status.md` not in the diff. `phylo_dep` (twin L1787)
not this slice. Tweedie / AGHQ / #255–259 not touched.

## GitHub Issue Maintenance

No issue action. This is a fence, not a close.

## What Did Not Go Smoothly

An earlier draft pinned stale twin SHA `3cedd849` and a content-hash
that was not the closed blob `e1922dbf`, and over-claimed that
`brms-sugar.R` raises `cli_abort`. Patched to the closed pin before
commit.

## Team Learning

Identity-STOP for a *planned covariance keyword* is the lognormal
Identity shape (lock estimand before sugar), plus an extra honesty
rule: Rd that *documents* `cli_abort` is not the abort implementation.

## Remaining Risks

- A later engine can still invent a Δ or flip L47 on grammar rename.
- Parser / `fit-multi.R` guards were named, not re-derived in this slice.
- `scalar()` remains absent from the Julia grid (out of this Identity).

## Known Limitations

No Julia `dep()`. No ledger promote. No twin Δ. `phylo_dep` / animal /
kernel not started. Mac-light N/A.

## Next Command

Sibling push + docs-only `gh pr create` (OPEN GATE). Do **not**
`gh pr merge`. Do not start the engine.

## Rose Verdict

Rose verdict: PASS WITH NOTES — docs-only lock; L47 stays `planned`;
`capability-status.md` not edited; no `src/`; no invented Δ; twin
`cli_abort` body not claimed in `brms-sugar.R`; Mac-light N/A
(CI is the verifier if a PR opens).
