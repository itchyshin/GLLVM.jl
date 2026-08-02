# After Task: Grouped NB one-group ≈ shared identity

## Goal

Clear the pre-existing red cell at `test/test_grouped_dispersion.jl:61`
(`fit_nb_gllvm_grouped` with `group = ones(Int, p)` ≈ `fit_nb_gllvm`) without
silently widening `atol=1e-2` / `rtol=1e-4`.

## Diagnosis

At seed 503 / `iterations=150`:

| Fit | Hessian | logLik | r̂ |
|---|---|---|---|
| `fit_nb_gllvm_grouped` (default) | `:observed` | −3189.854 | 3.6669 |
| `fit_nb_gllvm` | Fisher (shared path) | −3188.914 | 3.6679 |
| `fit_nb_gllvm_grouped(; hessian=:fisher)` | `:fisher` | −3188.914 | 3.6679 |

Default ΔlogLik ≈ **−0.940** is an **objective mismatch** (TMB observed
curvature vs shared Fisher-Laplace), not packing or optimiser failure.
Fisher-aligned grouped fit matches shared to ~**3e-12**.

Docstring already stated the identity holds when `hessian=:fisher`; the test
was comparing defaults that intentionally differ for TMB parity.

## Implemented

- Test cell requests `hessian=:fisher` for the same-model identity assertion;
  comment records why default `:observed` must not be compared to `fit_nb_gllvm`.
- File-header comment in `src/families/grouped_dispersion.jl` aligned with that
  contract. Default `hessian=:observed` unchanged (NB2 TMB route / catch-up
  oracle).

## Files Changed

- `test/test_grouped_dispersion.jl`
- `src/families/grouped_dispersion.jl` (comment only)
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` (this file)

## Checks Run

```sh
julia --project=. -e 'include("test/test_grouped_dispersion.jl")'
```

Result: **14/14 pass**.

```sh
julia --project=. test/runtests.jl
```

Result: **5064 passed, 0 failed, 3 broken** (49m29.9s;
`/tmp/grouped-dispersion-runtests-20260802.log`). Aqua/JET skipped in core
env (as expected — full battery is `Pkg.test()`).

## Not covered / fenced

- Changing grouped default away from `:observed` (would regress NB2 TMB light
  logLik).
- Shared `fit_nb_gllvm` observed-Hessian upgrade.
- NB2/Beta+X light cells; #129/#128; ADEMP; coverage; Totoro/DRAC; Phylo Model A.
- Full family parity.

## Rose claim fence

**OK:** “One-group `fit_nb_gllvm_grouped` matches `fit_nb_gllvm` under the
shared Fisher-Laplace objective (`hessian=:fisher`); prior default-vs-default
gap was objective mismatch (Δ≈0.94), not silent tol widen.”

**Not OK:** “default grouped `:observed` equals shared NB,” or “full family
parity.”

## Rose verdict

`Rose verdict: PASS WITH NOTES — identity locked under matching hessian;
observed default retained for TMB; core suite 5064/0/3 broken (fail cell gone).`

## Next

- Ask maintainer before push/PR of `fix/grouped-dispersion-one-group-20260802`.
- Optional later (fenced): NB2/Beta+X identity design ultra-plan.
