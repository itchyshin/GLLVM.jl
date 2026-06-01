# After Task: Structured Schur Woodbury Inverse Helper

## Goal

Add the exact inverse building block needed before the determinant-lemma Schur
path can plausibly support structured Poisson fitted gradients.

## Implemented

`_schur_u_woodbury(op)` now caches the determinant-lemma factors for
`S_u = B - C C'`, including the base Cholesky, the small determinant Cholesky,
the site factor `C`, `B^-1 C`, and the exact logdet. Two internal helpers use
those factors: `_schur_u_woodbury_inv_apply!` computes exact `S_u^-1 V`, and
`_schur_u_woodbury_inv_diag` computes exact `diag(S_u^-1)`. The default
fitter and determinant policy are unchanged.

## Mathematical Contract

The inverse uses Woodbury on the determinant-lemma factorization:

```text
S_u = B - C C'
S_u^-1 = B^-1 + B^-1 C (I - C' B^-1 C)^-1 C' B^-1.
```

For sparse base precision, the base inverse diagonal uses the existing
`takahashi_diag` helper on the base Cholesky; this is exact for the diagonal.

## Files Changed

- `src/structured_schur.jl` - added `_SchurUWoodbury`,
  `_schur_u_woodbury`, exact inverse apply, and exact inverse diagonal helpers.
- `test/test_structured_schur.jl` - added dense/sparse inverse-apply and
  inverse-diagonal checks against dense references.
- `bench/structured_schur_woodbury_bench.jl` - new repeatable benchmark harness
  for setup, small RHS apply, and all-site apply-plus-diagonal timing.
- `docs/dev-log/check-log.md` - evidence ledger entry.
- `docs/dev-log/after-task/2026-06-01-structured-schur-woodbury-inverse.md` -
  this audit report.

## Tests Added

Eight structured Schur checks were added: cached logdet for dense/sparse
precision, inverse apply for dense/sparse precision, inverse diagonal for
dense/sparse precision, and two dimension guardrails.

## Benchmark Numbers

Repeatable harness:

```text
smoke    p=  80 n=  24 K=2 dense_setup=0.0015 woodbury_setup=0.0001 setup_speed=11.50x dense_batch=0.0011 woodbury_batch=0.0032 batch_speed=0.33x apply_err=2.22e-16 diag_err=4.16e-17
giant    p=1024 n= 256 K=2 dense_setup=0.0224 woodbury_setup=0.0095 setup_speed=2.35x dense_batch=0.0208 woodbury_batch=0.0372 batch_speed=0.56x apply_err=2.08e-17 diag_err=6.07e-18
xlarge   p=2048 n= 512 K=2 dense_setup=0.1181 woodbury_setup=0.0263 setup_speed=4.49x dense_batch=0.1229 woodbury_batch=0.1454 batch_speed=0.85x apply_err=1.56e-17 diag_err=3.90e-18
```

CSV details for break-even cells:

```text
giant:  dense_apply=0.000106666 s, woodbury_apply=0.0002880625 s, dense_batch_bytes=33,616,240, woodbury_batch_bytes=59,576,264
xlarge: dense_apply=0.0008307085 s, woodbury_apply=0.012988583 s, dense_batch_bytes=134,340,976, woodbury_batch_bytes=236,584,176
```

Interpretation: the setup phase is a clear exact speedup, but the full
all-site apply-plus-diagonal workload is slower in this rerun and uses more
memory. This slice is therefore an exact enabling substrate, not a
fitted-gradient speed promotion.

## R-Parity Verdict

Parity: N/A - this is an internal structured Schur linear algebra substrate,
not a public R `gllvmTMB` parity surface.

## JET / Allocs / Aqua Verdicts

- JET: clean through the `Pkg.test()` quality gate.
- Allocs: benchmark records Woodbury bytes; current full batch allocates more
  than dense inverse materialization.
- Aqua: clean through the `Pkg.test()` quality gate.

## CI And Bootstrap Status

No confidence-interval, bootstrap, or public CI configuration code was edited.
The full suite still exercises the current CI/bootstrap tests. No branch CI was
triggered because this local branch was not pushed.

## Checks Run

```sh
julia --project=. --startup-file=no -e 'include("test/test_structured_schur.jl"); include("test/test_structured_poisson_laplace.jl")'
```

Focused result: 158 pass, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Core result: 2367 pass, 1 existing broken sparse-phy precision placeholder, 2
expected quality placeholders in the direct core environment, 0 fail, 0 error.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Full result: 2379 pass, 1 existing broken sparse-phy precision placeholder,
quality 12/12 pass, 0 fail, 0 error.

## Consistency Audit

Commands run:

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

## GitHub Issue Maintenance

No issue action was taken. This is an internal algorithm substrate and benchmark
slice; it does not change public family support or R parity surfaces.

## What Did Not Go Smoothly

The full all-site Woodbury batch was slower after including the exact diagonal
and still allocated more than the dense reference. That is useful evidence:
promotion needs a more fused trace formula, not just replacing dense inverse
calls mechanically.

## Team Learning

Gauss/Karpinski: Woodbury setup is a real win, but the gradient needs a fused
site-trace implementation to avoid paying for large temporary matrices.
Fisher: exactness is proven to roundoff before any fitter policy changes.

## Remaining Risks

- This helper is not wired into the fitted gradient path yet.
- Full batch timing is slower and memory-heavier on large cells in the latest
  rerun.
- The helper currently supports the determinant-lemma `K <= 3` path.

## Known Limitations

No public structured non-Gaussian formula/API, no R `gllvmTMB` parity benchmark,
and no non-Gaussian CI/bootstrap implementation changed in this slice.

## Next Command

```sh
julia --project=. --startup-file=no bench/structured_schur_woodbury_bench.jl --break-even --reps=2 --warmups=1
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - Woodbury inverse application and diagonal are
exact and setup is faster, but full gradient promotion needs a fused trace path
because the current all-site batch is not consistently faster.
