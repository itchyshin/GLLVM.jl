# NB1+X grouped_cov call-site map

**Branch:** `cursor/nb1-x-engine-arc12-fffd` @ `63fe1c29`  
**Goal:** Implement `fit_nb1_gllvm_grouped_cov` / `NB1GroupedCovFit` mirroring Gamma/NB2.  
**Scope:** Call sites only (no engine code in this scratch).

---

## 1. `src/families/grouped_dispersion.jl` — Gamma + NB2 analogues

### GammaGroupedCovFit + `fit_gamma_gllvm_grouped_cov`

| Symbol | Lines |
| --- | --- |
| Docstring + `struct GammaGroupedCovFit` | **946–965** |
| `Base.show` / `_loadings` / `_loglik` / `_nparams` | **967–981** |
| `getLV(::GammaGroupedCovFit, …)` | **983–997** |
| Docstring + `function fit_gamma_gllvm_grouped_cov` … `end` | **999–1072** |

Packing: `θ = [β; γ_free; pack(Λ); log α_1 … log α_G]`; offset `O = _build_offset(X_fit, γ)` into `gamma_grouped_marginal_loglik_laplace`.

### NB2 analogue (start lines)

| Symbol | Start → end |
| --- | --- |
| Docstring + `struct NBGroupedCovFit` | **264–283** |
| show / `_nparams` / `getLV` | **285–315** |
| Docstring + `function fit_nb_gllvm_grouped_cov` … `end` | **317–389** |

Packing: `θ = [β; γ_free; pack(Λ); log r_1 … log r_G]` → `nb_grouped_marginal_loglik_laplace`.

### NB1 no-X (insert cov **after** this block)

| Symbol | Lines |
| --- | --- |
| Section header + `_nb1_grouped_loglik_site` | **1074–1122** |
| `nb1_grouped_marginal_loglik_laplace` | **1134–1149** |
| `struct NB1GroupedFit` … `fit_nb1_gllvm_grouped` | **1152–1267** |

**Gap:** no `NB1GroupedCovFit` / `fit_nb1_gllvm_grouped_cov` in this file.

---

## 2. Bridge X routing (`src/bridge.jl`)

### Allow-list (gamma/nb2 in; nb1 out)

| Site | Lines | Notes |
| --- | --- | --- |
| `_BRIDGE_X_FAMILIES` | **174–175** | `"negbinomial"`, `"beta"`, `"gamma"`, ordinal… — **no `"nb1"`** |
| Comment “NB1 remains absent” | **171–173** | Documents the fence |

### Where nb1 currently throws

| Site | Lines | Behaviour |
| --- | --- | --- |
| `bridge_fit` entry X guard | **400–410** | `(key == "gaussian" \|\| key in _BRIDGE_X_FAMILIES) \|\| throw(… "nb1 is a documented follow-up")` |
| Direct-path X guard before `_bridge_fit_onepart_cov` | **652–656** | `key in _BRIDGE_X_FAMILIES \|\| throw(…)` — same fence |

### Positive X routes (mirrors for nb1)

| Family | Dispatch | Lines |
| --- | --- | --- |
| NB2 | `fit_nb_gllvm_grouped_cov` → `_bridge_assemble_grouped_cov` | **1131–1137** |
| Beta | `fit_beta_gllvm_grouped_cov` → assemble | **1138–1143** |
| Gamma | `fit_gamma_gllvm_grouped_cov` → assemble | **1144–1149** |
| Assemble union | `Union{NBGroupedCovFit, BetaGroupedCovFit, GammaGroupedCovFit}` | **1203–1245** |

Test lock expecting throw: `test/test_bridge_x.jl` **374–377** (`family="nb1"` + `X`).

---

## 3. `src/formula.jl` — cov-family dispatch

| Site | Lines |
| --- | --- |
| Docstring (NB2/Beta/Gamma → `*_grouped_cov`) | **67–75** |
| `elseif family isa NegativeBinomial` → `fit_nb_gllvm_grouped_cov` | **118–119** |
| `elseif family isa Beta` → `fit_beta_gllvm_grouped_cov` | **120–121** |
| `elseif family isa Gamma` → `fit_gamma_gllvm_grouped_cov` | **122–123** |
| `elseif family isa Ordinal` → per-trait cov | **124–125** |
| `else` → `fit_gllvm_cov` | **126–128** |

**NB1 note:** `NB1` is not special-cased; today it would fall through to `fit_gllvm_cov` (shared-φ). Engine work should add `elseif family isa NB1` → `fit_nb1_gllvm_grouped_cov` beside the NB2/Gamma arms.

---

## 4. `src/confint_family.jl` — grouped_cov adapters

