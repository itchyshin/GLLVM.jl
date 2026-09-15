# After-task — StudentTFit fixed-ν Wald `_CIFit`

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (`honest-070-true-parity` `/goal`)  
**Branch:** `cursor/studentt-fixed-nu-wald-ci-a0ce`

## Rose fence

- **≠** second-order §7; **≠** paired R SO cells; **≠** free / estimated-ν Wald;
  **≠** GP-1 ruling; **≠** BB shared-φ pairing; **≠** Λ raw.
- **=** native `confint` for fixed-ν `StudentTFit` (shared and species σ).
- **bridge.jl** untouched (#357 foreign).

## Why ungated

Holdout row for fixed-ν was **PARTIAL (first-order only) / API gap** (`StudentTFit`
∉ `_CIFit`), not paste-gated. Free ν remains OUT (boundary pathology); this slice
does not clear it. No Stage 1 / S4 / Totoro / `Project.toml` / R surgery.

## What landed

1. `StudentTFit` ∈ `_FamilyFit` + `_family_ci` when `estimated_nu == false`
   (packing `[β; pack(Λ); log σ…]`; ν plug-in; shared `sigma` or `sigma[t]`).
2. Estimated-ν path throws a clear `ArgumentError` (holdout fence).
3. Focused test `test/test_second_order_studentt_ci.jl` **29/29**.
4. Holdouts: Student-t fixed-ν → **PARTIAL (native Wald)**; free ν stays **OUT**.

## Checks

```text
julia --project=. test/test_second_order_studentt_ci.jl
→ shared σ 18 pass / species σ 9 pass / free-ν holdout 2 pass
```

## Follow-up

- Paired SO toy cell / RCall receipt (optional; fixed-ν first-order Δ already exists).
- Remaining paste gates: Delta dispersion A; D3 Stage 1; S4; Totoro T4; #357 foreign rebase.
- Still OUT: GP-1 ruling, Student-t free ν, BB shared-φ pairing, Λ raw.
