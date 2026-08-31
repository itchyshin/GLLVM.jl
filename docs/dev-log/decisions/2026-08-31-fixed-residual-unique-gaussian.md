# Fixed Gaussian residual plus trait-specific unique variance

Reference: gllvmTMB b4d5fee64def88bc768dda1f1f77c29b295edd86,
R/fit-multi.R:5611–5648. The ordinary row-level unique diagonal fixes the residual
SD to c=max(0.001*sd(vec(Y)),1e-6), then estimates unique SDs and loadings.
For complete trait-by-site data with one observation per trait/site:

    Y_s = X_s beta + L z_s + diag(sqrt(psi2)) u_s + c e_s,
    z_s ~ N(0,I_K), u_s,e_s ~ N(0,I_p), independently,
    M = L L' + diag(psi2 + c^2).

| Quantity | Julia contract | Reference coordinate | Information retained |
|---|---|---|---|
| c | explicit fixed_residual_sd | mapped log_sigma_eps | fixed, not counted as a free parameter |
| psi2 | exp(log_unique_variance) per trait | exp(2*theta_diag_B) | fit.ψ², no subtraction near zero |
| total diagonal | psi2+c^2 | unique plus fixed residual | existing fit.phi-squared semantics unchanged |
| L | packed raw lower triangle | theta_rr_B | covariance compared, sign invariant |
| beta | complete X GLS; X=nothing means trait intercepts | beta_fix | zero-column design means zero mean |

Implement in the existing per-variance fitter as an explicit fixed-residual
keyword, default0 retaining the existing model. This does not alter has_diag
or any shared-sigma model. Store unique and total diagonal variances separately
and preserve the old six-argument fit constructor with c=0. Parameter count
q+rr_theta_len(p,K)+p is unchanged. No automatic residual suppression or hidden
ridge: callers/compatibility layer supply the reference's c explicitly.

For c>0 optimize raw L and log(psi2), with exact GLS and normalized Gaussian
marginal; reuse existing stable direct Cholesky. Existing EM applies only when
c=0 and X is omitted; c>0 uses L-BFGS because unconstrained EM can cross the
fixed residual lower bound. Do not fit unrestricted total variance and subtract
c^2 afterwards: that permits negative unique variance and changes the domain.

Regression requirements before implementation: new keyword fails on baseline;
finite positive unique variance, total=unique+c^2, fixed scale preserved,
zero-column and nonzero designs, normalized density and AD/FD scale transform,
old constructor/default behavior, invalid fixed scales. A sizable c control must
expose implementations that ignore it or subtract it only after fitting.

Reference replay retains the original p4/n120/K1 seed81031 realization and R
unique defaults. First compare normalized likelihood and gradients at fixed
coordinates against retained R TMB inputs; then both-engine fit health and
absolute delta logLik<=1e-3. Do not replace failed R health with a native-only
success. No intervals, recovery, formula/bridge or AGHQ-fallback parity claimed
until those surfaces are implemented and qualified separately.
