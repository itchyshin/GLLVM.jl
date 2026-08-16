# Gaussian logLik parity cell — RCall shape recon (2026-08-01)

Read-only recon for Phase 1.0 `test/parity/test_gaussian_parity.jl`. Sources: local parity scaffold (`origin/main` matches working tree on parity files), twin R at `/tmp/gllvmtmb-parity-restart-20260801` (gllvmTMB dev) plus CRAN `gllvm` docs/tests referenced from that repo.

---

## 1. What the DRAFT currently calls

**Runner:** `GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` (`runparity.jl` dev-adds GLLVM, loads RCall, includes `test_gaussian_parity.jl`).

**Julia side (sound):**
- DGP: `p=5, K=2, n=80`, `Random.seed!(42)`, lower-triangular `Λ_true`, shared `σ_true=0.7`, `y = Λ_true * η + σ_true * randn(p, n)` (traits × sites).
- Fit: `fit_gaussian_gllvm(y; K=K)` → `jl_fit.logLik`, `jl_fit.pars.Λ`, `jl_fit.pars.σ_eps`, `jl_Σ_y = ΛΛᵀ + σ_eps² I`.

**R side (DRAFT — not validated live):**
```r
library(gllvm)
Y_r <- t(y)                    # n × p  (transpose Julia p×n)
fit_r <- gllvm(
    Y_r,
    num.lv  = K,
    family  = "gaussian",
    seed    = 42L
)
r_logL  <- fit_r$logL
r_theta <- fit_r$params$theta      # treated as loadings (WRONG — see §3)
r_sigma <- fit_r$params$sigma      # residual SD (field name uncertain for Gaussian)
Lam     <- r_theta                 # p×K after maybe t()
Sigma_y <- Lam %*% t(Lam) + diag(sigma_eps_r^2, p)
```

**Provisional asserts:** `logL` rtol 1e-3; `Σ_y` atol 1e-2; `σ_eps` rtol 5e-2.

**Known draft defects (documented in README + inline `# DRAFT`):**
- Targets **CRAN `gllvm::gllvm()`**, not **`gllvmTMB::gllvmTMB()`** (repo headline twin).
- Extractors copied from gllvm 1.x folklore; **`params$theta` is not Λ**.
- Never executed against live R (Phase 1.0 scaffold status unchanged).

---

## 2. Correct gllvmTMB call — tiny Gaussian, no-X cell

Goal: match GLLVM.jl J1 model `y[t,s] = (Λ η_s)[t] + ε[t,s]`, `ε ~ N(0, σ_eps² I)` with **shared scalar `σ_eps`**, **no covariates**, rank `K`.

### Symbolic alignment choices

| Piece | GLLVM.jl | gllvmTMB equivalent |
| --- | --- | --- |
| Latent rank | `K` | `d = K` in `latent(...)` |
| Shared residual | single `σ_eps` | Gaussian `sigma_eps` (scalar in `fit$report$sigma_eps`) |
| No per-trait Ψ | `Σ = ΛΛᵀ + σ²I` only | **`latent(..., unique = FALSE)`** — loadings-only subset (suppresses default Ψ companion) |
| Fixed effects | none (zero-mean likelihood) | **`0 + trait` adds per-trait intercepts** — **misaligned** unless data are **column-centred per trait** on both sides before fit |
| Integration | exact Gaussian marginal | Laplace exact for Gaussian (`logLik` = `-opt$objective`) |

**Recommended first green path:** centre `y` per trait in Julia (`y .-= mean(y, dims=2)`) before both fits; use `unique = FALSE`.

### Wide call (closest to matrix DGP)

Julia `y` is `p × n`. Build wide `data.frame` with `n` rows, `p` trait columns, `site` factor:

