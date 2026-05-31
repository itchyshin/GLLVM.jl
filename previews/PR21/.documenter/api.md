
# API reference {#API-reference}

The full public API surface, picked up automatically from docstrings on exported functions, types, and modules. As docstrings are added to the public functions during the integration pass this page populates without further edits.
<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.augmented_phy-Tuple{AbstractString}' href='#GLLVM.augmented_phy-Tuple{AbstractString}'><span class="jlbinding">GLLVM.augmented_phy</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
augmented_phy(newick::AbstractString) :: AugmentedPhy{Float64}
```


Parse a minimal Newick string and return the augmented-state sparse precision representation.

**Restrictions**
- Binary (bifurcating) trees only — every internal node has exactly two children. Multifurcations and unary nodes are rejected.
  
- Leaf names follow `[A-Za-z0-9_.\-]+`. Internal node labels are tolerated but discarded.
  
- Branch lengths must all be &gt; 0 (otherwise 1/b blows up).
  
- The root has no parent branch; the optional root length in `(…):0.0;` is read but does not enter Q.
  

**Example**

```julia
phy = augmented_phy("((A:0.1,B:0.2):0.3,C:0.5);")
phy.n_leaves      # 3
phy.n_total       # 5  (3 leaves + 2 internal)
length(phy.branch_lengths)   # 4
nnz(phy.Q_topology)          # 16  (4 per edge × 4 edges)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy.jl#L196-L221" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.binomial_marginal_loglik_laplace-Tuple{AbstractMatrix, AbstractMatrix, AbstractMatrix, AbstractVector, GLLVM.Link}' href='#GLLVM.binomial_marginal_loglik_laplace-Tuple{AbstractMatrix, AbstractMatrix, AbstractMatrix, AbstractVector, GLLVM.Link}'><span class="jlbinding">GLLVM.binomial_marginal_loglik_laplace</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
binomial_marginal_loglik_laplace(Y, N, Λ, β, link; kwargs...) -> Float64
```


Total Laplace log-marginal over the `n` sites of a Binomial GLLVM. `Y`, `N` are p×n response and trial-count matrices; `Λ` p×K; `β` length-p; `link` a `Link`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/binomial.jl#L58-L63" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.bootstrap_ci-Tuple{GllvmFit}' href='#GLLVM.bootstrap_ci-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.bootstrap_ci</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
bootstrap_ci(fit::GllvmFit;
             n_boot = 100,
             level = 0.95,
             seed = 0,
             y = nothing,
             n_sites = nothing,
             X = nothing,
             Σ_phy = nothing,
             parms = nothing,
             verbose = false)
    -> NamedTuple
```


Parametric bootstrap CIs for the fitted parameters in `fit`. Returns a NamedTuple with fields:
- `term::Vector{String}`         — parameter names (θ_packed order)
  
- `estimate::Vector{Float64}`    — original MLE (`fit.pars.θ_packed`)
  
- `lower::Vector{Float64}`       — percentile `100·(1-level)/2`
  
- `upper::Vector{Float64}`       — percentile `100·(1+level)/2`
  
- `n_converged::Int`             — number of bootstrap fits that converged
  
- `replicates::Matrix{Float64}`  — `n_boot × n_params` matrix of bootstrap θ̂_b
  

`n_sites` is required because `GllvmFit` does not record it. Supply either `n_sites` directly, or pass the original `y` (or `X`) — the function infers `n_sites` from `size(y, 2)` or `size(X, 2)`.

`X` and `Σ_phy` must be supplied when the original fit had fixed effects (`q > 0`) or a phylogenetic block (`K_phy > 0` or `has_phy_unique`). Otherwise the bootstrap model spec would not match the fitted spec.

`parms` selects a subset of returned terms (default `nothing` = all). Accepts a `String` (single term name) or `Vector{String}`.

`n_boot` defaults to 100; publication-grade is 500–2000.

**Algorithm**
1. Reconstruct Σ̂_y at the fitted parameters (`Λ̂ Λ̂' + diag(d_total)`, plus the phy block when present).
  
2. For b = 1..n_boot:
  - Simulate y_b ~ N(μ̂, Σ̂_y) using a Cholesky factor of Σ̂_y_site (independent across sites for J1 / J2; J3 adds species-shared phylogenetic contributions).
    
  - Refit via `fit_gaussian_gllvm(y_b; K, K_W, has_diag, K_phy, has_phy_unique, Σ_phy, X)` so the bootstrap model matches the original spec.
    
  - Record the resulting θ_packed and convergence flag.
    
  
3. Compute percentile CIs over the non-NaN replicates per parameter.
  

Replicates whose refit errors out are recorded as `NaN` (and excluded from the percentile calculation); a parameter with fewer than 10 converged replicates returns `NaN` bounds.

**Example**

```julia
fit = fit_gaussian_gllvm(y; K = 1)
ci  = bootstrap_ci(fit; y = y, n_boot = 200, seed = 42)
ci.term      # parameter names
ci.lower     # 2.5% percentile bounds
ci.upper     # 97.5% percentile bounds
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_bootstrap.jl#L193-L256" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.bootstrap_ci_derived-Tuple{GllvmFit, Function}' href='#GLLVM.bootstrap_ci_derived-Tuple{GllvmFit, Function}'><span class="jlbinding">GLLVM.bootstrap_ci_derived</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
bootstrap_ci_derived(fit::GllvmFit, derived_fn::Function;
                     n_boot = 500, seed = 0, level = 0.95,
                     y = nothing, n_sites = nothing,
                     X = nothing, Σ_phy = nothing,
                     verbose = false)
    -> NamedTuple
```


Parametric bootstrap percentile CI for a scalar-valued _derived quantity_ of a fitted Gaussian GLLVM. Wraps the parametric bootstrap in src/confint_bootstrap.jl: simulate y_b ~ N(μ̂, Σ̂_y) for b = 1..n_boot, refit, evaluate `derived_fn` on each replicate, return percentile CIs.

`derived_fn` is called as `derived_fn(fit_b)` first and, if that errors with a `MethodError`, as `derived_fn(fit_b.pars.θ_packed)`. Either form is fine — pick the more convenient.

Returns a NamedTuple with fields:
- `estimate::Float64`      — the derived quantity at the original MLE
  
- `lower::Float64`         — percentile `100·(1-level)/2`
  
- `upper::Float64`         — percentile `100·(1+level)/2`
  
- `n_converged::Int`       — number of bootstrap fits that converged
  
- `n_valid::Int`           — number of replicates with a finite derived value
  
- `replicates::Vector{Float64}` — the n_boot derived-quantity samples                                 (with `NaN` for failed refits)
  

Pass `y`, `X`, `Σ_phy` matching what was originally passed to `fit_gaussian_gllvm` (the bootstrap needs them to simulate and refit).

