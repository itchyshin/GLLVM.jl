# Check Log

## 2026-06-02 - Sparse Phy Single-Axis Takahashi Gradient

### Scope

Swapped the `K_aug == 1` branch of `sparse_phy_grad` onto same-leaf Takahashi
selected-inverse entries. This is an internal Gaussian sparse-phylo gradient
performance slice: no exported API, likelihood parameterization, fitter default,
or response-family interface changed. The general multi-axis branch remains
the exact dense leaf-block path and is still `O(p²)`.

### Implementation

- `sparse_phy_grad(st)` now dispatches `K_aug == 1` to
  `_sparse_phy_grad_single_axis_takahashi`.
- `_single_axis_Msad_inv_diag` computes the same-leaf diagonal of
  `M_sad^-1` from `takahashi_diag(st.chol_Q_eff)` plus the rank-`K_B`
  Woodbury correction.
- Single-axis loading/scalar gradient helpers reuse the existing low-rank
  sparse-operator algebra and support both one `Λ_phy` axis and phylo-unique
  `σ_phy`.
- The source, benchmark comments, and `docs/src/benchmarks.md` now distinguish
  the Takahashi-backed single-axis path from the still-`O(p²)` multi-axis path.

### Correctness Tests

Focused gradient tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_takahashi_selinv.jl"); include("test/test_sparse_phy_grad.jl"); include("test/test_node_gradient.jl")'
```

Result: `Takahashi selected inverse` 8/8 pass; `sparse phy analytic gradient`
36/36 pass; `node-frame analytic gradient` 58/58 pass.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: manual tally from emitted summaries = 2400 pass, 1 existing
`sparse phy precision` broken placeholder, 2 expected direct-environment
quality placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: manual tally from emitted summaries = 2412 pass, 1 existing
`sparse phy precision` broken placeholder, 0 fail, 0 error. The `quality`
testset passed 12/12 and `Pkg.test()` printed `Testing GLLVM tests passed`.

Docs:

```sh
julia --project=docs --startup-file=no docs/make.jl
julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "docs"); include("docs/make.jl")'
```

Result: the direct docs environment failed before rendering because its
manifest is stale for the current package graph (`SpecialFunctions` direct-dep
metadata was not visible from `docs/`). The stacked main+docs environment built
successfully. Documenter still emitted pre-existing local-link warnings and npm
reported existing moderate audit notices.

### Tests Added

- `test/test_sparse_phy_grad.jl`: one helper regression assertion checks
  `_single_axis_Msad_inv_diag(st) ≈ diag(leaf_block_inv(st))` on the one-axis
  `Λ_phy` fixture. This compares the new Takahashi diagonal route with the
  independent exact dense leaf-block helper and would have failed before the
  helper existed.

### Benchmark Evidence

Pre-edit scout at `d3c4899` (`@elapsed` / `@allocated`, same fixed-seed
single-axis fixture):

```text
p=80  time=0.000867875  bytes=3127176
p=160 time=0.001673083  bytes=12326232
p=320 time=0.014568791  bytes=47541240
```

Current scout:

```text
p=80  time=0.000126458  bytes=900224
p=160 time=0.000604542  bytes=3011760
p=320 time=0.001408000  bytes=11183392
```

BenchmarkTools medians via stacked env
(`julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "bench"); ...'`):

```text
p=80  median_time_ns=205396.0    median_memory=900224   median_allocs=345
p=160 median_time_ns=607542.0    median_memory=3011760  median_allocs=345
p=320 median_time_ns=1.6402295e6 median_memory=10920448 median_allocs=373
```

Full sparse-gradient benchmark script:

```sh
julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "bench"); include("bench/sparse_phy_grad_bench.jl")'
```

Result:

```text
p=100  analytic=0.219 ms dense-FD=120.654 ms speedup=549.9x
p=500  analytic=0.773 ms dense-FD=52541.520 ms speedup=68000.2x
p=1000 analytic=1.612 ms dense-FD=skipped
p=5000 analytic=7.654 ms dense-FD=skipped
analytic log-log slopes: [0.782, 1.061, 0.968]
dense-FD log-log slopes: [3.776]
```

Interpretation: the single-axis sparse analytic gradient is now near-linear in
the measured range. Dense ForwardDiff remains unusable beyond the cutoff.

### DRM.jl Capacity Check

Fetched `/Users/z3437171/Dropbox/Github Local/DRM.jl` and checked
`origin/main` rather than the dirty local branch. DRM.jl already has the same
capacity:

- `src/DRM.jl` documents the q=4 sparse augmented-state Laplace path with an
  exact `O(p)` gradient via Takahashi selected inverse.
- `src/fit_q4_sparse_tmb.jl` calls `takahashi_selinv(chH)` for the selected
  inverse of `H` and uses it in the log-determinant derivative.
- `test/test_step1_sparse.jl` checks Takahashi selected inverse and diagonal
  entries against dense inverse calculations.
- `README.md` advertises the exact `O(p)` marginal gradient.

No GitHub issue was opened for DRM.jl because the requested capacity is already
present on `origin/main`.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked public content, excluding .gitignore and generated docs>
rg -n 'Takahashi follow-up would bring|Analytic slope ≈ 2|NOT yet O\(p\)|selected-inverse term|older `sparse_phy_grad` path|gradient stays at O\(p²\) overall|inapplicable to the gradient|sparse analytic gradient code is intentionally NOT wired|PERF\+\+ hard constraint|do NOT modify src/GLLVM' src bench docs/src README.md CLAUDE.md test/test_sparse_phy_grad.jl
rg -n 'single-axis|multi-axis|K_aug == 1|Takahashi|O\(p²\)|O\(p\)' src/sparse_phy_grad.jl bench/sparse_phy_grad_bench.jl docs/src/benchmarks.md test/test_sparse_phy_grad.jl
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public content, excluding `.gitignore`
  and generated docs: no matches.
- Stale Takahashi/wiring scan: no remaining hits in the touched sparse-phy
  gradient files; unrelated historical hard-constraint comments remain in other
  benchmark/prototype files.
- Scope scan: expected hits in `src/sparse_phy_grad.jl`,
  `bench/sparse_phy_grad_bench.jl`, `docs/src/benchmarks.md`, and the focused
  sparse-phy gradient test.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.
- Allocs.jl check: `Package Allocs not found in current path`; allocation
  evidence is from `@allocated` and BenchmarkTools memory/alloc counters.

## 2026-06-02 - Structured Schur K3 Site Inverse

### Scope

Specialized the `K == 3` site inverse/logdet construction inside
`_SchurUOperator`. This is an internal structured Schur performance slice only:
no public API, fitter default, likelihood parameterization, docs syntax, or
R-parity surface changed.

### Implementation

- `_SchurUOperator` now builds each `K == 3` site matrix
  `A_s = I + Lambda' diag(w_s) Lambda` by scalar upper-triangle accumulation.
- The branch stores `A_s^-1` from the closed-form adjugate/determinant formula
  and `logdet(A_s) = log(det(A_s))`, bypassing the generic tiny Cholesky path.
- `test/test_structured_schur.jl` now includes a workspace sentinel check that
  pre-fills `ws.Amats` with `NaN` and verifies the `K == 3` constructor leaves
  those generic buffers untouched while preserving dense Schur equivalence.

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 185 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2399 pass, 3 expected broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2411 pass, 1 existing sparse-phy precision placeholder, 0 fail, 0
error. The `quality` testset passed 12/12.

### Benchmark Evidence

Baseline was a detached `HEAD` worktree at `3cd756d`, with the local ignored
`Manifest.toml` copied in only to reproduce the same dependency set.

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=3 --warmups=2 --out=/tmp/structured-schur-k3ainv-baseline-2026-06-02.csv
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=3 --warmups=2 --out=/tmp/structured-schur-k3ainv-current-2026-06-02.csv
```

Constructor timing from the benchmark CSV:

```text
giant  baseline=0.004299 s current=0.000370 s speedup=11.61x
xlarge baseline=0.017711 s current=0.001396 s speedup=12.69x
```

Same-fixture constructor allocation check:

```text
giant  baseline=80432 bytes current=80432 bytes
xlarge baseline=160304 bytes current=160304 bytes
```

Exact logdet check from the current benchmark:

```text
giant  dense=0.011113 s lemma=0.024175 s lemma_relerr=1.587e-15
xlarge dense=0.089015 s lemma=0.054723 s lemma_relerr=1.551e-15
```

Interpretation: the target constructor path is about 11.6x-12.7x faster with
stable constructor allocations. End-to-end exact lemma timing is mixed at this
short-rep setting, but the exact lemma values remain at roundoff relative error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "[T]ODO|[F]IXME|[T]BD|[P]LACEHOLDER|[p]ending" docs/dev-log/after-task/2026-06-02-structured-schur-k3-site-inverse.md
rg -n "K3 Site Inverse|K == 3|c11|c12|c13|detA|structured-schur-k3ainv" src/structured_schur.jl test/test_structured_schur.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-02-structured-schur-k3-site-inverse.md
rg -n "K3 Site Inverse|site inverse|A_s\\^-1|structured Schur" README.md CLAUDE.md docs/src docs/PERF-plus-design.md 2>/dev/null
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder scan for the after-task report: clean.
- K3 site-inverse scan: expected source and new report/check-log hits, plus
  historical K3 factor check-log handles from the broad `K == 3` pattern.
- User-facing stale wording scan: no hits requiring README, CLAUDE.md, or docs
  updates for this internal-only change.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Structured Schur K3 Factor

### Scope

Specialized the `K == 3` exact Schur factor used by the internal
determinant-lemma/Woodbury path. This is an internal fast-algorithm slice only:
no public API, fitter default, CI/bootstrap, likelihood parameterization, or
R-parity surface changed.

### Implementation

- `_schur_u_tinyk_factor!` now writes the `K == 3` lower factor of
  `A_s^{-1}` by scalar formula.
- `test/test_structured_schur.jl` now directly checks each tiny-`K` site factor
  against `B_s A_s^{-1} B_s'` for `K = 1, 2, 3`.

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 183 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2397 pass, 3 expected broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2409 pass, 1 existing sparse-phy precision placeholder, 0 fail, 0
error. The `quality` testset passed 12/12.

### Benchmark Evidence

Baseline K=3 scout before this change:

```text
frontier p= 640 n= 160 K=3 factor=0.00046 s bytes=4.35e+04 lemma=0.00507 s dense=0.00443 s dense/lemma=0.87x
giant    p=1024 n= 256 K=3 factor=0.00116 s bytes=6.96e+04 lemma=0.00952 s dense=0.01479 s dense/lemma=1.55x
xlarge   p=2048 n= 512 K=3 factor=0.00464 s bytes=1.39e+05 lemma=0.05562 s dense=0.07578 s dense/lemma=1.36x
```

After closed-form K3 factor:

```text
frontier p= 640 n= 160 K=3 factor=0.00009 s bytes=0.00e+00 lemma=0.00383 s dense=0.00259 s dense/lemma=0.68x
giant    p=1024 n= 256 K=3 factor=0.00032 s bytes=0.00e+00 lemma=0.01114 s dense=0.01098 s dense/lemma=0.99x
xlarge   p=2048 n= 512 K=3 factor=0.00130 s bytes=0.00e+00 lemma=0.04694 s dense=0.06841 s dense/lemma=1.46x
```

Repo benchmark:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=3 --warmups=2 --out=/tmp/structured-schur-logdet-k3factor-2026-06-01.csv
```

Result:

```text
giant  p=1024 n=256 K=3 dense=0.0136 s lemma=0.0126 s slq=0.2406 s dense/lemma=1.08x lemma_relerr=1.587e-15 slq_relerr=3.181e-04
xlarge p=2048 n=512 K=3 dense=0.1189 s lemma=0.0880 s slq=1.0137 s dense/lemma=1.35x lemma_relerr=1.551e-15 slq_relerr=2.610e-04
```

Interpretation: the factor step is about 3.6x-5.1x faster and zero-allocation
in the scout. The full exact lemma logdet is faster than dense in the
giant/xlarge benchmark rows and exact to roundoff, while SLQ is still slower at
these sizes.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "K3 Factor|K == 3|l31|l32|l33|structured-schur-logdet-k3factor" src/structured_schur.jl test/test_structured_schur.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-k3-factor.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the guard patterns used in this audit.
- K3 factor scan: expected current source/report hits only.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Structured Schur K2 Workspace

### Scope

Reduced exact determinant-lemma/Woodbury overhead for the internal structured
Poisson gradient path. This is an internal fast-algorithm slice only: no public
API, fitter default, confidence-interval, bootstrap, or R-parity surface
changed.

### Implementation

- Added a closed-form `K == 2` lower factor in `_schur_u_tinyk_factor!`,
  avoiding a generic tiny Cholesky per site.
- Added a workspace overload for `_schur_u_woodbury_inv_apply!`.
- Reused the Woodbury apply workspaces across chunked exact lemma-gradient site
  RHS blocks in `src/families/structured_poisson.jl`.
- Added workspace-overload correctness and dimension-guard tests.

### Rejected Scout

An exact `mode_solve = :woodbury` path for the structured Poisson inner mode was
tested and removed before commit. It matched dense to roundoff but was slower
than CG on the measured medium/large cells and used more memory.

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 168 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2382 pass, 3 expected broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2394 pass, 1 existing sparse-phy precision placeholder, 0 fail, 0
error. The `quality` testset passed 12/12.

### Benchmark Evidence

Exact structured Poisson dense-vs-lemma gradient benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-k2factor-workspace-2026-06-01.csv
```

Result:

```text
medium   p= 512 n= 128 K=2 dense=0.0317 s lemma=0.0288 s speedup=1.10x bytes=(9.85e+06, 1.97e+07) valuediff=0.00e+00 gradrel=1.20e-16
large    p=1024 n= 256 K=2 dense=0.1253 s lemma=0.1105 s speedup=1.13x bytes=(3.86e+07, 6.99e+07) valuediff=0.00e+00 gradrel=1.73e-16
xlarge   p=2048 n= 512 K=2 dense=0.7084 s lemma=0.4419 s speedup=1.60x bytes=(1.53e+08, 2.61e+08) valuediff=0.00e+00 gradrel=1.64e-16
```

Higher-rep large/xlarge spot check:

```text
large    p=1024 n= 256 K=2 dense=0.1200 s lemma=0.1101 s speedup=1.09x bytes=(3.86e+07, 6.99e+07) valuediff=0.00e+00 gradrel=1.44e-16
xlarge   p=2048 n= 512 K=2 dense=0.8349 s lemma=0.5128 s speedup=1.63x bytes=(1.53e+08, 2.61e+08) valuediff=0.00e+00 gradrel=1.99e-16
```

Interpretation: the exact lemma path is faster than dense in the large and
xlarge rows and agrees to roundoff, but it remains memory-heavier than dense.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "mode_solve = :woodbury|mode_solve=:woodbury|K2 Workspace|k2factor|workspace" src/structured_schur.jl src/families/structured_poisson.jl test/test_structured_schur.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-k2-workspace.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the guard patterns used in this audit.
- Workspace scan: expected current helper/report hits plus older historical
  workspace ledger rows. The pre-existing exact lemma adjoint still calls the
  joint solve with `mode_solve = :woodbury`; the rejected inner-mode solver
  branch and fitter option do not remain.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Non-Gaussian Benchmark Parity Labels

### Scope

Sharpened `bench/non_gaussian_gllvmtmb_bench.jl` agreement labels for families
that are fast but not yet strict R parity. This prevents NB/Beta/Gamma rows from
being collapsed into a vague parameterization note.

### R Parameter-Name Audit

Temporary R introspection on `gllvmTMB` 0.2.0, smoke-sized data:

```text
NB par length: 15
"b_fix" x5, "theta_rr_B" x5, "log_phi_nbinom2" x5
Beta par length: 15
"b_fix" x5, "theta_rr_B" x5, "log_phi_beta" x5
Gamma par length: 11
"b_fix" x5, "log_sigma_eps" x1, "theta_rr_B" x5
```

Conclusion: for `p=5,K=1`, R `gllvmTMB` uses trait-specific NB dispersion and
Beta precision, while Julia currently uses one shared scalar. Gamma has the same
parameter count as Julia but uses an R-side `log_sigma_eps` parameter, so it
needs a separate sigma/shape likelihood audit.

### Benchmark Smoke Check

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --families=negbin,beta,gamma,ordinal --reps=1 --warmups=1 --out=/tmp/non-gaussian-gllvmtmb-status-labels-2026-06-01.csv
```

Result: completed. A current-tree rerun wrote
`/tmp/non-gaussian-gllvmtmb-status-labels-2026-06-01-rerun.csv`.
Agreement labels now report:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement status |
| --- | ---: | ---: | ---: | --- |
| NegBin | 0.0348 | 0.5860 | 16.85x | `dispersion_scope_mismatch_r_trait_specific` |
| Beta | 0.0158 | 0.5580 | 35.29x | `precision_scope_mismatch_r_trait_specific` |
| Gamma | 0.0161 | 0.4940 | 30.59x | `gamma_sigma_eps_shape_audit_needed` |
| Ordinal | 0.1090 | 0.4830 | 4.43x | `non_equivalent_link` |

The smoke timings still show Julia faster locally, but these rows should not be
used as strict likelihood parity claims until the labeled audit items are
resolved.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "dispersion_scope_mismatch|precision_scope_mismatch|gamma_sigma_eps_shape_audit_needed|same_data_parameterization_audit_needed" bench/non_gaussian_gllvmtmb_bench.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-nongaussian-benchmark-parity-labels.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the guard patterns used in this audit.
- Status-label scan: expected current harness/report hits plus older historical
  benchmark-ledger rows that retain their original generic status wording. The
  generic fallback remains in `agreement_status` for unknown future family
  names.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Non-Gaussian gllvmTMB Smoke Refresh

### Scope

Refreshed the local smoke comparison against R `gllvmTMB` 0.2.0 using the
existing `bench/non_gaussian_gllvmtmb_bench.jl` harness. This was benchmark
evidence only; no source code, public API, or fitter default changed.

### Environment

```sh
which R
Rscript -e 'cat(as.character(utils::packageVersion("gllvmTMB")), "\n")'
```

Result: `/usr/local/bin/R`; `gllvmTMB` 0.2.0.

### Cold Smoke

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --reps=1 --warmups=0 --out=/tmp/non-gaussian-gllvmtmb-smoke-2026-06-01.csv
```

Cold result: completed, but Gaussian/binomial/ordinal are dominated by Julia
first-call compilation and should not be used as speed claims.

### Warm Smoke

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --reps=1 --warmups=1 --out=/tmp/non-gaussian-gllvmtmb-smoke-warm-2026-06-01.csv
```

Warm median elapsed seconds:

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement status |
| --- | ---: | ---: | ---: | --- |
| Gaussian | 0.0002 | 0.4440 | 1921.85x | same data logLik comparable |
| Binomial | 0.0059 | 0.4450 | 75.67x | same data logLik comparable |
| Poisson | 0.0111 | 0.4400 | 39.56x | same data logLik comparable |
| NegBin | 0.0264 | 0.5780 | 21.90x | parameterization audit needed |
| Beta | 0.0768 | 0.5600 | 7.29x | parameterization audit needed |
| Gamma | 0.0165 | 0.4750 | 28.84x | parameterization audit needed |
| Ordinal | 0.0408 | 0.4960 | 12.17x | non-equivalent link |

Interpretation: the smoke cell confirms the warmed Julia fitters are materially
faster than R `gllvmTMB` locally, but it is not the full grid. Only
Gaussian/binomial/Poisson currently have same-data comparable log-likelihood
status in this harness; NegBin/Beta/Gamma still need parameterization parity
audit before strict likelihood claims, and ordinal remains a timing smoke
because the links differ.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-nongaussian-gllvmtmb-smoke-refresh.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean after finalizing this report.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only. This entry records a smoke benchmark with caveats,
  not a full-grid or public 100x claim.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Structured Poisson Lemma RHS Chunking

### Scope

Chunked the exact structured Poisson lemma-gradient site RHS matrices so the
trace block no longer materializes all `K * n` site-loading columns at once.
The internal chunk cap is 256 RHS columns. This preserves the exact Woodbury
route, keeps `logdet_method = :lemma` opt-in, and changes no public API.

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 165 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2379 pass, 3 broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2391 pass, 1 existing broken sparse-phy precision placeholder, 0 fail,
0 error. The `quality` testset passed 12/12, covering Aqua/JET in the full
package battery.

### Benchmark Evidence

Structured Poisson exact lemma-gradient benchmark with 256-column chunks:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-chunked.csv
```

