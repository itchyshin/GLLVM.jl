# NB2-log each-own-optimum 2SO smoke — M2 remainder (2026-09-06)

**Contract:** `docs/dev-log/core070/second-order-parity-contract.md` §4  
**Claim boundary:** M2 remainder smoke — **NOT** programme §7 second-order parity claim.

## Cell

`nb2_log` fixture: seed=45, p=5, K=2, n=80, each-own-optimum.
Family default Hessian `:observed`.

## Warnings inspected (do not discard)

1. Julia: grouped-dispersion boundary for groups `[1, 3]` (`r` outside `[1e-6, 1e6]`);
   `boundary_terms = ["r[1]", "r[3]"]`.
2. Julia `jl_converged = false`; `pd_hessian_native = false`.
3. R `pd_hessian_r = false`; `r_condition_number = 7.11e5`.
4. RCall warning: `NaNs produced` in `sqrt(diag(cv))` on the full `sd_report` diagonal.
5. Native condition number of the compared β-block: `6.42e15`.

This is the T14 boundary pattern. The assessor still printed
`eoo_smoke_pass: true` because the **β SE/CI** comparison stayed finite
(`se_n_finite_of_total = 5/5`, SE rel 2.12e-6, CI abs 1.06e-6) and the
vcov Frobenius 0.380 is below the **cond-scaled** bar
(`0.01 * 710686/1000 ≈ 7.1`). That scaling is the existing contract rule,
not a newly widened tolerance.

## Judgment (not a tolerance change)

| Quantity | Label |
|---|---|
| β SE / Wald CI (EOO) | pass, finite |
| full vcov Frobenius | **partial** — 0.38 raw; only “inside bar” via cond-scale |
| joint Hessian / convergence | **blocked / warning** — both `pdHess` false; Julia not converged |
| gate-tier A11 | stays **partial**; M2-R2 still needs a new G0 |

**Do not** promote this cell to covered. **Do not** loosen the 1e-2 vcov bar.

## Artifacts

- JSON: `docs/dev-log/core070/nb2-2so-eoo-smoke-receipt-2026-09-06.json`
- Driver: `tools/core070_second_order/smoke_nb2_eoo.jl`
