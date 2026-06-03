# Check Log

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