Result:

```text
medium   p= 512 n= 128 K=2 dense=  0.0332 s lemma=  0.0311 s speedup= 1.07x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.21e-16
large    p=1024 n= 256 K=2 dense=  0.1847 s lemma=  0.1111 s speedup= 1.66x bytes=(3.86e+07, 6.89e+07) valuediff=0.00e+00 gradrel=1.71e-16
xlarge   p=2048 n= 512 K=2 dense=  0.8321 s lemma=  0.4542 s speedup= 1.83x bytes=(1.53e+08, 2.64e+08) valuediff=0.00e+00 gradrel=1.73e-16
```

Rejected 512-column chunk probe:

```text
medium   p= 512 n= 128 K=2 dense=  0.0327 s lemma=  0.0282 s speedup= 1.16x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.21e-16
large    p=1024 n= 256 K=2 dense=  0.1293 s lemma=  0.1050 s speedup= 1.23x bytes=(3.86e+07, 7.31e+07) valuediff=0.00e+00 gradrel=1.71e-16
xlarge   p=2048 n= 512 K=2 dense=  0.8257 s lemma=  0.4768 s speedup= 1.73x bytes=(1.53e+08, 2.72e+08) valuediff=0.00e+00 gradrel=1.73e-16
```

Interpretation: chunking trims the largest-cell lemma allocation
(`2.89e8` bytes before this memory slice after the triangular diagonal change,
`2.64e8` bytes with 256-column chunks) while preserving exact value/gradient
agreement and an xlarge speedup over dense. It is a memory-budget improvement,
not a default-policy change.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-rhs-chunking.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-rhs-chunking.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the pending/rerun guard patterns.
- Stale-wording scan: expected historical and command-pattern hits only; no
  public API/status claim changed by this internal memory cleanup.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only; no public 100x structured speed claim was added.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Woodbury Diagonal Triangular Correction

### Scope

Replaced the exact Woodbury inverse-diagonal correction
`diag(BinvC * H^-1 * BinvC')` with the equivalent triangular form
`sum(abs2, L \\ BinvC')`, where `H = L * L'`. This keeps the same exact
determinant-lemma path and changes no public API or fitter default.

The discarded CHOLMOD column-wise base-solve probe was slower than the current
matrix RHS solve:

```text
cholmod_batch p=512 n=128 K=2 current=0.002258 colwise=0.002681 speedup=0.84x bytes=(6.82e+06, 9.07e+06) err=6.94e-18
```

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 165 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2379 pass, 3 broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2391 pass, 1 existing broken sparse-phy precision placeholder, 0 fail,
0 error. The `quality` testset passed 12/12, covering Aqua/JET in the full
package battery.

### Benchmark Evidence

Woodbury inverse-diagonal helper microbenchmark, old SPD solve vs new
triangular correction:

```text
woodbury_diag_tri p=512 n=128 K=2 old=0.002649 new=0.000719 speedup=3.68x bytes=(1.13e+06, 1.65e+06) err=1.73e-18
woodbury_diag_tri p=1024 n=256 K=2 old=0.006510 new=0.003240 speedup=2.01x bytes=(4.35e+06, 6.45e+06) err=1.73e-18
woodbury_diag_tri p=2048 n=512 K=2 old=0.026719 new=0.014880 speedup=1.80x bytes=(1.71e+07, 2.55e+07) err=8.67e-19
```

Structured Poisson exact lemma-gradient benchmark after the diagonal change:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-tri-diag.csv
```

Result:

```text
medium   p= 512 n= 128 K=2 dense=  0.0351 s lemma=  0.0286 s speedup= 1.23x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.21e-16
large    p=1024 n= 256 K=2 dense=  0.1167 s lemma=  0.1092 s speedup= 1.07x bytes=(3.86e+07, 7.31e+07) valuediff=0.00e+00 gradrel=1.71e-16
xlarge   p=2048 n= 512 K=2 dense=  0.7969 s lemma=  0.4118 s speedup= 1.94x bytes=(1.53e+08, 2.89e+08) valuediff=0.00e+00 gradrel=1.73e-16
```

Interpretation: the helper diagonal correction is faster but allocates more in
isolation. The full lemma-gradient route remains exact and fastest in the
largest cell, but memory is still not good enough for a default-policy change.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-diag-triangular.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-diag-triangular.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the pending/rerun guard patterns.
- Stale-wording scan: expected historical and command-pattern hits only; no
  public API/status claim changed by this internal helper cleanup.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only; no public 100x structured speed claim was added.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Woodbury Apply Correction In-Place

### Scope

Removed one temporary correction matrix from `_schur_u_woodbury_inv_apply!` by
solving the small Woodbury correction system in-place in the existing RHS
buffer. This preserves the sparse CHOLMOD-safe base solve path and does not
change any public API or fitter default.

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 165 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: 2379 pass, 3 broken placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: 2391 pass, 1 existing broken sparse-phy precision placeholder, 0 fail,
0 error. The `quality` testset passed 12/12, covering Aqua/JET in the full
package battery.

### Benchmark Evidence

Dense-base helper microbenchmark comparing the previous correction allocation
against the in-place correction solve:

```text
dense_base_apply p=512 n=128 K=2 old=0.003497 new=0.003417 speedup=1.02x old_bytes=3145920 new_bytes=2621584 alloc_reduction=1.20x err=0.00e+00
```

Structured Poisson exact lemma-gradient benchmark after the helper change:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-correction-inplace.csv
```

Result:

```text
medium   p= 512 n= 128 K=2 dense=  0.0717 s lemma=  0.0458 s speedup= 1.57x bytes=(9.87e+06, 1.82e+07) valuediff=0.00e+00 gradrel=1.24e-16
large    p=1024 n= 256 K=2 dense=  0.1962 s lemma=  0.1227 s speedup= 1.60x bytes=(3.86e+07, 7.10e+07) valuediff=0.00e+00 gradrel=1.60e-16
xlarge   p=2048 n= 512 K=2 dense=  0.9555 s lemma=  0.5032 s speedup= 1.90x bytes=(1.53e+08, 2.80e+08) valuediff=0.00e+00 gradrel=1.72e-16
```

Interpretation: this is a small allocation cleanup, not a new algorithmic
breakthrough. It preserves exactness and trims memory in the lemma-gradient
route without weakening the existing speed evidence.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-apply-correction-inplace.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-woodbury-apply-correction-inplace.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun scan: clean for the pending/rerun guard patterns.
- Stale-wording scan: expected historical and command-pattern hits only; no
  public API/status claim changed by this internal helper cleanup.
- Performance-claim scan: expected existing Gaussian/gllvmTMB and internal
  benchmark-log hits only; no public 100x structured speed claim was added.
- GitHub lane check: open PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`; this slice did not edit that lane.

## 2026-06-01 - Private Provenance Historical Report Scrub

### Scope

Scrubbed a historical after-task report line that named private-provenance scan
terms. The report now records only a generic private-provenance guard pattern.
No source, tests, public API, or benchmark code changed.

### Checks

```sh
git diff --check
```

Result: clean.

Private-source trace scan over tracked public artifacts: no PDF/upload trace
matches in the current working tree. A broader private-provenance guard remains
in force; do not transcribe the guarded terms in public artifacts.

## 2026-06-01 - Structured Poisson Fitter Auto Logdet Default

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `95df912`.

### Scope

- Changed the private `_fit_structured_poisson_laplace` default from
  `logdet_method = :dense` to `logdet_method = :auto`, so the fitted structured
  Poisson prototype follows the shared exact-dense/SLQ cutoff by default.
- Extended `bench/structured_poisson_fit_bench.jl` with `--logdet=auto` as the
  default and a `--dense-cutoff=N` option; row-level CSV now records the cutoff.
- Added tests proving the default small-p auto path matches explicit dense and
  that forced `:auto` above the cutoff uses the SLQ/Lanczos route.
- Kept public APIs unchanged. No edits to `src/sparse_phy_grad.jl`,
  `src/em_phylo.jl`, or the PR #59 formula/family/CIs lane.

### Verification

Focused structured command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                     | 43/43 pass
structured Schur SLQ logdet                   | 18/18 pass
structured Poisson Laplace prototype          | 13/13 pass
structured Poisson implicit gradient          | 19/19 pass
structured Poisson internal fitter            | 28/28 pass
structured Poisson sigma-to-zero reduction    | 1/1 pass
```

Focused total: 122 pass, 0 fail, 0 error.

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2336 pass, 1 existing
broken sparse-phy precision placeholder, 2 expected direct-env quality
placeholders, 0 fail, 0 error.

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2348 pass, 1 existing broken sparse-phy
precision placeholder, quality 12/12 pass, 0 fail, 0 error.

CI/bootstrap status from both suite runs stayed green:

```text
confint                         | 14/14 pass
profile CI                      | 4/4 pass
parametric bootstrap CI         | 9/9 pass
derived-quantity CIs            | 45/45 pass
profile_ci_derived phylo cell   | 20/20 pass
```

### Benchmark Smoke Evidence

Default fitted benchmark now reports `logdet=auto` and the shared dense cutoff:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --reps=1 --warmups=1 --out=/tmp/structured-poisson-fit-auto-smoke.csv
```

Result:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=2048, trace_solve=auto
smoke   p=  5 n=  8 K=1 dense= 0.0005 s  cg= 0.0005 s  speedup= 1.08x  diff=5.26e-12 calls=(6,6)
```

Forced large-p route smoke (`dense_cutoff=0`) chooses the SLQ/Lanczos trace
path:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --nprobes=5 --lanczos-steps=5 --reps=1 --warmups=1 --out=/tmp/structured-poisson-fit-auto-forced-slq-smoke.csv
```

Result:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=0, trace_solve=auto
smoke   p=  5 n=  8 K=1 dense= 0.0010 s  cg= 0.0009 s  speedup= 1.04x  diff=2.97e-12 calls=(6,6)
```

CSV headers include the new `dense_cutoff` column, and the row-level
`trace_solve` column records `solve` for the default small-p route and
`lanczos` for the forced-SLQ route.

### Hygiene

- `git diff --check`: clean after the dev-log update.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun/fill-result scan over this check-log entry and the
  matching after-task report: clean.
- Stale-wording/performance scans: expected historical and command-pattern
  hits only; this slice adds no public R `gllvmTMB` comparison claim and no
  20x-100x claim.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; this slice does not modify it.

## 2026-06-01 - Structured Poisson Auto Dense Gradient

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `fecc69c`.

### Scope

- Routed `_structured_poisson_implicit_value_grad(...; logdet_method = :auto)`
  to the dense block implicit gradient when `p <= dense_cutoff`.
- Added regression coverage that checks the `:auto` value and gradient match
  the exact dense block path and that the tiny auto path stays below a generous
  allocation ceiling. The allocation guard catches the previous AD fallback.
- Kept the public API unchanged. No edits to `src/sparse_phy_grad.jl`,
  `src/em_phylo.jl`, or the PR #59 formula/family/CIs lane.

### Verification

Focused structured command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                     | 43/43 pass
structured Schur SLQ logdet                   | 18/18 pass
structured Poisson Laplace prototype          | 13/13 pass
structured Poisson implicit gradient          | 19/19 pass
structured Poisson internal fitter            | 23/23 pass
structured Poisson sigma-to-zero reduction    | 1/1 pass
```

Focused total: 117 pass, 0 fail, 0 error.

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2331 pass, 1 existing
broken sparse-phy precision placeholder, 2 expected direct-env quality
placeholders, 0 fail, 0 error.

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2343 pass, 1 existing broken sparse-phy
precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Benchmark And Allocation Probe

Fixed-seed warmed probe, `p = 8`, `n = 12`, `K = 2`, comparing the old direct
AD scaffold (`_structured_poisson_implicit_value_grad_ad`) to the routed
`logdet_method = :auto` path:

```text
p=8 n=12 K=2 old_ad_auto=0.000429 s fast_auto=8.762e-5 s speedup=4.896x valuediff=0.0 gradmax=1.11e-15
old_alloc_bytes=3936824 new_alloc_bytes=31168 allocation_reduction=126.3x
```

Interpretation: this is a narrow constant-factor route fix, not a new
asymptotic algorithm. It prevents small/medium `:auto` cells from paying the
old joint ForwardDiff implicit-gradient scaffold after the dense cutoff was
raised to `p <= 2048`.

### Hygiene

- `git diff --check`: clean after the dev-log update.
- Private-source trace scan over tracked public artifacts: clean.
- Placeholder rerun/fill-result scan over this check-log entry and the
  matching after-task report: clean.
- Stale-wording/performance scans: expected historical and command-pattern
  hits only; this slice adds no public R `gllvmTMB` comparison claim and no
  20x-100x claim.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; this slice does not modify it.

## 2026-05-31 — Dense-Laplace Mode Workspace For Scalar-Aux Fits

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `646d02b`.

### Scope

- Added an internal `_LaplaceModeWorkspace` for the Fisher-scoring mode finder
  to reuse `η`, `μ`, `dμ/dη`, score, weight, Hessian, RHS, and Newton-step
  buffers.
- Reused packed `β`, `Λ`, and scalar auxiliary views once per aggregate
  objective call instead of reconstructing them at every site.
- Enabled the workspace only for scalar-auxiliary Beta/Gamma paths. A broader
  canonical Poisson/Binomial workspace variant caused an isolated
  `fit_poisson_gllvm` convergence failure under `Pkg.test()`, so that path was
  deliberately backed out.
- Kept NegativeBinomial on the old BLAS-heavy mode solve because the workspace
  loop reduced allocations but slowed the medium NB fit.
- No public API changes. No edits to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`,
  or the PR #59 non-Gaussian CI / two-part lane.

### Verification

Gradient gate:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
```

All non-Gaussian recovery command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2214 pass, 3 broken
placeholders, 0 fail, 0 error.

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2226 pass, 1 existing broken sparse-phy
precision check, 0 fail, 0 error.

### Allocation Probes

Probe shape: `p = 30`, `n = 120`, `K = 2`; one warmed aggregate value/gradient
call measured with `@allocated`.

| family/path | before bytes | after bytes | allocation reduction |
| --- | ---: | ---: | ---: |
| Gamma scalar-aux | 8,650,448 | 1,974,224 | 4.38x |
| Beta scalar-aux | not recorded before this slice | 1,920,752 | reported as after-only |
| Negative-binomial scalar-aux | 6,145,616 | 6,020,016 | intentionally near unchanged |

### Benchmarks

Julia-only warmed medium-cell benchmark:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=negbin,beta,gamma --iterations=120 --warmups=2 --reps=3 --julia-only
```

| family | p | n | K | median seconds | convergence |
| --- | ---: | ---: | ---: | ---: | --- |
| negbin | 30 | 500 | 2 | 0.8786 | 3/3 |
| beta | 30 | 500 | 2 | 2.2930 | 3/3 |
| gamma | 30 | 500 | 2 | 1.1868 | 3/3 |

For comparison with immediately prior logged medians on this branch:
negative-binomial remains near the previous `0.8803s`; Beta improves from the
previous logged `2.5687s`; Gamma improves from the previous logged `1.5403s`.

### Hygiene

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Gamma Scalar-Aux Implicit Fitter

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `f3564b1`.

### Scope

- Added closed-form Gamma log-link scalar-auxiliary observation derivatives for
  the dense-Laplace implicit-gradient helper: log density, score, expected
  weight, and derivatives with respect to `η` and `log α`.
- Switched `fit_gamma_gllvm` from `Optim` ForwardDiff over the dense Laplace
  objective to the existing scalar-auxiliary implicit-gradient route.
- Kept the public API unchanged and did not widen tolerances.
- Tested a cache-backed Gamma variant and rejected it because it slowed the
  medium benchmark cell; the committed path is the simpler stateless implicit
  gradient.
- Did not edit `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or the open
  non-Gaussian CI / two-part PR lane.

### Verification

Gradient gate:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
```

Targeted Gamma recovery:

```sh
julia --project=. --startup-file=no -e 'include("test/test_gamma_fit.jl")'
```

Result:

```text
fit_gamma_gllvm | 7/7 pass
```

All non-Gaussian recovery command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2214 pass, 3 broken
placeholders, 0 fail, 0 error. The touched blocks included:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
fit_gamma_gllvm                                      | 7/7 pass
post-fit Gamma fits                                  | 215/215 pass
quality                                              | 2 broken placeholders
```

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2226 pass, 1 existing broken sparse-phy
precision check, 0 fail, 0 error.

### Benchmarks

Julia-only warmed Gamma benchmark, same command before and after the change:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small,medium --families=gamma --iterations=120 --warmups=1 --reps=1 --julia-only
```

