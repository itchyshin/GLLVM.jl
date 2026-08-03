# After-task — NB2/Beta+X Arc 2: light gllvmTMB logLik parity cells

**Date:** 2026-08-02  
**Lane:** `nb2-beta-x-arc2-20260802`  
**Branch:** `parity/nb2-beta-x-arc2-20260802`  
**Base:** `origin/main` @ `9f5133a7` (#175 merge)  
**Twin:** gllvmTMB source `~/Dropbox/Github Local/gllvmTMB` @ `ab49638b`  
**R lib:** `/tmp/R-gllvmtmb-x-parity-20260802` (gllvmTMB 0.6.0, installed
2026-08-02 06:24; reused as-is, no reinstall needed)  
**Rose verdict:** **PASS WITH NOTES** — light logLik with **shared site-X +
per-trait dispersion** for NB2 and Beta, twin to gllvmTMB `disp.group`. Not
full family parity; no Gamma+X/Ordinal+X/X_lv; no shared-φ-Julia-vs-per-trait-R
comparison.

## Goal

Close the twin gap opened by Arc 0 (identity decision) and Arc 1 (engine):
NB2+X and Beta+X light gllvmTMB logLik parity cells at rtol `1e-6`, using Arc 1
`fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov` (`group=collect(1:p)`,
default `hessian=:observed`). No engine changes.

## What landed

| Slice | Change |
|---|---|
| S0 | Confirmed #175 merged to `main` @ `9f5133a7` (merged by maintainer, all 4 Julia CI jobs + Documenter green). Fresh worktree `.worktrees/gllvmjl-nb2-beta-x-arc2-20260802` on branch `parity/nb2-beta-x-arc2-20260802`. |
| S1 | Verified R twin lib at `/tmp/R-gllvmtmb-x-parity-20260802/gllvmTMB` (gllvmTMB 0.6.0) — reused, no reinstall. |
| S2 | Extended `test/parity/parity_helpers.jl` `fit_gllvmtmb_parity_loglik_x` to accept `:negbinomial`/`:beta` (`gllvmTMB::nbinom2()`/`gllvmTMB::Beta()`, per-trait dispersion by R default). |
| S3 | Added "NB2 + shared X (q=1)" and "Beta + shared X (q=1)" `@testset`s to `test/parity/test_x_covariate_parity.jl`, calling `fit_nb_gllvm_grouped_cov`/`fit_beta_gllvm_grouped_cov` with `group=collect(1:p)`, default `hessian=:observed`. |
| S4 | Live run: shared site-X cohort **34/34** (was 18/18 before Arc 2). |
| S5 (repair) | Both cells' first DGP draw left one trait's per-trait dispersion running to a near-boundary value — a genuine Heywood-like identifiability failure, not numerical noise (see below). Repaired DGP for both; re-verified clean. |
| S6 | Docs close-out: `test/parity/README.md`, `docs/design/capability-status.md`, `docs/dev-log/check-log.md`, `docs/dev-log/coordination-board.md`. |
| S7 | This after-task + plan-actual note. |

## Evidence (read Δ from log, not exit code)

Log: `/tmp/arc2_parity_run2.log` (also `/tmp/arc2_parity_run.log`,
`/tmp/arc2_full_suite.log`; repro: `GLLVM_PARITY_TESTS=1 julia
--project=test/parity test/parity/runparity.jl`)

```text
Shared site-X light logLik: GLLVM.jl vs gllvmTMB
  Gaussian+X   Δ≈1.19e-9    Pass 6/6
  Binomial+X   Δ≈3.40e-9    Pass 6/6
  Poisson+X    Δ≈1.23e-9    Pass 6/6
  NB2+X        Δ≈1.29e-8    Pass 8/8
  Beta+X       Δ≈4.29e-9    Pass 8/8
X cohort total                        34/34
```

Full suite (`julia --project=. -e 'using Pkg; Pkg.test()'`, Aqua/JET included):
**5096 pass / 1 broken (pre-existing) / 0 fail**, 55m21.7s. No regressions.

## DGP repair (Fisher's reserved repair slot, used as budgeted)

Both cells needed exactly one repair round, matching the ultra-plan's Fisher
note:

- **NB2+X:** first draw (`K=2, r_true=6.0, n=60`) left one trait's per-trait
  `r` at ~4.2e7 (effectively Poisson) while the R optimizer settled at a
  different local optimum (`Δ logLik = 0.645`, R "relative convergence" flag
  but non-agreeing value). Repaired to `K=1, r_true=1.5, n=120`, milder
  loadings (`0.2×`) — every per-trait `r` then stays in `[1.1, 1.6]` and
  `Δ = 1.29e-8`.
- **Beta+X:** first draw (`φ_true=12.0, n=60`) left one trait's per-trait `φ`
  at ~3.5e5 (near-degenerate); R reported "false convergence (8)" even though
  the logLik itself was already close (`Δ ≈ 8.8e-6` relative, i.e. within
  rtol but with a genuine convergence-flag failure). Repaired to `φ_true=8.0,
  n=80`, milder loadings (`0.1×`) — every per-trait `φ` then stays in `[6,
  17]` and both engines report clean convergence, `Δ = 4.29e-9`.

**rtol stayed fixed at `1e-6`; no tolerance was widened.** The fix was DGP
identifiability (per Fisher's guidance and the repo's no-silent-tolerance-
widening rule), not a looser bar.

## Rose fence

Claim: **"NB2/Beta + shared site-X light logLik under per-trait φ, twin to
gllvmTMB `disp.group`."**

Do **not** claim: full family parity; shared-φ-Julia-vs-per-trait-R
comparison; Gamma+X; Ordinal+X; species-specific XB; `X_lv`; ADEMP; coverage.

## Next

Push/PR when maintainer asks (owner said "please allow" per this session's
follow-up — see PR link in the commit/PR that follows this after-task).
