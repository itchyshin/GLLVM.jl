---
name: julia-package-development
description: >
  Use when working on Julia package hygiene — Project.toml, exports,
  Aqua.jl, JET.jl, Allocs.jl, version bumps, Manifest stability.
---

# Julia package development

Discipline for maintaining a Julia package: dependency bounds, module
structure, static checks, allocation budgets, version bumps, and the
test invocation. Mirrors what `r-package-development` does for R, adapted
to Julia tooling. Applies to GLLVM.jl and other Julia libraries the
maintainer ships from this machine.

## 1. Project.toml hygiene

`Project.toml` is the package manifest. It pins identity (`name`, `uuid`,
`version`, `authors`), declares dependencies (`[deps]`), and bounds them
(`[compat]`). A clean `Project.toml` is the single most important
hygiene artifact — Pkg's resolver, the registry's auto-merge bot, and
downstream users all read it.

Rules:

- **Every `[deps]` entry must have a matching `[compat]` entry.** No
  exceptions. An uncapped dep means any future breaking release of that
  package silently becomes part of your supported set.
- **Compat entries use semver lower bounds**, written in Julia's compat
  shorthand (`"1.6"` means `[1.6, 2)`, equivalent to `^1.6`). Prefer the
  bare-number form over explicit `^` — it's the registry convention.
- **Never `[compat] julia = "1"`.** That permits any 1.x release back to
  1.0, including ones that lack features (e.g. package extensions need
  1.9, public/private keyword needs 1.11). Use the actual minimum you
  test against, e.g. `julia = "1.10"`. The registry's TagBot and
  CompatHelper bots assume this.
- **Bump compat lower bounds when you start depending on a new feature.**
  E.g. if you adopt `Base.@kwdef` defaults that need 1.9, raise the
  Julia bound to `"1.9"` in the same commit.
- **`test/Project.toml` is its own world.** Test-only deps go there, not
  in the package's `Project.toml`. The test environment has its own
  `[deps]`, `[compat]`, `[extras]`, and `[targets]` blocks. Pattern:

  ```toml
  [deps]
  Aqua = "..."
  JET = "..."
  Test = "..."

  [compat]
  Aqua = "0.8"
  JET = "0.9"

  [extras]
  # rarely needed under the modern test/Project.toml layout;
  # only used by the legacy single-Project.toml workflow

  [targets]
  test = ["Aqua", "JET", "Test"]
  ```

  If both `test/Project.toml` and `[extras]/[targets]` in the root
  `Project.toml` exist, the test/ version wins on modern Julia. Pick
  one; prefer `test/Project.toml` and remove the root `[extras]`.
- **Do not list the package itself as a test-time dep.** `Pkg.test` and
  `julia --project=. test/runtests.jl` already activate the package
  under test; a self-entry triggers the `can not merge projects` error
  (this repo hit that — see the `7b7385a` fix).

## 2. Module structure

Julia packages are a single `module` rooted in `src/<Pkg>.jl`. The
discipline mirrors R's NAMESPACE / @export pattern.

- **One concept per file.** A 1500-line `src/Pkg.jl` is a smell. Split
  by responsibility (e.g. `likelihood.jl`, `packing.jl`, `confint.jl`),
  then `include()` from the root module.
- **The root file is a manifest, not a workhorse.** Pattern:

  ```julia
  module GLLVM

  using LinearAlgebra
  using Optim
  using SparseArrays

  include("packing.jl")
  include("likelihood.jl")
  include("fit.jl")
  # ... one include per concept

  export
      AnotherType,
      fit_gaussian_gllvm,
      pack_lambda,
      unpack_lambda,
      ZetaSomething

  end # module
  ```

- **Curate `export` deliberately and alphabetically.** Public API lives
  here. If a name isn't in this block, callers must qualify it
  (`GLLVM.foo`), which is the correct signal for "internal helper".
- **Resist `export`-by-default.** Anything exported is part of the
  public API and bound by semver. Prefer a small export list and let
  power users reach in with `GLLVM.<name>` when they need to.
- **`using` vs `import` inside the module.** `using LinearAlgebra`
  brings names in. `import Pkg: foo` is only needed if you intend to
  add methods to `foo`. Be intentional — method-extension is a public
  contract.

## 3. Aqua.jl checks

Aqua catches the boring-but-fatal package hygiene bugs that humans
miss. Run it in CI and locally before tagging.

```julia
using Aqua, GLLVM
Aqua.test_all(GLLVM)
```

What it checks (each is independently runnable as `Aqua.test_<name>`):

- **`ambiguities`** — pairs of methods where Julia cannot decide which
  to dispatch. Almost always a latent bug.
- **`unbound_args`** — type parameters that appear in a signature but
  cannot be inferred from any argument (e.g. `f(x::Vector{T}) where T`
  where nothing pins `T`). Causes confusing dispatch failures.
- **`undefined_exports`** — names in `export` that don't exist. The
  module loads, but `using GLLVM` then errors on access.
- **`stale_deps`** — entries in `[deps]` that aren't actually
  referenced. Bloat the install footprint and break the dep graph.
- **`deps_compat`** — every `[deps]` entry has a matching `[compat]`
  entry (the rule from §1). Aqua enforces this mechanically.
- **`project_extras`** — `[extras]` / `[targets]` consistency.
- **`piracies`** — methods added to functions from other packages, on
  types you don't own. Type piracy is the strongest form of
  global-state mutation in Julia.

Run Aqua as part of "Workflow Q" (the pre-commit / pre-tag local check
loop): `Aqua.test_all` first, fix everything it complains about, then
move on to JET and the test suite.

