# Non-unit-height tree precision check

Frozen oracle: gllvmTMB 0.7.0 at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. No R engine changes.

For independent Brownian edge increments with variances equal to branch
lengths, let P map increments to root-dropped node values. The native
covariance is C = P diag(length) P'. The bridge correlation convention uses
C / h and Q = h C^-1, where h = 4 for the explicit eight-tip fixture.
Its determinant is logdet(Q) = 14 log(h) - sum(log(length)). Root value is
fixed at zero; the other six internal nodes are retained and marginalized.
The observed order is s8,s1,s6,s3,s7,s2,s5,s4, each repeated twice.

The Julia oracle will assemble covariance by shared ancestral edge paths,
not by inverting R's precision. For loading L and residual variance v, the
fixed response covariance is kron(C_observed / h, L L') + v I. Compare its
dense Gaussian marginal objective to the actual multivariate precision
consumer. Deliberate wrong scale, dropped internal nodes and wrong maps
must differ. Also retain R's non-ultrametric correlation rejection.

This is model identity and transport evidence only. Fitted estimates,
intervals, adapter admission, S4 and recovery are separate pending gates.
Export/test estimates: under 30 seconds each; no optimization or campaign.
