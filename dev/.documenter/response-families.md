
# Response families {#Response-families}

A GLLVM links its latent factors to the responses through a **response family** and a **link**. GLLVM.jl follows the Julia convention (as in GLM.jl): the family is a `Distributions.jl` distribution, chosen with the `family =` keyword to `fit_gllvm`.

## The unified entry point {#The-unified-entry-point}

```julia
using GLLVM, Distributions

# Gaussian responses (continuous) — exact closed-form marginal
fit_gllvm(Y;  family = Normal(),   K = 2)

# Binary / binomial responses — Laplace marginal
fit_gllvm(Yb; family = Binomial(), K = 2, link = LogitLink())
```


`fit_gllvm` dispatches on the family: `Normal()` uses the exact closed-form Gaussian marginal; `Binomial()` uses a Laplace approximation, because the latent integral is non-conjugate for non-Gaussian families.

## Links {#Links}

For the binomial family you can choose the link:

|                      Link |   `linkinv(η)` |                                 Use |
| -------------------------:| --------------:| -----------------------------------:|
| `LogitLink()` _(default)_ |       logistic | log-odds; the canonical binary link |
|            `ProbitLink()` |         `Φ(η)` |    latent-Gaussian threshold models |
|           `CLogLogLink()` | `1 − exp(−eη)` |  asymmetric; rare-event / occupancy |


```julia
fit_gllvm(Yb; family = Binomial(), K = 2, link = ProbitLink())
```


## Supported families {#Supported-families}

|               Family |      Status |    Marginal |                                                            Notes |
| --------------------:| -----------:| -----------:| ----------------------------------------------------------------:|
|           `Normal()` | ✅ available | closed form |                        continuous responses; the original engine |
|         `Binomial()` | ✅ available |     Laplace | binary (Bernoulli) and binomial counts; logit / probit / cloglog |
|          `Poisson()` |   ⏳ planned |     Laplace |                                                           counts |
| `NegativeBinomial()` |   ⏳ planned |     Laplace |                                             overdispersed counts |
|              ordinal |   ⏳ planned |     Laplace |                                               ordered categories |
|             `Beta()` |   ⏳ planned |     Laplace |                                                      proportions |


Calling `fit_gllvm` with an unimplemented family raises a clear error listing what is currently available.

## Binomial trials {#Binomial-trials}

For binomial _counts_ (not just binary), pass the trial counts `N` — a `p×n` integer matrix; the default is all-ones (Bernoulli):

```julia
fit_gllvm(Y; family = Binomial(), K = 2, N = trials)
```


See also: [Get started](/quickstart) · [Covariance and correlation](/covariance-correlation) · [Reference](/api).
