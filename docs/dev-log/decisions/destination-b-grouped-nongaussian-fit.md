# Destination B — grouped non-Gaussian Laplace fitter contract

Status: development candidate, now routed through public `fit_gllvm` and formula
interfaces. See `docs/src/grouped-models.md` and the public-route tests. This is
not an admitted R bridge contract, recovery result, or coverage claim.

## Symbolic contract

For traits by observations response `Y`, complete mean design `D`, selected
grouping terms `s`, and `i = trait + p * (observation - 1)`, the candidate is

```math
\eta = D\gamma + Wb, \qquad
W = [Z_1 \otimes L_1^* \; \cdots \; Z_S \otimes L_S^*], \qquad
b \sim N(0, I).
```

The conditional response is one common family over all rows: Poisson with log
link, Binomial with logit link and supplied trials, Beta with logit link and
precision `\phi`, or NB2 with log link and size `r`. For Beta/NB2, the outer
coordinates include `log_phi`/`log_r` and construct `\phi=exp(log_phi)` or
`r=exp(log_r)`. There is no Gaussian residual-scale coordinate in this model.
For Beta/NB2, `dispersion=:trait` is the default and packs one terminal
`log_phi[t]` or `log_r[t]` coordinate per trait. Its marker objects are expanded
trait-fast to the `vec(Y)` rows, so row `trait + p * (observation - 1)` uses
that trait's precision or size. `dispersion=:shared` is an explicit one-coordinate
subset that retains the scalar inner-kernel call. The inner contract therefore
has two deliberate paths: legacy scalar family marker for shared dispersion;
validated uniform-family vector of length `p*n` for trait dispersion. The
vector path must use its row family in every likelihood, score, Fisher,
observed-curvature, clamp, and domain calculation.

Poisson/Binomial accept the default `dispersion=:trait` as a no-op because they
have no dispersion coordinate; an explicit `:shared` may be rejected. Public
routing preserves the per-trait Beta/NB2 defaults and never silently coerces
them to the shared subset.

The fixed-parameter inner routine returns the joint Laplace approximation

```math
\tilde\ell(\theta) = \ell_c(y;\eta(\hat b),\delta)
  - \tfrac12\hat b'\hat b - \tfrac12\log|H_b(\hat b)|,
```

where `\delta` is absent for Poisson/Binomial and is `\phi` or `r` otherwise.
It has one global whitened `b`; terms may be shared or crossed through their
sparse incidence matrices. The outer negative objective is `-\tilde\ell` only
when the inner status is exactly `:ok` and converged. Any other status,
saturation, non-finite result, failed precision factorisation, or failed outer
finite-difference stencil is invalid objective information, never a substitute
finite likelihood.

Outer search begins value-only so an invalid neighbouring finite-difference
stencil cannot crash or contaminate a line search. When the resulting point has
an entirely valid central-difference gradient, a BFGS refinement is attempted;
otherwise the value-only endpoint remains non-converged. In every case, the
reported point-solver verdict still requires a finite observed-marginal
finite-difference gradient, so the fallback cannot manufacture convergence.

| Symbol | private coordinate/code | deterministic test | current evidence |
| --- | --- | --- | --- |
| `D\gamma` | `_trait_mean_design` / `_source_mean_design`, packed `gamma` | bounded Poisson fixed-effect fit | endpoint wiring only |
| `Z_s` | explicit `GroupingTerm` plus labels | p=2 crossed/independent design equality | exact sparse matrix equality |
| `L_s^*` | `latent`, `indep`, `dep`; optional unique diagonal factors | design equals `kron(Z,L*)` | exact sparse matrix equality |
| `b` | one concatenated sparse `W` | inner kernel status propagated | deterministic failure check |
| `\phi`, `r` | final `log_phi`/`log_r` coordinate | Beta/NB2 tiny fits | natural positive estimate only |
| `H_b` | fixed joint-Laplace kernel | non-`:ok` invalidates outer objective | kernel-owner focused check |

## Packing, intervals, and boundaries

The outer packing is

```text
[ gamma ; coordinates(term 1) ; ... ; coordinates(term S) ; log_dispersion? ]
```

in supplied term order. For Beta/NB2, `log_dispersion?` is `p` trait coordinates
by default or one coordinate only under explicit `dispersion=:shared`.
Grouping coordinates exactly reuse the private Gaussian
grouping packer: lower loading coordinates, then optional unique log-SDs;
`indep` uses diagonal log-SDs; `dep` uses a full lower loading. The natural
term covariance is `L*L' + diag(d)` as applicable. `indep` off-diagonals are
fixed zero and are retained in a covariance display but omitted from interval
targets.