| cell | p | n | K | before Julia (s) | after Julia (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 10 | 100 | 1 | 0.0884 | 0.0723 | 1.22x |
| medium | 30 | 500 | 2 | 18.7340 | 1.5403 | 12.16x |

R comparator smoke:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small,medium --families=gamma --iterations=120 --warmups=1 --reps=1
```

| cell | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| small | 0.0723 | 0.5260 | 7.28x | same_data_parameterization_audit_needed |
| medium | 1.5403 | 3.5810 | 2.32x | same_data_parameterization_audit_needed |

The R rows are timing evidence only until the Gamma parameterisation audit is
closed; the likelihood values differ by more than the comparable Gaussian /
Binomial / Poisson rows and are therefore not used as a strict parity claim.

### CI Status

The interval layer was not changed in this slice. The current full suite passed
the existing Wald, profile-likelihood, parametric-bootstrap, and derived-CI
tests. The broader non-Gaussian CI catch-up remains in PR #59's lane.

### Hygiene

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Beta Cache-Then-Polish Fitter

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `9a731e3`.

### Scope

- Updated `fit_beta_gllvm` to run a cache-backed scalar-auxiliary dense-Laplace
  pass first, then use the existing stateless value/gradient as a final polish
  whenever the cached pass does not satisfy Optim's convergence criteria.
- The final `BetaFit.converged` flag is still based on the stateless polish when
  polishing is needed; the cache is used only to get close quickly.
- No public API changes.
- Did not edit `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or the open
  non-Gaussian CI PR lane.

### Verification

Targeted command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_beta_fit.jl")'
```

Result:

```text
fit_beta_gllvm | 7/7 pass
```

All non-Gaussian recovery command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted summaries: 2214 pass, 3 broken
placeholders, 0 fail, 0 error. The touched blocks included:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
fit_beta_gllvm                                        | 7/7 pass
post-fit Beta fits                                    | 215/215 pass
```

Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2226 pass, 1 existing broken sparse-phy
precision check, 0 fail, 0 error.

### Benchmarks

Julia-only warmed Beta benchmark, medium cell:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=beta --iterations=120 --warmups=1 --reps=3 --julia-only
```

| family | p | n | K | before median (s) | after median (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| beta | 30 | 500 | 2 | 2.9037 | 2.5687 | 1.13x |

Julia-only warmed Beta benchmark, small cell:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small --families=beta --iterations=80 --warmups=3 --reps=5 --julia-only
```

| family | p | n | K | before median (s) | after median (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| beta | 10 | 100 | 1 | 0.0524 | 0.0362 | 1.45x |

The larger 100x target still needs a workspace-based site-mode implementation
or a structured sparse/operator Laplace path; cache-then-polish is a safe
constant-factor improvement, not the final algorithm.

### Hygiene

- `git diff --check`: clean.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Scalar-Aux Analytic Derivatives

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `8165059`.

### Scope

- Replaced per-observation ForwardDiff Jacobians in the scalar-auxiliary
  dense-Laplace gradient with analytic derivatives for the production
  Negative Binomial log-link (`log r`) and Beta logit-link (`log φ`) paths.
- Replaced the corresponding NB/Beta per-observation `logpdf(...)`
  distribution-object calls with closed-form `loggamma` log densities.
- Added an in-place Laplace mode helper and a cache-backed scalar-auxiliary
  value/gradient helper for benchmark/future fitter experiments.
- Left NB/Beta production fitters on the stateless scalar-auxiliary gradient:
  the cache-backed helper is faster but the NB recovery fixture can lose the
  Optim convergence flag through line-search behaviour.
- Public model APIs are unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Confidence-Interval Lane Check

- Current branch already has Gaussian Wald/profile/bootstrap and derived CI
  tests passing.
- Non-Gaussian CIs are not part of this speed slice. Open draft PR #59
  (`claude/package-work-catchup-mQiZM`) owns Delta-Gamma / ZIP-ZINB /
  non-Gaussian CI work, so this branch avoids those files.

### Gradient And Recovery Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
```

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2214 pass, 3 broken placeholders, 0 fail, 0 error. The broken entries are the
existing sparse-phy precision check plus the direct-run Aqua/JET placeholders
that are exercised by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
post-fit NB fits                                      | 160/160 pass
post-fit Beta fits                                    | 215/215 pass
Hurdle-Poisson                                        | 166/166 pass
Hurdle-NB                                             | 15/15 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2226 pass, 1 existing broken
sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Production scalar-auxiliary value/gradient kernel, p = 80, n = 400, K = 3,
24 reps:

| family | median (s) | min (s) | mean allocations |
| --- | ---: | ---: | ---: |
| negative-binomial | 0.0180 | 0.0173 | 43.9 MB |
| beta | 0.0429 | 0.0417 | 44.0 MB |

Compared with the earlier generic-observation-AD scalar-aux path in this same
branch, the production kernel is now about 2.5x faster for NB and 1.7x faster
for Beta on this cell.

Cache-backed scalar-auxiliary helper, same cell:

| family | median (s) | mean allocations | verdict |
| --- | ---: | ---: | --- |
| negative-binomial | 0.0134 | 21.1 MB | verified as value/gradient-equivalent, not production-wired |
| beta | 0.0296 | 21.1 MB | verified as value/gradient-equivalent, not production-wired |

R comparator smoke, small cell only, warmed with 3 warmup fits and 3 measured
reps:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small --families=negbin,beta --iterations=80 --warmups=3 --reps=3
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| negative-binomial | 0.0488 | 1.1510 | 23.58x | same_data_parameterization_audit_needed |
| beta | 0.0524 | 0.9980 | 19.04x | same_data_parameterization_audit_needed |

The earlier zero-warmup smoke included Julia compilation cost and is not a
per-fit engine comparison. Strict likelihood interpretation still needs the
NB/Beta parameterisation audit.

Medium warmed smoke, one warmup and one measured repetition:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=medium --families=negbin,beta --iterations=120 --warmups=1 --reps=1
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| negative-binomial | 0.8803 | 27.7240 | 31.49x | same_data_parameterization_audit_needed |
| beta | 2.9037 | 10.3560 | 3.57x | same_data_parameterization_audit_needed |

Medium Beta is now the named scalar-aux bottleneck; NB is comfortably ahead
against the R comparator on the warmed small and medium cells.

### Hygiene

- `git diff --check`: clean.
- `rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md -g '!docs/node_modules/**'`:
  existing `AGENTS.md` status snapshot hit only; not edited.
- Sensitive-provenance guard scan over public repo artifacts: clean.

## 2026-05-31 — Structured Fast-Algorithm Scout

Branch: `codex/non-gaussian-fitter-gradients`

Head after rebase onto `origin/main`: `f442b78`.

### Scope

- Rebased the local non-Gaussian gradient branch onto current `origin/main`,
  which now includes the structured-dependence design spec.
- Added a public-source-only strategy memo:
  `docs/dev-log/2026-05-31-structured-fast-algorithm-scout.md`.
- The memo synthesizes two scout passes and ranks the 100x path as sparse
  precision / node-frame / operator-based structured Laplace, with warm mode
  reuse, profiling, Kronecker/SPDE/Vecchia extensions, and determinant tiers.
- No `src/` files were edited.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Verification

- Core command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. The direct core run retained the expected direct-run
quality placeholders because Aqua/JET are loaded by `Pkg.test()`. Key
post-rebase touched blocks included:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 74/74 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
Hurdle-Poisson                                        | 166/166 pass
Hurdle-NB                                             | 15/15 pass
```

- Full command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  8.8s
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks after the rebase: 2208 pass,
1 existing broken sparse-phy precision check, 0 fail, 0 error.
- Benchmarks: not run; the memo records existing benchmark evidence from the
  canonical-gradient slice and labels 100x structured speedups as unproven
  targets.
- Provenance: public citations only; no non-public source path or metadata was
  added.

## 2026-05-31 — Canonical And Scalar-Aux Non-Gaussian Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `e1a971f`.

### Implementation Checks

- Added hand-coded implicit dense-Laplace gradients for canonical Poisson-log
  and Binomial-logit objectives.
- Added per-fitter latent-mode caches for the canonical Binomial and Poisson
  paths; non-canonical Binomial links still use the generic implicit fallback.
- Added a scalar-auxiliary implicit gradient for one dispersion-like parameter
  after `[β; vec(Λ)]`; wired Negative Binomial (`log r`) and Beta (`log φ`) to
  it.
- Left Gamma on direct ForwardDiff for fitting; its scalar-auxiliary helper is
  tested but not production-wired until mode convergence is hardened.
- Added `--cells=` to `bench/non_gaussian_gllvmtmb_bench.jl` so small/medium
  benchmark cells can run without entering the long large R cell.
- Kept public model APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: AD/implicit gradients |   74     74  26.3s
```

The test now checks direct ForwardDiff-through-objective, generic implicit
gradients, canonical hand-coded gradients, cached canonical gradients, and
scalar-auxiliary gradients against central finite differences or the stateless
canonical reference.

### Targeted Recovery Tests

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl"); include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl")'
```

Result:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 62/62 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
```

The standalone gradient test was then rerun after adding the cache-equivalence
checks and passed 74/74.

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. The direct core environment reported only the expected
quality-tool placeholders because Aqua/JET are loaded by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 74/74 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
post-fit residuals                                    | 10/10 pass
structured_cov                                        | 31/31 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  8.6s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1806 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Poisson finite-difference baseline vs canonical hand-coded gradient:

| p | n | K | params | finite-diff gradient (s) | canonical gradient (s) | speedup |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 100 | 1 | 20 | 0.0154 | 0.0004 | 35.4x |
| 30 | 200 | 2 | 89 | 0.2693 | 0.0017 | 160.7x |

Generic implicit gradient vs fast hand-coded / scalar-auxiliary gradient:

| family | p | n | K | params | generic implicit (s) | fast gradient (s) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| binomial | 80 | 400 | 3 | 317 | 0.4542 | 0.0064 | 70.8x |
| poisson | 80 | 400 | 3 | 317 | 0.3374 | 0.0057 | 58.8x |
| negative-binomial | 80 | 400 | 3 | 318 | 0.4073 | 0.0379 | 10.7x |
| beta | 80 | 400 | 3 | 318 | 0.7635 | 0.0642 | 11.9x |

R-vs-Julia full-grid subset command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=small,medium --families=binomial,poisson --iterations=80 --warmups=1 --reps=1
```

| cell | family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | --- | ---: | ---: | ---: | --- |
| small | binomial | 0.0235 | 0.5040 | 21.5x | same_data_loglik_comparable |
| small | poisson | 0.0189 | 0.5060 | 26.8x | same_data_loglik_comparable |
| medium | binomial | 0.2590 | 2.0170 | 7.8x | same_data_loglik_comparable |
| medium | poisson | 0.4000 | 3.8250 | 9.6x | same_data_loglik_comparable |

Large-cell command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --cells=large --families=binomial,poisson --iterations=80 --warmups=0 --reps=1
```

| cell | family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status | note |
| --- | --- | ---: | ---: | ---: | --- | --- |
| large | binomial | 5.9188 | 64.1420 | 10.8x | same_data_loglik_comparable | Julia converged |
| large | poisson | 5.7804 | 147.9730 | 25.6x | same_data_loglik_comparable | Julia hit 80-iteration cap but matched logLik |

## 2026-05-31 — Non-Gaussian Implicit Dense-Laplace Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: rebased on `origin/main` at `7e4c64b`, with previous
ForwardDiff slice at `6481e95`.

### Implementation Checks

- Added an implicit dense-Laplace value/gradient helper for scalar families.
- Added an ordinal implicit-gradient helper for the cumulative-logit mode
  equation.
- Switched Binomial, Poisson, Negative Binomial, Beta, and Ordinal fitters to
  `Optim.only_fg!` with explicit objective/gradient callbacks.
- Kept Gamma on direct ForwardDiff through the dense Laplace objective after a
  post-fit fixture exposed non-converged Gamma site modes where the implicit
  mode-equation assumption is not yet reliable.
- Kept public APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: AD/implicit gradients |   42     42  25.4s
```

The test now checks both direct ForwardDiff-through-objective and the implicit
gradient against central finite differences for all six non-Gaussian families.
Gamma's implicit helper is verified on the stable small objective, but the Gamma
fitter still uses direct ForwardDiff pending mode convergence hardening.

### Targeted Recovery Tests

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_binomial_fit.jl"); include("test/test_poisson_fit.jl"); include("test/test_nb_fit.jl"); include("test/test_beta_fit.jl"); include("test/test_gamma_fit.jl"); include("test/test_ordinal_fit.jl")'
```

Result:

```text
fit_binomial_gllvm — recovery | 8/8 pass
fit_poisson_gllvm — recovery  | 7/7 pass
fit_nb_gllvm — recovery       | 7/7 pass
fit_beta_gllvm                | 7/7 pass
fit_gamma_gllvm               | 7/7 pass
fit_ordinal_gllvm             | 9/9 pass
```

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. The direct core environment again reported the expected
quality-tool placeholders as broken because Aqua/JET are loaded only by
`Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: AD/implicit gradients | 42/42 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
post-fit residuals                                    | 10/10 pass
structured_cov                                        | 31/31 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  9.5s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1774 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Poisson gradient-evaluation benchmark:

| p | n | K | params | ForwardDiff-through-Newton (s) | implicit (s) | speedup |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 | 60 | 1 | 10 | 0.0003 | 0.0004 | 0.72x |
| 10 | 100 | 1 | 20 | 0.0021 | 0.0015 | 1.42x |
| 30 | 200 | 2 | 89 | 0.1733 | 0.0197 | 8.80x |

R-vs-Julia warmed smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --iterations=80 --reps=1 --warmups=1
```

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0002 | 0.4690 | 1898.8x | same_data_loglik_comparable |
| binomial | 0.0180 | 0.4990 | 27.7x | same_data_loglik_comparable |
| poisson | 0.0182 | 0.4910 | 27.0x | same_data_loglik_comparable |
| negative-binomial | 0.0300 | 0.6540 | 21.8x | same_data_parameterization_audit_needed |
| beta | 0.0317 | 0.6040 | 19.0x | same_data_parameterization_audit_needed |
| gamma | 0.0405 | 0.5000 | 12.3x | same_data_parameterization_audit_needed |
| ordinal | 0.0463 | 0.5200 | 11.2x | non_equivalent_link |

Representative Poisson full-grid attempt:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --full --families=poisson --iterations=80 --warmups=1 --reps=1
```

Result: stopped after several minutes because the large R cell exceeded the
interactive budget. No CSV was written.

## 2026-05-31 — Non-Gaussian ForwardDiff Fitter Gradients

Branch: `codex/non-gaussian-fitter-gradients`

Head before local commit: `a9a860f`

### Implementation Checks

- Switched `fit_binomial_gllvm`, `fit_poisson_gllvm`, `fit_nb_gllvm`,
  `fit_beta_gllvm`, `fit_gamma_gllvm`, and `fit_ordinal_gllvm` from
  `autodiff = :finite` to `autodiff = :forward`.
- Made dense Laplace accumulators and ordinal scratch arrays element-type
  generic so ForwardDiff Dual values survive the inner Fisher-scoring path.
- Kept public APIs unchanged.
- Did not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Gradient Verification

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_family_forwarddiff_gradients.jl")'
```

Result:

```text
Test Summary:                                         | Pass  Total   Time
non-Gaussian fitter objectives: ForwardDiff gradients |   18     18  14.5s
```

The test compares `ForwardDiff.gradient` to a central finite-difference
gradient for the packed objective of each non-Gaussian fitter. Gate: max
absolute difference ≤ 1e-6.

Observed one-off maxima before adding the test:

| family | maximum absolute gradient difference |
| --- | ---: |
| binomial | 5.857e-9 |
| poisson | 1.029e-8 |
| negative-binomial | 6.298e-9 |
| beta | 2.943e-9 |
| gamma | 5.118e-9 |
| ordinal | 2.646e-9 |

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Functional tests passed; the direct core environment
reported the expected quality-tool placeholders as broken because Aqua/JET are
loaded only by `Pkg.test()`.

Key touched blocks:

```text
non-Gaussian fitter objectives: ForwardDiff gradients | 18/18 pass
fit_binomial_gllvm — recovery                         | 8/8 pass
fit_poisson_gllvm — recovery                          | 7/7 pass
fit_nb_gllvm — recovery                               | 7/7 pass
fit_beta_gllvm                                        | 7/7 pass
fit_gamma_gllvm                                       | 7/7 pass
fit_ordinal_gllvm                                     | 9/9 pass
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       |   12     12  12.0s
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 1750 pass, 1 existing
broken sparse-phy precision check, 0 fail, 0 error.

### Benchmarks

Julia version: 1.10.0.
R comparator: R 4.5.2, `gllvmTMB` 0.2.0.

Fixed-iteration Julia before/after smoke, p = 5, n = 60, K = 1,
6 L-BFGS iterations, `g_tol = 0.0`. The finite-difference numbers were recorded
immediately before the code change on the same branch; the ForwardDiff numbers
were recorded immediately after.

| family | finite diff (s) | ForwardDiff (s) | speedup |
| --- | ---: | ---: | ---: |
| binomial | 0.0916 | 0.0049 | 18.7x |
| poisson | 0.0696 | 0.0052 | 13.4x |
| negative-binomial | 0.0808 | 0.0093 | 8.7x |
| beta | 0.0896 | 0.0148 | 6.1x |
| gamma | 0.0926 | 0.0131 | 7.1x |
| ordinal | 0.0514 | 0.0105 | 4.9x |

R-vs-Julia warmed smoke command:

```sh
julia --project=. --startup-file=no bench/non_gaussian_gllvmtmb_bench.jl --smoke --iterations=80 --reps=1 --warmups=1
```

Cell: p = 5, n = 60, K = 1.

| family | Julia (s) | gllvmTMB (s) | R / Julia | agreement_status |
| --- | ---: | ---: | ---: | --- |
| gaussian | 0.0003 | 0.5120 | 1640.6x | same_data_loglik_comparable |
| binomial | 0.0142 | 0.5150 | 36.2x | same_data_loglik_comparable |
| poisson | 0.0339 | 0.5060 | 14.9x | same_data_loglik_comparable |
| negative-binomial | 0.0195 | 0.6400 | 32.9x | same_data_parameterization_audit_needed |
| beta | 0.0331 | 0.6100 | 18.4x | same_data_parameterization_audit_needed |
| gamma | 0.0219 | 0.5070 | 23.1x | same_data_parameterization_audit_needed |
| ordinal | 0.1083 | 0.5570 | 5.1x | non_equivalent_link |

Log-likelihood spot checks on comparable smoke rows:

| family | Julia logLik | gllvmTMB logLik | absolute difference |
| --- | ---: | ---: | ---: |
| gaussian | -328.9497618208953 | -328.949761826271 | 5.38e-9 |
| binomial | -199.02063720298568 | -199.020637206598 | 3.61e-9 |
| poisson | -557.3922590332276 | -557.392259036326 | 3.10e-9 |

The full small/medium/large grid is implemented in
`bench/non_gaussian_gllvmtmb_bench.jl` but was not run in this slice.

### Quality And Audit Scans

Commands:

```sh
rg -n "autodiff\\s*=\\s*:finite|Finite-difference gradient|finite-difference gradient" src/families test bench README.md docs/src CLAUDE.md AGENTS.md
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md AGENTS.md
<private-source trace scan over tracked repo content>
```

Results:

- No remaining `autodiff = :finite` or obsolete finite-difference fitter
  wording under `src/families`.
- No private-source trace in tracked repo content.
- `AGENTS.md` still contains the user-provided stale "Gaussian only" snapshot;
  not edited because AGENTS edits require maintainer approval under that file's
  own rules.
- Allocs.jl was not run: `Package Allocs not found in current path`.

Open PR / collision check:

```text
gh pr list --limit 10 --json number,title,headRefName,updatedAt
[]
```

## 2026-05-31 — Structured Schur/SLQ Substrate

### Scope

Added the first internal substrate for the large-`p` non-Gaussian structured
dependence path: a Schur-complement operator for the latent structured response
block plus deterministic stochastic-Lanczos quadrature (SLQ) log-determinant
estimation over supplied probes. The substrate also includes an internal
determinant selector that uses exact dense `logdet` for small `p` and frozen-probe
SLQ for large `p`. This is not yet wired into public fitters.

The implemented operator applies

```text
S_u x = σ⁻² Qx + (sum_s w_s) .* x
        - sum_s D_s Λ (I + Λ' D_s Λ)⁻¹ Λ' D_s x
```

where `D_s = diag(w_s)`. Sparse precision matrices are preserved rather than
densified, and the internal dense-reference / SLQ paths reuse multiply scratch.

### Targeted Tests

Command:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

Result:

```text
structured Schur operator | 22/22 pass
structured Schur SLQ logdet | 9/9 pass
```

The tests cover dense and sparse precision storage, `mul!` agreement with the
independent dense Schur matrix, SPD checks, malformed dimensions / boundary
`sigma2`, exact-basis SLQ agreement with dense `logdet`, deterministic
repeatability with frozen Rademacher probes, dense/SLQ selector branches, and
invalid selector inputs.

### Core Suite

Command:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from the emitted `Test Summary` blocks:
2257 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Key touched blocks:

```text
structured Schur operator     | 22/22 pass
structured Schur SLQ logdet   | 9/9 pass
quality                       | 2 broken placeholders
```

### Full Package Suite

Command:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
structured Schur operator     | 22/22 pass
structured Schur SLQ logdet   | 9/9 pass
quality                       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from the emitted `Test Summary` blocks: 2257 pass, 1 existing
broken sparse-phy precision placeholder, 0 fail, 0 error.

### Allocation / Timing Smoke

Command:

```sh
julia --project=. --startup-file=no -e 'using GLLVM, Random, LinearAlgebra, SparseArrays; p=80; n=12; K=2; Random.seed!(804); Λ=0.2 .* randn(p,K); W=0.1 .+ rand(p,n); main=fill(2.2,p); off=fill(-0.4,p-1); Q=spdiagm(-1=>off,0=>main,1=>off); op=GLLVM._SchurUOperator(Symmetric(Q), Λ, W; sigma2=1.1); probes=GLLVM._rademacher_probes(MersenneTwister(805), p, 8); GLLVM._slq_logdet(op, probes; lanczos_steps=20); bytes=@allocated GLLVM._slq_logdet(op, probes; lanczos_steps=20); t=@elapsed GLLVM._slq_logdet(op, probes; lanczos_steps=20); println("slq_p80_n12_K2_steps20_probes8 elapsed=", t, " allocated=", bytes)'
```

Result:

```text
slq_p80_n12_K2_steps20_probes8 elapsed=0.001644 allocated=103552
```

This is a smoke number for the new substrate, not a before/after fitter
speedup. The next meaningful benchmark is dense `logdet(S_u)` vs sparse/SLQ
inside the structured non-Gaussian Laplace objective.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds existing Gaussian / benchmark wording only; no
  new user-facing speed claim was added.

Open PR / collision check:

```text
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 - Structured Schur Auto Dense Cutoff

### Scope

Raised the internal structured Schur automatic dense/SLQ cutoff from `256` to
`2048` after direct dense assembly made exact dense logdet faster than
frozen-probe SLQ through the new break-even grid. This changes only internal
structured non-Gaussian prototype defaults: `logdet_method=:auto` now keeps the
exact dense path for `p <= 2048`, and only falls to SLQ above that cutoff.

### Implementation Notes

- Added `_STRUCTURED_SCHUR_DENSE_CUTOFF = 2048` in `src/structured_schur.jl`.
- `_schur_u_logdet(...; method=:auto)` now uses that constant by default.
- Structured Poisson prototype helpers and `_fit_structured_poisson_laplace`
  now share the same cutoff default instead of carrying local `256` literals.
- `bench/structured_schur_logdet_bench.jl` now has `--break-even` mode with
  cells up to `p=2048`.
- `bench/README.md` documents the break-even command.
- Added a regression test where `p=257` must still choose exact dense under
  the default `:auto` path.
- Lane check: branch was `codex/non-gaussian-fitter-gradients` at `2f96967`
  before this slice. Open PR #59 remains the separate draft formula/family/CIs
  catch-up lane. This slice did not edit `src/sparse_phy_grad.jl` or
  `src/em_phylo.jl`.

### Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 43/43 pass
structured Schur SLQ logdet                  | 18/18 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 15/15 pass
structured Poisson internal fitter           | 23/23 pass
structured Poisson sigma-to-zero reduction   |  1/1 pass
```

Focused total: 113 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2327 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2339 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Benchmarks

Ad hoc larger-cell probe before editing the cutoff:

| p | n | K | dense exact (s) | SLQ (s) | dense / SLQ | relerr |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 640 | 160 | 3 | 0.0610 | 0.5669 | 0.108x | 5.441e-04 |
| 1024 | 256 | 3 | 0.0697 | 1.4366 | 0.048x | 8.351e-05 |
| 1280 | 320 | 3 | 0.1105 | 2.2370 | 0.049x | 4.740e-05 |
| 2048 | 512 | 3 | 0.4463 | 5.7495 | 0.078x | 3.135e-04 |

Reproducible benchmark command after adding `--break-even`:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --reps=1 --warmups=1
```

Result:

| cell | p | n | K | dense exact (s) | SLQ (s) | dense / SLQ | relerr |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| frontier | 640 | 160 | 3 | 0.0258 | 0.5663 | 0.05x | 1.292e-03 |
| giant | 1024 | 256 | 3 | 0.0769 | 1.4375 | 0.05x | 1.845e-04 |
| huge | 1280 | 320 | 3 | 0.0899 | 2.2793 | 0.04x | 2.640e-04 |
| xlarge | 2048 | 512 | 3 | 0.4604 | 5.7120 | 0.08x | 3.157e-05 |

Interpretation: exact dense remains both faster and exact through `p=2048` on
this structured benchmark grid. SLQ remains the future large-p path, but the
break-even is above the previous `256` cutoff.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-auto-cutoff.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-auto-cutoff.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked repo content: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders remain after
  this update.
- Stale-wording scan: expected hits only - the user-provided AGENTS.md
  "Gaussian only" snapshot, historical check-log command/result records, and
  this scan command.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal speed records, benchmark-script column names, and
  this slice's internal structured Schur cutoff evidence. This slice adds no R
  `gllvmTMB` parity claim and no public 20x-100x structured speedup claim.
- GitHub lane check: open PR #59 is still the separate draft
  formula/family/CIs catch-up lane; no issue or PR was modified.

### Open Risks

- The dense/SLQ break-even is still above, not identified exactly. The next
  dedicated run should probe `p > 2048` with `--skip-dense` fallbacks ready.
- Dense remains exact but memory-bound at sufficiently large `p`; the SLQ path
  still matters for the eventual very-large structured dependence lane.
- This is internal Julia structured evidence, not an R `gllvmTMB` comparison.

## 2026-06-01 - Structured Schur Direct Dense Assembly

### Scope

Replaced `_schur_u_dense` construction by basis-vector matvecs with direct
assembly of the exact Schur matrix:
`S_u = Q / sigma2 + Diagonal(Wsum) - sum_i B_i A_i^{-1} B_i'`, where
`B_i = Diagonal(W_i) Lambda`. This keeps the same exact dense determinant path
but moves the dense construction onto small BLAS-3 updates. A sparse
`Symmetric(SparseMatrixCSC)` precision copy path avoids p-squared sparse
lookups before the low-rank site updates.

This is an internal structured algorithm speed slice, not a public API change.
It does not edit `src/sparse_phy_grad.jl` or `src/em_phylo.jl`, and open PR #59
remains the separate formula/family catch-up lane.

### Implementation Notes

- `_schur_u_dense` now allocates two `p x K` workspaces and calls
  `_schur_u_dense_direct!`.
- `_schur_u_dense_direct!` copies/scales the structured precision, adds the
  diagonal site-weight sum, then subtracts `B_i A_i^{-1} B_i'` per site.
- `_copy_scaled_precision!` has a sparse-Symmetric specialization for banded or
  tree precision inputs.
- The public internal `_schur_u_dense!` scratch-argument method is preserved for
  tests/callers, but delegates to the direct assembler after dimension checks.

### Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 112 pass, 0 fail, 0 error. The additional check covers
`Symmetric(sparse(...), :L)` precision storage for the new sparse copy path.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2326 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2338 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Benchmarks

Direct in-process median timer comparing the previous basis-vector dense
assembly against the new direct assembly on the same `_SchurUOperator`:

| p | n | K | old basis-vector dense (s) | direct dense (s) | old / direct | max abs diff |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 80 | 80 | 2 | 0.00369 | 0.00014 | 26.45x | 4.44e-16 |
| 160 | 120 | 2 | 0.02183 | 0.00091 | 24.07x | 1.42e-14 |
| 320 | 160 | 2 | 0.11519 | 0.00468 | 24.61x | 1.42e-14 |
| 320 | 160 | 3 | 0.14154 | 0.00547 | 25.87x | 6.66e-16 |

Structured Schur logdet benchmark:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --reps=3 --warmups=3 --nprobes=16 --lanczos-steps=40
```

Result:

| cell | p | n | K | dense exact (s) | SLQ (s) | dense / SLQ | relerr |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 80 | 20 | 2 | 0.0002 | 0.0095 | 0.02x | 2.119e-03 |
| medium | 160 | 40 | 2 | 0.0008 | 0.0319 | 0.03x | 7.706e-04 |
| large | 320 | 80 | 3 | 0.0035 | 0.1469 | 0.02x | 5.466e-04 |
| frontier | 640 | 160 | 3 | 0.0186 | 0.5673 | 0.03x | 1.449e-04 |

Interpretation: for these current benchmark cells, exact dense is now much
faster than the frozen-probe SLQ approximation. The scalable determinant lane
therefore needs larger-p break-even evidence, not an assumption that SLQ wins
at p <= 640.

Structured Poisson trace-gradient benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --reps=3 --warmups=3 --nprobes=4 --lanczos-steps=20
```

Before this direct assembler, same command at commit `c021e07`:

| cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| large | 320 | 160 | 2 | 0.1652 | 0.0647 | 2.55x | 6.15e-01 | 1.41e-01 |
| frontier | 640 | 160 | 2 | 0.5805 | 0.1283 | 4.53x | 2.46e+00 | 3.18e-01 |

After this direct assembler:

| cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| large | 320 | 160 | 2 | 0.0462 | 0.0657 | 0.70x | 6.15e-01 | 1.41e-01 |
| frontier | 640 | 160 | 2 | 0.1220 | 0.1336 | 0.91x | 2.46e+00 | 3.18e-01 |

The exact dense trace-gradient comparison improved by about 3.6x on `large`
and 4.8x on `frontier`, changing the local default recommendation: exact dense
is competitive or faster at these sizes, while stochastic SLQ still carries the
fixed-probe approximation error shown above.

Fitted dense-logdet calibration:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=dense --reps=3 --warmups=3 --iterations=10
```

Result:

| cell | p | n | K | dense mode (s) | CG mode (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| small | 5 | 8 | 1 | 0.0009 | 0.0009 | 1.07x | 9.95e-14 | (12,12) |
| medium | 8 | 12 | 2 | 0.0017 | 0.0020 | 0.88x | 4.15e-12 | (13,13) |
| large | 20 | 25 | 2 | 0.0051 | 0.0079 | 0.65x | 9.09e-13 | (13,13) |

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-dense-assembly.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-dense-assembly.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked repo content: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders remain after
  this update.
- Stale-wording scan: expected hits only - the user-provided AGENTS.md
  "Gaussian only" snapshot, historical check-log command/result records, and
  this scan command.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal speed records, benchmark-script column names, and
  this slice's internal structured Schur/Poisson benchmark evidence. This slice
  adds no R `gllvmTMB` parity claim and no public 20x-100x structured speedup
  claim.
- GitHub lane check: open PR #59 is still the separate draft
  formula/family/CIs catch-up lane; no issue or PR was modified.

### Open Risks

- Exact dense assembly is still paired with dense Cholesky for `logdet(S_u)`;
  the very-large-p break-even against SLQ remains a separate benchmark question.
- The direct assembler allocates two `p x K` workspaces per dense construction;
  a future workspace-threaded variant can remove those allocations if they show
  up in Allocs/JET work.
- This is internal Julia evidence, not an R `gllvmTMB` comparison.

## 2026-06-01 - Structured Poisson Mode Cached Inverse Reuse

### Scope

Extended the cached site-inverse optimization into the structured Poisson
inner mode solver. `_SchurUOperator` already stores each site-level
`A_i^{-1}`; the Newton/Fisher mode updates now use those cached inverses for
the `U` Schur RHS elimination and for each site-level `ΔZ_i` update, instead
of re-solving the same tiny Cholesky systems. The dense block-gradient and SLQ
trace-gradient paths also read `op.Ainvs[i]` directly instead of copying the
matrix into a scratch buffer before read-only use.

### Implementation Notes

- In `_structured_poisson_mode`, replaced `copyto!` + `ldiv!(op.Achols[i], ...)`
  with `mul!(..., op.Ainvs[i], ...)` for both RHS elimination and `ΔZ`.
- In `_structured_poisson_block_implicit_value_grad` and
  `_structured_poisson_trace_implicit_value_grad`, removed the per-site copy of
  `A_i^{-1}` and use the cached matrix directly as read-only data.
- Scratch probe rejected: caching `W_iΛ` was tested and backed out because a
  direct Schur matvec comparison was neutral (`1.00x`, `1.02x`, `0.96x` across
  the tested cells).
- Lane check: branch was `codex/non-gaussian-fitter-gradients` at `84769c2`
  before this slice. Open PR #59 remains the separate draft formula/family
  catch-up lane. This slice did not edit `src/sparse_phy_grad.jl` or
  `src/em_phylo.jl`.

### Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 42/42 pass
structured Schur SLQ logdet                  | 17/17 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 15/15 pass
structured Poisson internal fitter           | 23/23 pass
structured Poisson sigma-to-zero reduction   |  1/1 pass
```

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2325 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2337 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Benchmarks

Before this slice, fitted SLQ auto default:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=3 --warmups=3 --iterations=10
```

Result:

| state | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| before | small | 5 | 8 | 1 | 0.0030 | 0.0038 | 0.81x | 5.83e-12 | (37,48) |
| before | medium | 8 | 12 | 2 | 0.0042 | 0.0042 | 1.01x | 3.41e-12 | (15,15) |
| before | large | 20 | 25 | 2 | 0.0272 | 0.0229 | 1.19x | 5.12e-12 | (14,14) |

After this slice, same command:

| state | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| after | small | 5 | 8 | 1 | 0.0032 | 0.0035 | 0.92x | 5.90e-12 | (41,48) |
| after | medium | 8 | 12 | 2 | 0.0042 | 0.0039 | 1.09x | 3.41e-12 | (15,15) |
| after | large | 20 | 25 | 2 | 0.0264 | 0.0220 | 1.20x | 4.89e-12 | (14,14) |

CG fitted-path before/after ratios from this calibrated grid were about 1.09x,
1.08x, and 1.04x for small, medium, and large respectively. The change is small
but positive on the fitted CG path, where mode solves are repeatedly reused by
the optimizer.

Before trace-gradient benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --reps=3 --warmups=3 --nprobes=4 --lanczos-steps=20
```

Result:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | large | 320 | 160 | 2 | 0.1629 | 0.0657 | 2.48x | 6.15e-01 | 1.41e-01 |
| before | frontier | 640 | 160 | 2 | 0.5802 | 0.1281 | 4.53x | 2.46e+00 | 3.18e-01 |

After trace-gradient benchmark, same command:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| after | large | 320 | 160 | 2 | 0.1652 | 0.0647 | 2.55x | 6.15e-01 | 1.41e-01 |
| after | frontier | 640 | 160 | 2 | 0.5805 | 0.1283 | 4.53x | 2.46e+00 | 3.18e-01 |

SLQ trace-gradient time was effectively neutral: about 1.02x on `large` and
flat on `frontier`, with unchanged fixed-probe approximation error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over tracked repo content: no matches.
- Stale-wording scan: expected hits only - the user-provided AGENTS.md
  "Gaussian only" snapshot, historical check-log command/result records, and
  this scan command.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal structured benchmark records, benchmark-script
  column names, and this slice's internal fitted-path benchmark evidence. This
  slice adds no R `gllvmTMB` parity claim and no public 20x-100x structured
  speedup claim.

### Open Risks

- This is a small fitted-mode constant-factor improvement, not a new
  determinant algorithm or R comparison result.
- Larger fitted structured cells may show a different balance between mode
  solve, trace-gradient work, and optimizer line-search noise.
- The rejected `W_iΛ` cache suggests not every obvious Schur algebra cache pays
  off; keep direct kernel benchmarks in the loop.

## 2026-06-01 - Structured Schur Cached Site Inverses

### Scope

Cached the tiny site-level inverses `A_i^{-1}` inside the internal
`_SchurUOperator` workspace. The structured Poisson mode, trace-gradient,
block-gradient, and joint-solve paths already pay to factor each
`A_i = I + Λ'W_iΛ`; this slice also materializes the corresponding inverse once
per operator build and reuses it in repeated Schur matvecs and adjoint solves.
This is an internal fast-algorithm constant-factor slice, not a public API
change.

### Implementation Notes

- `_SchurUOperator` now carries `Ainvs::Vector{Matrix{T}}` beside `Achols`.
- `_SchurUOperatorWorkspace` owns reusable `Ainvs` buffers and checks their
  shape alongside `Amats`.
- `_schur_u_mul!` now uses `mul!(sol, A_i^{-1}, tmp)` instead of solving the
  tiny Cholesky system on every matvec.
- `_structured_poisson_joint_solve`, `_structured_poisson_block_implicit_value_grad`,
  and `_structured_poisson_trace_implicit_value_grad` reuse `op.Ainvs[i]`
  instead of repeatedly solving identity or vector right-hand sides.
- Lane check: branch was `codex/non-gaussian-fitter-gradients` at `aa252aa`
  before this slice. Open PR #59 remains the separate draft formula/family
  catch-up lane. This slice did not edit `src/sparse_phy_grad.jl` or
  `src/em_phylo.jl`.

### Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 42/42 pass
structured Schur SLQ logdet                  | 17/17 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 15/15 pass
structured Poisson internal fitter           | 23/23 pass
structured Poisson sigma-to-zero reduction   |  1/1 pass
```

The new operator checks compare each cached `A_i^{-1}` against an explicit
site-level inverse and verify workspace identity reuse.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2325 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2337 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Benchmarks

Before the cached-inverse change, fitted SLQ auto default:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=3 --warmups=3 --iterations=10
```

Result:

| state | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| before | small | 5 | 8 | 1 | 0.0063 | 0.0057 | 1.09x | 5.87e-12 | (54,48) |
| before | medium | 8 | 12 | 2 | 0.0067 | 0.0063 | 1.06x | 3.41e-12 | (15,15) |
| before | large | 20 | 25 | 2 | 0.0393 | 0.0317 | 1.24x | 5.34e-12 | (14,14) |

After the cached-inverse change, same command:

| state | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| after | small | 5 | 8 | 1 | 0.0030 | 0.0039 | 0.77x | 5.83e-12 | (37,48) |
| after | medium | 8 | 12 | 2 | 0.0045 | 0.0042 | 1.09x | 3.41e-12 | (15,15) |
| after | large | 20 | 25 | 2 | 0.0268 | 0.0225 | 1.19x | 5.12e-12 | (14,14) |

CG fitted-path before/after ratios from this calibrated grid were about 1.46x,
1.50x, and 1.41x for small, medium, and large respectively. Dense timings also
shifted because the dense-mode gradient and joint solve reuse the cached
site inverses, but the tiny-cell ratios are noisy.

Before trace-gradient benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --cells=large,frontier --trace-solve=lanczos --reps=3 --warmups=3 --nprobes=4 --lanczos-steps=20
```

Result:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| before | large | 320 | 160 | 2 | 0.1616 | 0.0676 | 2.39x | 6.15e-01 | 1.41e-01 |
| before | frontier | 640 | 160 | 2 | 0.5584 | 0.1337 | 4.18x | 2.46e+00 | 3.18e-01 |

After trace-gradient benchmark, same command:

| state | cell | p | n | K | dense (s) | SLQ (s) | dense / SLQ | value diff | grad rel |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| after | large | 320 | 160 | 2 | 0.1593 | 0.0651 | 2.45x | 6.15e-01 | 1.41e-01 |
| after | frontier | 640 | 160 | 2 | 0.5268 | 0.1311 | 4.02x | 2.46e+00 | 3.18e-01 |

SLQ trace-gradient time moved modestly, about 1.04x on `large` and 1.02x on
`frontier`, while preserving the fixed-probe approximation error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over `README.md`, `docs/src`, `docs/dev-log`,
  `bench`, `src`, `test`, `CLAUDE.md`, and `AGENTS.md`: no matches.
- Stale-wording scan: expected hits only - the AGENTS.md "Gaussian only"
  snapshot, historical check-log command/result records, and the newly recorded
  scan command itself. This slice adds no new public status claim.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal benchmark records, benchmark-script column names,
  and this new internal structured Schur fitted/trace benchmark evidence. This
  slice does not add an R `gllvmTMB` parity or public speed claim.

### Open Risks

- Caching `A_i^{-1}` adds small operator-construction work and memory, so this
  is a repeated-matvec win rather than a universal tiny-cell win.
- The trace-gradient frontier cell is effectively neutral in wall-clock ratio;
  the useful gain is clearer in the fitted CG path.
- This is internal Julia structured-Poisson evidence, not an R `gllvmTMB`
  comparison.

## 2026-06-01 - Structured Poisson Auto Fused SLQ Fitted Path

### Scope

Promoted the private fixed-covariance structured Poisson fitter to
`trace_solve=:auto`. For fitted SLQ log-determinant runs, `:auto` now selects
the fused Lanczos inverse-probe path added in the previous slice; dense
log-determinant runs keep the older explicit solve path. The benchmark script
now records the effective trace-solve path in CSV output. This is an internal
prototype/fitted-benchmark change, not a public API change.

### Implementation Notes

- `_fit_structured_poisson_laplace` accepts `trace_solve=:auto|:solve|:lanczos`
  and stores the effective choice in the returned fit object.
- `:auto` maps to `:lanczos` when `logdet_method=:slq`, or when
  `logdet_method=:auto` would use the large-p SLQ path; otherwise it maps to
  `:solve`.
- `bench/structured_poisson_fit_bench.jl` defaults to `--trace-solve=auto`,
  writes a `trace_solve` CSV column, and records the effective fitted value.
- Lane check: branch was `codex/non-gaussian-fitter-gradients` at `2901ca8`
  before this slice, with open PR #59 still on
  `claude/package-work-catchup-mQiZM` for Delta-Gamma, ZIP/ZINB, and
  non-Gaussian CIs. This slice did not touch that lane and did not edit
  `src/sparse_phy_grad.jl` or `src/em_phylo.jl`.

### Tests

Focused structured Poisson test:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 15/15 pass
structured Poisson internal fitter           | 23/23 pass
structured Poisson sigma-to-zero reduction   |  1/1 pass
```

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2319 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2331 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Benchmarks

Fitted SLQ grid with explicit solve trace path:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=solve --reps=1 --warmups=1 --iterations=6
```

Result:

| trace solve | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| solve | small | 5 | 8 | 1 | 0.0018 | 0.0021 | 0.88x | 5.68e-14 | (8,8) |
| solve | medium | 8 | 12 | 2 | 0.0046 | 0.0111 | 0.42x | 4.55e-13 | (9,9) |
| solve | large | 20 | 25 | 2 | 0.0299 | 0.0302 | 0.99x | 2.39e-12 | (10,10) |

Fitted SLQ grid with the new auto default:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --logdet=slq --trace-solve=auto --reps=1 --warmups=1 --iterations=6
```

Result:

| trace solve | cell | p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| auto -> lanczos | small | 5 | 8 | 1 | 0.0018 | 0.0017 | 1.06x | 5.68e-14 | (8,8) |
| auto -> lanczos | medium | 8 | 12 | 2 | 0.0043 | 0.0041 | 1.04x | 4.26e-13 | (9,9) |
| auto -> lanczos | large | 20 | 25 | 2 | 0.0275 | 0.0226 | 1.22x | 2.61e-12 | (10,10) |

For the CG fitted path on this tiny calibrated grid, `:auto` improved measured
CG time over `:solve` by about 1.24x, 2.71x, and 1.34x for the small, medium,
and large cells respectively, with the same objective-call counts and
sub-`1e-11` likelihood agreement against the corresponding dense-mode fit.

Larger single-cell probe, `p=80`, `n=80`, `K=2`, `iterations=4`,
`nprobes=4`, `lanczos_steps=20`, same fixed data/probes:

```text
p=80 n=80 K=2 solve time=0.2508 effective=solve loglik=-9860.455381 calls=(8,5)
p=80 n=80 K=2 auto  time=0.1987 effective=lanczos loglik=-9860.455381 calls=(8,5) speedup=1.26x diff=1.819e-11
```

CSV smoke path:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=slq --trace-solve=auto --reps=1 --warmups=1 --iterations=4 --out=/tmp/structured-poisson-fit-auto-smoke.csv
head -2 /tmp/structured-poisson-fit-auto-smoke.csv
```

Result: CSV file written with the expected `trace_solve` header, and the smoke
row recorded the effective value `lanczos`.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- Private-source trace scan over `README.md`, `docs/src`, `docs/dev-log`,
  `bench`, `src`, `test`, `CLAUDE.md`, and `AGENTS.md`: no matches.
- Stale-wording scan: expected hits only - the AGENTS.md "Gaussian only"
  snapshot, historical check-log command/result records, and the newly recorded
  scan command itself. This slice adds no new public status claim.
- Performance-claim scan: expected hits only - existing Gaussian/gllvmTMB
  claims, historical internal benchmark records, benchmark-script column names,
  and this new internal structured Poisson fitted-benchmark evidence. This
  slice does not add an R `gllvmTMB` parity or public speed claim.

### Open Risks

- This is still a private fixed-covariance structured Poisson prototype, not a
  public structured non-Gaussian API.
- The benchmark cells are deliberately small calibration cells plus one larger
  probe. Wider stochastic-probe and covariance-shape sweeps remain needed
  before making public speed claims.
- R `gllvmTMB` parity is N/A for this internal fitted path; the separate
  comparison repo remains the place for public R-vs-Julia timing claims.

## 2026-06-01 — Structured Poisson Orthogonal Probe Control

### Implemented Claim

Added a scaled orthogonal Gaussian probe generator for the internal structured
Schur SLQ workbench and exposed it in
`bench/structured_poisson_trace_gradient_bench.jl` via
`--probe-kind=orthogonal`. This is an optional probe-strategy control for
accuracy studies, not a new default and not a public fitted-model claim.

### Collision And Lane Checks

```sh
git status --short --branch
git branch --show-current
git rev-parse --short HEAD
gh pr list --limit 10 --state open
gh run list --limit 3
```

Result:

```text
## codex/non-gaussian-fitter-gradients...origin/main [ahead 20]
M bench/structured_poisson_trace_gradient_bench.jl
M src/structured_schur.jl
M test/test_structured_schur.jl
?? .claude/
branch: codex/non-gaussian-fitter-gradients
head: 8ab244d
open PR: #59 draft, claude/package-work-catchup-mQiZM
latest runs: pages success; PR #59 Documenter success; PR #59 CI failure
```

No edits were made to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or PR #59
files. `.claude/` remains untracked and untouched.

### Focused Tests

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

Result:

```text
structured Schur operator     | 36/36 pass
structured Schur SLQ logdet   | 14/14 pass
```

The new tests check the orthogonal probe shape, scaled Gram matrix
`P'P = pI`, SLQ compatibility, and the malformed `nprobes > p` failure path.

### Benchmarks

Smoke paths:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --probe-kind=rademacher
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --probe-kind=orthogonal
```

Result:

```text
rademacher smoke: dense=0.0098 s, slq=0.0121 s, speedup=0.81x, valuediff=1.36e-01, gradrel=6.79e-02
orthogonal smoke: dense=0.0851 s, slq=0.0149 s, speedup=5.73x, valuediff=2.12e-01, gradrel=6.44e-02
```

Large/frontier comparison with `nprobes=4`, `lanczos_steps=20`,
`reps=1`, `warmups=2`:

| probe kind | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| rademacher | large | 320 | 160 | 0.1973 | 0.0837 | 2.36x | 6.15e-01 | 1.41e-01 |
| rademacher | frontier | 640 | 160 | 0.5337 | 0.1672 | 3.19x | 2.46e+00 | 3.18e-01 |
| orthogonal | large | 320 | 160 | 0.1815 | 0.0848 | 2.14x | 7.40e-01 | 1.49e-01 |
| orthogonal | frontier | 640 | 160 | 0.5460 | 0.1708 | 3.20x | 2.72e+00 | 3.34e-01 |

Higher-probe large-cell comparison with `nprobes=16`, `lanczos_steps=20`,
`reps=1`, `warmups=2`:

| probe kind | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| rademacher | large | 320 | 160 | 0.1591 | 0.2320 | 0.69x | 7.08e-01 | 6.98e-02 |
| orthogonal | large | 320 | 160 | 0.1582 | 0.2314 | 0.68x | 2.12e-01 | 6.61e-02 |

Interpretation: orthogonal probes are a useful benchmark control and may reduce
noise at higher probe budgets, but the live evidence does not justify making
them the default.

### Test Suites

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2308 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2320 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean after code and documentation edits.
- Private-source trace scan: no matches in tracked repo content.
- Stale-wording scan is expected to find the user-provided AGENTS.md
  "Gaussian only" snapshot and historical check-log entries; this slice adds no
  new stale public claim.
- Performance-claim scan is expected to find existing Gaussian/gllvmTMB claims
  and historical internal structured benchmark records. This new section labels
  the orthogonal-probe result as optional internal evidence only.

Open PR / collision check:

```text
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson Fused SLQ Trace Solve

### Implemented Claim

Added an internal fused SLQ helper that reuses each Lanczos basis for both the
`logdet(S_u)` estimate and the inverse-probe approximation `S_u^{-1}R` in the
structured Poisson trace-gradient path. The new path is opt-in via
`trace_solve = :lanczos`; the default remains the previous explicit solve path.
This is an internal speed slice, not a public API change and not an R
`gllvmTMB` parity claim.

### Collision And Lane Checks

```sh
git status --short --branch
git rev-parse --short HEAD
gh pr list --limit 10 --state open
```

Result:

```text
## codex/non-gaussian-fitter-gradients...origin/main [ahead 21]
M bench/README.md
M bench/structured_poisson_trace_gradient_bench.jl
M src/families/structured_poisson.jl
M src/structured_schur.jl
M test/test_structured_poisson_laplace.jl
M test/test_structured_schur.jl
?? .claude/
head before commit: 3226d79
open PR: #59 draft, claude/package-work-catchup-mQiZM
```

No edits were made to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or PR #59
files. `.claude/` remains untracked and untouched.

### Focused Tests

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 17/17 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 15/15 pass
structured Poisson internal fitter           | 19/19 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

The new exact-reference checks use a full scaled identity probe basis and
`lanczos_steps = p`: the fused inverse-probe helper must match `S_u \ R`, and
the structured Poisson fused trace-gradient must match the dense/block gradient
to the existing `1e-6` tolerance.

### Benchmarks

Smoke and CSV path:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --trace-solve=lanczos --out=/tmp/structured-poisson-trace-fused-smoke.csv
head -2 /tmp/structured-poisson-trace-fused-smoke.csv
```

Result:

```text
Structured Poisson trace-gradient benchmark (smoke); reps=1, warmups=2, probe_kind=rademacher, nprobes=4, steps=20, trace_solve=lanczos
smoke    p=  80 n=  80 K=2 dense=  0.0100 s  slq=  0.0102 s  speedup= 0.97x  valuediff=1.36e-01  gradrel=6.79e-02
CSV header includes trace_solve.
```

Large/frontier comparison with `nprobes=4`, `lanczos_steps=20`,
`reps=1`, `warmups=2`:

| trace solve | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| solve | large | 320 | 160 | 0.1599 | 0.0873 | 1.83x | 6.15e-01 | 1.41e-01 |
| solve | frontier | 640 | 160 | 0.5523 | 0.1719 | 3.21x | 2.46e+00 | 3.18e-01 |
| lanczos | large | 320 | 160 | 0.1785 | 0.0700 | 2.55x | 6.15e-01 | 1.41e-01 |
| lanczos | frontier | 640 | 160 | 0.5628 | 0.1341 | 4.20x | 2.46e+00 | 3.18e-01 |

Frontier comparison with `nprobes=8`, `lanczos_steps=20`, `reps=1`,
`warmups=2`:

| trace solve | cell | p | n | dense (s) | SLQ (s) | dense / SLQ | value diff | gradient relative error |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| solve | frontier | 640 | 160 | 0.5606 | 0.2729 | 2.05x | 1.55e-01 | 1.36e-01 |
| lanczos | frontier | 640 | 160 | 0.5937 | 0.1970 | 3.01x | 1.55e-01 | 1.36e-01 |

Interpretation: fused Lanczos removes the separate trace-probe solve cost while
preserving the same frozen-probe value and gradient approximation. On the
frontier cell it cut SLQ trace-gradient time by about 22% with four probes and
about 28% with eight probes.

### Test Suites

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2315 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2327 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean after code and documentation edits.
- Private-source trace scan: no matches in tracked repo content.
- Stale-wording scan is expected to find the user-provided AGENTS.md
  "Gaussian only" snapshot and historical check-log entries; this slice adds no
  new stale public claim.
- Performance-claim scan is expected to find existing Gaussian/gllvmTMB claims
  and historical internal structured benchmark records. This new section labels
  the fused-Lanczos result as internal structured Poisson trace-gradient
  evidence only.

Open PR / collision check:

```text
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson Trace-Gradient Benchmark And Workspace Reuse

### Implemented Claim

Added a dedicated benchmark for the structured Poisson dense-vs-SLQ
trace-gradient crossover, and removed one per-site `K×K` matrix allocation from
both dense block and SLQ trace gradient loops by reusing the site inverse
workspace. This is an internal performance/evidence slice, not a public API
change and not an R `gllvmTMB` parity claim.

### Collision And Lane Checks

```sh
git status --short --branch && git rev-parse --short HEAD
gh pr list --limit 20
git log --all --oneline --since='6 hours ago' --decorate
```

Result:

```text
## codex/non-gaussian-fitter-gradients...origin/main [ahead 19]
?? .claude/
c453962

59 gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs claude/package-work-catchup-mQiZM DRAFT
```

No edits were made to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or PR #59
files. `.claude/` remains untracked and untouched.

### Focused Tests

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Poisson Laplace prototype      | 13/13 pass
structured Poisson implicit gradient      | 12/12 pass
structured Poisson internal fitter        | 18/18 pass
structured Poisson sigma-to-zero reduction| 1/1 pass
```

### Benchmarks

Allocation/timing spot check for one SLQ trace-gradient evaluation:

```text
baseline slq p=160 n=120 K=2 time=0.03400 bytes=869920 value=-28793.6191
after    slq p=160 n=120 K=2 time=0.03400 bytes=858496 value=-28793.6191
```

Interpretation: the workspace reuse is a small allocation cleanup, not a major
time speedup by itself.

New trace-gradient benchmark smoke + CSV:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --smoke --out=/tmp/structured-poisson-trace-gradient-smoke.csv
head -2 /tmp/structured-poisson-trace-gradient-smoke.csv
```

Result:

```text
Structured Poisson trace-gradient benchmark (smoke); reps=1, warmups=2, nprobes=4, steps=20
smoke    p=  80 n=  80 K=2 dense=  0.0090 s  slq=  0.0121 s  speedup= 0.74x  valuediff=1.36e-01  gradrel=6.79e-02
Wrote /tmp/structured-poisson-trace-gradient-smoke.csv
```

CSV header and first row were written as expected.

Full trace-gradient benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --full --reps=1 --warmups=2
```

Result:

```text
Structured Poisson trace-gradient benchmark (full); reps=1, warmups=2, nprobes=4, steps=20
small    p=  80 n=  80 K=2 dense=  0.0098 s  slq=  0.0121 s  speedup= 0.81x  valuediff=1.36e-01  gradrel=6.79e-02
medium   p= 160 n= 120 K=2 dense=  0.0379 s  slq=  0.0358 s  speedup= 1.06x  valuediff=4.18e-01  gradrel=7.70e-02
large    p= 320 n= 160 K=2 dense=  0.1583 s  slq=  0.0855 s  speedup= 1.85x  valuediff=3.99e-01  gradrel=1.07e-01
frontier p= 640 n= 160 K=2 dense=  0.5423 s  slq=  0.1730 s  speedup= 3.13x  valuediff=7.84e-01  gradrel=1.62e-01
```

Fitted SLQ smoke still runs:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --gradient=implicit --logdet=slq --nprobes=4 --lanczos-steps=20 --reps=1 --warmups=1
```

Result:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=slq
smoke   p=  5 n=  8 K=1 dense= 0.0014 s  cg= 0.0016 s  speedup= 0.91x  diff=1.42e-13 calls=(6,6)
```

### Test Suites

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2303 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2315 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-upload trace scan: no matches.
- Stale-wording scan: still finds the user-provided AGENTS.md "Gaussian only"
  snapshot and historical check-log entries; no new stale public claim was
  introduced.
- Performance-claim scan: existing Gaussian/gllvmTMB speedup claims and
  historical internal structured speed records. The new benchmark labels the
  result as internal structured Poisson trace-gradient scaling evidence.

Open PR / collision check:

```text
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson SLQ Trace Gradient

### Implemented Claim

Added a frozen-probe stochastic trace-gradient path for the internal structured
Poisson fitter when `logdet_method = :slq` (or `:auto` above the dense cutoff).
With a scaled identity probe basis and full Lanczos steps, the SLQ path recovers
the dense block gradient to the existing `1e-6` gradient tolerance; with
Rademacher probes it gives the first fitted large-p determinant-gradient
prototype that avoids dense `S_u^{-1}` materialization.

This is still an internal fixed-covariance structured Poisson path, not a public
API change and not an R `gllvmTMB` parity claim.

### Collision And Lane Checks

```sh
git status --short --branch && git rev-parse --short HEAD
gh pr list --limit 20
git log --all --oneline --since='6 hours ago' --decorate
```

Result:

```text
## codex/non-gaussian-fitter-gradients...origin/main [ahead 18]
?? .claude/
40e8994

59 gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs claude/package-work-catchup-mQiZM DRAFT
```

No edits were made to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or PR #59
files. `.claude/` remains untracked and untouched.

### Tests Added

Extended `structured Poisson implicit gradient` so that `logdet_method = :slq`
with the full scaled identity probe basis must match the dense block value and
gradient under both dense and CG Schur solves. This checks the trace-gradient
formula against the exact dense-gradient reference before using stochastic
probes for speed.

### Focused Tests

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                 | 36/36 pass
structured Schur SLQ logdet               | 9/9 pass
structured Poisson Laplace prototype      | 13/13 pass
structured Poisson implicit gradient      | 12/12 pass
structured Poisson internal fitter        | 18/18 pass
structured Poisson sigma-to-zero reduction| 1/1 pass
```

### Benchmarks

Fitted benchmark, dense determinant, implicit block gradient:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit --logdet=dense
```

Result:

```text
Structured Poisson fitted benchmark (full); reps=3, warmups=1, iterations=6, gradient=implicit, logdet=dense
small   p=  5 n=  8 K=1 dense= 0.0011 s  cg= 0.0010 s  speedup= 1.06x  diff=9.66e-13 calls=(8,8)
medium  p=  8 n= 12 K=2 dense= 0.0025 s  cg= 0.0022 s  speedup= 1.10x  diff=2.90e-12 calls=(9,9)
large   p= 20 n= 25 K=2 dense= 0.0140 s  cg= 0.0101 s  speedup= 1.39x  diff=3.98e-12 calls=(9,9)
```

Fitted benchmark, frozen-probe SLQ determinant, implicit trace gradient:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit --logdet=slq --nprobes=4 --lanczos-steps=20
```

Result:

```text
Structured Poisson fitted benchmark (full); reps=3, warmups=1, iterations=6, gradient=implicit, logdet=slq
small   p=  5 n=  8 K=1 dense= 0.0018 s  cg= 0.0022 s  speedup= 0.83x  diff=5.68e-14 calls=(8,8)
medium  p=  8 n= 12 K=2 dense= 0.0047 s  cg= 0.0057 s  speedup= 0.82x  diff=4.55e-13 calls=(9,9)
large   p= 20 n= 25 K=2 dense= 0.0309 s  cg= 0.0313 s  speedup= 0.99x  diff=2.39e-12 calls=(10,10)
```

Fitted benchmark, frozen-probe SLQ determinant, finite-difference comparator
(`reps=1` to keep the comparator cheap):

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=finite --logdet=slq --nprobes=4 --lanczos-steps=20 --reps=1
```

Result:

```text
Structured Poisson fitted benchmark (full); reps=1, warmups=1, iterations=6, gradient=finite, logdet=slq
small   p=  5 n=  8 K=1 dense= 0.0123 s  cg= 0.0116 s  speedup= 1.06x  diff=1.34e-09 calls=(8,8)
medium  p=  8 n= 12 K=2 dense= 0.0625 s  cg= 0.0577 s  speedup= 1.08x  diff=7.03e-08 calls=(9,9)
large   p= 20 n= 25 K=2 dense= 0.9753 s  cg= 0.8171 s  speedup= 1.19x  diff=2.16e-07 calls=(9,9)
```

SLQ finite-difference to SLQ trace-gradient speedup:

| cell | path | finite SLQ (s) | trace SLQ (s) | speedup | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: |
| small | dense mode | 0.0123 | 0.0018 | 6.83x | 1.34e-09 |
| small | CG mode | 0.0116 | 0.0022 | 5.27x | 1.34e-09 |
| medium | dense mode | 0.0625 | 0.0047 | 13.30x | 7.03e-08 |
| medium | CG mode | 0.0577 | 0.0057 | 10.12x | 7.03e-08 |
| large | dense mode | 0.9753 | 0.0309 | 31.56x | 2.16e-07 |
| large | CG mode | 0.8171 | 0.0313 | 26.11x | 2.16e-07 |

Single gradient-evaluation scaling, CG mode with 4 frozen probes:

```text
p=80 n=80 K=2 logdet=dense seconds=0.0094 value=-9667.157 gradnorm=75.3885
p=80 n=80 K=2 logdet=slq seconds=0.0126 value=-9666.929 gradnorm=76.1265
p=160 n=120 K=2 logdet=dense seconds=0.0386 value=-29138.3849 gradnorm=121.0937
p=160 n=120 K=2 logdet=slq seconds=0.036 value=-29138.4019 gradnorm=121.7038
p=320 n=160 K=2 logdet=dense seconds=0.1658 value=-77897.3181 gradnorm=168.0861
p=320 n=160 K=2 logdet=slq seconds=0.1119 value=-77897.7654 gradnorm=171.9908
p=640 n=160 K=2 logdet=dense seconds=0.5749 value=-152429.9588 gradnorm=210.2985
p=640 n=160 K=2 logdet=slq seconds=0.1794 value=-152430.463 gradnorm=214.683
```

Interpretation: SLQ is slower than exact dense on very small fitted cells, but
it begins to overtake exact dense gradient evaluation at `p≈160` and is about
3.2x faster at `p=640` with 4 probes. This is a determinant-gradient substrate,
not a final public large-p claim.

### Test Suites

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2303 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2315 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-upload trace scan: no matches.
- Stale-wording scan: still finds the user-provided AGENTS.md "Gaussian only"
  snapshot and historical check-log entries; no new stale public claim was
  introduced.
- Performance-claim scan: existing Gaussian/gllvmTMB speedup claims and
  historical internal structured speed records. The new claim is explicitly
  internal to the fixed-covariance structured Poisson SLQ trace-gradient
  prototype.

Open PR / collision check:

```text
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson Schur Adjoint And Block Gradient

### Implemented Claim

Replaced the dense-logdet structured Poisson fitted-gradient path with an
exact block implicit gradient. The mode equations are still solved with the
existing structured Schur operator, but the gradient no longer materializes the
full joint `ForwardDiff.jacobian` over `[U; Z; θ]` for `logdet_method = :dense`.
The non-dense determinant path keeps the previous ForwardDiff fallback.

This is an internal fixed-covariance structured Poisson prototype, not a public
API change and not an R `gllvmTMB` parity claim.

### Collision And Lane Checks

```sh
git status --short --branch && git rev-parse --short HEAD
gh pr list --limit 20
git log --all --oneline --since='6 hours ago' --decorate
```

Result:

```text
## codex/non-gaussian-fitter-gradients...origin/main [ahead 17]
 M src/families/structured_poisson.jl
?? .claude/
9d4e6ef

59 gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs claude/package-work-catchup-mQiZM DRAFT
```

No edits were made to `src/sparse_phy_grad.jl`, `src/em_phylo.jl`, or PR #59
files. `.claude/` remains untracked and untouched.

### Tests Added

Added a structured Poisson implicit-gradient check comparing the new block
Schur adjoint against the old dense `Fx' \ qx` adjoint, for both dense and CG
Schur solves, on the existing `p=4, n=3, K=1` fixture.

### Focused Tests

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                 | 36/36 pass
structured Schur SLQ logdet               | 9/9 pass
structured Poisson Laplace prototype      | 13/13 pass
structured Poisson implicit gradient      | 6/6 pass
structured Poisson internal fitter        | 18/18 pass
structured Poisson sigma-to-zero reduction| 1/1 pass
```

### Benchmarks

Full fitted grid, implicit block gradient:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit
```

Result:

```text
Structured Poisson fitted benchmark (full); reps=3, warmups=1, iterations=6, gradient=implicit
small   p=  5 n=  8 K=1 dense= 0.0011 s  cg= 0.0010 s  speedup= 1.07x  diff=9.66e-13 calls=(8,8)
medium  p=  8 n= 12 K=2 dense= 0.0025 s  cg= 0.0029 s  speedup= 0.87x  diff=2.90e-12 calls=(9,9)
```

Full fitted grid, finite-difference comparator:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=finite
```

Result:

```text
Structured Poisson fitted benchmark (full); reps=3, warmups=1, iterations=6, gradient=finite
small   p=  5 n=  8 K=1 dense= 0.0068 s  cg= 0.0063 s  speedup= 1.08x  diff=1.02e-09 calls=(8,8)
medium  p=  8 n= 12 K=2 dense= 0.0330 s  cg= 0.0281 s  speedup= 1.17x  diff=4.71e-08 calls=(9,9)
```

Finite-difference to block-gradient speedup:

| cell | path | finite (s) | block implicit (s) | speedup | abs loglik diff |
| --- | --- | ---: | ---: | ---: | ---: |
| small | dense | 0.0068 | 0.0011 | 6.18x | 1.02e-09 |
| small | cg | 0.0063 | 0.0010 | 6.30x | 1.02e-09 |
| medium | dense | 0.0330 | 0.0025 | 13.20x | 4.71e-08 |
| medium | cg | 0.0281 | 0.0029 | 9.69x | 4.71e-08 |

Exploratory larger CG cells:

```text
p=12 n=16 K=2 cg finite=0.0702 implicit=0.0038 speedup=18.51 diff=6.469241498052725e-8 calls=(9,9)
p=20 n=25 K=2 cg finite=0.2972 implicit=0.0098 speedup=30.48 diff=1.8724563233263325e-8 calls=(9,9)
```

Interpretation: this is the first structured non-Gaussian fitted path where
the speedup grows with problem size because the gradient no longer scales with
a full joint AD Jacobian. It is still exact dense-logdet work; the next
large-p jump needs the structured leverage / trace path for SLQ rather than
dense `S_u^{-1}`.

### Test Suites

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2297 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2309 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|gllvmTMB" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
```

Results:

- `git diff --check`: clean.
- Private-upload trace scan: no matches.
- Stale-wording scan: still finds the user-provided AGENTS.md "Gaussian only"
  snapshot and historical check-log entries; no new stale public claim was
  introduced.
- Performance-claim scan: existing Gaussian/gllvmTMB speedup claims and
  historical internal structured speed records. The new claim is explicitly
  internal to the fixed-covariance structured Poisson prototype.

Open PR / collision check:

```text
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson Implicit Fitted Gradient

### Scope

Added a private implicit value/gradient helper for the fixed-covariance
structured Poisson Laplace objective. The helper builds the joint random-effect
mode equation for `u` and all site-level `z` values, applies the
implicit-function adjoint, and makes the private fitted helper default to
`gradient=:implicit`. The old Optim finite-difference path remains available
with `gradient=:finite`.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson implicit gradient         | 4/4 pass
structured Poisson internal fitter           | 18/18 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Gradient verification:

```text
structured implicit gradient max abs diff vs central finite difference: 2.32e-09
threshold: 1e-6
```

Structured Poisson fitted benchmark, finite-difference gradient:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=finite --out=/tmp/structured-poisson-fit-implicit-slice-finite-full.csv
```

Result:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0069 | 0.0060 | 1.15x | 1.02e-09 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0334 | 0.0278 | 1.20x | 4.71e-08 | 9/9 |

Structured Poisson fitted benchmark, implicit gradient:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --gradient=implicit --out=/tmp/structured-poisson-fit-implicit-slice-implicit-full.csv
```

Result:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0018 | 0.0018 | 1.00x | 9.24e-13 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0058 | 0.0057 | 1.01x | 2.67e-12 | 9/9 |

Before/after gradient speedup from the benchmark above:

| cell | path | finite (s) | implicit (s) | speedup |
| --- | --- | ---: | ---: | ---: |
| small | dense | 0.0069 | 0.0018 | 3.83x |
| small | CG | 0.0060 | 0.0018 | 3.33x |
| medium | dense | 0.0334 | 0.0058 | 5.76x |
| medium | CG | 0.0278 | 0.0057 | 4.88x |

Exploratory warm large-ish CG cells:

| p | n | K | finite (s) | implicit (s) | speedup | abs loglik diff |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 12 | 16 | 2 | 0.0329-0.0348 | 0.0133-0.0134 | 2.45x-2.60x | 2.88e-07 |
| 20 | 25 | 2 | 0.1535 | 0.0714 | 2.15x | 1.60e-07 |

Interpretation: the private structured fitted path now avoids Optim
finite-difference gradients by default on the dense reference objective. This
is the first true structured implicit-gradient slice, but the generic joint
ForwardDiff Jacobian is still a scaffold; the production large-p path needs the
matrix-free structured adjoint.

Full core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result:

```text
2295 pass, 3 expected broken placeholders, 0 fail, 0 error.
Notable blocks:
structured Poisson implicit gradient | 4/4 pass
structured Poisson internal fitter   | 18/18 pass
quality (direct environment)         | 2 expected broken
```

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
Testing GLLVM tests passed.
2307 pass, 1 expected broken placeholder, 0 fail, 0 error.
quality | 12/12 pass
```

Final scans:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Result:

- `git diff --check`: clean.
- Stale-wording scan: known historical check-log entries plus the
  user-provided AGENTS.md "Gaussian only" snapshot; no new public API/status
  claim was added by this private gradient scaffold.
- Performance-claim scan: existing Gaussian/gllvmTMB speedup claims and
  historical non-Gaussian/structured speed records; the new text explicitly
  labels the fitted speedup as a private structured implicit-gradient scaffold,
  not the final 20x-100x large-p structured algorithm.
- Private-source trace scan: no matches in tracked repo content checked for
  this slice.

## 2026-06-01 — Structured Poisson Fitted Mode Cache

### Scope

Added warm-started `u`/`z` mode caching to the private fixed-covariance
structured Poisson fitter. The likelihood formula is unchanged; the cache only
changes the starting point for neighbouring optimizer probes. The cold-start
path remains available with `mode_cache=false`.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson internal fitter           | 14/14 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Structured Poisson fitted benchmark smoke:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --out=/tmp/structured-poisson-fit-cache-smoke.csv
```

Result:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| smoke | 5 | 8 | 1 | 4 | 0.0049 | 0.0045 | 1.10x | 3.51e-08 | 6/6 |

Structured Poisson fitted benchmark full grid:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --out=/tmp/structured-poisson-fit-cache-full.csv
```

Result:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0068 | 0.0059 | 1.15x | 1.02e-09 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0344 | 0.0267 | 1.29x | 4.71e-08 | 9/9 |

Before/after against commit `f6630b9`:

| cell | path | before (s) | after (s) | speedup |
| --- | --- | ---: | ---: | ---: |
| smoke | dense | 0.0099 | 0.0049 | 2.02x |
| smoke | CG | 0.0096 | 0.0045 | 2.13x |
| small | dense | 0.0138 | 0.0068 | 2.03x |
| small | CG | 0.0133 | 0.0059 | 2.25x |
| medium | dense | 0.0779 | 0.0344 | 2.26x |
| medium | CG | 0.0722 | 0.0267 | 2.70x |

ForwardDiff-through-Newton probe:

```text
dense reference gradient max abs diff vs central finite difference: 1.32
```

Interpretation: the cache is a real constant-factor fitted speedup, but the
gradient probe confirms that this structured path still needs the
implicit/envelope gradient rather than a simple `autodiff=:forward` switch.

Full core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result:

```text
2287 pass, 3 expected broken placeholders, 0 fail, 0 error.
Notable blocks:
structured Poisson internal fitter | 14/14 pass
quality (direct environment)       | 2 expected broken
```

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
Testing GLLVM tests passed.
2299 pass, 1 expected broken placeholder, 0 fail, 0 error.
quality | 12/12 pass
```

Final scans:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Result:

- `git diff --check`: clean.
- Stale-wording scan: known historical check-log entries plus the
  user-provided AGENTS.md "Gaussian only" snapshot; no new public API/status
  claim was added by this private cache.
- Performance-claim scan: existing Gaussian/gllvmTMB speedup claims and
  historical non-Gaussian/structured speed records; the new cache text
  explicitly labels the speedup as an internal constant-factor fitted-path
  improvement, not the final 20x-100x structured algorithm.
- Private-source trace scan: no matches in tracked repo content checked for
  this slice.

## 2026-06-01 — Structured Poisson Internal Fitted Prototype

### Scope

Added a private fixed-covariance structured Poisson fitter around the existing
joint Laplace objective. The helper estimates `β` and lower-triangular `Λ` for
a supplied structured precision and fixed `sigma2`, and lets the fitted path
switch between the exact dense mode solve and the matrix-free CG mode solve.
No public API or formula syntax changed.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson internal fitter           | 9/9 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Structured Poisson fitted benchmark smoke:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --out=/tmp/structured-poisson-fit-smoke.csv
```

Result:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| smoke | 5 | 8 | 1 | 4 | 0.0099 | 0.0096 | 1.03x | 1.09e-10 | 6/6 |

Structured Poisson fitted benchmark full grid:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --full --out=/tmp/structured-poisson-fit-full.csv
```

Result:

| cell | p | n | K | iterations | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 5 | 8 | 1 | 6 | 0.0138 | 0.0133 | 1.04x | 2.14e-11 | 8/8 |
| medium | 8 | 12 | 2 | 6 | 0.0779 | 0.0722 | 1.08x | 1.07e-10 | 9/9 |

Exploratory larger fitted cells, two L-BFGS iterations:

| p | n | K | dense (s) | CG (s) | dense / CG | abs loglik diff | calls |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 25 | 2 | 0.4099 | 0.2669 | 1.54x | 2.59e-8 | 5/5 |
| 40 | 40 | 2 | 3.4018 | 1.6331 | 2.08x | 1.87e-8 | 6/6 |

Interpretation: this is the fitted-model bridge for the structured
non-Gaussian fast path. The current private fitter still uses Optim finite
differences, so it is not yet the 20x-100x algorithm. It proves that the exact
CG mode solve can be carried through fitted optimization with matching
log-likelihoods; the next multiplier is the structured implicit/envelope
gradient.

Full core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result:

```text
2282 pass, 3 expected broken placeholders, 0 fail, 0 error.
Notable blocks:
non-Gaussian fitter objectives: AD/implicit gradients | 92/92 pass
structured Poisson internal fitter                   | 9/9 pass
quality (direct environment)                         | 2 expected broken
```

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
Testing GLLVM tests passed.
2294 pass, 1 expected broken placeholder, 0 fail, 0 error.
quality | 12/12 pass
```

Final scans:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Result:

- `git diff --check`: clean.
- Stale-wording scan: known historical check-log entries plus the
  user-provided AGENTS.md "Gaussian only" snapshot; no new public API/status
  claim was added by this private helper.
- Performance-claim scan: existing Gaussian/gllvmTMB speedup claims and
  historical non-Gaussian/structured speed records; the new fitted-prototype
  text explicitly limits the claim to internal dense-vs-CG timing and says it
  is not the 20x-100x structured algorithm.
- Private-source trace scan: no matches in tracked repo content checked for
  this slice.

## 2026-06-01 — Dense Schur Materialization Allocation Trim

### Scope

Reduced dense Schur materialization overhead in the internal structured
Poisson Laplace path. `_schur_u_dense` now fills and symmetrizes caller-owned
storage through `_schur_u_dense!`, avoiding the extra `S + S'` and broadcast
temporaries. The exact dense mode solve now factors the returned `Symmetric`
Schur matrix directly rather than first copying it back to a plain `Matrix`.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 36/36 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Dense Schur materialization microbenchmark, fixed seed, BLAS threads set to 1:

| p | n | K | dense build (s) | dense build bytes | build + logdet (s) | build + logdet bytes |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 80 | 80 | 2 | 0.004513 | 59,280 | 0.004519 | 110,528 |
| 160 | 120 | 2 | 0.024074 | 220,528 | 0.024098 | 425,376 |
| 320 | 160 | 3 | 0.156511 | 850,384 | 0.147645 | 1,669,632 |

Compared with the pre-slice checkpoint in the same session:

| p | dense build bytes before | dense build bytes after | build + logdet bytes before | build + logdet bytes after |
| ---: | ---: | ---: | ---: | ---: |
| 80 | 162,768 | 59,280 | 214,144 | 110,528 |
| 160 | 630,256 | 220,528 | 835,088 | 425,376 |
| 320 | 2,488,912 | 850,384 | 3,308,144 | 1,669,632 |

Full structured Poisson objective benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --reps=5 --warmups=3 --out=/tmp/structured-poisson-laplace-dense-copyless.csv
```

Result:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0047 | 0.0020 | 0.0028 | 2.40x | 1.71x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0420 | 0.0103 | 0.0093 | 4.07x | 4.49x | 4.91e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.1661 | 0.0363 | 0.0242 | 4.58x | 6.87x | 0.00e+00 | 9.13e-1 |

The ratio speedups are objective-level internal comparisons, not fitted-model
or R-parity claims. The exact CG path remains the reference-quality fast path;
SLQ is approximate and still needs optimizer-stability work before production
use.

### Test Suites

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2273 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2285 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot and prior check-log entries; not edited because AGENTS.md changes
  require maintainer approval.
- Performance-claim scan finds this new benchmark entry plus existing Gaussian /
  non-Gaussian speedup records. The new numbers are internal objective and
  allocation timings, not fitted-model or R-parity claims.
- Open PR collision check still finds draft PR #59 as the separate
  non-Gaussian CI / extra-family lane.

## 2026-06-01 — Structured Schur Workspace And Sparse Precision Logdet

### Scope

Reduced another layer of structured Poisson objective overhead by adding a
reusable Schur-operator workspace for per-site `A_s` matrices / Cholesky factors
and by computing the structured precision log determinant in native storage
instead of densifying sparse `Q`. Public APIs remain unchanged.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 34/34 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 13/13 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Schur operator construction probe:

```sh
julia --project=. --startup-file=no -e '<fixed-seed Schur operator construction probe>'
```

Result:

| cell | allocating constructor (s) | workspace constructor (s) | allocating bytes | workspace bytes |
| --- | ---: | ---: | ---: | ---: |
| p=80, n=80, K=2 | 7.80e-5 | 6.75e-5 | 12,704 | 1,688 |
| p=160, n=120, K=2 | 1.93e-4 | 1.78e-4 | 17,040 | 120 |
| p=320, n=160, K=3 | 5.27e-4 | 5.74e-4 | 28,640 | 120 |

Exact CG+dense objective allocation/timing probe:

```sh
julia --project=. --startup-file=no -e '<fixed-seed structured Poisson allocation probe>'
```

Result:

| cell | previous median (s) | current median (s) | previous bytes | current bytes | allocation reduction |
| --- | ---: | ---: | ---: | ---: | ---: |
| p=80, n=80, K=2 | 0.0095 | 0.0090 | 645,864 | 486,512 | 24.7% |
| p=160, n=120, K=2 | 0.0383 | 0.0362 | 2,050,040 | 1,568,016 | 23.5% |

Compared with the first prototype baseline, the same cells are down from
1,429,560 and 4,327,576 bytes respectively.

Full structured Poisson objective benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-schurws-logdet.csv
```

Result:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0047 | 0.0020 | 0.0027 | 2.42x | 1.73x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0303 | 0.0088 | 0.0088 | 3.46x | 3.45x | 4.91e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.1559 | 0.0361 | 0.0239 | 4.32x | 6.52x | 0.00e+00 | 9.13e-1 |

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Parsed tally from emitted `Test Summary` blocks:
2271 pass, 3 broken placeholders (1 existing sparse-phy precision placeholder
and 2 expected direct quality placeholders), 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Parsed tally from emitted `Test Summary` blocks: 2283 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds this new benchmark entry plus existing Gaussian /
  non-Gaussian speedup records. The new numbers are internal objective and
  allocation evidence, not an R `gllvmTMB` parity claim.

Open PR / collision check:

```text
gh pr list --limit 5
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson Workspace Reuse

### Scope

Reduced allocation pressure in the internal structured Poisson Laplace
prototype by reusing the score/weight matrices inside the mode loop, adding a
scratch-aware Schur CG solve, and avoiding redundant dense/sparse storage copies
when matrix element types already match. Public APIs remain unchanged.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 29/29 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 12/12 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Allocation/timing probe against the exact CG+dense path:

```sh
julia --project=. --startup-file=no -e '<fixed-seed structured Poisson allocation probe>'
```

Result:

| cell | before median (s) | after median (s) | before bytes | after bytes | time speedup | allocation reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| p=80, n=80, K=2 | 0.0104 | 0.0095 | 1,429,560 | 645,864 | 1.10x | 54.8% |
| p=160, n=120, K=2 | 0.0386 | 0.0383 | 4,327,576 | 2,050,040 | 1.01x | 52.6% |

Full structured Poisson objective benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-workspace-final.csv
```

Result:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0047 | 0.0019 | 0.0027 | 2.43x | 1.72x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0345 | 0.0089 | 0.0090 | 3.89x | 3.82x | 4.91e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.2190 | 0.0363 | 0.0262 | 6.04x | 8.35x | 0.00e+00 | 9.13e-1 |

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2265 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2277 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds this new benchmark entry plus existing Gaussian /
  non-Gaussian speedup records. The new numbers are internal objective and
  allocation evidence, not an R `gllvmTMB` parity claim.

Open PR / collision check:

```text
gh pr list --limit 5
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Poisson Laplace Prototype

### Scope

Added the first full structured non-Gaussian objective prototype: an internal
Poisson Laplace marginal with a response-structured Gaussian random effect,
site latent factors, dense Schur fallback, matrix-free CG mode solve, and the
existing dense/SLQ Schur determinant selector. This is not exported and is not
yet wired into public fitters.

### Commands

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result:

```text
structured Schur operator                    | 26/26 pass
structured Schur SLQ logdet                  | 9/9 pass
structured Poisson Laplace prototype         | 9/9 pass
structured Poisson sigma-to-zero reduction   | 1/1 pass
```

Full structured Poisson objective benchmark:

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --full --out=/tmp/structured-poisson-laplace-full.csv
```

Result:

| cell | p | n | K | dense (s) | CG + dense (s) | CG + SLQ (s) | dense / CG+dense | dense / CG+SLQ | CG+dense abs diff | CG+SLQ abs diff |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 40 | 40 | 2 | 0.0050 | 0.0022 | 0.0030 | 2.31x | 1.69x | 9.55e-11 | 4.73e-1 |
| medium | 80 | 80 | 2 | 0.0903 | 0.0097 | 0.0098 | 9.31x | 9.26x | 4.55e-11 | 6.36e-1 |
| large | 160 | 120 | 2 | 0.1772 | 0.0394 | 0.0279 | 4.49x | 6.35x | 0.00e+00 | 9.13e-1 |

CSV smoke path:

```sh
julia --project=. --startup-file=no bench/structured_poisson_laplace_bench.jl --smoke --reps=1 --out=/tmp/structured-poisson-laplace-smoke.csv
head -2 /tmp/structured-poisson-laplace-smoke.csv
```

Result: CSV file written with the expected header and one smoke row.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2259 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from `/tmp/gllvm-pkgtest-structured-poisson.log`: 2271 pass, 1
existing broken sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds this new benchmark entry plus existing Gaussian /
  non-Gaussian speedup records. The new claim is local to the internal
  structured Poisson objective prototype and is not a gllvmTMB parity claim.

Open PR / collision check:

```text
gh pr list --limit 5
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 — Structured Schur Logdet Benchmark Harness

### Scope

Added a Julia-only benchmark harness for the structured non-Gaussian determinant
lane. The script compares exact dense `logdet(S_u)` against frozen-probe SLQ on
the internal `_SchurUOperator`, records the dense/SLQ speedup and SLQ relative
error, and can write row-level CSV output. This does not change package source
or public APIs.

### Commands

Smoke run:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=3
```

Result:

```text
Structured Schur logdet benchmark (smoke); reps=3, warmups=3
smoke    p=  80 n=  12 K=2 dense=  0.0008 s  slq=  0.0009 s  speedup=   0.95x  relerr=5.371e-03
```

Full local grid:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --reps=3
```

Result:

| cell | p | n | K | probes | steps | dense (s) | SLQ (s) | dense / SLQ | relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| small | 80 | 20 | 2 | 4 | 20 | 0.0013 | 0.0013 | 0.96x | 4.382e-3 |
| medium | 160 | 40 | 2 | 4 | 20 | 0.0083 | 0.0043 | 1.94x | 2.776e-3 |
| large | 320 | 80 | 3 | 4 | 20 | 0.0743 | 0.0189 | 3.92x | 3.018e-3 |
| frontier | 640 | 160 | 3 | 4 | 20 | 0.5886 | 0.0734 | 8.02x | 2.825e-4 |

Accuracy-oriented probe sweep:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --full --cells=large,frontier --reps=3 --nprobes=8 --lanczos-steps=20
```

Result:

| cell | p | n | K | probes | steps | dense (s) | SLQ (s) | dense / SLQ | relative error |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| large | 320 | 80 | 3 | 8 | 20 | 0.0764 | 0.0375 | 2.04x | 4.717e-4 |
| frontier | 640 | 160 | 3 | 8 | 20 | 0.5849 | 0.1440 | 4.06x | 6.225e-4 |

CSV smoke path:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=1 --out=/tmp/structured-schur-smoke.csv
head -2 /tmp/structured-schur-smoke.csv
```

Result: CSV file written with the expected header and one smoke row.

### Test Suites

Focused structured test:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl")'
```

Result:

```text
structured Schur operator     | 22/22 pass
structured Schur SLQ logdet   | 9/9 pass
```

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2257 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2257 pass, 1 existing broken
sparse-phy precision placeholder, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs/src docs/dev-log/check-log.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
<private-source trace scan over tracked repo content>
```

Results:

- `git diff --check`: clean.
- No private-source trace in tracked repo content.
- The stale-wording scan still finds the user-provided AGENTS.md "Gaussian only"
  snapshot; not edited because AGENTS.md changes require maintainer approval.
- Performance-claim scan finds this new benchmark entry plus existing Gaussian /
  non-Gaussian speedup records. The new claim is local to the structured Schur
  determinant benchmark and is not a fitted-model speed claim.

Open PR / collision check:

```text
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
[#59 draft: gllvmTMB catch-up: Delta-Gamma + zero-inflated (ZIP/ZINB) families + non-Gaussian CIs]
```

No issue or PR was modified.

## 2026-06-01 - Structured Poisson Fitted Probe Controls

### Scope

Added a fitted-benchmark CLI/CSV control for SLQ probe construction:
`bench/structured_poisson_fit_bench.jl` now accepts
`--probe-kind=rademacher|orthogonal`, freezes the matching probe matrix for
forced-SLQ fitted cells, prints the selected kind at startup, and records
`probe_kind` in the CSV. `bench/README.md` documents the new orthogonal-probe
control. This is benchmark instrumentation only; no package API, likelihood,
or fitter default changed.

### Benchmark Smoke Evidence

Help output:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --help
```

Result: help includes
`--probe-kind=KIND  rademacher or orthogonal for SLQ fits (default: rademacher).`

Rademacher forced-SLQ smoke:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --probe-kind=rademacher --nprobes=5 --lanczos-steps=5 --reps=1 --warmups=1 --out=/tmp/structured-poisson-fit-probes-rademacher.csv
```

Result:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=0, trace_solve=auto, probe_kind=rademacher
smoke   p=  5 n=  8 K=1 dense= 0.0009 s  cg= 0.0009 s  speedup= 0.99x  diff=2.97e-12 calls=(6,6)
Wrote /tmp/structured-poisson-fit-probes-rademacher.csv
```

Orthogonal forced-SLQ smoke:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --probe-kind=orthogonal --nprobes=5 --lanczos-steps=5 --reps=1 --warmups=1 --out=/tmp/structured-poisson-fit-probes-orthogonal.csv
```

Result:

```text
Structured Poisson fitted benchmark (smoke); reps=1, warmups=1, iterations=4, gradient=implicit, logdet=auto, dense_cutoff=0, trace_solve=auto, probe_kind=orthogonal
smoke   p=  5 n=  8 K=1 dense= 0.0009 s  cg= 0.0009 s  speedup= 1.04x  diff=5.24e-12 calls=(6,6)
Wrote /tmp/structured-poisson-fit-probes-orthogonal.csv
```

CSV checks:

```sh
head -n 2 /tmp/structured-poisson-fit-probes-rademacher.csv
head -n 2 /tmp/structured-poisson-fit-probes-orthogonal.csv
```

Results: both CSVs include the new `probe_kind` column. The rademacher row
records `trace_solve=lanczos, probe_kind=rademacher, absdiff_loglik=2.970e-12`;
the orthogonal row records
`trace_solve=lanczos, probe_kind=orthogonal, absdiff_loglik=5.244e-12`.

Invalid option smoke:

```sh
julia --project=. --startup-file=no bench/structured_poisson_fit_bench.jl --smoke --logdet=auto --dense-cutoff=0 --probe-kind=invalid --reps=1 --warmups=0 --out=/tmp/structured-poisson-fit-invalid.csv
```

Result: exit code 1 with
`ArgumentError: --probe-kind must be rademacher or orthogonal; got invalid`.

### Test Suites

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 122 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2336 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2348 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-fitted-probe-controls.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-fitted-probe-controls.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after the audit report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal benchmark-instrumentation record
  only.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-02 - Bootstrap CI Parallel Replicates And Warm Starts

### Scope

Added optional `parallel` and `warm_start` controls to the parametric
bootstrap CI paths. `bootstrap_ci` and `bootstrap_ci_derived` now use
deterministic per-replicate RNG seeds, can distribute bootstrap refits across
Julia threads when the process has more than one thread, and share one private
helper for refit warm-start keyword construction. README and quickstart
bootstrap examples were corrected to pass the original response matrix `y`.

### Correctness Tests

Added tests proving:

- serial and threaded `bootstrap_ci` calls produce identical replicate matrices
  and convergence counts under the same seed;
- `bootstrap_ci(...; warm_start = true)` returns finite percentile bounds on a
  small Gaussian fixture;
- serial and threaded `bootstrap_ci_derived` calls produce identical derived
  replicate vectors, convergence counts, and valid replicate counts.

Focused direct tests:

```sh
julia --project=. test/test_confint_bootstrap.jl
julia --project=. test/test_confint_derived.jl
```

Results:

```text
parametric bootstrap CI | 13/13 pass
derived-quantity CIs    | 48/48 pass
```

Focused threaded tests:

```sh
JULIA_NUM_THREADS=2 julia --project=. test/test_confint_bootstrap.jl
JULIA_NUM_THREADS=2 julia --project=. test/test_confint_derived.jl
```

Results:

```text
parametric bootstrap CI | 13/13 pass
derived-quantity CIs    | 48/48 pass
```

Core suite:

```sh
julia --project=. test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2421 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2433 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error. The run
also emitted non-failing duplicate-include warnings from `takahashi_selinv.jl`;
this slice did not touch that path.

### Documentation Build

First attempt:

```sh
julia --project=docs docs/make.jl
```

Result: failed before rendering because a local ignored `docs/Manifest.toml`
had stale path-dependency metadata for `GLLVM` and omitted `SpecialFunctions`.
The tracked root `Project.toml` already declares `SpecialFunctions`.

Local docs-environment refresh:

```sh
julia --project=docs -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
(cd docs && julia --project=. -e 'using Pkg; Pkg.develop(path=".."); Pkg.resolve(); Pkg.instantiate()')
```

Result: the ignored local docs manifest was refreshed; no tracked manifest
change exists because root `.gitignore` ignores all `Manifest.toml` files.

Second attempt:

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0. Existing non-failing warnings remain: invalid local links
from several docs pages, deployment skipped outside CI, missing Vitepress
assets/default substitutions, and npm audit reporting 4 moderate issues.

### Benchmark Evidence

N/A - no speed claim is made in this slice. The new behavior is scheduling and
initialization control for stochastic refits; correctness was checked by serial
vs threaded deterministic equality rather than timing.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked public artifacts, excluding the guard file and historical dev logs>
rg -n "bootstrap_ci\([^;\n]*;[^\n]*(n_boot|seed)" README.md docs/src src test
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src CLAUDE.md
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/PERF-plus-design.md CLAUDE.md
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean.
- Private-source trace scan: no matches in tracked public artifacts scanned.
- Bootstrap example scan: all README/docs/src/src/test examples found by the
  pattern now pass `y = y`; no stale no-data bootstrap example remains in the
  searched files.
- Stale status scan: no hits in README, docs/src, or CLAUDE.md.
- Performance-claim scan: expected existing benchmark and gllvmTMB parity
  wording only; this slice adds no new speed or R-parity claim.
- GitHub lane check: PR #60 is the current draft branch
  `codex/non-gaussian-fitter-gradients`; PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM`. No PR or issue was modified.

## 2026-06-02 - Sparse Phy Analytic Fitter Route

### Scope

Wired `fit_gaussian_gllvm(...; phy=...)` to the sparse Brownian-tree analytic
gradient for the current single-axis Gaussian phylogenetic cases:

- `K_phy == 0, has_phy_unique == true`
- `K_phy == 1, has_phy_unique == false`

The dense `Σ_phy` route remains the general path. The sparse route rejects
multi-axis combinations, fixed effects, W-tier, and diagonal-tier fits for now,
and treats `Σ_phy` and `phy` as mutually exclusive inputs.

### Correctness Tests

Focused fitter smoke:

```sh
julia --project=. --startup-file=no -e 'include("test/test_fit.jl")'
```

Result: 27 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2414 pass, 1 existing sparse-phy precision placeholder, 2 expected
direct-environment quality placeholders, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted summaries: 2426 pass, 1 existing sparse-phy precision
placeholder, 0 fail, 0 error.

Docs:

```sh
julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "docs"); include("docs/make.jl")'
```

Result: exit code 0. Local build succeeded with pre-existing invalid-local-link
warnings, Vitepress default-file warnings, missing logo/favicon warnings, and
npm audit notices.

### Benchmark Evidence

Local timing smoke, unique sparse phylo cell, three timed refits after warmup:

```text
p=32, n=64:
dense Σ_phy median = 0.428047042 s
sparse phy median  = 0.068494209 s
speedup            = 6.249390251371469x
dense reps         = [0.458757292, 0.428047042, 0.409211042]
sparse reps        = [0.05248425, 0.076899625, 0.068494209]
```

The attempted p=64/n=96 timing cell was terminated after the dense baseline ran
too long for a quick audit smoke.

### Quality And Audit Scans

Commands:

```sh
git diff --check
rg -n "evaluation-only|AD-based fitting|must therefore use the dense|Dense path only|Σ_phy is required|user-supplied Σ_phy|phy fast path|phy=\\.\\.\\.|Brownian-tree" README.md docs/src src test
rg -n "JABE|OneDrive|Library/CloudStorage|uploaded|private PDF|private-file|PDF" README.md docs/src src test docs/dev-log/check-log.md docs/dev-log/after-task -g '!docs/build/**' -g '!docs/node_modules/**'
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-02-sparse-phy-fit-analytic.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB|6\\.25x|6\\.249" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**' -g '!docs/build/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state,url
```

Results:

- `git diff --check`: clean.
- Sparse-phy stale wording scan: expected current `evaluation-only for
  ForwardDiff` wording remains; stale "must use dense fitter" wording was
  removed from the touched public docs.
- Private-source trace scan: one historical check-log note only; no trace in
  this slice's changed source, README, docs, tests, or new after-task report.
- Stale wording scan: expected historical check-log hits and the user-provided
  AGENTS.md "Gaussian only" snapshot.
- Performance-claim scan: expected historical benchmark logs and existing
  Gaussian/gllvmTMB claims. This slice adds only internal Julia dense-vs-sparse
  timing evidence, not a new R `gllvmTMB` parity or public 100x claim.
- GitHub lane check: PR #60 is this draft branch; PR #59 remains the separate
  draft `claude/package-work-catchup-mQiZM`.

## 2026-06-01 - Structured Poisson Exact Lemma Gradient Route

### Scope

Added an opt-in exact `logdet_method = :lemma` route for the internal
structured Poisson implicit-gradient path. The route reuses the Schur
determinant-lemma / Woodbury factors to compute `logdet(S_u)`,
`diag(S_u^-1)`, `S_u^-1` times all site-loading RHS columns, and the adjoint
Schur solve without materializing the dense `S_u^-1`. Defaults are unchanged:
`:auto` still selects exact dense below the cutoff and SLQ above it.

### Correctness Tests

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 165 pass, 0 fail, 0 error. New checks compare lemma value/gradient to
the exact dense block gradient, compare Woodbury adjoint solve to the dense
joint solve, exercise a fitted `logdet_method = :lemma` path, and keep the
invalid-logdet guard active.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2374 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2386 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Benchmark Evidence

New repeatable harness:

```sh
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --smoke --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-smoke-rerun.csv
julia --project=. --startup-file=no bench/structured_poisson_lemma_gradient_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-poisson-lemma-gradient-break-even-reps2.csv
```

Results:

```text
smoke    p= 160 n= 120 K=2 dense=  0.0085 s lemma=  0.0145 s speedup= 0.59x bytes=(1.74e+06, 6.80e+06) valuediff=0.00e+00 gradrel=1.20e-16
medium   p= 512 n= 128 K=2 dense=  0.0429 s lemma=  0.0269 s speedup= 1.60x bytes=(9.87e+06, 1.87e+07) valuediff=0.00e+00 gradrel=1.24e-16
large    p=1024 n= 256 K=2 dense=  0.1342 s lemma=  0.1235 s speedup= 1.09x bytes=(3.86e+07, 7.31e+07) valuediff=0.00e+00 gradrel=1.60e-16
xlarge   p=2048 n= 512 K=2 dense=  1.0541 s lemma=  0.4880 s speedup= 2.16x bytes=(1.53e+08, 2.89e+08) valuediff=0.00e+00 gradrel=1.72e-16
```

Interpretation: the exact lemma path is slower on the smoke cell but faster on
the medium-to-xlarge gradient cells. It is still memory-heavier, so it remains
opt-in until the batched RHS workspace is reduced or reused across optimizer
calls.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-gradient.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-lemma-gradient.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders after this
  report was finalized.
- Stale-wording scan: expected historical and command-pattern hits only,
  including the user-provided AGENTS.md "Gaussian only" snapshot; this slice
  adds no public API/status claim.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal exact lemma-gradient speed
  evidence only; no public 100x structured speed claim or new R `gllvmTMB`
  parity claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Poisson Trace Break-Even Harness

### Scope

Added a break-even mode to `bench/structured_poisson_trace_gradient_bench.jl`
so the structured Poisson trace-gradient benchmark can study the crossover
range around the exact-dense cutoff (`p = 640, 1024, 1536, 2048`) without
editing source. The same script now accepts `--skip-dense`, recording `missing`
dense speed/accuracy fields when running approximate SLQ-only exploratory
cells. `bench/README.md` documents the new command and warns that probe-kind
comparisons must be run sequentially because concurrent benchmark processes can
distort dense timings.

### Corrected Benchmark Evidence

Discarded evidence: an earlier Rademacher/orthogonal comparison launched two
frontier runs concurrently and produced false dense timings near 30 seconds,
making SLQ look about 150x faster. Sequential reruns contradicted that result,
so those parallel timings are not used as evidence.

Sequential frontier dense-vs-SLQ check:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=frontier --trace-solve=lanczos --probe-kind=orthogonal --nprobes=8 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-break-even-frontier-dense-seq.csv
```

Result:

```text
Structured Poisson trace-gradient benchmark (break-even); reps=3, warmups=2, probe_kind=orthogonal, nprobes=8, steps=20, trace_solve=lanczos, dense=true
frontier p= 640 n= 160 K=2 dense=  0.0946 s  slq=  0.1897 s  speedup=   0.50x  valuediff=1.78e-01  gradrel=1.13e-01
```

Interpretation: at `p=640`, exact dense is still faster than the approximate
SLQ trace-gradient path on this local machine. This supports keeping the
current exact-dense auto cutoff high and treating SLQ as a true larger-p /
memory-avoidance path, not as a blanket speedup at the current fitted frontier.

SLQ-only larger exploratory cell:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --skip-dense --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-break-even-giant-skipdense.csv
```

Result:

```text
Structured Poisson trace-gradient benchmark (break-even); reps=3, warmups=2, probe_kind=orthogonal, nprobes=16, steps=20, trace_solve=lanczos, dense=false
giant    p=1024 n= 256 K=2 dense=      NA s  slq=  0.7845 s  speedup=      NA  valuediff=NA  gradrel=NA
```

CSV checks:

```sh
head -n 2 /tmp/structured-poisson-trace-break-even-frontier-dense-seq.csv
head -n 2 /tmp/structured-poisson-trace-break-even-giant-skipdense.csv
```

Results: the dense row records numeric dense speed, speedup, value difference,
and gradient relative error; the `--skip-dense` row records `missing` in dense
speed/accuracy fields and still records SLQ value/time.

Sequential edge sweep after the harness commit:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=1 --warmups=1 --out=/tmp/structured-poisson-trace-break-even-giant-dense-seq.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=huge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=1 --warmups=1 --out=/tmp/structured-poisson-trace-break-even-huge-dense-seq.csv
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=xlarge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=1 --warmups=1 --out=/tmp/structured-poisson-trace-break-even-xlarge-dense-seq.csv
```

Results:

```text
giant    p=1024 n= 256 K=2 dense=  0.2910 s  slq=  0.7843 s  speedup=   0.37x  valuediff=7.29e-01  gradrel=9.89e-02
huge     p=1536 n= 320 K=2 dense=  0.6524 s  slq=  1.4708 s  speedup=   0.44x  valuediff=2.31e-01  gradrel=1.37e-01
xlarge   p=2048 n= 512 K=2 dense=  1.4356 s  slq=  3.2011 s  speedup=   0.45x  valuediff=4.48e-01  gradrel=1.69e-01
```

Interpretation: the current exact-dense cutoff at `p=2048` is conservative in
the right direction for this trace-gradient configuration; SLQ is not faster up
to the cutoff under sequential load.

Failure-path smoke:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=nope --skip-dense --reps=1 --warmups=0
```

Result: exit code 1 with
`ArgumentError: unknown cells for break-even mode: nope`.

### Test Suites

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 122 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2336 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-trace-break-even-bench.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-trace-break-even-bench.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after the audit report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this corrected internal benchmark evidence
  only; this slice explicitly rejects the misleading parallel 100x-looking
  result.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Poisson Dense In-Place Inverse

### Scope

Removed one avoidable dense allocation in the exact dense structured Poisson
block-gradient path. `_structured_poisson_block_implicit_value_grad` now builds
the identity matrix once and overwrites it with `ldiv!(Csu, G)` instead of
forming `Csu \ Matrix{T}(I, p, p)`, which allocated both the identity and a
separate inverse result. The likelihood, gradient formula, and public API are
unchanged.

### Before/After Benchmark

Before:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-giant-before-inplace-inv.csv
```

Result:

```text
giant    p=1024 n= 256 K=2 dense=  0.2608 s  slq=  0.7842 s  speedup=   0.33x  valuediff=7.29e-01  gradrel=9.89e-02
```

After:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-giant-after-inplace-inv.csv
```

Result:

```text
giant    p=1024 n= 256 K=2 dense=  0.2329 s  slq=  0.7841 s  speedup=   0.30x  valuediff=7.29e-01  gradrel=9.89e-02
```

Interpretation: exact dense trace-gradient time improved by about `1.12x` on
the `p=1024, n=256, K=2` break-even cell. This is a modest constant-factor
speedup on the current winning dense path, not a new SLQ or R `gllvmTMB` parity
claim.

### Test Suites

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 122 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2336 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2348 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-dense-inplace-inverse.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-poisson-dense-inplace-inverse.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after the audit report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal constant-factor dense-path
  improvement only; no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Schur Direct Site Factors

### Scope

Replaced stored per-site Schur Cholesky factors with stored `logdet(A_s)` values
and `A_s^{-1}` matrices, where `A_s = I + Lambda' W_s Lambda`. The
`K = 1` and `K = 2` site factors now use closed-form log-determinant/inverse
formulas; the generic `K >= 3` path still uses Cholesky locally and stores only
the resulting log determinant plus inverse. The structured Poisson likelihood,
gradient formula, public API, and dense/SLQ selector are unchanged.

### Before/After Benchmark

Manual setup microbenchmark, after one warmup on `p = 1024`, `n = 256`,
`K = 2`, tridiagonal sparse precision, 30 workspace reps, 20 operator reps:

Before:

```text
workspace median=0.0322495 ms bytes=68144
operator median=2.3687919999999996 ms bytes=68256
```

After:

```text
workspace median=0.0162085 ms bytes=64048
operator median=0.3101455 ms bytes=64160
```

Interpretation: workspace setup improved about `1.99x`; `_SchurUOperator`
construction improved about `7.64x` on the benchmarked `K = 2` site-factor
cell.

Trace-gradient benchmark after the change, compared with the immediately
previous dense-in-place slice:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-giant-after-direct-site-factors.csv
```

Result:

```text
giant    p=1024 n= 256 K=2 dense=  0.2220 s  slq=  0.7712 s  speedup=   0.29x  valuediff=7.29e-01  gradrel=9.89e-02
```

Previous same-cell result: dense `0.2329s`, SLQ `0.7841s`. Interpretation:
about `1.05x` exact-dense trace-gradient improvement and about `1.02x` SLQ
trace-gradient improvement. This is an internal setup-path speed slice, not a
new public R `gllvmTMB` parity claim or a 100x structured result.

### Test Suites

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 137 pass, 0 fail, 0 error. This includes direct `K = 1`/`K = 2`
coverage and a new generic `K = 3` site-factor check.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2346 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2358 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-site-factors.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-direct-site-factors.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after the audit report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal setup-path speed evidence only;
  no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Schur Tiny-K Matvec

### Scope

Specialized the matrix-free Schur matvec `_schur_u_mul!` for `K = 1`, `K = 2`,
and `K = 3`. These are the current structured Poisson benchmark and planned
large-grid dimensions. The generic `K >= 4` loop remains unchanged. This
directly targets the CG mode solve and the SLQ/Lanczos determinant path, where
one objective or gradient evaluation can call the Schur matvec many times.

### Before/After Benchmark

Manual matvec microbenchmark on `p = 1024`, `n = 256`, tridiagonal sparse
precision, 200 reps for `K = 1` and `K = 2`, 100 reps for `K = 3`, after one
warmup:

Before:

```text
K=1 matvec median=1286.7085 us bytes=80
K=2 matvec median=1824.1045 us bytes=80
K=3 matvec median=2227.7295 us bytes=80
```

After:

```text
K=1 matvec median=314.5835 us bytes=80
K=2 matvec median=335.0420 us bytes=80
K=3 matvec median=368.6670 us bytes=80
```

Interpretation: matrix-free Schur matvec improved by about `4.09x` for
`K = 1`, `5.44x` for `K = 2`, and `6.04x` for `K = 3`, with no allocation
increase.

Trace-gradient benchmark after the change, compared with the immediately
previous direct-site-factor slice:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-giant-after-tinyk-matvec.csv
```

Result:

```text
giant    p=1024 n= 256 K=2 dense=  0.1950 s  slq=  0.2253 s  speedup=   0.87x  valuediff=7.29e-01  gradrel=9.89e-02
```

Previous same-cell result: dense `0.2220s`, SLQ `0.7712s`. Interpretation:
exact dense trace-gradient improved by about `1.14x`, while the SLQ/Lanczos
trace-gradient path improved by about `3.42x` and is now close to the dense
reference timing on this `p = 1024` cell. The SLQ value/gradient approximation
error is unchanged, so this is speed evidence only, not a parity claim.

### Test Suites

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 139 pass, 0 fail, 0 error. The structured Schur operator test now
includes explicit matvec checks for `K = 1`, `K = 2`, and `K = 3`.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2348 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2360 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-matvec.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-matvec.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after the audit report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders.
- Stale-wording scan: expected historical and command-pattern hits only.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal Schur-matvec speed evidence only;
  no public 100x structured speed claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Schur Tiny-K Dense Batch

### Scope

Specialized exact dense Schur assembly for `K <= 3` by batching all site
correction columns into one tall matrix `C` and applying a single
`mul!(S, C, C', -1, 1)`. The generic direct assembler remains in place for
`K >= 4`. This targets the current structured Poisson benchmark grid and keeps
the exact dense determinant path competitive while the stochastic large-`p`
path is still approximate.

### Correctness Tests

Added direct tests for `_schur_u_dense_tinyk!`:

- `K = 1`, `K = 2`, and `K = 3` dense-batch assembly matches the existing
  generic direct dense assembler to `1e-10`.
- `_schur_u_dense(op)` dispatches to the same exact dense result for each
  tiny-`K` case.
- `K > 3` and malformed `C` workspace dimensions throw the intended errors.

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 147 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2356 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2368 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Before/After Benchmark

Same-command dense assembly benchmark from the prior committed state versus
this dense-batch implementation:

| p | n | K | before dense assembly | after dense assembly | before / after | after bytes |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1024 | 256 | 2 | 84.013833 ms | 13.069604 ms | 6.43x | 12,636,256 |
| 2048 | 512 | 2 | 663.276958 ms | 116.877959 ms | 5.68x | 50,438,240 |
| 1024 | 256 | 3 | 123.875562 ms | 20.5697495 ms | 6.02x | 14,749,792 |

Current-code smoke probe after the test addition:

```text
p=1024 n=256 K=2 dense median_ms=9.885438 bytes_median=1.2636256e7
p=2048 n=512 K=2 dense median_ms=52.3524165 bytes_median=5.043824e7
p=1024 n=256 K=3 dense median_ms=14.981125 bytes_median=1.4749792e7
```

Interpretation: the exact dense Schur assembly hot path is about `5.7x` to
`6.4x` faster on the same-command before/after probe for the tested `K = 2`
and `K = 3` cells. The batch path allocates a wider `p x (K*n)` workspace, so
the speedup is a compute/BLAS batching win rather than an allocation reduction.

Trace-gradient benchmark after the change:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=giant,huge,xlarge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=16 --lanczos-steps=20 --reps=3 --warmups=2 --out=/tmp/structured-poisson-trace-break-even-after-tinyk-dense-batch.csv
```

Result:

```text
giant    p=1024 n= 256 K=2 dense=  0.2122 s  slq=  0.2349 s  speedup=   0.90x  valuediff=7.29e-01  gradrel=9.89e-02
huge     p=1536 n= 320 K=2 dense=  0.4426 s  slq=  0.4180 s  speedup=   1.06x  valuediff=2.15e-01  gradrel=1.50e-01
xlarge   p=2048 n= 512 K=2 dense=  0.9094 s  slq=  0.9563 s  speedup=   0.95x  valuediff=1.98e-01  gradrel=1.67e-01
```

Compared with the previous tiny-`K` matvec slice, exact dense trace-gradient
time improved from `0.2740s` to `0.2122s` on `giant`, from `0.8152s` to
`0.4426s` on `huge`, and from `1.7342s` to `0.9094s` on `xlarge`. The SLQ
approximation error is unchanged; exact dense is now roughly tied with the
current SLQ configuration through `p = 2048`, while remaining exact.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-dense-batch.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-tinyk-dense-batch.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders after this
  report was finalized.
- Stale-wording scan: expected historical and command-pattern hits only,
  including the user-provided AGENTS.md "Gaussian only" snapshot; this slice
  adds no public API/status claim.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal Schur dense-assembly speed
  evidence only; no public 100x structured speed claim or new R `gllvmTMB`
  parity claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Schur Determinant Lemma

### Scope

Added an exact determinant-lemma logdet path for the internal structured Schur
operator:

```text
S_u = B - C C',
B = sigma2^-1 Q + diag(sum_s w_s),
C_s = D_s Lambda chol(A_s^-1),
A_s = I_K + Lambda' D_s Lambda.
```

The new method is exposed only through the internal `_schur_u_logdet(op;
method = :lemma)` path. It does not change the default `:auto` policy and is
not wired into the fitted gradient path yet, because the gradient still needs
either dense inverse information or a matching Woodbury-style inverse/trace
derivation.

### Correctness Tests

Added structured Schur tests proving:

- `method = :lemma` matches exact dense logdet for dense precision.
- `method = :lemma` matches exact dense logdet for sparse precision.
- `method = :lemma` rejects unsupported `K > 3`.

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 150 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2359 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2371 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Benchmark Evidence

SLQ calibration probe that motivated the exact path:

```sh
julia --project=. --startup-file=no bench/structured_poisson_trace_gradient_bench.jl --break-even --cells=xlarge --trace-solve=lanczos --probe-kind=orthogonal --nprobes=32 --lanczos-steps=40 --reps=2 --warmups=1 --out=/tmp/structured-poisson-trace-xlarge-orth32-l40-after-dense-batch.csv
```

Result:

```text
xlarge   p=2048 n= 512 K=2 dense=  0.8562 s  slq=  2.5396 s  speedup=   0.34x  valuediff=3.73e-01  gradrel=1.17e-01
```

Interpretation: increasing probes/steps made the SLQ trace-gradient path slower
while still leaving material approximation error, so the next useful algorithm
slice was exact structured determinant work rather than more probes.

Updated durable Schur logdet benchmark:

```sh
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --smoke --reps=2 --warmups=1 --out=/tmp/structured-schur-logdet-lemma-smoke.csv
julia --project=. --startup-file=no bench/structured_schur_logdet_bench.jl --break-even --cells=giant,xlarge --reps=2 --warmups=1 --out=/tmp/structured-schur-logdet-lemma-break-even.csv
```

Results:

```text
smoke    p=  80 n=  12 K=2 dense=  0.0001 s  lemma=  0.0001 s  slq=  0.0003 s  dense/lemma=   1.69x  dense/slq=   0.48x  lemma_relerr=0.000e+00  slq_relerr=5.371e-03
giant    p=1024 n= 256 K=3 dense=  0.0116 s  lemma=  0.0101 s  slq=  0.2415 s  dense/lemma=   1.15x  dense/slq=   0.05x  lemma_relerr=1.587e-15  slq_relerr=3.181e-04
xlarge   p=2048 n= 512 K=3 dense=  0.1159 s  lemma=  0.0666 s  slq=  1.0721 s  dense/lemma=   1.74x  dense/slq=   0.11x  lemma_relerr=1.551e-15  slq_relerr=2.610e-04
```

Current-method K=2 probe for the structured Poisson trace-gradient grid shape:

```text
p=1024 n=256 K=2 dense=0.01502425 lemma=0.005754917 dense/lemma=2.610680571066446 absdiff=9.094947017729282e-13
p=2048 n=512 K=2 dense=0.091694896 lemma=0.0296673545 dense/lemma=3.090767530350574 absdiff=1.6370904631912708e-11
```

Interpretation: the lemma path is exact to roundoff and is faster than exact
dense logdet in the tested K=2/K=3 cells, but it allocates more memory because
it forms `C`, `B\\C`, and the smaller `K*n` determinant matrix. It is not yet
a full fitted-gradient replacement.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-determinant-lemma.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-determinant-lemma.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders after this
  report was finalized.
- Stale-wording scan: expected historical and command-pattern hits only,
  including the user-provided AGENTS.md "Gaussian only" snapshot; this slice
  adds no public API/status claim.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal determinant-lemma speed evidence
  only; no public 100x structured speed claim or new R `gllvmTMB` parity claim
  was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.

## 2026-06-01 - Structured Schur Woodbury Inverse Helper

### Scope

Added an exact internal Woodbury inverse substrate for the determinant-lemma
Schur path. Given `S_u = B - C C'`, `_schur_u_woodbury(op)` now caches the
base Cholesky, the small determinant Cholesky, `C`, `B^-1 C`, and the exact
logdet. New helpers compute `S_u^-1 V` and `diag(S_u^-1)` from those factors.
This does not change the default fitter or the `:auto` determinant policy.

### Correctness Tests

Added direct structured Schur tests proving:

- Woodbury cached logdet matches exact dense logdet for dense and sparse
  precision.
- `_schur_u_woodbury_inv_apply!` matches dense `S_u \ R` for dense and sparse
  precision.
- `_schur_u_woodbury_inv_diag` matches `diag(inv(S_u))` for dense and sparse
  precision.
- malformed RHS/output dimensions throw `DimensionMismatch`.

Focused structured tests:

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Result: 158 pass, 0 fail, 0 error.

Core suite:

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: exit code 0. Manual tally from emitted `Test Summary` blocks:
2367 pass, 1 existing broken sparse-phy precision placeholder, 2 expected
quality placeholders in the direct core environment, 0 fail, 0 error.

Full package suite:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result:

```text
quality       | 12/12 pass
Testing GLLVM tests passed
```

Manual tally from emitted `Test Summary` blocks: 2379 pass, 1 existing broken
sparse-phy precision placeholder, quality 12/12 pass, 0 fail, 0 error.

### Benchmark Evidence

New repeatable harness:

```sh
julia --project=. --startup-file=no bench/structured_schur_woodbury_bench.jl --smoke --reps=2 --warmups=1 --out=/tmp/structured-schur-woodbury-smoke.csv
julia --project=. --startup-file=no bench/structured_schur_woodbury_bench.jl --break-even --reps=2 --warmups=1 --out=/tmp/structured-schur-woodbury-break-even.csv
```

Results:

```text
smoke    p=  80 n=  24 K=2 dense_setup=0.0015 woodbury_setup=0.0001 setup_speed=11.50x dense_batch=0.0011 woodbury_batch=0.0032 batch_speed=0.33x apply_err=2.22e-16 diag_err=4.16e-17
giant    p=1024 n= 256 K=2 dense_setup=0.0224 woodbury_setup=0.0095 setup_speed=2.35x dense_batch=0.0208 woodbury_batch=0.0372 batch_speed=0.56x apply_err=2.08e-17 diag_err=6.07e-18
xlarge   p=2048 n= 512 K=2 dense_setup=0.1181 woodbury_setup=0.0263 setup_speed=4.49x dense_batch=0.1229 woodbury_batch=0.1454 batch_speed=0.85x apply_err=1.56e-17 diag_err=3.90e-18
```

CSV details for the break-even cells:

```text
giant:  dense_apply=0.000106666 s, woodbury_apply=0.0002880625 s, dense_batch_bytes=33,616,240, woodbury_batch_bytes=59,576,264
xlarge: dense_apply=0.0008307085 s, woodbury_apply=0.012988583 s, dense_batch_bytes=134,340,976, woodbury_batch_bytes=236,584,176
```

Interpretation: Woodbury setup is exact and `2.35x` to `4.49x` faster than
materializing the full dense inverse on large cells. The full all-site
apply-plus-diagonal batch is slower in this rerun (`0.56x` to `0.85x`) and
allocates more, so this is an enabling inverse substrate, not a fitted-gradient
speed promotion yet.

### Quality And Audit Scans

Commands:

```sh
git diff --check
<private-source trace scan over tracked repo content>
<placeholder rerun scan over current check-log and after-task report>
rg -n "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-woodbury-inverse.md CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
rg -n "340.?x|speedup|per.?fit|moderate.?to.?large p|100x|100.?x|gllvmTMB" README.md docs/src docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-structured-schur-woodbury-inverse.md bench CLAUDE.md AGENTS.md -g '!docs/node_modules/**'
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results:

- `git diff --check`: clean after this report.
- Private-source trace scan over tracked public artifacts: no matches.
- Placeholder rerun scan: no stale rerun/fill-result placeholders after this
  report was finalized.
- Stale-wording scan: expected historical and command-pattern hits only,
  including the user-provided AGENTS.md "Gaussian only" snapshot; this slice
  adds no public API/status claim.
- Performance-claim scan: expected historical benchmark records, existing
  Gaussian/gllvmTMB claims, and this internal Woodbury inverse setup speed
  evidence only; no public 100x structured speed claim or new R `gllvmTMB`
  parity claim was added.
- GitHub lane check: PR #59 remains the separate draft
  `claude/package-work-catchup-mQiZM` lane; no PR or issue was modified.
