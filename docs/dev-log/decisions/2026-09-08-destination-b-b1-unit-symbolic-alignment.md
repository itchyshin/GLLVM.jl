# Destination B B1 — Gaussian `unit` fixed-coordinate alignment

**Status:** implementation contract and fixed-coordinate regression target.
It is not fitted R--Julia parity, interval evidence, recovery evidence, public
bridge admission, or a qualified B1 capability row.

**Reference:** frozen `gllvmTMB` 0.7.0 at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. The R engine is read-only.

## Model

For trait `t = 1,\ldots,p`, observation `i = 1,\ldots,n`, and grouping
partition `g(i)`, the aligned one-factor model is

\[
Y_{ti} = \beta_t + \lambda_t z_{g(i)} + \epsilon_{ti},\qquad
z_g \sim \mathcal N(0,1),\quad
\epsilon_{ti} \sim \mathcal N(0,\sigma_\epsilon^2).
\]

Thus the only `unit` trait covariance is

\[
\Sigma_{\mathrm{unit}} = \Lambda\Lambda^\mathsf T,
\]

with no `Psi`/unique companion, and the observation covariance in Julia's
column-major `vec(Y)` order is

\[
V_{(t,i),(u,j)} =
  \mathbb{1}\{g(i)=g(j)\}(\Lambda\Lambda^\mathsf T)_{tu} +
  \mathbb{1}\{i=j,\ t=u\}\sigma_\epsilon^2.
\]

The source-level relation is visible in frozen R at `src/gllvmTMB.cpp`
lines 1506--1525 (`Sigma_B = Lambda_B Lambda_B^T`) and 2551--2569 (the
site-selected latent score), with a scalar Gaussian residual at 2703--2719.

## Alignment table

| Symbol | Frozen R form | Julia form | Fixed fixture / draw | Observable and boundary |
| --- | --- | --- | --- | --- |
| `beta` | `0 + trait` | default trait mean design | supplied finite trait intercepts | packed first; fixed-coordinate NLL only, not coefficient recovery |
| `Lambda` | `latent(0 + trait | site, d = 1, unique = FALSE)` | `GroupingTerm(:unit; mode=:latent, rank=1, unique=false)` | lower-triangular rank-one loading | compare `Lambda Lambda'`; never signed loading coordinates |
| `z_g` | one latent score per repeated `site`/`unit` level | one column per group in sparse unit incidence | integrated standard-Normal factor, not estimated target | `site_species` retains replicate observations; the unit partition determines sharing |
| `sigma_eps` | Gaussian `exp(log_sigma_eps)` | final packed `log_sigma_eps` coordinate | positive scalar residual SD | same-observation, same-trait diagonal only |
| `Y` | long rows with `trait_id`, repeated `site_id`, and distinct `site_species_id` | traits-by-observations matrix | deterministic `p=2, n=8` fixture | Julia `vec(Y)` is trait-within-observation; R orders site, replicate, then trait |

The public calls are deliberately idiomatic rather than textually identical:

```r
gllvmTMB(
  value ~ 0 + trait + latent(0 + trait | site, d = 1, unique = FALSE),
  data = df, family = gaussian(), trait = "trait", unit = "site",
  REML = FALSE, control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

```julia
fit_gllvm(Y; family=Normal(),
    grouping=[GroupingTerm(:unit; mode=:latent, rank=1, unique=false)],
    unit=site_labels)
```

R's `unit="site"` selects the repeated between-unit grouping column; a
distinct `site_species` (or explicitly supplied `unit_obs`) identifies the
replicate observation within a site without adding a second fitted covariance
term. Julia's `unit=site_labels` receives the corresponding aligned
observation vector. The source-alignment fixture has four sites, two replicate
observations per site, and two traits: its Julia labels are
`[:a, :a, :b, :b, :c, :c, :d, :d]`. Equal partitions, rather than literal
label names or R's factor integer codes, are the contract. Frozen R documents
this separation at `R/gllvmTMB.R` lines 77--95 and 114--124, and constructs
separate site and site-species dimensions at `R/fit-multi.R` lines 2558--2567.

## Fixed-coordinate oracle and wrong-map control

The regression supplies `beta`, a nonzero rank-one `Lambda`, a positive
`sigma_eps`, repeated unit labels, and the packed Julia coordinates
`[beta; pack_lambda(Lambda); log(sigma_eps)]`. It independently forms dense
`V`, evaluates the Gaussian negative log likelihood by dense Cholesky, and
compares that value against the sparse grouped objective at the same
coordinates.

Its discrimination control changes one observation's membership so that the
partition changes; the independently assembled and grouped-objective NLLs
must both differ from the correct-partition value. A bijective rename of every
group is not a wrong-map control and is expected to leave the model invariant.

This particular regression uses repeated labels so its changed-membership
control exercises sharing across observation columns. Repetition is not a
general identifiability requirement for a rank-one two-trait covariance plus a
scalar residual: away from degeneracy, the residual is the smallest eigenvalue
of the within-observation covariance. `unique=false` is nevertheless
deliberate: for `p=2, rank=1`, adding trait-specific unit unique variances
would overparameterise the three-coordinate symmetric unit covariance.

## Evidence boundary

This contract makes a source-attested fixed-coordinate identity test possible.
It does **not** establish optimizer agreement, a fitted R--Julia likelihood
comparison, parameter recovery, valid confidence intervals, non-Gaussian
grouping, `unit_obs`/`cluster`/`cluster2`, S3b/S4, dense `vcv`, FRK, 0.7.1
parity, or Destination B completion. A frozen-R receipt records the R side;
it does not by itself upgrade any of those boundaries.
