# Post-fit API — Slice 1: Ordination core (`getLV` / `getLoadings` / `rotation`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract reproducible ordination from a fitted GLLVM — latent-variable scores (`getLV`) and species loadings (`getLoadings`) in a canonical rotation (`rotation`), for both `GllvmFit` (Gaussian) and `BinomialFit`.

**Architecture:** A new `src/postfit.jl` holds the post-fit methods. Loadings come straight from the fit (`fit.pars.Λ` / `fit.Λ`); the canonical rotation is the right-singular-vector matrix `V` of `Λ` (SVD), sign-fixed for determinism. Latent scores are the conditional posterior mean (Gaussian, closed form using `Ψ = Σ_y − ΛΛ'`) or the Laplace conditional mode (Binomial, the inner Fisher-scoring solve already in `laplace_loglik_site`, refactored into a reusable `_laplace_mode`). Rotating scores and loadings by the same `V` leaves `Λ Zᵀ` (hence `Σ_y`) unchanged.

**Tech Stack:** Julia, LinearAlgebra (`svd`, `cholesky`, `\`), the existing `sigma_y_site`, `linkinv`/`mu_eta`, `Test`.

This is **Slice 1 of 5** from the spec (`docs/superpowers/specs/2026-05-31-postfit-api-design.md`). Slices 2–5 (predict/fitted, residuals, summary/show, docs+exports page) are planned separately as we reach them. This slice produces working, testable software on its own: ordination scores + loadings.

---

## File structure

- **Create `src/postfit.jl`** — `_loadings`, `_svd_rotation`, `rotation`, `getLoadings`, `_fitted_mean`, `getLV` (both fit types). One file, one responsibility: ordination extraction.
- **Modify `src/families/binomial.jl`** — extract the inner Fisher-scoring solve into `_laplace_mode(y, n, Λ, β, link; …)`; have `laplace_loglik_site` call it. Behaviour unchanged.
- **Modify `src/GLLVM.jl`** — `include("postfit.jl")` (after the families includes, before confint) and export `getLV, getLoadings, rotation`.
- **Create `test/test_postfit.jl`** — all Slice-1 tests.
- **Modify `test/runtests.jl`** — `include("test_postfit.jl")`.

---

## Task 1: Loadings + canonical rotation (`_loadings`, `_svd_rotation`, `rotation`, `getLoadings`)

**Files:**
- Create: `src/postfit.jl`
- Modify: `src/GLLVM.jl` (include + exports)
- Test: `test/test_postfit.jl`

- [ ] **Step 1: Write the failing test**

Create `test/test_postfit.jl`:

```julia
using GLLVM, Test, Random, LinearAlgebra

if !isdefined(GLLVM, :getLV)
    include(joinpath(@__DIR__, "..", "src", "postfit.jl"))
end

@testset "post-fit ordination core" begin
    @testset "rotation + getLoadings (Gaussian)" begin
        Random.seed!(0)
        p, K, n = 5, 2, 120
        Λt = 0.8 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        R = GLLVM.rotation(fit)
        @test size(R) == (K, K)
        @test R' * R ≈ I(K) atol = 1e-10            # orthogonal

        Lr = GLLVM.getLoadings(fit; rotate = true)
        L0 = GLLVM.getLoadings(fit; rotate = false)
        @test size(Lr) == (p, K)
        @test L0 ≈ fit.pars.Λ                         # raw == stored Λ
        @test Lr ≈ L0 * R                             # rotated == Λ·R
        @test Lr * Lr' ≈ L0 * L0' atol = 1e-9         # rotation-invariant ΛΛ'
        # canonical: rotated columns ordered by decreasing norm
        nrm = [norm(@view Lr[:, k]) for k in 1:K]
        @test issorted(nrm; rev = true)
        # sign-fix: largest-magnitude entry of each rotated column is ≥ 0
        for k in 1:K
            @test Lr[argmax(abs.(@view Lr[:, k])), k] ≥ 0
        end
    end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: FAIL — `UndefVarError: getLV not defined` (the `include` finds no `src/postfit.jl`) or `LoadError` opening the missing file.

- [ ] **Step 3: Write minimal implementation**

Create `src/postfit.jl`:

```julia
# Post-fit ordination extraction for fitted GLLVMs.
#
# Loadings come from the fit; the canonical rotation is the right-singular-
# vector matrix V of Λ (SVD), sign-fixed so each rotated loading column's
# largest-magnitude entry is non-negative and columns are ordered by
# decreasing singular value. Rotating loadings (Λ → Λ V) and scores
# (Z → Z V) by the same V leaves Λ Zᵀ — hence Σ_y — unchanged.

# Loadings accessor — dispatches over the two fitted types.
_loadings(fit::GllvmFit)   = fit.pars.Λ
_loadings(fit::BinomialFit) = fit.Λ

# Canonical sign-fixed right-singular-vector rotation of Λ (p×K) -> K×K.
function _svd_rotation(Λ::AbstractMatrix)
    F = svd(Λ)                      # Λ = U S Vᵀ ; columns of V order by S↓
    V = Matrix(F.V)                 # K×K
    ΛV = Λ * V
    @inbounds for k in 1:size(V, 2)
        idx = argmax(abs.(@view ΛV[:, k]))
        if ΛV[idx, k] < 0
            @views V[:, k] .= .-V[:, k]
        end
    end
    return V
end

"""
    rotation(fit) -> K×K orthogonal matrix

Canonical rotation `R` of the latent space (sign-fixed SVD of the loadings):
`getLoadings(fit; rotate=true) == getLoadings(fit; rotate=false) * R` and
`getLV(fit, y; rotate=true) == getLV(fit, y; rotate=false) * R`. `R'R == I`.
"""
rotation(fit) = _svd_rotation(_loadings(fit))

"""
    getLoadings(fit; rotate=true) -> p×K matrix

Species loadings. `rotate=true` (default) returns them in the canonical
ordination orientation (`Λ R`, columns ordered by decreasing variance,
signs fixed); `rotate=false` returns the raw fitted `Λ`. Rotation leaves
`Λ Λᵀ` (and `Σ_y`) unchanged.
"""
function getLoadings(fit; rotate::Bool = true)
    Λ = _loadings(fit)
    return rotate ? Λ * _svd_rotation(Λ) : copy(Λ)
end
```

Then add to `src/GLLVM.jl`: after the families includes (the line `include("families/fit_gllvm.jl")`), add `include("postfit.jl")`, and add `getLV, getLoadings, rotation` to the `export` list.

- [ ] **Step 4: Run test to verify it passes**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: PASS (the `rotation + getLoadings (Gaussian)` testset).

- [ ] **Step 5: Commit**

```bash
git add src/postfit.jl src/GLLVM.jl test/test_postfit.jl
git commit -m "feat(postfit): getLoadings + canonical SVD rotation"
```

---

## Task 2: Refactor `_laplace_mode` out of `laplace_loglik_site`

**Files:**
- Modify: `src/families/binomial.jl:28-56` (the `laplace_loglik_site` function)
- Test: `test/test_postfit.jl`

- [ ] **Step 1: Write the failing test**

Append to the `@testset "post-fit ordination core"` block in `test/test_postfit.jl`:

```julia
    @testset "_laplace_mode matches the marginal's inner solve" begin
        Random.seed!(7)
        p, K, n = 4, 1, 1
        Λ = reshape([1.0, 0.8, -0.6, 0.4], p, K)
        β = [0.2, -0.1, 0.0, 0.3]
        y = reshape([1, 0, 1, 1], p, n)
        N = ones(Int, p, n)
        ẑ = GLLVM._laplace_mode(view(y, :, 1), view(N, :, 1), Λ, β, LogitLink())
        @test length(ẑ) == K
        # At the mode the penalised-score stationarity holds: Λ'(working
        # residual) − ẑ ≈ 0 (the inner Newton step is ~0).
        η = β .+ Λ * ẑ
        μ = inv.(1 .+ exp.(-η))
        me = μ .* (1 .- μ)
        s = (vec(y) .- vec(N) .* μ) ./ (μ .* (1 .- μ)) .* me
        @test maximum(abs.(Λ' * s .- ẑ)) < 1e-6
    end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: FAIL — `UndefVarError: _laplace_mode not defined`.

- [ ] **Step 3: Write minimal implementation**

In `src/families/binomial.jl`, replace the body of `laplace_loglik_site` (lines 28–56) so the inner mode-finder is a reusable helper. Insert this helper immediately before `laplace_loglik_site`:

```julia
# Inner Laplace mode-finder (Fisher-scoring Newton). Returns the conditional
# mode ẑ (length K) for one site. Shared by the marginal log-likelihood and
# by getLV.
function _laplace_mode(y::AbstractVector, n::AbstractVector,
        Λ::AbstractMatrix, β::AbstractVector, link::Link;
        maxiter::Integer = 100, tol::Real = 1e-9)
    K = size(Λ, 2)
    z = zeros(K)
    for _ in 1:maxiter
        η  = _clamp_eta.(β .+ Λ * z)
        μ  = _clamp_mu.(linkinv.(Ref(link), η))
        me = mu_eta.(Ref(link), η)
        v  = μ .* (1 .- μ)
        s  = (y .- n .* μ) ./ v .* me
        W  = n .* me .^ 2 ./ v
        A  = Symmetric(Λ' * (W .* Λ) + I)
        Δ  = A \ (Λ' * s .- z)
        z  = z .+ Δ
        maximum(abs, Δ) < tol && break
    end
    return z
end
```

Then change `laplace_loglik_site` to call it instead of repeating the loop. Replace its lines from `z = zeros(K)` through the `for`-loop end (the inner Newton loop, up to and including `maximum(abs, Δ) < tol && break` / `end`) with:

```julia
    p, K = size(Λ)
    z = _laplace_mode(y, n, Λ, β, link; maxiter = maxiter, tol = tol)
```

The remainder of `laplace_loglik_site` (recomputing `η, μ, me, v, W, A`, the `ℓ` sum, and `return ℓ - 0.5*dot(z,z) - 0.5*logdet(A)`) stays exactly as is.

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: PASS (new `_laplace_mode` testset).

Run the existing binomial tests to confirm the refactor is behaviour-preserving:
Run: `~/.juliaup/bin/julialauncher --project=. test/test_binomial_laplace.jl`
Expected: PASS (unchanged log-likelihood values).

- [ ] **Step 5: Commit**

```bash
git add src/families/binomial.jl test/test_postfit.jl
git commit -m "refactor(binomial): extract reusable _laplace_mode from laplace_loglik_site"
```

---

## Task 3: `getLV` for `GllvmFit` (Gaussian conditional posterior mean)

**Files:**
- Modify: `src/postfit.jl` (add `_fitted_mean`, `getLV(::GllvmFit, …)`)
- Test: `test/test_postfit.jl`

- [ ] **Step 1: Write the failing test**

Append to the testset in `test/test_postfit.jl`:

```julia
    @testset "getLV (Gaussian) matches the factor-analysis posterior" begin
        Random.seed!(1)
        p, K, n = 5, 2, 150
        Λt = 0.9 .* randn(p, K)
        y = Λt * randn(K, n) .+ 0.5 .* randn(p, n)
        fit = fit_gaussian_gllvm(y; K = K)

        Z = GLLVM.getLV(fit, y; rotate = false)
        @test size(Z) == (n, K)

        # Independent reference: m_s = (I + Λ'Ψ⁻¹Λ)⁻¹ Λ'Ψ⁻¹ y_s with
        # Ψ = Σ_y − ΛΛ'.
        Λ = fit.pars.Λ
        Σ = GLLVM.sigma_y_site(fit)
        Ψ = Σ - Λ * Λ'
        ΨiΛ = Ψ \ Λ
        M = Symmetric(I(K) + Λ' * ΨiΛ)
        Zref = (M \ (ΨiΛ' * y))'              # n×K
        @test Z ≈ Zref atol = 1e-8

        # Rotation consistency: Λ_rot Z_rotᵀ == Λ Z_rawᵀ.
        Zr = GLLVM.getLV(fit, y; rotate = true)
        Lr = GLLVM.getLoadings(fit; rotate = true)
        @test Lr * Zr' ≈ Λ * Z' atol = 1e-8
    end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: FAIL — `MethodError: no method matching getLV(::GllvmFit, ::Matrix{Float64})`.

- [ ] **Step 3: Write minimal implementation**

Add to `src/postfit.jl`:

```julia
# Fitted mean μ (p×n): X·β when fixed effects are present, else zeros.
function _fitted_mean(fit::GllvmFit, y::AbstractMatrix,
                      X::Union{Nothing, AbstractArray{<:Real, 3}})
    p, n = size(y)
    β = fit.pars.β
    if X === nothing || β === nothing || length(β) == 0
        return zeros(Float64, p, n)
    end
    μ = zeros(Float64, p, n)
    q = size(X, 3)
    @inbounds for s in 1:n, t in 1:p, k in 1:q
        μ[t, s] += X[t, s, k] * β[k]
    end
    return μ
end

"""
    getLV(fit::GllvmFit, y; X=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores (site ordination): the Gaussian posterior
mean `mₛ = (I + Λᵀ Ψ⁻¹ Λ)⁻¹ Λᵀ Ψ⁻¹ (yₛ − μₛ)`, with residual covariance
`Ψ = Σ_y − ΛΛᵀ` and `μ` the fitted mean (`X·β`, or 0 when there are no fixed
effects). `y` (and `X`, when the fit used fixed effects) must match what was
passed to `fit_gaussian_gllvm` — the fit does not store the data. `rotate=true`
applies the canonical [`rotation`](@ref).
"""
function getLV(fit::GllvmFit, y::AbstractMatrix;
               X::Union{Nothing, AbstractArray{<:Real, 3}} = nothing,
               rotate::Bool = true)
    Λ = fit.pars.Λ
    K = size(Λ, 2)
    Σ = sigma_y_site(fit)
    Ψ = Σ - Λ * Λ'
    R = y .- _fitted_mean(fit, y, X)
    ΨiΛ = Ψ \ Λ
    M = Symmetric(Matrix{Float64}(I, K, K) + Λ' * ΨiΛ)
    Z = M \ (ΨiΛ' * R)                  # K×n
    Zt = permutedims(Z)                 # n×K
    return rotate ? Zt * _svd_rotation(Λ) : Zt
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/postfit.jl test/test_postfit.jl
git commit -m "feat(postfit): getLV for Gaussian fits (conditional posterior mean)"
```

---

## Task 4: `getLV` for `BinomialFit` (Laplace conditional mode)

**Files:**
- Modify: `src/postfit.jl` (add `getLV(::BinomialFit, …)`)
- Test: `test/test_postfit.jl`

- [ ] **Step 1: Write the failing test**

Append to the testset in `test/test_postfit.jl`:

```julia
    @testset "getLV (Binomial) matches per-site Laplace mode" begin
        Random.seed!(3)
        p, K, n = 6, 2, 80
        Λt = 0.9 .* randn(p, K)
        β  = 0.3 .* randn(p)
        η  = β .+ Λt * randn(K, n)
        μ  = inv.(1 .+ exp.(-η))
        Y  = Int.(rand(p, n) .< μ)
        fit = fit_binomial_gllvm(Y; K = K)

        Z = GLLVM.getLV(fit, Y; rotate = false)
        @test size(Z) == (n, K)
        # Each row equals the per-site Laplace mode.
        N = ones(Int, p, n)
        for s in 1:n
            ẑ = GLLVM._laplace_mode(view(Y, :, s), view(N, :, s), fit.Λ, fit.β, fit.link)
            @test Z[s, :] ≈ ẑ atol = 1e-7
        end
        # Rotation consistency.
        Zr = GLLVM.getLV(fit, Y; rotate = true)
        @test GLLVM.getLoadings(fit; rotate = true) * Zr' ≈ fit.Λ * Z' atol = 1e-7
    end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: FAIL — `MethodError: no method matching getLV(::BinomialFit, ::Matrix{Int…})`.

- [ ] **Step 3: Write minimal implementation**

Add to `src/postfit.jl`:

```julia
"""
    getLV(fit::BinomialFit, Y; N=nothing, rotate=true) -> n×K matrix

Conditional latent-variable scores: the per-site Laplace mode `ẑₛ` (the inner
Fisher-scoring solve of the marginal). `Y` is the p×n integer response matrix;
`N` the trial counts (default all-ones, i.e. Bernoulli). `rotate=true` applies
the canonical [`rotation`](@ref).
"""
function getLV(fit::BinomialFit, Y::AbstractMatrix{<:Integer};
               N::Union{Nothing, AbstractMatrix{<:Integer}} = nothing,
               rotate::Bool = true)
    p, n = size(Y)
    Nm = N === nothing ? fill(1, p, n) : N
    K = size(fit.Λ, 2)
    Z = Matrix{Float64}(undef, K, n)
    @inbounds for s in 1:n
        Z[:, s] = _laplace_mode(view(Y, :, s), view(Nm, :, s), fit.Λ, fit.β, fit.link)
    end
    Zt = permutedims(Z)                 # n×K
    return rotate ? Zt * _svd_rotation(fit.Λ) : Zt
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/.juliaup/bin/julialauncher --project=. test/test_postfit.jl`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/postfit.jl test/test_postfit.jl
git commit -m "feat(postfit): getLV for Binomial fits (Laplace conditional mode)"
```

---

## Task 5: Wire into the suite + full-suite verification

**Files:**
- Modify: `test/runtests.jl` (add the include)

- [ ] **Step 1: Add the include**

In `test/runtests.jl`, after the line `include("test_fit_gllvm.jl")`, add:

```julia
include("test_postfit.jl")
```

- [ ] **Step 2: Run the core suite**

Run: `~/.juliaup/bin/julialauncher --project=. test/runtests.jl`
Expected: PASS — all existing tests plus the new `post-fit ordination core` testset; no regressions.

- [ ] **Step 3: Commit**

```bash
git add test/runtests.jl
git commit -m "test(postfit): wire test_postfit.jl into the suite"
```

- [ ] **Step 4: Branch, push, PR (the established rhythm)**

```bash
git push -u origin postfit-api
gh pr create --base main --head postfit-api \
  --title "Post-fit API slice 1: ordination core (getLV/getLoadings/rotation)" \
  --body "First slice of the post-fit API (#9): getLV (Gaussian posterior mean / Binomial Laplace mode), getLoadings, canonical SVD rotation, for both fitted types. Rotation-invariant; verified against the closed-form posterior and the internal Laplace mode. Spec: docs/superpowers/specs/2026-05-31-postfit-api-design.md."
```

Then dual-watch CI.yml + Documenter and merge on green (per the repo rhythm; check **both** workflows).

---

## Self-review

**Spec coverage (Slice 1 only):** `getLV` ✓ (Tasks 3, 4), `getLoadings` ✓ (Task 1), `rotation` ✓ (Task 1). Rotation-invariance test ✓ (Tasks 1, 3, 4). Both fit types ✓. predict/residuals/summary/docs are Slices 2–5 (out of scope here, per spec).

**Placeholder scan:** none — every step has runnable code or an exact command.

**Type consistency:** `_loadings(fit)` returns `p×K`; `_svd_rotation` returns `K×K`; `getLV` returns `n×K` (via `permutedims`); `rotation`/`getLoadings`/`getLV` all rotate by the same `_svd_rotation(_loadings(fit))`, so `getLoadings(rotate=true) == Λ·R` and `getLV(rotate=true) == Z·R` are consistent (`Lr * Zr' == Λ * Z'`). `_laplace_mode` signature matches both its call sites (the marginal and `getLV(::BinomialFit)`).

**Note for the executor:** `getLV(::GllvmFit)` is exact for J1 (`Ψ = σ²I`) and is the Bartlett/regression-score posterior for J2/J3 (`Ψ = Σ_y − ΛΛᵀ`). The phylogenetic block is not in `Σ_y_site` by design, so scores reflect the per-site latent structure — consistent with `sigma_y_site`/`communality`.
