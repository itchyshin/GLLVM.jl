# Maintainer decision set — Core 0.7.0 parity close (2026-09-03)

Six decisions the lane cannot make for itself. Each has a recommendation and a default; a
"use your judgment" answer takes the default and is recorded as such. Nothing below is
blocking further *reversible* work — they gate what the parity claim is allowed to say.

Companion evidence: `second-order-parity-contract.md`, `t5-rebind-2026-09-03.md`,
`t8-aghq-policy-rows-proposal.md`, `t12-grouping-levels-design.md`,
`realistic-size-grid-2026-09-03.md`.

---

## D1 — T3: sign the second-order tolerances

**Question.** Do the drafted SE / vcov / Wald-endpoint tolerances become the contract?

**What the receipts now show** (they did not exist when the draft was written):
20 paired toy cells — SE relative Δ median 6e-6, max 1e-4; Wald endpoints max 3e-5.
22 realistic-size cells (p ≥ 20, n ≥ 500) — no delta above the draft tolerances.
So the *each-own-optimum* tier (rel ≤ 1e-2, scaled by cond(H)/1e3) is not being
approached; the measured data sit two orders inside it.

**Recommendation: sign as drafted.** The draft is loose relative to what the engines
actually do, which is the right direction for a contract — it will not fail on a
conditioning-driven wobble, and the matched-coordinates diagnostic (rel ≤ 1e-4) is the
tight number that would catch a real curvature-formula divergence.

**Cost of tightening instead:** a contract at rel 1e-5 would pass today and start
failing on optimizer-termination noise the first time a family's convergence criteria
change. Default if unanswered: sign as drafted.

---

## D2 — cond(H): which engine's number does the contract's scaling use?

**Question.** The each-own-optimum tolerance scales by `cond(H)/1e3`. On the largest
realistic-size cell the two engines report **858 (Julia) vs 14 138 (R)** — a 16× gap,
on the same data at the same optimum.

**Why they differ:** different parameterisations, not different curvature. Julia
optimises log-scale dispersions and a packed lower-triangular Λ; R's TMB parameter
vector carries its own scaling. Condition number is not parameterisation-invariant, so
both numbers are correct about different coordinate systems.

**Recommendation: the contract names R's cond(H)**, because R is the oracle and the
claim is "R workflows run identically through Julia" — the tolerance should widen when
*the reference problem* is hard, not when our parameterisation happens to be tidy.
Record both in every receipt.

**Cost of choosing Julia's instead:** the tolerance would narrow exactly on the cells
where R's own SEs are least trustworthy. Default if unanswered: R's, both recorded.

---

## D3 — `loading_profile`: estimand scope

**Question.** R's `loading_profile()` profiles a Λ entry on a **confirmatory**
(pinned-loadings) fit. GLLVM.jl's `loading_profile` profiles an **exploratory**
(unpinned) fit. Same name, different estimand. Is that a parity defect or a deliberate
Julia extension?

This is the **last of the 8 estimand-defect rows still un-rebound** (7 of 8 re-bound on
frozen-oracle receipts; BOUND 285 → 292). It cannot be settled by re-running anything —
no batch exercises R's accessor, because our fixture is exploratory.

**Three answers, all defensible:**
- **(a) Julia gains a confirmatory gate** matching R → the row binds; costs a
  `lambda_constraint`-equivalent surface we do not have.
- **(b) Rename ours** (`loading_profile_exploratory`) and mark the R row
  `needs-surface` → honest, cheap, but a user-facing rename.
- **(c) Declare it out of the parity family** → cheapest; the ledger keeps one
  dispositioned row forever.

**Recommendation: (b).** The collision is the name, not the mathematics; renaming makes
the gap visible in the API instead of hiding it behind a matching signature.
Default if unanswered: (c), recorded as a named exclusion, revisitable.

---

## D4 — T8: reclassify 8 AGHQ policy rows?

**Question.** 22 AGHQ rows are `BLOCKED_SPEC_DEFECT` ("name an exact native policy
call"). Analysis of the frozen oracle's production call site finds **14 bindable** via a
public same-model fit (read `fit$aghq$k` / `$used` / `$reason`), and **8 not publicly
reachable at all** — they force values (`gate_table=NULL`, a column-dropped gate,
`n_traits=NA`, `route="laplace"` under an eligibility check that excludes it) that
`.aghq_auto_decide` never receives from a real fit.

**Recommendation: reclassify the 8, bind the 14.** Those 8 test the *helper's own
defensive contract*, not a policy any user's fit can exercise; holding them as required
parity rows means the ledger can never reach zero for a reason that has nothing to do
with parity.

**Cost:** the reclassification must state that reason in the ledger, or it reads as
scope-shaving. Default if unanswered: reclassify with the reason recorded.

---

## D5 — T12: are the four level names the ledger keys?

**Question.** `unit` / `unit_obs` / `cluster` / `cluster2` on both engines was relayed as
an owner requirement. Measured: R exposes all four as `gllvmTMB()` arguments. Julia has
`unit` partially (intrinsic axis + scalar row effects; full trait-vector only Gaussian),
`unit_obs` Gaussian-only, and **`cluster` / `cluster2` not at all**.

**Four sub-questions** (detail in `t12-grouping-levels-design.md` §5):
1. Keep the R names verbatim as Julia kwargs, or Julia-idiomatic names + a map?
   → **recommend verbatim** (the whole point is that an R user's call transfers).
2. Does "it is important" bump this ahead of phylo transport? → **recommend no** —
   phylo S1/S2 have landed; S3/S4 are small. Grouping levels are a multi-week build.
3. `cluster`/`cluster2` diagonal-only (matching R's own restriction), or correlated
   from the start? → **recommend diagonal-only**; correlated structures on that axis is
   a Julia-beyond feature, not parity.
4. Do the new kwargs alias onto `RowEffectFit`/`RowRandomFit`, or a parallel family?
   → **recommend alias**, with the existing names kept as deprecated aliases.

**Default if unanswered:** the four names are the ledger keys; `unit_obs` for
non-Gaussian is a **new required surface**, sequenced after phylo transport.

---

## D6 — the two relayed items, still awaiting direct confirmation

Both arrived via the gllvmTMB lane on 2026-09-02, recorded but never confirmed by you
directly:

- *"Make sure both Julia and R have `unit_obs`, `unit`, `cluster` and `cluster2` — it is
  important."* → this is what D5 acts on. Confirm or correct the relay.
- *"Bring zip/zinb/zib to R."* → supersedes decision #12's "no R twin" on the R side.
  Nothing changes for the Julia fitters or their ADEMP evidence; once R ships them the
  rows become pairable. **Confirm or correct.**

A relayed instruction is not an instruction until you say it is; the lane has treated
both as recorded-not-acted-on.

---

## What is NOT in this set

The parity work itself is finished to the line you drew. Open *findings* that need no
decision today: the Julia-vs-R wall-time gap on the largest realistic cell (2 h 36 m vs
498 s — an M3 performance track, not a parity question), and 2 invalid realistic-size
pairs needing an R-driver re-run with the seed in the filename (mechanical).
