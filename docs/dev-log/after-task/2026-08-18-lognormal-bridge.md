# After-task — lognormal no-X bridge admit (twin fid 3)

**Date:** 2026-08-18
**Lane:** `cursor/lognormal-bridge-20260818`, worktree
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-lognormal-bridge-20260818`
from `origin/main` @ `3d5acba0` (#253). **Not** piled onto OPEN #257
(multinomial). **Not** the honesty / AGHQ worktree.
**Identity (locks):** `docs/dev-log/decisions/2026-08-15-lognormal-identity.md`
(ACCEPTED). Engine already on main: `Lognormal`, `LognormalFit`,
`fit_lognormal_gllvm`.
**Reviewed as:** Ada (orchestration / claim wording), Hopper (bridge admit),
Rose (claim-vs-evidence fence).

## Goal

Stated as a check before writing code: `bridge_fit(; y, family = "lognormal", d)`
returns the flat contract with `loglik` / `alpha` / `loadings` matching a
direct `fit_lognormal_gllvm(Y; K)` call to ≤ 1e-8, and rejects X / X_lv /
mask / CI at the boundary. **No-X only.** Paying the bridge admit is this
slice. Do **not** invent a twin Δ.

## What landed

`src/bridge.jl` (the conductor choke point):

- `"lognormal"` inserted after `"poisson"` / before `"binomial"` in
  `_BRIDGE_ONEPART_FAMILIES` and `_bridge_family_key`.
- `_bridge_fit_onepart` no-X arm (poisson/gamma shape; assemble like ZIP
  because `LognormalFit` has no `getLV` / link-residual / `_CIFit` adapter):
  `fit_lognormal_gllvm`, shared-block `ΛΛᵀ` Sigma, empty scores, shared
  scalar `σ` in `dispersion`.
- Honest fences: `"lognormal"` in `_BRIDGE_NO_CI_FAMILIES` and
  `_BRIDGE_NO_SCALAR_POSTFIT_FAMILIES`; `_bridge_ci_guard_lognormal` throws
  on any `ci_method` other than `"none"`. Not in `_BRIDGE_X_FAMILIES` /
  `_BRIDGE_XLV_FAMILIES` / `_BRIDGE_MASK_FAMILIES`.
- Capability note names twin fid 3 and says light RCall Δ is still **OWED**
  (not invented).

## Files changed

| File | Change |
| --- | --- |
| `src/bridge.jl` | family key + one-part membership + no-X arm + CI/postfit fences + notes |
| `test/test_bridge_lognormal.jl` | **new** — focused no-X smoke (43 tests) |
| `test/test_bridge_capabilities.jl` | golden: `lognormal` after `poisson`; dedicated row assertions |
| `test/runtests.jl` | include the new file |
| `docs/design/capability-status.md` | lognormal note: bridge paid; light RCall Δ still OWED. AGHQ rows **untouched** (`missing`) |
| `docs/dev-log/check-log.md` | entry for this arc |
| `docs/dev-log/after-task/2026-08-18-lognormal-bridge.md` | this report |

## Verification (actual output, not a summary)

Mac-LIGHT: **no local `Pkg.test()`** — GitHub CI is the verifier for the full
suite (incl. Aqua/JET). `GLLVM_PARITY_TESTS` was unset; no live RCall Δ was
run and **none is invented**.

```
$ julia --project=. test/test_bridge_capabilities.jl
Test Summary:              | Pass  Total  Time
bridge capabilities ledger |  211    211  0.5s

$ julia --project=. test/test_bridge_lognormal.jl
Test Summary:                       | Pass  Total   Time
lognormal bridge (no-X, twin fid 3) |   43     43  21.4s
```

What the 43 tests cover: family-key / list membership (after poisson, before
binomial; out of X / X_lv / mask; in no-CI and no-scalar-postfit); the no-X
point route against `fit_lognormal_gllvm` at 1e-8 (`alpha`, rotated loadings,
`loglik`, shared `σ` in `dispersion`, `LogLink`, unit-diagonal correlation,
empty scores, `nobs`); case-normalised alias; loud rejection of mask, `X`,
`X_lv`, `ci_method="wald"`, non-positive `y`, and `lognormal` inside a
mixed-family vector.

## Workflow Q status

| Check | Verdict |
| --- | --- |
| FD verification ≤ 1e-6 | **N/A** — no new likelihood or gradient; the lognormal marginal FD gate landed with the engine (`test/test_lognormal.jl`) |
| Cross-check vs in-repo reference ≤ 1e-8 | **PASS** — bridge vs `fit_lognormal_gllvm` at 1e-8 |
| R-parity via RCall | **OWED, not invented** — twin fid 3 exists so a Δ is legitimate, but `GLLVM_PARITY_TESTS` was unset and no live number is quoted |
| JET / Allocs / Aqua | **deferred to CI** (Mac-LIGHT); no new type unions or hot-loop code |
| Multi-shape | **N/A** — no phylogenetic substrate touched |

## Rose fence

**OK to claim:** the R bridge accepts `family = "lognormal"` for **no-X**
fits, routing `fit_lognormal_gllvm` with a shared scalar log-scale `σ` and
y-scale loglik (Jacobian included).

**NOT OK to claim:** any live `gllvmTMB` light RCall Δ (still OWED); CI;
+X; X_lv; missing-response masks; residuals/simulate; ADEMP or coverage;
any AGHQ promotion (both ledger rows stay `missing`).

## Remaining risks / follow-ups

1. **Light RCall Δ** — the one remaining owed lognormal cell. Own G0; do not
   invent a number.
2. **CI** — needs `LognormalFit` in `_CIFit` (or a dedicated adapter) before
   `_BRIDGE_NO_CI_FAMILIES` can drop it.
3. **Scores / postfit** — `getLV` / `residuals` / `simulate` for
   `LognormalFit` are not on this engine; scores stay `0×0`.
4. **+X / X_lv / masks** — own G0s; not this chip.
5. `test/runtests.jl` include line will merge-conflict with OPEN #257
   (multinomial include) — one-line each; expected.

## Next command

```sh
gh pr checks --watch          # full CI is the verifier for this arc
```

## Rose Verdict

Rose verdict: PASS WITH NOTES — bridge admit paid and fenced; light RCall Δ
still OWED (not invented); AGHQ rows untouched.