`n_boot` defaults to 500 — publication-grade. Lower (e.g. 100) for quick checks. The cost is `n_boot × per-fit time`; PERF+I already optimised the per-fit path.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L443-L475" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.build_node_perspecies-Tuple{GLLVM.AugmentedPhy{Float64}, AbstractVector, Real}' href='#GLLVM.build_node_perspecies-Tuple{GLLVM.AugmentedPhy{Float64}, AbstractVector, Real}'><span class="jlbinding">GLLVM.build_node_perspecies</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
build_node_perspecies(phy::AugmentedPhy{Float64}, σ_phy, σ²_eps) -> NodePerSpecies
```


Assemble a `NodePerSpecies` solver for the matched single-trait per-species model. `σ_phy` is the length-`p` per-tip phylogenetic SD (with `σ²_phy` folded in); `σ²_eps` is the residual variance. Builds the root-dropped tree precision `Q_cond`, the augmented node precision `Λ̃ = Q_cond + σ_eps⁻² S' diag(σ_phy²) S`, and their sparse Cholesky factors (O(p) on a tree).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/node_gradient.jl#L276-L284" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.build_sparse_phy_state-Tuple{AbstractMatrix, AbstractMatrix, Real}' href='#GLLVM.build_sparse_phy_state-Tuple{AbstractMatrix, AbstractMatrix, Real}'><span class="jlbinding">GLLVM.build_sparse_phy_state</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
build_sparse_phy_state(y, Λ_B, σ_eps; Λ_phy, σ_phy, phy, σ²_phy)
```


Assemble the augmented-state sparse machinery for the STANDARD phylogenetic GLLVM (no W tier, no per-trait diagonal REs, scalar `σ²_phy`). Mirrors the construction in `likelihood_sparse_phy.jl` and is shared between the value (`sparse_phy_value`) and the analytic gradient (`sparse_phy_grad`).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy_grad.jl#L130-L137" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.communality-Tuple{GllvmFit}' href='#GLLVM.communality-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.communality</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
communality(fit::GllvmFit) -> Vector
```


Per-trait communality `c²[t] = (Λ_B Λ_B')[t, t] / Σ_y_site[t, t]`. This is the fraction of the per-site trait variance explained by the shared latent factors. Values are in [0, 1].


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L196-L202" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.confint-Tuple{GllvmFit}' href='#GLLVM.confint-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.confint</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
confint(fit::GllvmFit; level=0.95, parm=nothing,
        y=nothing, X=nothing, Σ_phy=nothing) -> NamedTuple
```


Wald confidence intervals for the parameters of a fitted Gaussian GLLVM. Returns a NamedTuple with fields:
- `term::Vector{String}`     — parameter names
  
- `estimate::Vector{Float64}` — point estimates (raw scale for SDs)
  
- `lower::Vector{Float64}`    — lower CI bound at `level`
  
- `upper::Vector{Float64}`    — upper CI bound at `level`
  
- `se::Vector{Float64}`       — standard errors (working scale)
  
- `pd_hessian::Bool`          — whether the observed information matrix                               was positive definite at the MLE
  

`level` is the nominal coverage (default 0.95 → two-sided 95% CI).

`parm` selects a subset of parameters by name. Acceptable forms:
- `nothing` (default) — all parameters
  
- `"sigma_eps"` — single name
  
- `"Lambda"` — all Λ entries across all tiers (B, W, phy)
  
- `"Lambda:1,1"` — shorthand for `"Lambda_B[1,1]"`
  
- `["sigma_eps", "Lambda:1,1"]` — mixed list
  

Working-scale convention: σ_eps, σ_B, σ_W are parameterised on the log scale internally. The CI bounds returned for those entries are on the _raw_ (positive) scale via `exp(log_θ ± z * SE_log)`. σ_phy uses an identity (signed) link — its Wald CI is the plain `θ̂ ± z * SE`. β and Λ entries are reported on their native (linear) scale.

The Hessian is computed via ForwardDiff at the fitted parameter vector stored on `fit.pars.θ_packed`. The function needs the original data matrix `y` (and optionally `X`, `Σ_phy`) to reconstruct the NLL closure. If the Hessian is not positive definite, this function returns NaN bounds for the affected entries with `pd_hessian = false` (matching the R glmmTMB / gllvmTMB convention).

When PERF lands with reverse-mode AD, the integration agent can swap the ForwardDiff.hessian call for the faster path; the public API stays stable.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint.jl#L196-L236" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.correlation-Tuple{GllvmFit}' href='#GLLVM.correlation-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.correlation</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
correlation(fit::GllvmFit) -> Matrix
```


Cross-trait correlation derived from `Σ_y_site`: `ρ[i, j] = Σ_y_site[i, j] / sqrt(Σ_y_site[i, i] · Σ_y_site[j, j])`.

Diagonal entries are exactly 1.0. The off-diagonals are the _site-level_ correlations driven by the shared loadings Λ_B.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L266-L274" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.default_link-Tuple{Distributions.Normal}' href='#GLLVM.default_link-Tuple{Distributions.Normal}'><span class="jlbinding">GLLVM.default_link</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
default_link(family) -> Link
```


Canonical link for a response family: identity for `Normal`, logit for `Binomial`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/links.jl#L47-L52" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.em_fa-Tuple{AbstractMatrix, Integer}' href='#GLLVM.em_fa-Tuple{AbstractMatrix, Integer}'><span class="jlbinding">GLLVM.em_fa</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
em_fa(y::AbstractMatrix, K::Integer;
      λ_init = nothing, ψ_init = nothing,
      tol = 1e-8, max_iter = 500)
    -> (Λ, ψ, loglik, n_iter, converged)
```


EM for factor analysis. `y` is (p, n). Returns Λ (p × K), ψ (p-vector of positive idiosyncratic variances), final log-likelihood, iteration count, and convergence flag.

E-step (per observation s):     β = Λ'(ΛΛ' + Ψ)⁻¹                        (K × p, via Woodbury)     E[η_s | y_s]      = β y_s     E[η_s η_s' | y_s] = I − β Λ + β y_s y_s' β'

M-step (aggregated over s = 1, …, n):     S_yy = Y Y'                              (p × p)     S_yη = S_yy β'                            (p × K)     S_ηη = n (I − β Λ) + β S_yy β'            (K × K)     Λ_new = S_yη S_ηη⁻¹     ψ_new = diag(S_yy − Λ_new S_yη') / n

Both updates are closed-form. The log-likelihood is evaluated via Woodbury at the start of each iteration (i.e. at the parameters produced by the previous M-step) so monotone non-decrease is testable.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/em_fa.jl#L11-L36" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.fit_binomial_gllvm-Tuple{AbstractMatrix{<:Integer}}' href='#GLLVM.fit_binomial_gllvm-Tuple{AbstractMatrix{<:Integer}}'><span class="jlbinding">GLLVM.fit_binomial_gllvm</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
fit_binomial_gllvm(Y; K, link=LogitLink(), N=nothing, …) -> BinomialFit
```


Fit a Binomial GLLVM by L-BFGS on the Laplace marginal log-likelihood (`binomial_marginal_loglik_laplace`). `Y` is a p×n integer response matrix (responses × sites); `N` the matching trial counts (default all-ones, i.e. Bernoulli / binary). `K` is the latent dimension. Optimises the intercepts `β` and loadings `Λ`.

The L-BFGS gradient is finite-difference: the Laplace inner mode-finder is not forward-AD-friendly, so this keeps the first driver simple and robust (an envelope-theorem analytic gradient is the planned optimisation). Warm start: empirical link-scale intercepts + an SVD (PPCA-style) loadings init.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/binomial.jl#L100-L113" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.fit_gaussian_gllvm-Tuple{AbstractMatrix}' href='#GLLVM.fit_gaussian_gllvm-Tuple{AbstractMatrix}'><span class="jlbinding">GLLVM.fit_gaussian_gllvm</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
fit_gaussian_gllvm(y; K, K_W=0, has_diag=false, K_phy=0,
                   has_phy_unique=false, Σ_phy=nothing, X=nothing,
                   σ_eps_init=1.0, λ_init=nothing, λ_W_init=nothing,
                   λ_phy_init=nothing,
                   σ²_B_init=0.1, σ²_W_init=0.1, σ_phy_init=0.1,
                   β_init=nothing, x_tol=1e-8, f_tol=1e-10,
                   g_tol=1e-6, iterations=500) -> GllvmFit
```


