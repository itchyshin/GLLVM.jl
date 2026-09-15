# After-task: leftover open PR triage (Mac true-parity)

2026-09-15, Mac Studio true-parity (report only). `origin/main` is `9519b3e28` (#371 MERGED on #369 `c00e9345`). `gh pr list --state open` returned four leftovers. No merges. No `src/` edits.

## Skip list (confirmed)

Matches the Mac handover (`docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md`) and the pending board:

| PR | Why skip stays | Live state |
|----|----------------|------------|
| [#363](https://github.com/itchyshin/GLLVM.jl/pull/363) Cloud Agent env | Unrelated to true-parity. Draft is also dirty: 87 files include leftover Lognormal/Trunc* Wald commits (already on main via #361) plus `.worktrees/` noise. | DRAFT · CONFLICTING · DIRTY |
| [#314](https://github.com/itchyshin/GLLVM.jl/pull/314) old D-220 handover | Stale 2026-09-07 Codex handoff. 183 files / +35k; no CI. Superseded by later Mac handovers. | DRAFT · CONFLICTING · DIRTY |
| [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) bridge logLik receipts | Foreign. Julia 8/8 + Documenter green; Frozen R advisory FAIL OK. Conflict is `check-log.md` only. Owner rebases; this lane does not edit. | OPEN · CONFLICTING · DIRTY |

## Leftovers that need a Mac decision

| PR | State | Checks (this snapshot) | Recommended action |
|----|-------|------------------------|--------------------|
| [#367](https://github.com/itchyshin/GLLVM.jl/pull/367) StudentTFit fixed-ν Wald | OPEN · **MERGEABLE** · UNSTABLE (not draft) | Documenter **green**. All 8 Julia shards + Frozen R advisory **still running**. | **Ada owns merge.** Babysit until Julia + Documenter green (Frozen R FAIL OK). Do not merge from this note. After merge: board + `LOOP/checkpoint.md` tip. |

Already closed (not leftovers): #369 MERGED `c00e9345`; #370 MERGED `c459751bf`; #371 MERGED `9519b3e28` (Active goal + #291 ultra-plan pointers landed on `main`).

## #367 detail (report only)

- Branch `cursor/studentt-fixed-nu-wald-ci-a0ce`. +224/−17 across 8 files, including `src/confint_family.jl` and `test/test_second_order_studentt_ci.jl`.
- Handover still says OPEN CONFLICTING in places; live GitHub is **MERGEABLE**. Board tip is stale on that point.
- Claude lease still covers `docs/dev-log/`, `LOOP/`, `src/confint_family.jl`, `test/`. Parallel Wald edits on those paths stay refused.
- This slice did **not** merge, rebase, or push.

## #371 (closed at bank time)

- MERGED as #371 `9519b3e28` while this triage was held for lease. No longer an open PR.
- Residual board/check-log/LOOP collision with #367 tip refresh still applies after #367 lands.

## Next (Ada)

1. Wait for #367 Julia shards. Merge when green (Frozen R advisory OK). This lane does not merge.
2. Refresh board/checkpoint for Student-t fixed-ν PARTIAL after #367 is on `main`.
3. Leave #363 / #314 / #357. Next ungated engine slice only after #367 is on `main` (BB shared-φ is the handover's pick).

## Checks

```text
gh pr list --repo itchyshin/GLLVM.jl --state open
# 367 OPEN · 363 DRAFT · 357 OPEN · 314 DRAFT  (#371 merged)
git rev-parse --short origin/main   # 9519b3e28
```

Tests / JET / Allocs / Aqua / R-parity: **N/A** (docs-only triage).

Rose verdict: PASS WITH NOTES. Skip list confirmed. #367 not merged (Ada). #371 already on `main`. Lease on `docs/dev-log/` is held by `cursor:mac-true-parity-367`; scratch bank only (lease REFUSED for parallel commit).
