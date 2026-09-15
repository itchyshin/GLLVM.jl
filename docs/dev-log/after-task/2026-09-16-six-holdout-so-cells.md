# After-task: six holdout paired second-order cells (2026-09-16)

## Scope

Paired SO toy cells + `GLLVM_PARITY_TESTS=1` test hooks for families that had native
Wald but no R-paired receipt: Lognormal, OrdinalPerTrait (probit), Truncated-Poisson,
Truncated-NB2 (shared `r` Julia fit), Multinomial FE, Student-t fixed-ν (species σ).

No `confint_family.jl` edits. #357 untouched. No `Project.toml` bump.

## Outcome

- `tools/core070_second_order/common.jl`: extended `r_fit_se` for lognormal / trunc*
  families; added `r_fit_se_ordinal_probit`, `r_fit_se_student`, `r_fit_se_multinomial`.
- `tools/core070_second_order/cells.jl`: six new cells + dispatcher ids; `using Random`,
  `LinearAlgebra` so test includes work without `run_cell.jl` prelude.
- Six `test/test_second_order_*_ci.jl` files: R paired `@testset` (skip unless parity env).

## Live Δ (local, `GLLVM_PARITY_TESTS=1`, 2026-09-16)

| cell_id | se_max_relative_delta (β block) |
|---|---|
| lognormal | 8.30e-6 |
| ordinal_pertrait_probit | 9.54e-6 |
| truncated_poisson | 8.94e-6 |
| truncated_nbinom2 | 9.81e-2 (shared Julia `r` vs R per-trait φ) |
| multinomial_fe | 5.36e-6 |
| studentt_fixed_nu | 2.99e-6 |

## Checks

```text
julia --project=. -e 'include("test/test_second_order_lognormal_ci.jl"); ... (six files + betabinomial_shared)'
→ 133 pass / 0 fail / 7 broken (R skip)
```

Rose fence: Julia paired SO smoke only; ≠ programme §7; truncNB2 large Δ is documented
parameterisation mismatch on dispersion, not promoted to D1.
