# 2026-06-15 - PR #94 Unique-Content Audit

## Scope

Audit `GLLVM.jl#94` (`a1-nongaussian-ci`) before anyone closes or supersedes it.
The PR is too broad to merge safely, but it still contains candidate ideas that
must not be lost.

Live PR snapshot:

- `#94` title: `Non-Gaussian families, inference, REML, missing-data, RE layer + R->Julia bridge`
- state: open draft
- mergeability: conflicting
- base: `main`
- head: `a1-nongaussian-ci` at `09fc846`
- URL: `https://github.com/itchyshin/GLLVM.jl/pull/94`

Reference branch:

- `#95` title: `integration: green tree + EM-FA per-var default (review)`
- state: open draft
- mergeability: mergeable
- head: `integration` at `65a1f10`

Local integration audit head:

- branch: `codex/high-rate-poisson-safeguard`
- head at initial audit time: `d3d8129`
- successor-issue review head before remote mutation: `862f081`

## Method

Fetched PR heads locally without changing branches:

```sh
git fetch origin pull/94/head:refs/remotes/origin/pr-94 \
    pull/95/head:refs/remotes/origin/pr-95 main integration
```

Classified every `origin/main...origin/pr-94` path by comparing the PR blob hash
against `HEAD` and `origin/integration`.

Result:

| class | count | meaning |
| --- | ---: | --- |
| `absent-from-integration` | 124 | path exists in #94 but not current integration |
| `present-different-local-head` | 50 | path exists now, but current integration has different content |
| `same-as-local-head` | 2 | path is byte-identical to current integration |

Byte-identical rows:

- `src/boundary_inference.jl`
- `src/reml.jl`

## Decision

Do not merge `#94`.

Reasons:

- It is draft and conflicting.
- Its base is stale relative to `#95` and the current local integration branch.
- It overlaps many files that have since been corrected, renamed, or extended.
- A wholesale checkout would overwrite later validated work, including #91/#92
  fixes, Gamma analytic-gradient defaulting, bridge smoke/parity repairs, the
  sparse phylo node-gradient shortcut, and test warning hygiene.

Treat `#94` as an archival source for follow-up issues and selective manual
ports only.

## Likely Superseded By Current Integration

These should not be ported from `#94` without a fresh side-by-side review,
because current integration has newer implementations under different names or
broader substrates:

- `src/families/betabinomial.jl` -> current `src/families/beta_binomial.jl`
- `src/families/compoisson.jl` -> current `src/families/com_poisson.jl`
- `src/families/nb1.jl` -> current `src/families/negbin1.jl`
- `src/families/zip.jl`, `src/families/zinb.jl`,
  `src/families/zibinom.jl` -> current two-part/mixture substrate in
  `src/families/twopart.jl`, plus current `src/postfit.jl` and
  `src/confint_family.jl`
- `src/confint_families*.jl` -> current consolidated `src/confint_family.jl`
- `src/postfit_families*.jl` -> current consolidated `src/postfit.jl`
- `src/bridge.jl` and bridge tests -> current bridge has narrower,
  runtime-validated no-X contract plus later JuliaConnectoR parity smoke
- many docs/after-task files -> older historical ledger; do not import wholesale
  into current status docs

## Candidate Unique Work To Preserve As Successor Issues

These are the main #94 remnants that appear not to have a direct current
integration equivalent. Each needs a narrow issue, parameterization note,
tests, and runtime validation before any port.

### Extra One-Part Families

- `src/families/genpoisson.jl`
  - Generalized Poisson GP-1 with under/over-dispersion.
  - Needs domain/support tests, Poisson-limit tests, gradient-vs-FD, recovery,
    bridge mapping, and docs before promotion.
- `src/families/studentt.jl`
  - Heavy-tailed continuous Student-t with fixed `ν` and scale `σ`.
  - Needs identifiability and CI status review; fixed vs estimated `ν` must be
    explicit.
- `src/families/lognormal.jl`
  - True one-part lognormal candidate.
  - Current integration covers Delta-lognormal two-part models, not a standalone
    one-part lognormal row.
- `src/families/truncpoisson.jl`
- `src/families/truncnb.jl`
  - Current integration has hurdle Poisson/NB positive components inside
    `twopart.jl`.
  - A standalone one-part zero-truncated family still needs its own public
    support decision.

### Model Comparison And Diagnostics

- `src/anova.jl`
  - LRT/anova surface for nested models.
  - Needs boundary-status handling and no-overclaim language; LRTs for variance
    components are not ordinary chi-square by default.
- `src/diagnostics.jl`
  - PIT/randomized quantile residual helpers.
  - Current integration has postfit/residual coverage in several places, but a
    unified diagnostics surface still needs Pat/Fisher/Rose review.

### Structured Non-Gaussian Speed Substrate

- `src/structured_schur.jl`
- `src/families/structured_poisson.jl`
- `bench/structured_*`
  - Candidate substrate for structured non-Gaussian dependence and future speed
    work.
  - Must be treated as prototype material until it has equality tests, gradient
    checks, benchmark metadata, and CI/status evidence.

### Benchmarks And Parity Scripts

- `bench/non_gaussian_gllvmtmb_bench.jl`
- `bench/phylo_poisson_gllvmtmb_bench.jl`
  - Potentially useful as benchmark seeds, but stale relative to current
    bridge/parameterization work. Rebuild rather than run blindly.

## Close/Supersede Gate For #94

Before closing `#94`, create successor issues or issue comments for the
candidate unique rows above:

1. Generalized Poisson family.
2. Student-t family.
3. Standalone true lognormal family.
4. Standalone zero-truncated Poisson/NB.
5. ANOVA/LRT and model-comparison API.
6. Unified diagnostics / randomized quantile residuals.
7. Structured Schur / structured Poisson speed substrate.
8. Old gllvmTMB/non-Gaussian benchmark scripts as rebuild tasks.

Then comment on `#94` with this audit and close as superseded by `#95` plus the
new successor issues. Do not merge `#94` and do not cherry-pick broad files from
it without new tests.

## Rose Verdict

Partial but actionable. The audit proves `#94` cannot be merged safely and
identifies the candidate unique work that must be preserved. It does not itself
validate any #94 code.
