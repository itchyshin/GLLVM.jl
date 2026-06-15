# Check Log

## 2026-06-15 - Ordinal-Probit Bridge Mask Key

### Scope

Added a distinct `ordinal_probit` bridge family key so the R
`gllvmTMB::ordinal_probit()` constructor routes to cumulative-probit ordinal
GLLVM fits instead of the cumulative-logit `ordinal` default.

- `bridge_fit(...; family = "ordinal_probit", mask = M)` now calls
  `fit_ordinal_gllvm(..., link = ProbitLink(), mask = M)`;
- bare `family = "ordinal"` remains cumulative-logit;
- masked no-X one-part family evidence now covers Poisson, Bernoulli Binomial,
  NB2, Beta, Gamma, and Ordinal-probit from the R bridge.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl
```

Result: `23/23 pass` in `16.8s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: `66/66 pass` in `46.2s`.

Paired live R bridge:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result: `232/232 pass` in `50.9s`.

### Rose Boundary

PASS WITH NOTES. This proves the bridge family key, probit-link routing, and
R-live masked no-X family matrix. It does not add masked CI refits, X+mask,
Gaussian masks, or ordinal prediction/residual payloads.

## 2026-06-15 - Bridge Missing-Response Mask Hook

### Scope

Added the minimal Julia transport hook needed by the R-first
`gllvmTMB(..., engine = "julia", missing = miss_control(response = "include"))`
slice:

- `bridge_fit(...; mask = M)` now accepts a `p x n` observed-cell mask
  (`true = observed`) for one-part no-X non-Gaussian families;
- all-true masks normalize to the complete-data bridge path;
- Gaussian masks, X+mask, mixed-family masks, and masked CI requests fail
  before fitting;
- bridge latent scores and latent-scale summaries call the mask-aware
  post-fit/link-residual paths so sentinel placeholders do not influence
  predictions or correlations.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl
```

Result: `17/17 pass` in `15.5s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: `52/52 pass` in `18.9s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: `66/66 pass` in `46.1s`.

```sh
~/.juliaup/bin/julia --project=. -e 'using Test, GLLVM, Distributions; include("test/test_missing_data.jl")'
```

Result: `34/34 pass` in `12.5s`. The direct file form needs
`Distributions` loaded because the standalone test file assumes the full
`test/runtests.jl` include context.

```sh
~/.juliaup/bin/julia --project=. test/test_postfit.jl
```

Result: post-fit family blocks passed (`96/96`, `9/9`, `10/10`, `8/8`,
`163/163`, `160/160`, `215/215`, `215/215`, `216/216`).

```sh
~/.juliaup/bin/julia --project=. test/test_confint_family.jl
```

Result: `122/122 pass` in `4m15.5s`.

### Rose Boundary

PASS WITH NOTES. This is a bridge transport and post-fit correctness hook, not
full missing-data release readiness. Masked CI refits, X+mask, Gaussian masks,
and per-family R-side parity rows remain separate gates.

## 2026-06-15 - gllvmTMB Bridge X Admission Status Sync

### Scope

Synced `docs/src/gllvmtmb-parity.md` with the current R-side
`gllvmTMB(..., engine = "julia")` bridge surface:

- complete, balanced one-part no-X reduced-rank bridge fits are admitted for
  Gaussian, Poisson, Binomial, NB2, Beta, Gamma, and Ordinal;
- fixed-effect `X` is admitted for complete, balanced one-part Gaussian,
  Poisson, Binomial, NB2, Beta, and Gamma bridge fits;
- response-missing masks, mixed-family bridge metadata, ordinal covariate fits,
  structured terms, and user-selectable Julia optimizer controls remain explicit
  follow-ups;
- REML wording is Gaussian-only, and HSquared-style AI-REML is recorded as a
  later exact-Gaussian scouting target, not non-Gaussian Laplace terminology.

Also updated `docs/dev-log/codex-fast-algorithms-brief.md` with the same REML /
AI-REML boundary.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: 50/50 passed in 18.0s.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is a documentation/status-sync slice only. It does not
claim new Julia engine behavior beyond the already-tested `bridge_fit(...; X=...)`
contract, and it does not claim non-Gaussian REML or AI-REML.

## 2026-06-15 - PR #94 Successor Issue Drafts

### Scope

Converted the `GLLVM.jl#94` unique-content audit into a local successor-issue
draft bank without mutating GitHub remotely.

