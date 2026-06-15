# 2026-06-15 - Test Warning Hygiene

## Goal

Clean duplicate-method warnings from the full GLLVM.jl test logs so real
warnings remain visible.

## Files Changed

- `test/test_takahashi_selinv.jl`
  - Removed direct source self-include.
  - Calls `GLLVM.takahashi_selinv` and `GLLVM.takahashi_diag` from the loaded
    package module.
- `test/test_bridge_ci.jl`
  - Renamed the bridge-CI Poisson simulator helper to
    `_sim_poisson_bridge_ci` to avoid colliding with
    `test/test_confint_family.jl`.
- `docs/dev-log/check-log.md`
  - Banked the validation evidence.

## Validation

```sh
~/.juliaup/bin/julia --project=. test/test_takahashi_selinv.jl
```

Result: 8/8 passed in 0.4s, with no duplicate-method warning.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: 66/66 passed in 45.4s.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.0s. The previous
`takahashi_selinv.jl` and `_sim_poisson` overwrite warnings did not reappear.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m12.0s. The duplicate-method
warnings did not reappear.

## Benchmark

Not applicable.

## R Parity Verdict

Not applicable. This slice changes test helpers only.

## JET / Aqua / Allocs

`Pkg.test()` passed, including the package quality battery available in this
environment. No dedicated Allocs evidence was added.

## Rose Audit Verdict

Covered. This is a test-harness cleanup and carries no new capability claim.

## Next Command

```sh
git diff --check
```
