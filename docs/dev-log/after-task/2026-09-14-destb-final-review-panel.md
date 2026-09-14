# Destination B — FINAL-REVIEW panel (Rose + Fisher)

**Date:** 2026-09-14
**Panel:** Rose (claims/scope) + Fisher (inference evidence)
**Lane reviewed:** `cursor/honest-070-destb` (local; 16 commits ahead of `origin/main` @ `23fd0496`)
**Frozen oracle:** gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`
**Inputs read:** `2026-09-14-destb-g10-final-review-prep.md`; the honest-0.7 DestB
ultra-plan; after-tasks G1 (API-BOUNDARY), G2 (capability promotion), G4 (T13
`mi()`), G5 (T14 NB2 Wald), G6 (T15 knife-edge), G7 (#323 handoff), G9 (S4
recorder push); `docs/design/capability-status.md` Arc 0 / T13–T15 fences;
`LOOP/GOAL.md`.

This is the **sign-off memo** the G10 prep packet called for. It closes the
`FINAL-REVIEW` gate item for the DestB-admitted 32-row scope and the honest-0.7
Arc 0 grid promotion **as documented on this branch**. It is **not** the joint
0.7.0 version decision (G11) and it does **not** touch `Project.toml`.

---

## 0. Verification performed for this memo (not chat memory)

| Check | Command | Result |
|---|---|---|
| Version fence | `rg '^version = ' Project.toml` | `version = "0.3.0"` — unchanged |
| Scope identity | `node tools/destination_b_scope_check.mjs` | exit 0, `enumerated: 32`, trailing `SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS` |
| Public wording fence | `rg '0.7 parity' README.md` | line 12: *"GLLVM.jl remains an experimental partial R-to-Julia bridge, not 0.7 parity."* — unchanged |
| Arc 0 test files exist | `test -f` on 7 named files | all 7 present (`test_phylo_dep.jl`, `test_animal_dep.jl`, `test_animal_latent.jl`, `test_kernel_indep.jl`, `test_kernel_dep.jl`, `test_kernel_latent.jl`, `test_spatial_dep.jl`) |
| Spot re-run (Fisher) | `julia --project=. test/test_mi_fitter.jl` | **5/5 pass**, live — matches G4's pinned receipt exactly |
| Branch content shape | `git log cursor/honest-070-destb --oneline` vs `origin/main` | 16 commits, entirely `docs(destb)` / `docs(LOOP)` / check-log; **zero `src/` or `test/` diffs** |
| Decision/map docs cited exist | `test -f` × 4 | `2026-09-13-honest-070-parity-aim.md`, `2026-09-13-destination-b-b1-close-as-limit.md`, `true-parity-decision-map.md`, `true-parity-gate-tier-2026-09-05.md` — all present |
| No concurrent Julia | `pgrep -fl julia` | none running before spot-check |

Only one live re-run was performed (the mi() fitter). The remaining test-count
claims (57/57 mi suite, 20/20 grouped dispersion, 192/192 bridge_x, 97/97 S3b)
are **not** independently re-run in this memo — they are accepted on the
strength of (a) the one matching spot-check, (b) the after-task receipts
being dated the same session with exact numbers (not round or hedged), and
(c) `check-log.md` corroboration. This distinction matters and is recorded
below, not glossed over.

---

## 1. Rose verdict — claims vs scope

**Claim under test:** *"The honest-0.7 Destination B programme's G1–G9 receipts
are consistent with each other, with `main`, and with the standing public
wording — nothing has been silently promoted beyond evidence."*

### PASS items

- **Version:** `Project.toml` reads `0.3.0` on the branch tip; no commit in the
  16-commit range touches it. Confirmed live, not from the prep doc's memory.
- **README wording:** unchanged "experimental partial R-to-Julia bridge, not
  0.7 parity" line survives untouched across all 9 after-tasks.
- **Arc 0 promotion (G2):** every promoted row carries the qualifier
  `(Arc 0 Gaussian function API only)`; the one row that does **not** get that
  qualifier — `spatial × dep` — is correctly held at `planned (Arc 0 fail-loud
  entry only)` rather than promoted, because only a fail-loud entry point
  exists. This is the single most important scope discipline in the whole
  batch and it holds.
- **T13 `mi()`:** correctly described as a **receipt pin**, not a new
  capability — the row was already `implemented` on `main`; G4 only attaches
  test evidence that had been implicit. No status word changed.
- **T14 NB2 Wald:** correctly described as **receipt-only** for a fix set that
  shipped 2026-09-02, not a new engineering claim. The "carried open" item
  (no single seed reproduces the *old* 3×70 shape well-conditioned across
  Julia 1.10/1.12) is stated, not buried.
- **T15 knife-edge:** correctly framed as **audit, zero edits** — 18 fixtures
  dispositioned as keep/document, explicitly refusing to retarget the
  intentionally-degenerate seed-523 family "without a maintainer sweep."
- **G7 (#323):** correctly refuses to claim anything about advisory-red R
  gradients as a Julia defect, states the D-139 estimate, and does not launch
  compute from this Cursor lane.
- **G9 (S4):** push-only, matches G0 Q2 exactly (push authorised, probe
  deferred to a second yes); explicitly states the probe was **not** run.
- **API-BOUNDARY (G1):** the 32-row scope identity is intact
  (`enumerated: 32`, oracle hash match), and the boundary table correctly
  separates the DestB 32-row list from the Arc 0 grid (a recurring
  "do not confuse" fence that is honoured in every subsequent after-task).
- **Foreign-lane hygiene:** the entire branch is docs-only (`docs/`, `LOOP/`,
  one `capability-status.md` prose/table edit) — no `src/` or `test/` diff, so
  the "16 foreign lanes live on shared Dropbox" risk named in the ultra-plan's
  Phase 0.2 preflight is not realised on this branch.

### CORRECTIONS (must fix before FINAL-REVIEW is "complete", not blocking this memo)

1. **G10 prep doc line 8 has a stray inline line-number artifact.** The
   Status banner reads `    10|FINAL-REVIEW complete, **not** a capability
   promotion...` — a `    10|` fragment leaked into the rendered prose (looks
   like a copy-paste of a line-numbered tool read). Cosmetic, but it is a
   FINAL-REVIEW-facing document; fix before it is cited externally.
2. **G6 (T15) summary table arithmetic:** "KEEP (stable or intentionally
   degenerate)" lists **11**, "KEEP + document" lists **4**, "DOCUMENT
   known-fail" lists **4**, "Retarget already applied" lists **1** — sums to
   **20**, but the file's own inventory table enumerates **18** fixtures and
   the summary line states "Audited fixtures: 18." Recount: walking the
   inventory, items are 1 KEEP+doc, 2 KEEP, 3 KEEP+doc, 4 KEEP+doc, 5 KEEP,
   6 KEEP, 7 KEEP, 8 DOCUMENT, 9 KEEP, 10 DOCUMENT, 11 DOCUMENT, 12 KEEP,
   13 KEEP, 14 KEEP(retarget), 15 KEEP, 16 DOCUMENT, 17 DOCUMENT, 18 DOCUMENT
   — that is 9 KEEP, 4 KEEP+document, 4 DOCUMENT (#16/#17/#18 plus one of
   #10/#11), and item 14 is the retarget-flagged one but is tagged KEEP. The
   table's row-level tags and its own summary counts do not reconcile to a
   single consistent partition. **This is a bookkeeping defect in an
   already-published after-task, not a live-test failure** — flag it for a
   correction pass, do not treat T15 as re-opened for engine work.
3. **Test-count claims beyond the one spot-checked (mi() 5/5) are unverified
   in this memo.** Rose does not fail the panel on this — the after-tasks are
   dated, specific, and internally consistent with `check-log.md` — but the
   FINAL-REVIEW memo must say plainly that 57/57 (full mi() suite), 20/20
   (`test_grouped_dispersion.jl`), 192/192 (`test_bridge_x.jl`), and 97/97
   (S3b adapter-consumer) are **receipted, not re-verified today**. Anyone
   citing this memo as "Rose independently reran everything" would be wrong.

### Must NOT be claimed (fences to carry forward verbatim)

- "Destination B is complete" or "32/32 rows closed" — **false**: B1 rows are
  closed-as-limit (not satisfied), S4 is held (not probed), and `API-BOUNDARY`
  + `FINAL-REVIEW` are the *last two* gates, with FINAL-REVIEW only closing now
  via this memo.
- "Arc 0 grid = family parity" or "Arc 0 grid = gllvmTMB `covered`" — every
  Arc 0 row is Gaussian-function-API-only, no `@formula` sugar, no bridge
  receipt, no realistic-size or second-order evidence. `spatial × dep` is
  fail-loud only and must stay `planned`.
- "T14 fixed" as a fresh engineering claim — it is a **2026-09-02** fix;
  today's slice only receipts it, and the "carried open" cross-version seed
  gap remains open.
- "#323 resolved" or "frozen R smoke green" — no live Totoro run happened in
  this programme; #323 stays open pending Codex/Totoro execution.
- "S4 probed" or any public-formula phylo-dep result — only the recorder
  branch was made fetchable on gllvmTMB (draft PR #1283); zero Julia-side
  probe code ran.
- Any two-directional parity statement (R↔Julia). T1's one-directional
  framing (R workflow → Julia) stands.
- Any `Project.toml` version claim beyond `0.3.0`.

---

## 2. Fisher verdict — inference evidence

**Claim under test:** *"The numerical/inference-adjacent DestB lines (B1, S3b,
T14, T15) are honestly characterized, and no interval or curvature evidence is
overstated."*

### PASS items

- **B1 closed-as-limit** is the correct disposition for what was actually
  measured: two independent out-of-pipeline `MakeADFun` reconstructions
  against the frozen 0.7.0 TMB binding failed *before* reaching
  `obj$he()`/`sdreport()` — that is an **interface limit** of rebuilding a
  frozen capture outside gllvmTMB's own pipeline, not a curvature or
  singularity finding about GLLVM.jl. The G2 closeout states this
  distinction explicitly and the G10 prep does not blur it. `B1-RECOVERY`
  correctly stays `NOT AUTHORIZED` per G0 Q1 — accepting this is the honest
  call; there is no path to a Wald-grouping recovery claim from a
  reconstruction that never got as far as computing curvature.
- **S3b 97/97** is narrowly and correctly fenced: three named fixture classes
  (tree, pedigree-with-ancestors, dense-`vcv`), adapter/test-only scope, "does
  not authorise generic bridge routing." The claim is scoped to exactly what
  ran.
- **T14 F1/F2/F3** disposition is scientifically coherent: F1 flags the
  boundary (`dispersion_boundary`) and degrades the affected Wald parameter
  rather than silently returning a wrong number; F2 adds a **separate**
  well-conditioned DGP alongside the explicit degenerate seed-523 case rather
  than "fixing" the degenerate case by changing its seed; F3 is a CI
  comparator fix (`x == y` including `Inf` counts as agreement), which is a
  test-harness correction, not a tolerance widening on the underlying
  likelihood. None of this is silent tolerance widening in the sense
  AGENTS.md forbids — the boundary condition is *detected and surfaced*, not
  hidden by a looser threshold.
- **T15** correctly refuses to retarget the intentionally-degenerate seed-523
  family "without a maintainer sweep" — this is the right instinct: a
  knife-edge fixture that exists *to lock in* boundary behaviour should not be
  quietly moved to a friendlier seed by an audit pass.
- **Live spot-check:** re-running `test/test_mi_fitter.jl` reproduced the
  claimed 5/5 exactly, with no test skips or `@test_broken` markers hiding a
  failure as a pass.

### CORRECTIONS

1. **T15's own count defect (see Rose #2 above) is also a Fisher concern**:
   an audit whose published summary table does not sum to its own stated
   fixture count is a data-integrity smell in exactly the kind of document
   this programme is trying to hold to a higher bar than the rest of the
   ecosystem. Recommend a corrected recount before the after-task is cited
   as closing T15 for good.
2. **The T14 "carried open" cross-version seed gap should be named explicitly
   in the joint decision note (G11), not just in check-log prose.** It is a
   real, acknowledged gap (no seed found across ~35k search that is
   well-conditioned on both Julia 1.10 and 1.12 for the legacy 3×70 shape) —
   Fisher does not consider this a blocker for FINAL-REVIEW (F2's alternate
   DGP is a legitimate substitute), but a joint version proposal that omits it
   would be an omission, not a correction to make now.
3. **No B1-RECOVERY evidence exists and none should be implied.** Any future
   document that reads "grouping Wald intervals validated under B1" without
   the closed-as-limit caveat would contradict this memo.

### Must NOT be claimed

- No Wald-interval coverage claim from the B1 line (the reconstruction never
  reached a curvature computation).
- No "T14 fully closed for all NB2+X cells" — only the receipted fix set and
  the two named test files are in evidence; the cross-version seed gap is
  open.
- No claim that the S3b 97/97 run was re-executed today (it was not; it is
  the 2026-09-13 `ce46bebf` receipt, cited, not repeated).
- No claim that the frozen oracle pin (`b4d5fee6`) moved — it has not, in any
  document reviewed.

---

## 3. Blockers before any joint 0.7.0 version discussion (G11)

These are the concrete gate items still open per `LOOP/GOAL.md`'s own
unchecked boxes — this panel does **not** close them, it only confirms they
remain correctly unclosed:

1. **S4** — recorder is now fetchable (gllvmTMB draft PR #1283, tip
   `97214679c`), but the probe itself needs a **second, separate maintainer
   yes** per G0 Q2. Held.
2. **#323** — advisory Frozen R smoke has a scoped Codex/Totoro handoff
   (D-139 estimate pasted) but **no live run** happened. Open.
3. **T15 count reconciliation** — fix the arithmetic defect noted above (Rose
   #2 / Fisher #1) so the audit's own numbers are internally consistent.
4. **G10 prep doc cosmetic artifact** (stray `10|` line fragment) — trivial,
   fix before external citation.
5. **G11 joint decision note** — does not exist yet; this memo is a
   precondition for it, not a substitute. It must explicitly carry forward
   every fence in §1–§2 above (Arc 0 ≠ parity, B1 closed-as-limit, T14 open
   sub-item, S4 held, #323 open) — a version proposal that drops any of these
   is not honest per D-183.
6. **`Project.toml` stays `0.3.0`.** No commit reviewed touches it; this memo
   does not authorise or recommend a change to that file. Any move toward
   `0.7.0` remains a **separate maintainer act**, after G11, not an automatic
   consequence of this sign-off.

None of these are re-opened by this panel; they were already correctly listed
as open in the G10 prep packet and in `LOOP/GOAL.md`. This memo's job was to
check whether the *closed* items are honestly closed — they are, modulo the
two corrections above.

---

## 4. Panel verdict

**PASS-WITH-CORRECTIONS.**

"DestB programme receipts ready for maintainer read": **yes, with two
named corrections carried forward** (T15 count arithmetic; G10 prep cosmetic
artifact). Neither correction changes any capability status, any test
result, or any version number. Both are documentation-hygiene fixes, not
re-openings of closed engineering questions.

**Top 3 corrections:**

1. Fix `2026-09-14-destb-g6-t15-knife-edge.md`'s summary-table arithmetic so
   its per-disposition counts sum to the stated 18 fixtures (currently sums
   to 20 against 4 disposition buckets whose row-level tags do not partition
   cleanly — see §1 item 2 for the reconciliation detail).
2. Remove the stray `    10|` line-number artifact from
   `2026-09-14-destb-g10-final-review-prep.md`'s status banner before it is
   cited in any maintainer-facing packet.
3. When G11's joint decision note is drafted, it must explicitly restate (not
   drop) the T14 cross-version-seed open sub-item and the S4/#323 held
   states — the version proposal is only as honest as its weakest omitted
   caveat.

**Explicit re-affirmations for the record:**

- `Project.toml` **stays `0.3.0`**. Not touched by this memo, not
  recommended for change here.
- **`FINAL-REVIEW` (this gate)** is satisfied for the DestB-admitted rows and
  the honest-0.7 Arc 0 grid **as documented on this branch**, subject to the
  two corrections above.
- **G11 (joint version proposal)** remains a *separate, subsequent* act that
  this memo does not perform and does not pre-approve the outcome of.
- No push, no merge, no `main` change performed by this panel review.
