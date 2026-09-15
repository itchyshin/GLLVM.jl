# After-task — §2 Hessian (A) + binomial_cloglog receipt promotion

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (true-parity `/goal` continuation)  
**Branch:** `cursor/s2-hessian-a-tweedie-receipt-01b1` from `origin/main` @ `3091fe61`  
**Base context:** PR **#347** already **MERGED** → `main` @ `3091fe61`.

## Goal

Apply Ada default **(A)** for contract §2: ratify `:observed` Hessian selector for
Binomial/cloglog and Tweedie grouped defaults; promote existing each-own-optimum
`binomial_cloglog` receipt; land gated RCall regression test.

## Rose fence

- **≠** programme §7 / true-parity destination complete.
- **≠** full 0.7 parity claim.
- **=** `binomial_cloglog` each-own-optimum D1 may be cited for fixed-effect SE/vcov
  (existing tolerances); Tweedie grouped **second-order Wald** still **OUT** (`_CIFit` gap).

## Changes

| Area | Files |
|------|--------|
| Decision ACCEPTED (A) | `docs/dev-log/decisions/2026-09-15-second-order-hessian-s2-pending.md` |
| Contract + holdouts | `second-order-parity-contract.md`, `second-order-holdouts-2026-09-04.md` |
| Board + LOOP | `2026-09-14-true-parity-pending-board.md`, `LOOP/checkpoint.md` |
| Receipt + driver | `second-order-batch-out/binomial_cloglog.json`, `tools/core070_second_order/cells.jl` |
| Test (parity-gated) | `test/test_second_order_s2_cloglog_ratified.jl`, `test/runtests.jl` |

## Commands

```text
git fetch origin main   # tip 3091fe61 post-#347
julia --project=. test/test_second_order_s2_cloglog_ratified.jl   # skip unless GLLVM_PARITY_TESTS=1
gh pr view 347 --json state   # MERGED
gh pr checks 351              # Documenter-only docs PR
```

## PR / merge sweep (same turn)

| PR | State | Notes |
|----|-------|-------|
| [#347](https://github.com/itchyshin/GLLVM.jl/pull/347) | **MERGED** | Julia 8/8 + Documenter green; Frozen R advisory FAIL OK → `3091fe61` |
| [#350](https://github.com/itchyshin/GLLVM.jl/pull/350) | OPEN | FORWARD export disposition — CI in flight @ sweep time |
| [#351](https://github.com/itchyshin/GLLVM.jl/pull/351) | OPEN → merge if green | T11 spec-defect inventory — Documenter green |
| [#353](https://github.com/itchyshin/GLLVM.jl/pull/353) | OPEN | Twin bridge headline inventory — CI in flight |

## Reviewers (bounded)

- **Fisher:** §2 (A) aligns receipts with observed TMB structural default for cloglog.
- **Rose:** fences explicit; no covered-row promotion; no version bump.
- **Shannon:** docs + test + tool receipt only; no engine edit.

## Remaining Shinichi gates

- **S4 probe yes** · **G0 Stage 1** (`loading_profile`) · **ack Totoro D-139** (T4 / optional #323)
- **Reverse tokens:** `reject §2 hessian A`, `reopen #323`, `reject matched-θ C`
- Open docs PRs **#350/#353** await full Julia shard green before merge