The draft bank now contains seven durable successor records:

1. Generalized Poisson family.
2. Student-t one-part family.
3. True one-part lognormal family.
4. Standalone zero-truncated Poisson/NB.
5. ANOVA/LRT model-comparison API.
6. Unified check-fit diagnostics, calibration, and plots.
7. Structured Schur / structured Poisson prototype.

Stale #94 benchmark-script notes are routed to existing benchmark/runtime
issues (`#65` and `#61`) rather than duplicated as a new issue.

### Checks Run

```sh
gh issue list --repo itchyshin/GLLVM.jl --state open --limit 100 --json number,title,labels,updatedAt,url
gh issue list --repo itchyshin/gllvmTMB --state open --limit 100 --json number,title,labels,updatedAt,url
gh pr view 94 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
gh pr view 95 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
git log --oneline 65a1f10..HEAD --reverse
```

Live PR state at drafting time:

- `#94` open draft, conflicting, `a1-nongaussian-ci` at `09fc846`.
- `#95` open draft, mergeable, `integration` at `65a1f10`.
- local runtime stack head before this draft slice: `862f081`.

### Rose Boundary

PASS WITH NOTES. Do not close `#94` yet. Close only after the seven durable
successor records exist and the benchmark-script notes are routed into existing
benchmark issues. No GitHub issue, PR comment, closure, or push was performed in
this slice.

## 2026-06-15 - PR #94 Unique-Content Audit

### Scope

Audited draft/conflicting `GLLVM.jl#94` before closure or supersession.

Live state at audit time:

- `#94` open draft, conflicting, `a1-nongaussian-ci` at `09fc846`
- `#95` open draft, mergeable, `integration` at `65a1f10`
- local integration audit head: `d3d8129`

### Checks Run

```sh
gh pr view 94 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
gh pr view 95 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
git fetch origin pull/94/head:refs/remotes/origin/pr-94 pull/95/head:refs/remotes/origin/pr-95 main integration
```

Blob classification of `origin/main...origin/pr-94` paths against current local
integration:

| class | count |
| --- | ---: |
| absent from integration | 124 |
| present but different from local integration | 50 |
| byte-identical to local integration | 2 |

### Rose Boundary

PARTIAL BUT ACTIONABLE. Do not merge `#94`. Treat it as an archive to mine into
successor issues for Generalized Poisson, Student-t, standalone lognormal,
standalone zero-truncated count families, ANOVA/LRT, diagnostics, structured
Schur/Poisson prototypes, and stale benchmark rebuilds. Close only after those
successor issues/comments exist.

## 2026-06-15 - Test Warning Hygiene

### Scope

Removed duplicate-method warnings from the core and full package test logs:

- `test/test_takahashi_selinv.jl` now uses the package-loaded
  `GLLVM.takahashi_selinv` and `GLLVM.takahashi_diag` implementations instead
  of self-including `src/takahashi_selinv.jl` into `Main`;
- `test/test_bridge_ci.jl` renamed its local Poisson simulator helper to avoid
  overwriting the helper in `test/test_confint_family.jl` during full-suite
  execution.

