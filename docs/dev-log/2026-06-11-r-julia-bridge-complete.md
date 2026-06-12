# R→Julia bridge complete: `gllvmTMB(engine = "julia")` runs the GLLVM.jl engine

2026-06-11. The one-way R→Julia bridge — the "super-important" coupling point — is
now functional end-to-end and verified to machine precision against the native TMB
engine. R users can fit a GLLVM with the fast Julia engine through the ordinary
`gllvmTMB()` formula API.

## What landed

Two repos, local commits only (no push), feature branches:

- **GLLVM.jl** (`a1-nongaussian-ci`)
  - `8d65270` — `fix(bridge): accept scalar or matrix N in the binomial path`.
    `bridge_fit`'s binomial branch assumed `N` was matrix-like (`Matrix(N)`), so a
    scalar trials count from R hit `MethodError: no method matching Matrix(::Int64)`.
    Now handles `nothing` → Bernoulli, a scalar `Number` → broadcast, else a per-cell
    matrix. (Surfaced while wiring the R wrapper, which passes `N = 1L`.)

- **gllvmTMB** (`engine-julia`, branched off `main`)
  - `fa2bf71` — `feat(bridge): R-side engine='julia' wrapper over GLLVM.jl bridge_fit`.
    New `R/julia-bridge.R`: `gllvm_julia_setup()` (JuliaCall + GLLVM.jl load, once per
    session; path via `options(gllvmTMB.GLLVM.jl.path=)` or `GLLVM_JL_PATH`),
    `gllvm_julia_fit()` (matrix API → `GLLVM.bridge_fit` → a `gllvmTMB_julia` list with
    `logLik`/`print` methods), and a family map (gaussian/poisson/binomial/nbinom2/
    nbinom1/beta/gamma/ordinal/lognormal + a list for mixed). JuliaCall is a soft
    dependency: every entry errors cleanly if it (or the GLLVM.jl path) is absent.
  - `238af7e` — `feat(bridge): wire engine='julia' into the gllvmTMB() formula API`.
    `gllvmTMB(..., engine = c("tmb","julia"))`. `engine="julia"` routes the *parsed*
    model to `.gllvmTMB_julia_dispatch()` right after `desugar_brms_sugar()` +
    `parse_multi_formula()`, so the user grammar (latent/dep/indep/unique) is
    interpreted exactly as the TMB engine interprets it. The dispatch pivots the long
    `(trait, unit)` response to a `p × n` matrix, reads `K` from the `rr` latent block,
    maps the family, and routes to `gllvm_julia_fit()`.

## Verification (all green)

- **Matrix API** (`/tmp/test_julia_bridge_wrapper.R`): family map (5 cases), gaussian/
  poisson/binomial/mixed fits, `units_are_rows` transpose, S3 methods; **exact loglik
  parity** vs a direct `bridge_fit` call (|Δ| = 0).
- **Formula API** (`/tmp/test_engine_julia.R`): `gllvmTMB(y ~ 0 + trait +
  latent(0 + trait | site, d = 2), engine = "julia")` for gaussian + poisson; correct
  `K`/dims/trait levels; **formula-path vs hand-built-matrix loglik parity exact**
  (|Δ| = 0) — proves the long→wide pivot and the grammar mapping are correct.
- **TMB ↔ Julia parity** (`/tmp/test_tmb_vs_julia.R`): same Gaussian model both engines
  → **logLik agree to 3.91e-12** (relative). Exceeds the plan DoD (≤ 1e-6 vs pure-R TMB).
- **Regression**: default `engine = "tmb"` unchanged (additive `engine` arg, default
  path fits as before: logLik −311.3181, 0.4 s).

## Scope of `engine = "julia"` (honest boundaries — loud errors, no silent approximation)

Supported now: the **unconstrained-ordination core** — a single reduced-rank latent
block (`latent(... d = K)`) + per-trait intercepts (`0 + trait`), for every family the
bridge exposes, on a **balanced** trait × unit table.

Rejected loudly with a pointer to `engine = "tmb"`:
- structured / grouped / phylo / spatial covariance terms (`diag`/`propto`/`equalto`/
  `spde`/`phylo_rr`/`re_int`) — not yet in `bridge_fit`;
- fixed-effect covariates beyond the per-trait intercept (Xβ);
- `cbind(successes, failures)` binomial;
- unbalanced tables (empty trait × unit cells).

## Follow-ups (documented deferrals, each its own slice)

1. **Gaussian Xβ via the bridge** — `bridge_fit` already accepts a Gaussian `X` array;
   the dispatch just needs to build it (p × n × q) from the long covariates + verify
   parity. Highest-value next extension (environmental covariates in SDM).
2. **Unbalanced data (NA cells)** — GLLVM.jl already does NA-FIML; needs verifying that
   R `NA` flows through JuliaCall → a missing-typed Julia matrix in `bridge_fit`, then
   drop the balanced-only restriction.
3. **Structured / grouped / phylo terms via the bridge** — expose the RE fitters
   (`fit_gaussian_structured_re`, …) through `bridge_fit`, then map the covstructs.
4. Package mechanics for CRAN: add `JuliaCall` to `Suggests`; `@export` the public
   bridge functions (roxygen tags present); a skip-if-no-Julia testthat fixture.

The maintainer/Codex own the gllvmTMB R-side merge (`engine-julia` → `main`); these
edits are additive and default-off (`engine = "tmb"`), so they are safe to review and
merge deliberately.
