# Native fitting update: ordinary fixed-residual modes


MODE-ORD-INDEP and MODE-ORD-COMMON now have actual native fits using
`fit_gaussian_sources(...; sigma_eps_fixed=reference_sd)`, with6 and4 free
coordinates respectively. The original deterministic data, public R calls,
per-row residual suppression and independent-versus-common covariance meanings
are unchanged. Both engines pass the declared health checks; absolute likelihood
differences are2.56e-11 and3.98e-13. See source-fixed-residual-final-evidence.json and
source-fixed-residual implementation after-task. This supersedes the earlier
UNIMPLEMENTED_OR_UNQUALIFIED statement for these two native models only.
The other seven exact fitted-mode cases, formula/bridge reachability, source
crossings, recovery and inference remain unqualified by this slice.
