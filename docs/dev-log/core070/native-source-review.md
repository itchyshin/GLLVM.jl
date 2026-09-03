Noether verdict: scoped acceptance for the internal Gaussian complete-data evaluator. I found no mathematical or implementation blocker.

- The covariance assembly uses the correct trait-within-unit `vec(Y)` index and computes  
  `σ²I + Σᵣ Cᵣ[gᵣ(i),gᵣ(j)] λᵣλᵣ′`; residual noise remains independent. The normalized `pn·log(2π)`, log-determinant, and Cholesky quadratic form are all present. [source_covariance.jl](../../../src/source_covariance.jl:45)
- Source-specific incidence is implemented correctly through `groups[i, r]`/`groups[j, r]`, and source order is not conflated. [source_covariance.jl](../../../src/source_covariance.jl:51)
- Validation covers dimensions, one-based IDs, finite inputs, exact symmetry, and SPD source covariances. ForwardDiff is exercised for β, λ, and log σ, including against the frozen R gradients. [test_source_covariance.jl](../../../test/test_source_covariance.jl:25) [test_source_native.jl](../../../test/parity/test_source_native.jl:23)
- Registration is appropriately internal: included in `GLLVM.jl`, not exported, and its unit suite is wired into `runtests.jl`. [GLLVM.jl](../../../src/GLLVM.jl:20) [runtests.jl](../../../test/runtests.jl:150)

One scoped test-coverage gap: the contract admits two sources with different numbers of groups, but the two-source unit test uses two 2×2 covariance matrices, and the frozen fixture repeats one incidence vector across sources. Add one direct-reference test with, say, source 1 having 2 groups and source 2 having 3 groups. The implementation appears to support it; this is missing regression evidence, not a detected defect.

Retained process evidence is substantive, not inferred: current hashes of the evaluator, registration, and both targeted tests match the receipt’s pins; its recorded runs are 24/24 unit assertions and 18/18 frozen-R assertions. I did not rerun tests, fits, or alter files. [unit receipt](../../../.unlazy/core070-aghq/native-source/green/process/00.log:4) [frozen-point receipt](../../../.unlazy/core070-aghq/native-source/green/process/01.log:7)

Limit remains exactly as contracted: this does not establish whole B1, fitting or optimiser parity, formula/bridge exposure, missing data, higher rank, inferred covariance, other families, or inference.

Parent response: added a separate two-group/three-group direct-reference covariance check using explicit incidence matrices. No production code change. Final rerun evidence is tracked in native-source-evidence.json; original24-assertion run remains retained.