## 4. JET.jl checks

JET is a static analyzer built on Julia's own type inferencer. Three
modes, each with a distinct purpose:

- **`JET.report_opt(f, types)`** — type-stability proof on a specific
  call. Reports every `runtime_dispatch` (i.e. a call where the
  compiler couldn't pick a concrete method ahead of time). Use this on
  hot loops. A passing `report_opt` means the loop is monomorphic.

  ```julia
  using JET
  JET.report_opt(em_phylo_inner!, (Vector{Float64}, ...))
  ```

- **`JET.report_call(f, types)`** — call-graph reachability and error
  detection. Walks every method call reachable from `f(types...)` and
  flags missing methods, undefined globals, and obvious type errors.
  Cheap; run on every public entry point.
- **`JET.report_package(GLLVM)`** — whole-package sweep, equivalent to
  `report_call` over every top-level definition. Run as part of
  Workflow Q. Slow; do not run in tight inner-loop iteration.

JET's reports are advisory, not failing — wrap with `@test_call` /
`@test_opt` (from `JET.@test_call`) inside `runtests.jl` to fail CI on
regression. Pin the JET version in `test/Project.toml` `[compat]`
because the report format changes between minor versions.

## 5. Allocs.jl / allocation budgets

Hot loops in a numerical library should allocate **zero** bytes per
iteration. Allocation in the gradient inner loop is the single biggest
performance bug in Julia code.

Tools:

- **`BenchmarkTools.@ballocated`** — the canonical zero-alloc gate.

  ```julia
  using BenchmarkTools
  @test 0 == @ballocated grad_inner!($g, $state, $θ) setup=(...)
  ```

  Put a `@ballocated == 0` assertion in `test/test_allocations.jl` for
  every identified hot loop. If the assertion ever fails, you've
  silently introduced a tuple, a closure capture, or an SArray-to-Array
  conversion.
- **`Profile.Allocs`** (stdlib) — sample-based allocation profiler.
  Use when `@ballocated > 0` and you need to find *which line*
  allocated. Output via `PProf.Allocs.pprof()` or
  `flame(Profile.Allocs.fetch())`.
- **`@code_warntype f(args...)`** — quick first-pass when a function
  allocates unexpectedly. Red `::Union{...}` or `::Any` rows are the
  source.

Identify the hot loops once (the gradient inner loop, the E-step inner
loop, the Cholesky solve wrapper), pin them with `@ballocated == 0`
tests, and treat any new allocation as a blocking regression.

## 6. Version bumps

Semver discipline:

- **PATCH (`0.1.0` → `0.1.1`)**: bug fixes, no public-API change, no
  output-numerics change beyond noise.
- **MINOR (`0.1.0` → `0.2.0`)**: new exported functions, new methods on
  existing functions, deprecations. No removed names.
- **MAJOR (`0.1.0` → `1.0.0` or `1.0.0` → `2.0.0`)**: removed or
  renamed exports, signature changes, numerical-output changes that
  break downstream tests.
- **Pre-1.0 (`0.x.y`)**: by Julia registry convention, `0.x.y` →
  `0.(x+1).0` is treated as breaking. Bumping the minor of a `0.x`
  package is a major-equivalent bump.

Atomic version-bump commit must include:

1. `Project.toml` `version = "..."` update.
2. `CHANGELOG.md` entry under a new dated heading, with bullets grouped
   by Added / Changed / Fixed / Removed.
3. `docs/` rebuild if Documenter is in use — verify
   `julia --project=docs/ docs/make.jl` runs clean before tagging.
4. Tag commit message: `Release v0.2.0` (plain, no markdown). The tag
   itself is `v0.2.0`.

Do **not** mix version bumps with substantive code changes. Version
bumps are administrative; the bump commit should only touch
`Project.toml`, `CHANGELOG.md`, and (if necessary) docs config.

## 7. Manifest.toml hygiene

`Manifest.toml` records exact resolved versions of every transitive
dep. The convention:

- **Library packages**: `.gitignore` the `Manifest.toml`. Libraries are
  consumed by others, who will resolve against *their* environment.
  Committing a `Manifest.toml` causes confusing "why doesn't my version
  match the maintainer's?" reports.
- **Applications / reproducible analyses / papers**: commit
  `Manifest.toml`. The whole point is reproducibility — a future reader
  needs to recover the exact env.

**GLLVM.jl is a library → `Manifest.toml` is gitignored.** Already done.
Verify with `git ls-files Manifest.toml` returning empty before
tagging.

For the `docs/` and `test/` sub-environments: same rule. Both are
internal to the library; their `Manifest.toml`s are also gitignored.

## 8. Test runner

**Never `Pkg.test` on this repo.** It triggers a Pkg sandbox that fails
with `can not merge projects` on this layout. The working invocation
is:

```sh
julia --project=. test/runtests.jl
```

Run from the package root. `test/runtests.jl` activates the test
environment via the standard `Test.@testset` blocks; the
`--project=.` flag pins the package env, and `test/runtests.jl`
internally handles the test-deps via `test/Project.toml`.

Workflow Q (local pre-commit / pre-tag check):

1. `julia --project=. -e 'using Aqua; using GLLVM; Aqua.test_all(GLLVM)'`
2. `julia --project=. -e 'using JET; using GLLVM; JET.report_package(GLLVM)'`
3. `julia --project=. test/runtests.jl`
4. `julia --project=docs/ docs/make.jl` (if docs/ exists)

All four must pass before tagging or pushing. Run locally on macOS
first per the global "Local checks over GitHub Actions" rule — only
push when all four are green.
