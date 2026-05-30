---
name: add-family
description: Add a new non-Gaussian response family to GLLVM.jl with Laplace-approximated likelihood, link functions, Julia multiple-dispatch wiring, ADEMP recovery test, and documentation. Use when extending Phase 3 (non-Gaussian families) beyond the Gaussian-only v0.1.0 pilot.
---

# Add a Distribution Family (GLLVM.jl, Phase 3)

Use this skill when adding a new response family to `GLLVM.jl`. The v0.1.0 pilot is **Gaussian only**; Phase 3 expands the package to the full GLM family set (Poisson, binomial, ordinal, negative binomial, beta, hurdle / zero-inflated). This skill governs that expansion.

Before starting, study the existing Gaussian path. The marginal log-likelihood is a single function (`gaussian_marginal_loglik` in `src/likelihood.jl`); `fit_gaussian_gllvm` (`src/fit.jl`) is a thin driver around Optim + PPCA warm-start. The non-Gaussian path should follow the same skeleton: one `*_marginal_loglik_laplace` per family, one `fit_*_gllvm` driver per family, shared packing / Cholesky / init helpers.

## Hard prerequisites

These must exist (or be built as part of the same slice) **before** a family lands:

- **`src/laplace.jl`** — Laplace-approximation infrastructure for the marginal likelihood. Gaussian + identity admits a closed-form marginal; no other family does. Phase 3.1 deliverable. Do not duplicate Laplace machinery across families.
- **Link function infrastructure** — declarative table of links (`logit`, `log`, `probit`, `cloglog`, `identity`, …) with `linkfun` / `linkinv` / `mu_eta` (the d mu / d eta derivative) and numerically stable evaluations on the log / logit scale where needed. See the **Link table** section below.
- **Family abstract type** — `abstract type Family end` with concrete subtypes (`struct Poisson <: Family`, `struct NegativeBinomial <: Family; r::Float64 end`, etc.). Dispatch all family-specific logic through Julia multiple dispatch on the `Family` type. **Do not** replicate the 23-branch hardcoded `switch`/`if-elseif` dispatch pattern from `drmTMB`'s `Family()` constructor — that pattern does not scale and fights the language.

## Required outputs (Definition of Done)

A family is not done until every item below is delivered. Skip none.

1. **Math derivation doc** at `docs/design/families/<family>.md`, covering:
   - Density / mass function on the numerically stable scale.
   - Link choices, with the canonical link marked.
   - Laplace approximation derivation: mode-finding equation, Hessian at the mode, marginal log-likelihood expression.
   - Parameter bounds and identifiability notes.
   - Variance function and what `predict(type=:response)`, `fitted`, `dispersion` should return.
2. **Implementation** in `src/families/<family>.jl`:
   - `struct <Family> <: Family` (with dispersion / shape fields as needed).
   - `loglik(::<Family>, ::<Link>, y, eta)` — pointwise log-density on the natural scale, numerically stable.
   - `<family>_marginal_loglik_laplace(...)` — driver over the Laplace approximation.
   - `init_<family>(...)` — starting values (see init strategy below).
3. **ADEMP parameter-recovery test** under `test/families/test_<family>_recovery.jl`. Use the `add-simulation-test` skill to scaffold this; it must follow Morris et al. (2019) ADEMP and Williams et al. (2024) reporting.
4. **Link table entry** in `docs/design/links.md`: add the family's row (links supported, canonical link, fitted-response rule, variance rule, parameter meaning).
5. **Docstrings** on the exported family constructor and the fit driver, with one runnable example.
6. **Tutorial stub** under `docs/src/families/<family>.md` showing simulate → fit → CI → diagnostics on a small example.
7. **After-task audit**: run the full test suite via `julia --project=. test/runtests.jl` (do **not** use `Pkg.test()` — it fails here), paste the actual pass/fail tally, and confirm the recovery test is included in the run.
8. **Rose audit** — submit the slice for the maintainer's Rose audit before any commit / push. Do not stage or push without explicit instruction.

## Checklist (work order)

Follow this order. Each step has a verification check; do not advance until it passes.

