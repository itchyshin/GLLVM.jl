🎯 GOAL
Solo platform: Cursor (planning lane; GLLVM.jl writable, gllvmTMB read-only)
Deliverable: an owner-readable Phase 1 plan for the remaining Destination B programme, with acceptance gates only for the first leave-able tranche
HEADLINE: correct “0.7.1 parity” to `v0.true-parity` against frozen gllvmTMB 0.7.0, then package A+D and continue only through explicitly gated arcs
IN PARALLEL: package the completed A+D work; prepare the authorised merge queue; prepare the next M2/M3 slice without starting M2-R2
DEFER: 0.7.1 Class-1 catch-up (C), M2-R2 matched coordinates without a new G0, full M3–M5 execution, campaigns, R-engine edits, and public parity claims
DISCIPLINE: verify=unlazy gates plus fresh checks · compute=local smoke only until a separate D-139 approval · closure=G0 answers recorded and this plan stops

**Status: STOP AT G0.** This file plans the remainder only. It does not push
the A/D implementation branches, merge PRs, run `/goal`, run campaigns, or
claim true parity.

## Naming and destination

“0.7.1 parity” is undefined as the twin milestone. The signed destination is:

> `v0.true-parity`: retained paired evidence for the owner-approved 42-row
> gate tier, against frozen gllvmTMB 0.7.0; this is not a claim that every
> capability-ledger row is covered.

The gllvmTMB DESCRIPTION version or a later 0.7.1 release does not change this
oracle. The 0.7.1 Class-1 surface remains deferred unless Shinichi explicitly
re-opens C with named rows and a re-freeze decision.

## Phase 0 receipts

### Lane pre-flight

`~/shinichi-brain/tools/lane_preflight.sh` was run on both repositories with
full paths.

- **GLLVM.jl:** second Cursor lane active; other live lanes include #306,
  #305, #304, #303, #301, #298, #297, and the A/D implementation lanes.
  Lane taken here: `cursor/ultra-plan-true-parity-remainder-20260906`, in a
  fresh scratch worktree. This lane owns this plan only; it does not touch
  source, tests, bridge files, or other lanes’ receipts.
- **gllvmTMB:** foreign Claude/Codex lanes active and additional Cursor lanes
  active. The twin is read-only for this plan; no files are claimed there.
- A lease claim for `docs/dev-log/check-log.md` was refused because the active
  kernel-bridge lane already owns that path. This plan therefore does not
  edit the shared check log; the next safe lane must append the plan receipt
  after that lease is released.

### Prior-work sweep

- **Canonical programme:** #291, `v0.true-parity` / frozen 0.7.0 / signed
  42-row gate-tier / M2→M5 envelope. #291 remains the programme canon.
- **Destination decision:** #306 and the prior destination plan recorded the
  A/B/C/D choice. Shinichi’s 2026-09-06 G0 selected **B**, with A as the
  first leave-able arc.
- **M2 baton:** #303 remains the execution-plan reference. It explicitly
  fences M2-R2, campaigns, R-engine edits, merges, and claims behind the
  relevant gates.
- **A already local:** `cursor/m2-s1s2-remainder-20260906` at
  `c422374c`; EOO smokes and `se=TRUE` schema receipts exist for Binomial,
  Beta, and NB2. This is evidence, not M5 completion.
- **D already local:** Julia kernel bridge audit at `75d0a37c`; paired R
  work is at `c717a5720`. D remains packaging/bridge evidence, not permission
  to alter the R engine or claim full parity.
- **Open queue inspected:** #297, #301, #304, and #303 remain relevant;
  #306 is the prior destination-plan PR. #298 remains research/waiting.
  #1236 in gllvmTMB remains parked and is not authorised by this plan.
- **Deterministic grep:** searched `docs/dev-log/`, the brain
  `AGENT_LOG.md`, `DECISIONS.md`, `OPEN_QUESTIONS.md`, and
  `projects/deep-research/README.md` for
  `true-parity|0.7.1 parity|Destination B|M2|M3|M4|M5|NB2|#291|#306`.
  The result supports reuse of #291/#303 and the signed B decision; no new
  destination is inferred.
