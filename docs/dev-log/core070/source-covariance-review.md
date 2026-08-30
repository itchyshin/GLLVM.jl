## Scoped verdict — B1 representation accepted; no native parity

The six labelled fixed points support the source covariance as a frozen Gaussian-objective invariant:

\[
V=\sigma_\varepsilon^2I+\sum_r (Z_rC_rZ_r^\top)\otimes(\lambda_r\lambda_r^\top)
\]

for complete trait-by-site data (column-major `vec(Y)`). For arbitrary long-format observations, the safe implementation form is instead
\[
V_{ov}=\sigma_\varepsilon^2\mathbf1[o=v]+\sum_r
C_r[g_r(o),g_r(v)]\lambda_r[t(o)]\lambda_r[t(v)],
\]
not a literal Kronecker product.

- The R oracle constructs exactly this latter observation-level covariance and agrees with its TMB objective at all six labelled cases; the Julia reference independently reproduces values and gradients. See [R oracle](../../../tools/core070_source_fixed_point.R:25), [reference test](../../../test/parity/test_source_fixed_point.jl:16), and the retained 44/44 result [log](../../../.unlazy/core070-aghq/source-fixed-point/attempt2/process/02.log:4).
- Qualification: these are fixed-parameter, Gaussian, complete-data checks—not fitted parity. Also, animal and one-kernel prepared inputs are byte-identical, so this is six labelled points but only two numerical source-structure classes (one source and two sources).

## Existing routes

No inspected production route matches the general source model.

- `gaussian_marginal_loglik`’s structured/phylogenetic term is \(J_n\otimes B\), with its supplied covariance on the trait axis, not arbitrary group/site \(ZC Z^\top\). [likelihood](../../../src/likelihood.jl:64), [implementation](../../../src/likelihood.jl:206).
- Grouped random effects use an iid group covariance and trait effect proportional to \(11^\top\), not arbitrary \(C_r\) and \(\lambda_r\lambda_r^\top\). [random-effects model](../../../src/fit_random_effects.jl:17), [slope implementation](../../../src/fit_random_effects.jl:83).
- The coevolution routes are matrix-normal: \(C\otimes(\lambda\lambda^\top+\sigma^2I)\). [Kronecker model](../../../src/coevolution_kronecker.jl:8); block-NA is a selected version of that same separable model. [block-NA covariance](../../../src/coevolution_blockna.jl:9).

The counterexample is mathematically fair: source covariance has
\(C\otimes\lambda\lambda^\top+\sigma^2I\), whereas matrix-normal also correlates residual noise through \(C\). The observed nonzero gaps substantiate that mismatch. [test](../../../test/parity/test_source_fixed_point.jl:38) Its limitation is that it drops source 1 from the two-source case, so it is a structural counterexample, not a direct failed comparison of the full two-source R point.

## B1 boundary and blocker

B1 should be an explicit Gaussian source-covariance evaluator: complete \(p\times n\) data; known ordered group incidence and fixed SPD \(C_r\); scalar residual scale; one loading vector per source; source counts 1–2 initially. It should exclude source-unique terms, ordinary latent coexistence, missing/block-NA data, covariance estimation, non-Gaussian/AGHQ paths, formula/bridge exposure, inference, and optimizer-parity claims.

Blocking condition: the present Julia test is test-only—its matching density is local test code, not production code. [test](../../../test/parity/test_source_fixed_point.jl:21) Do not reuse `fit_coevolution_gaussian` as B1. A native evaluator must first match all retained R values and gradients with the exact captured group ordering and precision-to-covariance mapping.

