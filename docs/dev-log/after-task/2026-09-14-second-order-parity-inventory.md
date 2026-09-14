# After-task — second-order parity inventory (prep-only)

**Date:** 2026-09-14  
**Lane:** Cursor / Ada (true-parity programme)  
**Branch:** `docs/second-order-parity-inventory-20260914` (from `origin/main`; separate from `cursor/issue-323-totoro-launch-pack`)  
**Scope:** Read-only inventory — **no** Totoro/DRAC campaigns, **no** engine edits, **no** `Project.toml` bump, **no** promotion of second-order parity or programme §7 closure.

## Programme anchors

| Item | Path |
|------|------|
| Destination | `docs/dev-log/core070/true-parity-decision-map.md` |
| Second-order contract (T3, signed tolerances) | `docs/dev-log/core070/second-order-parity-contract.md` |
| LOOP arcs | `LOOP/arcs.md` (#16 T5 partial 7/8, #22–#25, #323 handoff) |
| Goal gate | `LOOP/GOAL.md` — **#323** executed (receipt) **or** maintainer **`waive #323`** before downstream true-parity claims |
| #323 disposition | **NOT DONE** — `docs/dev-log/decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md` remains **PENDING_ACCEPTANCE** (issue [#323](https://github.com/itchyshin/GLLVM.jl/issues/323) **OPEN**) |

## What “second-order” means (T3)

Per maintainer decision **2026-09-02** (recorded in `true-parity-decision-map.md` and contract §1), second-order parity is **R↔Julia agreement on inference at the fixed-parameter optimum**, not on fitted values or recovery-to-truth:

1. **Standard errors (SE)** of every fixed parameter on the working scale (β, shared/per-trait dispersion where paired, loadings only via rotation-invariant derived quantities — contract §3).
2. **Fixed-effect vcov block** — R `vcov()` from TMB `sdreport()` vs Julia `inv(ForwardDiff.hessian(nll, θ̂))` on the same Laplace-marginal NLL (`second-order-parity-contract.md` §2).
3. **Wald confidence-interval endpoints** on the link scale.

**Explicitly out of the parity claim:** `fitted` / `predict` / `residuals`; paired recovery-to-truth; Julia-only DRAC **coverage** (wiring sanity only, not R agreement).

**Tolerance tier shipped in receipts today:** **each-own-optimum** (contract §4) — both engines fit independently; R `cond(H)` scales relative gates when `cond(H) > 1e3`. **Matched-coordinates** (same θ on both sides) is diagnostic only and is **not** fully wired for all batch-1 families.

**Hessian convention (frozen):** observed joint / Schur-complement marginal on both sides; per-cell `hessian_selector` recorded. **GP-1** remains Fisher-retained on Julia; **binomial-cloglog** and **Tweedie grouped** defaults are **disputed** (contract §2) — receipts may run with `hessian_selector_disputed=true` but **no claim** until signed.

## Measured wiring status (not a parity claim)

| Layer | Status | Evidence |
|-------|--------|----------|
| Toy 20-cell each-own-optimum | SE **20/0** fail; CI **20/0**; vcov **15 pass / 5 skip** (NB2 full-block boundary) | `second-order-batch-2026-09-03.md`; merged-tip refresh in `second-order-d1-gate-receipt-2026-09-04.json` |
| Batch-1 five families (each-own) | **5/5** D1 pass on toy shape | Same JSON `post_merge_smoke` |
| Realistic-size paired (24 cells) | First-order logLik **24/24** ≤1e-4 after idx 9/17 repair; SO metrics **24/24** with SE/vcov/Wald D1 **24/0/0** among β cells | `second-order-d1-gate-receipt-2026-09-04.json`; `realistic-size-pairing-disposition-2026-09-04.md` |
| Programme §7 / true second-order parity | **NOT DONE** | Contract §7; JSON `goal_complete_second_order_objective: false` |
| Matched-coordinates tier | **NOT implemented** (pilot only) | `second-order-matched-coordinates-2026-09-04.md` |

## Blocked cells — matched-coordinates (θ-map)

Pilot `run_matched_batch1.jl` (**2026-09-05**, PR #285): **3 pass / 2 blocked / 0 fail** at matched-coordinates tier (`second-order-parity-contract.md` §6 table; detail in `second-order-matched-pilot-batch1-20260905.md`).

| Cell | Matched-coordinates | Blocker |
|------|---------------------|---------|
| `gaussian` | pass | — |
| `poisson` (log) | pass | — |
| `binomial_logit` | pass | — |
| **`beta_logit`** | **blocked** | R **per-trait** `log_phi_*` (length **p**) vs Julia **shared** log-dispersion (length **1**); no honest θ transplant without changing parameterization on one side |
| **`nb2_log`** | **blocked** | Same structural mismatch (R per-trait φ vs Julia shared **r** on default paired fixture) |

**Disposition options (next construction slice, docs + θ-map only until maintainer picks):** (a) align fixtures to shared-φ on both sides; (b) extend Julia grouped route to match R per-trait packing for these two families only; (c) sign **permanent matched-coordinates OUT** for beta/NB2 default bridge cells and keep each-own-optimum only.

Each-own-optimum receipts for **beta_logit** and **nb2_log** can still pass (measured on toy batch); blockage is **only** the matched-coordinates diagnostic and any claim that both curvatures were evaluated at identical θ.

## Blocked / held-out families (contract §6)

Frozen list: `second-order-holdouts-2026-09-04.md` (Option D disposition **2026-09-05**). Summary for executors:

| Holdout | Why blocked | Receipt class allowed |
|---------|-------------|------------------------|
| Binomial-cloglog | §2 disputed `:observed` vs Fisher note | Each-own with `hessian_selector_disputed=true`; **no claim** |
| Tweedie shared + grouped | Disputed default; no paired toy cell in 20-cell arc | **NOT ATTEMPTED** |
| GP-1 | Fisher-retained; no ruling on R comparator | **OUT** |
| Student-t (free ν) | ν boundary; no `_CIFit` Wald | **OUT** |
| Ordinal per-trait | No Wald on `OrdinalPerTrait*Fit` | **OUT** (API gap) |
| Lognormal, Truncated-Poisson, Truncated-NB2 | No Wald `_CIFit` dispatch | **OUT** (API gap) |
| Delta-lognormal, Delta-Gamma | In `_CIFit`; not in 20-cell window | Follow-up batch |
| Multinomial, BetaBinomial shared-φ | 20-cell arc paired per-trait φ only | Follow-up batch |
| Loadings Λ raw entries | Rotation (§3) | Derived Σ_y / communality / correlation only |
| **NB2-log (batch-1 note)** | **PARTIAL** — each-own D1 OK; matched-coordinates blocked; vcov full-block skip on boundary | See T14 disposition (`2026-09-14-destb-g5-t14-nb2-wald-nan.md`) |

## Programme gates before “execute second-order at scale”

| Gate | State | Notes |
|------|-------|-------|
| **#323** advisory Frozen R smoke | **OPEN** — execution pack ready | `2026-09-14-destb-g7-frozen-r-smoke-handoff.md`; Codex/Totoro **after D-139 ack**; separate branch `cursor/issue-323-totoro-launch-pack` |
| T5 `PARTIAL_PARITY_DEFECT` re-bind | **7/8** — arc not closed | Row 8 `loading_profile` → `BLOCKED_NEEDS_JULIA_SURFACE` (D3); `2026-09-14-t5-partial-defect-inventory.md` |
| T4 realistic-size **campaign** | **Blocked on compute allocation** | Grid closed Ada-default: Gaussian, Poisson, NB2; p∈{20,50}, n∈{500,2000}; one pre-run cell done — full grid **Totoro** (`LOOP/arcs.md` #22) |
| T7 real-data workflows | **Blocked** | gllvmTMB PR **#1236** merge (`LOOP/arcs.md` #23) |
| Contract §2 stale defaults | **Unresolved** | cloglog / Tweedie-grouped — cascade or revert before promoting cells |

**Verdict:** Prep and local D1 receipts exist; **programme execution** of the next second-order tranche stays **behind #323 disposition** per `LOOP/GOAL.md` (receipt **or** documented waive — **not** inferred from handoff alone).

## Next executable slices (ordered, after #323 gate)

These are **bounded** next steps; none closes programme §7 or true parity destination alone.

1. **#323 Track A on Totoro** — mirror CI `test-parity` frozen build; three gradient-health cells (`NATIVE-06-NB2`, `NATIVE-12-TRUNCATED-NB2`, `NATIVE-10-STUDENT`); receipt JSON + issue comment; **does not** close issue unless advisory-green **and** maintainer sign-off (`2026-09-14-destb-g7-frozen-r-smoke-handoff.md`).
2. **Matched-θ disposition slice (beta_logit, nb2_log)** — engineering spike or signed permanent OUT; update `second-order-matched-coordinates-2026-09-04.md` + `tools/core070_second_order/theta_map.jl` contract; **no** campaign required for (c); (a)/(b) need maintainer parameterization choice.
3. **T4 realistic-size second-order campaign** — Totoro batch over closed grid (24+ cells beyond existing repair archive); D-139 pre-run one cell if grid shape changes; record `cond(H)_R` on every receipt per contract §4.
4. **Follow-up second-order batch (API gaps)** — add Wald dispatch + paired cells for Delta-lognormal/Delta-Gamma; then Ordinal/Lognormal/Truncated families per holdout table (engine + `confint_family.jl` slices).
5. **§2 disputed-default resolution** — single maintainer decision on cloglog/Tweedie-grouped; then either promote cells or keep `hessian_selector_disputed` forever in receipts.
6. **T5 row 8 (`loading_profile`)** — Julia surface/backlog (D3); independent of second-order machinery but blocks LOOP #16 closure.

## Compute target

| Work | Host | D-139 / D-50 |
|------|------|----------------|
| **#323** Frozen R smoke | **Totoro** (Codex lane); single Julia process | **Maintainer ack before spend** (G0 Q3; handoff §Track A) |
| Toy / batch-1 re-smoke (≤20 cells) | Local laptop OK (precedent: ~49s–602s wall, 1 thread) | Under 30-minute line — no campaign |
| **T4 realistic-size grid** (full) | **Totoro-first**; DRAC only with maintainer approval | Pre-run one cell per family before full parallel batch |
| Large recovery / coverage | **Not in this inventory** | Totoro/DRAC only; never GitHub Actions artifacts (D-50) |

Environment pins for R-side work: frozen `gllvmTMB` **`b4d5fee64def88bc768dda1f1f77c29b295edd86`**, R **4.5.3**, Posit PPM snapshot per `frozen-r070-contract.toml` / CI.yml (local R 4.6.x Track B was **BLOCKED→Totoro** in G7b).

## Rose fence (this document)

- **≠** #323 executed, waived, or closed.
- **≠** second-order parity, matched-coordinates parity, or true parity destination reached.
- **≠** T5 arc closed (7/8 only).
- **=** inventory of blockers, definitions, and ordered slices for post-#323 execution planning.

## Checks run (this slice)

- Read: `true-parity-decision-map.md`, `second-order-parity-contract.md`, `LOOP/arcs.md`, holdouts + matched-coordinates dispositions, `second-order-d1-gate-receipt-2026-09-04.json`, #323 pending decision + G7 handoff.
- **Not run:** `Pkg.test()`, Documenter, Totoro, any `tools/core070_second_order` driver.

## Top 3 recommended next slices (for maintainer G0)

1. **#323 Totoro execution** (or explicit **`waive #323`**) — programme gate; use `cursor/issue-323-totoro-launch-pack` / G7 handoff.
2. **Matched-θ disposition for `beta_logit` + `nb2_log`** — unblock or permanently fence matched-coordinates tier.
3. **T4 realistic-size second-order campaign on Totoro** — Gaussian / Poisson / NB2 grid after D-139 ack.
