# Explicit per-trait truncated NB2 routing

The public default remains one shared r. Explicit disp_group=:species or one
positive distinct ID per trait selects the existing per-trait engine. Repeated
IDs are rejected, because that engine does not implement partial grouping.

For y>=1, log f(y)=log NB2(y; mu,r_t)-log(1-(r_t/(r_t+mu))^r_t),
mu=exp(beta_t+Lambda_t*z_s), z_s~N(0,I). Observed joint curvature and likelihood
constants are unchanged. Free coordinates are beta, identified loadings, log r_t;
this dispatch adds no parameter, ridge, optimizer, or inference method.

The original seed58/p5/n120/K1 fixture is retained. Tests compare the named fitter,
unified fit, wide intercept-only and reordered complete long-table fits. Explicit
per-trait selection preserves the R reference's log_phi_truncnb2 parameterization.
Covariate, partial-grouping, bridge and interval support are not implied.
