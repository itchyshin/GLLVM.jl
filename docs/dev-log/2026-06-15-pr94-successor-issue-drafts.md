# 2026-06-15 - PR #94 Successor Issue Drafts

## Purpose

`GLLVM.jl#94` is a broad, stale, conflicting draft PR. The local audit in
`docs/dev-log/2026-06-15-pr94-unique-content-audit.md` concluded:

- do not merge `#94`;
- do not cherry-pick broad files from it;
- preserve candidate unique ideas through narrow successor issues before closing.

This file is the local issue/comment draft bank. Nothing here has been posted to
GitHub yet.

## Existing Issues To Reuse

Before creating new issues, avoid duplicates with these live issues:

- `#7` Families: original family-abstraction umbrella.
- `#9` Engine postfit: predict / residuals / summary / show.
- `#10` R bridge.
- `#13` Cross-project learning.
- `#27` Missing-data handling.
- `#61` Phylogenetic Poisson implicit-gradient route.
- `#62` SPDE / Matérn-GMRF spatial module.
- `#65` Analytic Laplace gradients and non-Gaussian benchmarking.
- `#98` Per-response-column family dispatch.

Recommendation: create narrow successor issues for the #94 remnants below, then
link them back to `#7`, `#9`, `#10`, `#13`, and/or `#65` as appropriate. Do not
dump the whole #94 list into the old umbrella issues where it will disappear.

## Issue Draft 1 - Generalized Poisson Family

Title:

```text
[families] Generalized Poisson GP-1 family from #94 archive
```

Body:

```markdown
Source: archived draft PR #94 (`src/families/genpoisson.jl`).

Goal
Implement or deliberately reject a Generalized Poisson GP-1 one-part family for
GLLVM.jl, preserving the useful idea from #94 without importing stale broad PR
state.

Claim boundary
- Planned until reimplemented or audited on current integration.
- Do not reuse #94 code wholesale.
- Parameterization must be documented before user-facing promotion.

Candidate parameterization from #94
- Mean parameterization: `μ = exp(η)`.
- Dispersion `α` can be positive or negative.
- Variance `Var(Y) = μ(1 + αμ)^2`.
- Poisson limit at `α = 0`.

Acceptance gates
- Domain/support tests for `1 + αμ > 0` and `1 + αy > 0`.
- Poisson-limit exactness tests at `α -> 0`.
- Conditional logpdf, score, and weight verified against finite differences.
- Laplace marginal gradient-vs-FD gate ≤ 1e-6.
- ADEMP recovery test with over- and under-dispersed cells.
- `fit_gllvm` route and explicit R bridge status: covered / partial / planned.
- Wald/profile/bootstrap CI status or explicit unsupported status.
- Docs row in response-family matrix and caveat about under-dispersion.
- After-task report and Rose audit.

Related issues
- #7 family expansion umbrella.
- #65 analytic-gradient / benchmark umbrella.
```

Suggested labels: `families`, `engine`, `enhancement`.

## Issue Draft 2 - Student-t One-Part Family

Title:

```text
[families] Student-t heavy-tailed continuous family from #94 archive
```

Body:

```markdown
Source: archived draft PR #94 (`src/families/studentt.jl`).

Goal
Evaluate and, if sound, implement a Student-t one-part GLLVM family for
heavy-tailed continuous responses.

Claim boundary
- Planned until current-code implementation and recovery tests pass.
- Fixed-ν and estimated-ν are different models. Do not imply both.
- If `ν` is fixed, it is a user control, not an estimated dispersion target.

Candidate parameterization from #94
- Identity link, location `η`.
- Scale `σ > 0`, estimated on log scale.
- Degrees of freedom `ν` fixed in v1.

Acceptance gates
- Closed-form density checked against `Distributions` or direct reference.
- Score/weight verified against finite differences.
- Gaussian-limit sanity check for large `ν` where numerically feasible.
- Robustness recovery simulation with outlier contamination.
- Identifiability and CI policy: `σ` CI supported/statused; `ν` fixed/excluded.
- R bridge support or deliberate tested rejection.
- Docs row and article example showing why this is not the Gaussian family.
- Rose review for overclaiming around robustness.

Related issues
- #7 family expansion umbrella.
- #65 analytic-gradient / benchmark umbrella.
```

Suggested labels: `families`, `engine`, `enhancement`.

## Issue Draft 3 - True One-Part Lognormal Family

Title:

```text
[families] True one-part lognormal family, distinct from delta-lognormal
```

Body:

