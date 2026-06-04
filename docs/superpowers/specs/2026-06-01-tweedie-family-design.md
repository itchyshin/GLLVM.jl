# Tweedie family for GLLVM.jl — design spec

- **Status: SPEC ONLY — not implemented.** No `src/` code is touched. Design
  analysis + slice plan with verifiable goals, so the build is done *with* tests
  (the rest of the family stack was validated by running; this spec exists so
  Tweedie is too, rather than shipped blind).
- Date: 2026-06-01
- Scope: add the **Tweedie** exponential-dispersion family (power index
  `1 < p < 2`, the compound Poisson–Gamma case) to the non-Gaussian Laplace
  stack — the standard distribution for **non-negative data with exact zeros and
  a positive continuous part** (biomass, CPUE, % cover, abundance), an alternative
  to the Delta / Hurdle two-part families already in the package.

---

## 0. TL;DR / verdict

Tweedie slots onto the **existing scalar-μ Laplace core** (`src/families/laplace.jl`)
like any other GLM family: it needs only the three hooks `_glm_score`,
`_glm_weight`, `_glm_logpdf` dispatched on a `Tweedie` marker, plus a fitter that
jointly estimates the dispersion `φ` (and optionally the power `p`). **The score
and Fisher weight are simple closed forms** (the EDM unit-variance function
`V(μ)=μ^p`); the **only hard part is the log-density** `log f(y; μ, φ, p)`, whose
normalising term has no elementary form for `1<p<2` and must be evaluated by the
**Dunn & Smyth (2005) infinite series** (exact, slower) or the **saddlepoint
approximation** (fast, approximate). That density evaluation is the single piece
that needs careful numerical work and validation against R's `tweedie` package.

**Recommendation:** ship `p` **fixed** (user-supplied, default `p=1.5`) first —
this makes Tweedie a drop-in scalar-μ family reusing everything — then add **`p`
estimation** (profile over a grid, the `tweedie::tweedie.profile` pattern) as a
follow-on. Estimating `p` inside the same L-BFGS as `β,Λ,φ` is ill-conditioned
and not recommended for v1.

---

## 1. Why Tweedie, and where it sits

The Tweedie EDM with `1<p<2` is the compound Poisson–Gamma: `N ~ Poisson(λ)`
"arrivals", each an independent `Gamma` jump, total `y = Σ_{i=1}^N G_i`. So
`P(y=0) = e^{-λ} > 0` (exact zeros) and `y>0` is continuous. This is *the*
canonical model for semicontinuous ecological response (catch rates, biomass,
cover), and is the main alternative to the package's existing two-part families:

| Model | Zero mechanism | Positive part | Params |
|---|---|---|---|
| Delta-lognormal / Delta-Gamma | separate Bernoulli `π` | lognormal / Gamma | `βz, βc, σ`/`α` |
| Hurdle-Poisson / NB | separate Bernoulli `π` | zero-truncated count | `βz, βc[, r]` |
| **Tweedie** | **single `μ`** drives both zero prob and positive mean | Gamma jumps | `β, φ, p` |

The Tweedie's appeal is parsimony: **one linear predictor** `η=log μ` controls
both the probability of zero and the positive mean (they are not separately
parameterised), which is often what an ecologist wants and is exactly
`gllvmTMB`/`gllvm`'s `family = "tweedie"`. It is therefore a genuine parity item,
not a duplicate of the two-part families.

**Mean / variance:** `E[y]=μ`, `Var[y]=φ μ^p`. Link: `log` (so `μ=exp(η)`),
matching the count/positive families. Boundaries: `p→1⁺` → (over-dispersed)
Poisson-type; `p→2⁻` → Gamma. These limits are the cross-checks (§5).

---

## 2. Model and the Laplace wiring

Per species `t`, site `s`: `η_{ts} = β_t + (Λ z_s)_t`, `μ=exp(η)`,
`y_{ts} ~ Tweedie(μ, φ, p)`, `z_s ~ N(0,I_K)` — identical latent structure to the
other families. The marginal is the existing per-site Laplace
(`laplace_loglik_site`); Tweedie only supplies the three family hooks.

### 2.1 Score and Fisher weight (closed form — the easy part)

For an EDM with unit variance function `V(μ)=μ^p` and dispersion `φ`, log link
(`dμ/dη = μ`):

