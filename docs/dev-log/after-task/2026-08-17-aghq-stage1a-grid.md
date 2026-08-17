# After Task: AGHQ Stage-1a live-pin grid + k=1 golden

## Goal

Ship A4 item (1) from the #248 Identity: a new Julia symbol on the live
`.gllvmTMB_aghq_grid` convention, with a golden test that `k = 1` matches
the existing dense Laplace marginal. Not an estimator. Not a surface admit.

## Implemented

Internal probabilists' GH (`_aghq_gh_normal`) + tensor `aghq_grid(d, k)`
with `logw_j = Σ_m log w_{j_m} + (d/2) log(2π) + ½ u_j'u_j`. Sanity
`aghq_grid_ok` matches `.gllvmTMB_aghq_grid_ok`. Stage-1a `k = 1` evaluator
applies the template identity
`log L_i = −½ logdet H_i + (d/2) log(2π) + inner_ll(ẑ_i)` and equals
`laplace_loglik_site` / `poisson_marginal_loglik_laplace`. Fail-loud on
`k ≠ 1` and on extra random structure (row effects, phylo, `mi()`, unique /
`s_B`, `use_lv_B`, multinomial). Does **not** call `_gauss_hermite`. Does
**not** port the twin's fit-time `k = 1` → Laplace skip.

## Mathematical Contract

Live pin is twin `.gllvmTMB_gh_normal` + `.gllvmTMB_aghq_grid`
(`R/fit-multi.R`; C++ comment at `src/gllvmTMB.cpp` 619–626). Not the
peer `.aghq_grid` / `.gauss_hermite_physicist` physicists' rule. Julia VA
`_gauss_hermite` stays the ELBO measure. `k = 1` ≡ Laplace is a
grid-convention identity, not a capability claim.

## Files Changed

- `src/families/aghq_grid.jl` — new grid + k=1 identity evaluator
- `src/GLLVM.jl` — include after `laplace.jl`
- `test/test_aghq_grid.jl` — new focused file
- `test/runtests.jl` — include
- `docs/dev-log/plans/2026-08-17-aghq-stage1a-arc.md` — Arc Card + Actuals
- `docs/dev-log/decisions/2026-08-17-aghq-stage1a-grid.md` — provenance
- `docs/dev-log/check-log.md` — this slice
- `docs/dev-log/coordination-board.md` — this lane's Active-Lane-Split row
- `docs/dev-log/after-task/2026-08-17-aghq-stage1a-grid.md` — this report

`docs/design/capability-status.md` **not** edited; both AGHQ rows stay
`missing`. `variational.jl` / Tweedie / #247 handover **not** touched.

## Tests Added

`test/test_aghq_grid.jl`: k=1 point rule; normalising + second-moment
identities; probabilists' ≠ VA physicists'; k=1 site/marginal vs Laplace;
fail-loud fences.

## Benchmark Numbers

N/A — grid construction, not a hot-path fitter.

## R-Parity Verdict

Parity: N/A — no twin Δ. Twin cited from files (Hopper pin), not from a
Julia number. Inventing a Δ would be a fence break.

## JET / Allocs / Aqua Verdicts

- JET: not run locally (Mac-light; CI is the verifier)
- Allocs: N/A — not an inner-loop claim
- Aqua: N/A — no Project.toml change

## Checks Run

```
julia --project=. --startup-file=no test/test_aghq_grid.jl
# Test Summary: AGHQ Stage-1a live-pin grid | Pass 69  Total 69  Time 4.3s
```

Mac-light: no local `Pkg.test`. Full suite = GitHub CI.

## Consistency Audit

```
rg -n '_gauss_hermite' src/families/aghq_grid.jl
# comment / docstring only; no call
rg -n 'aghq=' src/families/fit_gllvm.jl
# not added
```

## GitHub Issue Maintenance

No issue action. Grid only; estimator still `missing`.

## What Did Not Go Smoothly

Worktree had no Manifest; copied from the ordered-beta worktree then
`Pkg.instantiate` (Manifest is gitignored). Shannon forbade a second
worktree and forbade editing capability-status AGHQ rows — the earlier
honesty note on that file was reverted.

## Team Learning

The k=1 golden must evaluate the **template identity**, not copy the
twin's fit-time skip. Same polynomials as VA GH, different Jacobi
off-diagonal (`√j` vs `√(j/2)`).

## Remaining Risks

A4 items (2)–(5) unpaid: per-site adaptation, structural gate, adaptation
loop, report honesty. A public knob would still advertise a missing
estimator.

## Known Limitations

No `k > 1` marginal. No public `aghq=`. No twin Δ. Tweedie `fit_gllvm`
still STOP. #247 left OPEN and unedited.

## Next Command

Ask Shinichi before push/PR. If approved:
`git -C .worktrees/gllvmjl-aghq-stage1a-20260817 push -u origin HEAD`
then `gh pr create` (never `--auto`; never merge #247).

## Rose Verdict

Rose verdict: PASS WITH NOTES — Stage-1a grid + k=1 golden only; both
AGHQ rows stay `missing`; no public knob; no Δ; no Tweedie; local full
suite not run (Mac-light, CI is the verifier).