- **Brain search:** `search_notes` with
  `true-parity Destination B frozen gllvmTMB 0.7.0 M2 M5 0.7.1`,
  `search_all_projects: true`, hybrid search. The repo’s signed plan and
  receipts remain the technical source of truth.

### Route check

1. Destination is writable: **yes**, B is already signed.
2. The slices do not hide a new either/or: **yes**, this plan separates
   reversible packaging and preparation from the choices that still need G0.
3. Each slice has an output path or explicit manual outcome: **yes**.

**Route verdict:** decompose toward B; do not rebuild the decision map.

## Programme state: M2→M5

The broad B programme remains approximately 120–230 agent-days over 9–18
calendar months. That estimate is for the programme, not for A or D.

| Milestone | Current state | Remaining boundary |
|---|---|---|
| M2 | A’s local S1/S2 evidence exists; D’s bridge evidence exists separately | Package A+D, then select the next bounded M2/M3 slice; do not call A complete until its authorised checks and receipts are reviewed |
| M3 | Not complete | Build only the next named family/bridge slice after A; every slice gets its own output and gate |
| M4 | Not started as a claim | Requires accumulated M2/M3 evidence and a fresh scope review |
| M5 | Destination/qualification target only | Retained evidence for the signed 42-row tier, not automatic coverage of all ledger rows |

### Already done locally

- **A:** M2 S1/S2 remainder receipts: Binomial, Beta, NB2 EOO smokes and
  `se=TRUE` schema smoke, committed at `c422374c`.
- **D:** kernel bridge evidence and Rose claim audit, Julia at `75d0a37c`;
  paired R work at `c717a5720`.

### Not done

- A+D have not been pushed or merged.
- The programme is not complete and no M5 evidence claim is allowed.
- NB2 A11 remains **partial**; do not promote it silently to covered.
- M2-R2 matched coordinates need a new G0.
- 0.7.1 Class-1 remains deferred.

## Phase 1 slice list

These are the slices to collapse into execution only after G0. They are not
being executed in this chat.

| Slice | Member / model | Bar | Output | Dependencies | Estimate |
|---|---|---|---|---|---|
| P1 — package A+D | Ada / Composer or Grok, bounded docs/git work | Cursor Models | push-ready branch/commit receipts and a short packaging note under `docs/dev-log/plan-actual/` | G0 authorises push; A=`c422374c`, D=`75d0a37c` + `c717a5720` | 1–2 h |
| P2 — merge queue | Ada + Rose / Auto Cost judgment; handoff for merges | Other Models → handoff | ordered merge checklist: #301 → #297 → #304; #306 after this plan; explicit stop conditions | P1 and CI/owner authorisation; no merge by silence | 1–3 h of review, CI wall time excluded |
| P3 — next M2/M3 scope | Ada + Gauss/Hopper / pinned Claude/GPT judgment | Other Models | one bounded next-slice brief with exact files, oracle, output receipt, and estimate | A review; **not** M2-R2 without new G0 | 2–4 h planning |
| P4 — leave-able M2/M3 execution | Codex Terra/Sol | handoff | implementation and paired evidence for only P3’s named slice | P3 approval, its ledger, and any compute G0 | days to be estimated per slice |
| P5 — mechanical verification | Curie / Composer or Grok | Cursor Models | fresh test/receipt inventory and unlazy re-verification output | P1–P4 outputs | 30–90 min |
| P6 — claim/scope review | Rose / pinned Claude/GPT | Other Models | verdict on whether the evidence supports the stated row status | P5 | 1–2 h |
| P7 — live R/Julia or campaign work | Codex Terra/Sol | handoff | only a named, separately approved evidence artifact | explicit compute target, estimate, smoke, and G0 | not estimated yet |

**Parallel:** P1 packaging and P3 preparation can be prepared independently,
but P3 must not authorize M2-R2. P5/P6 follow returned evidence.

**Sequential:** P2 follows P1; P4 follows P3; P5 follows the implementation;
P6 follows P5. P7 is a separate future gate, not implicit in this plan.