No production source changed in this slice.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_takahashi_selinv.jl
```

Result: 8/8 passed in 0.4s, with no duplicate-method warning.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: 66/66 passed in 45.4s.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.0s. The previous
`takahashi_selinv.jl` and `_sim_poisson` overwrite warnings did not reappear.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m12.0s. The duplicate-method
warnings did not reappear under Pkg's temporary test environment.

### Rose Boundary

PASS. This is test-harness hygiene only. It reduces warning noise and does not
change model behavior, likelihoods, fitters, bridge payloads, or public API.

## 2026-06-15 - Sparse Phylo Node-Gradient Shortcut

### Scope

Wired the verified node-frame O(p) gradient into the public sparse phylo
gradient dispatcher for the phylo-unique shape only:

- `K_aug == 1`
- `K_phy == 0`
- `has_unique == true`

All other augmented sparse-phylo gradient shapes still route through the exact
leaf-block fallback (`_sparse_phy_grad_leafblock`). The fallback remains the
reference for `Λ_phy` and mixed augmented shapes because those derivatives need
the dense leaf-row x leaf-column block.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_node_gradient.jl
```

Result: 58/58 passed in 9.7s. The node route was checked against dense
ForwardDiff and the preserved leaf-block reference on balanced and caterpillar
trees. Max relative node-vs-leaf-block error for the `σ_phy` block was
`1.015e-13`; scalar/global blocks were zero or machine precision.

```sh
~/.juliaup/bin/julia --project=. test/test_sparse_phy_grad.jl
```

Result: 101/101 passed in 7m12.1s. The end-to-end sparse/dense value
consistency gate reported `8.731e-11` logLik difference at the sparse optimum;
the warm-start comparison to `fit_gaussian_gllvm` had `Δll_warm = 2.092e-5`.

```sh
~/.juliaup/bin/julia --project=. bench/sparse_phy_grad_bench.jl
```

Result:

| p | shortcut ms | leafblock ms | speedup | dense-FD ms | max rel err |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 100 | 0.344 | 1.027 | 2.99x | 198.884 | 8.76e-15 |
| 300 | 1.117 | 3.670 | 3.29x | skipped | 2.28e-14 |
| 600 | 1.114 | 24.030 | 21.58x | skipped | 7.11e-15 |

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.2s.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m36.2s.

### Rose Boundary

PASS WITH NOTES. This closes the verified phylo-unique node-gradient wiring
slice only. It does not claim O(p) for `Λ_phy`, mixed augmented phylo effects,
or any non-Gaussian Laplace adjoint route. The full package gate passed, but the
suite still emits pre-existing duplicate-include/helper overwrite warnings that
should be cleaned in a separate hygiene slice.

## 2026-06-14 - JuliaConnectoR R gllvm Parity Smoke

### Scope

Closed the first R `{gllvm}` vs GLLVM.jl JuliaConnectoR parity smoke gap:

- `gllvm_jl_init()` now accepts `jl_path` and defaults to `GLLVM_JL_PATH`,
  activating the local Julia project before importing `GLLVM`;
- the standalone fallback in `r/gllvmtmb_julia.R` mirrors the same activation
  path;
- `r/parity_check.R` scales R `{gllvm}` `params$theta` by `params$sigma.lv`
  before Procrustes-aligned loading comparison.

The previous apparent Poisson mismatch was harness drift: Julia could import a
stale/default-environment `GLLVM`, and the R loadings were compared before the
latent-variable scale was applied.

### Checks Run

```sh
JULIA_BINDIR=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin \
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(jl_path=Sys.getenv("GLLVM_JL_PATH")); set.seed(1); y <- matrix(rpois(30*4,3), nrow=30); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", row.eff="none"); stopifnot(res$diffs$logLik < 1e-6, res$diffs$beta["abs"] < 1e-5, res$diffs$loadings["abs"] < 1e-5)'
```

Result: exit code 0.

```text
logLik absolute diff: 2.086e-11
beta max abs diff:   1.760e-07
loadings max abs:    6.559e-07
```

### Rose Boundary

PASS WITH NOTES. This is one live Poisson `method="LA"` no-row-effect parity
smoke. It proves the scaffold can hit the same likelihood target when the local
project is activated and R loadings are scale-mapped. It does not prove full
family, dispersion, covariate, missingness, R-bridge, or CI parity.

## 2026-06-14 - Rose Status Drift Cleanup

### Scope

Cleaned public/status drift found by the Rose audit after the runtime-gap fixes:

- `AGENTS.md` no longer describes the integration tree as the old v0.1
  Gaussian-only pilot;
