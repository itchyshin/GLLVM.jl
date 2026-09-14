# Destination B B1 — Gaussian `unit_obs` diagonal alignment

**Status:** alignment contract and one retained paired fixture. Frozen R and
the registered Julia test now agree on one nested diagonal `unit_obs` fit; this
single pair cannot qualify B1, intervals, recovery, S3b, S4, dense `vcv`, FRK,
or any version-wide parity claim.

**Reference:** frozen `gllvmTMB` 0.7.0 at
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. The R engine remains read-only.

## Model

For trait \(t = 1,\ldots,p\), measurement observation \(i = 1,\ldots,n\),
within-unit group \(w(i)\), and parent unit \(u(i)\), the first admitted
shape is

\[
Y_{ti} = \beta_t + a_{t,w(i)} + \epsilon_{ti},\qquad
a_{t,w} \sim \mathcal N(0,\tau_t^2),\qquad
\epsilon_{ti} \sim \mathcal N(0,\sigma_\epsilon^2).
\]

Thus \(\Sigma_{\mathrm{unit\_obs}} =
\operatorname{diag}(\tau_1^2,\ldots,\tau_p^2)\). The initial fixture has
`p = 2`, 12 units, two `unit_obs` levels nested within every unit, and two
measurement columns per `unit_obs` level. Each \(a_{t,w}\) is consequently
identified by repeated measurements rather than being confounded by a
one-row-per-group observation-level random effect.

Current Julia deliberately accepts only this globally nested shape: one
`unit_obs` label must map to exactly one `unit` label. Frozen R also allows a
crossed design; that broader R behaviour is visibly out of scope here.

## Alignment table

| Symbol | Frozen R form | Julia form | Fixture / draw | Observable and boundary |
| --- | --- | --- | --- | --- |
| `beta_t` | `0 + trait` | default trait mean design | two finite trait intercepts | compare fitted fixed effects only in the same retained fixture |
| `a_{t,w}` | `indep(0 + trait | obs)` with `unit_obs = "obs"` | `GroupingTerm(:unit_obs; mode=:indep)` | one independent Normal draw per trait × nested `obs` | integrated random effect; trait covariance is diagonal |
| `u(i)` | `unit = "unit"` | `unit=unit_labels` | 12 parent labels | validation-only parent map; it does not add a `unit` random covariance |
| `w(i)` | `unit_obs = "obs"` | `unit_obs=obs_labels` | 24 globally unique nested labels, repeated twice | its incidence matrix supplies sharing |
| `sigma_eps` | Gaussian residual coordinate | final packed `log_sigma_eps` coordinate | positive shared residual SD | separate from `a` because every trait × `obs` cell has two observations |
| `Y` | long rows ordered `unit`, `obs`, repeat, trait | traits-by-observation matrix | deterministic 2 × 48 response | Julia `vec(Y)` must preserve trait-within-observation ordering |

The paired public calls are intentionally idiomatic rather than literal API
copies:

```r
gllvmTMB(
  value ~ 0 + trait + indep(0 + trait | obs),
  data = df, family = gaussian(), trait = "trait", unit = "unit",
  unit_obs = "obs", REML = FALSE,
  control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

```julia
fit_gllvm(Y; family=Normal(),
    grouping=[GroupingTerm(:unit_obs; mode=:indep)],
    unit=unit_labels, unit_obs=obs_labels)
```

`extract_Sigma(fit, level = "unit_obs", part = "total")$Sigma` is the R
covariance extractor. The raw R `Sigma_W` report field is intentionally not
the oracle for this diagonal route; its absence is expected.

## Executed discrimination control

The registered Julia check preserves every response and fixed coordinate, then
moves one measurement to the other `unit_obs` group **within its same parent
unit**. That keeps Julia's nesting contract valid while changing the incidence
partition. A global renaming would not be a valid wrong-map control.

## Evidence boundary

The retained 2026-09-10 receipt now evidences one frozen-R 0.7.0, same-data,
Gaussian, nested, diagonal `unit_obs` fit. At the R optimum and after an
independent Julia refit, it checks marginal likelihood, trait intercepts,
total diagonal W covariance, residual SD, and a valid changed-incidence
control. It does not admit crossed or low-rank `unit_obs`, intervals, recovery,
all B1 levels, a public formula bridge, S3b/S4, dense `vcv`, FRK, 0.7.1,
broad 0.7 parity, or Destination B completion.
