# After-task — truncated_poisson no-X bridge admit (twin fid 10)

**Date:** 2026-08-19
**Lane:** `cursor/truncpois-nox-bridge-20260819`, worktree
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-truncpois-nox-bridge-20260819`
from `origin/main` @ `d9bd69ca` (#257 multinomial, #259 lognormal,
#260 none-dep Identity). **Not** piled onto OPEN #254 (handover).
**Not** the honesty / AGHQ / none-dep-engine worktrees.
**Identity (locks):** `docs/dev-log/decisions/2026-08-15-truncated-poisson-identity.md`
(ACCEPTED). Engine already on main: `TruncatedPoisson`,
`TruncatedPoissonFit`, `fit_truncated_poisson_gllvm`.
**Reviewed as:** Ada (orchestration / claim wording), Hopper (bridge admit),
Rose (claim-vs-evidence fence).

## Goal

Stated as a check before writing code: `bridge_fit(; y, family = "truncated_poisson", d)`
returns the flat contract with `loglik` / `alpha` / `loadings` matching a
direct `fit_truncated_poisson_gllvm(Y; K)` call to ≤ 1e-8, rejects any
`y < 1` loudly, and rejects X / X_lv / mask / CI at the boundary.
**No-X only.** Paying the bridge admit is this slice. Do **not** invent
a twin Δ.

## What landed

`src/bridge.jl` (the conductor choke point):

- `"truncated_poisson"` inserted after `"zib"` in
  `_BRIDGE_ONEPART_FAMILIES` and `_bridge_family_key` (aliases
  `truncpois` / `truncatedpoisson` / case-folded `TruncPois`).
- `_bridge_fit_onepart` no-X arm (lognormal shape; assemble shared-block
  `ΛΛᵀ` because `TruncatedPoissonFit` has no `getLV` / link-residual /
  `_CIFit` adapter): `fit_truncated_poisson_gllvm`, empty scores,
  communality 1, `dispersion` NaN.
- Fail-loud `all(>=(1), Yf)` before rounding — zeros and non-positive
  cells throw (no silent skip).
- Honest fences: `"truncated_poisson"` in `_BRIDGE_NO_CI_FAMILIES` and
  `_BRIDGE_NO_SCALAR_POSTFIT_FAMILIES`; `_bridge_ci_guard_truncated_poisson`
  throws on any `ci_method` other than `"none"`. Not in
  `_BRIDGE_X_FAMILIES` / `_BRIDGE_XLV_FAMILIES` / `_BRIDGE_MASK_FAMILIES`.
- Capability note names twin fid 10 and says light RCall Δ is still
  **OWED** (not invented).

## Files Changed

| File | Change |
| --- | --- |
| `src/bridge.jl` | family key + one-part membership + no-X arm + y ≥ 1 guard + CI/postfit fences + notes |
| `test/test_bridge_truncated_poisson.jl` | **new** — focused no-X smoke (45 tests) |
| `test/test_bridge_capabilities.jl` | golden: `truncated_poisson` after `zib`; dedicated row assertions |
| `test/runtests.jl` | include the new file |
| `docs/design/capability-status.md` | truncated_poisson note: bridge paid; light RCall Δ still OWED. L47 none × dep stays **planned**. AGHQ rows **untouched** |
| `docs/dev-log/check-log.md` | entry for this arc |
| `docs/dev-log/after-task/2026-08-19-truncpois-nox-bridge.md` | this report |

## Tests Added

`test/test_bridge_truncated_poisson.jl` (45 tests). Clauses satisfied:
bridge vs independent native fitter at 1e-8; loud rejects for X / X_lv /
mask / CI / `y = 0` / `y = 0.4` / mixed-family vector.

## Benchmark Numbers

N/A — no hot-path change. Bridge dispatch only.

## R-Parity Verdict

Parity: **OWED, not invented** — twin fid 10 exists so a Δ is
legitimate, but `GLLVM_PARITY_TESTS` was unset and no live number is
quoted.

## JET / Allocs / Aqua Verdicts

- JET: deferred to CI (Mac-LIGHT); no new type unions or hot-loop code
- Allocs: N/A — no inner-loop change
- Aqua: deferred to CI

## Checks Run

Mac-LIGHT: **no local `Pkg.test()`** — GitHub CI is the verifier for the
full suite (incl. Aqua/JET). `GLLVM_PARITY_TESTS` was unset; no live
RCall Δ was run and **none is invented**.

```
$ julia --project=. --startup-file=no test/test_bridge_capabilities.jl
Test Summary:              | Pass  Total  Time
bridge capabilities ledger |  238    238  0.4s

$ julia --project=. --startup-file=no test/test_bridge_truncated_poisson.jl
Test Summary:                                | Pass  Total   Time
truncated_poisson bridge (no-X, twin fid 10) |   45     45  18.2s
```

What the 45 tests cover: family-key / list membership (after zib; out of
X / X_lv / mask; in no-CI and no-scalar-postfit); the no-X point route
against `fit_truncated_poisson_gllvm` at 1e-8 (`alpha`, rotated loadings,
`loglik`, `LogLink`, unit-diagonal correlation, empty scores, `nobs`);
case-normalised `TruncPois` alias; loud rejection of mask, `X`, `X_lv`,
`ci_method="wald"`, `y = 0`, `y = 0.4`, and `truncated_poisson` inside a
mixed-family vector.

## Consistency Audit

`rg` patterns: `truncated_poisson|TruncPois|twin fid 10` on
`src/bridge.jl`, `test/test_bridge_*.jl`, `docs/design/capability-status.md`.
L47 `none × dep` still `| planned |`. AGHQ rows not edited.
`aghq_grid.jl` not touched.

## GitHub Issue Maintenance

No issue action needed — this is the queued chip-1 bridge admit after
#259, not an issue closer.

## What Did Not Go Smoothly

Prior session left uncommitted WIP on this branch at `d9bd69ca`. This
close-out reviewed that WIP against the #259 clone, added check-log +
after-task, and pasted live Mac-LIGHT tallies. No invented Δ.

## Team Learning

Clone the last paid one-part bridge admit (#259) including the OWED-Δ
sentence; do not invent a number to look finished.

## Remaining Risks

1. **Light RCall Δ** — the one remaining owed truncated_poisson cell.
   Own G0; do not invent a number.
2. **CI** — needs `TruncatedPoissonFit` in `_CIFit` (or a dedicated
   adapter) before `_BRIDGE_NO_CI_FAMILIES` can drop it.
3. **Scores / postfit** — `getLV` / `residuals` / `simulate` for
   `TruncatedPoissonFit` are not on this engine; scores stay `0×0`.
4. **+X / X_lv / masks** — own G0s; not this chip.

## Known Limitations

No-X only. No formula change. No AGHQ. No L47 promote. No twin Δ.

## Next Command

```sh
gh pr checks --watch          # full CI is the verifier for this arc
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — bridge admit paid and fenced; light
RCall Δ still OWED (not invented); L47 stays planned; AGHQ parked.
