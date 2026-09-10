# Destination B: private grouped Gaussian variance-profile inversion

**Status:** numerical wrapper integrated with the exported
`grouped_gaussian_variance_profile` selector. Independent dense endpoints,
failure regressions, callback review and public workflow checks passed at the
documented scope. This is not coverage, calibration, global-optimum, or R-parity evidence.

For an accepted full grouped fit with recomputed baseline \(Q(\hat\theta)\),
the wrapper evaluates only complete constrained-refit receipts from the nuisance
callback and forms

\[
 D(v)=2\{Q_v(\hat\psi_v)-Q(\hat\theta)\},
 \qquad D(v)\le q_{\chi^2_1}(\text{level}).
\]

The lower side first evaluates the exact \(v=0\) overlay. The upper side uses
bounded geometric expansion until it has an accepted finite outside receipt.
Both sides then delegate a real-receipt bracket to the callback inversion
helper, including final endpoint refits. Any failed receipt, material negative
deviance, observed outward re-entry, absent bracket, or unverified endpoint
makes the whole result unavailable; no midpoint or expansion bound becomes an
endpoint. The chi-square cutoff is a descriptive interior profile reference,
not a boundary calibration or coverage claim.
