# Per-species Gaussian fixed-design profiling

For site s, y_s ~ Normal(X_s beta, V), where V=Lambda Lambda' + diag(phi^2). With a full-column-rank stacked X, define A=sum_s X_s' V^-1 X_s and b=sum_s X_s' V^-1 y_s. The ML profile coefficient is beta_hat=A^-1 b. Evaluate the normalized Gaussian ML log-likelihood at this coefficient; do not add the REML logdet(A) adjustment.

An omitted X retains p unrestricted trait means, which are row means of the p-by-n Y matrix. An explicit X contains all requested fixed effects with no implicit intercept. A zero-column X fixes the mean to zero. The estimated parameter count is length(beta)+pK-K(K-1)/2+p.

Initial reuse of the Woodbury GLS kernel exposed loss of precision near a zero diagonal variance. Both the marginal and design GLS now factor the full covariance directly. This is the same exact likelihood, without a ridge or variance floor, at O(p³) factorization cost. Intercept-only EM retains its separate fast path; performance claims need new measurements. GLS is recomputed for each covariance trial; OLS is only a mean-shift-equivariant warm start. Full-rank and finite-input checks precede optimization.

Regression requirements: known complete design, dense independent stacked GLS/likelihood, Y→Y+Xdelta equivariance, zero-column design, malformed/rank-deficient rejection and unchanged intercept-only tests. This is an existing ignored-X bug repair, not a new variance model, R-default decomposition, REML feature or recovery claim. Frozen R's fixed-design creation is R/fit-multi.R:2710 at b4d5fee64def88bc768dda1f1f77c29b295edd86; exact R variance-map fit parity remains a separate obligation.

Covariance trials that cannot be factored in finite precision are rejected with an infinite objective, with a counted warning at fit completion. This does not add a ridge or clamp any parameter. Other exceptions are rethrown. The reported likelihood is reevaluated at returned coordinates and cannot be marked converged if nonfinite.