```markdown
Source: archived draft PR #94 (`src/families/lognormal.jl`).

Goal
Decide whether GLLVM.jl should expose a true one-part lognormal family for
strictly positive continuous responses.

Claim boundary
- Current integration already supports delta-lognormal two-part models.
- This issue is only for strictly-positive one-part lognormal responses.
- Do not call this covered until the support distinction is visible in docs,
  bridge gates, and tests.

Acceptance gates
- Support checks: all responses strictly positive; zeros fail deliberately.
- Equivalence to Gaussian GLLVM on `log(Y)` where the same model is fitted.
- Fit, predict, residuals/PIT, and CI status.
- Bridge route or tested rejection with precise error message.
- Docs row distinguishing one-part lognormal from delta-lognormal.
- Recovery test and after-task report.

Related issues
- #7 family expansion umbrella.
- #9 postfit / residuals surface.
```

Suggested labels: `families`, `engine`, `documentation`.

## Issue Draft 4 - Standalone Zero-Truncated Count Families

Title:

```text
[families] Standalone zero-truncated Poisson/NB, distinct from hurdle positives
```

Body:

```markdown
Source: archived draft PR #94 (`src/families/truncpoisson.jl`,
`src/families/truncnb.jl`).

Goal
Decide whether to expose standalone one-part zero-truncated Poisson and NB2
families.

Claim boundary
- Current integration has hurdle Poisson/NB positive components inside the
  two-part substrate.
- A standalone zero-truncated one-part family is a different public model.
- Do not import #94 files wholesale.

Acceptance gates
- Support checks: response counts must be ≥ 1; zeros fail deliberately.
- Reduction tests:
  - zero-truncated NB -> zero-truncated Poisson as `r -> Inf`;
  - large-μ zero-truncated Poisson approaches ordinary Poisson.
- Score/weight finite-difference checks.
- Fit recovery tests for Poisson and NB2 truncation.
- CI status for intercepts/loadings/dispersion `r`.
- Bridge route or tested rejection.
- Docs row explaining distinction from hurdle families.

Related issues
- #7 family expansion umbrella.
- #9 postfit surface.
```

Suggested labels: `families`, `engine`, `documentation`.

## Issue Draft 5 - ANOVA/LRT And Model Comparison

Title:

```text
[inference] ANOVA/LRT model-comparison API with boundary-safe wording
```

Body:

```markdown
Source: archived draft PR #94 (`src/anova.jl`).

Goal
Provide a model-comparison surface for nested GLLVM fits without overclaiming
ordinary chi-square validity in boundary or weak-identifiability cases.

Claim boundary
- Ordinary LRT χ² reference is valid only for regular nested fixed-effect-like
  comparisons.
- Variance components, latent-dimension changes, zero-inflation boundaries, and
  dispersion boundaries need special status or simulation/profile evidence.

Acceptance gates
- `_loglik` and `_nparams` coverage for all current fit types.
- Regular nested-model LRT tests with known df.
- Boundary tests routed to existing `boundary_inference.jl` where applicable.
- Explicit status vocabulary for invalid/not-supported comparisons.
- AIC/BIC compatibility retained.
- Docs article section with examples and warnings.
- Rose/Fisher signoff.

Related issues
- #9 postfit/model summary surface.
- #65 inference/benchmark umbrella.
```

Suggested labels: `inference`, `api`, `documentation`.

## Issue Draft 6 - Unified Check-Fit Diagnostics

Title:

```text
[diagnostics] Unified check_fit diagnostics, calibration, and plots
```

Body:

```markdown
Source: archived draft PR #94 (`src/diagnostics.jl`).

Goal
Create a unified diagnostics layer for fitted GLLVM models, including
calibration summaries, residual/PIT plots, and parity checks where valid.

Claim boundary
- Current integration has residual/postfit coverage for several families, but
  not a single audited diagnostics contract.
- Residual diagnostics differ by continuous, discrete, two-part, ordinal, and
  structured models.

Acceptance gates
- Family-by-family diagnostics support matrix.
- Continuous PIT exactness tests.
- Discrete randomized PIT reproducibility with controlled RNG.
- Unsupported/partial status for families without valid residual definitions.
- Visual diagnostic helpers or documented plotting recipes.
- Article example with raw residual distribution and caveats.
- Pat/Fisher/Rose review.

Related issues
- #9 predict/residuals/summary/show.
```

Suggested labels: `diagnostics`, `postfit`, `documentation`.

## Issue Draft 7 - Structured Schur / Structured Poisson Prototype

Title:

```text
[speed] Structured Schur / structured Poisson prototype from #94 archive
```

Body:

