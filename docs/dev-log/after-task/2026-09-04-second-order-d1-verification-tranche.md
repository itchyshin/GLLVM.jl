# After-task — second-order D1 verification tranche (2026-09-04)

## Scope

Post-merge execution slice: merge PRs #280 (GLLVM.jl) and #1268 (gllvmTMB), then
gate existing second-order receipts under signed D1/D2 defaults
(`second-order-parity-contract.md` §4–§5, `maintainer-decision-set-2026-09-03.md`
D1–D2).

## Merge results

| Repo | PR | Merge SHA | Merged (UTC) | CI at merge |
|---|---|---|---|---|
| GLLVM.jl | [#280](https://github.com/itchyshin/GLLVM.jl/pull/280) | `b4447e16ce5fd169cf09f854b21a56c933858a88` | 2026-09-04T16:31:44Z | 2 CI shards pending; advisory R smoke fail; Documenter pass |
| gllvmTMB | [#1268](https://github.com/itchyshin/gllvmTMB/pull/1268) | `1e44d8d229120439893b482bced6b09c87cd362f` | 2026-09-04T16:31:48Z | ubuntu shard 1/4 fail; shards 2–4 pass |

Both PRs were drafts; marked ready, then squash-merged per maintainer instruction.

Worktree `/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904` merged
`origin/main` → `f873ee69`.

## Second-order receipts (object counts, D1 each-own-optimum)

**Toy archive (20 cells, 2026-09-03 batch):** SE **20 pass / 0 fail**; vcov **15 pass /
0 fail / 5 skip** (full-block route on nb2 boundary); Wald endpoints **20 / 0**.

**Post-merge smoke (contract §6 batch-1 families, local re-run on merged tip):**
5 cells → **5 / 0** under D1.

**Realistic-size paired grid (24 cells, Nibi Julia + Totoro R outputs on disk):**
24/24 paired; **22/24** first-order paired (`|ΔlogLik| < 1e-4`); idx **9** (poisson
p20 n500 K1) and **17** (nb2 p20 n500 K1) are mismatched optima. Among cells with
second-order fields in the collect script: SE **14/0/8 skip**; vcov **14/0/8**; Wald
**14/0/8** (8 gaussian cells lack β-block SE/vcov in collector output).

Machine-readable tally: `docs/dev-log/core070/second-order-d1-gate-receipt-2026-09-04.json`.

## Checks run

```text
python3 gate script on second-order-batch-out/*.json (D1 tolerances, R cond scaling)
julia --project=. tools/core070_second_order/run_cell.jl ×5 (batch-1 smoke)
python3 tools/core070_realistic_size_collect.py nibi totoro + D1 gate
gh pr view 280/1268 --json state,mergedAt,mergeCommit
```

Totoro ControlMaster socket: **absent** — no remote re-run; local smoke only.

## Outcome

Second-order machinery is **receipted under signed D1** on toy + realistic shapes where
paired optima agree; **not** a programme-level second-order parity claim (contract §7).

## Follow-up

- Refresh full 20-cell toy batch on merged main when a Totoro slot is available.
- Investigate realistic idx 9/17 local-optima divergence before counting them in any claim.
- Extend realistic collect script for gaussian β-block SE/vcov.
- Matched-coordinates diagnostic tier still unimplemented.

## Review lenses

- **Fisher:** tolerance tier applied with R-side cond(H) scaling (D2).
- **Rose:** merge CI caveats recorded; no "second-order parity complete" wording added.
