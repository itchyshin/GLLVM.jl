# After Task: Sparse Phy Single-Axis Takahashi Gradient

## Goal

Move the one-axis sparse phylogenetic analytic gradient onto Takahashi
selected-inverse entries, and check whether DRM.jl already has the same
capacity before opening any GitHub issue.

## Implemented

`sparse_phy_grad(st)` now dispatches `K_aug == 1` to a Takahashi-backed path
that uses same-leaf selected-inverse entries for the tree-coupled scalar and
loading-gradient terms. The general `K_aug >= 2` path remains the exact dense
leaf-block implementation because it needs cross-leaf inverse entries outside
the `L + L'` Takahashi sparsity pattern. Benchmark and docs wording now reflect
that split.

## Mathematical Contract

For one phylogenetic axis, the required trace contractions reduce to diagonal
same-leaf entries of `M_sad^-1 = Q_eff^-1 + alpha X_G S_K^-1 X_G'`. The
`Q_eff^-1` same-leaf diagonal is available from Takahashi selected inversion;
the low-rank Woodbury correction is dense only in `K_B`. This preserves the
Hadfield-Nakagawa augmented-state Gaussian phylogenetic likelihood while
replacing the previous dense leaf-block solve in the single-axis gradient.

## Files Changed

src:

- `src/sparse_phy_grad.jl` - added the `K_aug == 1` Takahashi fast path and
  tightened scaling comments.

test:

- `test/test_sparse_phy_grad.jl` - added a helper-level regression check against
  the exact dense leaf-block diagonal.

bench:

- `bench/sparse_phy_grad_bench.jl` - updated benchmark wording and reran the
  single-axis scaling script.
- `bench/node_gradient_bench.jl` - removed stale wording that all
  `sparse_phy_grad` work was the older `O(p^2)` path.
- `bench/sparse_phy_bench.jl` - removed stale branch-wiring wording.

docs:

- `docs/src/benchmarks.md` - updated the benchmark page to distinguish the
  Takahashi-backed single-axis gradient from the multi-axis limitation.
- `docs/dev-log/check-log.md` - recorded this slice.

## Tests Added

One assertion was added to `test/test_sparse_phy_grad.jl`:
`_single_axis_Msad_inv_diag(st) ≈ diag(leaf_block_inv(st))` on the one-axis
`Λ_phy` fixture. This satisfies the independent-calculation clause: the new
Takahashi diagonal route is compared to the existing exact dense leaf-block
helper and would not have existed before this change.

## Benchmark Numbers

Pre-edit one-shot scout at `d3c4899`:

```text
p=80  time=0.000867875  bytes=3127176
p=160 time=0.001673083  bytes=12326232
p=320 time=0.014568791  bytes=47541240
```

Current one-shot scout:

```text
p=80  time=0.000126458  bytes=900224
p=160 time=0.000604542  bytes=3011760
p=320 time=0.001408000  bytes=11183392
```

Current BenchmarkTools medians:

```text
p=80  median_time_ns=205396.0    median_memory=900224   median_allocs=345
p=160 median_time_ns=607542.0    median_memory=3011760  median_allocs=345
p=320 median_time_ns=1.6402295e6 median_memory=10920448 median_allocs=373
```

Full `bench/sparse_phy_grad_bench.jl` via stacked main+bench env:

```text
p=100  analytic=0.219 ms dense-FD=120.654 ms speedup=549.9x
p=500  analytic=0.773 ms dense-FD=52541.520 ms speedup=68000.2x
p=1000 analytic=1.612 ms dense-FD=skipped
p=5000 analytic=7.654 ms dense-FD=skipped
analytic log-log slopes: [0.782, 1.061, 0.968]
dense-FD log-log slopes: [3.776]
```

Verdict: clear speed and allocation reduction on the single-axis path; measured
scaling is near-linear over the benchmark grid.

## R-Parity Verdict

Parity: not run. This slice changes the Julia analytic gradient implementation,
not the Gaussian marginal likelihood formula. Dense-Julia parity against
ForwardDiff and the existing fitter comparison passed. The RCall parity suite is
still documented as a draft opt-in scaffold in `test/parity/README.md`, so a
live R `gllvmTMB` parity claim would be overstated here.

## JET / Allocs / Aqua Verdicts