`grouped_nongaussian_intervals` rebuilds the full observed marginal objective
with all nuisance coordinates. It only admits the retained response/incidences
from its fit provenance, and delegates observed finite-difference curvature to
the shared target helper. Point convergence is distinct from Hessian/interval
feasibility; no ridge, pseudo-inverse, profile endpoint, or AD claim is made.

Small fixed deterministic fits test execution and diagnostics, not recovery,
coverage, optimizer robustness, or family-wide performance. Those remain
required before any public capability claim.

## Predeclared bounded interior checks

Before executing the next local checks, the fixtures and targets are fixed as
follows. They are single deterministic diagnostics, not a recovery campaign.

| Check | seed/design | targets required available | purpose |
| --- | --- | --- | --- |
| Binomial interior | `MersenneTwister(202609071)`; 10 groups × 4 observations, 20 trials, p=1 independent common grouping | fixed intercept, group variance/SD | identifiable grouped binomial curvature |
| NB2 interior | `MersenneTwister(202609072)`; 10 groups × 4 observations, p=1 independent common grouping | fixed intercept, group variance/SD, NB2 size | identifiable grouped NB2 + dispersion curvature |
| trait-Beta interior | `MersenneTwister(202609073)`; 10 groups × 4 observations, p=2 independent common grouping, true precisions 8/16 | both Beta precisions plus all primary targets | trait-fast vector family and per-trait curvature |
| trait-NB2 boundary diagnostic | `StableRNG(202609091)`; 10 groups × 4 observations, p=2 independent common grouping, true sizes 5/12 | second NB2 size is deliberately unavailable; fit-level FD Hessian PD sign is a BLAS knife-edge | retained upper-size boundary diagnostic |
| trait-NB2 interior | separately initialized `StableRNG(202609091)`; same 10 groups × 4 observations and grouping, true sizes 5/3 | both NB2 sizes plus all primary targets | trait-fast vector family and per-trait curvature away from the upper-size boundary |
| all-four structure | fixed p=2, n=8 labels and factors for unit/unit_obs/cluster/cluster2 | exact sparse `W` equality | all selected sources remain one concatenated global design |
| objective bridge | fixed p=1 Poisson coordinates | exact equality to a separately constructed `joint_grouped_laplace_loglik` call | outer objective does not alter a successful inner result |

Each pilot has a two-minute local limit. There is no tolerance widening or
failure filtering: a non-available interval or non-`:ok` kernel status is a
reported diagnostic.

The predeclared Binomial interior fixture and all-four structural/Poisson
objective bridge passed. After the joint inner solver's fixed-parameter
roundoff repair, the unchanged predeclared NB2 fixture also has a converged,
positive-curvature point fit and available fixed-effect, group variance/SD, and
NB2-size intervals. The direct `log_r` forward-stencil reproducer is retained:
it guards the exact inner-solver behaviour that made this result possible.

This evidence is one deterministic interior diagnostic per family, not a
recovery or coverage result. Subsequent vector-family, outer-objective, and
public dispatch tests now exercise trait dispersion; this does not establish
frozen-reference paired qualification.

The original p=2 NB2 size-5/12 draw is retained rather than tuned away.  It
converged with an `:ok` inner mode but its second size ran to
`log_r[2] = 20.534712052952347` (`r[2] = 8.281559607055352e8`); the observed
finite-difference Hessian had a near-zero eigenvalue
`-3.745318692758868e-15` on macOS OpenBLAS; the same frozen `Y` can report a
barely positive least eigenvalue on Linux CI OpenBLAS Julia 1.10, so tests
assert finiteness of that eigenvalue rather than its sign.  Its marginal
interval coarse status is another knife-edge (`:partial` vs
`:invalid_curvature`); the invariant is that `nb2_size[2]` is never reported
`:available`.  The separately named
size-5/3 draw changes only the generating geometry, retains the design and
seed, and is the bounded interior diagnostic. Neither draw is recovery or
coverage evidence.

## Focused execution evidence

On 2026-09-07 the focused private test file passed 63/63 assertions in 14.1
seconds (19.2 seconds fresh-process wall time) using the resolved main project.
This includes the trait-Beta and separately named trait-NB2 interior fits with
available primary observed-marginal targets, the retained NB2 boundary
diagnostic, the p=2/n=3 trait-fast marker-order check, the independent
vector-family objective identity, the all-four-source sparse-design equality,
and the standalone Poisson objective's default no-dispersion normalization.
It does not establish parameter recovery, interval coverage, robustness beyond
these fixtures, a public fit route, or a general identification guarantee.
