# After-task — MultinomialFit Wald `_CIFit` (FE softmax)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `cursor/cloud-agent-1789479714671-jvn5g`

## Rose fence

- **≠** second-order §7; **≠** paired R SO cells; **≠** BetaBinomial shared-φ SO pairing; **≠** Multinomial LV (v1 FE only).
- **=** native `confint` for `MultinomialFit` (no-X and n×p +X).
- **bridge.jl** untouched (#357 foreign).

## Why ungated

Holdout row was **OUT / not attempted**, not paste-gated (no Stage 1 / S4 / Totoro / `Project.toml` / R surgery). Live first-order Δ already exists (`test_multinomial_parity.jl`).

## What landed

1. `MultinomialFit` ∈ `_CIFit` + `_family_ci` (contrast `beta[k]` / `gamma[k,j]` for `k≥2`; `η₁≡0`).
2. Public `confint(...; X=)` widened to accept n×p `AbstractMatrix` (Multinomial) alongside the existing 3-array cov layout.
3. Focused test `test/test_second_order_multinomial_ci.jl` **27/27**.
4. Holdouts: Multinomial FE → **PARTIAL (native Wald)**; BB shared-φ remains OUT.

## Checks

```text
julia --project=. test/test_second_order_multinomial_ci.jl
→ MultinomialFit … no-X 17 pass / +X 10 pass
```

## Follow-up

- Paired SO toy cell / RCall receipt (optional).
- Remaining paste gates: Delta dispersion A; D3 Stage 1; S4; Totoro T4; #357 foreign rebase.
- Still OUT: GP-1 ruling, Student-t free ν, BB shared-φ pairing, Λ raw.
