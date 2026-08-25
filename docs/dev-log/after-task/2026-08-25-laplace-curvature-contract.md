# After-task — Laplace curvature role-separation (contract + oracle), and the audit around it

**Date:** 2026-08-25 · **Lane:** `claude/lane-beyond-20260824` · PLATFORM: claude
**Reviewed as:** Ada (orchestration), Gauss (numerics), Rose (claim fence), Shannon (lanes).

## 1. Goal

Resume a committed overnight handover, then take the maintainer's chosen scope: close the
Fisher-vs-observed Laplace correctness debt at the core and move GLLVM.jl toward parity
with the gllvmTMB 0.7.0 twin. Within that, this arc covers the *contract* (commit A) and
the *oracle* that can judge a curvature change — not the flip.

## 2. Implemented

- **Curvature role separation** in `src/families/laplace.jl`: `_glm_weight_matches_observed`
  trait (default `false`, declared per-family), `_glm_obs_weight` (nested ForwardDiff
  through the coded log-density), `_default_hessian = :fisher`, a `hessian::Symbol` kwarg
  validated up front, and a PD guard at the `Λ'WΛ + I` assembly.
- **Trait methods** in `poisson.jl`, `binomial.jl` (logit only), `truncated_poisson.jl`,
  `censored_poisson.jl`.
- **Two new test files**: `test_laplace_curvature_contract.jl` (45) and
  `test_laplace_curvature_oracle.jl` (60), both wired into `runtests.jl`.
- **`truncated_poisson.jl:106`** — malformed `ArgumentError` interpolation fixed.
- **Seven previously-undocumented families documented** in `docs/src/response-families.md`
  (+376 lines) with the Supported-families table cascaded.
- **Five check-log entries** recording findings; one design/verdict artifact under
  `docs/dev-log/plans/`; the AGHQ handover recovered from a closed-PR branch.
- **PR #263 merged** (maintainer-confirmed); **PR #264 opened** for DeltaGamma.

## 3a. Decisions and Rejected Alternatives

- **Substrate over per-family patches** — maintainer's call, taken after the check-log
  recorded the fork as an explicit unmade decision.
- **Rejected: the DRM.jl `d1/d2/d3` ladder.** It would rewrite `_glm_score`/`_glm_weight`
  signatures consumed across many family files, guaranteeing digit churn in the
  already-correct set. Its *discipline* (AD gate at rtol 1e-10, damped search + exact
  value curvature) was imported instead; its signatures were not.
- **Rejected: flipping the default in the same commit.** M1 of the adversarial review.
  Unsplit, "the suite is green" carries no information, because commit A's failures and
  commit B's intended changes are indistinguishable in one diff.
- **Rejected: M4's direction-of-change oracle as a general gate.** Measured first; it does
  not hold for Beta (§9). Encoded only where it was measured to hold.
- **Chose fidelity to the coded objective** for the FD fallback's clamp convention (M6),
  documented it, and restricted the gate grid to interior cells — rather than tuning the
  test until it passed.
- **CensoredPoisson marked trait-true despite its `max(W,0)` clamp**, because routing it to
  the fallback would change a currently-fine family. Caveat recorded in source.

## 4. Files Touched

