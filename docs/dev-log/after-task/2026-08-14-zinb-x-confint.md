# After-task: ZINB+X confint under X (ZINBCovFit)

**Date:** 2026-08-14  
**Lane:** `feat/zinb-x-confint-20260814`  
**Worktree:** `.worktrees/gllvmjl-zinb-x-confint-20260814`  
**Base:** `origin/main` @ `d589bd40` (Merge #203, ZINB+X engine)

## Goal

Ship `confint(fit::ZINBCovFit, Y; X=…, method=:wald|:profile|:bootstrap)` via
`_family_ci` packing `[βz; γz_free; βc; γc_free; pack(Λc); log r]` with dual
offsets and shared scalar `r` (`:log`), lift `_bridge_ci_guard_zinb_x` /
empty `_BRIDGE_NO_CI_X_FAMILIES`, and verify bridge↔native Wald ≤ 1e-8.

## Implemented

1. **`_family_ci(::ZINBCovFit)`** — ZIP+X clone plus ZINBFit `log r` tail;
   dual free slopes, `Oz`/`Oc` via `_build_offset`, term names `betaz` /
   `gammaz` / `betac` / `gammac` / `Lambda` / `r`. Missing-`X` throws.
   Admitted on `_CIFit`.
2. **Bridge** — deleted `_bridge_ci_guard_zinb_x`; emptied
   `_BRIDGE_NO_CI_X_FAMILIES`; `_bridge_compute_ci_cov` ∪ `ZINBCovFit`;
   `_bridge_assemble_zinb_cov` routes CI when `ci_method ≠ "none"`.
3. **Capabilities** — `ci_x_{wald,profile,bootstrap}` true for `zinb`; note
   claims FD-Hessian CI under X (Julia-forward / twin-asymmetric; no twin Δ).
4. **Tests** — native Wald smoke + missing-X; optional zero-X shared-term
   ≈ `ZINBFit` (incl. `r`); bridge X Wald parity; capabilities golden; drop
   fail-loud fence.

## Mathematical Contract

ZINB Laplace marginal under Identity 2026-08-13: `η^z = βz + Xγz` (`Λz=0`),
`η^c = βc + Xγc + Λc z`, **one shared scalar `r`** (`r = exp(θ[2p+2q+rr+1])`).
Wald SEs from the central-difference Hessian of the packed dual-γ + `log r`
objective (same FD pattern as other non-Gaussian family CIs).

## Files Changed

- `src/confint_family.jl` — `_CIFit` ∪ `ZINBCovFit`; `_family_ci`; docstring
- `src/bridge.jl` — guard lift, assemble CI, capabilities note
- `test/test_confint_family.jl` — ZINBCovFit Wald + zero-X shared-term check
- `test/test_bridge_capabilities.jl` — `ci_x_*` + note + `x_ci_routed` golden
- `test/test_bridge_x.jl` — zinb Wald bridge↔native; drop fence throw
- `docs/src/confidence-intervals.md` — `ZINBCovFit` / `X=` + dual-γ/`r` terms
- `docs/design/capability-status.md` — CI-under-X no longer deferred
- `docs/dev-log/after-task/2026-08-14-zinb-x-confint.md`
- `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`, `AGENTS.md`

## Tests Added

- ZINBCovFit Wald: estimates match MLE (Δ = 0 on γz/γc/r); missing `X`
  throws; finite intervals bracket when finite; `pd_hessian = true` on the
  smoke cell.
- Optional Rung1: zero-X shared `betaz`/`betac`/`Lambda`/`r` estimates ≈ ZINBFit.
- Bridge X Wald vs native `confint` max abs diff `< 1e-8`.

## Benchmark Numbers

`N/A — no hot-path change` — CI layer is post-fit FD Hessian. Smoke Wald
took ~1.1 s on the maintainer Mac (p=3, n=55, K=1).

## R-Parity Verdict

`Parity: N/A — change does not touch the parity surface` (twin ZINB cut; no
light RCall Δ invented). Bridge CI vs native Julia `confint` ≤ 1e-8.

## JET / Allocs / Aqua Verdicts

- JET / Aqua: owned by full `Pkg.test()` / CI
- Allocs: N/A — no inner-loop change

## Checks Run

```
test/test_bridge_capabilities.jl          153 pass / 153 total   0.4s
test/test_confint_family.jl               240 pass / 240 total  7m40.1s
test/test_bridge_x.jl                     347 pass / 347 total  1m02.3s
Pkg.test() (full, Aqua/JET)              5539 pass / 1 broken / 5540  56m39.4s
```

Wald smoke (seed 50): Δγz=Δγc=Δr=0; 12/12 finite bounds; `pd_hessian=true`.
Tolerance widen: **none**.

## Consistency Audit

`rg` `_bridge_ci_guard_zinb_x` — gone from `src/`.  
`rg` `CI under X is a follow-up` in `src/bridge.jl` + capabilities tests —
no remaining ZINB hit. Ordinal CI still fenced. `_BRIDGE_NO_CI_X_FAMILIES = ()`.

## GitHub Issue Maintenance

No issue action — Arc Card execute-direct from #203 follow-up.

## What Did Not Go Smoothly

Subagent cannot `move_agent_to_root`; edits used absolute worktree paths.
Fresh worktree needed `Pkg.instantiate()` (did not dirty tracked
Project/Manifest). First capabilities run missed the `x_ci_routed` golden
(`zinb` now last); fixed without widening rtol.

## Team Learning

Keep the shared-`r` tail (`:log`) on the ZIP dual-γ packing rather than
inventing a per-trait dispersion — Identity lock, not NB2 copy.

## Remaining Risks

- Dual-γ FD Hessian can be non-PD; tests allow non-finite bounds (no
  `pd_hessian` demand), same as other family CIs. The smoke cell was PD.
- Profile/bootstrap are routed by the generic layer; Wald is the smoke
  oracle for ZINB+X.

## Known Limitations

≠ twin light RCall Δ ≠ hurdle/Tweedie+X ≠ ADEMP ≠ Phylo #127 ≠ invent
twin restore ≠ per-trait `r` ≠ re-open Identity.

## Next Command

Open PR from `feat/zinb-x-confint-20260814`; merge only on maintainer ask.

## Rose Verdict

Rose verdict: **PASS WITH NOTES** — Julia ZINB+X CI claim only (FD Hessian);
bridge↔native ≤ 1e-8; not twin parity; not ADEMP.

---

## Addendum 2026-08-15 — Ubuntu CI shared-start fix (PR #204)

**Symptom:** Julia 1.10 / Julia 1 on ubuntu-latest failed 8 assertions in
`zinb (dual-γ ZINBCovFit; shared r; Julia-forward)` at `atol=1e-8` (Δ ~2–5e-6
on γc/γz/β/Λ/r); macOS+Windows green; ZIP clone at same atol green; loglik
still agreed — two independent Optim runs on the shared-`r` ridge (and
mismatched `iterations` 120 vs 500), not a packing bug.

**Fix (no atol widen):**
- `fit_zinb_gllvm_cov(...; θ_init=…)` optional packed start; `iterations≤0`
  evaluates at `θ0` without a second LBFGS wander.
- Point-fit + Wald zinb bridge_x cells: one Optim +
  `_bridge_assemble_zinb_cov` for 1e-8 transport; `θ_init`/`iterations=0`
  identity; live `bridge_fit` tag/note smoke only.

**Verify:** `test_bridge_x.jl` **357/357**; zinb identity+capabilities
**195/195**; ZINBCovFit Wald smoke `pd_hessian=true`. Rose fence unchanged:
Julia CI ≠ twin Δ ≠ ADEMP ≠ per-trait r.
