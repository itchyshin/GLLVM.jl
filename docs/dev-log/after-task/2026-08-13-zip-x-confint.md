# After-task: ZIP+X confint under X (ZIPCovFit)

**Date:** 2026-08-13  
**Lane:** `feat/zip-x-confint-20260813`  
**Worktree:** `.worktrees/gllvmjl-zip-x-confint-20260813`  
**Base:** `origin/main` @ `5d570b11` (Merge #200, ZIP+X engine)

## Goal

Ship `confint(fit::ZIPCovFit, Y; X=…, method=:wald|:profile|:bootstrap)` via
`_family_ci` packing `[βz; γz_free; βc; γc_free; pack(Λc)]` with dual offsets,
lift `_bridge_ci_guard_zip_x` / `_BRIDGE_NO_CI_X_FAMILIES`, and verify
bridge↔native Wald ≤ 1e-8.

## Implemented

1. **`_family_ci(::ZIPCovFit)`** — dual free slopes, `Oz`/`Oc` via
   `_build_offset`, term names `betaz` / `gammaz` / `betac` / `gammac` /
   `Lambda`. Missing-`X` throws. Admitted on `_CIFit`.
2. **Bridge** — deleted `_bridge_ci_guard_zip_x`; emptied
   `_BRIDGE_NO_CI_X_FAMILIES`; `_bridge_compute_ci_cov` ∪ `ZIPCovFit`;
   `_bridge_assemble_zip_cov` routes CI when `ci_method ≠ "none"`.
3. **Capabilities** — `ci_x_{wald,profile,bootstrap}` true for `zip`; note
   claims FD-Hessian CI under X (Julia-forward / twin-asymmetric; no twin Δ).
4. **Tests** — native Wald smoke + missing-X; optional zero-X shared-term
   ≈ `ZIPFit`; bridge X Wald parity; capabilities golden; drop fail-loud fence.

## Mathematical Contract

ZIP Laplace marginal under Identity 2026-08-09: `η^z = βz + Xγz` (`Λz=0`),
`η^c = βc + Xγc + Λc z`. Wald SEs from the central-difference Hessian of the
packed dual-γ objective (same FD pattern as other non-Gaussian family CIs).

## Files Changed

- `src/confint_family.jl` — `_CIFit` ∪ `ZIPCovFit`; `_family_ci`; docstring
- `src/bridge.jl` — guard lift, assemble CI, capabilities note
- `test/test_confint_family.jl` — ZIPCovFit Wald + zero-X shared-term check
- `test/test_bridge_capabilities.jl` — `ci_x_*` + note expectations
- `test/test_bridge_x.jl` — zip Wald bridge↔native; drop fence throw
- `docs/dev-log/after-task/2026-08-13-zip-x-confint.md`
- `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`

## Tests Added

- ZIPCovFit Wald: estimates match MLE; missing `X` throws; finite intervals
  bracket when finite.
- Optional Rung1: zero-X shared `betaz`/`betac`/`Lambda` estimates ≈ ZIPFit.
- Bridge X Wald vs native `confint` max abs diff `< 1e-8`.

## Benchmark Numbers

`N/A — no hot-path change` — CI layer is post-fit FD Hessian.

## R-Parity Verdict

`Parity: N/A — change does not touch the parity surface` (twin ZIP cut; no
light RCall Δ invented). Bridge CI vs native Julia `confint` ≤ 1e-8.

## JET / Allocs / Aqua Verdicts

- JET / Aqua: owned by full `Pkg.test()` / CI
- Allocs: N/A — no inner-loop change

## Checks Run

```
test/test_bridge_capabilities.jl          140 pass / 140 total   0.4s
test/test_confint_family.jl               199 pass / 199 total  7m17s
test/test_bridge_x.jl                     294 pass / 294 total  49.9s
Pkg.test() (full, Aqua/JET)              5390 pass / 1 broken / 5391  53m35.8s
```

Tolerance widen: **none**.

## Consistency Audit

`rg` `_bridge_ci_guard_zip_x` — gone from `src/`.  
`rg` `CI under X is a follow-up` in `src/bridge.jl` + capabilities tests —
no remaining ZIP hit. Ordinal CI still fenced.

## GitHub Issue Maintenance

No issue action — Arc Card execute-direct from #200 follow-up.

## What Did Not Go Smoothly

Sandbox blocked first `git worktree add` (`.git/config`); recreated with
`required_permissions: ["all"]`. Subagent cannot `move_agent_to_root`; edits
used absolute worktree paths.

## Team Learning

Keep dual-γ term names (`gammaz`/`gammac`) distinct from one-part `gamma[k]`
so bridge payload consumers can tell the parts apart.

## Remaining Risks

- Dual-γ FD Hessian can be non-PD; tests allow non-finite bounds (no
  `pd_hessian` demand), same as other family CIs.
- Profile/bootstrap are routed by the generic layer; Wald is the smoke
  oracle for ZIP+X (optional Rung2 under-run not required for DoD).

## Known Limitations

≠ twin light RCall Δ ≠ ZINB/hurdle/Tweedie+X ≠ ADEMP ≠ Phylo #127 ≠ invent
twin restore.

## Next Command

Open PR from `feat/zip-x-confint-20260813`; merge only on maintainer ask.

## Rose Verdict

Rose verdict: **PASS WITH NOTES** — Julia ZIP+X CI claim only (FD Hessian);
bridge↔native ≤ 1e-8; not twin parity; not ADEMP; not ZINB+X.
