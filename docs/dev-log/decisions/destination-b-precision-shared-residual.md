# Destination B: precision multivariate shared residual implementation note

`residual_mode=:shared` implements the current frozen R source convention for
the simplest Gaussian phylogenetic rank-one model: one `log_sigma_eps` is
estimated and expanded to trait-length residual variance only when calling the
existing sparse likelihood kernel. The previous `:trait` layout remains the
default and estimates one log-SD per trait.

The retained Stan-oracle JSON/build provenance is **gllvmTMB 0.6.0**
(`meta.package_version`; reconciliation record `ff70b5e8`, 2026-08-03), not a
paired frozen-0.7.0 result. Separately, current frozen 0.7.0 source inspection
of `R/fit-multi.R` (initial scalar residual, stored scalar residual, and only
special diagonal mapping later) grounds this parameter-layout implementation.
It is not paired likelihood evidence, model admission, R-engine modification,
or an interval/coverage claim.
