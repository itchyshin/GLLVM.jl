# `@formula` front-end — dependency decision memo (maintainer call needed)

- **Status: DECISION REQUIRED from the maintainer.** This is not a design (that
  exists: `2026-05-31-formula-frontend-random-slopes-design.md`); it is the
  *one gating decision* that blocks starting the build — adding the package's
  first formula/data-frame dependencies.
- Date: 2026-06-01

## Why this is a separate, gated decision

The `@formula` front-end is the headline R-syntax-parity feature (issue #6) and is
fully designed. But its slice 1 ("Deps + skeleton") adds **GLLVM.jl's first
formula/data dependencies**, which per `AGENTS.md` ("API-surface change → maintainer
approval") and the design spec §6.1/§7 is **explicitly your call**. An agent should
not add these unilaterally. Everything else in the front-end is mechanical once the
deps are in; this memo exists so the decision can be made cleanly and the build can
then proceed.

## What gets added

| Dependency | Why | Weight |
|---|---|---|
| **StatsModels.jl** | the `@formula` macro, `schema`/`apply_schema`/`modelcols`, custom-term protocol (for `traits()`/`phylo()`/`latent()`). The ecosystem standard (GLM.jl, MixedModels.jl build on it). | medium; pulls `StatsAPI` (already transitive), `ShiftedArrays` |
| **Tables.jl** | accept any `Tables`-compatible frame (DataFrames, NamedTuple of columns, …) for the wide/long data front doors. | light, near-universal |
| (transitive) **CategoricalArrays.jl**, **DataAPI.jl** | contrast coding of categorical covariates / grouping factors. | light |

No heavy solver deps. The design spec recommends **vendoring** a ~200-line `|`-term
(random-effects grammar) rather than depending on **MixedModels.jl**, to avoid its
fitting stack — that keeps the dependency footprint to the two above.

## The three sub-decisions (spec §7 "open questions")

1. **Approve StatsModels + Tables?** (the gate). Recommended: **yes** — there is no
   lighter way to mirror R's formula grammar, and hand-rolling a parser is worse.
2. **Vendor the `|` random-effects term, or depend on MixedModels.jl?**
   Recommended: **vendor** (avoid the heavy dep; the IR needs only the parsed
   `(slopes | group)` structure).
3. **Random-slope covariance: per-species `G_t` (default) vs shared `G`?**
   Recommended: **per-species** (matches the package's per-trait variance style).

## What unblocks once approved

Slices 1–4 of the design (fixed effects → `X`, `traits()`/`latent()`/`phylo()`
terms, wide↔long round-trip) — the front-end is **shippable on the existing
Gaussian + Laplace engine before** any random-slope engine work, giving immediate
ergonomic value and the precondition for the R-bridge `engine="julia"` path and for
tutorials at gllvmTMB parity. The headline random-slope *engine* work (design
slices 5–8) is a larger, separate effort and need not block the front-end.

## Recommended decision

**Approve StatsModels + Tables; vendor the `|` term; per-species `G_t`.** Then build
design slices 1–4 (front-end) first, as a self-contained PR, validated by the
wide↔long round-trip identity and a logLik-parity check against the matrix-level
`fit_gaussian_gllvm`. Defer the random-slope engine to a follow-on.

> Note for the build agent: do **not** add these dependencies until the maintainer
> records approval here (or in the PR). Until then, the front-end is blocked by
> design, not by effort.