- JET: clean through the full `Pkg.test()` quality gate, 12/12 quality tests.
- Allocs: Allocs.jl not available in the active project; allocation evidence
  comes from `@allocated` and BenchmarkTools memory/alloc counters.
- Aqua: clean through the full `Pkg.test()` quality gate, 12/12 quality tests.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_takahashi_selinv.jl"); include("test/test_sparse_phy_grad.jl"); include("test/test_node_gradient.jl")'
```

Result: 102 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: manual tally from emitted summaries = 2400 pass, 1 existing sparse-phy
precision placeholder, 2 expected direct-environment quality placeholders,
0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: manual tally from emitted summaries = 2412 pass, 1 existing sparse-phy
precision placeholder, 0 fail, 0 error. `quality` passed 12/12 and Julia printed
`Testing GLLVM tests passed`.

```sh
julia --project=docs --startup-file=no docs/make.jl
julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "docs"); include("docs/make.jl")'
```

Result: direct docs env failed before rendering because the docs manifest is
stale for the current package dependency graph. The stacked main+docs build
succeeded, with pre-existing local-link warnings and npm audit notices.

```sh
julia --project=. --startup-file=no -e 'push!(LOAD_PATH, "bench"); include("bench/sparse_phy_grad_bench.jl")'
```

Result: benchmark completed; single-axis analytic slopes `[0.782, 1.061,
0.968]`.

## Consistency Audit

Patterns run:

```sh
git diff --check
<private-source trace scan over tracked public content, excluding .gitignore and generated docs>
rg -n 'Takahashi follow-up would bring|Analytic slope ≈ 2|NOT yet O\(p\)|selected-inverse term|older `sparse_phy_grad` path|gradient stays at O\(p²\) overall|inapplicable to the gradient|sparse analytic gradient code is intentionally NOT wired|PERF\+\+ hard constraint|do NOT modify src/GLLVM' src bench docs/src README.md CLAUDE.md test/test_sparse_phy_grad.jl
rg -n 'single-axis|multi-axis|K_aug == 1|Takahashi|O\(p²\)|O\(p\)' src/sparse_phy_grad.jl bench/sparse_phy_grad_bench.jl docs/src/benchmarks.md test/test_sparse_phy_grad.jl
gh pr list --limit 5 --json number,title,headRefName,isDraft,state
```

Results: whitespace clean; private-source scan over tracked public content,
excluding `.gitignore` and generated docs, is clean; stale Takahashi/wiring
wording removed from the touched sparse-phy gradient area; expected scope hits
remain in source, benchmark, docs, and tests. Open PR #59 is the separate draft
`claude/package-work-catchup-mQiZM`.

## GitHub Issue Maintenance

DRM.jl was checked after fetching refs. `origin/main` already documents and
implements Takahashi selected inverse for its q=4 sparse augmented-state
Laplace path, including tests against dense inverse entries. No DRM.jl GitHub
issue was opened because there is nothing to advise: the capacity already
exists.

## What Did Not Go Smoothly

BenchmarkTools is not in the main project; the bench environment has it but its
manifest is stale for the current GLLVM dependency graph. The docs environment
has the same stale-manifest issue. Both were worked around by stacking the bench
or docs environment behind the main project rather than mutating manifests.

## Team Learning

Gauss/Karpinski: use Takahashi only where the requested inverse entries are
actually in-pattern; for cross-leaf dense blocks, record the mathematical
boundary instead of forcing the algorithm.

## Remaining Risks

- R parity was not run; the parity scaffold is still draft and opt-in.
- Allocs.jl was not run; this report uses allocation measurements, not an
  Allocs.jl zero-allocation gate.
- Multi-axis sparse phy gradients still need dense cross-leaf inverse blocks
  and remain `O(p^2)`.
- The local docs build still emits pre-existing local-link warnings and npm
  audit notices unrelated to this slice.

## Known Limitations

The Takahashi branch is limited to `K_aug == 1`. It covers a single
phylogenetic loading axis or phylo-unique `σ_phy`; it does not solve the
general multi-axis dense leaf-block problem.

## Next Command

```sh
GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl
```

Run this only after the R/gllvmTMB parity scaffold has been validated against
the installed R API.

## Rose Verdict

Rose verdict: PASS WITH NOTES - the single-axis Takahashi implementation,
tests, benchmarks, docs, and DRM.jl capacity check are complete; R parity,
Allocs.jl, and multi-axis O(p) remain explicit limitations.
