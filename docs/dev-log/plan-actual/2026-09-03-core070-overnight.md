# Plan vs Actual — core070 overnight lane (2026-09-02/03)

Plan files: `LOOP/GOAL.md` + `LOOP/arcs.md` + `LOOP/ultra-plan.md` (the latter is the prior
true-parity K-slice cycle; this GOAL supersedes it for arc scope). Session: Claude Fable 5.1
(orchestrator), lane `codex/core070-aghq-20260830`, worktree `GLLVM.jl-core070-aghq-20260830`.
Reconciled: 2026-09-03 02:09Z (Melissa). Routing this loop: A2/A3/A4/A5/A6/A7/A8/A5b/Rose/Melissa
all Sonnet; zero Haiku, zero Opus/Fable children; orchestrator Fable 5.1. Fan-out: interval 1
(→push #1, 00:09Z) = 3 children (A2,A7,A8); interval 2 (→push #2, ~01:58Z) = 5 children
(A3,A4,A5,A6,A5b) — both ≤6, no fan-out breach.

## Arc table

| Arc | Planned member/model | Actual | Artifact planned | Artifact actual | Gate | Tag |
|---|---|---|---|---|---|---|
| A1 T14 land | — (carried fix set) | suite-run-02→03 green (13327/0/0/8, bba953df); push #1 d4c6b44a..bba953df | check-log entry, CI verdict | check-log:17258/17386; CI via workflow_dispatch (33699239628), 7/8 shards green | leaf-A1 G1 MET, G2 unticked (manual box, evidence exists in checkpoint) | adaptive |
| A2 CI sharding | Sonnet | a2-ci-shard, as planned | CI.yml sharded, shard test | afd66551; shard 4/4 3156/2 in 29m44s (was 135–170 min) | leaf-A2 2/2 MET | on-plan |
| A3 second-order receipts | Sonnet, dep A1 | a3-second-order, dep honoured (after push #1) | second-order-batch doc | 06f4b97a; 20/20 cells, tolerances measured not gated | leaf-A3 2/2 MET | on-plan |
| A4 T5 re-runs | Sonnet, dep A1 | a4-t5-rebind, dep honoured | t5-rebind doc, ledger flips | 76b8b28f; 7/8 rows re-bound, BOUND 285→292 | leaf-A4 2/2 MET | on-plan |
| A5 T4 realistic-size | Sonnet, dep A3 | a5-realistic-size **dispatched before A3 finished** (capacity argument) | prerun doc + Nibi array queued | fbfb7a44+addendum; pre-run 3 cells clean; Nibi array cancelled mid-run, resubmitted 21053691 | leaf-A5 2/2 MET | adaptive |
| A5b realistic-size pairing | *(not in arcs.md)* | a5b-realsize-pairing, Sonnet | — | bc96f540; 14/24 valid, 2 invalid (seed mismatch), 8 pending | folded into leaf-A5 | adaptive |
| A6 phylo S1/S2 | Sonnet, dep — (none planned) | a6-phylo-s1s2, dispatched with no dependency, as planned | PrecisionPhy + correlation gate | e18eeb59/ef95ef6f/0d732bd6; ΔlogLik=0.0, h-scaling confirmed | leaf-A6 2/2 MET | on-plan |
| A7 docs cascade | Sonnet, dep — | a7-docs-cascade, as planned | scoreboard + mi() flip | 0fe1c622/ffce3f3c/82bc1760; mi() on 57/57 receipt | leaf-A7 2/2 MET | on-plan |
| A8 design notes | Sonnet, dep — | a8-design-notes, as planned | T12/T8 notes | 622f4001; T12 partial/missing rows, T8 14 bindable/8 reclassify | leaf-A8 1/1 MET | on-plan |
| F1 follow-up | *(not in arcs.md)* | engine fix in `src/confint_family.jl`, inside T14's maintainer-approved F1 scope | — | 789bd97e; boundary conditioned out unconditionally; 326/326 both Julia versions | covered by leaf-A1/A3 evidence, no dedicated leaf | adaptive |
| A9 push #2 | one push after A3+A4 (+A2) | folded into itself; carried A3/A4/A5/A5b/A6 + F1 follow-up | push #2, CI watch | bba953df..789bd97e, 6c9e57de; pushes used 2/3 | no dedicated leaf (by design — see GATES.md OWNS) | adaptive |
| A10 close | Ada | in progress — report drafted, Rose-audited, 3 blockers repaired (868b4ace); this reconcile now; handover exists; push #3 and closeout.py not yet run | after-task, audit, reconcile, handover, push #3 | 4/5 artifacts exist; push #3 pending | leaf-A10 0/2 MET (both unticked) | pending, see below |

## Material deviations

1. **Scope/routing — A5 before A3.** `arcs.md` states `A5 | ... | A3`, but A5 was dispatched before
   A3 landed (capacity argument: A3 was Totoro-bound and A5's pre-run step was independent enough to
   start). Order was recovered in substance (A5's commit postdates A3's in the log) and no output was
   consumed before it existed. **Tag: adaptive. Owner: Ada.**
2. **Scope — push #2 scope crept past its named dependency.** A9 was specified as "after A3,A4 (and
   A2 if not already)" but actually carried A5, A5b, A6, and an unplanned F1 follow-up — batching to
   stay inside the 3-push budget rather than spending a 3rd push on A6. Consistent with the pushes
   invariant's spirit (≤3 overnight, cancel in-flight CI). **Tag: adaptive. Owner: Ada.**
3. **CI mechanics — no `pull_request` event on either push.** GitHub delivered zero workflow runs for
   both bba953df (push #1) and 789bd97e (push #2); CI was started by `workflow_dispatch` both times.
   Root cause is GitHub-side (status page reported operational), not a lane decision, and the
   substitute path was itself pre-authorised. **Tag: unclear (external cause). Owner: Ada** — worth a
   standing ticket if it recurs a third time.
4. **Compute discipline — Nibi array cancelled before checking `squeue`.** Ada cancelled the running
   Nibi array mid-run to fix a `--time` sizing mistake, losing 16/24 completed tasks' scheduling slot
   (data not lost, resubmitted as 21053691). Report §9 names this "avoidable." **Tag: drift
   (unjustified — a `squeue` read would have shown it was already running and could have been left
   alone or resized without a cancel). Owner: Ada.**
5. **Process — A5 child amended the wrong commit.** The A5 child ran `git commit --amend` on Ada's
   after-task draft commit by mistake, then restored it byte-identical under a new hash
   (f3c6140f→1d5a9cd5); origin was never touched and the child was stopped. History rewrite is
   named-forbidden in every later brief. **Tag: drift (unjustified process violation, though
   content-harmless). Owner: Ada.**
6. **Public claims/engine scope — F1 follow-up.** `789bd97e` is a `src/` engine edit landed after the
   *prior* K-slice cycle's "no engine edits this arc" line (`ultra-plan.md:160`) — but that line
   belonged to the true-parity map's fenced scope, not this GOAL, and the fix sits squarely inside
   T14 F1's maintainer-approved fix set (check-log:17042, 2026-09-02) discovered as a red CI shard,
   not a new capability. **Tag: adaptive. Owner: domain reviewer (Gauss/Fisher, confint machinery).**
7. **Evidence — sentinel test aligned to F1 semantics.** `test_known_sentinel_defects.jl`'s proxy
   assertion (`fh.converged`) was swapped for one matching F1's new `dispersion_boundary` semantics
   (`fh.loglik != -Inf && fh.converged == !any(fh.dispersion_boundary)`) rather than the fixture or
   tolerance being touched — the sentinel's original intent (screen must not fire on a real answer)
   is unchanged and still checked. **Tag: adaptive. Owner: domain reviewer.**
8. **Evidence — A3 gate regex corrected for footnote marks.** `leaf-A3`'s row-count CHECK regex was
   fixed to tolerate footnote markers after a visual confirmation of all 20 rows; the measurement
   threshold itself was not loosened. **Tag: adaptive. Owner: Ada** (gate plumbing, not method).
9. **Closeout — report drafted early, repaired after Rose.** The after-task report was written before
   all evidence was current; Rose's audit (scratchpad `rose-overnight-audit.md`) found 3 blockers
   (stale 23/24 vs actual 24/24 R-grid count; the A5b pairing write-up omitted; the A5-child amend
   incident omitted) — all repaired in `868b4ace` before this reconcile. This is the QA gate working
   as designed. **Tag: adaptive. Owner: Rose.**
10. **Evidence/routing — K9-style MECHANICAL-VERIFY not run.** The prior cycle's ultra-plan established
    a Haiku MECHANICAL-VERIFY pass (`gate-check.mjs --reverify` on every leaf, cheapest tier) between
    "all arcs landed" and "reconcile." That cycle's own reconcile flagged K9 as skipped (2026-09-02
    plan-actual, deviation 1). This loop repeats the gap: no dedicated mechanical-verify child ran
    before this reconcile; I ran `gate-check.mjs --status` myself as part of reconcile instead, and
    Rose's audit substituted a Sonnet-tier claim-vs-evidence pass. Substance was covered (leaves
    verified, 3 blockers caught) but at a higher tier than the plan's stated economy prescribes, and
    the pattern is now 2-for-2 skipped. **Tag: drift (unjustified, recurring). Owner: Ada.**

