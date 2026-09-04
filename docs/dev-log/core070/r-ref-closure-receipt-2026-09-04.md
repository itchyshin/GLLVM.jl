# `--r-ref` joint CLOSURE receipt — 2026-09-04

G0: Option A + Ada defaults. Slice S2 (parity tool pin trust).

## Command

```sh
cd /Users/z3437171/local-scratch/lanes/gllvmTMB-gllvm-twin-20260904
Rscript tools/parity_ledger.R \
  --ref origin/main \
  --r-ref origin/main \
  --julia-repo "/Users/z3437171/local-scratch/lanes/GLLVM.jl-gllvm-twin-20260904"
```

## Pins

| Side | Ref | Path |
|---|---|---|
| R capability ledger | `origin/main` @ gllvmTMB twin | `docs/design/capability-status.md` via `git show` |
| Julia capability ledger | `origin/main` @ GLLVM.jl twin | `docs/design/capability-status.md` via `git show` |

Note: `capability-status.md` does not exist at frozen oracle `b4d5fee6` on either repo. Export-level parity at that pin uses `GLLVM.jl/tools/parity_ledger.py` on `NAMESPACE`.

## Outcome

```
R ledger:     git -C "<gllvmTMB twin>" show origin/main:docs/design/capability-status.md (76 rows)
Julia ledger: git -C "<GLLVM.jl twin>" show origin/main:docs/design/capability-status.md (80 rows)
COUNTS: 48 matched (...), 32 R-only, 32 Julia-only
CLOSURE: PASS -- every one of 32 Julia-only rows carries a port/accounted/divergence disposition, 0 near-misses, all 4 grouping-level rows present, collision rows join correctly, all 19 R-NARROWER row(s) listed (not hidden)
```

Exit code: **0**.

## Before/after

Pre-patch: R ledger read from **working tree** (`R_LEDGER_PATH` on disk) while Julia side used `git show` — one lane could edit R's file uncommitted and still print CLOSURE PASS (D-220 caveat).

Post-patch: default `--r-ref origin/main`; `--r-ref working-tree` restores legacy behaviour for local generator runs.
