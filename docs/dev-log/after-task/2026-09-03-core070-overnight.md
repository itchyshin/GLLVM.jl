# After-task — core070 overnight loop (2026-09-02 23:15Z → 2026-09-03)

Session: Claude Fable 5.1 (Claude Code), lane `codex/core070-aghq-20260830`, worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`, arc-loop with the LOOP/ kit (`LOOP/GOAL.md`
immutable; `LOOP/arcs.md`; `LOOP/checkpoint.md` overwritten per arc). Pre-authorisation: Shinichi's
four answers of 2026-09-02 ~23:05Z (up to 3 pushes + CI sharding; phylo Q1–Q4 defaults; re-binds on
passing receipts + mi() flip on a test receipt; arcs A3/A4/A5 + docs; "consider using DRAC
cleverly"). Acceptance ledger `.unlazy/core070-overnight/` (9 leaves).

**Honesty line, first:** nothing in this report is a parity claim. Second-order receipts now exist on
20 paired toy-scale cells and three realistic-size pre-run cells; that is evidence collected under a
draft contract whose tolerances the maintainer has not signed. The qualification claim stays
first-order harness parity plus these receipts.

## 1. Goal

Run the lane autonomously until 05:00 MDT: land T14 (suite green, pushed, CI read); shard CI; collect
second-order receipts on every paired cell; T5 paired re-runs with re-binds; realistic-size pre-run and
grid (Totoro pre-run, Nibi array); phylo transport S1–S2 red-first; docs cascade; T12/T8 design notes;
close with report, audit, reconcile, handover. Three pushes maximum.

## 2. Implemented

**A1 — T14 landed.** Totoro suite-run-02 at 85918fe9: 13271 pass / 1 fail / 1 error / 8 broken —
error environmental (rsync omitted `frozen-r070-contract.toml`; registry test passes locally 4/4),
fail = the sentinel test's "healthy" NB2 grouped-cov fixture sits at a dispersion boundary
(r ≈ 2.9e9, the free latent factor absorbs the trait's overdispersion), which F1 now reports as
`dispersion_boundary` + `converged=false`; assertion aligned to the sentinel's actual intent
(25 pass / 1 broken on 1.12.6 and 1.10.12). Push #1 = d4c6b44a..bba953df. GitHub delivered **no
pull_request event** for that push (0 runs across all workflows; status all operational), so CI was
started by `workflow_dispatch` (run 33699239628, sharded). suite-run-03 (full suite at bba953df, Julia 1.12.6, `--depwarn=yes`, 68m06s):
**13327 passed, 0 failed, 0 errored, 8 broken — exit 0, fully green**. CI dispatch run 33699239628 (sharded, bba953df, 00:22–01:2xZ): **7 of 8 Julia shards green** (all four on 1.10.12, three on 1.12.7); the one red shard, `Julia 1 shard 1/4`, failed only F1's own red-first test `test_confint_family.jl:644-694` (`ci.pd_hessian == false` evaluated true): on CI's 1.12.7 x64 the seed-523 fixture landed in the barely-positive-definite regime the T14 diagnosis describes, and F1's degradation branch only fired on a Cholesky failure. Fixed in the follow-up commit (flagged boundary parameters are now conditioned out unconditionally; deterministic forced-boundary test added) — see §2 F1 follow-up. Advisory R smoke failed as documented. Also recorded: run 33661544679 at
d4c6b44a (17:30–20:37Z) was **fully green on both Julia jobs**, the NB2 Wald cell included,
consistent with the T14 knife-edge diagnosis.

**A2 — CI sharded (afd66551).** `GLLVM_TEST_SHARD=k/N` in `test/runtests.jl` with a pure-logic
partition test (43/43); CI matrix `shard: [1,2,3,4]` → 8 Julia jobs; coverage only on
`workflow_dispatch`. Shard 4/4 locally: 3156 pass / 2 broken in 29m44s (was 135–170 min per job).
The dispatched run shows the 8 sharded jobs by name.

**A3 — second-order receipts (06f4b97a).** 20/20 paired harness cells (10 families/links × no-X and
+X, plus two species-X cells), both engines on Totoro, observed Hessian both sides: max rel ΔSE
median 6.4e-6, max 1.01e-4 (nb1_log); vcov-block relative Frobenius median 1.09e-5, max 1.84e-4
(n=15; nb2_log null at a shared Poisson-limit boundary, reported not hidden); max |ΔWald endpoint|
median 6.7e-6, max 3.27e-5; |ΔlogLik| max 3.41e-6 (nb2 boundary cell). No cell above the draft
each-own-optimum tolerances; tolerances measured, not gated. 49 s per 20-cell pass. Receipts:
`core070/second-order-batch-out/`, tooling `tools/core070_second_order/`.

**A4 — T5 re-runs (76b8b28f).** Seven of eight PARTIAL_PARITY_DEFECT rows re-bound on frozen-oracle
receipts: extract_communality / correlations / proportions / Omega (PASS vs the real R accessors,
max abs diff ≤ 6.12e-6 at tol 1e-4) and POST-LOGLIK-NOBS / POST-NOBS-COUNT / POST-NOBS-FALLBACK
(exact). `loading_profile` held: an estimand-scope decision (confirmatory vs exploratory profile), not
a re-run. Ledger: REQUIRED=505 unchanged, BOUND 285→292, DISPOSITIONED 220→213. New standalone batch
`tools/core070_estimand_rebind_batch.{R,jl}` + verifier (self-tests passed) because the frozen wave5
batch cannot exercise those quantities.

**A5 — realistic-size (fbfb7a44 + addendum 317a0569).** Totoro pre-run p=20, n=500, K=1: R
1.25/1.74/12.99 s vs Julia 15.51/41.01/121.96 s (gaussian/poisson/nb2; Julia wall includes
fresh-process compile), cond(H) 40–100 both engines, max rel ΔSE ≤ 1.95e-5, no boundary flags. Nibi
(DRAC, "cleverly"): the array ran immediately despite the maintenance reservation; 16/24 tasks
completed at the original 10-min limit; Ada cancelled the array mid-run to resize it — an incident
recorded in the A5 addendum — and resubmitted the 8 largest cells as 21053691 (2 h, 6 GB): **7 of 8 COMPLETED** (wall 16m52s – 1h13m50s, ~99 % CPU efficiency, memory 418–780 MB per `seff`); `nb2_p50_n2000_K2` (task 24) **TIMEOUT** at 2h00m and was resubmitted as job 21059449 (`--time=05:00:00`, 4 GB; its K=1 sibling took 1h14m) — pending at report time. Pairing of the 7 new cells: `realistic-size-grid-2026-09-03.md` §Update (arc A5c). R side of the grid on Totoro: **24/24 complete** (19 min wall; largest cell 498 s, cond(H) 14137.7). R+gllvmTMB is not installed on Nibi, hence the Julia/R split.

**A5b — realistic-size pairing (bc96f540).** 14/24 cells validly paired by cell id (gaussian 8, poisson 4, nb2 2): max rel ΔSE over the β block 6.95e-6–1.58e-5 (worst `nb2_p20_n500_K2`); cond(H) Julia 19.3–2646.8, R 50.0–14137.7 — every cell with cond(H) > 1e3 is Gaussian (no β block), so the contract's conditioning scaling is untested by a β-comparable pair yet. Two pairs excluded as invalid: `poisson_p20_n500_K1` and `nb2_p20_n500_K1`, where the Totoro R driver reused spot-check outputs fitted on a different seed (filenames lack the seed) — recorded, not silently dropped. **A5c (20f15e1e)** paired the 7 large cells that completed on Nibi: max rel ΔSE (β) 2.19e-5 – 1.32e-4 (worst `poisson_p50_n2000_K1`; the p=50, n=2000 cells now dominate), cond(H) Julia 47–368, R 132–2103 — `poisson_p50_n500_K2` is the first β-comparable cell with R cond(H) > 1e3 and its Δ (3.76e-5) sits ~560× inside the contract's scaled bound; **22/24 valid pairs** after the last cell landed in the morning (`nb2_p50_n2000_K2`: 4h08m on Nibi; logLik Δ 1.6e-6, max rel ΔSE 6.3e-5, cond(H) Julia 858 vs R 14 138 — a parameterisation difference to settle in the contract; Julia 2h36m vs R 498 s), 2 invalid (R-driver seed mismatch, re-run owed), 0 pending. D-201 resize note written from `seff` (p=50/n=2000: ≥ 1h15m K=1, > 2 h nb2 K=2; recommend 3 h / 5 h, 1 GB). `docs/dev-log/core070/realistic-size-grid-2026-09-03.md`, receipts under `realistic-size-out/{nibi,totoro}/`.

**A6 — phylo transport S1/S2 (e18eeb59, ef95ef6f, 0d732bd6).** `PrecisionPhy` consumer (R
convention: root dropped, internal-first/tips-last, n_aug = 2p−2, log-det checksum) feeds the same
sparse-phylo kernel: max |ΔlogLik| vs AugmentedPhy = 0.0 on the 8-tip fixture at three σ²_phy,
log-det checksum diff 7.1e-15. `correlation=true` unit-height mode (opt-in, Q1) with
`GJL-GATE-PHYLO-NONULTRAMETRIC` (Q4): σ²_phy scales by exactly h = 0.3 at invariant logLik. Bundle
78 pass / 1 broken (pre-existing skip) on both Julia versions. S3/S4 not started (design order).

**A7 — docs cascade (0fe1c622, ffce3f3c, 82bc1760).** Fisher-retained list now matches source (only
GP-1); "what parity does NOT mean" section on the scoreboard; ZI-trio Julia-beyond note with the
12-cell recovery table and the 35 % cell; `mi()` row → implemented on a 57/57 test receipt (7 files).

**F1 follow-up (this loop).** `src/confint_family.jl`: a parameter the fit flags as `dispersion_boundary` is conditioned out even when the joint Hessian is barely PD (previously only on Cholesky failure), so the outcome no longer flips with the optimizer's stopping point; `pd_hessian=false` whenever a term is conditioned out. Deterministic forced-boundary test (r[2] set to 1e12 on a well-conditioned fit) added; docs page updated. Local verification: `test_confint_family.jl` 326/326 on Julia 1.12.6 and 1.10.12 (first attempts of the deterministic test failed on 1.12 only, on a precondition — a per-trait fixture at the boundary — and then on a fixed finite set; both were the test's assumptions, not the engine; the final form asserts the contract).

**A8 — design notes (622f4001).** T12 grouping levels: unit partial, unit_obs partial, cluster
missing, cluster2 missing, with required-row proposals; T8 AGHQ policy rows: 14 bindable with a
named public R call, 8 to reclassify (needs the maintainer's yes).

## 3a. Decisions and Rejected Alternatives

- Nibi over Vulcan/tamia for the grid: tamia in maintenance to October, Vulcan two CPU nodes and no
  depot, Nibi has the depot + outbound network. Rejected: Totoro-only for the grid (Totoro kept for
  pre-runs, the suite and the second-order batch).
- Push #2 was deferred behind the dispatched CI run so as not to cancel it; pushes used: **2** of 3 (push #1 bba953df 00:09Z; push #2 789bd97e ~01:45Z carrying A3/A4/A5/A5b/A6 + the F1 follow-up); the third is reserved for the close.
- Sentinel test: aligned to F1 semantics rather than changing the fixture (the fixture is documented
  as the sentinel's own).
- A5's `--time` mistake corrected by resubmission, not by editing the record.

## 4. Files Touched

`LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`; `.github/workflows/CI.yml`; `test/runtests.jl`,
`test/shard_util.jl`, `test/test_shard_selection.jl`, `test/test_known_sentinel_defects.jl`,
`test/test_phylo_precision.jl`, `test/test_sparse_phy.jl`; `src/phylo_precision.jl` (new),
`src/sparse_phy.jl`, `src/likelihood_sparse_phy.jl`, `src/GLLVM.jl`; `tools/core070_second_order/**`,
`tools/core070_estimand_rebind_batch.{R,jl}`, `tools/core070_verify_estimand_rebind_batch.py`,
`tools/core070_realistic_size*.{sbatch,jl,R,tsv}`; `docs/dev-log/core070/{second-order-batch-2026-09-03.md,second-order-batch-out/**,t5-rebind-2026-09-03.md,t5-rebind-out/**,realistic-size-prerun-2026-09-03.md,realistic-size-grid-2026-09-03.md,realistic-size-out/**,t12-grouping-levels-design.md,t8-aghq-policy-rows-proposal.md,required-source-case-map.json}`, `src/confint_family.jl`, `test/test_confint_family.jl`;
`docs/src/{gllvmtmb-parity,response-families,tutorial,api}.md`, `docs/design/capability-status.md`;
`docs/dev-log/check-log.md`; `docs/dev-log/decisions/2026-09-02-maintainer-decisions-true-parity.md`;
this report; `docs/dev-log/handover/2026-09-03-claude-handover.md`;
`docs/dev-log/plan-actual/2026-09-03-core070-overnight.md`. Remote: Totoro
`core070-aghq-20260830/{suite-run-03,second-order-01,t5-rebind-01,realsize-01}`; Nibi
`projects/def-snakagaw/snakagaw/gllvm-realsize-01/`.

## 5. Checks Run

- Totoro suite-run-02 (85918fe9): 13271/1/1/8 (both non-green diagnosed above). suite-run-03 (bba953df): 13327 pass / 0 fail / 0 error / 8 broken, exit 0 (68m06s).
- CI dispatch run 33699239628 (sharded): 7/8 shards success; Julia 1 shard 1/4 failure = 3469 pass / 8 fail (all in F1's seed-523 test), fixed by the follow-up; shard wall times ~30–55 min instead of 135–170 min per job.
- Aqua + JET (test env, Julia 1.12.6): 14/14 at 85918fe9.
- Per-arc test files on Julia 1.12.6 and 1.10.12: sentinel 25/1 broken; shard logic 43/43; phylo
  bundle 78/1 broken; mi() 57/57; bridge_x 183/183 earlier.
- Ledger counts: `TOTAL=769 REQUIRED=505 BOUND=292 DISPOSITIONED=213 FREE=0`.
- Gates (`gate-check.mjs --reverify`): leaf-A2 2/2, A3 2/2, A4 2/2, A5 2/2, A6 2/2, A7 2/2, A8 1/1;
  leaf-A1 G1 met (suite-run-03 green), G2 pending the CI verdict; leaf-A10 at close.

## 6. Tests of the Tests

Every engine change was red-first with the failure observed (S1: UndefVarError; S2: MethodError; T14
F1–F3 earlier). The shard partition test asserts disjoint-and-complete for four N. Verifiers ran
`--self-test` with mutation negatives before every re-bind. The A3 gate regex was corrected for
footnote marks after visually confirming the 20 rows; the measurement was not loosened.

## 7a. Issue Ledger

| # | Issue | State |
|---|---|---|
| 1 | GitHub delivered no pull_request event for push #1 (bba953df) | worked around by workflow_dispatch; watch on push #2 |
| 2 | Nibi array cancelled mid-run by Ada while resizing `--time` | 8 tasks resubmitted (21053691); no data lost; lesson in A5 addendum |
| 2b | The A5 child ran `git commit --amend` on the wrong commit (Ada's after-task draft), then restored it byte-identical under a new hash (f3c6140f → 1d5a9cd5, verified by empty diff; origin untouched) and put its own change in d02fd2cd | recorded; child stopped; history rewrite forbidden in every later brief |
| 3 | Julia fresh-process wall time 10–12× R at p=20, n=500 (compile included) | M3 performance track; not a parity item |
| 4 | Child saw `test_phylo_nb_xlv.jl` and `test_sparse_phy_grad.jl` failing locally on aarch64 before A6 | not seen on Totoro x64 suite-run-02; suite-run-03 on Totoro x64 is fully green (13327/0/0/8), so those two are aarch64-local only; recorded as such |
| 5 | `loading_profile` estimand scope (confirmatory vs exploratory) | maintainer decision |
| 6 | T8: 8 AGHQ policy rows to reclassify | maintainer yes needed |
| 7 | R+gllvmTMB not on Nibi → Julia/R grid split | pairing by cell id in the follow-up |

## 8. Consistency Audit

Neighbours walked: the scoreboard's Fisher paragraph against source; the T12 note against R's
`gllvmTMB()` signature on both frozen and main; the ledger counts after re-binds; the sentinel
test's other assertions unchanged; the LOOP kit's invariants against every action (≤120 Totoro
cores at all times: suite 3 + batch 40 + pre-run ≤ 9).

## 9. What Did Not Go Smoothly

Two children paused themselves waiting on their own background runs and had to be resumed; the
missing PR event cost 25 minutes of diagnosis (twice — push #2 needed a manual dispatch too); the
Nibi cancel was avoidable (read `squeue` first); the A5 child amended Ada's draft-report commit by
mistake and had to reconstruct it (content verified identical, hash changed); F1's first
red-first test assumed the seed-523 fixture's regime and failed on CI, and my first deterministic
replacement assumed a per-trait fixture stays off the boundary — both were test assumptions,
fixed by asserting the contract.

## 10. Known Residuals

Second-order tolerances unsigned (T3); the realistic-size grid's R/Julia pairing not yet written up;
S3/S4 phylo bridge slices not started; `loading_profile` and the AGHQ reclassification await the
maintainer; the two aarch64-only local failures need one reconciliation read.

## 11. Team Learning

**Memory receipt:** loaded the repo LOAD-FIRST manifest, `lane_preflight.sh`, D-64/D-139/D-143/D-201
via greps, the `compute-routing`, `arc-loop`, `unlazy` and `ultra-plan` skills, and the day's own
WHAT-WORKS entry — which the A5 child then violated (smallest-cell sizing) and Ada compounded (cancel
before `squeue`); both recorded. Recalled first via `/ask-brain` before scouting DRAC; nothing
re-scouted. **Golden Set:** in scope was FAILURE-TAXONOMY #11 (compute) — the guard fired (Totoro +
Nibi used, estimates written); `tools/memory_regression.py` is a transcript judge and was not run on
a transcript export. Rose verdict (S9, claim-vs-evidence audit): **BLOCKERS — 3, all repaired before the final commit**: (1) A5 said the R-side grid was 23/24 when the artifact shows 24/24; (2) the A5b pairing write-up (bc96f540) was missing from the report; (3) the A5-child amend incident was absent — now in §7a (2b) and §9. Audit file: session scratchpad `rose-overnight-audit.md`.

## 12. Cross-Product Coverage

This run **does NOT cover**: signed second-order tolerances; the 8 largest realistic-size cells (Nibi
21053691) and the two invalid pairs' re-run; a β-comparable pair at cond(H) > 1e3; phylo S3/S4 (bridge payload, R gate lift,
paired leaf); the 76 required_core rows needing a Julia surface; real-data acceptance runs; any
merge. Melissa plan-vs-actual: `plan-actual/2026-09-03-core070-overnight.md`.
