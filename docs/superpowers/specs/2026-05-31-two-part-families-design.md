# Two-part / mixture family tier for GLLVM.jl — design + spec

**Date:** 2026-05-31 · **Author:** Shinichi Nakagawa (itchyshin) · **Status:** design + spec (pre-plan). **This is a spec only — no families are implemented by this document.**

## Context & goal

GLLVM.jl now fits Gaussian, Binomial, Poisson, negative-binomial (NB2), Beta,
Gamma and ordinal GLLVMs. All non-Gaussian families share one Laplace core
(`src/families/laplace.jl`): a scalar-μ per-site Fisher-scoring mode-finder plus
the normalised marginal `log p(y_s) ≈ ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`. Ordinal
is the precedent for a family that does **not** fit the scalar-μ core: it carries
its own per-site mode-finder and marginal while reusing `_clamp_eta`/`_safe_solve`
and mirroring the same normalisation.

The next tier is the **two-part / mixture** families that dominate ecological
abundance data, where a structural excess of zeros coexists with a count or
positive-continuous "intensity":

- **Hurdle-Poisson, Hurdle-NB** — zero vs nonzero is one process; the positive
  count, given nonzero, is a zero-truncated Poisson/NB.
- **ZIP, ZINB** (zero-inflated Poisson / NB) — a structural-zero mixture: a point
  mass at zero mixed with an ordinary (un-truncated) Poisson/NB.
- **Delta / two-part continuous** — Bernoulli occurrence × a positive-continuous
  density (Gamma or lognormal) for the nonzero values. The "Tweedie-like" delta
  model of biomass/cover data.

This document specifies the **mathematics and the build plan**. It does **not**
implement anything. Another engineer/agent should be able to build slice 1 of any
family from §2 + §4 alone.

## Scope

**In:** the latent-structure decision (§1); explicit marginal likelihoods and
Laplace integration for all five families (§2); the parameter inventory and how
each is estimated (§3); a per-family slice plan with a concrete slice-1 verifiable
goal (§4); the recommended build order and parallelism map (§5).

**Out (deliberate):**
- Implementation (code) of any family.
- Phylogenetic two-part models (the phylo substrate composes orthogonally with
  the family layer; revisit once the shared-`z` two-part path is proven).
- Covariate / `@formula` front-end for the two parts (rides the covariate track).
- Tweedie *proper* (compound-Poisson-Gamma with a continuous power-variance law).
  The delta model is the discrete-continuous two-part surrogate ecologists
  actually fit in gllvm; true Tweedie is a separate, later item.
- Post-fit niceties beyond what §4 lists per slice (biplot figure, `anova`).

---

## 1. The latent-structure decision (the key fork)

A two-part model has **two linear predictors per species** at each site `s`:

- an **occurrence / zero** predictor `η^z_{ts}` (drives the Bernoulli / mixing
  probability), and
- an **abundance / positive** predictor `η^c_{ts}` (drives the count or positive
  density).

The fork: do the two predictors **share** the site latent vector `z_s`, or get
**separate** latent vectors?

### Option A — shared `z`, part-specific loadings (RECOMMENDED v1 default)

One ordination per site: `z_s ~ N(0, I_K)`, shared by both parts, with separate
loading matrices and intercepts:

```
η^z_{ts} = β^z_t + (Λ_z z_s)_t          (occurrence / zero part)
η^c_{ts} = β^c_t + (Λ_c z_s)_t          (abundance / positive part)
```

Both `Λ_z` and `Λ_c` are p×K and act on the **same** `z_s`. The integral is over
one K-vector per site.

### Option B — separate latents

Two independent site vectors `z^z_s ~ N(0, I_{K_z})`, `z^c_s ~ N(0, I_{K_c})`:

```
η^z_{ts} = β^z_t + (Λ_z z^z_s)_t
η^c_{ts} = β^c_t + (Λ_c z^c_s)_t
```

The integral is over a `(K_z + K_c)`-vector per site. The two parts share nothing
but the data partition.

### Analysis

| Criterion | A (shared `z`) | B (separate) |
|-----------|----------------|--------------|
| **Latent dim integrated per site** | `K` | `K_z + K_c` (≈ 2× cost: logdet of a `(K_z+K_c)` matrix, 2× the inner solve width) |
| **Free loading params** | `2·[pK − K(K−1)/2]` (two p×K blocks, each modulo its own rotation) | `[pK_z − K_z(K_z−1)/2] + [pK_c − K_c(K_c−1)/2]` |
| **Identifiability** | Each loading block identified up to its **own** K×K rotation (two separate rotations; see below). Mild. | Same per-block rotations **plus** a label/coupling non-identifiability is avoided (the parts are independent by construction), but the model is richer and the occurrence latent is estimated from binary data alone — weakly informed at low prevalence. |
| **Interpretability** | **One ordination.** A single site score `z_s` explains both where a species occurs and how abundant it is. This is the ecological story: one latent environmental gradient drives both. The two loading sets show how occurrence vs abundance respond to that one gradient. | **Two ordinations** to interpret and reconcile. Harder to communicate; the occurrence ordination is often poorly determined. |
| **Reduces to the single-part GLLVM when one part is degenerate** | Yes — set `Λ_z=0` (or `Λ_c=0`) and that part becomes species-specific intercepts only, the other part is an ordinary GLLVM on the same `z`. | Yes, but with a dangling unused latent block. |
| **gllvm / gllvmTMB convention** | **This is the gllvm convention** (see note below). | Not the gllvm default. |

