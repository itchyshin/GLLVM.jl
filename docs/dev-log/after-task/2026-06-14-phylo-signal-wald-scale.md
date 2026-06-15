# After Task: Phylo-Signal Wald Scale Fix

## Goal

Fix GLLVM.jl #92: `phylo_signal_wald_ci` rebuilt `sigma_phy` on the wrong scale
inside packed derived-quantity closures, so the packed phylogenetic signal could
disagree with `phylo_signal(fit; Σ_phy)` and leave `[0, 1]`.

## Implemented

- `_derived_unpack` now treats `sigma_phy[*]` as signed identity-scale values,
  matching `fit.pars.θ_packed` from `fit_gaussian_gllvm`.
- `confint_derived_wald.jl` is included in the module.
- `phylo_signal_wald_ci` is exported.
- `test/test_confint_derived_wald.jl` is included in `test/runtests.jl`.
- The phylo fixture now asserts packed `H²` equals the public
  `phylo_signal(fit; Σ_phy)` for every trait.

## Mathematical Contract

The packed Gaussian parameter layout is:

```text
β; log_sigma_eps; optional log_sigma_B/log_sigma_W; Lambda_B; Lambda_W;
sigma_phy; Lambda_phy
```

`sigma_phy` uses an identity signed scale, not a log scale. The fix makes the
derived-CI unpacker match that contract. Positive SD-like parameters still use
the existing log-scale handling.

## Files Changed

- `src/confint_derived.jl` - identity-scale unpack for `sigma_phy`.
- `src/GLLVM.jl` - include `confint_derived_wald.jl`; export
  `phylo_signal_wald_ci`.
- `test/runtests.jl` - include `test_confint_derived_wald.jl`.
- `test/test_confint_derived_wald.jl` - packed-H² equality regression.
- `docs/dev-log/check-log.md` - evidence entry.
- `docs/dev-log/after-task/2026-06-14-phylo-signal-wald-scale.md` - this report.

## Tests Added

Added an exact regression in the phylo transformed-Wald test:

```julia
_phylo_signal_packed(fit.pars.θ_packed, spec, t; diag_Σphy = diag(Σ_phy)) ≈
    phylo_signal(fit; Σ_phy)[t]
```

Gate: `rtol = 1e-8`, `atol = 1e-10` across all traits in the fixture.

## Benchmark Numbers

N/A - no speed path changed.

## R-Parity Verdict

N/A for this slice. This is a Julia derived-CI scale fix. R bridge exposure of
derived intervals remains a later bridge-method slice.

## JET / Allocs / Aqua Verdicts

- JET: passed through `Pkg.test()` quality gate.
- Allocs: not run - no hot path changed.
- Aqua: passed through `Pkg.test()` quality gate.

## Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived_wald.jl
```

Result:

```text
transformed-Wald CIs for derived bounded quantities | 102/102 pass
```

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived.jl
/Users/z3437171/.juliaup/bin/julia --project=. test/test_profile_derived_fix.jl
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint.jl
```

Results:

```text
derived-quantity CIs                 | 48/48 pass
profile_ci_derived fix on phylo cell | 20/20 pass
confint                              | 14/14 pass
```

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: exit code 0. The transformed-Wald block passed inside the suite:

```text
transformed-Wald CIs for derived bounded quantities | 102/102 pass
```

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result:

```text
transformed-Wald CIs for derived bounded quantities | 102/102 pass
bridge_fit minimal no-X contract                    | 175/175 pass
quality                                             | 12/12 pass
Testing GLLVM tests passed
```

## Consistency Audit

The fix removes the local #92 blocker but does not close the GitHub issue or
update public docs. Public docs still need a separate Rose cleanup for bridge
and non-Gaussian CI status drift.

## GitHub Issue Maintenance

No GitHub issue was opened, edited, commented on, or closed. Issue #92 should be
updated only after this branch is staged/committed and ready for review.

## What Did Not Go Smoothly

The transformed-Wald file existed but was not part of the module or main suite,
so the broken behavior could persist beside green package tests. That is now
fixed by including it in `src/GLLVM.jl` and `test/runtests.jl`.

## Team Learning

Noether/Rose: a diagnosed bug is not fixed until the exact failing invariant is
in the suite. Here the invariant is packed-H² equals public-H² under the
declared packing scale.

## Remaining Risks

- Public docs/changelog still need a status cleanup.
- The R bridge does not yet expose derived transformed-Wald CIs.
- The existing duplicate-include warnings in phylo tests remain outside this
  slice.

## Known Limitations

This fix covers the `has_phy_unique` packed scale path for transformed-Wald
phylogenetic signal. It does not broaden CI calibration claims or add coverage
simulation evidence.

## Next Command

```sh
rg -n 'does not expose|not wired|planned|deferred' docs/src docs/dev-log README.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - local #92 scale bug is fixed and package tests
are green; publish/tag remains blocked by public-doc and issue-ledger drift.
