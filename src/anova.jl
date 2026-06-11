# Nested-model likelihood-ratio tests (anova / lrt) for GLLVM fits, plus the
# `_loglik` / `_nparams` accessors for the extended one-part families that postfit.jl
# did not yet cover (so `aic` / `bic` work uniformly across families too).
#
# Free-parameter count convention matches postfit.jl: p intercepts + the
# rotational-df-corrected loading count (pK − K(K−1)/2) + one per scalar nuisance.
# Student-t holds ν fixed, so ν is not counted.

using Distributions: Chisq, ccdf

# β + Λ free-parameter count shared by the intercept-bearing one-part families.
_anova_beta_lambda_np(fit) = (p = size(fit.Λ, 1); K = size(fit.Λ, 2);
                              p + (p * K - div(K * (K - 1), 2)))

# --- _loglik / _nparams for the extended one-part families ---------------------
_loglik(fit::NB1Fit)          = fit.loglik
_nparams(fit::NB1Fit)         = _anova_beta_lambda_np(fit) + 1        # + φ

_loglik(fit::LognormalFit)    = fit.loglik
_nparams(fit::LognormalFit)   = _anova_beta_lambda_np(fit) + 1        # + σ

_loglik(fit::BetaBinomialFit)  = fit.loglik
_nparams(fit::BetaBinomialFit) = _anova_beta_lambda_np(fit) + 1       # + φ

_loglik(fit::StudentTFit)     = fit.loglik
_nparams(fit::StudentTFit)    = _anova_beta_lambda_np(fit) + 1        # + σ (ν fixed)

_loglik(fit::TruncPoissonFit)  = fit.loglik
_nparams(fit::TruncPoissonFit) = _anova_beta_lambda_np(fit)           # no dispersion

_loglik(fit::TruncNBFit)      = fit.loglik
_nparams(fit::TruncNBFit)     = _anova_beta_lambda_np(fit) + 1        # + r

_loglik(fit::ZIPFit)          = fit.loglik
_nparams(fit::ZIPFit)         = _anova_beta_lambda_np(fit) + 1        # + π

_loglik(fit::ZINBFit)         = fit.loglik
_nparams(fit::ZINBFit)        = _anova_beta_lambda_np(fit) + 2        # + r, π

_loglik(fit::ZIBinomFit)      = fit.loglik
_nparams(fit::ZIBinomFit)     = _anova_beta_lambda_np(fit) + 1        # + π

_loglik(fit::GenPoissonFit)   = fit.loglik
_nparams(fit::GenPoissonFit)  = _anova_beta_lambda_np(fit) + 1        # + α

_loglik(fit::CMPoissonFit)    = fit.loglik
_nparams(fit::CMPoissonFit)   = _anova_beta_lambda_np(fit) + 1        # + ν

# ---------------------------------------------------------------------------

"""
    lrt(reduced, full) -> NamedTuple

Likelihood-ratio test for two **nested** GLLVM fits (`reduced` ⊂ `full`). Returns
`(statistic, df, pvalue, loglik_reduced, loglik_full)`, with
`statistic = 2 (ℓ_full − ℓ_reduced)`, `df = nparams(full) − nparams(reduced)`, and
`pvalue = P(χ²_df ≥ statistic)`.

The caller is responsible for the models being genuinely nested and fit to the same
data; a warning is issued (and `pvalue = NaN` returned) if `full` does not have more
parameters than `reduced`, or if its log-likelihood is lower (a sign of
non-nesting or non-convergence). Free-parameter counts use the same convention as
[`aic`](@ref) / [`bic`](@ref) (loadings modulo the K(K−1)/2 rotational df).

```julia
m1 = fit_poisson_gllvm(Y; K = 1)
m2 = fit_poisson_gllvm(Y; K = 2)
lrt(m1, m2)              # is the second latent dimension supported?
```
"""
function lrt(reduced, full)
    k_r = _nparams(reduced); k_f = _nparams(full)
    ll_r = _loglik(reduced); ll_f = _loglik(full)
    df = k_f - k_r
    stat = 2 * (ll_f - ll_r)
    if df ≤ 0
        @warn "lrt: `full` does not have more free parameters than `reduced` " *
              "(Δdf = $df); check the model ordering / nesting"
    end
    if stat < -1e-6
        @warn "lrt: `full` log-likelihood ($(ll_f)) is below `reduced` ($(ll_r)); " *
              "check nesting and convergence"
    end
    pval = (df > 0 && isfinite(stat) && stat > 0) ? ccdf(Chisq(df), stat) : NaN
    return (statistic = stat, df = df, pvalue = pval,
            loglik_reduced = ll_r, loglik_full = ll_f)
end

"""
    anova(fits...) -> NamedTuple

Sequential likelihood-ratio tests across a chain of **nested** GLLVM fits supplied
in increasing order of complexity. Returns the column vectors
`(model, npar, loglik, df, statistic, pvalue)`; row `i` tests fit `i` against fit
`i − 1` (row 1 carries `NaN` test entries — there is nothing before it). Requires at
least two models. For non-nested comparison use [`aic`](@ref) / [`bic`](@ref).

```julia
anova(fit_poisson_gllvm(Y; K = 1),
      fit_poisson_gllvm(Y; K = 2),
      fit_poisson_gllvm(Y; K = 3))
```
"""
function anova(fits...)
    length(fits) ≥ 2 || throw(ArgumentError(
        "anova requires at least two fitted models (got $(length(fits)))"))
    m = length(fits)
    npar  = [_nparams(f) for f in fits]
    ll    = [_loglik(f) for f in fits]
    model = [string(nameof(typeof(f))) for f in fits]
    df   = fill(NaN, m)
    stat = fill(NaN, m)
    pval = fill(NaN, m)
    @inbounds for i in 2:m
        d = npar[i] - npar[i - 1]
        s = 2 * (ll[i] - ll[i - 1])
        df[i]   = d
        stat[i] = s
        pval[i] = (d > 0 && isfinite(s) && s > 0) ? ccdf(Chisq(d), s) : NaN
    end
    return (model = model, npar = npar, loglik = ll,
            df = df, statistic = stat, pvalue = pval)
end
