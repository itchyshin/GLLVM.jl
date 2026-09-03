# `structure=` kwarg — public wrapper notes (core070, round2-3 #6)

## Decision

Maintainer decision round2-3 #6
(`docs/dev-log/decisions/2026-09-01-maintainer-decisions-round2-3.md`):
expose the structured-term source grammar (`indep`, `dep`, `scalar`,
`kernel_indep`, `kernel_scalar`, `kernel_dep`, `kernel_latent`) publicly via
an explicit `structure=` fit kwarg taking raw term `Expr`s — **no macro**. A
full grammar macro (e.g. letting a user write `structure(indep(0 + trait | g))`
directly instead of quoting `:(indep(0 + trait | g))`) is deferred to a later,
separately maintainer-approved decision.

## What shipped

- `src/formula.jl`: `fit_gaussian_structured(Y, data; structure::Vector{Expr},
  family=Normal(), kernel_env=NamedTuple(), kwargs...)` — a public, exported,
  documented thin wrapper over the existing lane-internal
  `_fit_gaussian_structured_sources` (src/formula.jl:626-645 pre-existing).
  Runs the identical pipeline: `_recognize_source_term` per `Expr` →
  `_check_source_term_exclusions` (Step 4 mutual-exclusion gates) →
  `_source_term_covariance` per spec → `fit_gaussian_sources`. Every named
  error already raised by that pipeline (augmented-LHS rejection, non-literal
  flag rejection, unknown term name, mutual-exclusion violations, PD-strict
  kernel rejection, ...) surfaces unchanged through the public wrapper — no
  new error paths were introduced except the family gate below.
- Gaussian-only gate: `family` must be `Normal()`
  (`Distributions.Normal`, matching `fit_gaussian_sources`'s scope, which
  takes no `family` argument at all); any other value throws a named
  `ArgumentError` rather than silently ignoring the kwarg.
- `src/GLLVM.jl`: added `fit_gaussian_structured` to the `export` list
  (next to `SourceCovariance`, `fit_gaussian_sources`, `GaussianSourcesFit`).
- `test/test_formula_structured_terms.jl`: new testset
  `"fit_gaussian_structured: public structure= wrapper (round2-3 #6)"`
  (9 tests), reusing the file's existing Step 1 / Step 6 fixtures rather than
  re-deriving coverage:
  - public path ≡ internal path (loglik + beta) on a plain `indep()` term
    and on an `indep()` + `kernel_latent()` combination with a
    `kernel_env`-backed kernel matrix (proves kwarg forwarding, not just the
    trivial no-kernel case);
  - named errors surface identically through the public wrapper (augmented
    LHS; Step 4 mutual-exclusion gate on `dep` + `indep` over one grouping);
  - the Gaussian-only family gate rejects a non-`Normal` family
    (`Distributions.Poisson()`) with a named `ArgumentError`;
  - default `family=Normal()` needs no explicit kwarg;
  - a doctest-style test that runs the exact worked example from the
    docstring (kernel_latent + indep terms) end to end and checks
    `isfinite(fit.loglik)`.

## Why `Expr`, not `@formula`

StatsModels' `@formula` macro parses its RHS into `Term`s at macro-expansion
time and has no hook for a `lhs | group`-headed call — it rejects the bar
syntax as a parse error before any GLLVM code runs. `structure=` sidesteps
this entirely: the caller quotes each term with `:(...)`, and GLLVM's own
recognizer (`_recognize_source_term`) walks the raw `Expr` tree. This is
documented in the wrapper's own docstring, not just here, so it survives a
future rename/refactor of this notes file.

## Verification

```
julia --project=. -e 'using Test; include("test/test_formula_structured_terms.jl")'
```

Result: all 8 pre-existing testsets green (58 tests) plus the new testset
green (9 tests) — 67/67 tests pass, no failures, no errors.

Clean-load check:

```
julia --project=. -e 'using GLLVM; @assert isdefined(GLLVM, :fit_gaussian_structured)'
```

Result: loads cleanly, symbol defined and exported.

## Owed work (explicitly deferred, not silently dropped)

The convention-change cascade required by `AGENTS.md` §"Convention-change
cascade" for a new public/exported symbol — README.md, Documenter tutorials,
reference pages — is **deferred to the docs arc**, per the maintainer's
framing of this task ("full grammar macro later" / cascade is a separate
docs-arc concern for this specific API addition). This notes file plus the
docstring in `src/formula.jl` are the complete slice owned by this task. Do
not treat this deferral as closing the cascade obligation — the docs arc
still owes README/tutorial/reference updates before this symbol is
considered fully cascaded per AGENTS.md.

## Files touched (this task's ownership only)

- `src/formula.jl` — public wrapper section (`fit_gaussian_structured`)
- `src/GLLVM.jl` — export line only
- `test/test_formula_structured_terms.jl` — additions only (new testset)
- `docs/dev-log/core070/structure-kwarg-notes.md` — this file

Did not touch: `src/source_fit.jl`, `src/postfit.jl`, `src/model_selection.jl`,
`src/bridge.jl`, `src/extractors.jl`, `src/families/binomial.jl`, or any file
other agents in this session hold (postfit/model_selection/bridge/extractors/
families/re_sd/diagnostics), per the task's ownership boundary.
