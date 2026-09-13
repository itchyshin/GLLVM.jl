# 🎯 GOAL — Destination B frozen-0.7.0: get the G0 question right, then stop

| Field | Value |
|---|---|
| **Solo platform** | Cursor (Ada), read-only planning. One lane: `destination-b-plan-20260913`. |
| **Deliverable** | This plan, plus one decision from Shinichi. Nothing else is produced today. |
| **HEADLINE** | The handover's owed step — *"ask for G0 to create the Unlazy acceptance ledger"* — **cannot be asked as written**: a Destination B G0 authorisation already exists (2026-09-08) and a Destination B acceptance ledger already exists (`.unlazy/destination-b-programme/GATES.md`, 8 gates, all pending). The honest ask is narrower: *which* ledger, and does the 2026-09-08 authority carry into the re-scoped frozen-0.7.0 gate numbering. |
| **IN PARALLEL** | Nothing. This is a single decision, not a campaign. |
| **DEFER** | All numerical work (B1 marginal curvature, S4 probe, any fit/optimizer/R/TMB call), G1 audit, G2–G7, FRK, 0.7.1, coverage campaigns, releases, registration, pushes, vault writes. |
| **DISCIPLINE** | Static/read-only until an explicit, fresh maintainer decision. The B1 HOLD JSON is never staged, edited, deleted, or retried. The frozen oracle is `gllvmTMB` 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`; the dirty live 0.7.1 checkout is not an oracle. |

**PLATFORM: cursor | ON BRANCH: codex/destination-b-b1-integration-20260910 | LANE: destination-b-plan-20260913 | OTHER LANES: cursor+#314**

**Scope fence set by Shinichi, 2026-09-13 (binding):** this lane is **Destination B only**. The
GLLVM twin multi-agent test campaign (Grok Bot / DRM-shape testers) is **his own separate lane** and is
deliberately absent from this plan — no roles, no Mission Control, no burn compute menu here.

---

## Phase 0 receipts (evidence-first; pasted, not summarised from memory)

| Check | Result |
|---|---|
| Worktree / branch / tip | `/private/tmp/destination-b-b1-integration-20260910`, `codex/destination-b-b1-integration-20260910`, tip **`b24ffb09`** — matches the handover. |
| Drift | `ahead 86, behind 4` of `origin/main`. (Handover said 85; one commit is the handover itself.) |
| Working tree | Exactly one untracked file: the **protected B1 HOLD JSON**. Nothing else dirty. |
| Lane pre-flight | `lane_preflight.sh` verdict: **FOREIGN LANE ACTIVE (cursor)** — open PR **#314** `cursor/codex-handover-20260907`. Lane census: 2 lanes live. Lane taken here: `destination-b-plan-20260913`, touching only the plan file below. No bleed into #314. |
| Platform note | `lane_preflight.sh` printed `ME : claude` from the runtime, while this session is Cursor. Recorded as a **tool/runtime mismatch**, not evidence about who is editing; treat the PLATFORM line above as authoritative for this lane. |
| Coordination board | `docs/dev-log/coordination-board.md` is committed to `origin/main` (so it does reach other lanes), but its Active-Lane-Split's newest row is **2026-08-17**. **Destination B has no row on the board** (`rg -i "destination b"` → zero hits). See Finding F3. |
| Design numbers | No duplicate slots; next free = 74. Nothing allocated by this plan. |
| Lease | Granted paths were `docs/dev-log/handover/`, `docs/dev-log/core070/destination-b-b1/`, `.unlazy/`. This plan writes to `docs/dev-log/plans/` under **Shinichi's explicit instruction this turn**, which extends the lease to that one file. Declared rather than assumed. |

### Prior-work sweep (Phase 0.25 — receipt, not a claim)

This is where the plan changed shape. Searched the worktree's `docs/dev-log/plans/`,
`docs/dev-log/decisions/`, and `.unlazy/` before designing anything:

| Artifact found | What it already contains |
|---|---|
| `docs/dev-log/plans/2026-09-08-destination-b-g0-decision-packet.md` | A full G0 decision packet, marked **`RESOLVED 2026-09-08`**. |
| `docs/dev-log/decisions/2026-09-08-destination-b-g0-authorisation.md` | A **maintainer G0 authorisation receipt** binding five lines: B1 grouping (full programme, prior `unit` checkpoint is source-alignment only), S3b as R bridge adapter only, S4 Gaussian paired validation *after* the S3b consumer works, dense `vcv` under the R-ridged-once contract, FRK parked at `gllvmTMB#1275`. |
| `.unlazy/destination-b-programme/GATES.md` | **An existing Destination B acceptance ledger**: 8 gates — `G0-SCOPE`, `B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`, `B1-RECOVERY`, `S3B-CONSUMER`, `S4-PUBLIC-FORMULA`, `API-BOUNDARY`, `FINAL-REVIEW`. **All 8 unchecked/pending.** |
| `.unlazy/destination-b-b1-stationary-reference/GATES.md` | A narrower B1 stationary-reference ledger with **passing** `[x]` gates (G1 retained-receipt test under Julia, G2 write-once refusal). |
| `.unlazy/b1-balanced-complete-crossed-pre-run/GATES.md`, `.unlazy/totoro-t4-p6-grid/GATES.md`, `.unlazy/GATES.md` | Three further ledger scopes, incl. a root-level one for the **fixed-coordinate** curvature protocol. |
| `docs/dev-log/decisions/destination-b-scope-reconciliation.md` | The row count is **32** enumerated rows (A1–A15, B1–B4, C1–C5, D1–D8). The historical "42" is a sign-off prose artefact that **added no row**. Checker: `node tools/destination_b_scope_check.mjs`. |
| `test/` + `tools/` | **Two** B1 curvature protocol pairs coexist: `*_fixed_coordinate_curvature_protocol.{jl}` and `*_fixed_point_marginal_curvature_protocol.{jl}`. The handover's safe-check commands name the **fixed_point_marginal** pair; the root `.unlazy/GATES.md` gates the **fixed_coordinate** pair. |

