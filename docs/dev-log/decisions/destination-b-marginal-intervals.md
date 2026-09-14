# Destination B marginal interval foundation

Before implementation: for optimiser coordinates theta, compute H as the Hessian of the observed marginal negative log likelihood, including all free nuisance parameters. Solve H V=I. A named natural target g(theta) and chosen transform h have variance grad(h∘g)' V grad(h∘g); invert the transform on its Wald limits. Never use the conditional random-effect Hessian, an isolated fixed-effect block inverse, ridge repair, or a pseudo-inverse to report a successful interval.

| Target | Coordinates / draw | Extractor and interval scale |
|---|---|---|
| Fixed effect | Complete marginal theta beta block; simulation mean X beta | g=beta_i; identity |
| Group variance or SD | Group source loading/unique coordinates; independent source draws | diagonal(LL′+diag(U)) or its square root; log |
| Latent covariance | Source factor draw L z, not individually rotated loadings | entry of LL′ (plus named U when target includes it); identity off-diagonal/log diagonal |
| Identifiable variance share | Explicit ratio of named source variances in the fitted model | g in (0,1); logit; boundary unavailable pending profile |

The first helper is internal infrastructure, not a public grouped fit/interval claim. Its tests use an exact quadratic marginal objective with correlated nuisance parameters to detect the tempting incorrect blockwise inverse, transformed positive targets, nonconvergence, nonstationarity, singular/indefinite curvature, and target-domain boundaries. Sparse model fitters must supply the actual observed marginal objective and their complete coordinate vector; integration and recovery are separate owed gates. No blanket nominal-coverage threshold is introduced.
