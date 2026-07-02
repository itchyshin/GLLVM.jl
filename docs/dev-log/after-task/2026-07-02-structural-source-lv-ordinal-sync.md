# After Task: Structural-Source LV Ordinal Sync

## 1. Goal

Keep the structural-source LV Gate 0 matrix aligned after the ordinary
shared-cutpoint Ordinal `X_lv` selected-entry profile canary landed.

## 2. Implemented

No likelihood or package API changed. The live Design 73 source note, the
non-Gaussian structural-source Gate 0 matrix, and the structural-dependence
truth-matrix ultra-plan now all say the same thing: ordinary native
selected-entry `B_lv` profile route evidence covers Poisson, Binomial logit,
NB2, Gamma, Beta, and shared-cutpoint Ordinal logit; per-trait ordinal bridge
parity, source-specific structural `lv`, mixed-family `X_lv`, masks,
coverage calibration, and `unique=` parity remain blocked.

## 3a. Decisions and Rejected Alternatives

I did not open the R bridge to Ordinal `X_lv`; the Ordinal route is native
shared-cutpoint Julia evidence only. I also did not launch the predeclared
phylo x Poisson S2 Totoro diagnostic, because that still requires explicit
maintainer authorization.

## 3b. Mathematical Contract

No new mathematical contract was added. The ordinary interval target remains
`B_lv = Lambda * alpha_lv'`. The structural-source phylo x Poisson lane remains
on the private `B_eta_realized` target, not the retired population `B_lv` target.

## 4. Files Touched

- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
- `docs/dev-log/decisions/2026-07-02-structural-dependence-lv-truth-matrix-ultraplan.md`
- `docs/dev-log/after-task/2026-07-02-nongaussian-structural-source-lv-gate0.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```text
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.4s

julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params /tmp/phylo_poisson_xlv_s2_manifest_params_rerun.csv --reps 20 --seed0 20260702 --selected-entries 1,2,5 --profile-iterations 700 --iterations 250
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /tmp/phylo_poisson_xlv_s2_manifest_params_rerun.csv --task-id 1 --dry-run
wrote 20 S2 manifest tasks to /tmp/phylo_poisson_xlv_s2_manifest_params_rerun.csv
S2 dry-run task 1 / 20
target=B_eta_realized; method=private _phylo_poisson_xlv_profile_eta_realized
dry-run only: no model fit, no random draw, no Totoro/DRAC launch
```

JET: not run - no implementation change. Allocs: not run - no hot path changed.
Aqua: not run - no dependency/export/project metadata changed. Full
`Pkg.test()`: not run for this docs/truth-matrix sync.

## 6. Tests of the Tests

No new tests were added. The rerun covers the existing phylo x Poisson
structural S1 reduction/profile canaries so the next-source gate still has its
local evidence after the ordinary Ordinal extension.

## 7a. Issue Ledger

No GitHub issue or PR action. PR #127 remains closed/parked, and this sync does
not authorize public source-specific grammar.

## 8. Consistency Audit

The active notes now separate three facts: ordinary native Ordinal `X_lv`
selected-entry profile route evidence is in; per-trait ordinal bridge parity is
out; structural-source non-Gaussian LV remains gated by one source/family
estimand page at a time.

## 9. What Did Not Go Smoothly

The first audit command had a shell quoting miss around a backticked `X_lv`
pattern. I reran the search via direct file inspection and patched the active
truth sources rather than touching historical canary reports wholesale.

## 10. Known Residuals

Mission Control was not refreshed because the `gllvmTMB` checkout is heavily
dirty from concurrent/user work. The next structural-source action remains the
predeclared phylo x Poisson S2 Totoro diagnostic, but only after explicit
authorization.

## 11. Team Learning

Ada kept this as a truth-sync slice. Hopper kept native shared-cutpoint Ordinal
separate from per-trait bridge parity. Grace kept Totoro/DRAC as planned but
unlaunched. Rose blocks any reading that treats this as public source-specific
support.

Rose verdict: PASS WITH NOTES - current operating docs are aligned, with
Mission Control intentionally untouched until the R checkout is safe to edit.
