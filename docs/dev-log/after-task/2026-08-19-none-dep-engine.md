# After-task — none × dep() Gaussian matrix fitter (K = p)

**Date:** 2026-08-19
**Lane:** `cursor/lane-none-dep-engine-20260818` only, worktree
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-lane-none-dep-engine-20260818`.
Did **not** create a third branch. Did **not** use
`cursor/none-dep-engine-20260818` (premature L47 `implemented` flip
discarded). Rematched onto `origin/main` @ `d9bd69ca` (#257 / #259 /
#260). **Not** piled onto OPEN #254 (handover).
**Identity (locks):** `docs/dev-log/decisions/2026-08-18-none-dep-identity.md`
(ACCEPTED, #260). Twin pin `gllvmTMB` `b8a1891a` / blob `e1922dbf`.
**Reviewed as:** Ada (orchestration), Gauss (packing / Gaussian wrap),
Rose (L47 / formula / Δ fences).

## Goal

Stated as a check before writing code: `fit_dep_gllvm(Y; family = Normal())`
returns a `GllvmFit` whose `logLik` and packed `Λ` match
`fit_gaussian_gllvm(Y; K = p)` to ≤ 1e-8, with packed-L FD ≤ 1e-6 and
`rr_theta_len(p, p) = p(p+1)/2`. `K` / `num_lv`, W-tier, `has_diag`,
and phylo kwargs fail loud. **No** `@formula` `dep()`. Do **not** invent
a twin Δ. L47 stays **planned**.

## What landed

`src/none_dep.jl`:

- Exported `fit_dep_gllvm` — Gaussian wrapper, rank forced to `K = p`.
- Reuses `pack_lambda` / `unpack_lambda` / `rr_theta_len(p, p)`.
- Fail-loud: any supplied `K` or `num_lv`; `K_W ≠ 0`; `has_diag=true`;
  `K_phy` / `has_phy_unique` / `Σ_phy`; non-`Normal` family.
- Does **not** open `formula.jl`. Does **not** touch `bridge.jl` or
  `aghq_grid.jl`. Does **not** flip L47.

## Files Changed

| File | Change |
| --- | --- |
| `src/none_dep.jl` | **new** — `fit_dep_gllvm` Gaussian K=p wrapper + fail-loud |
| `src/GLLVM.jl` | `include` + export |
| `test/test_none_dep.jl` | **new** — free count / FD / match / fail-loud (37 tests) |
| `test/runtests.jl` | include the new file |
| `docs/dev-log/check-log.md` | entry for this arc |
| `docs/dev-log/after-task/2026-08-19-none-dep-engine.md` | this report |
| `LOOP/lanes/none-dep-engine-20260818/GOAL.md` | lane kit (already present) |

`docs/design/capability-status.md` **not** edited. L47 remains
`| planned |`.

## Tests Added

`test/test_none_dep.jl` (37 tests). Clauses: independent packing length;
FD vs ForwardDiff ≤ 1e-6; match `fit_gaussian_gllvm(Y; K = p)` ≤ 1e-8;
loud rejects for forbidden knobs.

## Benchmark Numbers

N/A — no hot-path change. Thin wrapper around the existing Gaussian
fitter.

## R-Parity Verdict

Parity: **N/A / forbidden** — a twin light Δ would be invented. Julia
now evaluates the matrix estimand; a later RCall cell may quote a live
number. This chip does not.

## JET / Allocs / Aqua Verdicts

- JET: deferred to CI (Mac-LIGHT)
- Allocs: N/A — no inner-loop change
- Aqua: deferred to CI (new export `fit_dep_gllvm`)

## Checks Run

Mac-LIGHT: **no local `Pkg.test()`**. `GLLVM_PARITY_TESTS` unset.

```
$ julia --project=. --startup-file=no test/test_none_dep.jl
Test Summary:            | Pass  Total  Time
none × dep matrix fitter |   37     37  8.1s
```

## Consistency Audit

`rg` patterns: `dep\(|fit_dep_gllvm|FunctionTerm` on `src/` and
`docs/design/capability-status.md`. No formula `dep()` sugar. L47 still
`planned`. `aghq_grid.jl` not touched. `bridge.jl` not touched (TruncPois
#261 owns that file).

## GitHub Issue Maintenance

No issue action needed — queued chip 2 after Identity #260.

## What Did Not Go Smoothly

Two existing none-dep worktrees. Used only
`cursor/lane-none-dep-engine-20260818`. The other worktree's premature
L47 `implemented` flip was discarded (file not copied). Rematch onto
`d9bd69ca` was a fast-forward; a second rematch is owed if #261
(TruncPois) merges first because `check-log.md` is hot.

## Team Learning

Do not flip a ledger row from a second worktree before tests pass, and
do not race a sibling chip on `bridge.jl` / `capability-status.md`.

## Remaining Risks

1. **L47 still planned** — engine + tests exist; public promote waits
   for a later Rose flip.
2. **No formula `dep()`** — v1 still rejects FunctionTerm / `(… | g)`.
3. **No twin Δ** — not invented.
4. **Gaussian only** — non-Normal family throws.
5. **Combo `dep`+`latent` fail-loud** waits for FunctionTerm sugar
   (Identity: abort body is not in `brms-sugar.R`).

## Known Limitations

No `@formula` `dep()`. No phylo/animal/spatial/kernel dep. No bridge
route. No AGHQ. No L47 promote.

## Next Command

```sh
gh pr checks --watch          # full CI is the verifier for this arc
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — matrix fitter paid and fenced; L47
stays planned; ≠ formula `dep()`; ≠ twin Δ; AGHQ parked.
