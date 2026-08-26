# After-task — Laplace curvature programme, phase 2 (PR #265)

**Date:** 2026-08-25 · **Lane:** `claude/lane-beyond-20260824` · PLATFORM: claude
**Reviewed as:** Ada (orchestration), Gauss (numerics), Rose (claim fence), Fisher (inference).

## 1. Goal

Resume a committed overnight handover; then, on the maintainer's chosen scope, close the
Fisher-vs-observed Laplace correctness debt at the root and move GLLVM.jl toward parity with
the gllvmTMB 0.7.0 twin.

## 2. Implemented

- **Instance 8** — `fit_gllvm(Y; family = Gamma())` moved to the observed log-det, with its
  coupled analytic gradient in the same commit.
- **Role-separation contract in 12 kernels** — `laplace`, `covariates`, `mixed`, `quadratic`,
  `grouped_dispersion`, `spde_latent`, `coevolution_glm`, `phylo_glm`, 4× `phylo_*_xlv`.
- **A live pre-existing defect fixed** — the grouped fitters ran their Newton mode search on
  the observed weight, which is measurably negative for Beta (−1.218), giving an unguarded
  indefinite Newton whose non-descent step was reported as success.
- **Three one-model-two-answers defects** — `mixed.jl` (R bridge), `covariates.jl` (0.238),
  `truncated_nbinom2.jl` (4.088e-02 → 0).
- **Honesty** — README/parity/changelog claims corrected against the package's own table; the
  Gaussian-only caveat added to `benchmarks.md`; the curvature class disclosed in the ledger.
- **Coverage** — six orphaned test files wired in; 54 tests for three untested exported
  inference functions. Suite 6463 → 6986.

## 3a. Decisions and Rejected Alternatives

- **Rejected: a global default flip.** Measured evidence says observed is *worse* for Beta
  and GP-1. Per-family, on per-family evidence.
- **Rejected: the DRM `d1/d2/d3` ladder** — would rewrite signatures across many family files
  and guarantee digit churn in the already-correct set. Its *discipline* was imported instead.
- **Rejected: widening a tolerance**, three times. Each failure had a real cause: mode
  convergence, a missing selector, a stale pin.
- **Rejected: updating `test_phylo_gamma_xlv.jl:123`** — own-the-verifier; I changed the code
  it judges.

## 4. Files Touched

20 `src/` files; 5 new test files; `runtests.jl`; README; 4 `docs/src/` pages;
`docs/design/capability-status.md`; `CHANGELOG.md`; `check-log.md`; after-task reports.

## 5. Checks Run

Full `Pkg.test()` at every gate — final **6986 pass / 1 broken (pre-existing) / 0 fail /
0 error**, exit 0, 80m21s. `docs/make.jl` exit 0, warnings at the 41 baseline. PR #263 and
#264 merged with all four Julia CI jobs green.

## 6. Tests of the Tests

- The invariance tests were **tautological** until an adversarial review caught it; rewritten
  to be falsifiable, which then *confirmed three trait declarations by measurement*.
- Cross-kernel and route-agreement tests carry **negative controls** — under `:fisher` the
  routes must also agree, at a different value.
- The C1 regression guard was validated by executing both string forms.
- Boundary-inference tests use closed forms and a longhand mixture, not the implementation.

## 7a. Issue Ledger

Fixed: instances 1/2/5/6/8, C1, the grouped Newton defect, three route inconsistencies.
Recorded not fixed: C2/C3/C5/C6/C7, GP-1 and Beta defaults, `aghq_grid.jl` (fenced).

## 8. Consistency Audit

Swept for siblings of every defect: string interpolation (1 occurrence, isolated); link
guards (5 of 34 families); module membership (8 `src/` files in no `include()`); the
one-model-two-answers pattern (3 instances).

## 9. What Did Not Go Smoothly

- The handover was wrong in four places; the check-log carried two false claims.
- **I misattributed a self-caused failure as pre-existing** and corrected it.
- My own safety net could not detect the failure it existed for.
- An audit declared a kernel unfixable; it was not.
- A `fam`-out-of-scope bug that `using GLLVM` loaded happily — loading is not evidence.

## 10. Known Residuals

Class **not closed** (12 of 13 kernels; `aghq_grid.jl` fenced). Ladder 13/17 — the four
unpaid cells need identity decisions. `test_phylo_gamma_xlv.jl:123` oracle stale. Nine
orphaned tests remain (they test the 8 un-included `src/` files). Version bump and first-tag
mechanics untouched. The PD guard's `-Inf` return branch is unexercised.

## 11. Team Learning

**Writing the documentation was the audit** — five code findings surfaced only because
someone had to describe the families precisely. **Measure the oracle before asserting it** —
M4 read as obviously true and was false for Beta. **"Correct" and "closer to the truth" are
different claims.** **Loading is not evidence; running is.**

## 12. Cross-Product Coverage

**Covers ✓** — the 12 kernels listed above, for families whose default is `:observed`.

**Does NOT cover ✗** — `aghq_grid.jl` (fenced, Fisher at `:203`).
**Does NOT cover ✗** — Beta, NB2, NB1-generic, Tweedie, Student-t, GP-1, Binomial at probit
and cloglog: contract present, default still Fisher, so they will **not** match `gllvmTMB` to
machine precision.
**Does NOT cover ✗** — the 17-cell parity ladder: 13/17, unchanged by this work.
**Does NOT cover ✗** — coverage/recovery evidence for the flip; no simulation-based coverage
certificate exists (`capability-status.md:170` still `missing`).

## Rose verdict

Not independently audited as a whole. The claim most needing a second pair of eyes is the
Beta/GP-1 direction-of-change result, because it reverses an expectation the programme had
been carrying.
