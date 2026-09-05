# Bridge-eligible row tag — design note (doc-only, M0-5)

**Status:** DESIGN NOTE — no `tools/parity_ledger.py` code change in map-clearance arc.  
**G0 lock (2026-09-05):** tiered bridge — thin JuliaCall for ACC-class workflows; native Julia elsewhere.

---

## Purpose

Tag ledger rows that **may** qualify through `gllvmTMB(engine = "julia")` so build arcs do not
implicitly assume every gate-tier row needs a native Julia surface first. A row without the tag
defaults to **native-only** for v0.true-parity planning.

---

## Tag definition

**Field name (proposed):** `bridge_eligible: true | false` on each gate-tier / required_core row
in the parity ledger JSON (future tool patch — P13 / post-map build arc).

| Value | Meaning |
|---|---|
| `true` | Row **may** pass via R→Julia bridge if an ACC-class receipt exists |
| `false` | Row **must** pass via native Julia (structured dependence, unsupported families, phylo beyond adapter, etc.) |

**Hard rule:** **No bridge-eligible row without an ACC-class receipt.** ACC classes follow
`real-workflow-acceptance-lessons.md` (eight acceptance classes). A bare bridge smoke or toy
fixture does **not** satisfy the tag.

---

## ACC-class receipt minimum

Before a `bridge_eligible: true` row flips to covered:

1. Public R call shape documented (`gllvmTMB(..., engine = "julia")`).
2. ACC id + classified outcome (PASS or honest FAIL with ACC code).
3. Receipt JSON + sha256 under `docs/dev-log/core070/` or `.unlazy/`.
4. Rose scan confirms no overclaim in linked docs.

**Existing example:** `acc-bridge-urbanisation-receipt-2026-09-05.json` — thin scout; gate-tier
promotion still requires full eight-class acceptance (`true-parity-gate-tier-2026-09-05.md` C1).

---

## Default tagging rules (Ada default)

| Row kind | `bridge_eligible` | Reason |
|---|---|---|
| Ordinary `latent()` bare + admitted bridge families (Gaussian, Poisson, Binomial-logit, Beta, NB2) | `true` | Bridge PASS receipts exist or are plausible |
| Structured covariance (`phylo_*`, `animal_*`, `kernel_*`, `spatial_*`, `dep`, `indep`) | `false` | `GJL-GATE-STRUCTURED-TERMS` — adapter blocks (`bridge-coverage-matrix.md`) |
| Grouping levels (`unit_obs`, `cluster`, `cluster2`) | `false` | No bridge payload; native surfaces owed |
| AGHQ rows | `false` | Deferred from gate-tier; Laplace default |
| Real-data workflows | `true` **only if** model formula is bridge-admissible | Otherwise native equivalent required |
| Second-order receipts | Usually `false` for claim tier | SE/vcov computed on Julia side; bridge may supply θ̂ only |

---

## Implementation deferral

| Item | When |
|---|---|
| `parity_ledger.py` field + export | First build arc after map clearance (P13 neighbourhood) |
| Ledger row backfill | After gate-tier sign-off (`true-parity-gate-tier-2026-09-05.md`) |
| CI gate | Optional — warn on `bridge_eligible: true` rows lacking ACC receipt path |

---

## P2 status

**CLOSED as design note.** Bridge width question answered at programme level (tiered + tag);
tooling patch scheduled, not map-clearance.
