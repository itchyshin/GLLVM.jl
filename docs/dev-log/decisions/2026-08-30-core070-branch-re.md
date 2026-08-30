# A4 branch-RE numerical repair

## Decision

Treat a variance trial that cannot be represented in the sparse Woodbury
calculation as an infinite profile negative log-likelihood. Do not add a
numerical ridge to the branch-increment precision.

## Basis

For finite positive `σ²`, `σ²_eps`, and branch lengths, the precision is

`Λ = diag(1 / (σ² * ell)) + (1 / σ²_eps) * Z'Z`.

It is positive definite because the diagonal first term is positive definite
and the Gram term is positive semidefinite. The CI failure therefore does not,
by itself, show a mathematical loss of positive definiteness. On Totoro Julia
1.12.6, the direct underflow trial `σ²_eps = 1e-320` produced a non-finite
likelihood under the old code, which establishes an unsafe numerical state.
The historical Julia 1.12.7 CI instead reported `PosDefException` during the
original Gate 3 fixture, but its exact optimiser trial was not traced. That
version-specific failure remains an unresolved reproduction and must not be
attributed to one mechanism.

The repair rejects unsafe trials with `Inf, NaN`, and factors
`Λscaled = Λ / lambda_scale`, where `lambda_scale` is the largest stored
magnitude. This is an exact positive scalar rescaling. The Woodbury solve and
log determinant apply the inverse scale and `E * log(lambda_scale)` exactly,
so the statistical model is unchanged. Its solve forms the posterior branch
mean before subtracting from the right-hand side; expanding the same identity
into two separately scaled `σ²_eps⁻¹` terms destroys the residual at small
observation variance. The profile quadratic is formed as `r' Σ⁻¹ y` and falls
back to `r' Σ⁻¹ r` if roundoff makes it negative. Since the intercept is
profiled, the response is centred before the sparse solves and the mean is
added back to the reported intercept; this exact translation removes a large
constant before the Woodbury residual arithmetic.

For `E > p`, the path-incidence matrix has a non-trivial nullspace. On that
subspace the precision is at most `max(W)`, while its largest eigenvalue is at
least the assembled largest entry. The code rejects a trial when the resulting
lower bound `lambda_scale / max(W) = lambda_scale * σ² * min(ell)` exceeds
`1 / sqrt(eps(Float64))`. This is a conditioning rejection, kept distinct from
a non-finite trial; it does not alter `Λ` or claim a successful fit.

## Boundaries

This does not establish that every finite but ill-conditioned variance point
is estimable, nor does it certify the branch-RE fitter as healthy outside the
fixed tests. A finite CHOLMOD factorization failure is recorded separately as
a conditioning rejection and returns an infinite objective; it is never a
successful fit. The original Gate 3 fixture and its thresholds remain
unchanged.
