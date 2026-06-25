# 2026-06-25 Binomial X_lv Stop Checkpoint

## Repository State

- Worktree: `/private/tmp/gllvmjl-binomial-xlv-20260625`
- Branch: `codex/binomial-xlv-20260625`
- Pre-stop head: `aa9593217a4bd5d9343dd273e37c8eb11772ab49`
- Open PR guard: GLLVM.jl PR #113 remains open as draft and merge-dirty, so no
  new PR was opened for this branch.

## Dirty State Before This Checkpoint

```sh
git status --short --branch
```

Result before this checkpoint commit: branch was aligned with
`origin/codex/binomial-xlv-20260625` and had one modified file,
`src/families/binomial.jl`.

```sh
git diff --stat
```

Result before this checkpoint commit: `src/families/binomial.jl | 3 ++-`.

## Change Preserved

- Allowed ordinary binomial fits to use `K = 0` again by changing the guard to
  `K >= 0`.
- Kept `X_lv` fits restricted to positive latent dimension with an explicit
  `X_lv requires a positive latent dimension K` error.

This preserves the existing no-latent/masked-CI bridge routes while retaining
the intended guard for predictor-informed latent-score binary fits.

## Commands Already Run

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `masked missing-response bridge 83/83` pass after the guard fix.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 94/94` pass after the
guard fix.

```sh
julia --project=. --startup-file=no test/test_binomial_fit.jl
```

Result: `fit_binomial_gllvm - recovery 8/8` pass after the guard fix.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `bridge CI routing 64/64` pass after the guard fix.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

First run result before the guard fix: failed after `4595` pass, `0` fail,
`1` error, and `1` broken in `46m20.7s`; the error was the accidental
positive-`K` requirement on the existing `K = 0` masked-CI binomial path.

Second run result after the guard fix: started and reached late
VA-vs-Laplace blocks, then was interrupted at Shinichi's stop request. A
process check found no remaining Julia test process.

## Commands Still Needed

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
julia --project=docs --startup-file=no docs/make.jl
git status --short --branch
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,isDraft,mergeStateStatus,url,updatedAt
```

## Next Safest Action

Tomorrow: rehydrate from this branch, confirm the branch is clean, rerun full
`Pkg.test()`, run Documenter if docs remain touched, then decide whether PR
#113 is settled enough to open the focused binomial X_lv PR. If #113 is still
open, keep this branch pushed as a backup and do not open a second PR.

## Blocking Question

None for the code path itself. Process blocker: PR #113 must be settled,
rebased, or explicitly parked before opening this branch as a new PR under the
one-open-PR discipline.
