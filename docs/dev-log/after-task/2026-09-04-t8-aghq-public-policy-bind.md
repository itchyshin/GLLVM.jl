# After-task: T8 AGHQ 14-row public-policy bind (2026-09-04)

## Scope

Bind the 14 public-fit AGHQ rows in `t8-aghq-bind-next-slice.md` with real
`gllvmTMB()` receipts. Do not touch D6/T7/T9/T10/T14.

## Outcome

- **14/14 bound** via `tools/core070_aghq_public_policy_bind.R` (public fits only)
- Receipt JSON + human summary under `docs/dev-log/core070/`
- Ledger updated: `executable_case_ids` populated, `disposition` removed on all 14
- **FREE=0** maintained; REQUIRED=497 unchanged

## Checks

```sh
Rscript --vanilla tools/core070_aghq_public_policy_bind.R \
  ../gllvmTMB-gllvm-twin-20260904 \
  docs/dev-log/core070/aghq-public-policy-bind-receipt-2026-09-04.json
# CORE070_AGHQ_PUBLIC_POLICY_BIND_PASS bound=14/14

python3 tools/core070_aghq_public_policy_bind_apply.py \
  --ledger docs/dev-log/core070/required-source-case-map.json \
  --receipt docs/dev-log/core070/aghq-public-policy-bind-receipt-2026-09-04.json

python3 tools/core070_ledger_counts.py docs/dev-log/core070/required-source-case-map.json
# REQUIRED=497 FREE=0; 14 target rows no longer BLOCKED_SPEC_DEFECT
```

## Notable observation

`AGHQ-AUTO-K-DELTA`: public fit k=5 (family label `"binomial Gamma"`), frozen
helper oracle k=9 (`family="delta_gamma"` string). Bind records public observation.

## Still open (Shinichi)

D6, T7, T9, T10, T14 unchanged. True-parity claim not closed.

## Rose

Doc refresh only; no user-facing API change.