**gllvmTMB / gllvm convention (reasoned; flag uncertainty).** I cannot execute
the R `gllvmTMB` source from this repo (it is a read-only reference and not loaded
here), so I cannot quote the exact code path. Reasoning from GLLVM theory and the
published gllvm design: the R `gllvm` package's latent-variable model places the
**same** latent vector `u_i` (site scores) into the linear predictor, and its
zero-inflated / hurdle support (`family = "ZIP"`, `"ZINB"`, and the hurdle
variants) treats the **zero-inflation probability as a species-specific
parameter** (`zeta`/`phi`-style per-column intercept), *not* as a second
latent-variable ordination. In other words, gllvm's headline two-part models use a
**latent count/abundance part + a non-latent (intercept-only) zero part** — which
is exactly Option A with the additional simplification `Λ_z = 0`. The fully
latent-driven occurrence part (`Λ_z ≠ 0`) is the natural generalisation Option A
supports but which gllvm does not expose by default. **Treat the "`Λ_z = 0`,
species-specific occurrence" reading as the most likely gllvm default and the
safest parity target; verify against the gllvmTMB source before claiming exact
parity in docs.**

### RECOMMENDATION

**Adopt Option A (shared `z`) as the v1 default**, and within Option A make the
**occurrence/zero part intercept-only by default** (`Λ_z = 0`, i.e. a
species-specific zero/occurrence probability), with `Λ_c` the latent abundance
ordination. Rationale:

1. **One ordination** is the interpretable object ecologists want and what gllvm
   delivers; two ordinations are a research-grade option, not a default.
2. It is the **most-likely gllvm parity target** (count/abundance latent +
   per-species zero probability), easing the future R bridge.
3. It is the **cheapest** integral (`K`-vector per site) and reuses the existing
   scalar-`z` Laplace substrate width.
4. It **degrades gracefully**: with the positive part alone it is an ordinary
   count/Gamma GLLVM; the two-part layer only adds the zero machinery.

**Generalisation path (post-v1), all within Option A's data layout:**

- **Latent-driven occurrence** — allow `Λ_z ≠ 0` (occurrence responds to the same
  `z`). One extra p×K loading block; the marginal/score machinery in §2 is written
  for the general 2-block `η = [η^z; η^c]` so this is a fitter-level switch, not a
  re-derivation.
- **Separate latents (Option B)** — only if a use case demands an occurrence
  ordination distinct from the abundance ordination. The §2 score/weight blocks
  are block-diagonal in `[η^z; η^c]`, so Option B is "stack two independent `z`
  blocks and concatenate the loadings"; the per-site mode-finder generalises by
  widening `z` and using a block-diagonal `Λ`. Defer until asked.

**Design consequence for §2.** Write the per-site Laplace machinery for the
**general 2-block predictor** `η_s = [η^z_s; η^c_s]` (length `2p`) as a function of
one shared `z_s`. The default `Λ_z = 0` is then just a fixed-zero loading block,
not a special code path — this keeps the door open to latent-driven occurrence
without rework.

---

## 2. The marginal likelihood, per family

### 2.0 Common structure — why these need a dedicated per-site mode-finder

For every two-part family the per-observation log-density is a function of **two**
linear predictors, `η^z_{ts}` and `η^c_{ts}` (plus family dispersion). The generic
core in `src/families/laplace.jl` assumes a **scalar** μ per observation and a
scalar score/weight wrt a single η. A two-part observation does not fit that
contract. Therefore — exactly as **ordinal** does — each two-part family needs its
**own per-site Fisher-scoring mode-finder and marginal**, reusing `_clamp_eta`,
`_safe_solve`, and the normalisation `ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`.

**Shared-`z` Laplace bookkeeping (Option A).** With one shared `z_s` (length `K`),
both predictors are linear in `z_s`:
`η^z_s = β^z + Λ_z z_s`, `η^c_s = β^c + Λ_c z_s`. The site conditional
log-likelihood is `ℓ_s(z) = Σ_t log f_two-part(y_{ts} | η^z_{ts}, η^c_{ts})`. Its
gradient and (expected) Hessian wrt `z` are assembled from **per-observation,
per-block** scores and Fisher weights. Define, for observation `(t,s)`:

- block scores `s^z_t = ∂ log f / ∂η^z_t`, `s^c_t = ∂ log f / ∂η^c_t`;
- block Fisher weights — the negative expected second derivatives —
  `W^z_t = −E[∂² log f / ∂(η^z_t)²]`, `W^c_t = −E[∂² log f / ∂(η^c_t)²]`, and the
  cross term `W^{zc}_t = −E[∂² log f / ∂η^z_t ∂η^c_t]`.

**The cross term is zero for every family in this spec** (shown per family below):
the two parts are conditionally independent given `(η^z, η^c)` — the zero/positive
split is a clean factorisation, and the structural-zero mixture's expected
information is block-diagonal. So `W^{zc}_t = 0` and the per-observation expected
information wrt `z` is