**Routing note:** the Cursor Models bar is for bounded recon/mechanical work.
Judgment and claim review belong on Other Models. Live R/Julia, Totoro/DRAC,
and merge authority hand off to Codex/Claude as named above.

## Unlazy acceptance ledger

`.unlazy/` and `.unlazy-hook-state.json` are already present in `.gitignore`.
The ledger below is intentionally limited to the **first leave-able tranche**:
packaging A+D, the merge queue, and preparation of the next M2/M3 slice. It
does not create empty gates for the 120–230 day programme.

Scope directory: `.unlazy/true-parity-remainder-20260906/`

- `GATES.md` — tranche contract and ownership
- `gates/leaf-package-a-d.md` — packaging
- `gates/leaf-merge-queue.md` — ordered merge decision
- `gates/leaf-next-m2-m3.md` — next-slice preparation

The ledger is written now because B is signed, but its checks remain blocked at
the relevant owner/merge gates. No push or merge is performed here.

## Pre-authorisation envelope

**After G0, continue:** scoped edits in the fresh planning/approved worktree;
routine local git/status/diff checks; the listed smoke and ledger checks;
local commits; and a push or draft PR for this planning artifact if Shinichi
explicitly confirms it. The next M2/M3 implementation must still use its own
bounded goal and gates.

**Still stop:** pushing A/D implementation branches unless explicitly named;
merging #301/#297/#304/#306; starting `/goal` in this chat; M2-R2; any R
engine edit; Totoro/DRAC or other campaign work; credentials; release/public
claims; and any scope change that promotes NB2 A11 or 0.7.1 Class-1 without a
new decision.

## G0 questions for Shinichi

1. **Push authorization:** may the A and D implementation branches be pushed,
   or should only this planning branch/PR be pushed?
2. **Merge authorization:** confirm the queue **#301 → #297 → #304**, then
   #306, or name a different order/PR set.
3. **First build arc after A:** confirm the next bounded M2/M3 slice, or name
   the exact family/bridge row to scope.
4. **M2-R2:** confirm it remains stopped until a new G0.
5. **NB2 A11:** keep it `partial` pending its missing evidence, or accept a
   narrower named claim? Recommendation: keep `partial`.
6. **D packaging:** should D be treated as a bridge-evidence tranche only,
   with no capability promotion beyond its current receipts?
7. **Compute:** confirm local-only smokes for the next planning slice; any
   Totoro/DRAC campaign gets its own estimate, smoke, and G0.
8. **Class-1:** confirm that 0.7.1 Class-1 stays deferred and does not alter
   the frozen 0.7.0 oracle.
9. **Next handoff:** after approval, should execution be launched through a
   new `/goal` prompt for only the approved tranche?

## Paste-ready `/goal` prompt — DO NOT RUN

```text
Use the approved plan at
docs/dev-log/plans/2026-09-06-ultra-plan-true-parity-remainder.md.

Destination is B: v0.true-parity against frozen gllvmTMB 0.7.0, with retained
paired evidence for the owner-approved signed 42-row gate tier. Do not call
this “0.7.1 parity”; 0.7.1 Class-1 remains deferred. A is the bounded M2
remainder; D is local kernel-bridge evidence. A is at c422374c; Julia D is at
75d0a37c and paired R D is at c717a5720.

First, re-read the plan and its .unlazy ledger. Work only on the owner-approved
first tranche: package A+D, process the explicitly authorised merge queue
(#301 → #297 → #304, then #306 if approved), and prepare the next bounded
M2/M3 slice. Keep NB2 A11 partial. Do not start M2-R2 without a new G0.

Before any dispatch, re-read every CHECK/EXPECT in
.unlazy/true-parity-remainder-20260906/ and claim only disjoint paths.
Re-verify every returned leaf with gate-check --reverify. Do not push or merge
unless the owner’s G0 answer explicitly names that action. Do not edit the
gllvmTMB R engine, run Totoro/DRAC, launch a campaign, make a parity claim,
or broaden the scope. Stop after the approved tranche’s gates and claim review.
```

## Closure

This plan stops at G0. A/D are real local prior work, not programme completion.
The next sitting must record Shinichi’s answers, re-check the branch heads and
leases, then execute only the named tranche.
