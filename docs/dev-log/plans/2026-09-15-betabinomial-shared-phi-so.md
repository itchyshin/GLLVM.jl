# Design packet — BetaBinomial shared-φ second-order / native Wald pairing

**Status:** DESIGN SCOUT ONLY. No implementation in this packet. `src/confint_family.jl` was
read, not edited. Consumer: Ada (or the next slice) after [#367](https://github.com/itchyshin/GLLVM.jl/pull/367)
lands.

**Item:** Mac Studio handover `docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`
"Next ungated candidates" #2 — *"BetaBinomial shared-φ SO pairing — holdout still OUT / not
attempted; same class as Multinomial before #366 (API/wiring gap, not paste-gated). Prefer
native `_CIFit` / toy cell only; ≠ §7."*

**Holdout row (current):** `docs/dev-log/core070/second-order-holdouts-2026-09-04.md` —
*"Multinomial, BetaBinomial shared-φ | … BB shared-φ pairing still out of 20-cell window"* and
the disposition-pass table: *"BetaBinomial shared-φ | OUT | 20-cell arc paired per-trait
dispersion only; shared-φ grouping not attempted | `second-order-batch-2026-09-03.md` lines 37–39"*.

---

## 0. Headline finding — this is NOT a wiring gap like Multinomial

The handover frames this "same class as Multinomial before #366 (API/wiring gap)". **That framing
is wrong and should not survive into the implementation slice.** Multinomial needed `MultinomialFit`
*added* to `_CIFit` and a new `_family_ci(fit::MultinomialFit, …)` adapter written from scratch
(#366). BetaBinomial shared-φ does not need that:

- `BetaBinomialFit` (the shared-scalar-φ, no-grouping, no-X struct — `src/families/beta_binomial.jl:246-254`)
  is **already** a member of `_FamilyFit` (`src/confint_family.jl:32`), hence already in `_CIFit`
  (`src/confint_family.jl:45`).
- `_family_ci(fit::BetaBinomialFit, Y; N=…, …)` **already exists**, fully wired, at
  `src/confint_family.jl:1214-1250` (working vector `[β; pack_lambda(Λ); log φ]`, `simulate`/`refit`
  closures, `N` threaded exactly like `binomial.jl`).
- `confint(fit::BetaBinomialFit, Y; method=:wald)` is therefore **already reachable today** — it
  routes through the same generic `confint(fit::_CIFit, Y; …)` entry point
  (`src/confint_family.jl:2861`) that every other `_FamilyFit` member uses. No dispatch method is
  missing.

**What actually blocks the holdout** is narrower: the 20-cell second-order toy batch
(`tools/core070_second_order/cells.jl`, 2026-09-03) only ever built a **paired R↔Julia toy cell**
for the *grouped* (per-trait-φ) BetaBinomial route (`cell_betabinomial_grouped()` /
`cell_betabinomial_x()`, both calling `fit_beta_binomial_gllvm_grouped(...)` /
`fit_beta_binomial_gllvm_grouped_cov(...)`). No cell exercises the plain shared-φ
`fit_beta_binomial_gllvm(...)` (→ `BetaBinomialFit`) against R. That is the literal meaning of
"shared-φ grouping not attempted" in the disposition table — it is a **toy-cell / test-evidence
gap**, not an API gap.

**Consequence for the implementation slice:** `src/confint_family.jl` needs **zero** changes. The
slice is `tools/core070_second_order/cells.jl` (+dispatcher) and a new
`test/test_second_order_betabinomial_shared_ci.jl`, following the Multinomial/TweedieGrouped/
OrdinalPerTrait *test-file* pattern but *not* their *`_CIFit`-wiring* pattern (there is nothing to
wire).

---

## 1. Pack layout (unchanged — cited, not edited)

`BetaBinomialFit` (`src/families/beta_binomial.jl:246-254`):

```
struct BetaBinomialFit
    β::Vector{Float64}   # length p
    Λ::Matrix{Float64}   # p×K
    link::Link
    φ::Float64           # SHARED scalar Beta precision (a+b)
    loglik::Float64
    converged::Bool
    iterations::Int
end
```

`_family_ci(fit::BetaBinomialFit, Y; N=nothing, newton_maxiter=100, newton_tol=1e-9, …)`
(`src/confint_family.jl:1214-1250`) builds:

- **θ** = `vcat(β, pack_lambda(Λ), log(φ))` — length `p + rr_theta_len(p,K) + 1`.
- **names** = `_glm_lin_names(p,K)` (`beta[t]`, `Lambda[...]`) `vcat` `"phi"`.
- **kinds** = `:linear` for the β/Λ block, `:log` for the trailing `φ`.
- **nll(θv)** rebuilds `(β, Λ, φ)` and calls `betabinomial_marginal_loglik_laplace(Y, Nm, Λ, β, φ; link, …)`.
- **simulate(rng)** draws `p ~ Beta(μφ, (1−μ)φ)` then `y ~ Binomial(N, p)` per cell.
- **refit(Yb)** calls `fit_beta_binomial_gllvm(Yb; K, link, N=Nm)`.
- `N` (trial counts, p×n) is threaded as a **kwarg to `confint`**, not stored on the fit — identical
  convention to `BinomialFit` and to the already-wired `BetaBinomialGroupedFit`/`GroupedCovFit`
  siblings immediately above it in the file (`src/confint_family.jl:838-949`).

This matches the file's own in-code comment at `src/confint_family.jl:1208-1213`
("Working vector `[β; pack_lambda(Λ); log φ]` — the NB/Beta scalar-dispersion template… `N` … taken
as data through the `N` kwarg").

**No `_CIFit` dispatch change, no new struct, no new packing convention.** This section exists so
the implementer does not re-derive it — it is a read, not a design decision.

---

## 2. What is genuinely missing

### 2a. A paired second-order toy cell for the shared-φ route

`tools/core070_second_order/cells.jl` needs a new `cell_betabinomial_shared()` (name to confirm at
implementation time; `cell_betabinomial_scalar()` is the alternative) mirroring **`cell_beta()`**
(`tools/core070_second_order/cells.jl:233-262`) — the existing precedent for a Julia **shared**-
dispersion fit paired against an R family whose dispersion is inherently **per-trait** — rather than
`cell_betabinomial_grouped()`.

**Why `cell_beta()` is the right template, not `cell_betabinomial_grouped()`:** gllvmTMB's
`betabinomial()` / `Beta()` R constructors have no public "shared/scalar dispersion" knob — the TMB
engine's `log_phi_betabinom` / `log_phi_beta` are always length-p vectors (confirmed:
`gllvmTMB/R/families.R:703-716` `betabinomial <- function(link = "logit")` takes no dispersion-
grouping argument; `gllvmTMB/R/julia-bridge.R:2265-2285` and `R/init-warmstart.R:135-215` both treat
per-family dispersion as length-p with a scalar-broadcast fallback, never the reverse). `cell_beta()`
already solves this exact mismatch for the Beta family: it fits Julia's shared-φ `BetaFit`
(`fit_gllvm(Y; family = GLLVM.Beta(), K)`) and pairs it against `r_fit_se(Y, K; family = :beta)`
(R's per-trait-φ default), comparing **only the `beta[...]` fixed-effect block** via
`beta_idx_jl`/`r_beta_idx` (`_assemble`'s contract, `tools/core070_second_order/cells.jl:900-945`) —
the φ/dispersion coordinate is never compared because the two sides are not the same estimand there.
`cell_betabinomial_shared()` should do the same thing one family over.

**Concrete cell design (DGP mirrors `cell_betabinomial_grouped()`, fit call mirrors `cell_beta()`):**

```julia
function cell_betabinomial_shared()
    seed = 57   # new seed — do not reuse 56 (betabinomial_logit) or 49 (betabinomial_x)
    Random.seed!(seed)
    p, K, n = 5, 1, 120
    β = [0.30, -0.20, 0.25, -0.15, 0.05]
    φ_true = 8.0                       # single shared precision, DGP-true
    N = fill(8, p, n)
    Λ = 0.2 .* parity_loadings_p5k2()[:, 1:K]
    Z = randn(K, n)
    η = β .+ Λ * Z
    Y = Matrix{Int}(undef, p, n)
    for t in 1:p, s in 1:n
        μ = clamp(1 / (1 + exp(-η[t, s])), 1e-4, 1 - 1e-4)
        psucc = clamp(rand(Beta(μ * φ_true, (1 - μ) * φ_true)), 1e-6, 1 - 1e-6)
        Y[t, s] = rand(Binomial(N[t, s], psucc))
    end

    t0 = time()
    fit = fit_beta_binomial_gllvm(Y; K = K, N = N)         # BetaBinomialFit — SHARED scalar φ
    wall_fit = time() - t0
    ci = confint(fit, Float64.(Y); method = :wald, N = N)
    ad = GLLVM._family_ci(fit, Float64.(Y); N = N)
    H = GLLVM._fd_hessian(ad.nll, ad.θ)
    Σ = _safe_inv(H)

    r = r_fit_se(Float64.(Y), K; family = :betabinomial, N = N)   # R side stays per-trait φ
    beta_idx_jl = findall(t -> startswith(t, "beta["), ad.names)
    r_beta_idx = findall(==("b_fix"), r.names)

    d = _assemble("betabinomial_shared",
        "test/parity/test_nox_dispersion_parity.jl (seed=57,p=5,K=1,n=120, SHARED phi, N=8)",
        "BetaBinomial-logit (shared phi; Julia scalar vs R per-trait — beta[] block only)",
        "$(fit.link isa LogitLink ? "observed" : "observed")", false,
        p, K, n, seed, fit.converged, fit.loglik, wall_fit, r, ci, Σ, ad.names, beta_idx_jl, r_beta_idx)
    d["note"] = "R gllvmTMB::betabinomial() has no public shared-phi knob (per-trait log_phi_betabinom " *
                "always); compared quantity is the beta[] fixed-effect block only, mirroring cell_beta(). " *
                "phi itself is not paired — different estimand (Julia: 1 free scalar; R: p free per-trait)."
    d["parameterisation_gap"] = false   # β block itself is the SAME estimand on both sides
    return d
end
```

Register it in the dispatcher (`tools/core070_second_order/cells.jl:16-64`):

```julia
elseif cell_id == "betabinomial_shared"
    return cell_betabinomial_shared()
```

`hessian_selector`: confirm at implementation time whether `fit_beta_binomial_gllvm` has a
`hessian` kwarg at all — per `src/families/beta_binomial.jl:420-424` comment, this family's
per-site Laplace has **no analytic-Hessian variant** (ForwardDiff-scored weight only, G0 lock), so
unlike Tweedie/NB2/Beta/Gamma grouped siblings there is no `:observed`/`:fisher` choice to record;
the cell's `hessian_selector` field should read a fixed literal (e.g. `"fisher (family default; no
observed-Hessian variant — G0 lock)"`), not a `fit.hessian` field access (that field does not exist
on plain `BetaBinomialFit` — only the Grouped/GroupedCov variants carry `hessian::Symbol`, and it is
hard-pinned to `:fisher` there too per `src/families/beta_binomial.jl:420-424,591-593`).

### 2b. Test file

New `test/test_second_order_betabinomial_shared_ci.jl`, following the `test_second_order_
tweedie_grouped_ci.jl` / `test_second_order_multinomial_ci.jl` shape (Julia-only wiring assertions
always run; live R paired Δ gated behind `ENV["GLLVM_PARITY_TESTS"] == "1"`):

```julia
# Second-order holdout clearance: shared-phi BetaBinomialFit is ALREADY in _CIFit
# (src/confint_family.jl:1214). This file adds the missing paired-cell test
# evidence, not new _CIFit wiring. ≠ programme §7. Bridge untouched.

using GLLVM, Test, Random, Distributions

@testset "BetaBinomialFit (shared phi) second-order Wald wiring" begin
    @testset "θ packing + public Wald on beta[] (no-X)" begin
        Random.seed!(571)
        p, K, n = 5, 1, 80
        β = [0.3, -0.2, 0.25, -0.15, 0.05]
        φ = 8.0
        Λ = 0.2 .* randn(p, K)
        N = fill(8, p, n)
        Z = randn(K, n)
        η = β .+ Λ * Z
        Y = Matrix{Int}(undef, p, n)
        for t in 1:p, s in 1:n
            μ = clamp(1 / (1 + exp(-η[t, s])), 1e-4, 1 - 1e-4)
            psucc = clamp(rand(Beta(μ * φ, (1 - μ) * φ)), 1e-6, 1 - 1e-6)
            Y[t, s] = rand(Binomial(N[t, s], psucc))
        end
        fit = fit_beta_binomial_gllvm(Y; K = K, N = N)
        @test fit isa BetaBinomialFit
        ad = GLLVM._family_ci(fit, Float64.(Y); N = N)
        @test length(ad.θ) == p + GLLVM.rr_theta_len(p, K) + 1
        @test count(startswith("beta["), ad.names) == p
        @test ad.names[end] == "phi"
        @test ad.kinds[end] === :log

        ci = confint(fit, Float64.(Y); method = :wald, N = N, parm = "beta")
        @test length(ci.term) == p
        fin = isfinite.(ci.se)
        @test count(fin) ≥ 3
        @test all(ci.lower[fin] .< ci.estimate[fin] .< ci.upper[fin])

        # phi itself: SE should exist and be finite/positive (existing generic
        # Wald machinery — not new, just asserting it does not silently break)
        ciphi = confint(fit, Float64.(Y); method = :wald, N = N, parm = "phi")
        @test ciphi.term == ["phi"]
        @test isfinite(ciphi.se[1]) && ciphi.se[1] > 0
    end

    @testset "N kwarg required consistently; mask/missing threads through" begin
        # optional: exercise `mask` / `missing` Y cells through _family_ci, mirroring
        # the existing BetaBinomialGroupedFit test coverage for the shared route
    end

    @testset "R paired betabinomial_shared cell (live Δ, beta[] block only)" begin
        if get(ENV, "GLLVM_PARITY_TESTS", "0") != "1"
            @test_skip "set GLLVM_PARITY_TESTS=1 with R + gllvmTMB for live second-order Δ"
        else
            using RCall
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "common.jl"))
            include(joinpath(@__DIR__, "..", "tools", "core070_second_order", "cells.jl"))
            d = run_one_cell("betabinomial_shared")
            @test get(d, "skip_reason", nothing) === nothing
            @test get(d, "parameterisation_gap", true) == false
            se_rel = d["se_max_relative_delta"]
            @test se_rel !== nothing && isfinite(se_rel)
            # Do not assert contract §4 D1 here — record live Δ; promote only after
            # a smoke receipt, per the tweedie_fixed / multinomial precedent.
        end
    end
end
```

### 2c. Optional smoke driver

Mirroring `tools/core070_second_order/smoke_tweedie_fixed_eoo.jl`, an optional
`smoke_betabinomial_shared_eoo.jl` that runs `run_one_cell("betabinomial_shared")` standalone and
writes a JSON receipt under `tools/core070_second_order/` output dir. Not required for the test
suite to pass; useful for the eventual live-Δ receipt once R+RCall are available. **Do not run it
in this design slice** — it needs R + `gllvmTMB` + `RCall`, and per the hard fences below, no
Totoro/D-139 spend is authorised.

---

## 3. Fences (carried into the implementation slice)

- **≠ §7.** This clears one row of the §6 holdout table with a toy-cell / native-Wald receipt. It is
  not a claim of second-order parity, matched-coordinates parity, coverage, or programme
  completion.
- **≠ bridge CI.** The R-side `ci_method` guard for BetaBinomial in `src/bridge.jl` (if any) stays
  untouched until [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) (bridge logLik receipts,
  **foreign/CONFLICTING — do not edit**) lifts. This slice is Julia-native `confint()` only.
- **≠ grouped/per-trait BetaBinomial.** `BetaBinomialGroupedFit`/`GroupedCovFit` are already fully
  wired *and* already have paired toy cells (`betabinomial_logit`, `betabinomial_x`). Nothing in this
  packet touches them.
- **≠ φ/dispersion parity.** Per §2a, the R comparator has no shared-φ knob; only the `beta[...]`
  block is a shared estimand. Do not claim the trailing `phi` Wald SE has been checked against R —
  it has not, and per the current toy-cell contract (see `cell_beta()`) it structurally cannot be
  without a different R-side mechanism (e.g. constraining `p = 1` trait so "per-trait" trivially
  collapses to one φ — out of scope here).
- **No `src/confint_family.jl` edits.** Confirmed unnecessary in §0; if an implementer finds
  themselves editing that file for this item, they have mis-scoped the slice.
  <!-- Ada should re-verify this against the file's live SHA at implementation time — this packet
       was scouted at GLLVM.jl `origin/main` @ `c459751bf`; re-check nothing moved BetaBinomialFit
       out of _FamilyFit before assuming this. -->
- **No Totoro / D-139 spend, no `S4 probe`, no `Project.toml` bump, no `#357` edits** — standing
  programme fences, unchanged by this item.
- **No gllvmTMB engine surgery.** The twin's `betabinomial()` R constructor has no shared-φ knob;
  this packet does not propose adding one (that would be engine surgery on a read-only reference
  package). The pairing scope (§2a) is designed to route *around* that gap, not fill it.

---

## 4. Estimated files to touch (implementation slice, not this packet)

| File | Change |
|---|---|
| `tools/core070_second_order/cells.jl` | Add `cell_betabinomial_shared()` + one `elseif` dispatcher line |
| `test/test_second_order_betabinomial_shared_ci.jl` | New file (§2b) |
| `tools/core070_second_order/smoke_betabinomial_shared_eoo.jl` | New, optional (§2c) |
| `docs/dev-log/core070/second-order-holdouts-2026-09-04.md` | Update the "Multinomial, BetaBinomial shared-φ" row → split BB shared-φ into its own PARTIAL row, mirroring the Multinomial-FE wording pattern |
| `docs/dev-log/2026-09-14-true-parity-pending-board.md` | "Second-order follow-up" bullet: move "BB shared-φ pairing … still OUT" to done/PARTIAL once merged |
| `docs/dev-log/check-log.md` | One entry, mirroring the Lognormal/TruncPois/TruncNB2 entries |
| `docs/dev-log/after-task/YYYY-MM-DD-betabinomial-shared-phi-so.md` | New after-task report (Definition of Done item 6) |

**No changes to:** `src/confint_family.jl`, `src/families/beta_binomial.jl`, `src/bridge.jl`
(bridge CI stays fenced behind #357).

**Total: ~4 required files + 1 optional smoke file + 1 after-task report = 5–6 files.** Materially
smaller than the Multinomial slice (#366), which had to add real `_CIFit` dispatch; this one is
test-and-toy-cell only.

---

## 5. Open questions for the implementer (not blocking; flag, don't block)

1. **Cell name:** `betabinomial_shared` vs `betabinomial_scalar` vs `betabinomial_nogroup` — pick
   one and use it consistently across `cells.jl`, the test file, and the holdout doc. This packet
   uses `betabinomial_shared` throughout for concreteness only.
2. **Seed:** 57 is a placeholder (56 and 49 are taken by the existing BB cells in `cells.jl:360,681`
   respectively) — confirm no other cell claims 57 before implementing.
3. **`hessian_selector` string:** confirm whether `_assemble`'s `hessian_selector` field expects a
   short tag (existing cells use `"observed (family default)"`-style strings) vs a longer
   G0-lock explanation; keep it consistent with neighbouring BB cells' wording
   (`"observed (grouped default)"` at `cells.jl:389`) even though this route is Fisher-only —
   i.e. the string should say `"fisher (no observed-Hessian variant; G0 lock)"` to avoid implying
   a choice that does not exist for this family.