- `README.md` now states that Gamma joins Poisson, NB2, Binomial, and Beta in
  the analytic-gradient default set for no-mask/no-offset fits;
- `docs/dev-log/CODEX_HANDOFF.md` now treats v0.3.0 tagging as a
  maintainer-gated release-ledger decision, not an automatic next command.

No source code, tests, Project version, or R bridge code changed in this slice.

### Checks Run

Stale wording scan:

```sh
rg -n "v0\\.1\\.0 pilot|Gaussian only|Gamma and the|bump `Project.toml` to v0\\.3\\.0 and|tag a release" AGENTS.md README.md docs/dev-log/CODEX_HANDOFF.md
```

Result: no matches.

Whitespace:

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is a wording/ledger cleanup only. It does not merge
`GLLVM.jl#95`, close `GLLVM.jl#94`, update remote issues #91/#92/#96, validate
the R `{gllvm}` statistical parity gate, or authorize a tag.

## 2026-06-07 - Analytic Gradient Defaults

### Scope

Runtime-gated the dormant analytic Laplace gradients. Poisson, NB2, Binomial,
and Beta defaulted to `gradient = :analytic` on the plain no-mask/no-offset path,
preserving the existing finite-difference fallback. At that time Gamma was left
finite because the benchmark gate found accuracy failures; the Gamma decision is
superseded by the 2026-06-14 entry below.

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

PASS WITH NOTES. The 2026-06-07 default flip was restricted to the four families
that cleared the measured speed/accuracy gate. This Gamma caveat is superseded
by the 2026-06-14 entry below. Remaining note from this historical run:
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

## 2026-06-14 - High-rate Poisson mode safeguard (#91)

### Scope

Fixed the integration-branch reproduction of GLLVM.jl #91, where the default
analytic-gradient `fit_poisson_gllvm` path could accept a runaway first step for
a high-rate `K = 2` Poisson fit. The root cause was the shared dense-Laplace
inner mode solve: full Fisher-scoring steps could lower the conditional
log-posterior by many orders of magnitude, making the warm-start marginal and
the analytic Poisson gradient invalid.

`src/families/laplace.jl` now keeps full Newton steps near the mode, but uses
step-halving against the conditional log-posterior for the cheap scalar families
where this safeguard is needed (`Poisson`, `Binomial`, `NegativeBinomial`,
`Beta`, `Gamma`, `Exponential`). Heavier bespoke families keep the previous
full-step path to avoid turning their expensive log-density calls into an inner
line search. A one-time restart from `z = 0` remains available when a solve
returns non-finite values.

`test/test_poisson_fit.jl` now carries the high-rate #91 fixture and checks:

1. the fitted intercepts stay on the empirical log-mean scale;
2. the fitted log-likelihood is finite and the optimizer converges;
3. the analytic Poisson Laplace gradient matches a central finite-difference
   gradient on the same high-rate warm start.

### Checks Run

Before the fix, on `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration`
at `65a1f10`, the reconstructed #91 fixture produced:

```text
kind = :allZ_col
analytic_converged = true
analytic_beta6 = -1.3725979588255058e6
fd_beta6 = 3.5848998478056116
beta06 = 2.046028486073364
analytic_maxabs = 1.3726000048539918e6
```

After the fix:

```text
kind = :allZ_col
converged = true
beta6 = 1.8845273881056652
beta06 = 2.046028486073364
maxabs = 0.16150109796769874
loglik = -9573.527202270865

kind = :interleaved_site
converged = true
beta6 = 1.9494694468357439
beta06 = 2.1177137251431333
maxabs = 0.16824427830738942

kind = :global_seed_interleaved
converged = true
beta6 = 1.9931572688527104
beta06 = 2.1386437132753118
maxabs = 0.1454864444226014
```

High-rate warm-start gradient check after the fix:

```text
marg0 = -10049.149835755072
grad analytic norm = 456.8484012361648
finite norm = 456.8484007642873
diff norm = 2.2149188558598164e-6
maxabsdiff = 1.0488242692119343e-6
```

