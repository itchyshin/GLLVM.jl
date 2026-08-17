# Overnight handoff — north-star surface admits (2026-08-17)

**Operator:** Cursor (Shinichi AFK → ~05:00 MDT)  
**Lane:** `cursor/orderedbeta-nox-20260817` (engine) + this docs pulse  
**Stop write:** 2026-08-17 ~02:45 MDT  
**Never `--auto`.** Merge only after full Julia + Documenter SUCCESS.

## SHAs (as of write)

| Ref | SHA | Note |
|---|---|---|
| `origin/main` tip | `320c83b1` | merge of #245 (BetaHurdle engine) |
| #241 merge | `5bd236dc` | COM-Poisson no-X engine (already on main at session start) |
| #242 merge | `fce43de4` | HurdleNB Identity (docs-only, tag-payload `r`) |
| #243 merge | `104ec5a7` | BetaHurdle Identity (docs-only, tag-payload `φ`) |
| #244 merge | `07a01ede` | HurdleNB no-X engine |
| #245 merge | `320c83b1` | BetaHurdle no-X engine |
| #246 head | `aec2347a` | OrderedBeta no-X engine — **CI running; not merged** |

## Done overnight

1. Skipped #241 rebase (already merged as `5bd236dc`).
2. HurdleNB Identity **#242** → merged `fce43de4`.
3. BetaHurdle Identity **#243** → merged `104ec5a7`.
4. HurdleNB no-X engine **#244** → merged `07a01ede` (focused 24/24 in 22.7s).
5. BetaHurdle no-X engine **#245** → merged `320c83b1` after full CI SUCCESS
   (Documenter + Julia 1.10 ubuntu + Julia 1 ubuntu/macOS/Windows).
6. OrderedBeta no-X engine **#246** opened from `320c83b1`:
   - Export `OrderedBeta`; `OrderedBeta() = OrderedBeta(-1.0, 1.0, 10.0)`
   - Include `ordered_beta.jl` moved **before** `fit_gllvm.jl`
   - `_fit_gllvm(::OrderedBeta)` → `fit_ordered_beta_gllvm`
   - Tag-inert: `OrderedBeta()` ≡ `OrderedBeta(0, 2, 3)` on `c0`, `c1`, **and** `φ`
   - Mac-LIGHT: `test/test_ordered_beta.jl` **36/36** in 11.5s
   - Identity: `docs/dev-log/decisions/2026-08-16-orderedbeta-fit-gllvm-identity.md` (#240)
   - URL: https://github.com/itchyshin/GLLVM.jl/pull/246

Tweedie `fit_gllvm` surface admit was **not** opened (Identity STOP; T2–T5 unpaid).

## Identity locks still in force

| Family | Marker | C1 | C1b | C2 |
|---|---|---|---|---|
| HurdleNB | `r` tag payload | never read; no `r_init` | `HurdleNB() = HurdleNB(10.0)` | → `fit_hurdle_nb_gllvm` |
| BetaHurdle | `φ` tag payload | never read; no `φ_init` | `BetaHurdle() = BetaHurdle(5.0)` | → `fit_beta_hurdle_gllvm` |
| OrderedBeta | `c0`, `c1`, `φ` tag payloads | never read; never inits; **not** Ordinal `τ₁=0` | `OrderedBeta() = OrderedBeta(-1.0, 1.0, 10.0)` | → `fit_ordered_beta_gllvm` |

C3: no bridge, no twin Δ (twin `.valid_family` ids 0–16 have none of these).  
C4: no +X / `disp_group` / `row_eff`.  
`"ordered"` on the bridge already means **ordinal** — do not reuse.

## Remaining (do not claim done)

- **#246 CI** — wait full Julia matrix + Documenter + `documenter/deploy` SUCCESS,
  then `gh pr merge 246 --merge`. Confirm `mergeable=MERGEABLE` / `CLEAN`.
- **Tweedie** — Identity STOP. Do **not** open a `fit_gllvm` admit. T2–T5 unpaid.
- Twin light Δ: untouched. Mac-light (no local `Pkg.test`). Full suite = GH CI.
- Do **not** force-push; do **not** widen rtol; stage by name.

## Next 3 morning actions

1. `gh pr view 246 --json mergeable,mergeStateStatus,statusCheckRollup` — if
   all SUCCESS and `CLEAN`, `gh pr merge 246 --merge` (never `--auto`). If
   Windows stuck >2.5h with peers green, rerun Windows once. If `CONFLICTING`
   or dirty vs `origin/main`, rematch by merging `origin/main` into the PR
   branch (no force-push).
2. `git fetch origin main && git log -5 --oneline origin/main` — confirm
   #245 is on main; confirm #246 only after it actually merges. Do **not**
   open Tweedie `fit_gllvm`.
3. Optional MC / capability pulse only. Surface-admit sequence for this
   overnight is HurdleNB → BetaHurdle → OrderedBeta. Stop after #246.

## Open PRs at handoff write

- **#246** OrderedBeta no-X engine — CI in progress at write.
  https://github.com/itchyshin/GLLVM.jl/pull/246
- This handoff docs PR (if opened separately).

## Worktrees (this session)

| Path | Branch | Role |
|---|---|---|
| `.worktrees/gllvmjl-hurdlenb-identity-20260817` | `cursor/hurdlenb-identity-20260817` | #242 merged |
| `.worktrees/gllvmjl-betahurdle-identity-20260817` | `cursor/betahurdle-identity-20260817` | #243 merged |
| `.worktrees/gllvmjl-hurdlenb-nox-20260817` | `cursor/hurdlenb-nox-20260817` | #244 merged |
| `.worktrees/gllvmjl-betahurdle-nox-20260817` | `cursor/betahurdle-nox-20260817` | #245 merged |
| `.worktrees/gllvmjl-orderedbeta-nox-20260817` | `cursor/orderedbeta-nox-20260817` | **#246 in flight** |
| `.worktrees/gllvmjl-overnight-surface-handoff-20260817` | `cursor/overnight-surface-handoff-20260817` | this file |

Dropbox checkout stays on stale `claude/jl-bridge-capabilities-20260619` —
**do not work there.** Use `.worktrees/` from `origin/main`.