## Pending at reconcile time

- **A10 close** — 4/5 artifacts exist (report, audit, this reconcile, handover); push #3 and
  `closeout.py check` have not run. `leaf-A10` both gates correctly unticked (0/2). This is in-sequence,
  not a stalled dependency — Melissa's reconcile is itself one of A10's listed steps.
- **A5b Nibi tail** — 8/24 realistic-size cells still on Nibi array 21053691 (`RUNNING`, no `seff` yet);
  2 invalid pairs (idx9/idx17, seed-mismatch) need a corrected R re-run.
- **A1 G2** — CI verdict is recorded in checkpoint.md/check-log but the gate file's manual checkbox is
  unticked.
- **T3/T8/loading_profile** — second-order tolerances, 8 AGHQ policy-row reclassifications, and the
  `loading_profile` estimand scope all await a maintainer sentence (unchanged from ultra-plan's fog).

## Recurring-class candidates (→ PLAN-DRIFT-LEDGER)

1. **Mechanical-verify step skipped in favour of a higher-tier substitute** — 2 cycles running now
   (2026-09-02 true-parity K9, 2026-09-03 overnight). If this keeps recurring, either fold the check
   into the reconciler's own routine (as done twice) and retire the separate Haiku step from the plan
   template, or add a hard gate that blocks reconcile dispatch until the mechanical pass's artifact
   exists.
2. **Children waiting on their own background compute** — two children this loop paused themselves
   mid-task waiting on a Totoro/Nibi run they had launched and had to be resumed manually (report §9).
   A standing pattern: a dispatched child that starts a long external job should return control
   immediately with a resume hook, not block in-session.
3. **Pre-run sizing from the cheapest cell class** — A5's `--time`/`--mem` for the Nibi grid was sized
   from the smallest pre-run cell and needed a mid-flight resubmission once larger cells ran long; the
   same failure mode was named in the 2026-09-02 reconcile (K3 pre-run sampled only the cheapest cell).
   Recurring 2-for-2; the D-201 rule ("size from the pre-run + margin") needs "pre-run the largest
   planned cell, not the smallest" made explicit.
4. **CI event delivery** — `pull_request` webhook not delivered on 2 consecutive pushes this loop; not
   yet enough data to call it a repo-side pattern vs GitHub-side noise, but worth a watch if a 3rd push
   also needs `workflow_dispatch`.

## Counts

Adaptive: **6** (1 A5-before-A3, 2 push-#2 scope creep, 6 F1 follow-up, 7 sentinel realignment,
8 A3 gate regex, 9 report repair-after-Rose).
Drift: **3** (4 Nibi cancel-before-squeue, 5 A5-child commit amend, 10 K9 mechanical-verify skip).
Unclear: **1** (3 missing pull_request events).
