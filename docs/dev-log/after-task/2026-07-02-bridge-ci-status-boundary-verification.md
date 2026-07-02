# After Task: Bridge CI Status Boundary Verification

## Goal

Verify that bridge confidence-interval requests either return real routed
payloads or fail/mark unavailable explicitly. The target risk was an empty or
success-shaped CI payload being misread as support for mixed-family,
per-trait-ordinal, or unsupported `X_lv` intervals.

## Implemented

No source behavior changed. This was an evidence-only verification slice.

Confirmed boundaries:

- `ci_method = "none"` leaves the default bridge payload unchanged;
- one-part Gaussian/Poisson/binomial CI routes have parity checks against native
  Wald/profile/bootstrap engines where admitted;
- per-trait ordinal bridge CI requests throw with an explicit not-routed
  message;
- mixed-family CI requests return an explicit `ci_note` saying CIs are not
  routed and an empty CI table;
- bridge `X_lv` fits admit only Wald `B_lv` payloads; profile/bootstrap remain
  fail-loud gates.

## Mathematical Contract

No interval method changed. Wald/profile/bootstrap scalar CI payloads remain
native bridge routes where tested. `X_lv` Wald intervals target
`B_lv = Lambda * alpha_lv'`. Profile/bootstrap `X_lv`, mixed-family CIs, and
per-trait ordinal-cutpoint CIs remain outside the admitted bridge contract.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-bridge-ci-status-boundary-verification.md`

## Tests Added

None. Existing focused CI tests already encode the relevant gates.

## Benchmark Numbers

N/A - no likelihood or hot-path code changed.

## R-Parity Verdict

Parity: guarded. The bridge CI ledger is not a broad R-user parity claim.
Unavailable rows are explicit status boundaries, not partial support.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs/evidence-only slice.
- Allocs: not run - no inner-loop code changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
# bridge CI routing | 64 pass

sed -n '260,330p' test/test_bridge_ci.jl
# confirmed flat CI payload contract and unsupported ci_method error

sed -n '1,80p' test/test_bridge_mixed.jl
# confirmed mixed-family ci_method="wald" returns empty CI names with
# ci_note containing "not routed"

sed -n '260,286p' test/test_lv_ci.jl
# confirmed bridge X_lv admits only ci_method="wald"; profile/bootstrap throw
```

## Consistency Audit

Bridge CI support is a routed-payload claim only. It does not imply
source-specific `lv`, mixed-family CIs, ordinal per-trait cutpoint CIs,
response-mask `X_lv`, or profile/bootstrap `X_lv`. The current tests and
capability notes keep those as blocked/follow-up rows.

## GitHub Issue Maintenance

No issue or PR action taken. This is local handover evidence only.

## What Did Not Go Smoothly

No test failure. The only ambiguity is semantic: mixed-family CI requests return
an explicit unavailable CI payload rather than throwing. That is acceptable
because `ci_param_names` is empty and `ci_note` says "not routed".

## Team Learning

Fisher/Rose: unavailable CI payloads must carry an explicit status/note, and
empty CI vectors must never be described as interval support.

## Remaining Risks

- R-side bridge code must continue to treat mixed-family CI payloads as
  unavailable status, not as successful interval output.
- Full-suite and live R bridge tests were not rerun in this slice.

## Known Limitations

This verifies focused Julia bridge CI behavior only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - CI routes and unavailability boundaries are
explicit; no mixed-family, ordinal per-trait, profile/bootstrap `X_lv`, or
source-specific interval support was promoted.