```
J_t(z) = (∂η^z_t/∂z)(W^z_t)(∂η^z_t/∂z)' + (∂η^c_t/∂z)(W^c_t)(∂η^c_t/∂z)'
       = W^z_t (Λ_z[t,:])'(Λ_z[t,:]) + W^c_t (Λ_c[t,:])'(Λ_c[t,:]).
```

Summing over `t` and adding the prior precision `I`:

```
A(z) = Λ_z' diag(W^z) Λ_z + Λ_c' diag(W^c) Λ_c + I_K            (SPD by construction)
g(z) = Λ_z' s^z + Λ_c' s^c − z                                   (gradient of ℓ_s(z) − ½z'z)
```

**Fisher-scoring Newton step:** `z ← z + A(z)⁻¹ g(z)`, solved with `_safe_solve`,
iterated to `‖Δz‖_∞ < tol`. At the mode `ẑ`,

```
log p(y_s) ≈ ℓ_s(ẑ) − ½ ẑ'ẑ − ½ logdet A(ẑ).
```

This is **structurally identical** to the ordinal mode-finder; the only new work
is the family-specific `(s^z, s^c, W^z, W^c, log f)` quadruple-plus-density per
observation. With the v1 default `Λ_z = 0`, the occurrence block drops out of
`A` and `g` (its score still enters `ℓ_s` through `β^z` but contributes nothing to
the `z`-Hessian), so the integral is genuinely `K`-dimensional and the occurrence
intercepts `β^z` are profiled/optimised outside the Laplace loop (see §3).

> **Note — Λ=0 sanity for the verifiable goals (§4).** When **both** loading
> blocks are zero (`Λ_z = Λ_c = 0`), `η` is non-random, the integral collapses,
> `A = I`, `ẑ = 0`, `logdet A = 0`, and `log p(y_s) = ℓ_s(0)` **exactly**. So the
> whole-matrix marginal must equal the sum of independent per-observation two-part
> log-likelihoods to machine precision — this is the slice-1 goal pattern (§4),
> mirroring the existing NB/Gamma `Λ = 0` tests (`atol = 1e-8`).

Below, `f_count(k; μ, …)` is the *untruncated* count pmf (Poisson or NB2 with mean
μ; for NB2, `Var = μ + μ²/r`). `logit⁻¹` is the logistic CDF. `π_t` denotes the
occurrence/Bernoulli "success" probability and `π0_t` the structural-zero
probability — defined per family below.

---

### 2.1 Hurdle-Poisson and Hurdle-NB

**Parameterisation.** A Bernoulli occurrence process decides zero vs nonzero; the
positive count, given nonzero, is the count law **truncated at zero**.

- Occurrence: `π_t = linkinv(g_z, η^z_t)` (default logit ⇒ `π_t = logit⁻¹(η^z_t)`),
  the probability that `y_t > 0`.
- Positive count: mean `μ_t = exp(η^c_t)` (log link); the law on `{1, 2, …}` is the
  zero-truncated `f_count`.

**Mass / density:**

```
P(y_t = 0)         = 1 − π_t
P(y_t = k), k ≥ 1  = π_t · f_count(k; μ_t) / (1 − f_count(0; μ_t))      (zero-truncated)
```

with, for **Hurdle-Poisson**, `f_count(0;μ) = e^{−μ}` so the truncation
denominator is `1 − e^{−μ_t}`; and for **Hurdle-NB**, `f_count(0;μ) = (r/(r+μ))^r`
so the denominator is `1 − (r/(r+μ_t))^r`.

**Per-observation log-density** (the `log f` for the mode-finder):

```
log f =  log(1 − π_t)                                                if y_t = 0
      =  log π_t + log f_count(y_t; μ_t) − log(1 − f_count(0; μ_t))   if y_t ≥ 1
```

**Block scores wrt η.** The log-density **separates additively** into an
occurrence term depending only on `η^z` and a (truncated-count) term depending only
on `η^c`:

- **Occurrence block** (Bernoulli on the indicator `1{y_t>0}`, canonical-logit):
  `s^z_t = (1{y_t>0} − π_t) · (dπ/dη^z)/(π_t(1−π_t))`; with logit this is the
  canonical `s^z_t = 1{y_t>0} − π_t`, `W^z_t = π_t(1−π_t)`.
- **Positive block** (only contributes when `y_t ≥ 1`): the score of the
  zero-truncated count wrt `η^c`. With `m_t = dμ/dη^c = μ_t` (log link),

  ```
  s^c_t = [ s^c_count(y_t; μ_t) − ∂/∂η^c log(1 − f_count(0; μ_t)) ] · 1{y_t ≥ 1}
  ```

  where `s^c_count` is the ordinary count score wrt `η^c` (Poisson: `(y−μ)`; NB2:
  `(y−μ)/(1+μ/r)`), and the truncation-correction derivative is, for **Poisson**,
  `∂/∂η^c log(1 − e^{−μ}) = μ e^{−μ}/(1 − e^{−μ})`, and for **NB**,
  `∂/∂η^c log(1 − f0) = [r μ/(r+μ)] · f0/(1 − f0)` with `f0 = (r/(r+μ))^r`.
- **Cross term** `W^{zc}_t = 0`: the occurrence term has no `η^c` dependence and the
  positive term (conditional on `y_t≥1`) has no `η^z` dependence — clean
  factorisation.
