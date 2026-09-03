# Native Gaussian source-fitting leaf
OWNS: parent src/source_fit.jl,test/test_gaussian_sources.jl; central includes,
exports, docs/README/changelog and runtime records. Existing source/spatial
fitters and all foreign/R lanes are untouched.
Contract: docs/dev-log/decisions/2026-08-31-gaussian-sources-fit.md.
CHECK: julia --project=test/parity tools/core070_gaussian_sources_run.jl
EXPECT: CORE070_GAUSSIAN_SOURCES_UNIT_PASS
Before implementation run missing-symbol regression (must fail). Then same
frozen test fixture must pass. Independent reference covariance and derivatives,
analytic no-source ML control, invalid-input tests, zero-iteration health control.
Runtime source/fixture/env hashes and failed attempts retained. No paired-R,
recovery/coverage or performance result. Totoro existing socket, one Julia/BLAS
thread; estimate under5min per bounded check, cap300s. No DRAC campaign here.
Full package/Documenter/public-interface closure remains unpaid until validated.
Execution checkpoint2026-08-31: regression-before-implementation ordering was
not achieved. Remote and local availability checks failed before assertions;
retain that deviation, do not count an infrastructure failure as the intended
red test. Candidate implementation and analytic nonempty-source test are now
prepared. Baseline fc2fb766 archive plus the same test will provide a negative
control once the runtime is restored, not retroactive TDD ordering. Current
Unlazy ledger: .unlazy/core070-aghq/gaussian-sources-checkpoint/GATES.md.
