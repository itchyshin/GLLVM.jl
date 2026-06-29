# Recovery Checkpoint: phylo X_lv DRAC wait state

Date: 2026-06-29 09:37 MDT

Branch: `codex/phylo-xlv-drac-launcher-20260628`

Head: `c315ca3 docs: record phylo xlv narval sizing pilot`

`git status --short --branch`:

```text
## codex/phylo-xlv-drac-launcher-20260628
```

`git diff --stat`:

```text
```

## Commands Already Run

- `julia --project=. test/test_confint_derived_wald.jl` passed `115/115`.
- Tiny local `bench/phylo_xlv_drac_task.jl --targets phylo_signal` smoke
  passed and wrote a row with `ci_seconds=2.829`.
- Nibi/Rorqual old per-trait phylo-signal target jobs were cancelled before
  entering the old one-Hessian-per-trait path.
- Replacement p=200, K=2 phylo-signal target-only jobs were submitted from
  source label `451090c-rsync-no-git`:
  - Nibi job `16927325`;
  - Rorqual job `14909918`.
- Old p=200, K=2 all-target Nibi job `16923927` remains running to measure
  the B_lv Wald bottleneck.
- Narval was instantiated with `Pkg.instantiate()` / `Pkg.precompile()`;
  `using GLLVM` succeeded.
- Narval p=150, K=2 B_lv-only sizing job `64331208` was submitted and started.
- gllvmTMB draft PR `#571` was checked: still draft, merge-clean, and Ubuntu
  R-CMD-check green.
- GLLVM.jl draft PR `#127` was checked: still draft/unstable; Documenter green,
  CI failed on Ubuntu/macOS/Windows from the older remote SHA.
- `/tmp/gllvm-dashboard/status.json` was updated through `09:38 MDT`.

## Live Jobs To Poll

- Nibi `16923927_1`: p=200, n_sites=200, K=2, all-target job, 4h cap.
  The fit converged in 47 iterations after `1394.49s`; at the last poll
  (`~2:01:35` wall time) it was still inside `B_lv CI start method=wald`.
- Nibi `16927325_1`: p=200, n_sites=200, K=2, `--targets phylo_signal`,
  2h cap. At the last poll (`~16:55`) it was still in the fit step.
- Rorqual `14909918_1`: p=200, n_sites=200, K=2, `--targets phylo_signal`,
  2h cap. At the last poll (`~17:11`) it was still in the fit step.
- Narval `64331208_1`: p=150, n_sites=150, K=2, `--targets B_lv`, 3h cap.
  At the last poll (`~5:11`) it was still in the fit step.

## Next Commands

Use light queue/log/result polling first:

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16927325 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-batched-iter80-2h-20260629-0918/logs/phylo_xlv_h2b-16927325-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-batched-iter80-2h-20260629-0918/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14909918 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-batched-iter80-2h-20260629-0918/logs/phylo_xlv_h2b-14909918-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-batched-iter80-2h-20260629-0918/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64331208 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/logs/phylo_xlv-64331208-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/results/result_000001.csv 2>/dev/null || true'
```

After any job finishes, run `seff <jobid>` on that cluster, record the result
CSV/log/seff in `docs/dev-log/check-log.md`, update
`/tmp/gllvm-dashboard/status.json`, and decide whether p=200, K=2 remains a
production blocker or whether p=150 can be the large K=2 production boundary.

## Next Safest Action

Wait for one of the four live jobs to finish or time out. Do not launch any
`>=500` reps/cell production array until the p=200, K=2 interval timing strategy
is resolved. Do not push this GLLVM.jl branch unless the maintainer explicitly
asks.

## Blocking Question

No immediate maintainer question. The likely decision point is whether V1
production coverage may define the K=2 large cell as `p=150` if p=200 remains
too slow for observed-information interval coverage.
