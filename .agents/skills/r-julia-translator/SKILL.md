---
name: r-julia-translator
description: >
  Use when porting/translating any gllvmTMB R-side API to GLLVM.jl, building
  parity tests under GLLVM_PARITY_TESTS, or auditing API mirror coverage.
---

# r-julia-translator

Hopper's working method for keeping GLLVM.jl's user-facing API legible to
gllvmTMB users without inheriting R idioms that don't fit Julia. Three jobs:

1. **Maintain the API mirror table** (`docs/src/r-parity.md`).
2. **Build parity tests** that run an R fit and a Julia fit on the same data
   and compare numerically, gated behind `ENV["GLLVM_PARITY_TESTS"] == "1"`.
3. **Catch up** when gllvmTMB ships a new article / feature: open an issue,
   trigger Workflow D, and update the mirror.

This is a *translator*, not a reimplementer. Engine work belongs in the
`add-family` and `julia-likelihood-review` skills. Translator only touches the
thin user-facing layer + the parity test harness.

---

## 1. API mirror table — `docs/src/r-parity.md`

Single source of truth for "what gllvmTMB function maps to what GLLVM.jl
function, and is the parity claim tested." Lives at
`docs/src/r-parity.md` so pkgdown / Documenter render it on the docs site.

### Schema

| gllvmTMB (R)                                          | GLLVM.jl (Julia)                              | Status         | Test                                  |
|-------------------------------------------------------|-----------------------------------------------|----------------|---------------------------------------|
| `gllvmTMB::gllvmTMB(y ~ x, data, family = gaussian)`  | `GLLVM.fit_gaussian_gllvm(Y, X)`              | ✓ tested       | `test/parity/test_gaussian_fit.jl`    |
| `gllvmTMB::predict.gllvmTMB_multi()`                  | `GLLVM.predict(::GllvmFit)`                   | ⚠ tested-not-passing | `test/parity/test_predict.jl`   |
| `gllvmTMB::ranef.gllvmTMB()` (phy BLUPs)              | `GLLVM.ancestral_states(::EmPhyloFit)`        | ✓ tested       | `test/parity/test_phy_blups.jl`       |
| `gllvmTMB::profile.gllvmTMB()`                        | `GLLVM.confint_profile`                       | ✓ tested       | `test/parity/test_profile_ci.jl`      |
| `gllvmTMB::confint.gllvmTMB(method = "wald")`         | `GLLVM.confint`                               | ✓ tested       | `test/parity/test_wald_ci.jl`         |
| `gllvmTMB::bootstrap()`                               | `GLLVM.confint_bootstrap`                     | ✓ tested       | `test/parity/test_bootstrap_ci.jl`    |
| `gllvmTMB::summary.gllvmTMB()`                        | `Base.show(::IO, ::GllvmFit)` + `summary`     | ✗ not implemented | —                                   |
| `gllvmTMB::simulate.gllvmTMB()`                       | `GLLVM.simulate_gaussian_gllvm`               | ✓ tested       | `test/parity/test_simulate.jl`        |

### Status legend (fixed, don't invent new tiers)

- **`✓ tested`** — parity test exists, runs under `GLLVM_PARITY_TESTS=1`, and
  passes within the tolerance ladder below.
- **`⚠ tested-not-passing`** — parity test exists and runs, but fails or has
  known tolerance violations. The row must link to a tracking issue.
- **`✗ not implemented`** — Julia side does not exist. No test required, but
  the row stays in the table so coverage gaps are visible.

### Maintenance rules

- Every public Julia export that corresponds to a gllvmTMB function gets a
  row. No silent omissions.
- When a parity test moves from failing to passing (or vice versa), update
  the status cell in the **same commit** as the test change.
- Row order: match the order of the gllvmTMB reference manual (fit → predict
  → summary → diagnostics → CIs → simulate). New rows go in the position the
  gllvmTMB manual would put them, not at the end.

---

## 2. Parity test pattern

Parity tests live in `test/parity/`. They use RCall.jl to fit the R model
in-process, then fit the Julia model on the same simulated data, then compare
named quantities. They are **gated** so CI's default Linux runner doesn't try
to install gllvmTMB.

### Gating

```julia
# at the top of every test/parity/test_*.jl file
const PARITY = get(ENV, "GLLVM_PARITY_TESTS", "0") == "1"
PARITY || (@info "skipping parity tests (set GLLVM_PARITY_TESTS=1 to run)"; return)
```

`test/runtests.jl` includes the `parity/` files unconditionally; the gate
above turns each file into a no-op when the env var isn't set. This matches
how `GLLVM_PERF_TESTS` is already gated in this repo (see recent commits).

### Skeleton

```julia
using Test, RCall, GLLVM, Random

@testset "Gaussian Wald CI parity" begin
    Random.seed!(42)
    sim = GLLVM.simulate_gaussian_gllvm(n = 200, p = 8, d = 2)

    # R side
    R"library(gllvmTMB)"
    @rput sim
    r_fit = R"""
        gllvmTMB::gllvmTMB(
            cbind(y1, y2, ..., y8) ~ x1 + x2,
            data = sim$df,
            family = gaussian
        )
    """
    r_coef = rcopy(R"coef($r_fit)")
    r_se   = rcopy(R"summary($r_fit)$coef[, 'Std. Error']")

    # Julia side
    j_fit = GLLVM.fit_gaussian_gllvm(sim.Y, sim.X)
    j_coef = GLLVM.coef(j_fit)
    j_se   = GLLVM.stderror(j_fit)

    @test isapprox(r_coef, j_coef, atol = 1e-5)
    @test isapprox(r_se,   j_se,   atol = 1e-4)
end
```