`.unlazy/` is `.gitignore`d (lines 19–20), so no ledger work churns the tree — that precondition is already satisfied.

---

## Phase 0.6 — Route check (written, mandatory)

1. **Destination in one sentence?** Yes: *the frozen-0.7.0 Destination B programme has exactly one authoritative acceptance ledger whose scope, oracle, protected files and exclusions are locked and reviewed, with G1 not started and no numerical event performed.* That is an end state.
2. **Do two or more slices say "depends what we decide"?** **Yes.** Whether to create a new ledger or re-scope the existing `destination-b-programme` one; and whether the 2026-09-08 authorisation already *is* the G0 the handover is asking for, or whether the revised G0–G7 numbering created a second, different G0.
3. **Can every slice name its output as a real file path?** **No.** The ledger's own path is unknown until (2) is answered — a new `.unlazy/<scope>/GATES.md` versus an edit to the existing one.

**Verdict: the decision map fires.** Phase 1 slice decomposition waits. Two of three checks failed, and the failure is not a gap in my reading — it is a genuine unresolved authority question. A slice list written today would be a decision wearing a slice's clothes.

---

## A. What we need to do now

- **Resolve one ambiguity, then stop.** The single owed action is a maintainer decision on the shape of G0 (below). Everything else in the programme is downstream of it.
- **Do not re-ask for authority that already exists.** The 2026-09-08 receipt already authorises the B1/S3b/S4/dense-`vcv`/FRK *lines*. Asking "may I start Destination B?" again would be noise; asking "does that receipt cover the re-scoped frozen-0.7.0 gate ladder?" is the real question.
- **Do not create a second ledger by reflex.** `.unlazy/destination-b-programme/GATES.md` exists with 8 pending gates. Creating a parallel frozen-0.7.0 ledger without a decision produces two ledgers for one programme — the failure mode the acceptance ledger exists to prevent.
- **Blocked by authority (unchanged, no fresh approval today):** capture materialization, B1 marginal-curvature evaluation, S4 probe, any fit/optimizer/retry, any R/TMB call, any recovery campaign.
- **Blocked by object availability:** the S4 recorder `97214679c` is **absent from this object database**. S4 cannot be touched from this worktree at all until its owning lane is rehydrated — that is a physical blocker, not a permission one.
- **Optional cheap hygiene, not owed:** Destination B is invisible on the coordination board (F3). One board row would fix it. It is a separate concern and a separate commit if he wants it.

