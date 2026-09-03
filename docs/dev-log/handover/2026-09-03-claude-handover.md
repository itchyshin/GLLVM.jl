# Handover → Claude, 2026-09-03 (morning after the overnight arc-loop)

You are Claude picking up lane `codex/core070-aghq-20260830` (worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`). You inherit no chat context; this file, `LOOP/GOAL.md`,
`LOOP/checkpoint.md` and the after-task report `docs/dev-log/after-task/2026-09-03-core070-overnight.md`
are authoritative. Read them in that order, then `AGENTS.md`.

## What happened overnight (2026-09-02 23:15Z → 2026-09-03)

The maintainer's four answers (recorded in `docs/dev-log/decisions/2026-09-02-maintainer-decisions-true-parity.md`
§Overnight envelope) authorised an autonomous arc-loop. Landed, all with receipts and ledger gates
(`.unlazy/core070-overnight/`, git-ignored, all leaves MET or ABANDONED with reason):

| arc | result | commits |
|---|---|---|
| A1 T14 landed | Totoro suite green except one env error + one sentinel assertion aligned to F1 semantics; pushed; CI via workflow_dispatch after GitHub dropped the PR event | bba953df … |
| A2 CI sharded | 8 Julia jobs (4 shards × 2 versions); coverage only on dispatch; ~30 min per shard | afd66551 |
| A3 second-order receipts | 20/20 paired cells; SE rel Δ median 6e-6 max 1e-4; Wald endpoints max 3e-5; none above the draft tolerances | 06f4b97a |
| A4 T5 re-runs | 7/8 rows re-bound on frozen-oracle receipts (BOUND 285→292); `loading_profile` held for an estimand decision | 76b8b28f |
| A5 realistic-size | Totoro pre-run 3 cells; Nibi array 24 cells (16 done + 8 resubmitted as 21053691); R side on Totoro 23/24 | fbfb7a44, 317a0569 |
| A6 phylo S1/S2 | `PrecisionPhy` consumer (bitwise logLik match, log-det 7e-15) + `correlation=true` mode with the non-ultrametric gate | e18eeb59, ef95ef6f, 0d732bd6 |
| A7 docs | Fisher list fixed; "what parity does NOT mean"; ZI-trio note; `mi()` → implemented on a 57/57 receipt | 0fe1c622, ffce3f3c, 82bc1760 |
| A8 design notes | T12 grouping levels (unit/unit_obs partial; cluster/cluster2 missing); T8 AGHQ rows (14 bindable, 8 reclassify) | 622f4001 |

Final state (close, ~03:10Z): pushes used **3 of 3** (bba953df 00:09Z; 789bd97e ~01:45Z; the close push = HEAD of this commit's successor, see `git log origin/codex/core070-aghq-20260830 -1`). CI: run 33699239628 (bba953df) 7/8 shards green; run 33705916094 (789bd97e) 6/8 green, the reds being one bit-literal test fixed in df109411 — **the close push's run is the one to read in the morning** (if GitHub drops the PR event again, dispatch it). Totoro suite-run-03 at bba953df fully green (13327/0/0/8). Ledgers: `.unlazy/core070-overnight/` leaves A1–A8 ALL MET, A10 verified after the close push. Rose: 3 blockers repaired. Melissa: 6 adaptive / 3 drift / 1 unclear. K9 mechanical verify: ALL OK. Nibi job 21059449 (last grid cell) pending.

## Owed next (in order)

1. **CI is green on the current head**: run 33746827144 (e76ee018, the lane merged with `origin/main`)
   passed all 8 Julia shards; the close push's run 33710504809 did too. PR #277 is mergeable with only
   the advisory frozen-R smoke red — **merging it is yours**; Totoro `suite-run-03/suite.end`. Reconcile the two aarch64-only
   local failures the A6 child saw (`test_phylo_nb_xlv.jl`, `test_sparse_phy_grad.jl` p=120) against
   the x64 suite; if they are platform-only, record them as such in the check-log.
2. **Realistic-size grid: 22/24 paired** (`docs/dev-log/core070/realistic-size-grid-2026-09-03.md`);
   owed: re-run the 2 invalid cells (idx 9, 17) with the seed in the R driver's filenames; decide which
   engine's cond(H) the contract's scaling uses (they differ 858 vs 14 138 on the largest cell).
3. **Bring the maintainer**: (a) T3 tolerances to sign (`second-order-parity-contract.md` §4; the
   receipts now show what "the same" looks like at toy and realistic scale); (b) `loading_profile`
   estimand scope; (c) T8: reclassify 8 AGHQ policy rows?; (d) T12: are the four level names the
   ledger keys, and is `unit_obs` a new surface (design note has the mapping); (e) the two relayed
   items still pending direct confirmation (grouping levels; ZI trio to R).
4. **Phylo S3** (bridge payload + R gate lift for phylo/animal) only after the maintainer confirms the
   Q1–Q4 defaults survive the morning read; S4 paired leaf after that.
5. **Push budget**: pushes used overnight are stated in the close line; each push re-triggers ~30-min
   sharded CI; if GitHub drops the PR event again, `gh workflow run CI.yml --ref codex/core070-aghq-20260830`.

## Gotchas learned tonight (do not repeat)

- **A queued DRAC array can already be running** — `squeue` before `scancel`. Size `--time` from the
  most expensive cell class, not the cheapest (the WHAT-WORKS entry of 2026-09-02 says so; the A5
  child and Ada both slipped).
- GitHub can silently deliver **no pull_request event** for a push; `actions/runs?head_sha=` returning
  0 with status operational is the signature; dispatch manually.
- Children that wait on their own background runs stop; resume them with a message telling them to
  Read the output file.
- `test/Project.toml` gets modified by any `Pkg.develop(path=".")` in the test env; revert it.
- The frozen R oracle is NOT on Nibi; Julia-only there, R on Totoro.

## How to resume

```sh
cd /private/tmp/GLLVM.jl-core070-aghq-20260830
~/shinichi-brain/tools/lane_preflight.sh .
git status -sb && git log --oneline -12
gh run list --branch codex/core070-aghq-20260830 --workflow CI.yml --limit 3
cat LOOP/checkpoint.md
```
