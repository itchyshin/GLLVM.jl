# Final missing-surface cluster (core070 §1) — small post-fit tables and
# helpers that did not have a natural home in postfit.jl / extractors.jl.
# Each function documents the R contract it mirrors (file:line in the frozen
# oracle readback) and any deliberate scope reduction.
#
# Item 1.1 — deviance (mirrors methods-gllvmTMB.R:2862-2864).

"""
    deviance(fit) -> Float64

`-2 * loglikelihood(fit)`. Mirrors `gllvmTMB`'s `deviance.gllvmTMB_multi`
(`methods-gllvmTMB.R:2862-2864`), which is exactly `-2 * logLik(object)` — no
null/saturated-model comparison, delegating through the same maximised
marginal log-likelihood that a ridged fit reports (R's "unpenalised logLik at
penalised MAP" caveat is inherited unchanged here).

Deliberately does not touch [`nobs`](@ref) or [`bic`](@ref) — the R/Julia
`nobs` convention mismatch (site count vs likelihood-contributing cells) is a
separate maintainer decision (core070 spec §3.1).
"""
StatsAPI.deviance(fit::AnyGllvmFit) = -2 * StatsAPI.loglikelihood(fit)
