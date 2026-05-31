# Response families + link functions.
#
# Response families reuse Distributions.jl distribution types as markers — the
# GLM.jl convention: `family = Normal()` (Gaussian, the default) or `Binomial()`
# (binary), `Poisson()`, … The marginal log-likelihood dispatches on the family
# type via Julia multiple dispatch (Gaussian → closed-form marginal;
# non-Gaussian → Laplace), with no hardcoded family switch. GLLVM defines only
# the link types below — Distributions provides the distributions, not the links.

abstract type Link end
struct LogitLink    <: Link end
struct ProbitLink   <: Link end
struct CLogLogLink  <: Link end
struct IdentityLink <: Link end
struct LogLink      <: Link end

"""
    linkinv(link, η) -> μ

Inverse link `g⁻¹`: map the linear predictor `η` to the mean `μ`.
"""
linkinv(::LogitLink, η)    = inv(one(η) + exp(-η))
linkinv(::ProbitLink, η)   = cdf(Normal(), η)
linkinv(::CLogLogLink, η)  = -expm1(-exp(η))
linkinv(::IdentityLink, η) = η
linkinv(::LogLink, η)      = exp(η)

"""
    mu_eta(link, η) -> dμ/dη

Derivative of the mean with respect to the linear predictor (numerically safe
at large |η|).
"""
mu_eta(::LogitLink, η)    = (e = exp(-abs(η)); e / (one(η) + e)^2)
mu_eta(::ProbitLink, η)   = pdf(Normal(), η)
mu_eta(::CLogLogLink, η)  = exp(η - exp(η))
mu_eta(::IdentityLink, η) = one(η)
mu_eta(::LogLink, η)      = exp(η)

"""
    linkfun(link, μ) -> η

Link `g`: map the mean `μ` to the linear predictor `η` (used for initialisation).
"""
linkfun(::LogitLink, μ)    = log(μ / (one(μ) - μ))
linkfun(::ProbitLink, μ)   = quantile(Normal(), μ)
linkfun(::CLogLogLink, μ)  = log(-log1p(-μ))
linkfun(::IdentityLink, μ) = μ
linkfun(::LogLink, μ)      = log(μ)

"""
    default_link(family) -> Link

Canonical link for a response family: identity for `Normal`, logit for
`Binomial`, log for `Poisson`.
"""
default_link(::Normal)   = IdentityLink()
default_link(::Binomial) = LogitLink()
default_link(::Poisson)  = LogLink()