---

## Findings of record (this plan's actual contribution)

**F1 — "G0" now names two different things.** The 2026-09-08 authorisation answered a *scope-authority* G0 (which programme lines may open). The 2026-09-12 handover proposes a *gate-ladder* G0 (create the acceptance ledger) inside a revised G0–G7 sequence. Both are called G0. Any approval given without separating them will be ambiguous later — which is exactly how a lane ends up believing it has numerical authority it never received.

**F2 — the acceptance ledger is not missing.** The handover's step 3 reads as greenfield work. It is not: an 8-gate Destination B programme ledger exists, plus three narrower scopes, one of which has passing gates. The owed work is therefore **reconcile-or-re-scope**, which is a smaller and differently shaped job than "create".

**F3 — Destination B is absent from the cross-lane entrypoint.** The handover names the coordination board as the entrypoint, and the board is correctly committed to `origin/main`, but it carries no Destination B row and stops at 2026-08-17. A sibling lane rehydrating from the board today would not learn this programme exists.

**F4 — two B1 curvature protocol pairs coexist.** `fixed_coordinate` and `fixed_point_marginal`. The handover's safe checks and the root `.unlazy/GATES.md` point at *different* ones. Before any G1 audit cites "the B1 static contract (22/22)", the audit must say **which pair** it verified. Not a defect; an under-specification that would silently mis-attribute evidence.

None of F1–F4 is a numerical finding, and none of them changes the evidence status of any Destination B row.

---

## B. Decision map

### Destination

When this is done: the frozen-0.7.0 Destination B programme has **one** authoritative acceptance ledger; its scope (the 32 reconciled rows), its frozen oracle (`b4d5fee6…`), its protected files (the B1 HOLD JSON, `.unlazy/**`, the `AGENTS.md` snapshot, sibling lanes) and its exclusions (0.7.1, FRK, coverage, release, registration, push) are written down and reviewed; and **G1 has not started**. No fit has run, no capability has been promoted, no claim has moved.

### Decisions so far (settled — do not reopen)

| Decision | Source |
|---|---|
| Frozen oracle is `gllvmTMB` 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`; live 0.7.1 is dirty and not interchangeable evidence. | handover + scope reconciliation |
| Scope is **32** enumerated rows (A1–A15, B1–B4, C1–C5, D1–D8); the "42" is prose, not rows. | `destination-b-scope-reconciliation.md` |
| B1 grouping, S3b (adapter only), S4 (after S3b consumer), dense `vcv` (R-ridged-once, no independent Julia inversion) are **authorised lines**; FRK is **parked**. | `2026-09-08-destination-b-g0-authorisation.md` |
| Public wording stays "experimental partial R-to-Julia bridge, not 0.7 parity". | same |
| The B1 HOLD JSON's `obj$he(theta_star)` error is an **interface limitation** — not a singularity verdict, not a curvature result, and not Wald inference. | handover |
| S4's earlier stop is **diagnostic retention only**, not phylogenetic parity. | handover |
| No push, merge, release, registry action by default. | D-220 + handover |

### Not yet specified (the fog — what Shinichi must settle)

1. **Which G0 is being asked for?** Does the 2026-09-08 scope authorisation already satisfy the handover's gate-ladder G0, or is a fresh, separately-recorded ledger gate wanted? (**F1**)
2. **One ledger or two?** Re-scope/annotate the existing `.unlazy/destination-b-programme/GATES.md` to the frozen-0.7.0 framing, or open a new sibling scope and mark the old one superseded? (**F2**)
3. **Does the ledger get a repo-visible record?** `.unlazy/` is gitignored, so a ledger-only G0 leaves **no committed trace**. Does he want an accompanying committed decision note, or is the ignored ledger sufficient?
4. **Board row now or later?** (**F3**)
5. **Which B1 protocol pair is canonical** for evidence citation? (**F4**) — answerable at G1, not needed for G0.

### Out of scope (with reasons)

| Excluded | Reason |
|---|---|
| GLLVM twin multi-agent test campaign, Grok Bot roles, testing Mission Control, burn compute menu | Shinichi's own separate lane, binding instruction 2026-09-13. Not this lane's business. |
| Any numerical B1 / S4 event | Requires its own fresh, explicit decision each time. |
| G1 audit and G2–G7 | Downstream of the G0 answer. |
| FRK | Parked at `gllvmTMB#1275`. |
| 0.7.1, releases, registration, coverage certification, generic bridge admission | Explicitly excluded by the authorisation's retained limits. |
| Pushes, merges, PR #314 files | No authority; foreign lane. |
| Vault writes | Not authorised. **FINDINGS-OF-RECORD: none.** |
| Editing the `AGENTS.md` snapshot pointer | Multi-lane rule: would orphan sibling handovers. |

