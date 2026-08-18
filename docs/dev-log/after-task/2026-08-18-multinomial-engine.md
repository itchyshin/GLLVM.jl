# After Task: Multinomial P1 engine (FE softmax)

**Date:** 2026-08-18
**Lane:** `cursor/lane-parity-beyond-20260818` (PR #257)
**Worktree:** `~/local-scratch/lanes/GLLVM.jl-parity-beyond-20260818`
**Identity:** `docs/dev-log/decisions/2026-08-18-multinomial-identity.md` (ACCEPTED)
**Twin pin:** `gllvmTMB` `origin/main` `af1218d8` (read-only)
**Julia pin:** `origin/main` `3d5acba0`

## Goal

Ship v1 fixed-effect softmax for the only missing twin family
(`multinomial` / fid 16) under the ACCEPTED Identity. Ledger stays
`missing`. No invented Δ. No LV. No P2.

## Implemented

One-trait baseline-category softmax. Marker is `Multinomial` (not
`Categorical`, not `categorical()`, not `Distributions.Multinomial`).
`y ∈ {1, …, K}` or a `K×n` one-hot; `K ≥ 3` fail-loud and names
binomial-logit. `η₁ ≡ 0`. Packed objective length `(K−1)(1+p)`,
contrast-major `[β₂…β_K; γ₂; …; γ_K]`. One softmax / logsumexp per
observation — no TMB `K−1` pseudo-rows. `fit_gllvm` routes
`family = Multinomial()` and rejects `K` / `num_lv` > 0, `row_eff`,
`disp_group`, and `pervar`. Distributions is imported without the
count-vector `Multinomial` name so the Identity marker can bind.

## Mathematical Contract

Identity Design 83 §2 (this repo's lock, not a new derivation):

- `η₁ ≡ 0`
- `η_k = β_k + xᵀ γ_k` for `k = 2, …, K`
- `P(y = k) = exp(η_k) / Σ_j exp(η_j)`
- Free count `(K−1)(1+p)`

No φ. No ordinal cutpoints. No `(π²/6)(I+J)` residual in the MLE.

## Files Changed

- `src/families/multinomial.jl` — marker, loglik, pack, fitter
- `src/GLLVM.jl` — include / export; Distributions import excludes
  `Multinomial`
- `src/families/fit_gllvm.jl` — dispatch + LV reject
- `src/confint_bootstrap.jl` — drop unused `using Distributions` (it
  re-imported the count-vector name)
- `test/test_multinomial.jl` — focused FD / fail-loud / smoke
- `test/runtests.jl` — include
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/after-task/2026-08-18-multinomial-engine.md` — this report
- `LOOP/arcs.md` / `LOOP/checkpoint.md` — P1-eng landed
- `AGENTS.md` — phase-snapshot line only

`docs/design/capability-status.md` **not** edited (row stays `missing`).
`src/families/aghq_grid.jl` **not** touched. Bridge / `@formula` /
Tweedie / lognormal P2 **not** opened.

## Tests Added

`test/test_multinomial.jl` (37 tests). Tests of the tests:

- independent logsumexp oracle for one-softmax-per-observation
- fail-loud: `K < 3`, `y` outside `1:K`, two-trait / pseudo-row matrix, LV `K` / `num_lv`
- packing length `(K−1)(1+p)` and `η₁ ≡ 0`
- packed NLL FD vs ForwardDiff ≤ 1e-6
- smoke recovery no-X and +X (same declared baseline)

RED before engine: `0 passed, 10 failed, 8 errored` (`UndefVarError`).

## Benchmark Numbers

N/A — no hot-path change. New small FE objective, not a Laplace inner loop.

## R-Parity Verdict

Parity: N/A — no twin light Δ exists; Identity forbids inventing one.
A later FE-only RCall cell may quote a live number. This after-task
does not.

## JET / Allocs / Aqua Verdicts

- JET: not run (Mac-light focused file; full suite = GitHub CI / `Pkg.test()`)
- Allocs: N/A — no inner-loop budget claimed
- Aqua: not run locally (same)

## Checks Run

```
export PATH="$HOME/.juliaup/bin:$PATH"
julia --project=. --startup-file=no test/test_multinomial.jl
```

```
Test Summary:                                | Pass  Total  Time
multinomial family (FE softmax, twin fid 16) |   37     37  2.7s
```

## Consistency Audit

`rg -n "aghq_grid" src/families/multinomial.jl` empty.
`rg -n "categorical\\(\\)" src/families/multinomial.jl src/families/fit_gllvm.jl`
  — only the "not categorical()" fence in the marker docstring.
No invented Δ string in this slice. Ledger file not edited.

## GitHub Issue Maintenance

No issue action. Engine commits go onto OPEN PR #257. Do not merge
from the agent.

## What Did Not Go Smoothly

`using Distributions` already binds the count-vector `Multinomial`.
Selective import plus removing an unused `using Distributions` in
`confint_bootstrap.jl` was required so `struct Multinomial end` could
exist. That is a naming collision, not an estimand change.

## Team Learning

Name the Distributions collision in the Identity before the engine arc
next time, so the marker type is locked without a mid-arc import edit.

## Remaining Risks

- Ledger still `missing` — engine+test is not a surface admit.
- No twin Δ. Do not quote one.
- No LV / Design 123 / `(1|g)` / AGHQ / VA.
- `using GLLVM, Distributions` in the same caller namespace will clash
  on `Multinomial`; qualify `GLLVM.Multinomial` vs
  `Distributions.Multinomial`.
- Full suite not run locally.

## Known Limitations

v1 is FE softmax only. One trait. Logit / softmax only. No bridge, no
`@formula` wiring, no CI, no ADEMP, no capability-table promote.

## Next Command

P1-eng STOP on this branch after push to #257. Do **not** start P2
lognormal / `truncated_nbinom2` Arc1b / Tweedie T2–T5. Do **not**
`gh pr merge`. Do **not** touch `aghq_grid.jl`.

## Rose Verdict

Rose verdict: PASS WITH NOTES — focused 37/37 and FD ≤ 1e-6; ledger
stays `missing`; no twin Δ; not a capability admit; no LV; `aghq_grid.jl`
untouched. Notes = remaining risks above. Not a self-signed programme
PASS and not a full-suite / Workflow-Q claim.
