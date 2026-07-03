# After Task: Bridge Missing-Mask Boundary Verification

## Goal

Verify the response-missing mask bridge boundary after the LV and mixed-family
truth locks: admitted one-part no-X masks should work, while Gaussian masks,
fixed-effect-X masks, `X_lv` masks, mixed-family masks, and ordinal masked CIs
must remain fail-loud or unavailable.

## Implemented

No source behavior changed. This was an evidence-only verification slice.

Confirmed boundaries:

- Poisson and NB1 masked fits match their native masked fitters and ignore
  sentinel values in unobserved cells;
- all-true masks reduce to the complete-data bridge path;
- masked no-X CIs route for the admitted one-part non-Gaussian rows;
- ordinal-probit masked point fits route through the per-trait cutpoint bridge;
- unsupported masked cells fail loudly: fixed-effect `X` plus mask, Gaussian
  mask, ordinal masked CI, and mixed-family mask.

## Mathematical Contract

No likelihood or missing-data contract changed. The mask remains an observation
indicator (`true = observed`) for response cells. This is not predictor missing
data, not `X_lv` missing-data support, and not mixed-family missing-response
support.

## Files Changed

docs:

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-02-bridge-missing-mask-boundary-verification.md`

## Tests Added

None. Existing focused tests already cover the mask boundary.

## Benchmark Numbers

N/A - no code changed.

## R-Parity Verdict

Parity: guarded. One-part non-Gaussian missing-response bridge rows are covered
where tested. Mixed-family and `X_lv` masks remain explicitly blocked.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs/evidence-only slice.
- Allocs: not run - no inner-loop code changed.
- Aqua: not run - no dependency/export/project change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
# bridge missing-response mask | 83 pass

sed -n '1,260p' test/test_bridge_missing_mask.jl
# confirmed admitted one-part masked rows and fail-loud unsupported cells

rg -n 'mask|missing|X_lv|mixed-family|ci_mask|ci_method|Gaussian|ordinal' src/bridge.jl test/test_bridge_missing_mask.jl test/test_bridge_capabilities.jl docs/src/gllvmtmb-parity.md docs/dev-log/decisions/2026-07-02-*
# confirmed capability notes and decision docs keep mixed-family and X_lv masks blocked
```

## Consistency Audit

The mask ledger is coherent: `GLLVM.bridge_capabilities()` lists
`missing_response` for the admitted one-part rows and excludes the mixed-family
row. `ci_mask_*` columns are narrower routed-CI flags, not a general promise of
masked inference for every family or structure.

## GitHub Issue Maintenance

No issue or PR action taken. This is local handover evidence only.

## What Did Not Go Smoothly

No failure. The only audit wrinkle is terminology: "missing-response mask" must
not be shortened to "missing data support" because predictor missingness and
mixed-family masks are still blocked.

## Team Learning

Curie/Rose: mask support should always name the admitted route and excluded
route, because "missing data" is too broad and easy to overclaim.

## Remaining Risks

- Full-suite and live R bridge tests were not rerun in this slice.
- Mixed-family and `X_lv` mask support remain future modelling/bridge work.

## Known Limitations

Focused Julia bridge evidence only. No API widening, no R grammar change, and
no new missing-data model.

## Next Command

```sh
cd /private/tmp/gllvmjl-phylo-xlv && julia --project=. --startup-file=no test/test_bridge_x.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - one-part missing-response mask support is
verified, and the mixed-family, Gaussian, fixed-effect-X, `X_lv`, and ordinal-CI
mask exclusions remain explicit.
