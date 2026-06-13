# Check Log

## 2026-06-07 - Analytic Gradient Defaults

### Scope

Runtime-gated the dormant analytic Laplace gradients. Poisson, NB2, Binomial,
and Beta now default to `gradient = :analytic` on the plain no-mask/no-offset
path, preserving the existing finite-difference fallback. Gamma remains
`gradient = :finite` because the benchmark gate found accuracy failures.

### Benchmark Evidence

Fitter-only run using the `bench/speed_bench.jl` simulators and timing logic
(`reps = 1`, `iterations = 300`; the full script stalled in profile-CI before
printing its final table):

| size | family | finite s | analytic s | speedup | delta logLik | gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 20x100x2 | Poisson | 2.592 | 0.274 | 9.46x | -9.09e-13 | pass |
| 20x100x2 | NB2 | 4.276 | 0.383 | 11.16x | -1.82e-12 | pass |
| 20x100x2 | Binomial | 4.719 | 0.416 | 11.33x | 3.18e-12 | pass |
| 20x100x2 | Beta | 15.511 | 1.261 | 12.30x | 1.14e-13 | pass |
| 20x100x2 | Gamma | 0.263 | 0.257 | 1.02x | -7.24e-4 | fail |
| 50x200x2 | Poisson | 50.685 | 4.847 | 10.46x | -1.09e-11 | pass |
| 50x200x2 | NB2 | 53.144 | 4.736 | 11.22x | -7.28e-12 | pass |
| 50x200x2 | Binomial | 59.231 | 5.357 | 11.06x | -1.09e-11 | pass |
| 50x200x2 | Beta | 223.527 | 17.699 | 12.63x | 6.37e-12 | pass |
| 50x200x2 | Gamma | 31.894 | 1.925 | 16.56x | 3.93e23 | fail |

### Checks Run

```sh
julia --project=. test/test_laplace_grad.jl
```

Result: 26 passed in 30.7s.

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3296 passed, 1 broken, 3297 total in 27m25.4s. The full suite includes
the quality battery (`test_quality.jl` with Aqua/JET checks).

```sh
tmp=$(mktemp -d /tmp/gllvm-doc-env-XXXXXX)
JULIA_PROJECT="$tmp" julia -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. The direct `julia --project=docs docs/make.jl` path could
not instantiate locally because `GLLVM` v0.3.0 is not registered, so the build
used a temporary docs environment with the local worktree developed. Pre-existing
warnings remain for absolute local links, missing logo/favicon assets, missing
`docs/package.json`, and npm audit reporting 4 moderate vulnerabilities.

```sh
git diff --check
rg -n "finite-difference outer gradients|opt-in today|kept opt-in|finite \\(the current default\\)|Default :finite|flip the package default" README.md docs/src docs/dev-log/CODEX_HANDOFF.md bench src/families/{poisson,negbin,binomial,beta,gamma}.jl test/test_laplace_grad.jl
```

Result: whitespace clean; stale-default wording scan had no matches beyond the
intended Gamma `gradient::Symbol = :finite` when searched separately.

### Rose Verdict

PASS WITH NOTES. The default flip is restricted to the four families that cleared
the measured speed/accuracy gate; Gamma is explicitly left finite. Remaining
notes: Gamma analytic gradients need a separate stability fix, and
`bench/speed_bench.jl` should stream fitter rows or make profile-CI optional.

## 2026-06-03 - Homepage Mobile Publication

### Scope

Published a narrow documentation hotfix for the live GLLVM.jl homepage. The
deployed mobile page rendered VitePress `layout: home`, `hero:`, and `features:`
frontmatter as ordinary page text. The homepage now uses plain
Documenter-compatible Markdown and starts as a docs page:

1. package title;
2. one-sentence identity;
3. install command;
4. first model example.

No source code, exported API, likelihood parameterization, or test behavior
changed.

### Checks Run

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0 locally before publication. Documenter and
DocumenterVitepress completed. Residual warnings remain: pre-existing absolute
local links in several article pages (`/quickstart`, `/api`, etc.), deployment
auto-detection skipped, missing `logo.png`/`favicon.ico`, missing
`docs/package.json`, and npm audit reporting 4 moderate vulnerabilities.

Playwright mobile check at 390 x 664 px against a local static server:

- no rendered `layout: home`, `hero:`, or `features:` text;
- no horizontal overflow;
- `Install` visible near the top;
- `Fit your first model` visible in the first phone viewport.

Screenshot evidence:
`/tmp/gllvm-mobile-audit/screens/gllvm_local_mobile_simplified.png`.

```sh
git diff --check
rg -n 'layout: home|hero:|features:|https://https://' docs/src docs/make.jl
rg -n 'Fast Generalised Linear Latent Variable Models|Install|Fit your first model|What works today' docs/build/.documenter/index.md docs/build/1/index.html
```

Result: whitespace clean; no frontmatter tokens in public source; rendered
index contains the install-first order.

### Rose Verdict

PASS WITH NOTES. The live-page source bug is fixed in the publication branch
and the mobile top is screenshot-verified. Remaining notes: full `Pkg.test()`
was not run for this docs-only hotfix, pre-existing article-link warnings remain
outside the homepage hotfix, and the live site updates only after the Documenter
deployment workflow completes.
