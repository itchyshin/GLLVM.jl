# After Task: Sparse Phy Analytic Fit Route

## Goal

Wire the sparse Brownian-tree analytic gradient into `fit_gaussian_gllvm` so
supported single-axis phylogenetic Gaussian fits can avoid the dense `Σ_phy`
path.

## Implemented

`fit_gaussian_gllvm(...; phy=...)` now routes to an `Optim.only_fg!` sparse
objective/gradient callback for the current single-axis tree cases:
`K_phy == 0, has_phy_unique == true` and `K_phy == 1, has_phy_unique == false`.
The route accepts an `AugmentedPhy` or Newick string, fixes the Brownian tree
scale at `σ²_phy = 1.0`, and estimates the scale through `σ_phy` or `Λ_phy`.
Unsupported combinations still throw `ArgumentError`; dense arbitrary
covariances continue to use `Σ_phy`.

## Mathematical Contract

The sparse fitter maximises the same closed-form Gaussian marginal likelihood as
the dense path,

```text
cov(vec(Y)) = I_n ⊗ A + J_n ⊗ B,
A = Λ_B Λ_B' + σ²_eps I,
B = (Λ_phy_aug Λ_phy_aug') .* Σ_phy,
```

with `Σ_phy = S Q_cond^-1 S'` represented by the augmented-state sparse
precision rather than materialised densely. Because CHOLMOD is Float64-only,
the optimiser gradient is not ForwardDiff through CHOLMOD; it is the
hand-coded Takahashi sparse analytic gradient.

## Files Changed

src:

- `src/fit.jl` - added the `phy` keyword path, sparse objective/gradient
  adapter, concrete packing, and supported-scope validation.
- `src/likelihood_sparse_phy.jl` - updated the AD/fitter support wording.
- `src/GLLVM.jl` - updated the sparse phy include comment.

test:

- `test/test_fit.jl` - added end-to-end sparse `phy` fitter tests for the
  `σ_phy` and `K_phy = 1` single-axis cases plus failure-path checks.

docs:

- `README.md` - added the sparse Brownian-tree single-axis fitter capability to
  the feature list.
- `docs/src/structured-dependence.md` - documented the `phy=...` route, scale
  convention, and dense-vs-sparse scope.
- `docs/dev-log/check-log.md` - recorded test, docs, benchmark, and audit
  evidence.

## Tests Added

The new `test_fit.jl` checks satisfy two clauses:

- independent calculation: the `K_phy = 1` sparse fit is checked against the
  dense likelihood evaluated at the sparse estimate and a dense warm-started
  refit;
- failure path: unsupported multi-axis sparse phy fits and simultaneous
  `Σ_phy`/`phy` inputs throw `ArgumentError`.

## Benchmark Numbers

Local timing smoke on the maintainer Mac, unique sparse phylo cell, three timed
refits after warmup:

```text
p=32, n=64:
dense Σ_phy median = 0.428047042 s
sparse phy median  = 0.068494209 s
speedup            = 6.249390251371469x
dense reps         = [0.458757292, 0.428047042, 0.409211042]
sparse reps        = [0.05248425, 0.076899625, 0.068494209]
```

The attempted p=64/n=96 timing cell was terminated after the dense baseline ran
too long for a quick audit smoke. This is internal Julia dense-vs-sparse timing
evidence, not an R `gllvmTMB` comparison.

## R-Parity Verdict

Parity: not run. This slice does not change the Gaussian marginal likelihood
formula. Julia-side dense/sparse likelihood agreement was verified to
`5.684341886080802e-14` in the scout check, and the formal test now checks
dense likelihood agreement for the `K_phy = 1` sparse fit.

## JET / Allocs / Aqua Verdicts

- JET: clean through the full `Pkg.test()` quality gate, 12/12 quality tests.
- Allocs: not run with Allocs.jl; timing smoke only. This route still allocates
  per objective/gradient evaluation and needs a later allocation pass.
- Aqua: clean through the full `Pkg.test()` quality gate, 12/12 quality tests.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_fit.jl")'
```

Result: 27 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2414 pass, 1 existing
sparse-phy precision placeholder, 2 expected direct-environment quality
placeholders, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: manual tally from emitted summaries: 2426 pass, 1 existing sparse-phy
precision placeholder, 0 fail, 0 error. `quality` passed 12/12 and Julia
printed `Testing GLLVM tests passed`.

```sh
julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "docs"); include("docs/make.jl")'
```

Result: exit code 0. The local build still emits pre-existing invalid-local-link
warnings, Vitepress default-file warnings, missing logo/favicon warnings, and
npm audit notices.

## Consistency Audit

Patterns run:

```sh
git diff --check
rg -n "evaluation-only|AD-based fitting|must therefore use the dense|Dense path only|Σ_phy is required|user-supplied Σ_phy|phy fast path|phy=\\.\\.\\.|Brownian-tree" README.md docs/src src test
rg -n "JABE|OneDrive|Library/CloudStorage|uploaded|private PDF|private-file|PDF" README.md docs/src src test docs/dev-log/check-log.md docs/dev-log/after-task -g '!docs/build/**' -g '!docs/node_modules/**'
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-02-sparse-phy-fit-analytic.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB|6\\.25x|6\\.249" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**' -g '!docs/build/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state,url
```

Results: whitespace clean; sparse-phy stale wording removed from touched public
docs; private-source trace scan has no hit in this slice's changed files;
stale-wording scan has expected historical check-log hits and the user-provided
AGENTS.md "Gaussian only" snapshot; performance scan has expected historical
benchmark records and no new R `gllvmTMB` or public 100x claim.

## GitHub Issue Maintenance

No new issue was opened. This slice belongs to PR #60. PR #59 remains the
separate draft `claude/package-work-catchup-mQiZM` lane.

## What Did Not Go Smoothly

The p=64/n=96 timing smoke was too expensive because the dense baseline entered
the old ForwardDiff dense covariance path; it was terminated and recorded as a
non-result rather than promoted.

## Team Learning

Gauss/Karpinski: the sparse analytic-gradient route is already a fitter-level
speed win, but a larger benchmark grid needs a dedicated harness so dense
baseline runs can be bounded and resumable.

## Remaining Risks

- Sparse `phy` fitting is intentionally limited to one phylogenetic axis.
- No fixed effects, W tier, or diagonal tier are supported on the sparse fitter
  route yet.
- R `gllvmTMB` parity was not run for this fitter route.
- Allocs.jl was not run; allocation cleanup remains a later performance pass.
- Local docs build warnings remain pre-existing.

## Next Command

```sh
julia --project=. --startup-file=no -e 'include("test/test_confint_bootstrap.jl"); include("test/test_confint_profile.jl")'
```

Use this as the starting guard before the next ordered CI-acceleration slice.

## Rose Verdict

Rose verdict: PASS WITH NOTES - sparse single-axis `phy` fitting is implemented,
tested, documented, and locally benchmarked; multi-axis sparse fitting, R
parity, and allocation cleanup remain explicit limitations.