- **Positive-block Fisher weight** `W^c_t`. Use the **expected information of the
  zero-truncated count** wrt `η^c`, evaluated under occurrence (i.e. multiplied by
  `π_t`, the probability the positive part is "active"). For numerical robustness
  and to keep `A` SPD, a convenient and valid Fisher-scoring weight is the
  occurrence-probability-weighted truncated-count information:
  `W^c_t = π_t · I_trunc(μ_t)`, with `I_trunc` the variance of `s^c_count` under
  the zero-truncated law (closed forms exist; or compute by the standard
  GLM expected-information `(dμ/dη)²·[1/Var_trunc]` using the truncated mean/variance
  — see implementation notes). A Poisson special case:
  `I_trunc(μ) = μ·(1 − (1+μ)e^{−μ}·… )` — **derive and unit-test against a
  finite-difference Hessian** rather than hand-transcribing (the truncated-variance
  algebra is error-prone; the slice-1 quadrature check in §4 catches mistakes).

> **Implementation guidance.** Because the truncated-count expected information is
> algebraically fiddly, the recommended robust path is: compute `s^c_t` exactly
> (above), and compute `W^c_t` as the **observed** or **expected** information via a
> small per-observation finite difference / autodiff of `−∂² log f/∂(η^c)²` at the
> current `η^c`, clamped to ≥ 0. This keeps `A` SPD and removes a class of
> transcription bugs; the cost is one extra scalar derivative per active
> observation. Switch to a closed form only after the FD version passes §4.

**Marginal.** Plug `(s^z, W^z, s^c, W^c, log f)` into the §2.0 shared-`z`
mode-finder and normalisation. With the default `Λ_z = 0`, the `W^z`/`s^z` blocks
do not enter `A`/`g` (only `ℓ_s` via `β^z`).

---

### 2.2 ZIP and ZINB (zero-inflated)

**Parameterisation.** A structural-zero **mixture**: with probability `π0_t` the
response is a structural zero; otherwise it is an **ordinary** (untruncated) count.

- Structural-zero probability: `π0_t = linkinv(g_z, η^z_t)` (default logit ⇒
  `π0_t = logit⁻¹(η^z_t)`). (gllvm convention: per-species `π0_t`, i.e. `Λ_z = 0`
  by default — see §1.)
- Count: mean `μ_t = exp(η^c_t)` (log link); ordinary `f_count` (**not** truncated).

**Mass:**

```
P(y_t = 0)         = π0_t + (1 − π0_t) · f_count(0; μ_t)
P(y_t = k), k ≥ 1  = (1 − π0_t) · f_count(k; μ_t)
```

with `f_count(0;μ) = e^{−μ}` (**ZIP**) or `(r/(r+μ))^r` (**ZINB**).

**Per-observation log-density:**

```
log f = log( π0_t + (1 − π0_t) f_count(0; μ_t) )       if y_t = 0
      = log(1 − π0_t) + log f_count(y_t; μ_t)           if y_t ≥ 1
```

**Block scores wrt η.** Unlike the hurdle, the **zero cell couples both
predictors** (a zero can come from either component), so the additive separation
holds only for `y_t ≥ 1`; the `y_t = 0` cell needs the mixture derivative. Let
`f0 = f_count(0; μ_t)` and the zero-cell mass `P0 = π0_t + (1−π0_t) f0`.

- **`y_t ≥ 1`:** `s^z_t = −(dπ0/dη^z)/(1 − π0_t)` (logit: `= −π0_t`);
  `s^c_t = s^c_count(y_t; μ_t)` (ordinary count score: Poisson `(y−μ)`, NB
  `(y−μ)/(1+μ/r)`).
- **`y_t = 0`:**
  ```
  s^z_t = (1 − f0)·(dπ0/dη^z) / P0           (logit: (1−f0)·π0(1−π0)/P0)
  s^c_t = (1 − π0_t)·(df0/dη^c) / P0         (df0/dη^c: Poisson −μe^{−μ}; NB −(rμ/(r+μ))·f0)
  ```
- **Cross term** `W^{zc}_t`. For `y_t ≥ 1` it is 0 (additive). For `y_t = 0` the
  expected cross information is generally nonzero in the structural-zero mixture.
  **However**, with the v1 default `Λ_z = 0` the occurrence block never enters `A`
  (it multiplies `Λ_z`), so the cross term is irrelevant to the integral and only
  the diagonal `W^c` is needed for the `z`-Hessian. **For the general
  latent-occurrence case** (`Λ_z ≠ 0`, post-v1), assemble the full 2×2 expected
  information per observation and keep the cross block — the §2.0 `A(z)` then gains
  the cross-coupled term `Σ_t W^{zc}_t [Λ_z[t,:]'Λ_c[t,:] + Λ_c[t,:]'Λ_z[t,:]]`.
  Document this; do not implement it in v1.
- **Weights for the v1 integral:** only `W^c_t` is needed. Use the **expected
  information of the zero-inflated count wrt `η^c`**; the robust path (as in §2.1)
  is a per-observation FD/autodiff of `−∂² log f/∂(η^c)²` at the current `η^c`,
  clamped ≥ 0. (Closed form: for `y≥1` it is the ordinary count info `μ` (Poisson)
  scaled by the active-component probability; for `y=0` it follows from
  differentiating the mixture-zero log-mass twice.)

