# Tweedie power contracts

For a Tweedie response, GLLVM.jl uses

```math
\operatorname{Var}(Y_{ts})=\phi_{g(t)}\mu_{ts}^{p_t},\qquad 1 < p_t < 2,
```

with a log link and the compound Poisson-Gamma likelihood. The dispersion group
and the power group describe different parameters: `group` selects the
dispersion `φ[group[t]]`, while the power controls below select `p_t`.

`fit_tweedie_gllvm_grouped` has three explicit model contracts.

| Request | Model |
| --- | --- |
| `power = 1.5` | a fixed common power; it contributes no estimated degrees of freedom |
| `power = nothing, power_group = :shared` | one estimated power shared by all species; this is the historical grouped Julia model |
| `power = nothing, power_group = :species` | one estimated power for each species; this matches the frozen gllvmTMB default parameterisation |

`power_group` must be `:shared` or `:species`, even when `power` is fixed.
This prevents a misspelled control from silently changing or obscuring the
model. Each estimated power uses an unconstrained coordinate mapped to `(1,2)`;
fits at the numerical endpoints are reported as unconverged.

For a fixed common power, use the same `power` on both engines when comparing
likelihoods. A shared estimated-power result and a per-species estimated-power
result are different models and must not be used as substitutes for each other.
The per-species route returns `TweediePerTraitPowerFit`, whose `power` field is
a length-`p` vector. The fixed and shared routes return `TweedieGroupedFit`;
its parameter count records whether power was fixed, rather than inferring this
from its numerical value.

Missing response cells can be passed with `mask`; they are excluded from the
likelihood. Offsets remain additive on the log-mean scale. Use the same mask,
offset, dispersion grouping, and `hessian` mode when comparing two fits.
