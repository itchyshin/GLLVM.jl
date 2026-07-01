# After Task: Phylo Model A Gate 0 Eta-Realized Target

## Goal

Implement the minimal Gate 0 target machinery for a future Phylo Gaussian Model
A restart without launching compute or widening source-specific `lv` exposure.

## Implemented

Added an internal eta-scale realized target helper,
`GLLVM._eta_realized_lv_effects(X_lv, Z_truth, Lambda)`, and wired the phylo
DRAC/Totoro bench runner to a bench-only `profile_eta_realized` method. The
runner now records simulated latent-score truth, computes `B_eta_realized` from
the noiseless latent-mediated trait surface, and labels summary/detail CSV rows
as `B_eta_realized` so they cannot be mistaken for old population-`B_lv`
coverage.

## Mathematical Contract

For replicate `r`, with centered realised design `Xc_r`, latent-score truth
`Z_r`, loadings `Lambda_r`, and noiseless trait surface
`Eta_r = Z_r * Lambda_r'`, the target is
`B_eta_realized_r = ((Xc_r' Xc_r)^(-1) Xc_r' Etac_r)'`. Selected-entry
profile-LR constrains fitted `B_lv[t, q]` to this realised eta-scale target and
checks `2 * (nll_constrained - nll_mle) <= qchisq(0.95, 1)`.

## Files Changed

- `src/lv_targets.jl`: new internal centering and eta-realized target helper.
- `src/GLLVM.jl`: includes the internal helper file.
- `bench/phylo_xlv_drac_task.jl`: adds latent-truth simulation, target
  computation, `profile_eta_realized`, and target-specific CSV labels.
- `test/test_phylo_eta_realized.jl`: new deterministic target test.
- `test/runtests.jl`: includes the new test in the core suite.
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md`:
  records Gate 0 implementation status.
- `docs/dev-log/check-log.md`: records checks and claim boundary.

## Tests Added

One new test file, `test/test_phylo_eta_realized.jl`, with 7 assertions. It
compares against an independent dense least-squares calculation, checks
centering invariance, proves the target is not the noisy observed-response
`Y ~ X_lv` slope, and exercises malformed input/rank failure paths.

## Benchmark Numbers

N/A -- no likelihood hot path changed. The helper is diagnostic target
bookkeeping for simulation/bench rows.

## R-Parity Verdict

Parity: N/A -- this does not change the R bridge, Gaussian marginal likelihood,
profile-out convention, fitter, or public CI machinery.

## JET / Allocs / Aqua Verdicts

- JET: not run -- no hot-path or type-stability-sensitive algorithm change.
- Allocs: not run -- no production likelihood or inner-loop change.
- Aqua: not run -- no dependency, export, or Project.toml change.

## Checks Run

```sh
julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
```

Result: `phylo Model A eta-realized target | 7 pass / 7 total`.

```sh
julia --project=. --startup-file=no -e 'include("bench/phylo_xlv_drac_task.jl"); println("bench-include-ok")'
```

Result: printed runner help including `profile_eta_realized`, then
`bench-include-ok`.

```sh
git diff --check -- src/lv_targets.jl src/GLLVM.jl test/test_phylo_eta_realized.jl test/runtests.jl bench/phylo_xlv_drac_task.jl
```

Result: no whitespace errors.

```sh
rm -rf /tmp/phylo_eta_gate0_smoke /tmp/phylo_eta_gate0_params.csv
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_eta_gate0_params.csv --reps 1 --lambdas 1.0 --n-species 12 --n-sites 50 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
mkdir -p /tmp/phylo_eta_gate0_smoke
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --params /tmp/phylo_eta_gate0_params.csv --outdir /tmp/phylo_eta_gate0_smoke --task-id 1 --methods profile_eta_realized --targets B_lv --b-lv-entries 1 --iterations 150 --profile-opt-iterations 80 --truth-init --write-details --force
```

Result: one tiny local smoke completed. Fit converged in 38 iterations; the
selected-entry constrained solve converged; summary/detail CSVs used
`target=B_eta_realized`, `method=profile_eta_realized`; LR was
`0.415558111946 < 3.84145882069`.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: interrupted after about 31 minutes while still CPU-bound in the
unrelated zero-inflated/two-part path at `test/test_zero_inflated.jl`; no
full-suite tally was recorded.

## Consistency Audit

Searches run after the doc update:

```sh
rg -n "B_eta_realized|profile_eta_realized|Gate 0|Gate 1|Gate 2|Gate 3|source-specific.*support|partial support|ready to scale|active compute" bench src test docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-phylo-model-a-gate0-eta-realized.md
```

The intended `B_eta_realized`, `profile_eta_realized`, and Gate 0 language is
present. Guard phrases continue to state that source-specific phylo `lv`
support is not exposed, Gate 1/2/3 are not run, and no active compute is
claimed.

## GitHub Issue Maintenance

No issue or PR action. GLLVM.jl PR #127 remains closed/parked as blocked
evidence; this local Gate 0 slice is not a PR reopen.

## What Did Not Go Smoothly

The broad `test/runtests.jl` sweep did not finish in a practical time window
and was interrupted while active in an unrelated zero-inflated/two-part test.
That prevents a full-suite-green claim for this slice.

## Team Learning

Curie and Fisher should keep Gate 1 as a tiny predeclared diagnostic, not a
coverage claim, because Gate 0 only proves the target plumbing is coherent.

## Remaining Risks

- Full core-suite tally is not available from this slice.
- `profile_eta_realized` is bench-only diagnostic plumbing, not public API.
- Gate 1 positive-control diagnostic, Gate 2 weak-cell diagnostic, and Gate 3
  DRAC claim evidence have not run.
- Passing Gate 0 does not authorize R grammar exposure or PR #127 reopening.

## Known Limitations

The target is finite-sample and design-conditional. It is not population
`B_lv = Lambda * alpha'`, not observed-response saturated `Y ~ X_lv`, and not a
non-Gaussian or mixed-family extension.

## Next Command

```sh
julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
```

## Rose Verdict

Rose verdict: PASS WITH NOTES -- Gate 0 target plumbing and focused evidence are
in place, but the full core suite was interrupted and Gate 1/2/3 remain unrun.