L-BFGS minimisation of the closed-form Gaussian marginal NLL via ForwardDiff gradients. Returns a `GllvmFit` with parameter estimates, convergence diagnostics, and wall-clock fit time.

Under the hood the optimisation runs on the profile NLL (σ²_eps and optionally β profiled out analytically, MixedModels.jl-style). The public API and parameter recovery semantics are unchanged.

J1 behaviour (`K_W = 0`, `has_diag = false`, `X = nothing`, `K_phy = 0`, `has_phy_unique = false`, `Σ_phy = nothing`) is preserved unchanged.

Optional extensions:
- J2-A-WD: `K_W::Integer = 0` (W-tier rank), `has_diag::Bool = false` (per-trait diagonal RE σ²_B, σ²_W).
  
- J3 phylogenetic: `K_phy::Integer = 0` (Λ_phy rank), `has_phy_unique::Bool = false` (per-trait σ_phy), and `Σ_phy::AbstractMatrix` (p × p species covariance, required when `K_phy > 0` or `has_phy_unique`).
  

Optional fixed effects:
- `X::AbstractArray{<:Real, 3}` of shape `(p, n_sites, q)`.
  
- `β_init::AbstractVector` of length q (defaults to `zeros(q)`).
  

The fit's `pars` NamedTuple always contains `(σ_eps, Λ, β, Λ_W, σ²_B, σ²_W, Λ_phy, σ_phy, θ_packed)` where `Λ_W`, `σ²_B`, `σ²_W`, `Λ_phy`, `σ_phy` are `nothing` when the corresponding flag is off.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/fit.jl#L61-L98" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.fit_gllvm-Tuple{AbstractMatrix}' href='#GLLVM.fit_gllvm-Tuple{AbstractMatrix}'><span class="jlbinding">GLLVM.fit_gllvm</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
fit_gllvm(Y; family = Normal(), K, kwargs...)
```


Fit a GLLVM, dispatching on the response `family` — a Distributions.jl distribution used as a marker (the GLM.jl convention):
- `Normal()`   → [`fit_gaussian_gllvm`](/api#GLLVM.fit_gaussian_gllvm-Tuple{AbstractMatrix}) — closed-form Gaussian marginal
  
- `Binomial()` → [`fit_binomial_gllvm`](/api#GLLVM.fit_binomial_gllvm-Tuple{AbstractMatrix{<:Integer}}) — Laplace marginal (binary / binomial)
  

`K` is the latent dimension; family-specific keyword arguments (`link`, `N`, `Σ_phy`, …) pass through to the underlying fitter.

```julia
fit_gllvm(Y; family = Normal(),   K = 2)                      # Gaussian
fit_gllvm(Y; family = Binomial(), K = 2, link = LogitLink())  # binary
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/fit_gllvm.jl#L3-L19" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.fit_phylo_gaussian-Tuple{GLLVM.AugmentedPhy, AbstractVector}' href='#GLLVM.fit_phylo_gaussian-Tuple{GLLVM.AugmentedPhy, AbstractVector}'><span class="jlbinding">GLLVM.fit_phylo_gaussian</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
fit_phylo_gaussian(phy, y; profile_mu=true, μ0, logσ²phy0, logσ²eps0,
                   g_tol=1e-5, iterations=500) -> PhyloGaussianFit
```


Fit the O(p) single-trait single-variance phylogenetic Gaussian model `y ~ N(μ·1, σ²_eps·I + σ²_phy·Σ_phy_unit)` by L-BFGS on the sparse, O(p) marginal negative log-likelihood — where `Σ_phy_unit` is the unit-variance Brownian-motion tip covariance of the tree, never formed densely.

`phy` is an `AugmentedPhy` (from [`augmented_phy`](/api#GLLVM.augmented_phy-Tuple{AbstractString})) or a Newick string; `y` is the length-`p` trait vector in tip order. When `profile_mu` (default), `μ` is profiled out by generalised least squares at every evaluation and only `(σ²_phy, σ²_eps)` are optimised; otherwise all three are optimised jointly. Variances are optimised on the log scale (kept strictly positive). The L-BFGS gradient is finite-difference (CHOLMOD blocks forward-mode AD), which is still O(p) per gradient.

A single exact gradient/likelihood evaluation scales linearly in the number of species `p` (≈0.8 ms at p=10,000), where dense phylogenetic GLLVMs cap near `p ≈ 500`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/fit_phylo.jl#L84-L104" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.gaussian_marginal_loglik-Tuple{AbstractMatrix, AbstractMatrix, Real}' href='#GLLVM.gaussian_marginal_loglik-Tuple{AbstractMatrix, AbstractMatrix, Real}'><span class="jlbinding">GLLVM.gaussian_marginal_loglik</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
gaussian_marginal_loglik(y, Λ_B, σ_eps; X=nothing, β=nothing,
                          Λ_W=nothing, σ²_B=nothing, σ²_W=nothing,
                          Λ_phy=nothing, σ_phy=nothing,
                          Σ_phy=nothing) -> Real
```


Marginal log-likelihood of `y` (size p × n_sites) under the Gaussian GLLVM with unit-tier loadings `Λ_B`(p × K_B), residual SD`σ_eps`, and optional W tier (`Λ_W`, p × K_W) and per-trait diagonal random effects (`σ²_B`,`σ²_W`, length p, positive variances).

The per-trait diagonal contribution is     d_total[t] = (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t] + σ²_eps. Without phylogeny, the site covariance is `A = Λ_B Λ_B' + diag(d_total)`, inverted via Woodbury (cost O(p K_B² + K_B³) per site).

Fixed effects: pass both `X::Array{<:Real, 3}` of shape (p, n_sites, q) and `β::Vector` of length q, or neither.

`Λ_W = nothing`, `σ²_B = nothing`, `σ²_W = nothing` together reproduce the J1 behaviour exactly (D = σ²_eps I).

Phylogenetic extension (`Σ_phy::AbstractMatrix`, p × p, supplied by caller — typically a species-trait covariance derived from a tree):
- `Λ_phy::AbstractMatrix` (p × K_phy): phylo-latent loadings.
  
- `σ_phy::AbstractVector` (length p): per-trait phylo-unique SDs.
  

With Λ_phy_aug = hcat(Λ_phy, σ_phy) the marginal covariance of vec(y) is `I_n ⊗ A + J_n ⊗ B` where `B = (Λ_phy_aug Λ_phy_aug') .* Σ_phy`. The rotation trick (J_n has rank 1) reduces this to two p×p Cholesky factorisations regardless of n.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/likelihood.jl#L42-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.gaussian_marginal_loglik_sparse_phy-Tuple{AbstractMatrix, AbstractMatrix, Real}' href='#GLLVM.gaussian_marginal_loglik_sparse_phy-Tuple{AbstractMatrix, AbstractMatrix, Real}'><span class="jlbinding">GLLVM.gaussian_marginal_loglik_sparse_phy</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
gaussian_marginal_loglik_sparse_phy(y, Λ_B, σ_eps;
    X=nothing, β=nothing,
    Λ_W=nothing, σ²_B=nothing, σ²_W=nothing,
    Λ_phy=nothing, σ_phy=nothing,
    phy::AugmentedPhy, σ²_phy::Real = 1.0)