| Site | Lines |
| --- | --- |
| `_GroupedDispersionCovFit` union | **40** — `Union{NBGroupedCovFit, BetaGroupedCovFit, GammaGroupedCovFit}` (**no NB1**) |
| `_family_ci(::NBGroupedCovFit, …)` | **479–536** |
| `_family_ci(::BetaGroupedCovFit, …)` | **538–595** |
| `_family_ci(::GammaGroupedCovFit, …)` | **641–698** |

No-X NB1 already has grouped CI via `_GroupedDispersionFit` including `NB1GroupedFit` (**39**); cov adapter for NB1 is absent.

---

## 5. `src/GLLVM.jl` — exports

| Export | Line |
| --- | --- |
| `fit_nb_gllvm_grouped_cov, NBGroupedCovFit` | **169** |
| `fit_beta_gllvm_grouped_cov, BetaGroupedCovFit` | **171** |
| `fit_gamma_gllvm_grouped_cov, GammaGroupedCovFit` | **173** |
| `fit_nb1_gllvm_grouped, NB1GroupedFit, nb1_grouped_marginal_loglik_laplace` | **174** (no-X only) |

**Gap:** no `fit_nb1_gllvm_grouped_cov` / `NB1GroupedCovFit` export.

---

## 6. Identity-test pattern

### `test/test_gamma_x_identity.jl` (closest single-family mirror)

| `@testset` | Lines |
| --- | --- |
| Outer: `"Gamma + X identity (API B under X)"` | **12** |
| `"constant αvec + X offset == shared Gamma cov marginal"` | **14** |
| `"fit_gamma_gllvm_grouped_cov G=1 ≈ fit_gllvm_cov"` | **38** |

Contract: constant-disp + offset ≈ shared cov marginal `@ 1e-10`; G=1 (+ `:fisher` where needed) ≈ `fit_gllvm_cov`.

### `test/test_nb_beta_x_identity.jl` (NB2/Beta twin of same pattern)

| `@testset` | Lines |
| --- | --- |
| Outer: `"NB2/Beta + X identity (API B under X)"` | **12** |
| `"constant rvec + X offset == shared NB cov marginal"` | **14** |
| `"constant φvec + X offset == shared Beta cov marginal"` | **39** |
| `"fit_nb_gllvm_grouped_cov G=1+fisher ≈ fit_gllvm_cov"` | **64** |
| `"fit_beta_gllvm_grouped_cov G=1+fisher ≈ fit_gllvm_cov"` | **92** |

**NB1 plan target:** `test/test_nb1_x_identity.jl` mirroring the Gamma file (two inner sets: marginal offset identity + G=1 fitter vs shared cov).

---

## 7. Parity helper — `fit_gllvmtmb_parity_loglik_x` family switch

**File:** `test/parity/parity_helpers.jl`

| Site | Lines |
| --- | --- |
| Docstring `family` ∈ `(… :gamma, … :ordinal)` | **122–133** |
| Julia allow-list | **141–142** |
| R `switch(fam, …)` | **159–168** |
| `:gamma` arm | **163** — `stats::Gamma(link = "log")` |
| `:ordinal` arm | **166** — `gllvmTMB::ordinal_probit()` |
| `:negbinomial` / `:beta` (already present) | **164–165** |

**NB1 gap:** no `:nb1` in allow-list or R switch; extend with `gllvmTMB::nbinom1()` (or twin’s NB1 constructor) beside `:gamma` / `:ordinal`.

Light cells live in `test/parity/test_x_covariate_parity.jl` (`:gamma` ~307, `:ordinal` ~354).

---

## Mirror checklist (engine Arc)

1. Copy Gamma block **954–1072** (or NB2 **272–389**) → `NB1GroupedCovFit` + `fit_nb1_gllvm_grouped_cov` after **1267**, reusing `nb1_grouped_marginal_loglik_laplace` + `O = Xγ`.
2. Export in `GLLVM.jl` next to line **174**.
3. Add `"nb1"` to `_BRIDGE_X_FAMILIES` (**174–175**); branch in `_bridge_fit_onepart_cov` after gamma (**1144**); widen `_bridge_assemble_grouped_cov` union (**1203**).
4. Formula `isa NB1` arm (**118–123** region); docstring (**67–75**).
5. Confint: extend union **40** + `_family_ci(::NB1GroupedCovFit)` mirroring **479–536**.
6. Identity: new `test_nb1_x_identity.jl` like Gamma’s two `@testset`s.
7. Flip `test_bridge_x.jl` **374–377** from throw → success once wired.
8. Parity: `:nb1` in helper **141–142** / **159–168** + one light cell.
