# StatsAPI generic shadowing — a measured interop defect (not "missing methods")

**Date:** 2026-08-25 · **Lane:** `claude/lane-beyond-20260824` · **Status:** FOUND, NOT FIXED
**Reclassifies:** ultra-plan slice **S22** ("Missing StatsAPI methods")

## The finding

The plan recorded S22 as an *additive* gap — `coef`, `vcov`, `nobs`, `dof`,
`loglikelihood` have no implementations. That is true, but it is the smaller half.

A full sweep of all **301** GLLVM exports against StatsBase, Distributions,
StatsModels and Base found **7 exported names that shadow another package's**
(same name, unrelated generic). They split into two very different groups.

**Group A — 1 name, known and deliberate.** `Multinomial` shadows
`Distributions.Multinomial`. This is *already documented*, twice and precisely:
`docs/src/response-families.md:77` (family table) and `:428-437`, which states the
exact consequence — *"the bare name `Multinomial` is undefined rather than resolving
to either one"* — and gives the workaround `GLLVM.Multinomial()`. **Not a defect.**
Recorded here only because the sweep returned it.

**Group B — 6 names, undocumented.** These shadow StatsBase/StatsAPI because
`src/GLLVM.jl` never imports StatsAPI, so they are unrelated generics that happen to
share a name:

| exported by GLLVM | also exported by StatsBase | same generic? | documented? |
|---|---|---|---|
| `confint` | yes | **no** | **no** |
| `aic` | yes | **no** | **no** |
| `bic` | yes | **no** | **no** |
| `predict` | yes | **no** | **no** |
| `fitted` | yes | **no** | **no** |
| `residuals` | yes | **no** | **no** |

`grep -rn "StatsBase\|StatsAPI" docs/src/*.md README.md` → **no matches**. Neither
package is mentioned anywhere in the user-facing documentation.

**Why the split matters.** The package demonstrably *has* the concept of export
collisions — someone wrote a careful paragraph about it for `Multinomial`. The audit
was simply never generalised to the rest of the export list, and the six it missed are
the most-used post-fit verbs. Unlike `Multinomial`, these six have a fix that removes
the collision outright rather than requiring the user to qualify.

## Measured consequence

```julia
using GLLVM, StatsBase
confint(fit, Y; method = :wald)
```
```
WARNING: both StatsBase and GLLVM export "confint"; uses of it in module Main must be qualified
ERROR: UndefVarError: `confint` not defined
```

Reproduced for all six Group-B names. Probes:
`scratchpad/statsapi-probe/probe2.jl` (targeted: compares
`getfield(GLLVM,n) === getfield(StatsBase,n)`, then evaluates each name in `Main`) and
`sweep.jl` (exhaustive: all 301 exports × 4 ecosystem modules).

These six are not obscure corners — they are the documented post-fit verbs:
`docs/src/confidence-intervals.md:17-19,81,97` and `docs/src/tutorial.md:242` are
written entirely in terms of `confint` and `predict`.

## Why CI cannot see it

```
grep -rn "using StatsBase\|import StatsBase" test/ docs/   →   (no matches)
```

Every test and every doc example loads `GLLVM` alone, so the shadowing never
materialises. The suite is green and the defect is real at the same time. This is the
same shape as the curvature fault class: **nothing in the suite compares two entry
points, so the disagreement is structurally invisible.**

Realistic trigger: any user who loads StatsBase for `mean`/`sample`, or who compares
GLLVM.jl against GLM.jl / MixedModels.jl in one session — i.e. exactly the parity and
benchmarking workflow this package is built around.

## The fix shape (NOT applied — needs maintainer approval)

Add `StatsAPI` (a zero-dependency, ultra-light package) and re-root, rather than
inventing new generics:

```julia
import StatsAPI: confint, aic, bic, predict, fitted, residuals,
                 coef, vcov, nobs, dof, loglikelihood, stderror, coeftable
```

Then the existing definitions become *methods* on the shared generic, and the seven
genuinely-missing verbs are added on the same footing.

Source-compatible for existing users: `using GLLVM; confint(fit, Y)` keeps working.
What changes is function *identity*, which is what removes the collision.

## Why this is not self-merge

AGENTS.md merge authority: *"Maintainer approval required (high risk): any API
change"*. Re-rooting six exported generics and adding a dependency is an API change,
even though it is behaviour-preserving at the call site. **Flagged for Shinichi, not
shipped.**

Also required by the convention-change cascade if it proceeds: docstrings, Documenter
pages, tests, README — same PR.

## Anti-recurrence

The fix alone does not stop this returning. Add a test that does
`using GLLVM, StatsBase` and asserts `GLLVM.confint === StatsBase.confint` for every
shared name. Better, port `sweep.jl` into the suite as a standing check over the whole
export list with `Multinomial` as the single declared exception — that is what turns a
one-off audit into a guard. Without it, the next exported verb that collides is
invisible again.
