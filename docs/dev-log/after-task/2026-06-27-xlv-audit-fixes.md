# After Task: act on the multi-agent X_lv subsystem audit

**Date**: `2026-06-27`
**Executed by**: Claude (Codex on leave), via the `xlv-finish-audit` workflow.

## 1. The audit

A multi-agent adversarial audit (`xlv-finish-audit`, 41 agents) reviewed the
landing X_lv CI subsystem across 8 dimensions (the `_fd_hessian` fix, the Wald
delta-method, the bootstrap, the bridge CI wiring, the family slices, the R
admission, test coverage, doc claims), adversarially verified every finding, and
synthesised a finish-the-group plan. **30 findings confirmed real.**

## 2. Must-fix applied (this commit + the R branch)

- **BLOCKER — Gaussian bootstrap transpose.** `_lv_boot_fns(::GllvmFit)` computed
  the score mean as `X_lv * alpha_lv'` instead of `X_lv * alpha_lv` (α_lv is
  q_lv×K). For q_lv≠K this `DimensionMismatch`es on every replicate → swallowed →
  `n_converged=0` → silent all-NaN; for q_lv==K>1 it draws from the wrong mean. It
  hid because every Gaussian fixture was q_lv==K==1 (transpose = no-op) and only
  Poisson bootstrap was tested. **Fixed**; added a Gaussian **K=2** bootstrap test
  (asserts `n_converged ≥ 25` — would be 0 under the bug) plus bootstrap smokes for
  binomial / NB2 / Gamma / Beta (all six families now have bootstrap coverage).
- **Docstrings + comment** said the X_lv CIs are admitted for `K = 1` only — the
  opposite of the shipped `K ≥ 1` relaxation (B_lv rotation-invariant). **Fixed**
  both `confint_lv_effects` docstrings and the internal comment.
- **Gaussian fixed-`X` guard.** The `GllvmFit` path had no `q==0` guard; a direct
  `fit_gaussian_gllvm(...; X=X, X_lv=X_lv)` would silently mis-extract (read β as
  α). Added `isempty(fit.pars.β) || throw(...)`. (The bridge already rejects it.)
- **Gamma/Beta bootstrap refit** now thread `link = fit.link` for parity with the
  Poisson/Binomial/NB closures.
- **CHANGELOG** (`Unreleased`): added a `Fixed` entry for the package-wide Wald-SE
  bug and an `Added` entry for `confint_lv_effects` (Wald + bootstrap, K≥1, six
  families) + the bridge `ci_method="wald"` fields, scoped honestly (R-side CI
  reading explicitly noted as not wired).
- **R branch** (`claude/nbgammabeta-xlv-r-20260627`): added
  `skip_if_not_installed("glmmTMB")` to the new mocked test — it eagerly builds
  `glmmTMB::beta_family()` (a Suggests-only dep), which **errored** (not skipped)
  under `--no-suggests`/CRAN.

## 3. Validation

- `test/test_lv_ci.jl` → **89/89** (was 81; +8 bootstrap tests incl. the Gaussian
  K=2 transpose guard).
- R test file parses (`Rscript -e parse`).

## 4. Deferred to a post-land cleanup (confirmed minor/nit)

Stale `_BRIDGE_XLV_FAMILIES` error-message lists (Julia bridge + R) omitting
negbinomial/gamma/beta; missing spaces in five `xlv_note` strings; `pd_hessian`
naming (reports invertibility, not PD); a few dev-log number/label slips; the
Gaussian packed-layout comment's stray `[beta(q);` token. Tracked for a single
cosmetic follow-up — none affect correctness.

## 5. Genuinely still unbuilt (per the audit, unchanged)

R-side reader of the Julia X_lv CI fields (the bridge payload is dead on the R
side until the gate is lifted + `extract_lv_effects` plumbs lower/upper/se);
profile CIs; q_lv>1 is structurally untested; non-Poisson/larger-K direct
recovery+coverage; mixed-family, X+X_lv, masks, W-tier, structured sources.
