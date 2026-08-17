# After Task: AGHQ Stage-1b A4(2) Liu–Pierce adaptation + k>1 golden

## Goal

Close the PR #252 test/DoD gap so A4(2) can pass CI: add the missing
`test/test_aghq_adapt.jl`, retire the Stage-1a `k=3` throw contract, and
record Mac-light tallies. Not an estimator. Not a surface admit.

## Implemented

`aghq_stage1a_loglik_site` already mapped probabilists' nodes at the
Laplace mode (`32967ef4`). This slice adds the focused adapt golden and
updates the obsolete grid fence:

```
z_ij = ẑᵢ + Lᵢ^{-T} uⱼ          # no √2
log Lᵢ = −½ logdet Aᵢ + logsumexpⱼ(logwⱼ + inner_ll(i,j))
```

`k = 1` still matches dense Laplace (template evaluated, not skipped).
`k > 1` matches an independent Liu–Pierce reconstruction and is not the
√2 map. Fail-loud remains for non loadings-only `z_B`. Does **not** call
`_gauss_hermite`. Does **not** add a public `aghq=` knob. Both AGHQ
ledger rows stay `missing`.

## Mathematical Contract

Hopper A4(2) pin: Liu–Pierce (1994) at the existing Laplace expected-Fisher
cache `A = Λ'WΛ + I`; `L^{-T} = R^{-1}` from `cholesky(A)`. Live pin is
Stage-1a `.gllvmTMB_aghq_grid` (probabilists'). Twin fit-time `k = 1` →
Laplace skip is **not** ported (A4.4). Twin 1e-8 ridge / `aghq_ridge` is
**not** ported.

## Files Changed

- `test/test_aghq_adapt.jl` — new k>1 Liu–Pierce golden
- `test/test_aghq_grid.jl` — k=3 no longer throws; k>1 node-loop exercise
- `test/runtests.jl` — include the adapt file
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/after-task/2026-08-17-aghq-stage1b-adapt.md` — this report

`src/families/aghq_grid.jl` / `src/GLLVM.jl` unchanged in this commit
(already on `32967ef4`). `docs/design/capability-status.md` **not**
edited; both AGHQ rows stay `missing`. Tweedie / #247 / Dropbox checkout
**not** touched.

## Tests Added

`test/test_aghq_adapt.jl`: k=1 site/marginal vs Laplace + independent
template golden; k=3 vs independent Liu–Pierce (rejects √2); fail-loud
on extra random structure at `k = 3`.

`test/test_aghq_grid.jl`: k=1 goldens retained; new k>1 finite / not-equal
to k=1; fail-loud renamed to extra-structure only.

## Benchmark Numbers

N/A — site evaluator, not a hot-path fitter.

## R-Parity Verdict

Parity: N/A — no twin Δ. Twin cited from files (Hopper pin), not from a
Julia number.

## JET / Allocs / Aqua Verdicts

- JET: not run locally (Mac-light; CI is the verifier)
- Allocs: N/A — not an inner-loop claim
- Aqua: N/A — no Project.toml change

## Checks Run

```
julia --project=. --startup-file=no test/test_aghq_grid.jl
# Test Summary: AGHQ Stage-1a live-pin grid | Pass 70  Total 70  Time 4.3s

julia --project=. --startup-file=no test/test_aghq_adapt.jl
# Test Summary: AGHQ Stage-1b Liu–Pierce adaptation | Pass 17  Total 17  Time 3.5s
```

Mac-light: no local `Pkg.test`. Full suite = GitHub CI.

## Consistency Audit

```
rg -n '_gauss_hermite(' src/families/aghq_grid.jl
# no call (comment / docstring only)
rg -n 'aghq=' src/families/fit_gllvm.jl
# not added
rg -n 'AGHQ estimator|Broad AGHQ' docs/design/capability-status.md
# both rows still missing
```

## GitHub Issue Maintenance

No issue action. No `gh pr merge`. Estimator still `missing`.

## What Did Not Go Smoothly

Push-agent commit `32967ef4` shipped src without the adapt test and left
the Stage-1a `k=3` throw in place. Worktree had no Manifest; `Pkg.instantiate`
was required before Mac-light.

## Team Learning

A Stage-1a fail-loud on `k ≠ 1` becomes a CI blocker the moment k>1 is
implemented. The adapt golden must reconstruct the Hopper map independently
and reject √2, not only assert `isfinite`.

## Remaining Risks

A4 items (3)–(5) unpaid: structural gate, adaptation loop / fit-time skip,
report honesty. A public knob would still advertise a missing estimator.
Full CI on #252 was IN_PROGRESS at write time (Mac-light only here).

## Known Limitations

No public `aghq=`. No twin Δ. No A4(3) gate. Tweedie `fit_gllvm` still
STOP. #247 left unedited. Dropbox checkout not touched.

## Next Command

`git push` to `origin/claude/lane-aghq-stage1b` (already asked). Do **not**
`gh pr merge`. Wait for full CI on #252.

## Rose Verdict

Rose verdict: PASS WITH NOTES — A4(2) test/DoD closed; both AGHQ rows stay
`missing`; no public knob; no Δ; no Tweedie; local full suite not run
(Mac-light, CI is the verifier). Do not merge #252 from this lane.