```
s = ∂ℓ/∂η = (y − μ) / (φ V(μ)) · dμ/dη = (y − μ) / (φ μ^{p-1})
W = (dμ/dη)² / (φ V(μ))            = μ^{2−p} / φ           (Fisher info wrt η, ≥ 0)
```

So `_glm_score(::Tweedie, μ, n, me, y) = (y - μ) * me / (φ * μ^p)` and
`_glm_weight(::Tweedie, μ, n, me) = me^2 / (φ * μ^p)` (with `me = μ` for the log
link these reduce to the boxed forms). **These need no series** — the mode-finder
(`_laplace_mode`) and the `logdet(Λ'WΛ+I)` term are therefore exactly as cheap as
for Gamma. `φ` and `p` ride in the `Tweedie(φ, p)` marker (only those fields read),
mirroring how NB carries `r` and Beta carries `φ`.

### 2.2 The log-density (the hard part)

`_glm_logpdf(::Tweedie, μ, n, y)` must return `log f(y; μ, φ, p)`. The density is

```
y = 0:  f = exp(−μ^{2−p} / (φ (2−p)))                       (closed form!)
y > 0:  f = a(y, φ, p) · exp( (1/φ)[ y μ^{1−p}/(1−p) − μ^{2−p}/(2−p) ] )
        a(y, φ, p) = (1/y) Σ_{j=1}^∞ W_j,   the Dunn–Smyth series
```

The bracketed term is the EDM "θy − κ(θ)" part (elementary). **Only `a(y,φ,p)` —
the normaliser — needs the series.** Note the `y=0` density is closed-form, so the
zero-inflation behaviour is exact and cheap; the series is only for `y>0`.

Two evaluation strategies (implement both; pick by accuracy/speed):

1. **Exact series (Dunn & Smyth 2005).** `log a = log Σ_j W_j` with
   `log W_j = j α log( (p-1)^{α}/( (2-p) y^{α} φ^{1-α} ) )... ` (the standard form;
   `α=(2-p)/(1-p)`). Sum is sharply peaked; evaluate in log-space with the
   **log-sum-exp** trick around the peak index `j*` (locate `j*` by the continuous
   approximation, sum outward until terms drop below machine-eps of the max). This
   is `dtweedie.series` in R's `tweedie`. Cost: O(#terms) per observation, #terms
   small (tens) for typical `φ, p`, growing as `φ→0` or `y` large.

2. **Saddlepoint approximation (Dunn & Smyth 2008).** `log f ≈ −½ log(2π φ y^p)
   − d(y,μ)/(2φ)` with the Tweedie deviance `d`. `dtweedie.saddle` in R. O(1) per
   obs, no series; accuracy degrades for very small `y` or `φ`. Good as the default
   for large problems and as a cross-check on the series.

**Design choice:** default to the **series** (exact) with a saddlepoint fallback
when the series is slow/ill-conditioned (a `method = :series | :saddle | :auto`
keyword on the fitter). The marginal optimiser only needs `logf` at the mode, so
the series cost is `p_species × n_sites` evaluations per L-BFGS step — acceptable
at the package's target sizes; gate to saddlepoint above a size threshold.

### 2.3 Why the series doesn't block the latent integral

The series term `a(y,φ,p)` depends on `y, φ, p` but **not on `μ`** (hence not on
`β, Λ, z`). So:
- the inner Laplace **mode-finder and `logdet`** never touch the series (they use
  `s, W` only — §2.1);
- the series enters only the **value** `ℓ(ẑ)` and therefore only the estimation of
  `φ` (and `p`). With `p, φ` fixed it is an additive constant in the latent
  integral. This cleanly isolates the delicate numerics to one scalar term.

---

## 3. Parameterisation and fitting

- **`p` fixed (v1 default).** User passes `power = 1.5` (or per the data). Then the
  param vector is `[β; pack_lambda(Λ); log φ]` — *identical shape to the Gamma/Beta
  fitters*, so `fit_tweedie_gllvm` is a near-copy of `fit_gamma_gllvm` with the
  Tweedie marginal. Lowest risk; ship first.
