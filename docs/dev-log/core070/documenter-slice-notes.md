# M3 Documenter opener — slice notes (documentation-writer, 2026-09-01)

Scope: `docs/` tree only. No `src/` or `test/` edits.

## 1. Build status

- **Before**: not previously instantiated in this worktree (`docs/Manifest.toml`
  did not exist; `Pkg.instantiate()` failed with `expected package GLLVM
  [2dc8e01c] to be registered` because `docs/Project.toml` lists `GLLVM` as a
  dependency but the package is unregistered and not `dev`'d in).
- **Fix**: `Pkg.develop(PackageSpec(path=pwd()))` then `Pkg.instantiate()` from
  `--project=docs`. This only touches the (git-ignored) `docs/Manifest.toml`,
  not `Project.toml`.
- **After**: `julia --project=docs docs/make.jl --local` completes cleanly.
  `SetupBuildDirectory` → `Doctest` → `ExpandTemplates` → `CrossReferences` →
  `CheckDocument` → `Populate` → `RenderDocument` → DocumenterVitepress build
  all pass with **zero** Documenter warnings about missing docstrings, stale
  `@docs` blocks, or broken cross-refs. Only cosmetic warnings: no
  `docs/src/assets/logo.png` / `favicon.ico`, no `docs/package.json` (both
  expected — DocumenterVitepress substitutes defaults), and a Vite chunk-size
  advisory. Vitepress `build complete in 6.42s`.
- No `docs/`-only fix was needed to get a clean build — the site was already
  wired correctly by whoever last touched it on this branch.

## 2. What I fixed

1. **`docs/src/quickstart.md`** — the R⟷Julia cheat-sheet row for Gaussian
   GLLVM said "~340× faster closed-form profile path" with no qualifier.
   AGENTS.md/CLAUDE.md require the single-σ² qualifier stay attached to any
   ~340× wording (see `changelog.md`'s 2026-08-25 correction, which also
   corrects "machine precision" to "at least six significant digits" — I left
   that correction text alone, it's already accurate). Changed to: "~340×
   faster closed-form profile path (single-σ² Gaussian only; see
   [Benchmarks](benchmarks.md))". Commit: see below.
2. **`README.md`** — found a garbled sentence from an evident bad prior edit:
   "that path runs **median 265.1× (range 161–698×) on the published Gaussian
   closed-form profile grid** than the R `gllvmTMB` engine..." — the bolded
   clause repeated "on the published Gaussian closed-form profile grid" and
   the sentence didn't parse ("runs X on the grid than the engine"). Rewrote
   as: "On our published Gaussian closed-form profile grid that path runs
   **median 265.1× faster (range 161–698×)** than the R `gllvmTMB` engine on
   the same problem, ..." — same facts, no numbers changed, grammar fixed.

Both are one-line/one-clause surgical fixes; no other prose in either file was
touched.

## 3. Stale-claim audit

**Family list.** `docs/src/response-families.md` and `docs/src/api.md` are
already comprehensive relative to the actual exported surface (I enumerated
`names(GLLVM)` — 367 exported symbols as of `91d9bb7a`, far beyond the
CLAUDE.md/AGENTS.md "Gaussian plus six dense-Laplace families" description,
which is stale relative to this branch but is *not* in my scope to edit — it's
outside `docs/`). The newer fitters called out in the task
(lognormal/truncated-Poisson/truncated-NB2/Tweedie/Student-t/beta-binomial/
censored-Poisson/COM-Poisson/GP1/multinomial/ordered-beta) are all present in
`response-families.md` with worked examples, not just name-drops. No
disposition needed — already current.

**~340× wording.** Fixed in quickstart.md (see above). Checked
`docs/src/benchmarks.md`, `docs/src/comparison.md`, `docs/src/index.md`,
`docs/src/gllvmtmb-parity.md`, `docs/src/changelog.md`: all already carry the
single-σ² qualifier or explicitly flag the figure as unverified pending
publication (`gllvmtmb-parity.md:89-92`). No other unqualified occurrence
found.

**Parity language.** Grepped every `parity` occurrence across `docs/src/*.md`
and `README.md`. The site already carries the panel's Tier-A/Tier-B-style
qualifiers throughout — `gllvmtmb-parity.md`, `studentt-parity.md`,
`response-families.md`, `structured-dependence.md`, and README.md all hedge
with explicit language ("does not establish parity", "unverified",
"candidate", cited Δ values per family-level checkmark, etc.). I found **no**
unqualified headline "GLLVM.jl is at parity with gllvmTMB" claim anywhere in
`docs/` or README.md. No changes needed; this dimension was already compliant
with `docs/dev-log/core070/parity-panel-2026-09-01.md` before I started.

## 4. Reference-page coverage — exported symbols with no `@docs` entry anywhere

Computed by diffing `names(GLLVM)` (367 symbols) against every identifier
appearing inside a fenced ` ```@docs ` block across all of `docs/src/*.md`.
Confirmed each candidate individually (some false positives from symbols
mentioned only in prose, e.g. `BinomialFit`/`StudentT`/`lv_effects` are named
in prose but not inside an actual `@docs` block either — genuine gaps):

| Symbol | Status |
|---|---|
| `EdgePhy` | Not mentioned anywhere in `docs/src/`. Exported `UnionAll` type. Missing reference entry. |
| `NodePerSpecies` | Not mentioned anywhere. Exported `UnionAll` type. Missing reference entry. |
| `branch_re_cache` | Not mentioned anywhere. Exported function. Missing reference entry. |
| `BinomialFit` | Named in prose (tutorial.md, confidence-intervals.md) but never inside an `@docs` block. Missing reference entry. |
| `StudentT` | Named in prose only (api.md, response-families.md, tutorial.md) — distinct from `StudentTFamily`, which *is* documented. `StudentT` (the `UnionAll` marker type) itself lacks a `@docs` entry. |
| `GeneralizedPoisson1` | Named in prose only (response-families.md); the GP1 fitter (`fit_gp1_gllvm`, `GP1Fit`) is documented, but the family marker type `GeneralizedPoisson1` is not. |
| `fit_phylo_squarem` | This is an alias for `em_fit_phylo_squarem`, which *is* documented under `@docs`. Low priority — same function, different exported name. |
| `lv_effects` | Named in prose widely but not inside an `@docs` block; `extract_lv_effects` *is* documented — need to confirm at the source level whether `lv_effects` is a distinct exported name or an alias (I did not check `src/`, out of scope). |
| `node_dσ_phy_only` | False positive from my first grep pass (unicode `σ` broke the regex) — it IS present in `api.md`'s `@docs` block. No action needed. |

**Not listed as gaps** (incoming from other lanes per the task instruction):
none of the above are recognisably AGHQ-slice symbols (`aghq_*`, which are
already documented under `GLLVM.aghq_*` in api.md's Likelihood & Gradient
Kernels section) — so nothing here overlaps with `aghq-builder`'s in-flight
work. I did not add reference entries for the 9 symbols above; flagging only,
per the task's docs-only + no-src-edits scope, since some of these (`StudentT`
vs `StudentTFamily`, `lv_effects` vs `extract_lv_effects`) may be intentional
internal aliases rather than user-facing API and warrant a maintainer call
before adding `@docs` blocks that might then fail to resolve to a docstring.

## 5. Commits

- `docs(quickstart): restore single-sigma-squared qualifier on 340x cheat-sheet row`
- `docs(readme): fix garbled Gaussian speedup sentence`

Both local-only on `codex/core070-aghq-20260830`, not pushed.

## 6. Not done / out of scope

- Did not touch `src/` docstrings for `EdgePhy`, `NodePerSpecies`,
  `branch_re_cache`, `BinomialFit`, `StudentT`, `GeneralizedPoisson1` — flagged
  above for the owning lane/maintainer.
- Did not rewrite `docs/src/index.md`'s "What works today" tip box to be
  fully exhaustive against all 367 exported symbols — it reads as a curated
  summary rather than a stale claim, and a full rewrite risks colliding with
  in-flight family/bridge work from other lanes (`family-reconciler`,
  `aghq-builder`, etc.).
- Noted but did not resolve: `origin/codex/non-gaussian-fitter-gradients` has
  an unmerged restructure of `quickstart.md` that removes the R⟷Julia cheat
  sheet table entirely (replaces it with a narrower "smallest complete path"
  framing). My one-line qualifier fix on the current file is compatible with
  either version landing later, but whoever merges that branch should re-check
  the qualifier survives the restructure.
