# Second-order parity contract — DEFAULTED 2026-09-04 (D1/D2; Option A + Ada defaults)

Status: **DEFAULTED 2026-09-04** — tolerances per D1; `cond(H)` scaling uses **R's
number** per D2 with both recorded in every receipt. Extends, does not replace, the
first-order contract in `docs/dev-log/core070/delta-matched-contract.md`. Oracle:
frozen `gllvmTMB` 0.7.0 export surface, commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86` (capability-status join uses
`origin/main` on both repos — that file post-dates the oracle pin).

## 1. Scope

Second-order parity (maintainer decision, 2026-09-02) means agreement of
three quantities per family: (a) standard error (SE) of every fixed
parameter (β, dispersion, per-trait ν, loadings, on the working scale — §3); (b) the
fixed-effect vcov block (`vcov()` in R; `ForwardDiff.hessian(nll,θ̂)⁻¹` in
Julia, `src/confint.jl:1-9,278`); (c) Wald CI endpoints on the link scale.

Today none of this is compared: all 40 paired cells run with `se = FALSE`
(`test/parity/parity_helpers.jl:374,476,545,638,707`, every
`gllvmTMBcontrol(n_init = 1L, se = FALSE)`), confirmed by the panel:
*"Nothing second-order is compared anywhere (se=FALSE throughout...)"*
(`docs/dev-log/core070/parity-panel-2026-09-01.md:24-27`).

**Out of claim:** fitted/`predict()`/residuals — first-order quantities,
would conflate evidence tiers; paired recovery-to-truth — a different
question (is the estimator right vs do two implementations agree); DRAC
coverage (§6) speaks to Julia alone, not R↔Julia agreement.

## 2. Hessian convention (FROZEN — argued, not changed)

**TMB.** `MakeADFun(..., random=...)` differentiates the coded joint
negative log-likelihood; its Laplace log-det is the **observed** joint
Hessian, structurally: *"Its Laplace log-determinant therefore uses the
observed joint Hessian, structurally and without ever making a choice
about it"* (`docs/src/gllvmtmb-parity.md:217-222`). `sdreport()` is the
targeted accessor: *"`vcov()` returns their covariance matrix, taken from
the fit's TMB `sdreport()`"* / *"The fixed-effect block of the single TMB
`sdreport()` the fit already [has]"*
(`.unlazy/core070-aghq/oracle-source/readback/R/vcov-coef.R:16,40`).

**Exact mechanism — AGENT-INFERRED** (Kristensen et al. 2016 *JSS*, not
confirmed by reading TMB's C++). Default call has no `getJointPrecision`
(confirmed absent: *"`sdreport(getJointPrecision = TRUE)`, which this fit's
single production `sdreport()` call does not request"*,
`.../readback/R/re-uncertainty.R:62-63`), so fixed-effect covariance is the
inverse Hessian of the **Laplace-marginal** NLL w.r.t. fixed parameters —
by the implicit function theorem this equals the Schur complement of the
observed **joint** Hessian after eliminating random effects. "Inverse of
the marginal Hessian" and "fixed block of the inverse joint Hessian" are
the same number here, not competing descriptions; no file read for this
ticket states that identity in words, hence AGENT-INFERRED.

**Julia.** `confint(fit; y=...)` reconstructs the same packed marginal NLL
the fitter minimized, takes `H = ForwardDiff.hessian(nll, θ̂)`, `Σ = inv(H)`
(`src/confint.jl:246-290`) — the same Schur-complement identity, since
`nll` already *is* the Laplace marginal. Which curvature enters that
marginal's log-det is `hessian::Symbol`, generic default `:fisher`
(`src/families/laplace.jl:225-235`).

**Fisher-retained families — one sentence each, source read today (HEAD
`df7009b3`):**

- **GP-1**: no override in `src/families/gp1.jl` → falls to generic
  `:fisher` (`src/families/laplace.jl:235`). Confirmed Fisher-retained,
  matching `DEFERRED_BY_DECISION keeps GP-1`
  (`docs/dev-log/decisions/2026-08-28-arc-decision-batch.md:42`); reason:
  *"Observed curvature is genuinely negative for Beta, Student-t and
  GP-1... a minority of cells derail badly under the observed weight"*
  (`src/families/laplace.jl:332`).

- **Binomial-cloglog — STALE IN THE BRIEF, flagged not resolved.** The
  2026-08-28 batch kept it Fisher (*"cloglog stays Fisher — intrinsic
  saturation pathology"*,
  `docs/dev-log/decisions/2026-08-28-arc-decision-batch.md:10`; still what
  `docs/src/gllvmtmb-parity.md:229-232` says). But
  `src/families/binomial.jl:95` currently reads `_default_hessian(::Binomial,
  ::CLogLogLink) = :observed`, dated *"CONFIRMED (2026-09-01, maintainer
  decisions round 1, item 2)... matches R to 7.4e-12... `:fisher` was a
  genuine Julia-side defect"* (`src/families/binomial.jl:74-90`); the
  round-1 note itself only authorized *opening* the investigation
  (`docs/dev-log/decisions/2026-09-01-maintainer-decisions-round1.md:8-10`).
  Cannot pick a side here: either cloglog is already repaired (drop from
  exclusions, update `gllvmtmb-parity.md` under the cascade rule) or the
  flip needs reverting. Excluded as a precaution until signed; receipt
  reason must say "disputed default" (§5), not restate 2026-08-28 as
  settled.

- **Tweedie grouped — SAME STALENESS.** Brief says "no selector," matching
  the historical defect (`src/families/grouped_dispersion.jl:1596-1602`),
  but current HEAD already has `hessian::Symbol = :observed`
  (`src/families/grouped_dispersion.jl:1630-1633`, *"this grouped route now
  reduces EXACTLY to the shared route under ITS default"*, lines
  1611-1613). Flag identically; exclude pending resolution.

Net: only **GP-1** is confirmed current-HEAD Fisher-retained; cloglog and
Tweedie-grouped read as already flipped — surfaced, not resolved.

## 3. Parameter alignment

**Pair one-to-one:** β (linear kind, `src/confint.jl:60-77`); shared
dispersion on a common natural scale — NB2 `r` (`Var=μ+μ²/r`, matching
`log_phi_nbinom2`, `docs/src/response-families.md:242`), Beta `φ`
(`docs/src/response-families.md:416`), both log-scale-optimized,
back-transformed identically (`:log_sd` kind); per-trait dispersion when
`disp_group=:species` matches on both sides (frozen call shape,
`delta-matched-contract.md`).

**Do NOT pair without extra work:**
- **Loadings Λ, up to rotation.** `(ΛQ)ᵀ(ΛQ)=ΛᵀΛ` is invariant, a raw
  entry is not (`docs/dev-log/core070/surface-conversion-notes.md:565-566,586-587`).
  Comparing raw per-entry SEs compares two arbitrary rotations and fails
  even for identical models. **Recommend comparing SEs of
  rotation-invariant derived quantities** — Σ_y entries, communality c²,
  cross-trait correlation (`src/confint_derived.jl`,
  `src/confint_derived_wald.jl`; already matches bootstrap to MC error).
  Alternative — Procrustes-align Λ first (`_svd_rotation`,
  `docs/dev-log/core070/extractors-slice-notes.md:60,137-139`) — adds an
  extra transform whose own uncertainty would need propagating; derived
  quantities avoid that.
- **Per-trait Student-t ν.** `disp_group` is `:shared` or `:species`
  (`src/families/studentt.jl:357`); needs identical grouping on both
  sides, and ν sits on a nonlinear boundary where Wald SEs misbehave
  (nu→∞ flagged, `parity-panel-2026-09-01.md:66-70`). Excluded from batch 1.
- **Grouped nuisance vectors generally** (NB1/Beta/Gamma per-species φ) —
  one-to-one only when `disp_group` matches exactly.

## 4. Tolerances

Not copied from first-order (absolute logLik ~1e-10, native gradient
~1e-6, `point_gradient_delta<=1e-6`,
`test/parity/test_gaussian_original_required.jl:45`): an SE is a second
derivative through an inversion — roughly one differentiation order worse,
scaled by local conditioning.

**Error classes:** (1) optimizer termination error propagated through H —
first-order native gradients run ~1e-6, refined R gradients ~1e-5
(`delta-matched-contract.md` table), bounding achievable relative SE
agreement to ~1e-4–1e-3, not 1e-6; (2) FD-vs-AD Hessian — both sides here
are AD (`ForwardDiff.hessian` / TMB `MakeADFun`), removing the FD
truncation error that forced the first-order contract's separate
"refined R" column (*"Default R max gradient... failed"*), so require
**refined** R nlminb tolerance (`rel.tol=1e-12`) for every second-order
cell; (3) matched-optimum vs each-own-optimum — two tiers, below; (4)
conditioning — Panel C measured a 2.2e-2 rotation-invariant discrepancy at
condition number ~1e6, curvature ~4.7e-4
(`parity-panel-2026-09-01.md:29-32`), so tolerance must scale with
conditioning, not be a single absolute bound.

| Quantity | Matched-coordinates | Each-own-optimum |
|---|---|---|
| SE — standard errors (β, shared dispersion) | rel ≤ 1e-4, or abs ≤ 1e-6 if SE ≤ 1e-2 | rel ≤ 1e-2, ×`cond(H)/1e3` when `cond(H)>1e3` |
| vcov block (‖ΔΣ‖_F / ‖Σ_R‖_F) | ≤ 1e-4 | ≤ 1e-2 (same conditioning scaling) |
| Wald CI endpoints (link scale) | ≤ 1e-4 abs, or SE tolerance propagated through θ̂±z·SE if θ̂ differs | ≤ 5e-2 relative to interval half-width |

**The claim uses each-own-optimum.** Matched-coordinates is the
diagnostic isolating curvature-formula disagreement from
optimizer-termination disagreement (mirrors the existing cross-objective
and `point_gradient_delta` diagnostics,
`parity-panel-2026-09-01.md:65-70`); a real user compares two
independently-fitted models, so each-own-optimum ships, always reported
alongside its matched-coordinates diagnostic for attribution.

**Conditioning scale (D2, DEFAULTED 2026-09-04):** when `cond(H)>1e3`, the
each-own-optimum relative tolerances multiply by **`cond(H)_R / 1e3`**, where
`cond(H)_R` is R's fixed-effect precision condition number from `sdreport()`.
Julia's `native_condition_number` is recorded alongside for attribution only —
different parameterisations can yield different condition numbers at the same optimum.

## 5. Receipt fields

Additions to the cell TOML (`test/parity/core070_receipts.jl:172-186`,
`record_case!`) — none exist today:

| Field | Type | Writer | Notes |
|---|---|---|---|
| `hessian_selector` | string | Julia | `"observed"`\|`"fisher"`, per `_default_hessian` |
| `hessian_selector_disputed` | bool | Julia | `true` for cloglog/Tweedie-grouped until §2 resolves |
| `matched_coordinates` | bool | Julia | both engines' Hessians at the same θ, vs each-own-optimum |
| `se_max_relative_delta` | float | Julia | max `\|SE_jl−SE_r\|/SE_r` |
| `vcov_frobenius_relative_delta` | float | Julia | `‖Σ_jl−Σ_r‖_F/‖Σ_r‖_F` |
| `ci_endpoint_max_delta` | float | Julia | max abs link-scale endpoint diff |
| `native_condition_number` | float | Julia | `cond(H)`, generalizes existing `hessian_min_eigenvalue` (`test/parity/covariance_formula_cases.jl:42`) |
| `r_condition_number` | float | R | condition number of `sdreport`'s fixed-effect precision |
| `pd_hessian_native` | bool | Julia | `confint`'s `pd_hessian` return field |
| `pd_hessian_r` | bool | R | `sdreport()`'s `pdHess` |
| `derived_quantity` | string\|nothing | Julia | which rotation-invariant quantity (§3) a loading-related cell used |

## 6. Cells — first second-order batch

**Batch 1: Gaussian, Poisson-log, Binomial-logit, Beta-logit, NB2-log.**
Exactly the five families the DRAC Wald-coverage campaign already fit,
with empirical coverage 0.932–0.958 at 95% nominal on per-trait β
(`docs/dev-log/core070/drac-coverage-campaign-findings.md` table) —
independent evidence Julia's own SE machinery is approximately sane before
any R comparison, lowering the risk that a tolerance failure is a Julia
bug rather than a contract-tuning issue. They span the curvature landscape
cleanly: Gaussian has no curvature choice; Poisson-log/Binomial-logit are
canonical (Fisher≡observed exactly, CLAUDE.md "Status"); Beta-logit/NB2-log
are the two families explicitly flipped to `:observed` on curvature
evidence (`docs/src/gllvmtmb-parity.md:238-247`, "2026-08-27... decision
A"). None touches the disputed cloglog/Tweedie-grouped defaults or the
Student-t/GP-1 boundary issues.

**Need a decision first:** Binomial-cloglog, Tweedie (shared+grouped) —
blocked on §2's disputed default; GP-1 — Fisher-retained by standing
decision, needs a ruling on whether "parity" means comparing against a
TMB Fisher alternative (if one exists) or is declared out of scope
alongside the existing logLik exclusion; Student-t — ν boundary repair
(§3, panel finding 4) needed first; Ordinal/Delta-lognormal/Delta-Gamma/
Tweedie/GP-1 grouped nuisance vectors — no `disp_group` pairing convention
chosen yet (§3).

## 7. What this contract does NOT claim

A future passing 5-cell run of this batch is not a second-order parity
claim. It is a pre-run on the existing toy-fixture shape (p≤5, K≤2, n≤150,
`parity-panel-2026-09-01.md` mandated qualifier): it proves the SE/vcov/CI
machinery is wired correctly end-to-end and gives a first tolerance read —
it does not prove the tolerances hold at realistic shape or conditioning
(Panel C: 1.4e-7 logLik agreement coexisted with 2.2e-2 rotation-invariant
discrepancy at higher condition number, same doc lines 29-32), does not
cover the families/groupings held out in §6, does not resolve §2's
disputed-default finding, and is not a recovery-to-truth or coverage claim
(that evidence exists only for Julia alone,
`drac-coverage-campaign-findings.md`). The panel's qualifier applies here
with the same force: state fixture shape and cell count alongside any
second-order pass/fail, every time.

### Measured status (2026-09-05 — NOT DONE)

**Programme §7 / second-order programme completion: NOT DONE.** A passing
each-own-optimum batch, a matched-coordinates pilot, or a toy pre-run does
not close §7. True parity and the full second-order programme remain tracked
in `docs/dev-log/core070/true-parity-decision-map.md`.

**Matched-coordinates tier: NOT implemented.** Contract §4 defines the tier;
receipts still ship **each-own-optimum only** (`matched_coordinates=false` in
`tools/core070_second_order/cells.jl`). The batch-1 pilot
(`docs/dev-log/core070/second-order-matched-pilot-batch1-20260905.md`, merged
#285 @ `987c293d`) measured **3 pass / 2 blocked / 0 fail / 0 skip** on five
cells:

| Cell | Status | Blocker |
|---|---|---|
| gaussian, poisson, binomial_logit | **pass** | — |
| beta_logit, nb2_log | **blocked** | R per-trait `log_phi_*` (×p) vs Julia shared log-dispersion (×1); no honest θ map without changing one side |

Disposition detail: `docs/dev-log/core070/second-order-matched-coordinates-2026-09-04.md`.
Do not read 3/5 pilot pass as closing programme §7 or as a shipped
matched-coordinates tier.