- **`p` estimated (v2).** Profile the marginal over a grid `p ∈ {1.1, 1.2, …, 1.9}`
  (the `tweedie.profile` approach), refitting `(β,Λ,φ)` at each and taking the
  argmax; optionally a 1-D golden-section refine. Do **not** fold `p` into the
  joint L-BFGS — the likelihood in `p` is flat/ridged and the series derivative
  wrt `p` is delicate. Profiling is what R's `tweedie` does and is robust.
- **Dispersion `φ`:** estimated jointly on `log φ`, like NB `r` / Beta `φ`.
- **Warm start:** `β0 =` log of (mean + small) per species; `Λ0 =` SVD of
  link-residuals (as the other families); `φ0` from a method-of-moments on the
  positives (`Var/μ^p`); `p0 = 1.5`.

`TweedieFit` carries `β, Λ, φ, p, link, loglik, converged, iterations`. Post-fit:
`predict` (`:link`→η, `:response`→μ, `:prob0`→`exp(−μ^{2−p}/(φ(2−p)))` the zero
probability), Dunn–Smyth residuals via the Tweedie CDF (R `ptweedie`), `aic`/`bic`,
`getLV`. CIs slot into `confint_family.jl` exactly like Gamma (Wald/profile/
bootstrap) — add `TweedieFit` to `_FamilyFit`, term `phi` (+`p` if estimated).

---

## 4. Code grounding (reuse, don't reinvent)

- Family hooks pattern: `src/families/gamma.jl` is the closest sibling
  (positive continuous, log link, one dispersion). Copy its structure; swap the
  variance function `μ²/α → φ μ^p` and the logpdf.
- Core: `src/families/laplace.jl` (`_laplace_mode`, `laplace_loglik_site`,
  `marginal_loglik_laplace`) is reused **verbatim** via dispatch — no core edit.
- Covariates: add `_cov_default_link(::Tweedie)=LogLink()`,
  `_cov_has_disp(::Tweedie)=true`, `_cov_family(::Tweedie,d)=Tweedie(d, p)`,
  `_cov_sample(::Tweedie, …)` (simulate via the compound Poisson–Gamma:
  `N~Poisson(λ)`, `y=Σ Gamma`, with `λ=μ^{2−p}/(φ(2−p))`, jump shape `−α`, scale
  `φ(p−1)μ^{p−1}`) — then covariate Tweedie fits come for free through
  `fit_gllvm_cov`.
