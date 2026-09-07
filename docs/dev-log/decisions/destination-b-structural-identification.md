# Covariance-coordinate identification diagnostic

For `p` traits, a symmetric trait covariance has `p(p+1)/2` free entries.
A lower-triangular anchored rank-`r` loading matrix has
`p*r-r*(r-1)/2` coordinates. Adding `p` separate unique variances can
therefore exceed the dimension of its only likelihood-visible quantity,
`L*L' + Diagonal(U)`. Such a decomposition is structurally non-identifiable,
regardless of sample size. With `p=2, r=1`, four coordinates describe three
entries. A positive numerical Hessian from roundoff does not repair this.

The named-group and phylogenetic fitters now warn before optimisation when that necessary
dimension bound fails. It preserves point fitting: total covariance may still
be identifiable although loading and unique components are not. For an
unrestricted total covariance target, `mode=:dep` removes this redundant
decomposition. This is a user choice, not a silent model substitution.

Passing the count check is not a sufficient identification test. Aliased
incidences, zero components, factor constraints, and insufficient replication
still need examination. Full-coordinate Wald intervals remain unavailable
when valid marginal curvature cannot be established; no ridge is added.
Known coordinate-count redundancy now returns `:nonidentifiable` before the
Wald helper attempts inversion. This avoids a spurious positive numerical
Hessian overriding a mathematical null direction. Historical failed-curvature
receipts remain preserved; the current explicit diagnosis is stronger, not a
relaxed interval acceptance gate.

The independent four-group pilot exposed this with two rank-one-plus-unique
terms at p=2. Its 100- and400-iteration receipts remain failures of the original
interval-feasibility requirement. A same-data `:dep` representation is a
separate predeclared diagnostic, not a replacement receipt or a coverage result.
