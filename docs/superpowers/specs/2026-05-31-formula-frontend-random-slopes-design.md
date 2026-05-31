# `@formula` front-end + random slopes — design

**Date:** 2026-05-31 · **Author:** Shinichi Nakagawa (itchyshin) · **Persona lead:** Boole (formula/macro grammar), with Gauss (engine), Hopper (R↔Julia parity), Emmy (architecture) · **Status:** scoping spec (SPEC ONLY — not a plan, no implementation)

> This document scopes a **large, previously-parked subsystem**: a `gllvmTMB`-style `@formula` front-end over both wide and long data, whose headline new capability is **covariate × grouping random slopes** `(1 + x | group)`. It is deliberately candid about cost. It is the missing front-end half of the "catch up with gllvmTMB" goal (issue #6, roadmap v0.3.0) and the precondition for the R-bridge `engine="julia"` path. **No code is written here.** A separate plan will sequence the slices.

---

## 0. Why this exists, and what it is not

### The goal
The maintainer wants a user to write, in Julia, something close to what they write in R's `gllvmTMB`:

```julia
gllvm(@formula(abundance ~ 1 + temperature + (1 + temperature | site) + phylo()),
      data; family = Poisson())
```

and have that parse — over **either** a wide species×site matrix **or** a long melted table — into the matrix-level arguments the existing engine already consumes (`Y`, `X`, `K`/`K_W`/`K_phy`, `Σ_phy`, …). The **random slope** `(1 + temperature | site)` is the centrepiece: today the engine has *no* covariate×grouping random-coefficient block, so this is a genuine new engine capability, not merely a parsing convenience.

### What it is NOT (hard scope fences)
- **Not** a rewrite of the marginal-likelihood kernels. The Gaussian closed form (`src/likelihood.jl`) and the Laplace core (`src/families/laplace.jl`) stay. We *extend* their covariance/linear-predictor surface, surgically.
- **Not** a new ordination model. `K`/`K_W` latent blocks are untouched in their math; the formula merely gives them syntax (`latent(...)`).
- **Not** an animal-model / `covariate × phylo_unique` feature (README explicitly excludes it; out of scope here too).
- **Not** spatial/SPDE random effects.
- **Not** a change to R's `gllvmTMB` (hard boundary: that package is read-only reference).

### The single most important engine finding (drives the whole size estimate)
There are **two** linear-predictor code paths, and they are **not symmetric**:

| Path | File | Linear predictor today | Carries `Xβ`? | Per-obs RE substrate? |
| --- | --- | --- | --- | --- |
| Gaussian | `src/likelihood.jl` `gaussian_marginal_loglik` | `y_s = X_s β + Λ_B η_B + Λ_W η_W + s_B + s_W + s_phy + ε` | **Yes** (`X::Array{p,n,q}`, `β::Vector{q}`) | diagonal only (`σ²_B`, `σ²_W`); **no covariate×group block** |
| Non-Gaussian (Laplace) | `src/families/laplace.jl` | `η_{ts} = β_t + (Λ z_s)_t`, `z_s ~ N(0,I_K)` | **No** — there is literally no `X` argument in the Laplace core or `fit_binomial_gllvm`/`fit_poisson_gllvm`/… | none |

So before random slopes can exist for non-Gaussian families, the Laplace path must first gain an `Xβ` fixed-effect term *at all*. This is flagged here as a **blocking prerequisite** (§6) and is the reason the honest size estimate is large rather than medium.

---

## 1. Grammar (gllvmTMB parity target)

### 1.1 Target surface syntax

```
response ~ fixed_effects + (slope_terms | group) + latent(...) + traits(...) + phylo(...)
```

Concretely, the forms we commit to parsing (Julia `@formula`, via StatsModels.jl):

```julia
# Gaussian, fixed effects only (already expressible at the matrix level today)
gllvm(@formula(y ~ 1 + temp + depth), data; family = Normal(), K = 2)

# Random intercept by site  → per-group intercept RE
gllvm(@formula(y ~ 1 + temp + (1 | site)), data; family = Normal(), K = 2)

# Random slope (HEADLINE): intercept + temp slope, correlated, by site
gllvm(@formula(y ~ 1 + temp + (1 + temp | site)), data; family = Poisson(), K = 2)

# Uncorrelated random slope (|| as in lme4/MixedModels)
gllvm(@formula(y ~ 1 + temp + (1 + temp || site)), data; family = Normal(), K = 2)

# Latent ordination block made explicit (today's K / K_W)
gllvm(@formula(y ~ 1 + temp + latent(K = 2) + latent(0 + 1 | unit)), data; family = Normal())

# Phylogenetic block (today's Σ_phy / Λ_phy / σ_phy)
gllvm(@formula(y ~ 1 + temp + phylo()), data; family = Normal(), K = 1,
      tree = my_tree)        # or Σ_phy = my_cov

# Multi-trait / fourth-corner (trait × environment interaction)
gllvm(@formula(y ~ 1 + temp + traits(body_size) + temp & traits(body_size)),
      data; family = Normal())
```

### 1.2 Grammar elements and their gllvmTMB analogue

| GLLVM.jl term | Meaning | gllvmTMB / lme4 analogue | Engine target (§2–3) |
| --- | --- | --- | --- |
| `1`, `x`, `x & z`, `poly(x,2)` | Fixed effects on the linear predictor | RHS fixed terms | `X` array + `β` |
| `(1 \| g)` | Random intercept by grouping factor `g` | `(1 \| g)` | **new** covariate×group RE block, slope part empty |
| `(1 + x \| g)` | Correlated random intercept + slope of `x` by `g` | `(1 + x \| g)` | **new** random-coefficient block, 2×2 covariance per `g` |
| `(0 + x \| g)` | Random slope, no random intercept | `(0 + x \| g)` | **new** RE block, 1×1 covariance |
| `(1 + x \|\| g)` | Uncorrelated intercept + slope | `(1 + x \|\| g)` | **new** RE block, **diagonal** covariance |
| `latent(K = m)` | Site-tier ordination, rank `m` | `latent(~ 0 + ... \| site)` (rr) | `K` / `Λ_B` (existing) |
| `latent(0 + 1 \| unit)` | Unit-obs ordination tier | `latent(... \| unit)` | `K_W` / `Λ_W` (existing) |
| `traits(...)` | Species-trait covariates → trait×environment (fourth-corner) | `gllvmTMB` `TR=` / `formula = y ~ (x) + (TR)` | column-expansion of `X` (§2.4) |
| `phylo()` / `phylo(tree)` | Phylogenetic random effect | `phylo`-structured RE | `Σ_phy` + `Λ_phy` / `σ_phy` (existing) |

**Parity boundary (be candid):** full `gllvmTMB` formula parity (e.g. nested grouping `(1 | a/b)`, crossed multi-grouping, `disp.formula`, `row.eff` correlation structures) is *not* a v1 target. We commit to: fixed effects, single-grouping random intercepts/slopes (correlated and uncorrelated), `latent()`, `traits()`, `phylo()`. Everything else is explicitly deferred and must error with a clear "not yet supported" message rather than silently mis-parse.

### 1.3 Wide vs long: two front doors, one internal representation

The maintainer requires that **both** data shapes parse to the *same* internal representation (an `IR`, §2.2) and ultimately the same engine matrices. The two shapes:

**WIDE** — the native ecology layout and the engine's current native layout.
- `Y`: a `p × n` (species × site) numeric matrix (or a `Tables`-compatible frame of `p` response columns).
- `site_data`: an `n`-row frame of **site-level** covariates (`temp`, `depth`, `site` id, …) — one row per *column* of `Y`.
- `trait_data` (optional): a `p`-row frame of **species-level** covariates (`body_size`, …) — one row per *row* of `Y`.
- `tree`/`Σ_phy` (optional): species-level phylogeny.

In wide mode the formula's *response* names the matrix (`y` ≡ the whole `Y`), fixed/random covariates resolve against `site_data` (length `n`) or `trait_data` (length `p`), and `traits(...)` resolves against `trait_data`. This matches `gllvmTMB(y, X = site_data, TR = trait_data)`.

**LONG** — one row per (species, site) observation; the `tidy`/melted form.
- `data`: an `n·p`-row frame with columns `response`, a species/column key (default `:species`), a site/row key (default `:site`), and any covariates (site-level covariates are *repeated* down the species axis; species-level covariates repeated down the site axis).
- The formula's response is the `response` column; the species and site keys are named via keyword (`species = :sp`, `site = :site`) or inferred from a `(1 | species)` / grouping convention.

**The contract:** `parse(formula, wide_inputs)` and `parse(formula, melt(wide_inputs))` produce **bit-identical** engine matrices (up to row/column permutation that the IR records and undoes). This identity is a *tested goal* (§5, §4).

---

## 2. StatsModels custom terms → engine matrices

### 2.1 Why StatsModels.jl (Jason/Boole call)

StatsModels.jl is the ecosystem-standard formula engine (MixedModels.jl, GLM.jl build on it). It gives us, for free: the `@formula` macro, `Term`/`InterceptTerm`/`FunctionTerm`/`InteractionTerm` AST, `schema(data)` → `apply_schema(formula, schema, Mod)` → `ContinuousTerm`/`CategoricalTerm`, and `modelcols(term, data)` → numeric design columns with contrast coding handled. We reuse it rather than hand-rolling a parser. **New direct dependencies:** `StatsModels`, `Tables` (and transitively `CategoricalArrays`); `StatsAPI` is already present transitively. This is the first time the package takes a formula/data-frame dependency — Emmy must sign off on the `Project.toml`/compat change (an API-surface change → maintainer approval per AGENTS.md).

### 2.2 The intermediate representation (IR)

Both front doors lower to a single struct (names illustrative):

```julia
struct GllvmFormulaIR
    family                     # Normal(), Poisson(), …
    p::Int; n::Int             # species, sites
    # Fixed effects → engine X
    X::Array{Float64,3}        # (p, n, q) — the engine's fixed-effect array
    fe_names::Vector{String}   # length q, for summary()/coef tables
    # Random-effect blocks (NEW) → §3
    re_blocks::Vector{ReBlock} # one per (slope_terms | group) term
    # Latent ordination
    K::Int; K_W::Int           # ranks (from latent(...) or K kwarg)
    # Phylogeny
    Σ_phy::Union{Nothing,Matrix{Float64}}
    K_phy::Int; has_phy_unique::Bool
    # Bookkeeping for the wide↔long round-trip
    species_levels::Vector     # row order of Y
    site_levels::Vector        # column order of Y
end
```

`ReBlock` is the new object the random-slope feature introduces:

```julia
struct ReBlock
    group_name::Symbol         # e.g. :site
    group::Vector{Int}         # length n (wide) — level index per site
    n_levels::Int              # number of groups (e.g. n_sites if group==site)
    Z::Matrix{Float64}         # (n × r) within-group covariate design: [1 x …]
    coef_names::Vector{String} # length r, e.g. ["(Intercept)", "temp"]
    correlated::Bool           # true for `|`, false for `||`
end
```

Here `r` is the number of random coefficients (e.g. `r = 2` for `(1 + temp | site)`). The covariance to estimate is `r × r` (correlated) or `r`-diagonal (uncorrelated). See §3.

### 2.3 Term-by-term lowering

**Fixed-effect terms** (`1`, `temp`, `temp & depth`, …):
1. `apply_schema` against the merged schema (site-level + trait-level columns).
2. `modelcols` → an `n × q_fe` matrix `M` for site-level covariates (one row per site).
3. **Broadcast to the engine's `(p, n, q)` shape.** The engine's `X[t, s, k]` is indexed by *species t, site s, covariate k*. A purely site-level covariate is constant across species: `X[:, s, k] = M[s, k]` for all `t`. A species-level covariate (rare as a pure fixed effect) is constant across sites: `X[t, :, k] = M_sp[t, k]`. This broadcast is the crux of mapping a 2-D design to the engine's 3-D array. Verified against `gaussian_marginal_loglik`'s `X` contract (`src/likelihood.jl:88–108`).

**Custom term `traits(...)`** — a `StatsModels` custom term (subtype `AbstractTerm`) registered so `@formula` accepts `traits(body_size)`:
- `apply_schema(::TraitsTerm, sch, Mod)` resolves the named columns against `trait_data` (length `p`).
- The *interaction* `temp & traits(body_size)` is the fourth-corner / trait×environment term: it produces a covariate that varies in **both** axes — `X[t, s, k] = temp[s] * body_size[t]`. This is exactly why the engine's `X` is 3-D rather than 2-D, and `traits()` is the term that exercises that generality. A bare `traits(body_size)` with no environment interaction broadcasts species-wise (`X[t, :, k] = body_size[t]`).
- Implementation note: `traits()` is *not* a random effect; it only expands `X`. It is in scope because it is cheap (column construction) and is the headline gllvmTMB modelling idiom that justifies the 3-D `X`.

**Custom term `phylo(...)`**:
- `phylo()` / `phylo(tree)` / `phylo(; Σ = …)` resolves to a species-level `p × p` covariance `Σ_phy` (from a supplied tree via a Brownian-motion correlation, or a directly supplied matrix). The tree→`Σ_phy` conversion itself is an existing concern (the package already consumes a caller-supplied `Σ_phy`); the formula term just *names* it and routes it to `fit_*`'s `Σ_phy` keyword.
- Sets `K_phy` / `has_phy_unique` flags on the IR (defaults: `phylo()` ⇒ `has_phy_unique = true`, the `σ_phy · φ` term; `phylo(rank = m)` ⇒ `K_phy = m`).
- **Candid note:** tree parsing (Newick, `Phylo.jl` interop) is a separate concern; this spec assumes `Σ_phy` is either supplied directly or produced by an already-existing helper. We do not scope tree I/O here.

**Custom term `latent(...)`**:
- `latent(K = m)` → sets IR `K = m` (the site-tier ordination, `Λ_B`). `latent(0 + 1 | unit)` → sets `K_W` (the unit-obs tier, `Λ_W`). This makes the existing `K`/`K_W` arguments expressible in the formula and documents the `latent(0 + trait | site)` hint already in `docs/src/model.md:29`. If the user passes `K` as a keyword *and* a `latent()` term, that is an error (one source of truth).

**Random-effect terms** `(slope_terms | group)` — the new substrate, §3.

### 2.4 What `apply_schema` / `modelcols` give us vs. what we build

StatsModels handles: parsing `~`, operator precedence, `&` interactions, contrast coding of categoricals, the `schema → apply_schema → modelcols` pipeline. We build, as StatsModels **custom term types** (each an `AbstractTerm` with `apply_schema`/`modelcols`/`StatsModels.terms` methods):
- `TraitsTerm`, `PhyloTerm`, `LatentTerm` — recognised inside `@formula` via the `FunctionTerm` mechanism (the documented StatsModels path for `mycall(args)` syntax: define a method capturing the special-function call).
- The random-effect term `(… | …)`: StatsModels itself does **not** define `|`. MixedModels.jl defines a `|` term (`FunctionTerm{typeof(|)}` → `RandomEffectsTerm`). We mirror MixedModels' approach (Jason: reuse the *pattern*, not necessarily the dependency — taking all of MixedModels as a dep is heavy; we lift the ~200-line `|`-term handling). **Decision point flagged:** depend on MixedModels.jl for its `|` term and `ReMat` machinery, or vendor a minimal `|` term. Recommendation: vendor minimal (avoid the heavy dep and its solver assumptions); revisit if parity demands grow.

---

## 3. Random slopes: the headline. Math + engine wiring

This is the core deliverable. We are concrete about both the statistics and where it plugs into each likelihood path.

### 3.1 The model augmentation

A term `(1 + x | group)` adds, to the linear predictor for observation (species `t`, site `s`), a **random coefficient** drawn per group level:

For grouping factor `g` with levels `1..L` (e.g. `group = site`, so `L = n`), and within-group covariate vector `z_s = [1, x_s]` (length `r = 2`):

```
η_{ts}  +=  z_sᵀ b_{t, g(s)}
```

where `b_{t,ℓ} ∈ ℝ^r` is the random coefficient for species `t` in group `ℓ`, and

```
b_{t,ℓ}  ~  N(0, G_t),        G_t = r×r covariance   (correlated, `|`)
                              G_t = diag(τ²_{t,1},…)  (uncorrelated, `||`)
```

**Per-species vs shared covariance — a real modelling choice (flag for maintainer):**
- **(A) Species-specific** `G_t` (each species has its own intercept/slope covariance): the natural GLLVM generalisation, matches how `σ²_B`/`σ²_W`/`σ_phy` are per-trait. Parameter count `~ p · r(r+1)/2`. This is the recommended default.
- **(B) Shared** `G` across species (one covariance, species share the random-coefficient distribution): far fewer parameters, closer to a classic mixed model. Cheaper, more identifiable at small `n`.

The spec recommends starting with **(A) per-species, with the slope's group = site being the common case**, because it slots into the existing per-trait diagonal-RE machinery and the Gaussian closed form (§3.3). (B) is a documented option for the plan.

### 3.2 Where it enters — the marginal likelihood

Random slopes are *integrated out* like every other RE. The key question is whether the integral stays closed-form (Gaussian) or needs Laplace (non-Gaussian).

**Gaussian + group = site (the tractable, headline-recovery case).**
Because `z_s` is fixed and `b_{t,ℓ}` is Gaussian, the contribution `z_sᵀ b_{t,g(s)}` is Gaussian and the marginal over `y` stays closed-form. Two sub-cases by what `group` is:

- **`group = site`** (each site is its own level, `g(s) = s`, `L = n`): then `b_{t,s}` is independent across sites, and the random-slope contribution is *independent per site*. Its marginal contribution to the **per-site** covariance `Σ_y_site` is, for species pair (t, t′):
  ```
  Cov(z_sᵀ b_{t,s}, z_sᵀ b_{t′,s})  =  z_sᵀ Cov(b_{t,s}, b_{t′,s}) z_s
  ```
  Under per-species independent `G_t` (option A, blocks independent across species) this is `z_sᵀ G_t z_s` on the diagonal (t = t′) and `0` off-diagonal — i.e. it adds a **site-dependent, per-trait diagonal term** `d_slope[t, s] = z_sᵀ G_t z_s` to `d_total`. This is *almost* the existing `σ²_B` machinery, except the diagonal now varies with `s` through `z_s`. **Engine change:** `gaussian_marginal_loglik`'s `d_total` (currently a length-`p` vector, `src/likelihood.jl:156–172`) must become *site-dependent* `d_total[:, s]` when a site-grouped random-slope block is present. The Woodbury path already inverts `A = Λ_B Λ_Bᵀ + diag(d_total)` per site conceptually; making `D` vary per site means recomputing the rank-`K` capacitance `I + Λ_Bᵀ D_s⁻¹ Λ_B` per site (cost `O(n·(pK² + K³))` instead of amortised). This is the concrete, bounded engine edit.

- **`group` coarser than site** (e.g. `region`, several sites share a level): then `b_{t,ℓ}` is shared across the sites in level `ℓ`, inducing **between-site covariance** within a region. This breaks the "independent per site" structure and pulls the model into the *same* algebraic regime as the phylogenetic block (`Σ_y_full = I_n ⊗ A + (block structure) ⊗ …`). This is materially harder and is **deferred** past the first slice (flagged in §5). The first random-slope slice targets `group = site`.

**Non-Gaussian (Laplace).**
The random coefficients `b` join the latent vector that the Laplace mode-finder integrates. The inner objective per group becomes
```
ℓ(z, b) − ½ zᵀz − ½ Σ_ℓ b_ℓᵀ G⁻¹ b_ℓ
```
and the Laplace approximation expands to the joint mode `(ẑ, b̂)` with the block Hessian `[Λ'WΛ+I, Λ'WZ; Z'WΛ, Z'WZ+G⁻¹]`. **But** this requires the Laplace core to (1) accept an `Xβ` term (it currently does not — see §0) and (2) accept a `Z`/`G` random-coefficient block. Both are new. This is why non-Gaussian random slopes are a *later* slice than Gaussian.

### 3.3 Worked mapping for the headline case

`@formula(y ~ 1 + temp + (1 + temp | site))`, Gaussian, `group = site`, per-species `G_t` (2×2):

1. **Fixed part** → `X[t, s, :] = [1, temp_s]` (broadcast site covariate across species), `β ∈ ℝ²`.
2. **Random part** → `ReBlock(group_name=:site, group=1:n, n_levels=n, Z=[1 temp_s], coef_names=["(Intercept)","temp"], correlated=true)`.
3. **Engine parameters added:** for each species `t`, a 2×2 SPD `G_t`, parameterised by its Cholesky (3 free params: `log τ₁, log τ₂, ρ` via a tanh or unconstrained lower-triangular). Total `3p` new optimisation parameters.
4. **Likelihood:** `d_total[t, s] = σ²_eps + (Λ_W Λ_Wᵀ)[t,t] + σ²_B[t] + σ²_W[t] + z_sᵀ G_t z_s`, with `z_s = [1, temp_s]`. The per-site Woodbury proceeds with this site-varying diagonal.
5. **Recovery target:** simulate from known `G_t` (e.g. intercept SD 0.8, slope SD 0.3, ρ = −0.4) and recover within Monte-Carlo tolerance (§5).

### 3.4 BLUPs (fast-follow, not in the first slice)
The conditional means `b̂_{t,ℓ}` are the random-slope BLUPs — analogous to how `em_phylo.jl` conditional means double as ancestral-state BLUPs. The post-fit API (`getLV`/`getLoadings` track) would gain a `ranef(fit)` extractor. Out of scope for the parse+fit slices; noted so the IR carries enough to compute them later.

---

## 4. The wide↔long round-trip (identity-preserving)

### 4.1 The canonical transform

Define `melt` and `cast`:
- `melt(Y, site_data, trait_data)` → long frame with columns `[response, species, site, <site covariates repeated>, <trait covariates repeated>]`, `n·p` rows, in **column-major (species-fastest) order** to match Julia/`vec(Y)`.
- `cast(long, response=:y, species=:species, site=:site)` → `(Y::p×n, site_data::n-row, trait_data::p-row)` by pivoting.

**Round-trip identity (the contract):** `cast(melt(W)) == W` and `melt(cast(L)) == L` up to the recorded level orderings. The IR stores `species_levels`/`site_levels` so the permutation is explicit and reversible.

### 4.2 Where the two doors converge
Both `parse(formula, wide…)` and `parse(formula, long…)` must yield the same `GllvmFormulaIR` (§2.2). Concretely:
- The long parser groups by `(species, site)`, sorts to canonical order, and reshapes `response` → `Y` (`p × n`). Site covariates are recovered by taking the unique value per site (and *validated* to be constant within site, §4.3). Trait covariates likewise per species.
- The wide parser builds `Y` directly and resolves covariates from `site_data`/`trait_data`.
- **Test:** for a fixture, assert `parse(f, wide).X == parse(f, long).X`, same for every IR field (modulo permutation). This is the headline round-trip goal (§5).

### 4.3 Edge cases (must be handled or clearly errored)
1. **Ragged / missing cells** — long data missing some (species, site) rows. Wide data has every cell. Options: error (require complete grid), or support `missing` in `Y` (the engine currently assumes a full `p × n` matrix → *error for v1*, with a clear message; missingness is a separate capability).
2. **Site covariate not constant within site** (long mode) — e.g. `temp` differs across rows that share a `site`. This is a *user error* in wide-style modelling; detect and error (don't silently average).
3. **Covariate axis ambiguity** — a covariate present in both `site_data` and `trait_data`, or a long column that varies in both axes (a genuine fourth-corner covariate). The IR must classify each covariate as site-varying, species-varying, or both; ambiguity → require explicit `traits(...)` wrapping.
4. **Factor level ordering** — wide column order vs long sort order must agree; the IR's `species_levels`/`site_levels` are the single source of truth, and `Y` is always materialised in that order.
5. **Empty groups** — a grouping level with no observations (long) → drop with a warning; renumber levels.
6. **`response` type vs family** — counts for Poisson must be integer; the parser validates against the family (mirrors `fit_binomial_gllvm`'s `<:Integer` signature).
7. **Single-species or single-site** — degenerate; error (the engine needs `n ≥ p`, `src/fit.jl:123`).

---

## 5. Slice plan with verifiable goals

Each slice is an independent branch → PR → CI/Documenter → merge, per the repo rhythm. Goals are stated as tests *before* code (Karpathy/Curie discipline). **Slices 1–4 are the front-end; slices 5–7 are the engine work random slopes require; slice 8 wires them.**

| # | Slice | Verifiable goal (the test) | Depends on |
| --- | --- | --- | --- |
| 1 | **Deps + skeleton.** Add `StatsModels`, `Tables` to `Project.toml`; define `GllvmFormulaIR`, `ReBlock`; stub custom terms. | Package loads; Aqua/JET clean; `@formula(y ~ 1 + x)` parses to a `FormulaTerm` (no engine call yet). | — |
| 2 | **Fixed-effects parse → `X` (wide).** `traits()`, `latent()` terms; broadcast 2-D design to `(p,n,q)`. | `parse(@formula(y ~ 1+temp), Y, site_data).X` equals a hand-built `(p,n,2)` array to `1e-12`; `gllvm(formula, …)` reproduces `fit_gaussian_gllvm(Y; X=…)` logLik to `1e-10`. | 1 |
| 3 | **Long parser + round-trip.** `melt`/`cast`; long→IR. | **Round-trip identity:** `cast(melt(W)) == W`; `parse(f, wide).X == parse(f, long).X` for every IR field (the headline §4 goal). Edge-case errors (§4.3) each have a test. | 2 |
| 4 | **`phylo()` term.** Route `Σ_phy`/`K_phy`/`has_phy_unique` from the formula. | `gllvm(@formula(y ~ 1+temp+phylo()), …; Σ_phy=…)` reproduces the matrix-level phylo fit logLik to `1e-10`. | 2 |
| 5 | **(ENGINE) Site-varying `d_total` in the Gaussian kernel.** Generalise `gaussian_marginal_loglik`'s `d_total` vector → `d_total[:, s]` when present; keep the length-`p` fast path when absent. | Existing 256 tests still pass (no regression on the constant-`d` path, exact equality); a new test with a hand-set site-varying `D` matches a dense `logpdf(MvNormal)` reference per site to `1e-9`. | — (parallel to 1–4) |
| 6 | **(ENGINE, NON-GAUSSIAN PREREQ) `Xβ` in the Laplace core.** Add an `X`/`β` fixed-effect term to `src/families/laplace.jl` and the family fitters. | A Poisson fit with a known `β` recovers it; logLik matches a hand-coded Laplace with the offset folded into `β_t`. **This is the §0 blocking gap.** | — |
| 7 | **(ENGINE) Random-coefficient block — Gaussian, `group=site`.** Add `ReBlock` consumption to the Gaussian fit: per-species `G_t`, contributing `z_sᵀ G_t z_s` to `d_total[t,s]`; Cholesky parameterisation of `G_t`. | **Random-slope recovery:** simulate from known `G_t` (intercept SD 0.8, slope SD 0.3, ρ=−0.4, `p=8`, `n=200`, 200 reps) → estimates within MC tolerance (bias < 2 MCSE); SPD `Ĝ_t`; correlated vs `||` (diagonal) both recover. | 5 |
| 8 | **Wire formula → random-slope engine.** `(1 + x \| site)` in the formula drives slice-7 `ReBlock`s end-to-end; `gllvm(formula)` fits. | `gllvm(@formula(y ~ 1+temp+(1+temp\|site)), data)` recovers the slice-7 `G_t` from the *formula* path; wide and long give identical fits. | 3, 7 |
| 9 | **(STRETCH) Non-Gaussian random slopes; `ranef()`; coarse grouping.** Laplace joint mode over `(z,b)`; BLUP extractor; `group` coarser than site. | Poisson `(1+x\|site)` recovery; `ranef(fit)` matches simulated `b`; documented identifiability caveats. | 6, 7, 8 |

**Sequencing note:** slices 1–6 can proceed in parallel lanes (front-end vs engine), as they touch disjoint files (`src/formula*.jl` vs `src/likelihood.jl`/`src/families/laplace.jl`). Slice 8 is the join. This matches the repo's parallel-agent, disjoint-file discipline.

---

## 6. Dependencies, honest size, and what it unblocks

### 6.1 New dependencies
- **Direct:** `StatsModels`, `Tables` (+ transitively `CategoricalArrays`, `DataAPI`). `StatsAPI` already transitively present.
- **Decision (flagged):** whether to depend on **MixedModels.jl** for its `|`-term + `ReMat` machinery, or vendor a minimal `|` term (~200 lines). Recommendation: **vendor minimal** to avoid the heavy dependency and its solver assumptions; the IR needs only the parsed `(slopes | group)` structure, not MixedModels' fitting stack.
- A `Project.toml`/compat change of this kind is an **API-surface change → maintainer approval required** (AGENTS.md "Merge authority"; also touches the formula grammar, doubly gated).

### 6.2 Honest size estimate

**This is a large subsystem — the largest single track on the roadmap.** Candidly:

- **Front-end (slices 1–4):** medium. StatsModels does the heavy lifting; the work is the custom terms (`traits`/`phylo`/`latent`), the 2-D→3-D `X` broadcast, and the wide↔long machinery with its edge cases. Estimate: ~4 well-scoped slices, each a few hundred lines of `src/` + tests. The wide↔long round-trip and the fourth-corner (`temp & traits()`) generality are the subtle parts.
- **Engine for random slopes (slices 5–7):** medium-to-large, and **the real cost**. Slice 5 (site-varying `d_total`) is bounded but touches the hottest kernel and its AD path — must preserve the 256-test exactness and the ForwardDiff compatibility. Slice 6 (`Xβ` in Laplace) is a genuine new capability the package lacks today and is a hard prerequisite for *any* non-Gaussian covariate modelling, not just slopes. Slice 7 (the `G_t` block + Cholesky parameterisation + recovery validation) is new statistical machinery with identifiability work.
- **Stretch (slice 9):** large and open-ended (Laplace joint mode, coarse grouping = phylo-like algebra, BLUPs). Explicitly *not* committed.

**Overall:** a multi-slice, multi-persona effort (Boole + Gauss + Fisher + Curie + Hopper). Not a single PR. The front-end alone is shippable and useful (it makes the *existing* Gaussian/phylo engine ergonomic) **before** any random-slope engine work lands — so the plan should ship slices 1–4 first for immediate value, then take the engine slices 5–8 as the random-slope deliverable.

### 6.3 What it unblocks
- **The R-bridge `engine="julia"` path** (the maintainer's stated vision): an R `gllvmTMB` call can hand its parsed model + data to GLLVM.jl over the bridge *only if* GLLVM.jl accepts a formula+data interface that mirrors R's. This spec is that interface. Without it, the bridge can only pass pre-built matrices, which defeats the "drop-in faster engine" goal.
- **Tutorials at parity with gllvmTMB** (roadmap v0.3.0): every gllvmTMB tutorial is written in formula syntax; we cannot mirror them without this.
- **Post-fit `newdata` prediction** (deferred in the post-fit spec, `2026-05-31-postfit-api-design.md` §3): `predict(fit, newdata)` needs the formula to rebuild `X` for new sites. This spec supplies that.
- **`anova`/LRT model selection:** comparing nested formulae needs the formula front-end to define "nested".

---

## 7. Locked decisions vs open questions

**Proposed locks (for maintainer ratification):**
1. Build on **StatsModels.jl + Tables.jl**; **vendor** a minimal `|` term rather than depend on MixedModels.jl.
2. Both wide and long lower to one `GllvmFormulaIR`; **round-trip identity is a tested contract.**
3. Random-slope first target: **Gaussian, `group = site`, per-species `G_t`** (option A). Coarse grouping and non-Gaussian deferred.
4. `traits()`, `phylo()`, `latent()` are **StatsModels custom terms**; full gllvmTMB parity (nested/crossed grouping, `disp.formula`) is **out of v1 scope** and must error clearly.
5. Missing (species, site) cells → **error for v1** (no `missing` in `Y` yet).
6. Ship **front-end (slices 1–4) before random-slope engine (5–8)** for incremental value.

**Open questions for the maintainer:**
- **Per-species vs shared `G`** (§3.1 A vs B): default A, but B is cheaper/more identifiable at small `n` — confirm A.
- **MixedModels.jl dep vs vendored `|`** — confirm vendoring (the cost/parity trade).
- **`traits()` scope:** include the fourth-corner interaction (`temp & traits()`) in the first front-end slice, or defer the interaction and ship only bare `traits()` broadcasting first? (Recommend: include — it is the term that justifies the 3-D `X` and is core gllvmTMB.)
- **Coarse grouping priority:** is `(1 + x | region)` (between-site covariance) needed early, or is `group = site` sufficient for the headline? (Recommend: site-only first; coarse grouping is a phylo-magnitude follow-on.)

---

## Appendix A — engine API contract this spec targets (verified against source)

- `fit_gaussian_gllvm(y; K, K_W, has_diag, K_phy, has_phy_unique, Σ_phy, X, …)` — `src/fit.jl:99`. `X::Array{<:Real,3}` is `(p, n_sites, q)`; `β` length `q` (`src/fit.jl:137–143`).
- `gaussian_marginal_loglik(y, Λ_B, σ_eps; X, β, Λ_W, σ²_B, σ²_W, Λ_phy, σ_phy, Σ_phy)` — `src/likelihood.jl:73`. `d_total` is a length-`p` vector (`:156–172`); §5 slice 5 generalises it to site-varying.
- `fit_gllvm(Y; family, K, kwargs...)` family dispatch — `src/families/fit_gllvm.jl:26`.
- Laplace core `laplace_loglik_site(family, y, n, Λ, β, link; …)` — `src/families/laplace.jl`. Linear predictor `η = β_t + (Λ z_s)_t`; **no `X` term** (§0, §5 slice 6).
- Packing `pack_lambda`/`unpack_lambda`/`rr_theta_len` — `src/packing.jl`. The `G_t` Cholesky parameterisation (§3.3) reuses this lower-triangular convention.
- Persona ownership: **Boole** (`StatsModels`/`@formula`/grammar), **Gauss** (kernel edits), per `AGENTS.md:70` and `:65`.
