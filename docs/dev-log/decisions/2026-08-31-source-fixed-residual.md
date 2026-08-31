# Fixed residual noise in additive Gaussian source models

The frozen R0.7.0 reference at b4d5fee64def88bc768dda1f1f77c29b295edd86
fixes residual noise in ordinary independent Gaussian random-effect models to
max(0.001*sd(y),1e-6). Existing reference qualification is recorded in
../core070/covariance-modes-contract.md and the retained exact calls in
test/parity/fixtures/core070_covariance_modes.R. The native source fitter needs
an explicit fixed-noise option to represent those models. It must not apply
the R heuristic to other Julia fits implicitly.

For traits by units response Y, mean beta and source r with projection P_r,
fixed source covariance C_r and estimated trait covariance B_r(theta),

    V(theta) = sigma_fixed^2 I + sum_r kron(P_r C_r P_r', B_r(theta))
    ell(theta) = -0.5 [pn log(2pi) + logdet V + e' V^-1 e]
    e = vec(Y - beta)

When sigma_eps_fixed is supplied, theta contains beta and source coordinates
only. Derivatives and observed Hessian are with respect to those free
coordinates; dof counts them. sigma_fixed must be finite and strictly positive.
It is neither a regularization term nor an extra estimated parameter. The
existing normalized objective can receive an internally assembled full vector
with log(sigma_fixed), but the public start/parameters omit the fixed coordinate.
Report the supplied Float64 scale exactly and residual_fixed=true. The default
nothing retains the existing free residual model and old constructor behavior.

Analytic checks use an empty-source mean-only model and ordinary independent
C=I sources. For each trait t, beta_hat is its sample mean, total variance is
sum_i (Y_ti-beta_t)^2/n, and independent-source variance subtracts known
sigma_fixed^2. With common independent variance, average over all pn residuals
before subtraction. The deterministic tests have interior positive differences.
Constant responses have a finite mean-only optimum when noise is fixed; they
have no finite positive residual-variance ML optimum when noise is free.

Free residual variance plus unrestricted ordinary trait covariance remains
nonidentified for observation-level groups. Fixing residual noise makes a
different specified model; it must not silently replace a requested free model.
No rotation-specific raw-loading parity, confidence interval, recovery/coverage
or broader source-family claim follows from these analytic checks. Exact R
comparisons and all remaining Core/AGHQ requirements remain separate gates.