Focused tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_fit.jl
```

Result: `12/12 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_laplace.jl
```

Result: `4/4 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_laplace_grad.jl
```

Result: `26/26 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_missing_response.jl
```

Result: `23/23 pass`; masked analytic-vs-FD max differences remained
`5.42e-8` for Poisson and `2.41e-8` for Binomial.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM, Test, Distributions, LinearAlgebra, Random; include("test/test_laplace_alloc_equiv.jl")'
```

Result: `7/7 pass`.

Affected scalar-family fit tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_nb_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_fit.jl
```

Results: Binomial `8/8`, NB `7/7`, Beta `7/7`, Gamma `7/7` pass.

Affected scalar-family marginal tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_negbin_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_laplace.jl
```

Results: Beta `2/2`, Gamma `2/2`, NB `2/2`, Binomial `9/9` pass.

`test/test_missing_response_extra.jl` was started twice and interrupted after
several minutes both times. The interrupt stack was inside long finite-difference
fits for Tweedie / row-effect wrappers, not in the new Poisson safeguard branch.
Full `test/runtests.jl` and `Pkg.test()` remain the next gates before PR.

### Rose Verdict

PASS WITH NOTES. #91 is reproduced on the integration branch and fixed with a
fit-level regression plus a gradient-vs-FD gate. The safeguard is intentionally
scoped to cheap scalar families to avoid slowing bespoke heavy likelihoods.
Remaining blocker: full-suite validation has not yet been run after this patch.

### 2026-06-14 — #91 full-suite validation and self-contained CI test import

`test/test_confint_family.jl` failed when run directly because the Tweedie
bootstrap test used `dot` without importing `LinearAlgebra`. Added the explicit
test-file import; no package source changed in this cleanup.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_family.jl
```

Result: `122/122 pass` in `4m08.6s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3749 pass, 3 broken, 0 failed, 0 errored` in `30m42.6s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m51.7s`.

Noted quality noise: the `Pkg.test()` sandbox still prints duplicate-method
warnings from repeated local helper definitions (`takahashi_selinv.jl` include
warnings and `_sim_poisson` in `test_confint_family.jl` / `test_bridge_ci.jl`).
They did not fail the gate, but should be cleaned in a later test-hygiene slice.

Rose verdict: PASS WITH NOTES. The #91 safeguard branch is full-suite green on
Julia 1.10; remaining notes are R parity not run (not bridge-facing) and
pre-existing duplicate-helper warning noise in the test harness.

Docs build note: `julia --project=docs docs/make.jl` is blocked locally because
`docs/Project.toml` expects registered package `GLLVM`. A no-deploy temp build
using `Pkg.develop(path=pwd())` reached Vitepress but failed on pre-existing
dead local links (`./quickstart`, `./model`, `./benchmarks`, `./comparison`, and
related extensionless page links). This is a docs-cleanup follow-up, not part of
the #91 numerical change.

### 2026-06-14 — Vitepress dead-link cleanup

Normalised the remaining relative page links in `docs/src/{index,quickstart,
comparison,gllvmtmb-parity}.md` to the existing absolute Vitepress route style.
This removed the hard Vitepress dead-link failure found during local no-deploy
docs validation.

```sh
/Users/z3437171/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.activate(; temp=true); Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); using Documenter, DocumenterVitepress, GLLVM; makedocs(; source="docs/src", build="/tmp/gllvm-docs-build", warnonly=true, ...)'
```

Result: passed; Vitepress built the site successfully in `4.66s`.

Remaining warnings: Documenter still warns on absolute local links (`/quickstart`,
`/api`, etc.) and DocumenterVitepress reports missing optional Vitepress assets /
`docs/package.json`. These are pre-existing warning-level documentation
infrastructure items, not hard build failures after this cleanup.

Rose verdict: PASS WITH NOTES. Hard dead-link blocker removed; warning-level
docs infrastructure cleanup remains.

## 2026-06-14 - Gamma Analytic Gradient Default

### Scope

Re-opened the Gamma analytic-gradient default after the high-rate Poisson
Laplace-mode safeguard. Gamma now joins Poisson, NB2, Binomial, and Beta in
defaulting to `gradient = :analytic` on the plain no-mask/no-offset path, with
the existing finite-difference fallback retained for masked or offset fits.

### Benchmark Evidence

The full original `bench/speed_bench.jl` grid was interrupted after roughly 13
minutes while still in the first grid cell, so the benchmark harness was updated
with opt-in runtime knobs (`GLLVM_SPEED_BENCH_GRID`, `GLLVM_SPEED_BENCH_REPS`,
`GLLVM_SPEED_BENCH_ITERS`, `GLLVM_SPEED_BENCH_PROFILE_CI`) and per-family
progress logging. Default full-run behaviour is unchanged.

Quick decision grid:

```sh
GLLVM_SPEED_BENCH_GRID=quick GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=80 GLLVM_SPEED_BENCH_PROFILE_CI=0 \
  /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma results:

