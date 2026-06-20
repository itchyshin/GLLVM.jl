# After-task: Phylo-signal Wald CI Scale Fix

Date: 2026-06-14
Branch: `codex/high-rate-poisson-safeguard`
Issue: GLLVM.jl #92

## Goal

Make `phylo_signal_wald_ci` correct and covered on the current integration
branch, rather than leaving the fix stranded on the stale/conflicting
`a1-nongaussian-ci` branch.

## Files Changed

- `src/GLLVM.jl`
- `src/confint_derived.jl`
- `test/test_confint_derived_wald.jl`
- `test/runtests.jl`
- `docs/dev-log/check-log.md`

## Implementation

`_derived_unpack` now treats the phylo-unique `σ_phy` block as natural-scale and
signed. This matches the Gaussian phylo fitter's packed parameter layout. The
previous `exp.(...)` was appropriate for log-packed `σ_eps`, `σ²_B`, and `σ²_W`,
but not for `σ_phy`; it inflated H² and destroyed the signed loading-like
parameterisation.

The transformed-Wald derived CI module is now included by `GLLVM.jl`, and these
helpers are exported:

- `transformed_wald_ci_derived`
- `correlation_wald_ci`
- `communality_wald_ci`
- `icc_wald_ci`
- `phylo_signal_wald_ci`

The regression test now asserts `_phylo_signal_packed(...) == phylo_signal(...)`
to `rtol = 1e-8` for both the `has_phy_unique` path and the `K_phy > 0` path.

## Validation

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived_wald.jl
```

Result: `108/108 pass` in `21.3s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived.jl
```

Result: `45/45 pass` in `13.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_profile_derived_fix.jl
```

Result: `20/20 pass` in `10.1s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_profile.jl
```

Result: `4/4 pass` in `21.4s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3869 pass, 1 broken, 0 failed, 0 errored` in `36m18.1s`.

## R Parity Verdict

Not applicable: this is a Julia derived-CI scale fix and does not change the
R bridge payload.

## JET / Allocs / Aqua

Covered by `Pkg.test()`.

## Rose Verdict

PASS. The scale fix is on the current branch, the regression is wired into the
main test suite, and the full package gate passed. This issue can be closed once
the branch lands or the maintainer accepts the local evidence.

## Next Command

```sh
git status --short --branch
```
