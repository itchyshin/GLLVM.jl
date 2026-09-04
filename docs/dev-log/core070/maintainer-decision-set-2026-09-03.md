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

### ✅ DEFAULTED 2026-09-04 (Option A + Ada defaults; Shinichi G0)

Adopt the drafted tolerances in `second-order-parity-contract.md` §4 unchanged. Measured
20+22 cells sit two orders inside the each-own-optimum tier; signing loose is the
recommended direction, not scope-shaving. Record as maintainer-default until explicitly
revised.

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

### ✅ DEFAULTED 2026-09-04 (Option A + Ada defaults; Shinichi G0)

The each-own-optimum tolerance scaling uses **R's `cond(H)`** (oracle-side reference
problem hardness). Every receipt records **both** `r_condition_number` and
`native_condition_number` (`second-order-parity-contract.md` §5). Parameterisation
differences explain the 16× gap on the largest realistic cell; neither number is wrong
for its coordinate system.

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

### ✅ DECIDED 2026-09-04 (Shinichi): **(b) — rename ours to `loading_profile_exploratory`.**

Implementation belongs to the **combined Cursor lane**, which holds both repos. The closing Julia
lane recorded the decision but did not execute it: the rename is a user-facing API change touching
**123 occurrences** across `src/`, `test/`, the docs and — the part that matters — the **ledger**,
which is a joint-contract artifact.

**Convention-change cascade (AGENTS.md: all of it in ONE PR; a partial cascade is a Rose blocker):**

1. `src/confint_derived.jl:1134-1171` — rename the function. Its docstring must state the estimand
   plainly: this profiles an **exploratory (unpinned)** fit, whereas R's `loading_profile()` targets
   a **confirmatory (pinned-loadings)** fit gated on `fit$lambda_constraint`. Same name, different
   estimand — that is the entire reason for the rename.
2. `src/GLLVM.jl:196` — the export list.
3. `src/confint_derived_wald.jl` — call sites.
4. `test/test_derived_ci_surfaces.jl` — tests.
5. **A deprecation shim** for `loading_profile`, since it is exported and may already be in use.
   NOTE the trap this repo has already paid for once: `@test_deprecated` matches on the word
   *"deprecated"*, and six shims here once said only *"renamed"*, so those tests silently **skipped**
   rather than passed. Write "is deprecated:" in the message, and run with `--depwarn=yes`.
6. README, `docs/src/`, and any status table naming the old symbol.

**Ledger consequence — do not skip it, and treat it as a seam decision.** The row
`namespace/export/loading_profile` is the **last** of the eight estimand-defect rows still carrying
`PARTIAL_PARITY_DEFECT_PENDING_DECISION` (the other seven re-bound; BOUND 285 → 292). After the
rename, R's confirmatory `loading_profile()` has **no Julia counterpart**, so that row becomes a
`needs-surface` row rather than a defect, and our exploratory surface is a Julia-beyond capability
recorded in the reverse direction. Update `required-source-case-map.json`, then re-run
`tools/core070_ledger_counts.py`: **REQUIRED must stay 505 and no row may become free.** Because the
ledger is a joint-contract artifact, put the reclassification wording to Shinichi rather than
settling it inside the lane.

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

### ✅ DEFAULTED 2026-09-04 (Option A + Ada defaults; Shinichi G0)

Reclassify the **8** unreachable helper-contract rows out of required parity; bind the
**14** via public same-model fit receipts (`t8-aghq-policy-rows-proposal.md`). Record
the reason on each reclassified row (defensive helper contract, not user-fit policy).

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

### ✅ DEFAULTED 2026-09-04 (Option A + Ada defaults; Shinichi G0)

Ledger keys = **`unit` / `unit_obs` / `cluster` / `cluster2`** verbatim (R call
transfer). Julia kwargs alias onto existing `RowEffectFit`/`RowRandomFit` with deprecated
old names. `cluster`/`cluster2` **diagonal-only** on first build (matching R's restriction).
Sequencing: **after phylo transport S3/S4**, not ahead of it. `unit_obs` for non-Gaussian
is a **new required surface**, not a rename.

---

## D6 — the two relayed items (2026-09-02)

Both arrived via the gllvmTMB lane on 2026-09-02:

- *"Make sure both Julia and R have `unit_obs`, `unit`, `cluster` and `cluster2` — it is
  important."*
- *"Bring zip/zinb/zib to R."*

### ✅ DEFAULTED 2026-09-04 (Option A + Ada defaults; Shinichi authorized Ada defaults)

Shinichi authorized Ada defaults for the remaining OPEN items (A+defaults, 2026-09-04).

**1. Grouping-level relay — CONFIRMED (default).** The 2026-09-02 relay stands: all four
level names (`unit` / `unit_obs` / `cluster` / `cluster2`) remain important ledger keys on
both engines. D5 engineering default applies unchanged — verbatim R kwargs, diagonal-only
`cluster`/`cluster2`, alias onto `RowEffectFit`/`RowRandomFit`, sequenced after phylo
transport S3/S4. Rationale: A+defaults keeps the twin surface aligned with R grammar; the
relay intent matches what D5 already defaulted.

**2. ZI trio relay — CONFIRMED supersession of decision #12 on the R side only (default).**
The 2026-09-02 *"Bring zip/zinb/zib to R"* relay is **satisfied by existing R constructors**
— R Arc D shipped `zi_poisson()` (fid 17), `zi_nbinom2()` (fid 18), and `zi_binomial()`
(fid 19) in `R/families.R`; no new R build is owed. This supersedes maintainer round2-3
decision #12's *"no R twin"* **on the R side only**. Julia-forward ZI fitters
(`zip`/`zinb`/`zib`) remain Julia-beyond until paired; rows become pairable when Julia
surfaces exist. Do not invent new R code for this relay.

| Relay item | Verdict | Record |
|---|---|---|
| Four grouping levels are important | **CONFIRMED** | D5 defaults stand; see `t12-grouping-levels-design.md` |
| Bring zip/zinb/zib to R | **CONFIRMED — already shipped** | `zi_poisson`/`zi_nbinom2`/`zi_binomial`; supersedes #12 R-side only |

---

## What is NOT in this set

The parity work itself is finished to the line you drew. Open *findings* that need no
decision today: the Julia-vs-R wall-time gap on the largest realistic cell (2 h 36 m vs
498 s — an M3 performance track, not a parity question), and 2 invalid realistic-size
pairs needing an R-driver re-run with the seed in the filename (mechanical).