```r
library(gllvmTMB)
p <- nrow(y); n <- ncol(y)
trait_names <- paste0("t", seq_len(p))
df <- as.data.frame(t(y))          # n × p, sites × traits
names(df) <- trait_names
df$site <- factor(seq_len(n))

fit <- gllvmTMB(
  as.formula(paste0(
    "traits(", paste(trait_names, collapse = ", "), ") ~ ",
    "1 + latent(1 | site, d = ", K, ", unique = FALSE)"
  )),
  data = df,
  unit = "site",
  family = gaussian(),
  control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

### Long call (explicit, easier to audit)

```r
df_long <- data.frame(
  site  = factor(rep(seq_len(n), each = p)),
  trait = factor(rep(trait_names, times = n), levels = trait_names),
  value = as.vector(y)   # R column-major on p×n ⇒ site 1 all traits, then site 2, …
)
fit <- gllvmTMB(
  value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
  data = df_long,
  unit = "site",
  trait = "trait",
  family = gaussian(),
  control = gllvmTMBcontrol(n_init = 1L, se = FALSE)
)
```

Wide and long are byte-equivalent objectives when pivoted correctly (`vignettes/gllvmTMB.Rmd`, `test-traits-keyword.R`).

### CRAN `gllvm` (secondary reference only)

If comparing to CRAN `gllvm` instead of gllvmTMB:

```r
fit_g <- gllvm::gllvm(
  y = t(y),              # n × p
  num.lv = K,
  family = "gaussian",
  seed = 42L,
  sd.errors = FALSE
)
```

**Do not use for the headline parity cell** — independent C++ engine, per-trait `beta0`, different optimiser; gllvmTMB's own comparator tolerates ~1% logL gap vs gllvm on Poisson (`test-comparator-gllvm.R`). Twin target remains **gllvmTMB**.

---

## 3. Extractor fields — logLik / sigma / Sigma

### gllvmTMB (canonical for this cell)

| Quantity | Extractor | Notes |
| --- | --- | --- |
| **logLik** | `as.numeric(logLik(fit))` | S3 method `logLik.gllvmTMB_multi`; equals `-fit$opt$objective` at convergence (`R/methods-gllvmTMB.R:740-795`) |
| **σ_eps** | `as.numeric(fit$report$sigma_eps)` | Fallback: `exp(unname(fit$opt$par["log_sigma_eps"]))` (`.gllvmTMB_sigma_eps`) |
| **Λ** (non-unique; do not assert entry-wise) | `getLoadings(fit, level = "unit")` or `extract_ordination(fit, level = "unit")$loadings` | `p × K`; rotation/sign arbitrary |
| **Σ_y shared block** | `extract_Sigma(fit, level = "unit", part = "shared")$Sigma` | `ΛΛᵀ` |
| **Σ_y total (J1-aligned when `unique=FALSE`)** | `Σ_shared + σ_eps^2 * I(p)` | With `unique=FALSE`, no Ψ diagonal; do **not** use `part = "total"` expecting extra Ψ |
| Convergence | `fit$opt$convergence == 0L` | |

### CRAN gllvm (draft used these — mostly wrong for loadings)

| Field | Meaning | Parity use |
| --- | --- | --- |
| `fit$logL` | total log-likelihood | OK scalar target |
| `fit$params$theta` | **Identification-constrained** matrix (1.0 on diagonal in standard parametrisation) | **NOT loadings** |
| `fit$params$sigma.lv` | LV scale on diagonal | Loadings = `theta %*% diag(sigma.lv)` (`getLoadings(fit)` or manual) |
| `fit$params$beta0` | per-column intercepts | Present even in no-X ordination; breaks zero-mean Julia model unless centred |
| `fit$params$sigma` / `phi` | dispersion / residual scales | Gaussian residual naming varies; prefer `getLoadings` + documented variance helpers over raw `params` |

Handover note (`docs/dev-log/handover/2026-07-29-claude-handover-vgh-heywood-gate.md:112-114`): omitting `sigma.lv` when reading `theta` produced bogus loadings comparisons.

---

## 4. Minimum Julia-side compare contract (logLik first)

**Phase A — logLik only (ship first):**

1. Shared seeded DGP (existing fixture OK after per-trait centring decision).
2. Julia: `fit_gaussian_gllvm(y_c; K=K)` → `jl_logL = fit.logLik`, require `fit.converged`.
3. R: gllvmTMB fit as §2 → `r_logL = rcopy(R"as.numeric(logLik(fit))")`.
4. Assert `@test jl_logL ≈ r_logL rtol=1e-6` (tighten from draft 1e-3 once live green; headline claim is machine precision on Gaussian).
5. Gate: `ENV["GLLVM_PARITY_TESTS"] == "1"`; skip cleanly if R/gllvmTMB missing.

**Phase B — rotation-invariant extras (after logLik green):**

6. `jl_σ = fit.pars.σ_eps` vs `r_σ = fit$report$sigma_eps` (`rtol ≈ 1e-4`).
7. `jl_Σ = ΛΛᵀ + σ²I` vs `r_Σ = extract_Sigma(..., part="shared")$Sigma + σ²I` (`atol ≈ 1e-4` entrywise or Frobenius relative).
8. Do **not** compare raw `Λ` / `theta`.

**Julia return shape (already in scaffold):** `GllvmFit.logLik::Float64`, `pars.Λ`, `pars.σ_eps`.

---

## 5. Blockers to a live green cell

| Blocker | Severity | Mitigation |
| --- | --- | --- |
| **Never run live** | Hard | Install R ≥4.2, `gllvmTMB` (GitHub dev or local checkout), `Pkg.build("RCall")` in `test/parity` |
| **Wrong R package in draft** | Hard | Replace `library(gllvm)` + `gllvm()` with `gllvmTMB::gllvmTMB()` |
| **Wrong extractors** | Hard | `logLik(fit)`, `fit$report$sigma_eps`, `extract_Sigma(..., part="shared")`; never `params$theta` |
| **Model mismatch: intercepts** | Hard | GLLVM zero-mean vs gllvmTMB `0+trait` intercepts — **centre per trait** or extend Julia fit with intercepts (out of scope for minimal cell) |
| **Model mismatch: Ψ** | Hard | Default `latent()` includes Ψ; must set **`unique = FALSE`** |
| **Optimiser / init luck** | Medium | Fix seed; `gllvmTMBcontrol(n_init = 1, se = FALSE)`; optionally match BFGS if needed |
| **CI exclusion by design** | Info | Parity opt-in only; not in default `Pkg.test()` |
| **RCall / R absent on agent host** | Env | Runner already exits 0 with skip message |

---

## A2 implementer checklist

**Path:** `/Users/z3437171/Dropbox/Github Local/GLLVM.jl/docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md`

- [ ] Confirm R + gllvmTMB installed; `julia --project=test/parity -e 'using Pkg; Pkg.instantiate(); Pkg.build("RCall")'`
- [ ] Replace draft R block in `test/parity/test_gaussian_parity.jl` with gllvmTMB call (§2 wide or long)
- [ ] Add per-trait centring of `y` (document in test comment) **or** prove intercept-free formula is accepted
- [ ] Set `latent(..., unique = FALSE)` and `family = gaussian()`
- [ ] Extract `as.numeric(logLik(fit))`, `fit$report$sigma_eps`, `extract_Sigma(..., part="shared")$Sigma`
- [ ] Phase A: single `@test` logLik `rtol=1e-6`; gate other asserts until green
- [ ] Run `GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` and paste pass tally in after-task report
- [ ] Tighten README tolerances once live-validated
- [ ] Update `docs/src/r-parity.md` row if status changes (translator skill)

**Twin R reference checkout:** `/tmp/gllvmtmb-parity-restart-20260801` (or `/Users/z3437171/Dropbox/Github Local/gllvmTMB`).

**Key R evidence files:**
- `R/methods-gllvmTMB.R` — `logLik.gllvmTMB_multi`
- `R/predictive-diagnostics.R` — `.gllvmTMB_sigma_eps`
- `R/extract-sigma.R` — `extract_Sigma`
- `tests/testthat/test-comparator-gllvm.R` — gllvm vs gllvmTMB ordination comparator (Poisson; documents `unique=FALSE` + `logL` pattern)
- `tests/testthat/test-aghq-surface.R` — Gaussian `unique=FALSE` formula reference
- `man/latent.Rd` — `unique=FALSE` semantics