| size | finite s | analytic s | speedup | delta logLik |
| --- | ---: | ---: | ---: | ---: |
| 8x40x1 | 0.2573 | 0.0255 | 10.09x | 2.842e-14 |
| 12x60x1 | 0.6706 | 0.0693 | 9.68x | 2.842e-13 |

Medium confirmation cell:

```sh
GLLVM_SPEED_BENCH_GRID=20,100,2 GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=120 GLLVM_SPEED_BENCH_PROFILE_CI=0 \
  /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma result: finite `10.8304s`, analytic `0.7590s`, speedup `14.27x`,
`delta logLik = -1.819e-12`.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_fit.jl
```

Result: `7/7 pass` in `10.7s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_laplace.jl
```

Result: `2/2 pass` in `2.2s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_laplace_grad.jl
```

Result: `26/26 pass` in `31.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m09.1s`.

### Rose Verdict

PASS WITH NOTES. Benchmark gate and full package tests passed after the default
change. Remaining note: R bridge parity was not rerun because the likelihood
target and bridge payload shape are unchanged.

## 2026-06-14 - JuliaConnectoR Bridge Smoke Repair

### Scope

Repaired the older `r/gllvmjl.R` / `r/gllvmtmb_julia.R` JuliaConnectoR scaffold
enough for a live transport smoke check:

- `gllvm_jl_init()` now loads `Distributions`, so family marker constructors such
  as `Distributions.Poisson()` are available.
- Added `.jl_value()` to tolerate JuliaConnectoR fields that are already
  converted to R values, avoiding double-`juliaGet()` failures on `β`, `loglik`,
  coefficient tables, and Unicode dispersion fields.
- Construct family markers through `Distributions.<Family>()`, not through the
  `GLLVM` module handle.
- Updated bridge README/status prose from "not executed" to
  "transport smoke-tested; parity open."

### Checks Run

```sh
JULIA_BINDIR="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin" \
JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(); set.seed(11); y <- matrix(rpois(30*4, 3), nrow=30); rownames(y) <- as.character(seq_len(nrow(y))); colnames(y) <- paste0("sp", seq_len(ncol(y))); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", disp.formula=~1, iterations=80L); stopifnot(is.finite(res$julia_fit$logLik), all(is.finite(res$julia_fit$coefficients))); print(res$diffs)'
```

Result: command exited `0`; Julia transport returned finite `logLik` and
coefficients.

Parity result: **not passed**. R `{gllvm}` vs GLLVM.jl on the smoke cell:
`|ΔlogLik| = 0.6194035`, max beta diff `0.04862639`, Procrustes-aligned loading
diff `2.862522`.

### Rose Verdict

PARTIAL. Transport defects are fixed and documented, but the end-to-end R
`gllvm` parity claim remains open. Next slice should reconcile likelihood target,
starts, centering, and parameterization before promoting this bridge path.

## 2026-06-14 - Phylo-signal Wald CI Scale Fix (#92)

### Scope

