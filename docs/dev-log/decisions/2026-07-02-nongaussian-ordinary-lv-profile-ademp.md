# Ordinary non-Gaussian LV selected-entry profile ADEMP gate

Date: 2026-07-02
Status: Gate 0 written; local Gate 1 canaries added for Poisson, Binomial logit, NB2, and Gamma
Scope: ordinary one-part non-Gaussian `X_lv` fits in GLLVM.jl only

## Decision

Start the non-Gaussian LV inference arc with ordinary one-part `X_lv` models,
not source-specific structural models. The first defensible target is
selected-entry profile-LR for the rotation-stable trait effect
`B_lv = Lambda * alpha_lv'` in admitted ordinary non-Gaussian fits. The first
local route canaries are Poisson, Binomial logit, NB2, and Gamma.

This gate does not expose or imply:

- source-specific `phylo_latent(..., lv = ~ env)`, `spatial_latent(..., lv =
  ~ env)`, animal, or kernel LV support;
- R bridge profile/bootstrap transport;
- R-vs-Julia parity;
- coverage calibration;
- mixed-family `X_lv`, masks, missing responses, or CIs;
- any `unique=` Julia parity work.

The concurrent `unique=` lane remains R/TMB-first and joins only after its R
contract is green and a separate parity gate is opened.

## ADEMP design

This note follows ADEMP (Morris, White, and Crowther 2019) and the Williams et
al. (2024) transparent simulation-reporting checklist.

### A - Aims

Primary aim: determine whether the public ordinary non-Gaussian selected-entry
profile route for `B_lv` can refit constrained one-part Laplace likelihoods and
return finite LR-inverted endpoints around known DGP truths.

Secondary aim: establish the smallest local evidence gate that justifies later
Totoro diagnostics for ordinary one-part non-Gaussian `B_lv`, while keeping
structural-source and bridge claims blocked.

### D - Data-generating mechanism

Single ordinary latent score block:

```text
X_lv[s, 1] fixed on [-1, 1], s = 1,...,n
z_s = X_lv[s, 1] * alpha[1, 1] + epsilon_s
epsilon_s ~ Normal(0, 1)
eta[t, s] = beta[t] + Lambda[t, 1] * z_s
Y[t, s] follows the one-part family likelihood for the gate family
```

Poisson Gate 1 local canary uses:

```text
p = 2 traits
n = 45 sites
K = 1 latent axis
q_lv = 1 predictor
beta = log([6.0, 4.5])
Lambda = [0.55, -0.42]'
alpha = [0.65]
selected profile entry = vec(B_lv)[1] = B_lv[1, 1]
truth = 0.3575
```

Binomial logit Gate 1 local canary uses:

```text
p = 2 traits
n = 60 sites
K = 1 latent axis
q_lv = 1 predictor
N = 30 trials per cell
beta = [-0.35, 0.25]
Lambda = [0.45, -0.35]'
alpha = [0.55]
selected profile entry = vec(B_lv)[1] = B_lv[1, 1]
truth = 0.2475
```

NB2 Gate 1 local canary uses:

```text
p = 4 traits
n = 45 sites
K = 1 latent axis
q_lv = 1 predictor
beta = log([8.0, 6.0, 7.0, 5.0])
Lambda = [-0.216, 0.232, -0.248, 0.264]'
alpha = [0.35]
NB2 r = 1.5
selected profile entry = vec(B_lv)[1] = B_lv[1, 1]
truth = -0.0756
```

Gamma Gate 1 local canary uses:

```text
p = 4 traits
n = 45 sites
K = 1 latent axis
q_lv = 1 predictor
beta = log([3.0, 2.4, 2.7, 2.1])
Lambda = [-0.216, 0.232, -0.248, 0.264]'
alpha = [0.35]
Gamma shape = 2.5
selected profile entry = vec(B_lv)[1] = B_lv[1, 1]
truth = -0.0756
```

Later diagnostic cells may vary `p`, `n`, `K`, signal strength, and selected
entry position, but only after the local canary is green.

### E - Estimands

The estimand is the ordinary trait/loading effect:

```text
B_lv = Lambda * alpha_lv'
```

For selected entry `idx`, profile-LR inverts:

```text
D(c) = 2 * (NLL_constrained(B_lv[idx] = c) - NLL_hat)
```

against the chi-square(1) cutoff. `alpha_lv` remains an axis/access-effect
component and is not the interval target.

### M - Methods

Gate 1 method:

- fit the ordinary one-part `X_lv` model;
- call `confint_lv_effects(...; method = :profile, profile_indices = [1])`;
- use bounded profile controls so this stays a local canary, not a compute
  campaign;
- record finite endpoints, MLE bracketing, and truth inclusion.

Bootstrap is retained only as a secondary diagnostic for later gates. Wald
intervals remain useful comparator output, not the primary uncertainty engine.

### P - Performance measures

Gate 1 pass/fail quantities:

- fit returns without error;
- selected profile route returns `method = :profile`;
- endpoint values are finite;
- `lower < estimate < upper`;
- known DGP truth lies inside the selected-entry interval;
- runtime is local-test scale.

Coverage calibration is not claimed from one canary. Gate 2 must predeclare its
denominator and report coverage with Monte Carlo standard error
`sqrt(p * (1 - p) / n_reps)`.

## Gate ladder

- Gate 0: this ADEMP note plus public route identification.
- Gate 1: local Poisson, Binomial logit, NB2, and Gamma selected-entry canaries in
  `test/test_lv_ci.jl`.
- Gate 2: Totoro diagnostic only after Gate 1 is green, with host and
  denominator recorded separately from DRAC.
- Gate 3: DRAC claim evidence only after Gate 2 is stable, with seed-matched
  denominator and MCSE.

## Williams self-audit

| Item | Status | Evidence |
| --- | --- | --- |
| 1. Aims | covered | Aims section names primary and secondary aims. |
| 2. DGP | covered | DGP math and Poisson/Binomial/NB2/Gamma Gate 1 constants are explicit. |
| 3. Estimands | covered | `B_lv` and selected-entry LR target are defined. |
| 4. Methods | covered | One-part fit and selected-entry profile route are named. |
| 5. Performance | covered | Gate 1 pass/fail quantities and MCSE formula are named. |
| 6. Software | pending | Exact command recorded in check-log after the test run. |
| 7. Code availability | covered locally | Test lives in `test/test_lv_ci.jl`. |
| 8. Reproducibility | covered locally | Fixed RNG seeds `20260702`, `20260703`, `20260711`, and `20260722` in the canaries. |
| 9. Applied example | not applicable | This is a method-route gate, not a data analysis. |
| 10. Results | pending | Filled by check-log and after-task report after verification. |
| 11. MCSE | covered for later gates | Formula and denominator rule are explicit. |

## Council notes

- Ada: keep this ordinary and narrow; no source-specific grammar.
- Fisher: profile-LR is the main uncertainty canary; bootstrap is secondary.
- Curie: one canary is route evidence only; coverage needs Gate 2/3.
- Hopper: native Julia profile does not imply R bridge profile transport.
- Grace: Totoro may be diagnostic later; DRAC is claim evidence; do not mix
  denominators.
- Rose: block "partial support", "ready to expose", and non-Gaussian
  inheritance from Gaussian structural evidence.
- Gauss: NB2 tiny cells can collapse toward the Poisson boundary, so the local
  canary includes a loose fitted-`r` guard and uses bounded profile controls.
- Curie: Gamma uses the same selected-entry route but needs its own positive
  continuous likelihood proof; the local canary includes a loose fitted-shape
  guard.
