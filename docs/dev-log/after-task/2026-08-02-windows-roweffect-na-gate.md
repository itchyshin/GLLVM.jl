# After Task: Windows row-effect NA gate (unblock #175)

## Goal

Land Arc 1 PR #175. Windows CI blocked on an unrelated missing-response
row-effect convergence cell; diagnose and unblock without widening
tolerances or touching Arc 1 NB2/Beta+X routing.

## Diagnosis

- CI run `30759479351` on `fix/nb2-beta-x-grouped-cov-20260802` @ `dd1d66b6`:
  Documenter + Julia 1.10 ubuntu + Julia 1 ubuntu + macOS **green**;
  Windows **red** twice (initial + `--failed` rerun).
- Failure: `test/test_missing_response_extra.jl:284` —
  `@test fr_na.converged` for Poisson `fit_roweffect_gllvm` with
  `iterations = 160` (budget cap from `8ebb9a9e`, 2026-07-02).
- Arc 1 cells on the same Windows runs: **NB2/Beta + X identity 14/14**.
- Diff vs `origin/main` does **not** touch `test_missing_response_extra.jl`
  or row-effect sources.
- Local macOS focused gate: **35/35**; seed-44 probe converges in **142**
  iters even when capped at 160 — Windows needs the full default budget.

## Implemented

- Dropped `iterations = 160` override on the two row-effect NA/mask fits;
  fitter default (`500`) restored.
- Kept `n = 50` runtime bound from the July budget gate.
- Comment documents the Windows CI finding.

## Files Changed

- `test/test_missing_response_extra.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md`

## Verification

```sh
julia --project=. -e 'using Test; include("test/test_missing_response_extra.jl")'
# expected: 35/35
```

Rose: this is a Windows optimizer-budget unblock for #175 — **not** Arc 2
RCall; **not** a claim that row-effect NA coverage is newly expanded.

## Next

Push to #175 tip → await full CI green → self-merge Arc 1 → stop before Arc 2.
