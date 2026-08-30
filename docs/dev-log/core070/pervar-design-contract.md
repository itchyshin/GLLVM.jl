# Per-variance Gaussian: requested design and numerical stability

The fitter accepted X but previously ignored it: a six-column requested design returned four trait intercepts and counted12 instead of14 free parameters. The retained red regression records1 pass/2 fail, with no unrelated errors.

The candidate now profiles the complete requested design by GLS at each covariance trial; no intercept is added implicitly. Coefficients and parameter counts reflect q. X=nothing preserves trait-intercept behavior, and a zero-column design specifies zero mean. Malformed, nonfinite and rank-deficient inputs fail explicitly. See the [math contract](../decisions/2026-08-30-pervar-requested-design.md).

Expanded tests found subtractive Woodbury cancellation near a zero diagonal variance: it produced huge positive likelihoods and lost GLS accuracy. This per-variance likelihood and its design GLS now use direct covariance Cholesky, with the same model and no ridge or variance floor. Numerically unfactorizable covariance trials are rejected with Inf and a counted warning; unrelated exceptions propagate. The reported likelihood is freshly evaluated at returned coordinates.

This direct factorization costs O(p³); no speed improvement is claimed. Default intercept-only EM retains its separate path. Any future faster implementation must preserve the boundary regressions and establish same-model accuracy before timing comparisons.

## Verified target

Final Totoro Julia1.12.6 one-thread runs pass27 new assertions (10 design,14 boundaries,3 tiny-diagonal) and14 unchanged adjacent assertions. Commands took25.38s and15.31s, below the declared under3minute budget/hard300s. The adjacent L-BFGS test visibly rejected3 covariance evaluations and still matched EM under its original tolerance. Tests check dense GLS/normalized likelihood, coefficient/covariance/loglik equivariance under Y+Xdelta, coefficient copies/counts, explicit versus implicit intercepts, malformed/empty designs and a tiny positive diagonal with SPD marginal covariance.

All five attempts remain available: original ignored-X red; initial10+14 green; expanded boundary failure; direct-Cholesky pass27 with an adjacent trial exception; final27+14 green. Evidence binds original and current source/fixture hashes and actual process outcomes. Six negative controls reject false parity, omitted checks, changed red source, missing process, invented review and corrupt process.

## Limits

This is a locally tested candidate repair, not full R parity. It does not implement R's fixed-residual/unique-variance decomposition, general newdata prediction, formula integration, intervals or recovery. No full package suite, JET/Aqua/Allocs, benchmark or Documenter build ran. README, docstrings, worked design and runner registration are updated; rendered verification remains pending.

Independent external numerical review remains pending payload-specific authorization; no rejected dispatch was retried. New source changes invalidate whole-source pins on earlier parity receipts: those remain historical until the relevant integrated runs are repeated. The master manifest remains DRAFT and M1 PARTIAL.