- CIs: `src/confint_family.jl` adapter pattern (Gamma is the template).
- Note: `Distributions.jl` has **no Tweedie type**, so define `struct Tweedie;
  φ::Float64; p::Float64; end` as the marker (like the package's own `Ordinal`),
  not a Distributions distribution. `_glm_logpdf` calls the new
  `_tweedie_logpdf(y, μ, φ, p)` rather than `logpdf(::Distribution, y)`.

---

## 5. Slice plan with verifiable goals

**Slice 1 — density kernel + its validation.** Implement `_tweedie_logpdf`
(series + saddlepoint) and the closed-form `y=0` branch.
- *G1 (vs R `tweedie`):* `_tweedie_logpdf` matches `tweedie::dtweedie(y, p, μ, φ)`
  (log) to ≤1e-6 over a grid of `(y, μ, φ, p)` incl. `y=0`, small `y`, `p∈{1.2,1.5,1.8}`.
  (Generate the reference table once in R; store as a fixture — the package already
  uses R-parity fixtures.)
- *G2 (series vs saddlepoint):* the two agree to the saddlepoint's known accuracy
  in the regime where it is valid; report the gap, don't tune to pass.
- *G3 (normalisation):* `∫ f dy + P(y=0) = 1` by quadrature over `y>0` for several
  `(μ,φ,p)` to ≤1e-4.

**Slice 2 — family hooks + marginal, `p` fixed.** `_glm_score`/`_glm_weight`/
`_glm_logpdf(::Tweedie)` + `tweedie_marginal_loglik_laplace`.
- *G4 (score FD-check):* `_glm_score` matches central differences of
  `_tweedie_logpdf` wrt `η` to ≤1e-7.
- *G5 (Λ=0 reduction):* with `Λ=0`, the marginal equals `Σ_{t,s}
  _tweedie_logpdf(y, exp(β_t), φ, p)` exactly (≤1e-8) — the strict identity test,
  as for every other family.
- *G6 (limits):* as `p→2⁻` at fixed `φ`, the per-obs logf → Gamma logf (matching
  the existing `gamma` pieces); as `p→1⁺`, → (quasi-)Poisson. Check at `p=1.99`
  and `p=1.01` to documented tolerance.

**Slice 3 — `fit_tweedie_gllvm` (`p` fixed) + post-fit + CI.** Near-copy of
`fit_gamma_gllvm`; wire `TweedieFit` into `postfit.jl` and `confint_family.jl`;
add covariate helpers.
- *G7 (recovery):* simulate from known `(β,Λ,φ)` at `p=1.5` (via the compound
  Poisson–Gamma sampler) and recover them within MC tolerance; the realised
  zero-fraction matches `E[exp(−μ^{2−p}/(φ(2−p)))]`.
- *G8 (post-fit/CI smoke):* `predict`/`:prob0`/residuals shapes; `confint(fit, Y;
  method=:wald)` brackets the MLE; bootstrap parallel==serial.

**Slice 4 — `p` estimation (profile).** `fit_tweedie_gllvm(...; estimate_power=true)`
profiles `p` over a grid.
- *G9:* on data simulated at `p_true`, the profiled `p̂` is within one grid step of
  `p_true` across reps.

**Slice 5 — docs + ADEMP cell.** Response-families page row; a Tweedie-vs-two-part
note (when to prefer which); an ADEMP cell (vary `p, φ, zero-fraction`).

---

## 6. Caveats (validate by running, not by assertion)

1. **Series conditioning.** The Dunn–Smyth series is sharply peaked; naive summation
   overflows. Sum in log-space with log-sum-exp around the located peak index;
   test at small `φ` and large `y` where #terms grows.
2. **`p` near the boundaries.** `α=(2−p)/(1−p) → ±∞` as `p→1,2`; guard the
   evaluation and document the supported range (e.g. `p ∈ [1.01, 1.99]`).
3. **Small `μ`.** `μ^{2−p}` and `μ^{1−p}` for tiny `μ` (η at the clamp) — reuse the
   `_clamp_eta` guard; `_clamp_mu(::Tweedie, μ)=max(μ,1e-12)`.
4. **Identifiability `φ`↔`p`.** Jointly weakly identified at low signal — the reason
   `p` is profiled, not joint-optimised, in v1.
5. **Estimating `p` from few zeros.** If the data have no/all zeros, `p` is barely
   identified; warn.

---

## 7. Feasibility verdict

**Low-to-moderate, with one delicate numerical kernel.** Everything except the
density is a mechanical copy of the Gamma family (score/weight/fitter/post-fit/CI/
covariate hooks all reuse existing patterns). The density series is well-documented
(Dunn & Smyth 2005/2008) and has a reference implementation (R `tweedie`) to
validate against — so it is *engineering with an oracle*, not research. **`p` fixed
is a ~2–3 day slice; `p` profiling adds ~1–2 days.** The risk is entirely in the
series numerics, which is exactly why slice 1 front-loads the R-parity validation
before any fitting.

---

## 8. References

- Tweedie, M.C.K. (1984). An index which distinguishes between some important
  exponential families. *Statistics: Applications and New Directions* (Indian
  Statistical Institute).
- Jørgensen, B. (1987). Exponential dispersion models. *JRSS-B* 49. — the EDM
  framework; `Var = φ μ^p`.
- Dunn, P.K. & Smyth, G.K. (2005). Series evaluation of Tweedie exponential
  dispersion model densities. *Statistics and Computing* 15. — `dtweedie.series`
  (the exact density; G1 oracle).
- Dunn, P.K. & Smyth, G.K. (2008). Evaluation of Tweedie exponential dispersion
  model densities by Fourier inversion / saddlepoint. *Statistics and Computing*
  18. — the saddlepoint approximation.
- Smyth, G.K. & Dunn, P.K. **tweedie** R package (`dtweedie`, `ptweedie`,
  `tweedie.profile`). — the validation oracle and the `p`-profiling pattern.
- Foster, S.D. & Bravington, M.V. (2013). A Poisson–Gamma model for analysis of
  ecological non-negative continuous data. *Environ. Ecol. Stat.* 20. — the
  ecological motivation (CPUE/biomass) and the two-part comparison.
- Shono, H. (2008). Application of the Tweedie distribution to zero-catch data in
  CPUE analysis. *Fisheries Research* 93. — applied ecology precedent.