Modified: `src/families/laplace.jl`, `src/families/poisson.jl`, `src/families/binomial.jl`,
`src/families/truncated_poisson.jl`, `src/families/censored_poisson.jl`,
`test/runtests.jl`, `docs/src/response-families.md`, `docs/dev-log/check-log.md`,
`docs/design/capability-status.md`.
Created: `test/test_laplace_curvature_contract.jl`,
`test/test_laplace_curvature_oracle.jl`,
`docs/dev-log/plans/2026-08-25-laplace-structural-design.md`,
`docs/dev-log/handover/2026-08-18-cursor-handover.md` (recovered verbatim),
this report.
In the sibling worktree (PR #264): `src/families/twopart.jl`, `test/test_delta_gamma.jl`,
`docs/dev-log/check-log.md`, `docs/dev-log/after-task/2026-08-24-deltagamma-observed-curvature.md`.

## 5. Checks Run

| check | result |
|---|---|
| `test_delta_gamma.jl` | 50 / 50 |
| `test_truncated_poisson.jl` | 14 / 14 (was 10; +4 regression assertions) |
| `test_laplace_curvature_contract.jl` | 45 / 45 |
| `test_laplace_curvature_oracle.jl` | 60 / 60 |
| `Pkg.test()` — DeltaGamma lane | **6424 pass / 1 broken / 0 fail / 0 error**, exit 0, 70m52s |
| `Pkg.test()` — contract (commit A) | **6462 pass / 1 broken / 0 fail / 0 error**, exit 0, 68m28s |
| CI on PR #263 | all 4 Julia jobs pass (macOS, ubuntu, **windows**, 1.10-ubuntu) + Documenter |

The commit-A run edited **no existing expected value** — the M1 gate.

## 6. Tests of the Tests

- The C1 regression guard was validated by **executing both string forms**: the shipped one
  yields `"found y=[1 2; 0 3][t,s] at (2,1)"`, the fixed one `"found y=0 at (2,1)"`. The
  test asserts value, index, absence of a spliced matrix, and constant message length — it
  fails on the old code by construction.
- The invariance tests assert `===`, not a tolerance. A tolerance would pass under exactly
  the bug they exist to catch.
- The fallback is checked against **two independently hand-derived formulas in a different
  file** (`_gamma_grouped_laplace_weight`, `_beta_grouped_laplace_weight`) at rtol 1e-10;
  measured worst error 1.8e-14. AD-vs-closed-form agreement at machine precision is not
  reachable by a wrong implementation.
- The Fisher-is-`E[observed]` collapse is asserted directly — the fault class's signature.

## 7a. Issue Ledger

Fixed: C1 (`truncated_poisson.jl:106`). Landed: DeltaGamma curvature (PR #264, open).
Merged: PR #263. Recorded, not fixed: C2 (GP1 link guard), C3 (silent `K = maximum(y)`),
C5 (unguarded `X` in lognormal), C6 (mixed-family `missing` warm start), C7 (six fit types
with no `confint` dispatch). Wording corrected: C4 (multinomial ledger clause).

## 8. Consistency Audit

- **Interpolation class** — swept `src/` for `"…$var[…"`: **exactly one** occurrence.
  Isolated, not a pattern.
- **Fail-loud class** — link guards exist in **5 of ~34** family files, all recent. The
  documented "only supported link is LogLink()" contract is unenforced; a mis-linked fit
  converges and returns a plausible wrong answer. Recorded, not patched (behaviour change).
- **Module-membership class** — **8 `src/` files are included nowhere**; `CLAUDE.md:49-56`
  documents six as components. README and `docs/src/` do not, so the drift is
  agent-facing, not public.
- **Fault-class census** — the class grew 8 → 11 → **13** during this arc.

## 9. What Did Not Go Smoothly

- **The handover was wrong in four places**, each checked rather than trusted: the
  DeltaGamma suite had not died with its session (it died later, by SIGTERM, at ~46 min);
  CI was running, not idle; #254 had been closed; the class was larger than recorded.
- **The check-log itself carried two false claims** — DeltaGamma marked "fixed" when no
  branch had the fix, and a wrong fix-site citation for NB1.
- **The drafted family docs came back CORRECTIONS on 6 of 7 sections (33 errors)**,
  including an example that could not run. Verification, not drafting, was the value.
- **M4's oracle premise was false.** Gamma 12/12 closer under `:observed`; **Beta 2/12**.
  Checked the fallback against an independent formula (1.8e-14) before concluding.
- A `gh run watch` died on an API 502 and I initially read `CI_EXIT=1` as a CI failure.
  Corrected in the same session.

## 10. Known Residuals

- **The class is NOT closed.** The selector reaches **1 kernel of 13**. Twelve build their
  own `logdet` — including live surfaces `covariates.jl:52-69` and `mixed.jl:249-254`.
- **The flip (commit B) is not done** and now carries a measured new risk: Beta's observed
  curvature is **negative** at reachable `(η, y)`, so flipping can drive Beta into the PD
  guard → `-Inf` → with the `1e12` sentinel, a *declared convergence*.
- **`test/parity/` never runs** in `runtests.jl` or CI. R-parity is local-only.
- **GP1 (#12) confirmed but unpatched**; **mixed.jl (#13)** unpatched.
- CensoredPoisson's `max(W,0)` clamp: whether it can bind is **UNVERIFIED**.
- PR #264 unmerged (human merges).

## 11. Team Learning

**Writing the documentation was the audit.** Five of the seven code findings surfaced only
because someone had to describe the families precisely enough for a user. Documentation
gaps and correctness gaps were the same gap.

**Measure the oracle before asserting it.** M4 read as obviously true and was false for
Beta. Had it been written as an assertion first, the natural repair would have been to
loosen it until it passed — converting a refutation into a rubber stamp.

**"Correct" and "closer to the truth" are different claims.** This arc is a **parity**
change, not an accuracy improvement. Gamma improves sharply; Beta does not.

## 12. Cross-Product Coverage

The `hessian` selector is a cross-cutting switch. On the product axis:

**Covers ✓** — the generic core `laplace.jl` and every family reaching it through
`marginal_loglik_laplace` / `laplace_loglik_site`.

**Does NOT cover ✗** — twelve kernels that build their own `Λ'WΛ + I` and `logdet`:
`grouped_dispersion.jl` (incl. Tweedie, which has no selector), `covariates.jl`
(backing `fourthcorner.jl`, `species_covariates.jl`, `constrained_ordination.jl`,
`row_effects.jl`), `quadratic.jl`, `mixed.jl`, `spde_latent.jl`, `aghq_grid.jl`,
`phylo_glm.jl`, `phylo_nb_xlv.jl`, `phylo_beta_xlv.jl`, `phylo_gamma_xlv.jl`,
`phylo_binomial_xlv.jl`, `coevolution_glm.jl`, `truncated_nbinom2.jl` (own kernel).

**Does NOT cover ✗** — the two-part substrate (`twopart.jl`); DeltaGamma is fixed
separately in PR #264.

**Does NOT cover ✗** — `confint`/`vcov`: the Wald Hessian is a finite-difference Hessian
of whatever objective it is handed, so it inherits the weight but has no coverage test to
detect miscalibration.

**Does NOT cover ✗** — the analytic gradient paths. `laplace_grad.jl:156`/`:221-222`/`:302-303`
remain matched to the **Fisher** log-det. Commit A is safe only because the default did
not move; commit B must change them in the same commit.

## Rose verdict

**Not independently audited.** Every load-bearing claim ships as a live assertion or a
reproducible command. The one claim I most want a second pair of eyes on is the Beta
direction-of-change result, because it reverses an expectation the whole programme has
been carrying.