```


Closed-form Gaussian marginal log-likelihood with the phylogenetic covariance represented in **augmented-state sparse precision** form instead of a dense `Σ_phy`. Numerically equivalent to `gaussian_marginal_loglik(...; Σ_phy = dense)` where `dense` is the explicit `σ²_phy · (S Q_cond⁻¹ S')` corresponding to `phy`, but scales as O(p) thanks to the sparse Cholesky on the augmented precision.

Use this on phylogenies with hundreds to tens of thousands of species, where forming or factorising the dense p × p Σ_phy is prohibitive.

**Evaluation-only (AD limitation)**

This path is **evaluation-only**: CHOLMOD (Julia's sparse Cholesky) does not support `ForwardDiff.Dual` element types, so inputs are cast to `Float64` for the sparse solve. AD-based fitting (`fit_gaussian_gllvm`) must therefore use the dense `gaussian_marginal_loglik` path. The sparse path is intended for likelihood evaluation, simulation, and verification on large trees — not for the optimiser's inner loop.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/likelihood_sparse_phy.jl#L80-L105" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.gaussian_nll_packed-Tuple{AbstractVector, AbstractMatrix, Integer, Integer}' href='#GLLVM.gaussian_nll_packed-Tuple{AbstractVector, AbstractMatrix, Integer, Integer}'><span class="jlbinding">GLLVM.gaussian_nll_packed</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
gaussian_nll_packed(params, y, p, K; X=nothing, q=0) -> Real
```


J1 / J2-A signature (single-tier, optional fixed effects). Parameter layout:
- `params[1:q]`     = β (when `q > 0`)
  
- `params[q + 1]`   = log σ_eps
  
- `params[(q+2):end]` = θ_rr (packed Λ_B, length `rr_theta_len(p, K)`)
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/likelihood.jl#L256-L264" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.gaussian_nll_packed-Tuple{AbstractVector, AbstractMatrix}' href='#GLLVM.gaussian_nll_packed-Tuple{AbstractVector, AbstractMatrix}'><span class="jlbinding">GLLVM.gaussian_nll_packed</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
gaussian_nll_packed(params, y; spec, X=nothing, Σ_phy=nothing) -> Real
```


J2-A-WD / J3 signature carrying a `spec::NamedTuple` with fields `(q, p, K_B, K_W, has_diag)` and optionally `K_phy` and `has_phy_unique` for the phylogenetic block. Parameter layout:

```julia
[β               (spec.q entries)
 log_σ_eps       (1)
 log_σ_B         (p entries if spec.has_diag)
 log_σ_W         (p entries if spec.has_diag)
 θ_rr_B          (rr_theta_len(p, K_B) entries)
 θ_rr_W          (rr_theta_len(p, K_W) entries if spec.K_W > 0)
 σ_phy           (p entries if spec.has_phy_unique, identity link — signed)
 θ_rr_phy        (rr_theta_len(p, K_phy) entries if spec.K_phy > 0)]
```


`X` may be passed as a keyword (required iff `spec.q > 0`). `Σ_phy` (p × p) is required iff `spec.K_phy > 0` or `spec.has_phy_unique`.

For the J1 case `(K_W = 0, has_diag = false)`, the layout collapses to `[β; log_σ_eps; θ_rr_B]` and the result matches the legacy positional method above.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/likelihood.jl#L284-L306" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.gaussian_profile_nll-Tuple{AbstractVector, AbstractMatrix}' href='#GLLVM.gaussian_profile_nll-Tuple{AbstractVector, AbstractMatrix}'><span class="jlbinding">GLLVM.gaussian_profile_nll</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
gaussian_profile_nll(params, y; spec, X=nothing, Σ_phy=nothing,
                     profile_beta=true) -> Real
```


Profile negative log-likelihood. σ²_eps is profiled out analytically; β is profiled out via GLS when `profile_beta=true` and there is no phylogenetic block.

Parameter layout (length = `profile_nparams(spec; profile_beta)`):
- β (spec.q entries if !profile_beta or has_phy_block)
  
- log_τ_B (p entries if spec.has_diag) — τ_B = exp(2·log_τ_B), i.e. ratios σ²_B / σ²_eps on the log-SD scale.
  
- log_τ_W (p entries if spec.has_diag)
  
- θ_rr_B for L_B (rr_theta_len(p, K_B) entries)
  
- θ_rr_W for L_W (rr_theta_len(p, K_W) entries if K_W &gt; 0)
  
- ρ_phy (p entries if has_phy_unique) — identity link, signed.
  
- θ_rr_phy for L_phy (rr_theta_len(p, K_phy) entries if K_phy &gt; 0)
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/profile.jl#L38-L55" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.grad_node_perspecies-Tuple{NodePerSpecies, AbstractVector, Real}' href='#GLLVM.grad_node_perspecies-Tuple{NodePerSpecies, AbstractVector, Real}'><span class="jlbinding">GLLVM.grad_node_perspecies</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
grad_node_perspecies(st::NodePerSpecies, y::AbstractVector, μ::Real) -> Vector{Float64}
```


Per-species gradient `∂negll/∂σ_phy[t]` (length `p`) of the matched single-trait fixed-`μ` phylogenetic model at the data vector `y` (length `p`) and mean `μ`. Each entry is

```julia
g[t] = ½ (trace_t − dataq_t),
trace_t = 2 σ_eps⁻² σ_phy[t] (Λ̃⁻¹)_{leaf(t),leaf(t)},
dataq_t = 2 u_t (Σ_φ Λ_φ u)_t,   u = Σ⁻¹ (y − μ),
```


with the node-diagonal `(Λ̃⁻¹)_{ll}` from `takahashi_diag` (O(nnz L)) and `u` via a Woodbury solve through `Λ̃`. O(p) given the `NodePerSpecies` pre-factorisation. Matches the edge-frame per-species gradient to machine precision while needing only a node diagonal (no ancestor–descendant path-pairs).

Sign convention: returns `∂negll/∂σ_phy` — the gradient of the _negative_ log-likelihood (what an optimiser minimises; consumed by the O(p) single-trait fitter). This is the OPPOSITE sign to [`node_grad`](/api#GLLVM.node_grad-Tuple{GLLVM.SparsePhyState}), whose blocks are `∂loglik/∂θ`. Verified against central FD of `+negll` to `rel < 1e-6`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/node_gradient.jl#L303-L324" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.init_theta_rr-Tuple{Integer, Integer}' href='#GLLVM.init_theta_rr-Tuple{Integer, Integer}'><span class="jlbinding">GLLVM.init_theta_rr</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
init_theta_rr(p::Integer, K::Integer) -> Vector{Float64}
```


Default initial values matching gllvmTMB::init_rr_theta (R/fit-multi.R:1291-1295):
- diagonal entries initialized to 0.5
  
- strict-lower entries initialized to 0
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/packing.jl#L87-L93" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.laplace_loglik_site-Tuple{AbstractVector, AbstractVector, AbstractMatrix, AbstractVector, GLLVM.Link}' href='#GLLVM.laplace_loglik_site-Tuple{AbstractVector, AbstractVector, AbstractMatrix, AbstractVector, GLLVM.Link}'><span class="jlbinding">GLLVM.laplace_loglik_site</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
laplace_loglik_site(y, n, Λ, β, link; maxiter=100, tol=1e-9) -> Float64
```


Laplace-approximated log-marginal for one site. `y`, `n` are the response counts and trial counts (length p); `Λ` is p×K loadings; `β` length-p intercepts; `link` a `Link`. Returns `ℓ(ẑ) − ½ẑ'ẑ − ½logdet(Λ'WΛ + I)`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/binomial.jl#L21-L27" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.leaf_block_inv-Tuple{GLLVM.SparsePhyState}' href='#GLLVM.leaf_block_inv-Tuple{GLLVM.SparsePhyState}'><span class="jlbinding">GLLVM.leaf_block_inv</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
leaf_block_inv(st::SparsePhyState) -> (LB_leaf, cols)
```


Dense (K_aug·p) × (K_aug·p) leaf-row × leaf-col block of `M_sad⁻¹`. `cols` are the augmented-state column indices corresponding to each column of `LB_leaf` (= the leaf positions, axis-stacked). Computed via the Woodbury form `M_sad⁻¹ = Q_eff⁻¹ + α · X_G · S_K⁻¹ · X_G'`, restricted to leaf rows and columns. The leaf-block of `Q_eff⁻¹` is obtained from a single batched CHOLMOD solve against the leaf unit columns (the dominant cost).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy_grad.jl#L339-L348" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.linkfun-Tuple{LogitLink, Any}' href='#GLLVM.linkfun-Tuple{LogitLink, Any}'><span class="jlbinding">GLLVM.linkfun</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
linkfun(link, μ) -> η
```


Link `g`: map the mean `μ` to the linear predictor `η` (used for initialisation).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/links.jl#L37-L41" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.linkinv-Tuple{LogitLink, Any}' href='#GLLVM.linkinv-Tuple{LogitLink, Any}'><span class="jlbinding">GLLVM.linkinv</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
linkinv(link, η) -> μ
```


Inverse link `g⁻¹`: map the linear predictor `η` to the mean `μ`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/links.jl#L16-L20" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.low_rank_chol-Tuple{AbstractMatrix, AbstractVector}' href='#GLLVM.low_rank_chol-Tuple{AbstractMatrix, AbstractVector}'><span class="jlbinding">GLLVM.low_rank_chol</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
low_rank_chol(Λ::AbstractMatrix, d::AbstractVector)
```


Build the [`LowRankPlusDiagChol`](/api#GLLVM.LowRankPlusDiagChol) factorisation of `M = Λ Λ' + Diagonal(d)`.

Promotes `eltype(Λ)` and `eltype(d)` so AD element types (e.g. `ForwardDiff.Dual`) flow through. Constructs the `K × K` capacitance matrix `I_K + Λ' D⁻¹ Λ` and factorises it once.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/lowrank_cholesky.jl#L43-L52" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.make_phy-Tuple{AbstractVector, Integer}' href='#GLLVM.make_phy-Tuple{AbstractVector, Integer}'><span class="jlbinding">GLLVM.make_phy</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
make_phy(edges::AbstractVector{<:Tuple}, n_leaves::Integer;
         root_index::Integer = -1) :: AugmentedPhy{Float64}
```


Convenience constructor: build an `AugmentedPhy` from a list of edges `(parent_id, child_id, branch_length)` with integer node ids 1..n_total (leaves first, internals last is the recommended convention but not required).

If `root_index < 0` it is auto-detected as the unique node that is not a child in any edge.

This bypasses the Newick parser — useful for tests and for trees that arrive from another tool already as edge lists.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy.jl#L302-L316" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.mu_eta-Tuple{LogitLink, Any}' href='#GLLVM.mu_eta-Tuple{LogitLink, Any}'><span class="jlbinding">GLLVM.mu_eta</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
mu_eta(link, η) -> dμ/dη
```


Derivative of the mean with respect to the linear predictor (numerically safe at large |η|).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/links.jl#L26-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.node_blups-Tuple{NodePerSpecies, AbstractVector, Real}' href='#GLLVM.node_blups-Tuple{NodePerSpecies, AbstractVector, Real}'><span class="jlbinding">GLLVM.node_blups</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
node_blups(st::NodePerSpecies, y::AbstractVector, μ::Real) -> (û, ẑ_tip)
```


Ancestral node posterior-mean BLUPs for the matched single-trait model. The node posterior over `u` (non-root augmented nodes) has precision `Λ̃` and mean

```julia
û = Λ̃⁻¹ (σ_eps⁻² S' Λ_φ (y − μ)),
```


and the tip phylo BLUP on the data scale is `ẑ_tip[t] = σ_phy[t] û[leaf(t)]`. Returns `(û, ẑ_tip)` with `û` indexed in the root-dropped node ordering.

CAVEAT. Node-frame posterior-mean BLUPs `û` are exact (≤8e-16 vs the dense reference). Edge-frame branch increments derived by differencing (`û_child − û_parent`) differ from the edge-frame (P2) representation by a `√σ²_phy`-scale convention; do not treat them as P2-equivalent branch BLUPs. See `docs/dev-log/decisions/2026-05-30-node-gradient-5.4e-2-convention.md`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/node_gradient.jl#L353-L369" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.node_dσ_phy_only-Tuple{GLLVM.SparsePhyState}' href='#GLLVM.node_dσ_phy_only-Tuple{GLLVM.SparsePhyState}'><span class="jlbinding">GLLVM.node_dσ_phy_only</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
node_dσ_phy_only(st::SparsePhyState) -> Vector{Float64}
```


Per-species `dσ_phy` block alone (length `p`), sharing the O(p) `cc = C⁻¹m` solve. This is the headline node-diagonal object — the apples-to-apples analogue of the edge-frame per-species gradient — isolated from the global `dΛ_B` / `dσ²_eps` / `dσ²_phy` work for timing and scaling studies.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/node_gradient.jl#L215-L222" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.node_grad-Tuple{GLLVM.SparsePhyState}' href='#GLLVM.node_grad-Tuple{GLLVM.SparsePhyState}'><span class="jlbinding">GLLVM.node_grad</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
node_grad(st::SparsePhyState) -> (; dΛ_B, dσ²_eps, dσ²_phy, dσ_phy)
```


Full NODE-FRAME analytic gradient of the phylo_unique marginal log-likelihood `sparse_phy_value(st)`. Every block is O(p) given a sparse`chol_Q_eff`:`dσ_phy`from the node-diagonal`takahashi_diag` + rank-K_B Woodbury correction; `dσ²_phy` / `dσ²_eps` from the same-leaf Takahashi selected inverse; `dΛ_B` from the engine's low-rank algebra (identical to `sparse_phy_grad`'s `P_A Λ_B` block).

Returns the same gradient as the engine's `sparse_phy_grad` for a phylo_unique state (verified to machine precision, ≤1e-13), but extracts the tree-coupled trace from a NODE DIAGONAL rather than a dense leaf-leaf block, so it stays O(p) on every tree shape (balanced AND caterpillar).

Assumes the phylo_unique configuration (`st.K_aug == 1`): one shared per-trait phylogenetic random effect with SDs`σ_phy = st.Λ_aug[:, 1]`and no separate`Λ_phy` axis.

Evaluation-only for ForwardDiff: the node-diagonal uses a CHOLMOD Float64 factor (see file header).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/node_gradient.jl#L184-L205" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.pack_lambda-Tuple{AbstractMatrix}' href='#GLLVM.pack_lambda-Tuple{AbstractMatrix}'><span class="jlbinding">GLLVM.pack_lambda</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
pack_lambda(Λ::AbstractMatrix) -> AbstractVector
```


Forward pack: given a p × K loading matrix with strict-upper = 0, return the flat θ vector of length rr_theta_len(p, K).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/packing.jl#L66-L71" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.phylo_signal-Tuple{GllvmFit}' href='#GLLVM.phylo_signal-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.phylo_signal</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
phylo_signal(fit::GllvmFit; Σ_phy = nothing) -> Vector
```


Per-trait phylogenetic signal `H²[t] = (Λ_phy_aug Λ_phy_aug')[t, t] · Σ_phy[t, t] / Σ_y_site[t, t]`, where `Λ_phy_aug = hcat(Λ_phy, σ_phy)` (each piece is included only when its flag is on). Returns a vector of length `p`; all entries are `NaN` when the fit has no phylogenetic block (`K_phy == 0` and `has_phy_unique == false`).

`Σ_phy` defaults to the identity matrix (standardised convention, diag == 1 per trait), so the diagonal entries reduce to `H²[t] = (Λ_phy_aug Λ_phy_aug')[t, t] / Σ_y_site[t, t]`. Supply the fitted phylogenetic VCV explicitly when the diagonal is not unit.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L286-L300" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.ppca_init-Tuple{AbstractMatrix, Integer}' href='#GLLVM.ppca_init-Tuple{AbstractMatrix, Integer}'><span class="jlbinding">GLLVM.ppca_init</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ppca_init(y::AbstractMatrix, K::Integer; lower_tri::Bool = true) -> (Λ, σ_eps)
```


Closed-form PPCA initialisation. `y` is (p, n_sites). Returns `Λ` (p × K) and `σ_eps` (positive scalar).

Implements the maximum-likelihood estimator of Tipping & Bishop (1999, eqs. 8-11) for the model `y ~ N(0, Λ Λ' + σ² I)`. Let S = y y' / n, with eigendecomposition S = U Λ_S U' and eigenvalues sorted in descending order. Then

σ̂² = (1/(p - K)) Σ_{k=K+1}^p Λ_S[k]   Λ̂  = U_K (Λ_S[1:K] - σ̂² I)^{1/2}

where U_K is the leading p × K block of U. Negative residual eigenvalues (Λ_S[k] &lt; σ̂² for k ≤ K) are floored at zero, matching the standard PPCA convention.

If `lower_tri = true` (default), rotate Λ so its top K × K block is lower triangular with positive diagonals, matching the engine's packing convention. The rotation is orthogonal, so Λ Λ' (and therefore the model likelihood) is invariant — see `rotate_to_lower_triangular`.

For p ≤ K the closed-form PPCA solution is degenerate (no residual eigenvalues to estimate σ² from); this implementation requires K &lt; p.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/ppca_init.jl#L21-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.profile_ci-Tuple{GllvmFit, AbstractString}' href='#GLLVM.profile_ci-Tuple{GllvmFit, AbstractString}'><span class="jlbinding">GLLVM.profile_ci</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
profile_ci(fit::GllvmFit, parm::AbstractString; kwargs...)
    -> NamedTuple{(:lower, :upper, :method)}
```


Convenience method that looks up `parm` by name (e.g., `"sigma_eps"`, `"Lambda_B[1,1]"`, `"Lambda:1,1"`) and calls the integer-index method.

Naming convention matches `confint(fit)` from src/confint.jl: SDs are reported on the raw (positive) scale, β and Λ on their native scale.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_profile.jl#L467-L476" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.profile_ci-Tuple{GllvmFit, Integer}' href='#GLLVM.profile_ci-Tuple{GllvmFit, Integer}'><span class="jlbinding">GLLVM.profile_ci</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
profile_ci(fit::GllvmFit, param_index::Integer;
           level = 0.95, grid_extent = 5, max_expand = 20,
           max_bisect = 30, y = nothing, X = nothing,
           Σ_phy = nothing)
    -> NamedTuple{(:lower, :upper, :method)}
```


Profile-likelihood CI for the parameter at packed position `param_index` in `fit.pars.θ_packed`.

`grid_extent` controls how far (in Wald SEs from θ̂_i, geometrically expanding) the initial bracket walks before bisection. Larger values help for asymmetric likelihoods; the geometric expansion keeps the total number of refits at O(log) even at large `grid_extent`.

`level` is the nominal coverage (default 0.95 → χ²_1 cutoff ≈ 3.841).

The data matrix `y` (the same `y` passed to `fit_gaussian_gllvm`) must be supplied so this function can reconstruct the NLL closure. `X` and `Σ_phy` are required iff the fit used them.

Returns a NamedTuple with fields:
- `lower::Float64` — lower CI bound on the raw scale for SD-style parameters (σ_eps, σ_B, σ_W, σ_phy), native scale for β / Λ.
  
- `upper::Float64` — upper CI bound, same scale convention.
  
- `method::Symbol` — `:profile` if both bounds were bracketed, `:partial` if only one side was found (the other is NaN), or `:failed` if neither side could be bracketed (both NaN).
  

Failure modes (each side independently):
- The bracket never crosses the chisq cutoff within `max_expand` geometric expansions → that bound is `NaN`.
  
- A constrained refit at a candidate value fails → bracket contracts inward on that side, still typically yielding a finite bound.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_profile.jl#L347-L381" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.profile_ci_derived-Tuple{GllvmFit, Function}' href='#GLLVM.profile_ci_derived-Tuple{GllvmFit, Function}'><span class="jlbinding">GLLVM.profile_ci_derived</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
profile_ci_derived(fit::GllvmFit, derived_fn::Function;
                   level = 0.95, y = nothing,
                   X = nothing, Σ_phy = nothing,
                   penalty_weight = 1e6,
                   initial_step = nothing,
                   max_expand = 20, max_bisect = 30)
    -> NamedTuple{(:lower, :upper, :estimate, :method)}
```


Profile-likelihood CI for a scalar-valued _derived quantity_ `g(θ) = derived_fn(θ_packed)`. The constraint `g(θ) = c` is enforced via a quadratic penalty     `NLL_pen(θ) = NLL(θ) + 0.5 · penalty_weight · (g(θ) − c)²`, re-optimised over θ via LBFGS at each candidate c. The profile log- likelihood at c is the unpenalised NLL evaluated at the constrained minimum θ̂(c); the deviance D(c) = 2(ℓ̂ − ℓ_p(c)) is ~ χ²₁ under g(θ) = c, so the CI is {c : D(c) ≤ qchisq(1−α, 1)}. Bracket-then-bisect on each side.

`derived_fn` must accept a packed-parameter vector and return a scalar (`Float64`). For the built-in derived quantities, use the closure helpers:

```julia
spec = GLLVM._derived_spec(fit)
f_c1 = θ -> GLLVM._communality_packed(θ, spec, 1)
ci   = GLLVM.profile_ci_derived(fit, f_c1; y = y)
```


Or, for σ²_eps (sanity check vs the parameter profile CI on σ_eps):

```julia
f_s2 = θ -> exp(2 * θ[1])    # log_σ_eps is at index 1 when q = 0
```


`penalty_weight` defaults to 1e6 — the _final_ weight at the end of an internal escalating schedule (1e2 → 1e3 → … → `penalty_weight`). The escalation is essential: in phylogenetically active cells, jumping straight to a large w at the warm-start θ̂ inflates the penalty term by O(w · (g(θ̂) − c)²) and pushes LBFGS into pathological regions (the constrained per-site covariance can drift non-PD), producing degenerate CIs. The schedule lets the optimiser move smoothly to the {g ≈ c} manifold first, then tightens. The internal NLL is also wrapped to return a finite barrier on `PosDefException`.

`initial_step` (default `nothing` → `max(0.05 · |g(θ̂)|, 0.01)`) seeds the bracket expansion. Smaller is better here — the geometric expansion inside the bisection grows the step rapidly, while a small first step keeps the very first constrained refit close to θ̂ (where the safe-NLL barrier is rarely triggered).

Returns a NamedTuple with fields:
- `estimate::Float64` — `g(θ̂)` at the original MLE
  
- `lower::Float64`    — lower CI bound (NaN if bracket failed)
  
- `upper::Float64`    — upper CI bound (NaN if bracket failed)
  
- `method::Symbol`    — `:profile` (both bounds), `:partial`                       (one side NaN), or `:failed` (both NaN)
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L829-L886" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.profile_nparams-Tuple{NamedTuple}' href='#GLLVM.profile_nparams-Tuple{NamedTuple}'><span class="jlbinding">GLLVM.profile_nparams</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
profile_nparams(spec; profile_beta=true) -> Int
```


Number of parameters the profile NLL optimises over. Drops σ_eps (always) and β (when `profile_beta && !has_phy`).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/profile.jl#L339-L344" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.profile_recover-Tuple{AbstractVector, AbstractMatrix}' href='#GLLVM.profile_recover-Tuple{AbstractVector, AbstractMatrix}'><span class="jlbinding">GLLVM.profile_recover</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
profile_recover(params, y; spec, X=nothing, Σ_phy=nothing,
                profile_beta=true) -> NamedTuple
```


Run one final NLL pass at `params` and return everything needed to build the user-facing fit:   (logLik, σ_eps, β, Λ_B, Λ_W, σ²_B, σ²_W, Λ_phy, σ_phy)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/profile.jl#L365-L372" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.proportions-Tuple{GllvmFit}' href='#GLLVM.proportions-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.proportions</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
proportions(fit::GllvmFit; component::Symbol = :shared) -> Vector
```


Per-trait variance decomposition. Each entry is in [0, 1]; the `:shared`, `:unique_W`, `:unique_B`, and `:residual` shares sum to 1 (when has_diag and W tier are off, only `:shared` and `:residual` are non-zero).

`component` can be:
- `:shared`    — `(Λ_B Λ_B')[t,t] / Σ_y_site[t,t]`   (== communality)
  
- `:unique_W`  — `(Λ_W Λ_W')[t,t] / Σ_y_site[t,t]`
  
- `:unique_B`  — `σ²_B[t] / Σ_y_site[t,t]`            (J2-A-WD path)
  
- `:unique_Wd` — `σ²_W[t] / Σ_y_site[t,t]`            (J2-A-WD path)
  
- `:residual`  — `σ²_eps / Σ_y_site[t,t]`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L211-L225" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.random_balanced_tree-Tuple{Integer}' href='#GLLVM.random_balanced_tree-Tuple{Integer}'><span class="jlbinding">GLLVM.random_balanced_tree</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
random_balanced_tree(p::Integer; branch_length::Real = 0.1) :: AugmentedPhy
```


Build a near-balanced binary tree with `p` leaves. All branch lengths equal `branch_length`. Used in benchmarks and scaling tests.

When `p` is a power of 2 this is perfectly balanced. Otherwise the left-over leaf at each level is carried up one extra step (so the tree remains binary, just with slightly uneven depths). Branch lengths stay uniform — the goal is a representative sparse-tree topology, not an ultrametric one.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy.jl#L379-L390" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.rotate_to_lower_triangular-Tuple{AbstractMatrix}' href='#GLLVM.rotate_to_lower_triangular-Tuple{AbstractMatrix}'><span class="jlbinding">GLLVM.rotate_to_lower_triangular</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rotate_to_lower_triangular(Λ::AbstractMatrix) -> Matrix
```


Rotate a p × K loading matrix (p ≥ K) so its top K × K block is lower triangular with positive diagonals — the canonical sign / orientation used by the engine's packing convention. The rotation is orthogonal (K × K), so Λ Λ' is preserved and any GLLVM likelihood depending only on Λ Λ' is invariant.

Convention used here: QR-decompose Λ' (a K × p matrix). The thin Q factor is K × K orthogonal; Q'·Λ' is upper-triangular in its first K columns, so Λ·Q has a lower-triangular top K × K block. We then flip the sign of any column whose new diagonal entry is negative, restoring the positive-diagonal sign anchor used by `unpack_lambda`.

Note that this convention determines a sign per column but does NOT fix the overall orientation when Λ Λ' has repeated eigenvalues. In that degenerate case any rotation within the repeated-eigenvalue subspace is equally valid; the QR pivoting choice is implementation- defined.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/ppca_init.jl#L76-L96" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.rr_theta_len-Tuple{Integer, Integer}' href='#GLLVM.rr_theta_len-Tuple{Integer, Integer}'><span class="jlbinding">GLLVM.rr_theta_len</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
rr_theta_len(p::Integer, K::Integer) -> Int
```


Number of parameters needed to pack a p × K lower-triangular loading matrix with zero strict upper triangle.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/packing.jl#L18-L23" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.sigma_phy_dense-Tuple{GLLVM.AugmentedPhy}' href='#GLLVM.sigma_phy_dense-Tuple{GLLVM.AugmentedPhy}'><span class="jlbinding">GLLVM.sigma_phy_dense</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
sigma_phy_dense(phy::AugmentedPhy; σ²_phy::Real = 1.0) :: Matrix
```


Build the dense (p × p) leaf covariance `Σ_phy = σ²_phy · (S Q_cond⁻¹ S')` where `Q_cond` is `phy.Q_topology` with the root row/col removed and `S` selects leaves. This is what the existing dense path expects; used by verification tests to compare sparse vs. dense.

This is **O(p³)** in storage and time — only intended for small trees in tests. Do NOT call it on the real workload; the entire point of `AugmentedPhy` is to avoid materialising Σ_phy.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy.jl#L358-L369" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.sigma_y_site-Tuple{GllvmFit}' href='#GLLVM.sigma_y_site-Tuple{GllvmFit}'><span class="jlbinding">GLLVM.sigma_y_site</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
sigma_y_site(fit::GllvmFit) -> Matrix
```


The per-site (within-species) trait covariance `Σ_y_site = Λ_B Λ_B' + diag(d_total)` where `d_total[t] = (Λ_W Λ_W')[t,t] + σ²_B[t] + σ²_W[t] + σ²_eps`. For J1, `Λ_W = nothing`, `σ²_B = σ²_W = 0`, so the diagonal collapses to `σ²_eps`.

The phylogenetic block is _not_ included — for J3, the phylo contribution is rank-1 across species and is separated out for biological interpretation. Use `phylo_signal` to recover the phy component, and `correlation` for the per-site cross-trait correlations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/confint_derived.jl#L173-L185" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.takahashi_diag-Tuple{SparseArrays.CHOLMOD.Factor{Float64}}' href='#GLLVM.takahashi_diag-Tuple{SparseArrays.CHOLMOD.Factor{Float64}}'><span class="jlbinding">GLLVM.takahashi_diag</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
takahashi_diag(ch::SparseArrays.CHOLMOD.Factor) -> Vector{Float64}
```


Convenience: return ONLY `diag(Q⁻¹)` (a length-n vector, in the ORIGINAL ordering) via the Takahashi recursion. Same cost as `takahashi_selinv` but without materialising the full sparse output (a small allocation win when only the diagonal is needed, as in the EM E-step's per-trait variance).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/takahashi_selinv.jl#L199-L206" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.takahashi_selinv-Tuple{SparseArrays.CHOLMOD.Factor{Float64}}' href='#GLLVM.takahashi_selinv-Tuple{SparseArrays.CHOLMOD.Factor{Float64}}'><span class="jlbinding">GLLVM.takahashi_selinv</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
takahashi_selinv(ch::SparseArrays.CHOLMOD.Factor) -> SparseMatrixCSC
```


Compute the Takahashi selected inverse of the matrix `Q` whose sparse Cholesky factor is `ch` (`P · Q · Pᵀ = L · Lᵀ` with `P = I[ch.p, :]`). Returns a `SparseMatrixCSC` holding `Q⁻¹` (in the ORIGINAL un-permuted ordering) at the union sparsity of `Pᵀ (L + Lᵀ) P`. Entries outside that pattern are NOT computed (and are NOT zero in general).

Cost: `O(nnz(L))` arithmetic + O(nnz(L)·log(max_col_nnz)) for the symmetric lookups (with constant `max_col_nnz` on a tree this is `O(nnz(L))` overall).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/takahashi_selinv.jl#L91-L102" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.unpack_lambda-Tuple{AbstractVector, Integer, Integer}' href='#GLLVM.unpack_lambda-Tuple{AbstractVector, Integer, Integer}'><span class="jlbinding">GLLVM.unpack_lambda</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
unpack_lambda(θ::AbstractVector, p::Integer, K::Integer) -> AbstractMatrix
```


Inverse of `pack_lambda`. Returns a p × K matrix Λ with the diagonals and strict-lower entries filled from `θ` and the strict upper triangle = 0.

AD-friendly: `eltype(θ)` is preserved, so `θ::Vector{<:ForwardDiff.Dual}` returns a matrix of `Dual`s.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/packing.jl#L38-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='LinearAlgebra.ldiv!-Tuple{AbstractVector, GLLVM.LowRankPlusDiagChol, AbstractVector}' href='#LinearAlgebra.ldiv!-Tuple{AbstractVector, GLLVM.LowRankPlusDiagChol, AbstractVector}'><span class="jlbinding">LinearAlgebra.ldiv!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
ldiv!(out, F::LowRankPlusDiagChol, b)
ldiv!(out, F::LowRankPlusDiagChol, b, buf_K)
```


In-place Woodbury solve `out = M⁻¹ b` with `M = F.Λ F.Λ' + Diagonal(F.d)`.

If `buf_K` is omitted a fresh `K`-vector is allocated; pass one in to make this fully allocation-free on the hot path.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/lowrank_cholesky.jl#L92-L100" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.AugmentedPhy' href='#GLLVM.AugmentedPhy'><span class="jlbinding">GLLVM.AugmentedPhy</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AugmentedPhy{T}
```


Augmented-state sparse phylogenetic precision for a binary tree.

**Fields**
- `n_leaves::Int`               – number of tip species (p).
  
- `n_total::Int`                – 2p − 1, leaves + internal ancestor nodes.
  
- `Q_topology::SparseMatrixCSC` – (n_total × n_total) topology contribution to the sparse precision. The actual phylogenetic precision is `Q_topology / σ²_phy`. About 8p non-zeros.
  
- `leaf_indices::Vector{Int}`   – maps a leaf k ∈ 1:p to its row/col in the augmented state. Ordering matches the order leaves were encountered in the Newick string (left-to-right).
  
- `leaf_names::Vector{String}`  – species names parsed from the Newick.
  
- `branch_lengths::Vector{T}`   – the 2p − 2 branch lengths in the order the parser walked the tree.
  
- `root_index::Int`             – which augmented row is the root.
  

`Q_topology` is positive **semi**-definite (rank 2p − 2). The all-ones vector is its sole zero eigenvector — fixing the root removes the degeneracy. The sparse log-likelihood path adds a positive contribution to the leaf diagonals (proportional to `λ_phy² / d_total`) which renders the active solve matrix positive definite without any explicit ridge.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/sparse_phy.jl#L39-L64" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.BinomialFit' href='#GLLVM.BinomialFit'><span class="jlbinding">GLLVM.BinomialFit</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
BinomialFit
```


Result of [`fit_binomial_gllvm`](/api#GLLVM.fit_binomial_gllvm-Tuple{AbstractMatrix{<:Integer}}): intercepts `β` (length p), loadings `Λ` (p×K), the `link`, the maximised Laplace `loglik`, the optimiser `converged` flag, and `iterations`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/families/binomial.jl#L77-L83" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.GllvmFit' href='#GLLVM.GllvmFit'><span class="jlbinding">GLLVM.GllvmFit</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
GllvmFit
```


Result of `fit_gaussian_gllvm`. Holds the fitted parameters, the converged log-likelihood, convergence info, and the raw Optim result.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/fit.jl#L45-L50" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.GllvmModel' href='#GLLVM.GllvmModel'><span class="jlbinding">GLLVM.GllvmModel</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
GllvmModel(p, K; K_W=0, has_diag=false, K_phy=0, has_phy_unique=false)
```


Immutable spec describing a Gaussian GLLVM. `p` traits, `K` (= K_B) unit-tier latent factors, plus optional W tier (`K_W`), per-trait diagonal random effects (`has_diag`), and phylogenetic block (`K_phy`axes of`Λ_phy`and/or per-trait`σ_phy`when`has_phy_unique`). The single-tier J1 case is the default`K_W = 0`,`has_diag = false`,`K_phy = 0`,`has_phy_unique = false`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/fit.jl#L19-L28" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.LowRankPlusDiagChol' href='#GLLVM.LowRankPlusDiagChol'><span class="jlbinding">GLLVM.LowRankPlusDiagChol</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
LowRankPlusDiagChol{T}
```


Factorisation of `M = Λ Λ' + Diagonal(d)` that stores three small pieces:
- `d::Vector{T}`              — the positive diagonal of `D`.
  
- `Λ::Matrix{T}`              — the `p × K` low-rank factor.
  
- `cholK::Cholesky{T, Matrix{T}}` — Cholesky of the `K × K` capacitance matrix `I_K + Λ' D⁻¹ Λ`.
  

Use [`low_rank_chol`](/api#GLLVM.low_rank_chol-Tuple{AbstractMatrix,%20AbstractVector}) to construct, then `\`, [`ldiv!`](/api#LinearAlgebra.ldiv!-Tuple{AbstractVector,%20GLLVM.LowRankPlusDiagChol,%20AbstractVector}), or `logdet` for the Woodbury-based operations.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/lowrank_cholesky.jl#L24-L36" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='GLLVM.PhyloGaussianFit' href='#GLLVM.PhyloGaussianFit'><span class="jlbinding">GLLVM.PhyloGaussianFit</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
PhyloGaussianFit
```


Result of [`fit_phylo_gaussian`](/api#GLLVM.fit_phylo_gaussian-Tuple{GLLVM.AugmentedPhy,%20AbstractVector}): the maximum-likelihood estimates `μ`, `σ²_phy`, `σ²_eps` of the single-trait single-variance phylogenetic Gaussian model, the achieved `negll`, the optimiser `converged` flag, and the number of `iterations` taken.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/itchyshin/GLLVM.jl/blob/150d1b356c67c6c8b80b8b9be0febc9e099b1414/src/fit_phylo.jl#L18-L25" target="_blank" rel="noreferrer">source</a></Badge>

</details>

