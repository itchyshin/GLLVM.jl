# Advisory smoke — Student-t Cell 9 (estimated ν) fail diagnosis

**Date:** 2026-09-05  
**Run:** [CI 33979515590](https://github.com/itchyshin/GLLVM.jl/actions/runs/33979515590) · job `101342094437` (PR #294)  
**Job:** `Frozen R 0.7.0 family smoke (advisory; rebuilt oracle)` — **continue-on-error**  
**Cell:** `NATIVE-10-STUDENT` · Parity Cell 9 · `test/parity/test_studentt_parity.jl`  
**Worktree:** `/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904` @ `0ffce588`  
**Branch:** `cursor/m2-foundation-day2-20260905`

## Scope

This note covers **seven of nine** advisory smoke failures — all in the Student-t
parity file. The other two (NB2 `NATIVE-06`, truncated-NB2 `NATIVE-12`) are
dispositioned separately in `advisory-smoke-fail-disposition-2026-09-05.md`.

## Fail tally (Cell 9 block)

| # | Line | Assertion | CI evaluated value |
|---:|---:|---|---|
| 1 | 113 | `r_est.converged` | `false` |
| 2 | 114 | `r_est.optimizer_code == 0` | `1` (`"false convergence (8)"`, 106 iter) |
| 3 | 119 | `jl_est.converged` | `false` (boundary honesty) |
| 4 | 146 | `abs(jl_est.loglik - r_est.logLik) ≤ 0.001` | `0.004954634365844868` |
| 5 | 189 | `r_diag.converged` (near-Gaussian diag, seed 73) | `false` |
| 6 | 190 | `r_diag.optimizer_code == 0` | `1` |
| 7 | 191 | `jl_diag.converged` | `false` |

Cell summary from CI Test Summary: **26 pass / 7 fail / 33 total** in
`NATIVE-10-STUDENT`. Fixed-ν and well-identified estimated-ν diagnostics pass.

## Fixture and DGP

| Field | Value |
|---|---|
| Seed | 71 (pre-registered in test header) |
| Shape | p=5, K=1, n=130 |
| DGP | β=[0.2,-0.1,0.3,0,−0.2], shared σ=0.7, **ν_true=4.0** (fixed at simulate time) |
| Cell 9 call | `df_fixed = nothing` / `nu = nothing`, `disp_group = :species` |
| Fixed-ν control | Same Y, `df = ν_true = 4.0` on both sides — **passes** (Δ logLik ≈ 4.3e-9) |

The DGP fixes ν at simulate time, but the **public estimated-ν fit is free**.
On the seed-71 **realized** Y, trait 1 is weakly identified: both engines drive
ν toward the flat Gaussian limit.

## Measured numbers (CI log, Cell 9)

```
Julia logLik          = -873.2348783384047
gllvmTMB logLik       = -873.2299237040388
Δ logLik (jl − r)     = -0.004954634365844868

Julia per-trait σ     = [0.0001097, 0.86528, 0.64951, 0.7156, 0.78022]
gllvmTMB per-trait σ  = [0.087043, 0.86521, 0.64948, 0.7155, 0.78006]
Julia per-trait ν     = [5.82e32, 5.0234, 4.179, 3.9207, 10.321]
gllvmTMB per-trait ν  = [3.32e10, 5.0274, 4.179, 3.9191, 10.317]

flat Gaussian-limit boundary diagnosed = true
gllvmTMB optimizer    = (1, "false convergence (8)", 106)
```

Near-Gaussian diagnostic (seed 73, intentional ν=1e6 DGP):

```
Δ logLik (jl − r) = -0.06446210575222722
ν (Julia, R)      = ([5.27e9, 5.75e10, 1.01e12], [17.68, 1.53e6, 19612])
```

## What passes on the same run (same file)

| Block | Result |
|---|---|
| Fixed ν + `disp_group=:species` (lines 89–108) | Δ logLik ≈ 4.3e-9 |
| Well-identified estimated-ν diagnostic (seed 72) | converged both sides; Δ ≤ 0.001 |
| Shared-σ baseline (lines 65–87) | intentionally non-gating |

## Assertion → cause hypothesis

### Lines 113–114 — R fit health on frozen oracle

**Assertion:** R must report `converged` and `optimizer_code == 0` on the
estimated-ν public target.

**Hypothesis (primary):** The **rebuilt CI oracle** is not the **retained
Totoro build**. Same source pin, different compiled artifact → nlminb lands on
a flat-ν ridge where nlminb returns code 1. Documented in
`ci-oracle-reproducibility-finding.md` (2026-09-02): identical failure class
across R version / CRAN snapshot / BLAS threading.

**Hypothesis (secondary):** Trait 1 on seed-71 realized Y sits on a **flat ν
plateau** (ν → ∞ indistinguishable from Gaussian). Optimizer convergence flags
are **unreliable at this boundary** — the test comments and
`docs/src/studentt-parity.md` say so explicitly.

**Cross-check:** Option D live-R slice (`advisory-r-smoke-nb2-studentt-2026-09-05.md`,
gllvmTMB **0.7.1**, `devtools::load_all`) reports **estimated ν:
`r_converged`, `optimizer_code=0`** on the same fixture export. So this is
**not** a universal R-engine defect; it is **build / optimizer-trajectory
sensitive** on a boundary-flat fixture.

**Not a Julia regression:** Assertions are R-side health only.

### Line 119 — Julia `jl_est.converged`

**Assertion:** Julia fit must report converged.

**Hypothesis:** **Intentional boundary honesty** in `src/families/studentt.jl`
(lines 431–443): when any estimated ν exceeds `1e6`, `_studentt_nu_boundary`
fires, `@warn` is emitted, and `converged` is forced **false** regardless of
Optim's verdict. CI log shows the warning and trait-1 ν = 5.82e32.

This wiring mirrors the Tweedie `:power_at_boundary` rule and is **by design**
since 2026-09-01 (check-log: "boundary honesty wiring"). It is **not** a silent
tolerance widen — it **tightens** the health gate on an unidentifiable plateau.

### Line 146 — log-likelihood agreement

**Assertion:** `|Δ logLik| ≤ 0.001` on the public estimated-ν target.

**Hypothesis:** With trait 1 at the ν boundary, Julia and R optimize **different
(σ, ν) pairs on the same flat ridge** (σ₁ = 1.1e-4 vs 0.087; ν₁ = 5.8e32 vs
3.3e10). Log-likelihoods remain close (Δ ≈ **0.005**, ~5× the gate) because the
ridge is flat — not because the engines disagree on the likelihood **function**.

Prior Totoro evidence (check-log 2026-08-30): `abs(ΔlogLik) = 0.000690` met
tolerance on retained build while R still reported false convergence. CI is
consistent with that pattern at slightly larger Δ.

**Not evidence of a Julia likelihood bug:** Fixed-ν control on the **same Y**
matches to 4.3e-9; seed-72 estimated-ν diagnostic passes.

### Lines 189–191 — near-Gaussian diagnostic (seed 73)

**Assertion:** Both engines converged on a DGP with ν_true = 1e6.

**Hypothesis:** **Test design mismatch.** Comments in the test (lines 193–195)
state ν is weakly identified near the Gaussian limit and convergence flags are
unreliable — yet the test still asserts `converged` on both sides. The DGP
**intentionally** places data on the boundary; failure is **expected** under
current boundary honesty (Julia) and nlminb behaviour (R). This block should
be reframed as a **boundary-diagnosis printout**, not a pass/fail gate.

## Disposition

| Option | Verdict | Rationale |
|---|---|---|
| **Accept non-gating (advisory)** | **YES** | Job is already `continue-on-error`. Failures are pre-classified A6 boundary-flat fixture + frozen-build sensitivity. Retained Totoro receipts remain authority (`ci-oracle-reproducibility-finding.md`). Required harness already ran **minus NATIVE-10-STUDENT** (check-log 2026-09-01 attempt5). |
| **Fix (follow-up slice)** | **YES — owed, not blocking #294** | (F1) Promote seed-72 well-identified DGP to the **Cell 9 gate**; demote seed-71 to diagnostic-only (fixed-ν control stays). (F2) Rewrite near-Gaussian block to assert `flat_boundary` / print diagnostics, **not** `converged`. (F3) No tolerance widen; no df cap. |
| **Fence Cell 9 estimated-ν** | **YES — already partially done** | Register / harness: estimated-ν remains **partial**; fixed-ν is the covered control. `second-order-holdouts-2026-09-04.md` already lists "Student-t ν (free) OUT". Do not promote until both engines healthy on a **well-identified** fixture. |
| **Julia engine fix** | **NO** | Likelihood and fixed-ν parity are sound. Boundary honesty is correct behaviour. |
| **gllvmTMB edit** | **NO** | Out of lane; live 0.7.1 passes estimated-ν health on same fixture. |

## Relation to prior evidence

| Source | Relevant finding |
|---|---|
| `ci-oracle-reproducibility-finding.md` | CI rebuild ≠ retained build; Student-t lines 113–119 fail class documented |
| `advisory-r-smoke-nb2-studentt-2026-09-05.md` | Live R 0.7.1: estimated ν **passes** health |
| `docs/src/studentt-parity.md` | Seed-71 estimated-ν: logLik within 0.001 on retained evidence; R code 1 = visible boundary, not promoted |
| check-log 2026-09-01 attempt2/5 | 284/286 required; only A6 Student Cell 9 health fails; attempt5 excludes cell from required set |
| `second-order-holdouts-2026-09-04.md` | Free ν excluded from SO batch 1 (Wald pathology at boundary) |

## Commands (repro class)

Advisory smoke (matches CI):

```sh
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
export GLLVM_PARITY_TESTS=1 CORE070_PARITY_REQUIRED=1
export GLLVM_PARITY_RECEIPT_DIR="$PWD/.unlazy/ci-parity-receipts"
export R_LIBS="$PWD/.unlazy/r-build/library"
export GLLVM_PARITY_R_LIBS="$R_LIBS"
export GLLVM_PARITY_R_SOURCE_PIN="$R_LIBS/gllvmTMB/CORE070_SOURCE_PIN.toml"
julia --project=test/parity test/parity/runparity.jl
```

Cell-only (after RCall available):

```sh
julia --project=test/parity -e 'include("test/parity/parity_helpers.jl"); include("test/parity/test_studentt_parity.jl")'
```

Diagnostic tools (seed 71, not parity gates): `tools/core070_student_diagnosis.jl`,
`tools/core070_student_samepoint.jl`.

## Recommendation (one paragraph)

**Accept advisory non-gating and keep Cell 9 estimated-ν fenced** — the seven
failures are the already-classified A6 boundary-flat fixture, not a new Julia
likelihood defect: fixed-ν on the same Y matches to 4.3e-9, seed-72 estimated-ν
passes, and live R 0.7.1 passes health while the **rebuilt frozen oracle** does
not (`ci-oracle-reproducibility-finding.md`). Trait 1 hits the Gaussian-limit ν
plateau (Julia boundary honesty correctly forces `converged=false`; R reports
nlminb code 1), producing a modest logLik gap (0.005) on a flat ridge. **Do not
widen tolerances or edit gllvmTMB.** Schedule a small follow-up to **swap the
Cell 9 gate to the seed-72 well-identified fixture**, demote seed-71 to
diagnostic-only, and fix the near-Gaussian block to test boundary diagnosis
instead of convergence.
