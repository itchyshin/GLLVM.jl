# Internal Gaussian source evaluator

The reviewed source model and fixed R reference are recorded in ../core070/source-covariance-contract.md. This implementation is derived from that explicit Gaussian marginal model, not copied from another package's implementation.

For complete Y (traits × units), each source r has known ordered SPD group covariance C_r, unit incidence Z_r and one trait loading vector lambda_r. Mean beta is fixed per trait. The observation covariance in vec(Y) order is

`V = sigma_eps^2 I + sum_r (Z_r C_r Z_r') ⊗ (lambda_r lambda_r')`.

The log density is `-(pn log(2pi) + logdet(V) + residual' V^-1 residual)/2`, where residual=vec(Y.-beta). Residual noise is independent. No centering, ridge, omitted normalization or source-scaled noise. Cholesky solves the quadratic form; no explicit covariance inverse is used in the evaluator.

Initial internal contract: one or two sources, one loading vector per source, complete finite data, scalar positive finite SD, fixed finite SPD source covariance, one-based integer group IDs. Sources may have different numbers of groups and different group incidence. Nonidentity kernels and repeated groups are admissible; the projected source covariance may be rank deficient. Invalid shapes, IDs, nonfinite inputs, asymmetry and non-PD source matrices fail clearly.

This is a dense reference-quality native evaluator, with quadratic memory and cubic factorization cost in pn, not a fast fitting API. ForwardDiff derivatives of beta, lambda and log-sigma are required. It is not exported and adds no fitter or formula/bridge route. Existing matrix-normal semantics remain unchanged. General ranks, unique/common components, missing cells, inferred covariance, other families, inference and optimized-fit parity remain programme obligations outside this increment.
