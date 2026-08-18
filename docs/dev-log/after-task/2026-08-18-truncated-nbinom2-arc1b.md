# After Task: truncated_nbinom2 Arc1b per-trait `log_phi_truncnb2`

**Date:** 2026-08-18
**Lane:** `cursor/truncnb2-arc1b-20260818`
**WT:** `/Users/z3437171/local-scratch/lanes/GLLVM.jl-truncnb2-arc1b-20260818`
**Base:** `origin/main` @ `3d5acba0` (#253)
**Cite:** `docs/dev-log/after-task/2026-08-15-truncated-nbinom2-identity-engine.md`
**Identity:** ACCEPTED 2026-08-15 already OWED this.

## Goal

Land the twin-default per-trait dispersion pack
`[β; pack(Λ); log r_1…log r_p]` (`r_t` ≡ `φ_t = exp(log_phi_truncnb2[t])`)
without touching the Laplace core, the AGHQ grid, or the bridge.

## Implemented

Arc1 shared-`r` pack `[β; pack(Λ); log r]` (length `p+rr+1`) is unchanged.
Arc1b adds `truncated_nbinom2_pertrait_marginal_loglik_laplace` and
`fit_truncated_nbinom2_gllvm_pertrait`: `rvec = exp.(θ[tail])`,
`fams = TruncatedNegBin2.(rvec)`, mode via `_grouped_laplace_mode`
(no edit to `grouped_dispersion.jl`). Score/weight keep
`a = r_t/(r_t+μ)` (Sol 2026-08-15).

## Mathematical Contract

Zero-truncated NB2 (twin fid 11):
`ℓ = log NB2(y; μ, r_t) − log(1 − p0)`, `μ = exp(η)`, `p0 = (r_t/(r_t+μ))^{r_t}`,
`Var = μ + μ²/r_t` ≡ twin `φ_t`. Per-trait `r_t` is the twin default
`log_phi_truncnb2`. Equal `r_t` reduces to the shared-`r` Laplace marginal.

## Files Changed

- `src/families/truncated_nbinom2.jl` — per-trait loglik + fitter
- `src/GLLVM.jl` — include comment + exports
- `test/test_truncated_nbinom2.jl` — FD tail, equal-`r_t` reduction, y=0
- `docs/dev-log/decisions/2026-08-15-truncated-nbinom2-identity.md` — Arc1b amend
- `docs/design/capability-status.md` — Notes only
- `docs/dev-log/check-log.md` — this tally
- `docs/dev-log/after-task/2026-08-18-truncated-nbinom2-arc1b.md` — this report

## Tests Added

3 new `@testset`s (5 assertions) in `test/test_truncated_nbinom2.jl`:

- equal-`r_t` reduces to shared-`r` ll (independent-path comparison; atol 1e-8)
- packed NLL FD vs ForwardDiff on the log-`r` tail ≤ 1e-6 (FD verification)
- y=0 still throws on both shared and per-trait fitters (failure path)

No rtol/atol widen.

## Benchmark Numbers

N/A — no hot-path change (`likelihood.jl` / `fit.jl` / `sparse_phy.jl` /
`em_phylo.jl` / `lowrank_cholesky.jl` untouched). Family-local Laplace
wrapper only.

## R-Parity Verdict

Parity: N/A — change does not invent a twin Δ (no ZIP/ZINB Δ; no light
RCall cell this slice). Claim is Julia pack ≡ twin `log_phi_truncnb2`
parameterisation, not a fitted logLik Δ.

## JET / Allocs / Aqua Verdicts

- JET: not run — focused Mac-light only; full suite = GitHub CI
- Allocs: N/A — no inner-loop change
- Aqua: not run — no `Project.toml` / export-hygiene change beyond additive exports

## Checks Run

```
julia --project=. --startup-file=no test/test_truncated_nbinom2.jl
```

```
Test Summary:            | Pass  Total  Time
truncated_nbinom2 family |   18     18  9.8s
```

**18 Pass / 0 Fail / 0 Error** (9.8 s).

## Consistency Audit

- `rg "Arc1b OWED|log_phi_truncnb2" docs/design/capability-status.md docs/dev-log/decisions/2026-08-15-truncated-nbinom2-identity.md` — Notes now say Arc1b landed; Identity amend dated 2026-08-18
- `rg "bridge.jl|aghq_grid|laplace.jl" src/families/truncated_nbinom2.jl` — no edits to those files
- Did not touch `src/bridge.jl`, `src/families/aghq_grid.jl`, `src/families/laplace.jl`, `src/families/grouped_dispersion.jl`

## GitHub Issue Maintenance

No issue action needed — this is the Identity-OWED Arc1b slice, not a
tracker close.

## What Did Not Go Smoothly

Fresh worktree had no `Manifest.toml` (gitignored). `Pkg.instantiate()`
once, then the focused file precompiled cleanly. Other-lane refs exist
on `capability-status.md` / `check-log.md` / `GLLVM.jl`; this slice only
adds truncated_nbinom2 Notes / a top check-log entry / additive exports.

## Team Learning

Identity-OWED per-trait packs should reuse `_grouped_laplace_mode` rather
than cloning another site Newton; the reduction test is the lock.

## Remaining Risks

- `fit_gllvm(TruncatedNegBin2())` still routes to shared-`r` Arc1 (honest;
  twin default is per-trait — call `fit_truncated_nbinom2_gllvm_pertrait`)
- Per-trait mode has no line-search backtrack (`_grouped_laplace_mode`);
  equal-`r_t` still matched shared-`r` to atol 1e-8 on the focused cell
- Not on the bridge; not AGHQ

## Known Limitations

- ≠ bridge admit
- ≠ AGHQ
- ≠ X / +cov / confint
- ≠ ADEMP
- ≠ invent ZIP/ZINB twin Δ
- `grouped_dispersion.jl` not extended with a TruncatedNegBin2 grouped fitter

## Next Command

Review + merge-on-green of this PR. Do not merge from the lane.

## Rose Verdict

Rose verdict: PASS WITH NOTES — per-trait pack ≡ twin `log_phi_truncnb2`;
≠ bridge admit ≠ AGHQ. Focused 18/18. No silent rtol. No ZIP/ZINB Δ.
