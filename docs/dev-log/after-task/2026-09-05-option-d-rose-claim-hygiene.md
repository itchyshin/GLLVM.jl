# After-task — Option D Rose claim hygiene (2026-09-05)

## Scope

Parallel Option D slice: read-only Rose scan + surgical prose edits only.
Did **not** touch #281 merge, §6 holdouts disposition, advisory R smoke scripts,
or engine code.

## Stale claims corrected

| Surface | Before | After |
|---------|--------|-------|
| `AGENTS.md` identity | "digital twin … at ~10× speed" | Julia companion; ledger ≠ true parity pointer |
| `AGENTS.md` headline | "machine precision" vs R | six significant digits on published grid |
| `AGENTS.md` phase snapshot | "Wald coverage 0.932–0.958" read as certificate | arcG undercoverage **evidence**; 0.7.1 withdrew 0.94 floor |
| `CLAUDE.md` headline | "machine precision" + no ledger fence | six sig digits + FREE=0 ≠ true parity |
| `docs/src/roadmap.md` | "digital twin" / "complete R bridge" v1.0 | companion + narrow bridge; v1.0 = true-parity map |
| `docs/src/gllvmtmb-parity.md` | DRAC coverage as "certification" | diagnostic programme; arcG evidence not calibration |
| `docs/design/capability-status.md` | (no arcG row) | partial arcG/DRAC diagnostic row + note |
| `docs/src/index.md` | generic companion wording | ledger ≠ parity; coverage = evidence not certificate |

## Verification

```sh
rg -n "0\.94 coverage|coverage floor|true parity complete|full twin|0\.7\.1 feature parity|parity and beyond|digital twin|machine precision" \
  AGENTS.md CLAUDE.md docs/src/roadmap.md docs/src/gllvmtmb-parity.md docs/src/index.md docs/design/capability-status.md
```

Post-edit: remaining "machine precision" hits are scoped (internal phylo cross-check, GP-1 parity exception, historical changelog correction block).

## Not claiming

- True parity complete
- Calibrated interval coverage
- 0.7.1 feature parity port
- Second-order contract §7 closure

Branch: `cursor/option-d-rose-hygiene-20260905` @ twin worktree.