1. **Define response dimension**: univariate (most) or bivariate (delta / hurdle).
2. **Define distributional parameters** and which are estimated vs. fixed (e.g. NB shape `r`, beta precision `phi`, ZI probability `pi`).
3. **Define the link table entry**: supported links, canonical link, fitted-response rule, variance rule, parameter meaning. Add the row to `docs/design/links.md` **before** writing code.
4. **Define native parameter meanings** so users know what `coef` returns.
5. **Define `predict(type=:response)`, `fitted`, `dispersion` semantics**.
6. **Define the variance rule** (or document why no finite variance exists, e.g. some hurdle parameterisations).
7. **Define valid parameter bounds** for the optimiser and the boundary handling for CIs.
8. **Write the log-likelihood on a numerically stable scale**: use `logaddexp`, `log1p`, `log1mexp`, etc.; never form `log(p)` after `p = exp(x)` round-trips.
9. **Wire Julia multiple dispatch**: `loglik(::<Family>, ::<Link>, y, eta)` and `linkinv(::<Link>, eta)`. Avoid `if family == :poisson … elseif family == :binomial …` — dispatch on the type.
10. **Add the Laplace driver** by calling `src/laplace.jl`; do not reimplement the inner Newton / quasi-Newton step inside the family file.
11. **Add the starting-value strategy** (see init strategy below).
12. **Add the ADEMP recovery test** via the `add-simulation-test` skill. Recovery must hit nominal coverage within Monte Carlo error for the chosen cells; if it does not, fix the cause, not the gate.
13. **Add boundary / degenerate-case tests**: zero counts (Poisson), all-success / all-failure (binomial), zeros-only (hurdle), separation (logit).
14. **Add link-scale, response-scale, and fitted prediction tests**.
15. **Add user-facing documentation** (docstrings + tutorial stub).
16. **Run the full test suite** (`julia --project=. test/runtests.jl`); paste the pass/fail tally.
17. **Submit for Rose audit**.

## Link table convention

Declarative pattern, Julia-native dispatch. Define links as singleton types:

```julia
abstract type Link end
struct LogitLink   <: Link end
struct LogLink     <: Link end
struct ProbitLink  <: Link end
struct CLogLogLink <: Link end
struct IdentityLink <: Link end

linkfun(::LogitLink, mu)   = log(mu / (1 - mu))   # use logit() from a stable helper
linkinv(::LogitLink, eta)  = 1 / (1 + exp(-eta))  # use logistic() from a stable helper
mu_eta(::LogitLink, eta)   = (e = exp(-eta); e / (1 + e)^2)
```

The link table in `docs/design/links.md` is the **specification**; the Julia structs are the **implementation**. They must agree. Do not encode the link semantics in a giant `if` block inside each family — make the family loop over `linkinv(link, eta_ij)` and let dispatch do the rest.

Why this differs from `drmTMB`: the R package uses a single `Family()` helper with a hardcoded 23-branch dispatch because R cannot dispatch on type parameters the way Julia can. In Julia, the multiple-dispatch design is shorter, faster, and easier to extend — one new `struct` plus a few methods per family, no edits to a central switch statement.

## Init strategy

PPCA (`src/ppca_init.jl`) assumes Gaussian + identity. For non-Gaussian families, choose **one** of:

- **Generalise PPCA** by transforming the response onto an approximately Gaussian scale and running PPCA there (e.g. `log(y + 0.5)` for Poisson, `qnorm` of empirical CDF for binomial counts), then map starting values back. Cheaper.
- **Accept a slower init**: marginal GLM per species to seed `beta` and dispersion, random `Lambda` with small magnitude, then let the Laplace-EM or LBFGS step take over. Simpler, but more iterations.

Document the choice in the family's math doc and the docstring. Do not silently pick one.

## Hard rules

- **No engine surgery on R's `gllvmTMB`.** That R package is a read-only reference; do not modify it.
- **No push without explicit maintainer instruction.** Commit locally first; ask before pushing.
- **Stage by name** (`git add path/to/file`). Never `git add -A` or `git add .`. Other agents may be working on disjoint files in parallel.
- **One concern per commit**: math doc, implementation, tests, link-table edit, and docs should be separable commits — keep refactors and cosmetic changes out.
- **No silent tolerance widening**: if the recovery test fails, fix the cause (init, link parameterisation, Laplace integration), not the gate.
- **Verify before claiming**: paste the actual `julia --project=. test/runtests.jl` tally before reporting the family as done.
- **Families must serve a clear distributional-regression use case.** Do not add a family because it exists in `gllvmTMB`, `glmmTMB`, or VGAM. Justify it in the math doc.

## Key references

- Bates et al. 2015 (lme4 sparse skeleton, *J Stat Soft*)
- Kristensen et al. 2016 (TMB; Laplace + sparse Cholesky adjoint, *J Stat Soft*)
- Skaug & Fournier 2006 (Automatic Laplace approximation, *CSDA*)
- Morris et al. 2019; Williams et al. 2024 (ADEMP reporting framework)
- Niku et al. 2019 (`gllvm` R package; Laplace + variational families)
