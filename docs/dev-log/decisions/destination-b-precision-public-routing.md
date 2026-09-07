# Destination B: explicit native precision routing

Status: native dispatch implemented with bounded regression; public R admission stays closed.

The existing `fit_gllvm` interface will accept `phylo=precision`, where
`precision isa PrecisionPhy`, together with `phylo_rank`, `phylo_mode` and
`species_id`. These keywords identify a phylogenetic covariance source, not
an ordinary group or the intrinsic trait axis. Defaults with an explicit
precision are rank one and `:barelowrank`; `:explicitunique` retains the
existing consumer's identification restrictions. Precision maps, native scale,
determinants and retained ancestors are unchanged.

Without ordinary `grouping`, this selects the existing multivariate Gaussian
precision fitter. With explicit grouping terms, it selects the single joint
Gaussian marginal likelihood, not two independently fitted models. The first
joint ordinary-source scope is `mode=:indep, common=false`; no other covariance
combination or non-Gaussian phylogenetic fit is implied. A global `K`, `num_lv`,
row-effect shortcut, dispersion partition, or `pervar` flag cannot silently
modify this model. Phylogenetic options without `phylo` must fail rather than
be ignored.

The grouping formula path supplies the complete fixed-effect design and may
resolve a `species_id` column symbol just as it resolves ordinary grouping
columns. No formula term is inferred merely from an identifier. The API reuses
the existing fit types, retained data, covariance representation and marginal
interval helpers; it changes dispatch only. Paired frozen-R qualification,
coverage and general joint-model completion remain separate requirements.