### Conventions

- One `@testset` per gllvmTMB function being mirrored.
- Always simulate Julia-side and pass the data into R via `@rput`. Never let
  R simulate — `set.seed()` in R does not commute with `Random.seed!()` in
  Julia and you'll chase phantom diffs.
- Compare named scalars/vectors. Don't compare whole fit objects.
- If you need to compare logL, use `R"logLik($r_fit)"` and
  `GLLVM.loglikelihood(j_fit)`, with the **logL tolerance** below.

---

## 3. Numerical tolerance ladder

Use these tolerances; don't invent new ones per test. Loosen only with an
explicit reason in a comment.

| Quantity                  | `atol`   | Why                                          |
|---------------------------|----------|----------------------------------------------|
| Log-likelihood            | `1e-6`   | Tightest. Closed-form Gaussian + identity link. |
| Coefficients (β, Λ)       | `1e-5`   | Optimiser stopping criteria differ slightly.  |
| Standard errors           | `1e-4`   | Hessian inversion / finite-difference noise.  |
| Profile CI endpoints      | `1e-3`   | Bracket-then-bisect vs uniroot; loosest tier. |
| Bootstrap CIs (per draw)  | —        | Compare distributions, not point-equality.    |

For bootstrap parity, fix the R and Julia seeds **independently** and check
that the resulting interval *widths* and *coverages* agree to within Monte
Carlo error — exact endpoint match across two RNG streams is impossible.

---

## 4. Idiom mapping rules

R's user-facing patterns don't all port cleanly. Use these rules; don't
machine-translate.

- **R formula `y ~ x | g`** → Julia `@formula(y ~ x + (1|g))`.
  R's `|` in `gllvmTMB` overloads as a random-effect grouping operator
  inside the LV layer; Julia's StatsModels.jl uses the lme4-style explicit
  `(1|g)` notation. **Document the difference inline** in the mirror table
  comment column — don't silently translate.
- **R's S3 `summary(fit)`** → Julia's two-method idiom: `Base.show(io, fit)`
  for the REPL print and a dedicated `summary(fit)` returning a struct.
  Never overload `Base.show` to do statistical work — keep show as
  formatting only.
- **R's NSE (e.g. `gllvmTMB(y ~ x, data = df)`)** → Julia macros
  (e.g. `@formula(y ~ x)`). Do not try to recreate NSE by string-evaling
  expressions — that path is brittle and Julians will rightly hate it.
- **R's `family = gaussian()`** → Julia's `Distributions.Normal` type
  (when family layer lands; Gaussian-only for now). Pass the **type**,
  not an instance, to mirror lme4 / MixedModels.jl.
- **R's `update(fit, . ~ . + z)`** → Julia just re-fits. There is no
  `update` method, and we are not planning to add one. Document the
  absence in the mirror table.

---

## 5. Catch-up tracker

gllvmTMB is under active development; the maintainer expects ~10 new
articles / vignettes / features over the next year. When one lands:

1. **Open an issue** titled `parity: catch up on <article-name>` with the
   gllvmTMB commit/release tag, a one-paragraph summary of what's new, and
   a checklist of (a) new exported R function(s) to mirror, (b) new
   docs/src/r-parity.md row(s) needed, (c) new parity test file(s) needed.
2. **Trigger Workflow D** (Hopper's "translator catch-up" workflow) for that
   article — the workflow runs add-family / julia-likelihood-review for
   any new engine work, then loops back here for the user-facing mirror.
3. **Update the mirror table** in the same PR as the implementation, with
   status `⚠ tested-not-passing` until the parity test passes, then `✓ tested`.
4. **Do not** silently mirror an API without a parity test. A row with
   no test column entry is an audit failure.

If the new gllvmTMB feature is *deliberately not mirrored* (e.g. an R-only
plotting helper, or an idiom that doesn't translate), add the row with
status `✗ not implemented` and a comment column explaining the deliberate
non-port. This way coverage is honest.

---

## Hard boundaries

- **No edits to R's gllvmTMB source.** That repo is read-only reference.
  This skill reads `gllvmTMB::` symbols and the gllvmTMB manual; it does
  not modify them.
- **No engine work.** If a parity test fails because the Julia engine is
  wrong, file a hand-off issue for the `add-family` or
  `julia-likelihood-review` skills. Translator does not touch
  `likelihood.jl`, `fit.jl`, the EM solvers, or the phylo paths.
- **No widening of the tolerance ladder** to make a failing test pass.
  Either fix the underlying numerical issue (engine skill's job) or mark
  the row `⚠ tested-not-passing` and open an issue.
- **Parity tests stay gated.** Do not remove the `GLLVM_PARITY_TESTS`
  guard. Default CI must not try to install gllvmTMB.