**Marginal.** §2.0 machinery with `(s^c, W^c, log f)`; `Λ_z = 0` default.

> **ZINB note.** ZINB carries **both** `π0` (structural zeros) and `r`
> (overdispersion). These are **not** redundant: `r` absorbs Poisson-overdispersion
> in the *positive* counts, `π0` absorbs *excess* zeros beyond what NB predicts.
> Estimate both (see §3). Identifiability is empirically weak when zeros are scarce
> — warn, don't block.

---

### 2.3 Delta / two-part continuous (Bernoulli × Gamma or × lognormal)

**Parameterisation.** Exact-zero point mass × a positive-continuous density for
the nonzero values. This is the continuous analogue of the hurdle.

- Occurrence: `π_t = linkinv(g_z, η^z_t)` (default logit), the probability `y_t > 0`.
- Positive density `g(y; …)` on `(0, ∞)` with mean `μ_t = exp(η^c_t)` (log link):
  - **Delta-Gamma:** `g(y) = Gamma(y; shape α, scale μ_t/α)`, `Var = μ_t²/α`. Reuses
    the existing Gamma family pieces (`src/families/gamma.jl`).
  - **Delta-lognormal:** `g(y) = LogNormal(y; meanlog θ_t, sdlog σ)`, with
    `η^c_t = θ_t` the meanlog directly (so the "mean of log y" is linear in `z`),
    and `σ` a shared/per-species log-scale SD. (Choose the meanlog parameterisation
    so the positive part is an ordinary Gaussian GLLVM on `log y` — see §3.)

**Mass / density** (a mixed measure: point mass at 0, density on `(0,∞)`):

```
P(y_t = 0)        = 1 − π_t
density(y_t), y>0 = π_t · g(y_t; …)
```

**Per-observation log-density:**

```
log f = log(1 − π_t)                          if y_t = 0
      = log π_t + log g(y_t; …)               if y_t > 0
```

**Block scores wrt η** — fully additive (clean hurdle-style factorisation; the
continuous positive part has no zero-truncation, so it is simpler than §2.1):

- **Occurrence block** (Bernoulli on `1{y_t>0}`, canonical-logit):
  `s^z_t = 1{y_t>0} − π_t`, `W^z_t = π_t(1−π_t)`.
- **Positive block** (only `y_t > 0`):
  - **Delta-Gamma:** reuse `src/families/gamma.jl`'s pieces exactly —
    `s^c_t = α(y_t − μ_t)/μ_t² · m_t` with `m_t = μ_t` ⇒ `s^c_t = α(y_t−μ_t)/μ_t`;
    `W^c_t = α m_t²/μ_t² = α` (constant — the Gamma log-link Fisher weight).
  - **Delta-lognormal:** the positive part is Gaussian in `log y` with mean `θ_t`
    and SD `σ`; `s^c_t = (log y_t − θ_t)/σ²` (with `dθ/dη^c = 1`), `W^c_t = 1/σ²`.
- **Cross term** `W^{zc}_t = 0`: occurrence depends only on `η^z`, the positive
  density only on `η^c`; clean factorisation.

