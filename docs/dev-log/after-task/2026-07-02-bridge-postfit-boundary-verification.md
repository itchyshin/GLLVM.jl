# After Task: Bridge Postfit Boundary Verification

## Goal

Verify the postfit bridge capability surface after the LV boundary closeout, and
confirm that the bridge ledger still separates native Julia postfit support from
the narrower R-bridge retained-payload contract.

## Implemented

No source behavior changed. This was an evidence-only verification slice.

The current bridge matrix remains coherent:

- `postfit_coef`, `postfit_fit_stats`, `postfit_summary`, and
  `postfit_ordination` are listed for all bridge rows;
- `postfit_predict` is listed for all bridge rows, including ordinal rows through
  retained cutpoint/probability payloads;
- `postfit_residuals` and `postfit_simulate` deliberately exclude ordinal bridge
  rows because the R bridge retained payload does not advertise a scalar-mean
  residual/simulation contract for ordinal rows;
- mixed-family remains complete balanced point/postfit only, with no fixed `X`,
  no `X_lv`, no masks, and no CIs.

## Mathematical Contract

No estimand, likelihood, or interval parameterisation changed. This verification
only checks that postfit capability flags match the implemented bridge payloads.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-bridge-postfit-boundary-verification.md`

## Tests Added

None. Existing focused tests already cover the postfit and bridge capability
contracts.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: guarded. Native Julia postfit methods are broader than the R bridge
admission surface in some places. The bridge ledger is intentionally narrower
and uses capability flags plus notes to avoid promoting retained payloads into
unsupported R-user claims.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs/evidence-only slice.
- Allocs: not run - no inner-loop code changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_postfit.jl
# post-fit ordination core | 96 pass
# post-fit predict/fitted | 9 pass
# post-fit residuals | 10 pass
# post-fit AIC/BIC + show | 8 pass
# post-fit Poisson fits | 163 pass
# post-fit NB fits | 160 pass
# post-fit Beta fits | 215 pass
# post-fit Gamma fits | 215 pass
# post-fit Ordinal fits | 216 pass

julia --project=. --startup-file=no test/test_simulate.jl
# simulate(fit) | 5 pass

julia --project=. --startup-file=no test/test_summary_table.jl
# Summary / coefficient table | 14 pass

julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# bridge capabilities ledger | 105 pass

julia --project=. --startup-file=no test/test_bridge_mixed.jl
# bridge mixed-family payload metadata | 18 pass

rg -n 'postfit_|newdata|unconditional|mixed-family|ordinal|simulate|residuals|predict' src/bridge.jl test/test_bridge_capabilities.jl test/test_bridge_mixed.jl docs/design docs/dev-log/decisions docs/src README.md
```

## Consistency Audit

The apparent native/bridge distinction is intentional: native ordinal residuals
exist, while the R bridge capability ledger does not claim ordinal
residual/simulate support because the retained bridge payload is not a
scalar-mean residual contract. Mixed-family postfit remains point/postfit only.

## GitHub Issue Maintenance

No issue action needed. This is local handover evidence for the finish-gap run.

## What Did Not Go Smoothly

No failures. The main ambiguity was wording: native postfit support is broader
than the R bridge capability ledger, so the audit explicitly preserves that
distinction.

## Team Learning

Hopper/Rose: bridge postfit flags should be read as retained-payload contracts,
not as broad native Julia postfit claims.

## Remaining Risks

- R-side admission can still drift if `gllvmTMB` widens postfit methods without
  a matching `GLLVM.bridge_capabilities()` audit.
- Mixed-family remains deliberately narrow: no fixed `X`, no `X_lv`, no masks,
  and no CIs.

## Known Limitations

This did not run the full package test suite or R-side bridge tests. It verified
the focused Julia postfit and bridge capability tests only.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && rg -n 'newdata|unconditional|simulate\\(|predict\\(|residuals\\(' src test docs/src
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - postfit capability flags match the current
bridge contract, with native-vs-bridge scope kept explicit and no public
capability promotion.
