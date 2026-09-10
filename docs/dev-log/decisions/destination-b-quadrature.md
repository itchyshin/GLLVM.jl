# Destination B scalar-quadrature anchors

**Status:** test-only numerical oracle for the grouped non-Gaussian Laplace
kernel; it is neither a fitter nor a recovery claim.

## Fixed contract

The fixture is deliberately one-dimensional. Each of its eight observations
has the same random-effect column, `W = ones(8, 1)`, so that they genuinely
share the *single* latent effect `b ~ Normal(0, 1)`. `X = ones(8, 1)` and the
listed intercept is held fixed. Thus the oracle is

```
log integral prod_i p(y_i | beta + b) phi(b) db.
```

It is evaluated with `QuadGK.quadgk` on `(-Inf, Inf)`, after subtracting the
fixed value of the log integrand at `b = 0` for numerical scaling. A
machine-safe `|eta| <= 30` constructor band evaluates the negligible
standard-Normal far tail as zero, avoiding invalid distribution parameters
after floating-point link saturation. Conditional densities inside that band
use public `Distributions` constructors, not GLLVM's private GLM helpers:

| label | marker and link | fixed parameters | beta | response / trials |
| --- | --- | --- | ---: | --- |
| `:poisson` | `Poisson()`, log | — | `log(3)` | `2, 4, 3, 5, 2, 3, 4, 3` |
| `:binomial` | `Binomial()`, logit | 8 trials each | `-0.2` | `3, 4, 5, 2, 4, 3, 4, 5` |
| `:beta` | `Beta(20, 1)`, logit | precision `phi=20` | `0.15` | `0.46, 0.55, 0.52, 0.49, 0.58, 0.50, 0.53, 0.47` |
| `:nb2` | `NegativeBinomial(8, .5)`, log | size `r=8` | `log(3)` | `2, 5, 3, 4, 2, 3, 5, 4` |

The rows are interior by construction: means are away from their link bounds,
all beta responses are strictly in `(0, 1)`, and Binomial counts lie in their
eight-trial support. These are the declared regression fixtures; do not tune
them, or the tolerance, in response to a failed assertion.

## What the two checks mean

For every label a no-random-effect (`W` with zero columns) check compares the
kernel to the exact sum of public conditional `logpdf`s at `beta` to `1e-12`.
That is an **implementation mismatch** check: it catches a lost response,
prior, or likelihood constant and admits no Laplace error.

The repeated-effect case compares the kernel's observed-curvature Laplace
objective with the scalar integral. The predeclared error bound is `0.01`
nats for each fixed fixture. That is an **approximation-error** check, not an
excuse to disguise a normalization mismatch. A non-`:ok` kernel diagnostic,
nonconvergence, or nonfinite quadrature value fails before that comparison.

The test requires the isolated quality environment's direct `QuadGK`
dependency. A bare core environment may skip loading this optional oracle;
such a skip is not evidence that the quadrature gate passed.
