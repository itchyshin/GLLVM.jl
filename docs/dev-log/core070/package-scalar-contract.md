# Complete-package local scalar qualification

The truncated NB2 repair is now exercised through `using GLLVM`, not merely a
source-prefix loader. The loader asserts that `pathof(GLLVM)` is the copied current
candidate's `src/GLLVM.jl`. The unchanged352-assertion precision regression passes;
the unchanged full-module curvature census adds66 passing structural/AD checks.

This qualifies complete-module loading and these targeted tests only. It does not
run `Pkg.test()`, the core suite, a model fit, R parity, recovery or a benchmark.
Independent numerical review remains unpaid. Earlier scalar-only receipts stay
historical and correctly retain their `whole_package_loaded=false` field; this is
new, separate evidence rather than a retroactive promotion.

## Environment and commands

Initial Julia1.12.6 directory discovery was insufficient: its `bin/julia` is absent.
Attempt1 exits127 before Julia runs. Attempt2 uses the verified Julia1.10.0 binary,
one Julia/BLAS thread, `JULIA_PKG_OFFLINE=true`, a fresh writable depot and the
existing local cache. `Pkg.offline(true); Pkg.resolve(); using GLLVM` passes44.39s,
leaving copied source and Project.toml unchanged. The new Manifest exists only in
`.unlazy/core070-aghq/package-qualification/attempt2`, with exact bytes retained.
Shared depots were used as cache inputs; no shared environment or foreign checkout
Project/Manifest was edited. No network dependency installation was requested.

Resolved runtime: Optim1.13.3, ForwardDiff0.10.39, StatsModels0.7.10,
Distributions0.25.131. Further direct dependency versions are pinned in
`package-scalar-evidence.json`. This is not the Totoro runtime or the old1.10 lock.

`tools/core070_package_scalar.jl` performs the module-path assertion and includes
`test/test_truncnb2_precision.jl` unchanged:352pass,7.41s process elapsed.
`test/test_curvature_census.jl` runs separately:66pass,3.17s. The census checks
curvature declarations and scalar derivative identities; it does not claim every
family's curvature policy is accurate or all family fits work.

## Gates and remaining work

`python3 tools/core070_verify_package_scalar.py` verifies exact source snapshots,
Manifest, executable hash, logs and process exits; use Python3.11+ for tomllib.
Nine negative controls reject false module/fullsuite/fitted claims, fabricated
counts, wrong Manifest, corrupt receipt, stale source and premature fitted success.
The first verifier draft read cwd from the receipt rather than its pinned execution
plan; corrected after a KeyError, without changing any process evidence.

Full-suite and original fitted replay remain required. Once authenticated Totoro
observation returns, recover the existing remote job before any restart and retain
its historical source identity. Then qualify this candidate and replay the original
truncated NB2 and Student fixtures under their original health and likelihood gates.
Do not transfer local targeted success into complete Core/AGHQ parity or release.
