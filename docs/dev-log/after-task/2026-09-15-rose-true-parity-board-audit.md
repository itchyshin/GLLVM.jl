# After Task: Rose claim-vs-evidence audit: true-parity board vs engine (2026-09-15)

## Goal

Docs-only Rose audit: check the true-parity pending board, the Mac Studio
handover, the second-order holdouts sheet, the `AGENTS.md` phase snapshot, and
`docs/src/gllvmtmb-parity.md` for any claim of full 0.7 parity, "§7 complete",
matched-θ as achieved/promoted, arcG/DRAC cited as an R-owed coverage
certificate, or PR [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) as
mergeable without conflict. No board edits made (Ada may refresh after #367);
corrections are recorded here as recommended patches only.

## Implemented

No code or doc changes. This report **is** the deliverable: an evidence audit
against live `git`/`gh` state plus a targeted `rg` sweep for over-claim
patterns across `docs/dev-log/`, `docs/src/`, and `LOOP/`.

## Scope Read

- `docs/dev-log/2026-09-14-true-parity-pending-board.md`
- `docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`
- `docs/dev-log/core070/second-order-holdouts-2026-09-04.md`
- `AGENTS.md` § Phase state snapshot (top bullet)
- `docs/src/gllvmtmb-parity.md` (spot check)
- Cross-checked against: live `git log origin/main`, `gh pr view` on
  [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) and
  [#367](https://github.com/itchyshin/GLLVM.jl/pull/367), `LOOP/checkpoint.md`,
  `LOOP/GOAL.md`, two cited decision files, and `src/confint_family.jl` /
  `test/` for the newly-claimed Wald wiring.

## Verdict

**OK, with one blocker (AGENTS.md phase snapshot stale) and two minor notes.**
No instance found of the four forbidden claims (full-0.7-complete, §7
complete, matched-θ as achieved, arcG as R-owed coverage) or of #357 being
misrepresented as mergeable. Every doc in scope that touches those claims
explicitly negates them ("NOT DONE", "≠ programme §7", "each-own-optimum
only", "ACCOUNTED, not a coverage certificate"). One document (`AGENTS.md`) is
stale against live `origin/main` by 6 commits/5 PRs and needs a refresh before
the next agent rehydrates from it.

## CHANGES-REQUIRED

### 1. `AGENTS.md` phase-state-snapshot top bullet is stale (6 commits behind)

The live top bullet reads:

> "**True-parity continuation (2026-09-15).** `origin/main` @ `deab192f`
> after #362/#356/#361/#355/#364/#365."

But `git rev-parse --short origin/main` returns **`9519b3e28`** (at scratch
bank time), which is **6 commits ahead** of `deab192f`:

```
9519b3e28 docs: Mac handoff with active goal + true-parity ultra-plan (#371)
c459751bf docs: Mac Studio main lane STARTED (coordination note) (#370)
c00e93451 docs: Mac Studio true-parity handover for Shinichi (#369)
1671b9477 docs: record #366 MultinomialFit Wald MERGED on true-parity board (#368)
c1842dd69 feat(second-order): MultinomialFit Wald CI + true-parity board refresh (#366)
deab192f4 Merge pull request #365 …
```

The bullet is missing #366 (MultinomialFit Wald `_CIFit`), #368/#369 (Mac
Studio handover), #370 (lane-ownership note), and #371 (Active goal /
ultra-plan handoff). A reader rehydrating from `AGENTS.md` alone would not
know the Mac Studio lane exists or that Multinomial has native Wald. That
gap is the drift pattern
`AGENTS.md` "Phase state snapshot" exists to prevent, and the file's own
routine (`Update this snapshot after every after-task report`) was not
followed for #366/#369/#370.

**Recommended patch** (not applied; Ada may fold this into the next board
refresh after #367 lands, to avoid two agents editing the same section):

```diff
 - **True-parity continuation (2026-09-15).** `origin/main` @ `deab192f` after
-  #362/#356/#361/#355/#364/#365. Multinomial FE Wald `_CIFit` on lane tip
-  (`docs/dev-log/after-task/2026-09-15-multinomial-wald-ci.md`). #357 foreign
-  CONFLICTING; do not edit. Still paste-gated: S4, D3 Stage 1, Totoro T4,
-  Delta dispersion A; `Project.toml` stays `0.3.0`. Goal **not** complete.
-  Board: `docs/dev-log/2026-09-14-true-parity-pending-board.md`.
+ - **True-parity continuation (2026-09-15).** `origin/main` @ `9519b3e2` after
+  #362/#356/#361/#355/#364/#365/#366/#368/#369/#370/#371. Multinomial FE Wald
+  `_CIFit` MERGED (#366, `c1842dd6`); Mac Studio now owns the programme lane
+  (#369 handover MERGED `c00e9345`; #370 lane-ownership note). Cloud
+  babysit-only for in-flight #367 (Student-t fixed-ν Wald). #357 foreign
+  CONFLICTING; do not edit. Still paste-gated: S4, D3 Stage 1, Totoro T4,
+  Delta dispersion A; `Project.toml` stays `0.3.0`. Goal **not** complete.
+  Board: `docs/dev-log/2026-09-14-true-parity-pending-board.md`. Handover:
+  `docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`.
```

Apply the patch in its own commit, staged by name (`git add AGENTS.md`),
separate from any board/#367-merge commit, per the repo's "one concern per
commit" rule and the maintainer note to leave the board untouched pending
Ada's own refresh.

## OK (checked, no defect found)

### 2. No "full 0.7 / §7 complete" claim found

`rg` for `full 0.7|full parity|programme §7 complete|true parity achieved`
across `docs/dev-log/`, `docs/src/`, `LOOP/` returns only **negated** uses:
"**do not** claim §7 / full 0.7 / `v0.true-parity` sign-off" (handover line
174), "Programme §7 / true parity: **NOT DONE**"
(`docs/src/gllvmtmb-parity.md` line 55), "**≠** programme §7 complete" (Delta
follow-up after-task, S2-hessian-A receipt, #347 after-task), "does not read
3/5 pilot pass **as** programme completion" (parity doc line 66). One line in
`true-parity-programme-decision-map-2026-09-05.md:44` reads "matched-
coordinates pilot = programme §7 complete" but it sits inside a sentence
listing what the reader must read the map **without implying**; i.e. it is
itself a negation, not a claim. No affirmative instance exists anywhere in
scope.

### 3. No matched-θ claimed as achieved for the disposed families

The board and holdouts sheet both cite matched-θ for `beta_logit`/`nb2_log`
as **(C) permanent OUT**: "each-own-optimum only", explicitly not a
matched-coordinates pass. Read the underlying decision file
(`decisions/2026-09-14-matched-theta-beta-nb2-pending.md`): it is honestly
framed as **AGENT-APPLIED Ada default, pending Shinichi reverse**, not a
maintainer-confirmed acceptance. The board and handover both surface that
caveat ("Disposed (2026-09-15, Ada default)", "Reverse: Shinichi may paste
`reject matched-θ C`"). This is transparent, not a claim inflation; flagging
as a process note only (see "Notes" below), not a blocker.

### 4. arcG/DRAC never cited as an R-owed coverage certificate

`docs/dev-log/decisions/2026-09-15-julia-only-arcg-disposition.md` disposes
the ledger row as **ACCOUNTED**: "Julia-beyond diagnostic programme; **not**
an R capability to port; **not** the twin-join DIFFER row"; Rose fence at the
bottom: "≠ covered promotion · ≠ programme §7 · ≠ claiming arcG calibrated."
`AGENTS.md`'s own header block (unaffected by the stale bullet above) already
carries the correct fence: "Julia-only Wald interval *coverage* … undercoverage
evidence, not a calibrated-coverage or R-parity certificate." `docs/src/
gllvmtmb-parity.md` reiterates: "Interval *coverage* is not part of parity;
it is a separate Julia-only diagnostic programme … Empirical undercoverage
there is **evidence**, not a calibrated-coverage certificate." Consistent
across all three documents.

### 5. #357 correctly described as CONFLICTING, not mergeable

Live check: `gh pr view 357 --json mergeable` → **`"mergeable":"CONFLICTING"`**
(Frozen R advisory job also FAILURE on that PR's last run, non-gating).
Every document in scope agrees: board: "Foreign: #357 CONFLICTING; do not
edit"; handover: "#357 … OPEN · CONFLICTING … Foreign; leave alone unless
Shinichi pastes otherwise"; `LOOP/checkpoint.md`: "#357 bridge receipts:
foreign; CONFLICTING." No document anywhere in scope claims #357 is
mergeable or asks to merge it. Clean.

### 6. #367 correctly described as open/pending-green, not merged

Live check: `gh pr view 367` → `state: OPEN`, `mergeable: MERGEABLE`, CI still
`IN_PROGRESS` on 8 of 9 checks at audit time (Documenter green). Board/
handover both say "OPEN · MERGEABLE · babysit … merge when Julia+Documenter
green"; accurate present-tense framing, no premature "merged" claim anywhere.

### 7. Second-order holdouts sheet: PARTIAL labels match the actual wiring

Spot-checked the newly-claimed `_CIFit`/`_family_ci` wiring against
`src/confint_family.jl` and confirmed against `test/`:

- `MultinomialFit` → `_family_ci` method at `src/confint_family.jl:2295`; test
  `test/test_second_order_multinomial_ci.jl` exists.
- `OrdinalPerTraitFit`/`OrdinalPerTraitCovFit` → methods at lines 2161/2211;
  test `test_second_order_ordinal_pertrait_ci.jl` exists.
- `LognormalFit`/`TruncatedPoissonFit`/`TruncatedNegBin2Fit` → methods at
  lines 394/431/473; tests `test_second_order_lognormal_ci.jl`,
  `test_second_order_truncpois_ci.jl`, `test_second_order_truncnb2_ci.jl`
  exist.
- `TweedieGroupedFit` → method at line 1120; test
  `test_second_order_tweedie_grouped_ci.jl` exists.

Every "PARTIAL (native Wald)" label in the holdouts sheet is backed by a real
dispatch method plus a named test file, not a doc-only claim. The sheet's own
caveat ("bridge `ci_method` guard still refuses until post-#357 lift") is
consistent with #357 sitting CONFLICTING/unmerged (finding #5).

### 8. `docs/src/gllvmtmb-parity.md` spot check: clean

The page carries its own explicit "What parity does NOT mean" section,
states the second-order programme is "NOT DONE", states the matched-
coordinates tier is "NOT implemented" (3 pass / 2 blocked, and even that
pilot is fenced as "do not read … as programme completion"), and separates
"Core070 FREE=0" from "true parity achieved" in its own subsection. No stale
speedup or precision claims found beyond the ones already self-corrected in
the page's own `!!! note "Corrected 2026-08-25"` callout.

## Notes (non-blocking, informational)

- AGENT-APPLIED decisions are self-labeled, not silently promoted. All
  four disposed items on the board (#323 waive, matched-θ C, §2 Hessian A,
  arcG ACCOUNTED) are decision files signed "AGENT-APPLIED Ada default
  (pending Shinichi reverse)" rather than a maintainer paste. The board is
  transparent about this and gives exact reverse-paste strings. Not a
  claim-vs-evidence defect, but worth Shinichi's eventual glance since these
  are load-bearing for later "true parity" gating.
- **`LOOP/checkpoint.md` rehydrate line is one PR behind** (`c00e9345`, i.e.
  pre-#370); lower materiality than the `AGENTS.md` gap since #370 is a
  docs-only lane-ownership note with no capability claim, and the file was
  otherwise current (mentions #366, #369, current holdouts). Same fix window
  as item 1 if convenient, not urgent on its own.
- **`docs/dev-log/coordination-board.md`** (referenced by the handover's
  rehydrate script, not by the user's read list) is stale relative to the
  true-parity board; its dated entries stop at #318 (2026-09-13) and never
  mention the true-parity programme. Out of this audit's named scope; flagged
  only so it is not mistaken for a live pointer if someone runs the
  handover's full rehydrate script literally.

## Checks Run

```
git fetch origin main && git rev-parse --short origin/main   # 9519b3e28
git log --oneline -15 origin/main                             # confirms 6-commit gap vs AGENTS.md's deab192f
gh pr view 357 --json state,mergeable,statusCheckRollup        # CONFLICTING, Frozen-R advisory FAILURE
gh pr view 367 --json state,mergeable,statusCheckRollup        # MERGEABLE, CI IN_PROGRESS
gh pr view 370 --json title,body                               # docs-only lane note, "Goal NOT complete"
rg "full 0.7|full parity|§7 complete|programme complete|true parity achieved|
    matched-coordinates.*(complete|achieved)|arcG.*coverage certificate|
    arcG.*R-owed|mergeable without conflict" docs/dev-log docs/src LOOP
diff <(git show origin/main:docs/dev-log/2026-09-14-true-parity-pending-board.md) \
     docs/dev-log/2026-09-14-true-parity-pending-board.md    # identical; local matches origin
grep -n "MultinomialFit\|OrdinalPerTraitFit\|LognormalFit\|TruncatedPoissonFit\|
          TruncatedNegBin2Fit\|TweedieGroupedFit" src/confint_family.jl
ls test/test_second_order_{multinomial,ordinal_pertrait,lognormal,truncpois,
   truncnb2,tweedie_grouped}_ci.jl                             # all 6 present
```

## Consistency Audit

Read the board, handover, holdouts sheet, `AGENTS.md` snapshot bullet,
`docs/src/gllvmtmb-parity.md`, `LOOP/checkpoint.md`, `LOOP/GOAL.md`, and the
two cited decision files end to end; cross-checked every SHA and PR-state
claim against live `git`/`gh` rather than trusting the prose. Ran a repo-wide
`rg` sweep for the four forbidden claim shapes named in the task plus
"mergeable without conflict"; every hit was a negation or an unrelated use
of "full parity" as a test-suite name (`advisory-r070-smoke-fail-brief`, which
correctly reports 9/286 failing, not a pass claim).

## What Did Not Go Smoothly

Nothing blocking. The one real gap (`AGENTS.md` stale by 6 commits) is a
routine drift of the kind the file's own "Update this snapshot after every
after-task report" instruction exists to catch. #366/#369/#370/#371 after-task
work landed the board/handover/checkpoint refresh but skipped the `AGENTS.md`
top bullet specifically.

## Team Learning

When a PR's after-task work refreshes the true-parity **board**, it should
refresh the `AGENTS.md` phase-snapshot bullet in the **same** PR; the two
have drifted apart twice now (this audit; the prior board itself notes
`AGENTS.md`-adjacent hygiene PRs #364/#365/#368). Consider a cheap mechanical
check (`rg` the `AGENTS.md` top-bullet SHA against `git rev-parse
--short origin/main` in CI or a pre-push hook) rather than relying on every
agent remembering the instruction by prose.

## Remaining Risks

- `AGENTS.md` top bullet will keep drifting until either (a) the recommended
  patch above is applied in its own commit, or (b) Ada's next board refresh
  (post-#367) folds it in.
- The four AGENT-APPLIED decisions remain formally reversible; nothing here
  changes that status, but any downstream reader treating them as
  maintainer-signed rather than agent-default should re-check the decision
  files' own headers first.

## Known Limitations

This audit is a point-in-time snapshot at `origin/main @ 9519b3e28` /
PR #357 `CONFLICTING` / PR #367 `MERGEABLE, CI in progress`. It does not
re-verify prior after-task reports' own internal math (e.g. the Δ figures
cited in the holdouts sheet); it verifies that the **labels and wiring
claims** in the four requested documents match live git/gh state and match
each other.

## Next Command

`git add AGENTS.md` with the patch in "CHANGES-REQUIRED §1" above, in its own
commit, once Ada confirms the board is not mid-refresh (i.e. after #367
lands and the post-merge board/checkpoint tip pass is done) to avoid two
concurrent edits to the same phase-snapshot region.

## Rose Verdict

Rose verdict: **PASS WITH NOTES**. No forbidden claim (full-0.7-complete,
§7-complete, matched-θ-achieved, arcG-as-R-owed-coverage, #357-mergeable)
found anywhere in the four requested documents or in a repo-wide sweep; every
document correctly negates or fences those claims. One blocker:
`AGENTS.md`'s phase-snapshot top bullet is 6 commits stale (missing #366,
#368, #369, #370, #371) and should be refreshed in its own commit; patch
supplied above, not applied per the task's docs-only / do-not-touch-board
instruction.
