# After-task — Option D §6 holdouts disposition (2026-09-05)

## Scope

Parallel Option D slice: honest OUT/PARTIAL/NOT ATTEMPTED disposition for every row in
`second-order-holdouts-2026-09-04.md` against `second-order-parity-contract.md` §6–§7.
No programme-level second-order parity claim.

## Outcome

| Count | Status |
|---|---|
| 9 | OUT |
| 3 | PARTIAL |
| 1 | NOT ATTEMPTED |

Key corrections vs frozen table alone:

- **Realistic Gaussian grid** → PARTIAL (repaired 2026-09-04 intercept-`X` patch; 8/8 SE D1)
- **NB2-log batch-1** → PARTIAL (SO): each-own receipts only, not matched-coordinates
- **Binomial-cloglog** → OUT despite numeric D1 pass: §2 disputed default blocks claim

## Checks run

```text
Read contract §6–§7, D1 gate receipt, binomial_cloglog.json, confint_family.jl _CIFit Union
Read gaussian-intercept + realistic-size pairing disposition docs
Advisory 0.7.1 smoke log (receipt-only; no re-run)
```

No code changes. No test re-run (disposition is evidence audit, not new compute).

## Files touched

- `docs/dev-log/core070/second-order-holdouts-2026-09-04.md` — disposition pass extended
- `docs/dev-log/core070/advisory-r071-smoke-2026-09-05.md` — new receipt stub
- `docs/dev-log/check-log.md` — append entry

## Not claiming

- Second-order parity complete (contract §7)
- Holdout clearance for cloglog/Tweedie/GP-1/Student-t/ordinal/truncated families
- Matched-coordinates tier
- Advisory 0.7.1 as oracle replacement

## Follow-up

- §2 maintainer ruling on cloglog/Tweedie-grouped disputed defaults
- API gaps: Wald `_CIFit` for Lognormal/Truncated*/OrdinalPerTrait*
- Follow-up batch: Delta-lognormal/Delta-Gamma, Multinomial, shared-φ BetaBinomial