Ported the narrow fix for GLLVM.jl #92 from the stale `a1-nongaussian-ci` branch
onto the current integration branch. The Gaussian phylo fitter packs the
phylo-unique `σ_phy` block on the natural signed scale, but `_derived_unpack`
was exponentiating it. That over-transformed the `phylo_signal_wald_ci` numerator
and could push H² outside `[0, 1]`.

Changes:

- `_derived_unpack` now reads `σ_phy` directly on the natural signed scale.
- `confint_derived_wald.jl` is included by the package and the transformed-Wald
  derived CI helpers are exported.
- `test_confint_derived_wald.jl` now guards packed-vs-public `phylo_signal`
  equality for both `has_phy_unique` and `K_phy > 0` paths.
- `test_confint_derived_wald.jl` is wired into `test/runtests.jl`.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived_wald.jl
```

Result: `108/108 pass` in `21.3s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived.jl
```

Result: `45/45 pass` in `13.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_profile_derived_fix.jl
```

Result: `20/20 pass` in `10.1s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_profile.jl
```

Result: `4/4 pass` in `21.4s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3869 pass, 1 broken, 0 failed, 0 errored` in `36m18.1s`.

### Rose Verdict

PASS. The scale bug is fixed on the current branch, the orphan test is now part
of the main suite, and the full package gate passed.

## 2026-06-15 - Gaussian-X bridge mean coefficient payload

### Scope

Added the flat `mean_coef::Vector{Float64}` payload field to
`GLLVM.bridge_fit(...; family = "gaussian", X = X)`. The existing Gaussian-X
fields are preserved; the new field exposes the full mean coefficient vector
needed by the R bridge to reconstruct in-sample fitted values for the supplied
`X` design.

Changes:

- `src/bridge.jl` now merges `mean_coef = fit.pars.β` onto the Gaussian-X bridge
  payload.
- `test/test_bridge_x.jl` now checks that `mean_coef` is a `Vector{Float64}` and
  equals the native Gaussian fit coefficient vector exactly.
- `docs/src/gllvmtmb-parity.md` records the payload contract.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: `52/52 pass` in `17.4s`.

### Rose Verdict

PASS WITH NOTES. This is a payload-only bridge change, not a likelihood change.
It closes the R-side Gaussian-X in-sample prediction gap when paired with the
matching `gllvmTMB` consumer; `newdata` prediction and ordinal probabilities
remain separate bridge payloads.

## 2026-06-15 - Bridge capability reporter for R drift guard

### Scope

Added `GLLVM.bridge_capabilities()` as a flat, JuliaCall-friendly reporter for
the current `bridge_fit` surface. The helper does not change fitting behavior;
it lets `gllvmTMB` enforce a one-way bridge-drift contract: every R-admitted
row must be supported by the paired Julia checkout, while Julia-only rows must
be explicitly planned or rejected on the R side.

Changes:

- `src/bridge.jl` now defines `_BRIDGE_ONEPART_FAMILIES` and the exported
  `bridge_capabilities()` ledger.
- `src/GLLVM.jl` exports `bridge_capabilities`.
- `test/test_bridge_capabilities.jl` locks the reported rows, including NB1 as
  a Julia one-part no-X route and the mixed-family vector route as no-X only.
- `docs/src/gllvmtmb-parity.md` records the R drift-guard contract.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.1s`.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3891 pass, 3 broken, 0 failed, 0 errored` in `30m39.8s`.

```sh
~/.juliaup/bin/julia --project=docs docs/make.jl
```

Result: failed before rendering because `Documenter` was not installed in the
docs environment.

```sh
~/.juliaup/bin/julia --project=docs -e 'using Pkg; Pkg.instantiate()'
```

Result: failed with `expected package GLLVM [2dc8e01c] to be registered`.
No docs source error was reached.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 353` in `61.6s`, including the new live R subset guard against
`GLLVM.bridge_capabilities()`.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The capability reporter is metadata-only and live-consumed by
the R bridge drift test. The local Documenter build remains blocked by the
pre-existing docs-environment registration issue, so no rendered-docs claim is
made for this slice.
