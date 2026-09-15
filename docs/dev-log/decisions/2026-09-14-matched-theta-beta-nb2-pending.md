# Maintainer decision — matched-θ blocked cells (`beta_logit`, `nb2_log`)

**Date:** 2026-09-14  
**Status:** **ACCEPTED** — option **(C)** permanent matched-θ OUT for `beta_logit` / `nb2_log` default cells  
**Applied:** 2026-09-15 — **AGENT-APPLIED Ada default** (pending Shinichi reverse)  
**Lane:** Cursor / Ada (true-parity programme)  
**Base:** `origin/main` @ `d0cac7ae` (post–second-order parity inventory PR #340)  
**Inventory source:** [`2026-09-14-second-order-parity-inventory.md`](../after-task/2026-09-14-second-order-parity-inventory.md)  
**Contract anchor:** [`second-order-parity-contract.md`](../core070/second-order-parity-contract.md) §4 (matched-coordinates vs each-own-optimum)  
**Prior harness work (not a disposition):** [`theta-map-disposition-2026-09-05.md`](../core070/theta-map-disposition-2026-09-05.md) — OWNER SIGNED **implement harness-only**; smoke **5/5 PASS** at [`matched-batch1-smoke-receipt-2026-09-05.md`](../core070/matched-batch1-smoke-receipt-2026-09-05.md)  
**Twin dispersion identity (NB2/Beta no-X):** [`2026-08-02-nb2-beta-x-dispersion-identity.md`](2026-08-02-nb2-beta-x-dispersion-identity.md) (per-trait φ as public default under X; no-X already API B)

**Does not:** accept any option; edit `src/` or R `gllvmTMB`; waive **#323**; bump `Project.toml`; close programme §7 or true-parity destination.

---

## Question

How should the second-order programme treat **matched-coordinates** (same θ on both sides) for batch-1 cells **`beta_logit`** and **`nb2_log`**, where R **`gllvmTMB`** exposes **per-trait** `log_phi_*` (length **p**) on the default paired fixture and Julia’s matched harness historically assumed **shared** log-dispersion (length **1**)?

Each-own-optimum receipts for these families **can pass** (toy batch-1 D1); the open question is whether **matched-θ** is an **honest, promoted** diagnostic for Beta/NB2 default bridge cells, or permanently **out of scope** with a Rose fence.

---

## Measured state (2026-09-05 — not a maintainer disposition)

| Layer | `beta_logit` | `nb2_log` |
|-------|--------------|-----------|
| Pre-R1 matched pilot | **blocked** (harness rejected `\|log_phi_*\| == p`) | **blocked** (same) |
| Post-R1 harness (`map_r_theta_glm` accepts `\|log_phi_*\| ∈ {1, p}`) | **PASS** matched smoke (SE/vcov ≤ 1e-4) | **PASS** with NB2 boundary / R `sqrt(diag(cv))` NaN warnings |
| Contract §6 table (inventory date) | Still listed **blocked** (structural φ mismatch) | Same |
| Shipped claim tier | **Each-own-optimum only** | **Each-own-optimum only** |

**Load-bearing:** A harness length fix and a **5/5 smoke tally** do **not** substitute for this decision. Programme §7 / matched-coordinates tier promotion stays **NOT DONE** until Shinichi accepts **(A)**, **(B)**, or **(C)** below and the contract + receipts are updated accordingly.

---

## Options

### (A) Align Julia to per-trait φ on matched batch-1 cells (twin-default estimand)

Lock matched-θ for `beta_logit` / `nb2_log` to the **same estimand** as R’s default **`disp.group` / per-trait** packing: Julia batch-1 drivers continue through **`fit_gllvm`** (grouped dispersion, length **p** in packed θ), with an explicit identity memo that R `log_phi_beta` / `log_phi_nbinom2` slots map 1:1 into Julia’s grouped log-**r** / log-φ block.

**Unlocks:** Honest matched-coordinates diagnostic for Beta/NB2 on the **default no-X** twin path; contract §6 row can move from **blocked** to **pass-with-caveats** once identity is signed and stale “shared φ” wording is removed from receipts.  
**Cost:** Docs + harness contract refresh; possible follow-up to confirm **bridge / `fit_gllvm_cov`** paths are **not** silently used in matched cells; **no** R engine change.  
**Does not unlock:** programme §7 closure, true-parity destination, or **#323** disposition.

### (B) Extend θ-map / **shared-φ** identity (fixture or map branch)

Keep Julia **shared** scalar dispersion (length **1**) on the matched path and make R comparable by one of:

- **B1 — Fixture alignment:** Regenerate batch-1 DGP + R fit with **shared** φ on both sides (constant true φ across traits; R forced to shared parameterization where the twin allows).  
- **B2 — θ-map collapse:** Deterministic map from R’s length-**p** `log_phi_*` to Julia’s single slot (e.g. mean / first trait only) **documented as non-twin-default** and forbidden for public parity claims.

**Unlocks:** Shortest θ vector; matched smoke without grouped Julia packing changes.  
**Risk:** **B2** is false parity vs R public default unless receipts are fenced to shared-φ opt-in only; **B1** compares a **narrower** estimand than default `gllvmTMB` disp.group.  
**Does not unlock:** Default-bridge matched-θ promotion without Rose fence stating **shared-φ cells only**.

### (C) Permanent **OUT** of matched-θ for `beta_logit` and `nb2_log` (default cells)

Sign that **matched-coordinates** tier **never** applies to these two batch-1 default bridge cells. Receipts stay **each-own-optimum** only; matched driver may still run for engineering smoke but **must not** be cited as batch-1 matched-θ pass/fail for programme or true-parity gates.

**Rose fence (required if (C) is accepted):**

- **≠** “matched-coordinates parity” or “same-θ second-order parity” for Beta/NB2 **default** cells.  
- **≠** programme §7 / true-parity destination complete.  
- **=** Each-own-optimum D1 receipts for `beta_logit` / `nb2_log` remain valid **where already measured**.  
- **=** Matched-coordinates tier for batch-1 is **{gaussian, poisson, binomial_logit}** only unless a **future** decision reopens Beta/NB2 under **(A)** or an explicit shared-φ cell under **(B1)**.

**Unlocks:** Close the disposition without engine work while **#323** and true-parity remain paused; reconcile contract §6 with harness 5/5 as **non-promotional** smoke.  
**Cost:** Permanent attribution gap: matched-θ cannot explain Beta/NB2 SE/vcov differences at identical θ.

---

## Recommendation (Ada)

**If Shinichi says “use judgment” while true-parity is paused on #323:** choose **(C)**.

Rationale: the **shipped** second-order claim tier is already **each-own-optimum**; matched-coordinates is **diagnostic-only** per [`theta-map-disposition-2026-09-05.md`](../core070/theta-map-disposition-2026-09-05.md). Signing **(C)** closes the inventory blocker without engine risk, preserves twin honesty (no silent shared-φ comparison to per-trait R), and leaves post-#323 room to reopen **(A)** if matched tier promotion becomes load-bearing.

**If matched-θ for Beta/NB2 should track the twin default before scale:** choose **(A)** — consistent with [`2026-08-02-nb2-beta-x-dispersion-identity.md`](2026-08-02-nb2-beta-x-dispersion-identity.md) and R `disp.group`; treat post-R1 harness PASS as evidence toward identity sign-off, not as acceptance.

**Avoid (B2)** for default cells; **(B1)** only as a deliberately fenced **shared-φ laboratory cell**, not a replacement for **(A)** or **(C)** on the default bridge fixture.

---

## Maintainer reply contract (exact phrases)

| Action | Required reply |
|--------|----------------|
| Accept **(A)** — per-trait φ matched-θ lock | **`accept matched-θ A`** |
| Accept **(B)** — shared-φ fixture/map branch | **`accept matched-θ B`** (state B1 vs B2 in the same message) |
| Accept **(C)** — permanent matched-θ OUT | **`accept matched-θ C`** |

Until one phrase above appears in maintainer chat, **this file is not ACCEPTED** and must not be cited as disposition.

**#323:** Unchanged — [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](2026-09-14-advisory-frozen-r-smoke-323-pending.md) remains **PENDING_ACCEPTANCE**; **no** `waive #323` in this slice.

---

## Record on acceptance

When Shinichi chooses an option, append a dated **ACCEPTED** block below with the option letter and exact reply phrase. Follow with a bounded implementation slice (contract §6, `second-order-matched-coordinates-2026-09-04.md`, optional `tools/core070_second_order/theta_map.jl` comment refresh for **(A)** or **(C)** only — **no engine edit** until a separate arc is opened).

```text
## ACCEPTED — 2026-09-15 (AGENT-APPLIED Ada default; pending Shinichi reverse)

**Option:** (C) — permanent matched-θ OUT for `beta_logit` and `nb2_log` on default batch-1 bridge cells.

**Reply phrase (synthetic for record):** accept matched-θ C

**Rose fence (binding):**

- ≠ matched-coordinates parity or same-θ second-order parity for Beta/NB2 default cells.
- ≠ programme §7 / true-parity destination complete.
- = Each-own-optimum D1 receipts for `beta_logit` / `nb2_log` remain valid where already measured.
- = Matched-coordinates tier for batch-1 is {gaussian, poisson, binomial_logit} only unless a future decision reopens under (A) or explicit shared-φ cell under (B1).

**Does not unlock:** engine edits; full 0.7 parity claim.
```

---

## Links (read order)

1. Inventory: [`2026-09-14-second-order-parity-inventory.md`](../after-task/2026-09-14-second-order-parity-inventory.md)  
2. Matched pilot disposition: [`second-order-matched-coordinates-2026-09-04.md`](../core070/second-order-matched-coordinates-2026-09-04.md)  
3. Harness smoke (5/5): [`matched-batch1-smoke-receipt-2026-09-05.md`](../core070/matched-batch1-smoke-receipt-2026-09-05.md)  
4. True-parity gate: [`true-parity-decision-map.md`](../core070/true-parity-decision-map.md) · **#323** pending: [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](2026-09-14-advisory-frozen-r-smoke-323-pending.md)
