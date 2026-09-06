# θ-map disposition — RESEARCH OPEN (2026-09-05)

**Status:** RESEARCH OPEN — **do not choose implement vs demote yet.** G0 Q5 locked:
θ-map **research first**, then owner chooses implement vs demote matched-coordinates tier for
v0.true-parity.

**Blocks:** claiming programme §7 / matched-coordinates tier complete; honest matched-coordinates
second-order receipts for beta_logit and nb2_log.

---

## Problem statement

The second-order parity contract defines two comparison tiers (`second-order-parity-contract.md`
§4):

1. **Each-own-optimum** — the shipped claim tier (two independently fitted models).
2. **Matched-coordinates** — diagnostic tier (both Hessians at the same θ).

The batch-1 matched-coordinates pilot (`second-order-matched-pilot-batch1-20260905.md`) measured
**3 pass / 2 blocked / 0 fail** on five cells. The two blocked cells share one structural blocker:

| Cell | Blocker |
|---|---|
| `beta_logit` | R per-trait `log_phi_*` (×p) vs Julia shared log-dispersion (×1) |
| `nb2_log` | same θ-index mismatch |

No honest θ map exists without changing parameterisation on one side or introducing an explicit
θ-map function that reindexes dispersion blocks.

---

## Research ticket (2-week framing)

**Ticket id:** `RESEARCH-THETA-MAP-20260905`  
**Duration:** ~2 calendar weeks (8–12 agent-days estimate)  
**Compute:** smoke in Cursor lane; any multi-seed grid on Totoro with D-139 estimate first.

### Questions the research must answer

1. **Parameter alignment table** — for each batch-1 family, enumerate R TMB parameter vector
   slots vs Julia packed θ; mark bijections, block permutations, and non-pairable entries.
2. **θ-map specification** — can a deterministic map `θ_R → θ_JL` (or shared θ*) be written
   for beta/NB2 dispersion blocks without changing either engine's public API?
3. **Implement cost** — if yes, estimate lines-of-code and test surface (bridge-only vs native).
4. **Demote cost** — if no, draft the v0.true-parity fence text: "matched-coordinates diagnostic
   available for {gaussian, poisson, binomial_logit}; beta/NB2 each-own-optimum only."
5. **Receipt impact** — which gate-tier rows (`true-parity-gate-tier-2026-09-05.md` A9, A11)
   change disposition under each branch?

### Deliverables

| Output | Path |
|---|---|
| Parameter alignment memo | `docs/dev-log/core070/theta-map-parameter-alignment-2026-09-XX.md` |
| θ-map spec or demotion memo | `docs/dev-log/core070/theta-map-spec-or-demote-2026-09-XX.md` |
| Owner decision record | Append to this file §Owner decision |

### Out of scope for research ticket

- Production implementation in `src/` or `test/` (follows owner choice).
- Changing R `gllvmTMB` parameterisation (read-only twin).
- Widening second-order tolerances to absorb θ mismatch.

---

## Owner decision — **OWNER SIGNED: implement harness-only** (chat G0 2026-09-05 approve)

**Signed:** 2026-09-05 — owner G0 approve baton + lean IMPLEMENT harness-only (θ-map). No `src/` / R engine edits. No true-parity / programme §7 claim.

| Branch | v0.true-parity claim |
|---|---|
| **Implement θ-map** | Matched-coordinates diagnostic included for all batch-1 families once map lands |
| **Demote matched tier** | v0.true-parity = each-own-optimum only; matched-coordinates remains optional diagnostic |

**Scheduled:** owner chooses at end of research ticket — **not during map-clearance arc**.

---

## P5 status

**CLOSED as research-scheduled.** Question dispositioned; implementation choice deferred per G0.
