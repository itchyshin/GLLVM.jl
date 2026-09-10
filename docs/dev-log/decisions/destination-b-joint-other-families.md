# Destination B — joint four-source non-Poisson fitted gates

Status: three separate deterministic integration gates for the public grouped
route. They extend the successful p=2/n=96 Poisson geometry, but no pooled
family verdict, recovery claim, coverage claim, or covariance-generalization
claim follows.

## Shared symbolic structure

For each family and traits `t=1,2`, observations `i=1,...,96`, generate four
independent source effects

```math
\eta_{ti}=a_t+U_{t,u_i}+O_{t,o_i}+C_{t,c_i}+D_{t,d_i},
```

where every source has covariance `s_j^2 I_2`. Fit all four through
`GroupingTerm(name; mode=:indep, common=true)`, so the fitted outer packing is
two trait means plus four common log-SDs (and, for Beta/NB2, two terminal
trait-specific dispersion coordinates). The labels are fixed: 12 units with
eight observations each; 48 globally nested, twice-replicated `unit_obs`
levels; eight within-unit-cycled crossed `cluster` levels; and eleven distinct
shifted-cycle crossed `cluster2` levels.

| Family | StableRNG seed | conditional response | `a` | source SDs `(U,O,C,D)` | dispersion/trials |
| --- | ---: | --- | --- | --- | --- |
| Binomial-logit | `202609076` | `Y ~ Binomial(20, logistic(eta))` | `(-0.30, 0.45)` | `(0.52, 0.40, 0.30, 0.25)` | 20 trials in every cell |
| Beta-logit | `202609077` | `Y ~ Beta(mu*phi_t, (1-mu)*phi_t)`, `mu=logistic(eta)` | `(-0.45, 0.25)` | `(0.36, 0.28, 0.22, 0.18)` | trait precisions `(12, 18)` |
| NB2-log | `202609078` | `Y ~ NB2(r_t, r_t/(r_t+exp(eta)))` | `(0.70, 1.00)` | `(0.38, 0.30, 0.24, 0.20)` | trait sizes `(1.5, 2.5)` |

Each family receives an independently initialized StableRNG and separately
drawn source matrices and responses. The NB2 sizes are deliberately well below
the near-Poisson limit. The96 observations were a small timing pilot:
twice-replicated nested levels do not guarantee source identification, as the
retained NB2 result demonstrates.

| Symbol | public fit representation | DGP draw | checked output | recorded truth |
| --- | --- | --- | --- | --- |
| `U,O,C,D` | four named `:indep, common=true` terms | independent normal source matrix | fitted `extract_Sigma` and named variance interval per source | common diagonal `s_j^2 I_2` |
| `a` | two fixed trait means | listed family-specific vector | fixed-effect interval status | listed, not recovery-scored |
| `phi_t` | default trait-specific Beta packing | `(12,18)` | `beta_precision[1:2]` interval status | yes |
| `r_t` | default trait-specific NB2 packing | `(1.5,2.5)` | `nb2_size[1:2]` interval status | yes |

## Predeclared execution and stop rule

For each family call public `fit_gllvm` with the fixed grouping, `iterations=250`
and `g_tol=1e-4`; then reconstruct observed marginal intervals from the
retained response and labels. Require, separately for every family: a finite,
converged, positive-curvature fit with `inner_status=:ok`; four finite positive
diagonal fitted covariance components; and `:available` finite ordered source
variance intervals. Beta/NB2 additionally require trait mode and both named
dispersion intervals available. The test logs elapsed fit-plus-interval time
and status per family; no family can borrow another family's pass.

Run Binomial first as the timing pilot. The fixed combined run has a two-minute
local limit in `/private/tmp/destination-b-quality-g8dtHV`; an overrun stops
the remaining families and reports the observed elapsed time. StableRNGs
absence is one explicit Broken skip and is not fitted evidence. Any first model
or interval failure stays as the fixed-seed receipt—there is no data, seed, or
tolerance search.

## Per-family first receipts

| Family | fit-plus-interval elapsed | fixed result | covariance/interval status |
| --- | ---: | --- | --- |
| Binomial-logit | 9.1443 s | 58/58 test assertions passed | all four fitted diagonal components positive; all retained source-variance intervals available |
| Beta-logit | 3.4930 s | 63/63 test assertions passed | all four fitted diagonal components positive; all retained source-variance and both trait-precision intervals available |
| NB2-log | 2.5377 s | 55/55 boundary-regression assertions passed; point fit converged, PD, inner `:ok` | `unit=0.1836049361`, `unit_obs=5.2744522e-9`, `cluster=3.7614612e-8`, `cluster2=0.0012942731`; unit and cluster2 variance intervals available, unit_obs and cluster intervals target-unavailable, both trait-size intervals available; overall interval status `:partial` |

The final combined observed fit-plus-interval time was about 15.2 seconds, below the
two-minute limit. The NB2 draw is retained as a source-scale boundary receipt:
the fixed DGP is not changed merely because two fitted components collapse.
The test asserts that exact partial-status pattern rather than mislabelling it
as a family-wide pass. These are three separate one-seed numerical diagnostics;
they do not establish recovery, coverage, or broad all-four-term NB2 interval
feasibility.