```markdown
Source: archived draft PR #94 (`src/structured_schur.jl`,
`src/families/structured_poisson.jl`, `bench/structured_*`).

Goal
Evaluate the archived structured Schur / structured Poisson prototype as a
candidate substrate for non-Gaussian structured-dependence speedups.

Claim boundary
- Prototype only until equality, gradient, CI/status, and benchmark gates pass.
- Do not advertise as SPDE/kernel/phylo support without matching structural
  tests.
- AI-REML language is not valid here unless the model is exact Gaussian REML.

Acceptance gates
- Define the exact estimand and structure represented by the precision matrix.
- Dense-reference equality tests for objective/logLik.
- Gradient-vs-FD ≤ 1e-6.
- Point-estimate equality to a baseline fitter.
- CI/status equality for at least one inference target or explicit CI hold.
- Benchmark metadata: OS, CPU, Julia SHA, BLAS/threads, cold/warm split.
- No copied external code without provenance note.
- Rose/Karpinski/Gauss signoff.

Related issues
- #61 phylogenetic Poisson route.
- #62 SPDE / Matérn-GMRF.
- #65 analytic-gradient / speed umbrella.
```

Suggested labels: `speed`, `engine`, `structured-dependence`.

## Existing Benchmark Issue Comment

Do not create a new benchmark issue for the stale #94 scripts. Route the
benchmark-script rebuild into existing benchmark/runtime issues, especially
`#65` for non-Gaussian analytic-gradient benchmarking and `#61` for the
phylogenetic Poisson route.

Suggested comment text:

```markdown
#94 also carried stale benchmark scripts:

- `bench/non_gaussian_gllvmtmb_bench.jl`
- `bench/phylo_poisson_gllvmtmb_bench.jl`

Do not run or cite those scripts as evidence. Rebuild them against current
integration and the current R bridge contract before making any speed claim.

Required metadata:
- OS/CPU/memory;
- Julia/R versions;
- package SHAs and dirty flags;
- BLAS/OpenMP/JULIA thread settings;
- cold start vs warm start;
- direct Julia kernel time;
- R bridge marshalling and reconstruction time;
- point estimates/logLik/CI-status checks.
```

## Draft Comment For PR #94

```markdown
I audited #94 against current local integration and the current #95 state.

Verdict: do not merge #94 as a branch. It is draft/conflicting and overlaps many
files that have since been corrected, renamed, or extended. A wholesale merge
would risk overwriting validated fixes (#91/#92, Gamma analytic default,
JuliaConnectoR bridge smoke/parity repairs, sparse-phylo node-gradient shortcut,
and test-warning hygiene).

Path classification against current integration:

| class | count |
| --- | ---: |
| absent from integration | 124 |
| present but different from local integration | 50 |
| byte-identical to local integration | 2 |

Byte-identical:
- `src/boundary_inference.jl`
- `src/reml.jl`

I recommend closing #94 only after successor issues/comments exist for the
candidate unique rows:

1. Generalized Poisson family.
2. Student-t family.
3. True one-part lognormal family.
4. Standalone zero-truncated Poisson/NB.
5. ANOVA/LRT and model-comparison API.
6. Unified check-fit diagnostics, calibration, and plots.
7. Structured Schur / structured Poisson prototype.

Benchmark-script rebuild notes from #94 should be routed to existing benchmark
issues (#65 and #61) rather than opened as a duplicate issue.

Local audit artifact:
`docs/dev-log/2026-06-15-pr94-unique-content-audit.md`

No #94 code was validated by this audit; it is only a preservation and
supersession ledger.
```

## Maintainer Decision Needed

Remote mutation is intentionally not done yet.

Decision required:

1. Should Codex create the seven successor issues on GitHub and comment on #94?
2. Should #94 be closed after those successor issues exist?
3. Should the local runtime-fix stack on `codex/high-rate-poisson-safeguard`
   be pushed as a PR before #95 is merged?

Important: `#95` currently points to remote `integration` at `65a1f10`. The
local runtime-fix stack adds these commits on top:

```text
e35c90b fix: safeguard high-rate Poisson Laplace modes
0d3bce5 test: make family CI test self-contained
843e33d docs: fix Vitepress page links
a208b28 perf: default Gamma fits to analytic gradients
6730d9d fix: repair JuliaConnectoR bridge smoke path
06e7c08 fix: wire phylo-signal Wald CI scale fix
387604c docs: clean stale runtime status wording
9639528 fix: activate local Julia bridge parity smoke
85efde2 perf: route sparse phylo unique gradients through node path
d3d8129 test: remove duplicate method warnings
862f081 docs: audit superseded pr94 content
```

Those commits are not included in the current remote #95 unless the maintainer
chooses to promote/push them.