---

## C. Gates — two, named distinctly

### Gate **Plan-G0** (this plan)
Shinichi answers fog items 1–3. That is all. Approving this plan is **not** approving Destination B numerical work, and **not** the same event as the 2026-09-08 authorisation.

### Gate **DestB-G0(frozen)** (the programme's ledger gate)
Only if Plan-G0 says yes: do the static ledger work below, then **STOP for review before G1**.

Explicitly *not* granted by either gate: capture materialization, `obj$fn`/`sdreport` evaluation, S4 probe, any fit, optimizer, retry, R/TMB call, `Pkg.test()`, or recovery campaign.

---

## D. Conditional slices (do not start — these run only after Plan-G0 **and** DestB-G0)

All three are static, single-session, and together estimated at **under one working day** (consistent with the handover's estimate). Bar column per Cursor two-bar hygiene.

| # | Slice | Output path | Bar / model | Gate |
|---|---|---|---|---|
| **S1** | Reconcile the ledger: read the existing 8 gates against the frozen-0.7.0 framing; either annotate in place or open one new scope and mark the old superseded. Lock oracle SHA, the 32-row scope, protected files, exclusions. | `.unlazy/destination-b-programme/GATES.md` (re-scope) **or** `.unlazy/destination-b-frozen070/GATES.md` (new) — **path chosen by fog item 2, not by me** | Cursor Models (Composer) — mechanical, bounded | DestB-G0 |
| **S2** | If fog item 3 says yes: one committed decision note recording what the ledger locks, so the gitignored ledger has a repo-visible counterpart. | `docs/dev-log/decisions/2026-09-13-destination-b-frozen070-ledger-lock.md` | Cursor Models | DestB-G0 |
| **S3** | Close the slice: check-log entry + after-task report; declare the untracked HOLD and the ignored ledger in the landing state. | `docs/dev-log/check-log.md`, `docs/dev-log/after-task/2026-09-13-destination-b-frozen070-g0.md` | Cursor Models | DestB-G0 |

**Draft ledger path listing only** (paths named so he can see the shape; **no file created, no gate written, no content authored today**):

```text
.unlazy/destination-b-programme/GATES.md            # EXISTS — 8 pending gates, candidate for re-scope
.unlazy/destination-b-frozen070/GATES.md            # CANDIDATE new scope (only if he picks "new")
.unlazy/destination-b-frozen070/gates/leaf-g0.md    # CANDIDATE leaf, CHECK/EXPECT form
```

Verification at S1 close would be the portable re-verify, not `--status`:

```sh
node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --reverify .unlazy/<scope>/gates/leaf-g0.md
```

Static safe checks available at G0 time (from the handover; **not run by this plan**), with F4's
which-pair ambiguity resolved first:

```sh
julia --startup-file=no --history-file=no --project=. test/test_b1_fixed_point_marginal_curvature_protocol.jl
julia --startup-file=no --history-file=no --project=. tools/verify_b1_fixed_point_marginal_curvature_protocol.jl
git diff --check
node tools/destination_b_scope_check.mjs
```

---

## Landing state of this plan

| Artifact | Committed | Pushed | State |
|---|---:|---:|---|
| `docs/dev-log/plans/2026-09-13-destination-b-g0-ultraplan.md` | no | no | **UNTRACKED / DECLARED** — written under explicit instruction; not staged, because no commit was requested. |
| `docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json` | no | no | **PROTECTED HOLD — untouched by this session.** Never stage, edit, delete, or retry. |
| Everything else | — | — | Unchanged. No numerical event occurred. No claim moved. |

**STOP. Awaiting Plan-G0.**
