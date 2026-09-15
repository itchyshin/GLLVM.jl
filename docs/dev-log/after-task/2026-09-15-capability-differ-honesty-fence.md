# After-task — capability DIFFER / planned-missing honesty fence (docs-only)

**Date:** 2026-09-15  
**Lane:** Cursor / Ada (true-parity `/goal`, parallel leaf)  
**Branch:** `docs/capability-differ-fence-20260915` from `origin/main`  
**Scope:** Wording fences only — **no** `src/`, **no** ledger JSON, **no** status
promotion, **no** `Project.toml`, **no** gllvmTMB edits, **no** LOOP/checkpoint /
pending-board touch.

## Rose fence (read first)

- **This slice ≠ closing the six gaps ≠ `covered` promotion ≠ true parity.**
- **Harness / bridge partial ≠ twin capability row matched** when the join says
  **DIFFER** or Julia status is `planned` / `missing`.

## Goal

Make the **6 twin-join DIFFER rows** and the worst **planned/missing** misreads
visible so public and internal docs do not imply covered twin parity.

## Source inventory (read-only)

- `docs/dev-log/after-task/2026-09-15-true-parity-ledger-gap-inventory.md` (Layer 4)
- `docs/design/capability-status.md` (Julia MC ledger)
- `docs/src/gllvmtmb-parity.md` (reader scoreboard)
- Twin join headline: **48 matched / 32 R-only / 33 J-only / 6 DIFFER**
  (`tools/parity_ledger.R` @ frozen oracle — not re-run this slice)

## Six DIFFER rows fenced

| # | Row | R (twin join) | Julia | Fence applied |
|---|-----|---------------|-------|---------------|
| 1 | `spatial × dep` | scope-limited | `planned` | §Twin join table + existing fail-loud note (#329) |
| 2 | `phylo_latent + lv = ~ x` | planned | `rejected` | §Twin join — intentional refusal |
| 3 | `multinomial / categorical` | scope-limited | `missing` | §Twin join + existing FE vs Design 123 comment |
| 4 | Simulation-validated coverage certificate | scope-limited | `missing` | §Twin join; arcG `partial` ≠ this row |
| 5 | AGHQ estimator | scope-limited (opt-in) | `missing` | §Twin join + existing AGHQ identity notes |
| 6 | Mixed-family response vector | scope-limited (R programme validated) | `planned` | §Twin join + bridge row relabelled (transport only) |

## Planned / missing — false parity reads addressed

| Misread | Correction |
|---------|------------|
| Bridge **mixed-family** `implemented` ⇒ twin row closed | Bridge point-fit only; matrix row stays `planned` (DIFFER #6) |
| Julia **implemented** on Arc 0 grid ⇒ gllvmTMB `covered` | Existing Arc 0 caveats retained; §Twin join points to scoreboard fences |
| **arcG / DRAC** Wald diagnostics ⇒ simulation coverage certificate | Row 4 DIFFER; `gllvmtmb-parity.md` already fences coverage out of parity |
| **R-NARROWER (21)** Julia ahead of R scope-limited | Named in §Twin join as promotion fence, not superiority claim |

## Files touched

- `docs/design/capability-status.md` — new § *Twin join — six DIFFER rows*; bridge mixed-family status clarified
- `docs/src/gllvmtmb-parity.md` — new § *Twin capability matrix — six DIFFER rows* (surgical)
- `docs/dev-log/after-task/2026-09-15-capability-differ-honesty-fence.md` — this report

## Checks run

```text
# Documenter / pkg hygiene (local, worktree)
julia --project=docs docs/make.jl   # expect green on docs-only diff
```

(Paste CI / Documenter outcome on PR merge.)

## Rose self-check (pre-merge)

- [ ] No `implemented` → `covered` promotion anywhere in the diff
- [ ] No `Project.toml` / `src/` / test / LOOP / pending-board edits
- [ ] DIFFER table matches inventory after-task (6 rows, same keys)
- [ ] Bridge mixed-family cannot be read as closing mixed-family matrix row
- [ ] `gllvmtmb-parity.md` still states harness ≠ true parity; new subsection links internal ledger
- [ ] No claim that Core070 FREE=0 implies twin capability alignment
- [ ] Twin repo untouched (read-only reference)

## Follow-up (out of scope here)

- Julia-only arcG disposition for R `parity_ledger.R` CLOSURE (inventory rank 7)
- Capability promotion pass (DestB G2) — separate Rose-gated arc
- Pending board / LOOP checkpoint pointer — owning lane only