**Marginal.** §2.0 machinery; `Λ_z = 0` default ⇒ only `W^c` enters the integral.
**Delta-Gamma** reuses the Gamma `_glm_*` weight/score algebra (don't re-derive).
**Delta-lognormal**'s positive part is literally a Gaussian-on-`log y` GLLVM, so its
contribution to `A` is the constant `W^c = 1/σ²` — the cleanest possible case.

> **Delta vs hurdle terminology.** "Hurdle" is conventionally the *discrete*
> two-part (zero-truncated count); "delta" the *continuous* two-part (Bernoulli ×
> positive density). They share the §2.0 machinery and the `P(0)=1−π` occurrence
> form; they differ only in the positive part (truncated count vs continuous
> density). Both are distinct from ZI (mixture, untruncated). Keep the three names
> distinct in the API.

---

## 3. Parameters per family and how they're estimated

Each fit optimises, by L-BFGS over a packed unconstrained vector, the same family
pattern as the existing fitters (`[β; vec(Λ); transformed-dispersion]`,
finite-difference gradient, SVD warm-start), **extended** with the two-part pieces.

| Family | Positive-part params | Zero/occurrence params | Dispersion | v1 default for zero loadings |
|--------|----------------------|------------------------|------------|------------------------------|
| Hurdle-Poisson | `β^c` (p), `Λ_c` (p×K) | `β^z` (p) occurrence intercepts | — | `Λ_z = 0` |
| Hurdle-NB | `β^c`, `Λ_c` | `β^z` (p) | `r` (1, shared) | `Λ_z = 0` |
| ZIP | `β^c`, `Λ_c` | `β^z` (p) structural-zero intercepts | — | `Λ_z = 0` |
| ZINB | `β^c`, `Λ_c` | `β^z` (p) | `r` (1, shared) | `Λ_z = 0` |
| Delta-Gamma | `β^c`, `Λ_c` | `β^z` (p) | shape `α` (1, shared) | `Λ_z = 0` |
| Delta-lognormal | `β^c`, `Λ_c` | `β^z` (p) | log-SD `σ` (1, shared) | `Λ_z = 0` |

**Estimation details.**

- **Occurrence/zero probabilities** (`π_t` or `π0_t`): driven by per-species
  intercepts `β^z_t` on the chosen link (default logit). These are **free
  parameters in the outer L-BFGS**, packed alongside `β^c`. They do **not** enter
  the Laplace inner mode-finder's `z`-Hessian under the `Λ_z = 0` default, but they
  **do** enter the conditional log-likelihood `ℓ_s` (the occurrence/zero term),
  so the marginal — and hence the L-BFGS objective — depends on them. (When the
  occurrence part is later made latent, `Λ_z` packs as a second loading block.)
- **Dispersion** (`r`, `α`, `σ`): a **single shared** scalar each (matching the
  existing NB `r`, Beta `φ`, Gamma `α` convention — one shared dispersion, not
  per-species), optimised on the log scale (`log r`, `log α`, `log σ`) so it stays
  positive for free. Per-species dispersion is a documented post-v1 option, not a
  default.
- **Link choices.** Occurrence/zero link defaults to logit; probit/cloglog allowed
  via the existing `Link` types (the score/weight formulas above are written for a
  general link through `dπ/dη`; only the logit canonical simplifications are noted
  inline). Positive-count link is log; Gamma positive link is log; lognormal uses
  identity on the meanlog.
- **Packing.** Reuse `pack_lambda`/`unpack_lambda` and `rr_theta_len` for `Λ_c`.
  The packed vector is `[β^z (p); β^c (p); vec(Λ_c) (rr); transformed-dispersion]`.
  (When `Λ_z` becomes free, append `vec(Λ_z)`.)
- **Warm start.** Occurrence intercepts `β^z_t = logit(empirical P(y_t>0))` (ZI:
  initialise `π0` from the zero-excess over the count fit's predicted zeros, or
  simply the empirical zero proportion as a loose start). Positive-part `β^c` and
  `Λ_c` from the existing count/Gamma/Gaussian SVD warm-start **applied to the
  positive observations only** (e.g. `log(y+0.5)` over nonzeros, zeros masked or
  mean-imputed for the SVD proxy). Dispersion from a moderate constant
  (`r₀ = 10`, `α₀ = … `, `σ₀ = sd(log y_{>0})`), matching the existing fitters.

---

## 4. Per-family slice plan + slice-1 verifiable goal

Each family follows the established **3-slice rhythm** (marginal → fit → post-fit),
each slice its own branch → PR → CI → merge, exactly as NB/Beta/Gamma/ordinal did.

### Slice structure (identical shape per family)

- **Slice 1 — marginal.** `<fam>_marginal_loglik_laplace(Y, …)` built on the §2.0
  shared-`z` mode-finder. Source: a new `src/families/<fam>.jl`. Test:
  `test/test_<fam>_laplace.jl`. **Verifiable goal below.**
- **Slice 2 — fit.** `fit_<fam>_gllvm(Y; K, …)` (L-BFGS over the §3 packed vector,
  finite-diff gradient, SVD warm-start) + a `<Fam>Fit` struct + a `_fit_gllvm`
  dispatch line in `src/families/fit_gllvm.jl`. Test: `test/test_<fam>_fit.jl`
  (recovers planted `β^z`/`β^c`/`Λ_c`/dispersion on simulated data within tolerance;
  `fit_gllvm(family=…)` routes correctly).
- **Slice 3 — post-fit.** `getLV`/`predict`/`residuals`/`_nparams`/`aic`/`bic`/`show`
  for `<Fam>Fit` in `src/postfit.jl`, parallel to the existing per-family blocks.
  `predict` must expose **both parts** (`:prob_occurrence`/`:mean_positive`/
  `:response` where `:response = π·μ` is the unconditional mean). Residuals:
  Dunn–Smyth randomized-quantile under the two-part CDF (the discrete-continuous
  mixed CDF for delta; the discrete mixed CDF for hurdle/ZI). Test:
  `test/test_<fam>_postfit.jl`.

### Slice-1 verifiable goal, per family (the Λ=0 reduction)

The house pattern (cf. `test/test_negbin_laplace.jl`, `test/test_gamma_laplace.jl`):
**with `Λ_c = 0` (and `Λ_z = 0`), the whole-matrix Laplace marginal must equal the
sum of independent per-observation two-part log-likelihoods to `atol = 1e-8`.**
Plus a `K=1` single-site numerical-quadrature cross-check (loose `atol`, because the
log link is non-canonical ⇒ Fisher-info Laplace, as in the Gamma test). Concretely,
each family's slice-1 test asserts `ll ≈ ll_indep` where `ll_indep` is:

- **Hurdle-Poisson** — `Σ_{t,s}` of:
  `log(1−π_t)` if `y=0`, else `log π_t + logpdf(Poisson(μ_t), y) − log(1 − e^{−μ_t})`,
  with `π_t = logit⁻¹(β^z_t)`, `μ_t = exp(β^c_t)`.
- **Hurdle-NB** — same, with `logpdf(NegativeBinomial(r, r/(r+μ_t)), y)` and
  truncation `− log(1 − (r/(r+μ_t))^r)` for `y ≥ 1`.
- **ZIP** — `Σ_{t,s}` of:
  `log(π0_t + (1−π0_t)·e^{−μ_t})` if `y=0`, else `log(1−π0_t) + logpdf(Poisson(μ_t), y)`,
  with `π0_t = logit⁻¹(β^z_t)`.
- **ZINB** — same with NB `f0 = (r/(r+μ_t))^r` and `logpdf(NegativeBinomial(r, r/(r+μ_t)), y)`.
- **Delta-Gamma** — `Σ_{t,s}` of:
  `log(1−π_t)` if `y=0`, else `log π_t + logpdf(Gamma(α, μ_t/α), y)`.
- **Delta-lognormal** — `Σ_{t,s}` of:
  `log(1−π_t)` if `y=0`, else `log π_t + logpdf(LogNormal(θ_t, σ), y)`, `θ_t = β^c_t`.

Each is a 3–5-line closed form over the data matrix — directly codable as the
slice-1 test oracle, exactly mirroring the existing NB/Gamma tests. **Building
slice 1 from §2 + this goal is self-contained.**

A second slice-1 assertion (recommended, mirroring `test_negbin_laplace.jl`'s
"large r → Poisson" cross-check): **Hurdle-NB → Hurdle-Poisson** and
**ZINB → ZIP** as `r → ∞` (`rtol = 1e-3`); and **ZIP → Poisson** /
**Hurdle-Poisson → Poisson** as `π0_t → 0` / `π_t → 1` (the two-part layer
vanishes), giving a free consistency check against the already-shipped Poisson
marginal.

---

## 5. Build order + parallelism

### Shared machinery (build once, first)

A new internal **two-part Laplace substrate** — the §2.0 shared-`z` 2-block
mode-finder and normalisation — generalises the ordinal precedent to a 2-block
predictor. Concretely a small set of internal helpers (e.g.
`_twopart_laplace_mode` / `_twopart_loglik_site` taking per-observation
`(s^z, W^z, s^c, W^c, log f)` closures, plus the `Λ_z`-aware `A`/`g` assembly).
**This is the one piece every family shares; build and unit-test it first** (against
a hand-rolled single-family marginal, e.g. delta-lognormal, whose `W^c = 1/σ²` is
trivial — the cleanest validation substrate).

### Dependency graph

```
        [0] two-part Laplace substrate (§2.0)  ── prerequisite for all ──┐
                                                                          │
   ┌──────────────────────────────────────────────────────────────────┐ │
   │ count-side (share count pmf + truncation/mixture algebra)          │ │
   │                                                                    │ │
   │   [1a] Hurdle-Poisson ──┐         [1b] ZIP ──┐                      │ │
   │            │            │              │     │                      │ │
   │            ▼            │              ▼     │                      │ │
   │   [2a] Hurdle-NB  ──────┘     [2b] ZINB ─────┘                      │ │
   │   (Hurdle-NB reuses Hurdle-Poisson's truncation + adds r;           │ │
   │    ZINB reuses ZIP's mixture + adds r)                              │ │
   └──────────────────────────────────────────────────────────────────┘ │
                                                                          │
   ┌──────────────────────────────────────────────────────────────────┐ │
   │ continuous-side (independent of the count-side; reuses Gamma/Gauss)│ │
   │   [1c] Delta-lognormal (trivial W^c) ── [2c] Delta-Gamma           │ │
   │   (Delta-Gamma reuses src/families/gamma.jl pieces)                │ │
   └──────────────────────────────────────────────────────────────────┘ │
                                                                          │
   note: Gamma currently has a marginal but NO fit/post-fit (only        │
   slice 1 shipped). Delta-Gamma's positive part is fine (marginal       │
   exists); Delta-Gamma's own fit/post-fit is new regardless. ──────────┘
```

### Recommended order

1. **[0] two-part Laplace substrate** (prerequisite; validate via a throwaway
   delta-lognormal marginal).
2. **[1a] Hurdle-Poisson** — simplest count two-part with truncation; proves the
   count-side substrate end-to-end (all 3 slices).
3. **[1b] ZIP** — proves the mixture-zero substrate (all 3 slices). **Can run in
   parallel with [1a]** once [0] lands: they touch **disjoint files**
   (`src/families/hurdle_poisson.jl` vs `src/families/zip.jl`, separate tests,
   separate `_fit_gllvm` lines, separate `postfit.jl` blocks).
4. **[1c] Delta-lognormal** — continuous-side; **fully parallel** with the entire
   count-side (disjoint files, no shared algebra beyond [0]).
5. **[2a] Hurdle-NB**, **[2b] ZINB**, **[2c] Delta-Gamma** — each extends its slice-1
   sibling with a dispersion parameter (`r`, `r`, `α`); build after the
   corresponding [1*] proves the pattern. These three are mutually parallel.

### Parallel vs serial summary

- **Serial prerequisite:** [0] before everything.
- **Three independent tracks** after [0] (assign to disjoint agents):
  **(A)** hurdle: [1a]→[2a]; **(B)** zero-inflated: [1b]→[2b]; **(C)** delta:
  [1c]→[2c]. The three tracks share **no source files** (each family is its own
  `src/families/<fam>.jl` + its own test + one line in `fit_gllvm.jl` + its own
  `postfit.jl` block) — so they satisfy the repo's "agents on disjoint files"
  discipline, with the **only** coordination point being `src/GLLVM.jl` includes,
  `src/families/fit_gllvm.jl` dispatch lines, and the `export` list (small, append-
  only, low-conflict; stage by name).
- **Within a track**, [2*] depends on [1*] (reuses the same `<fam>.jl` and adds the
  dispersion to the fitter), so a track is serial internally.

---

## 6. Locked decisions

1. **Shared `z` (Option A)** is the v1 latent structure; **occurrence/zero part is
   intercept-only (`Λ_z = 0`) by default** (per-species occurrence/zero
   probability), with `Λ_c` the abundance ordination. The §2 machinery is written
   for the general 2-block `η`, so latent-driven occurrence (`Λ_z≠0`) and separate
   latents (Option B) are post-v1 switches, not re-derivations.
2. **Per-site mode-finder per family** (ordinal precedent), not the scalar-μ generic
   core — two linear predictors don't fit the scalar contract. A shared 2-block
   substrate [0] is built once and reused.
3. **Dispersion is a single shared scalar** (`r`, `α`, `σ`), log-scale-optimised,
   matching NB/Beta/Gamma.
4. **Slice-1 verifiable goal is the `Λ=0` exact reduction** (`atol = 1e-8`) to the
   independent two-part-regression loglik, plus a `K=1` quadrature cross-check and
   the limit checks (NB→Poisson as `r→∞`; ZI/hurdle → base count as the zero layer
   vanishes) — mirroring the shipped NB/Gamma tests.
5. **Three keywords stay distinct**: hurdle (truncated-count two-part), ZI
   (untruncated mixture), delta (continuous two-part). Distinct family markers /
   fit functions / docs.
6. **Build order:** substrate [0] → three disjoint tracks (hurdle, ZI, delta),
   serial within each track ([1*]→[2*]). Tweedie-proper and phylogenetic two-part
   are out of scope.

## 7. Family markers (naming) — for the dispatch seam

`Distributions.jl` has no hurdle/ZI/delta types, so — exactly as `Ordinal` — GLLVM
defines its own markers. Proposed (final naming to confirm at slice 2):

- `HurdlePoisson`, `HurdleNB` (or a parametric `Hurdle{Poisson}` / `Hurdle{NB}` —
  decide at slice 2; standalone structs are simpler and match `Ordinal`).
- `ZIP`, `ZINB` (or `ZeroInflated{Poisson}` / `ZeroInflated{NB}`).
- `DeltaGamma`, `DeltaLogNormal` (or `Delta{Gamma}` / `Delta{LogNormal}`).

Each gets a `default_link` (logit for the zero/occurrence part) and a `_fit_gllvm`
dispatch line. Dispersion-carrying markers (`HurdleNB`, `ZINB`, `DeltaGamma`,
`DeltaLogNormal`) carry their dispersion in a field, as `NegativeBinomial`/`Beta`/
`Gamma` markers do, recomputed inside the fitter.

---

## Appendix — quick correctness cribsheet (all written for the v1 `Λ_z=0` default)

Per observation `(t,s)`; `π,π0 = logit⁻¹(β^z_t)`; `μ = exp(β^c_t)`; `m=dμ/dη^c=μ`.

| Family | `log f` (y=0) | `log f` (y>0 / y≥1) | `s^c` (enters g) | `W^c` (enters A) |
|--------|---------------|---------------------|------------------|------------------|
| Hurdle-Pois | `log(1−π)` | `log π + logPois(y;μ) − log(1−e^{−μ})` | `(y−μ) − μe^{−μ}/(1−e^{−μ})` | FD of `−∂²logf/∂η^{c2}` (≥0) |
| Hurdle-NB | `log(1−π)` | `log π + logNB(y;μ,r) − log(1−f0)`, `f0=(r/(r+μ))^r` | `(y−μ)/(1+μ/r) − (rμ/(r+μ))f0/(1−f0)` | FD (≥0) |
| ZIP | `log(π0+(1−π0)e^{−μ})` | `log(1−π0)+logPois(y;μ)` | `y=0:(1−π0)(−μe^{−μ})/P0`; `y≥1:(y−μ)` | FD (≥0) |
| ZINB | `log(π0+(1−π0)f0)` | `log(1−π0)+logNB(y;μ,r)` | `y=0:(1−π0)(−(rμ/(r+μ))f0)/P0`; `y≥1:(y−μ)/(1+μ/r)` | FD (≥0) |
| Delta-Gamma | `log(1−π)` | `log π + logGamma(y;α,μ/α)` | `α(y−μ)/μ` | `α` (const) |
| Delta-LogN | `log(1−π)` | `log π + logLogN(y;θ,σ)`, `θ=β^c_t` | `(log y−θ)/σ²` | `1/σ²` (const) |

`P0 = π0 + (1−π0)f0`. The occurrence score `s^z` and weight `W^z`
(logit: `s^z=1{y>0}−π`, `W^z=π(1−π)` for hurdle/delta; the ZI `y=0` cell couples)
enter `ℓ_s`/`g`/`A` only when `Λ_z≠0` (post-v1) — under the v1 default they affect
the marginal solely through `β^z` in `ℓ_s`, never the `z`-Hessian. The two-block
cross weight `W^{zc}=0` for hurdle/delta everywhere and for ZI at `y≥1`; the ZI
`y=0` cross term is needed only in the post-v1 latent-occurrence model.
