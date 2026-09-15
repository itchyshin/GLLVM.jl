# Mac Studio true-parity handover (2026-09-15)

**Lane:** new **Mac Studio** main (Shinichi + `shinichi-brain`) · **Programme:** honest-0.7 / true-parity vs frozen `gllvmTMB` 0.7.0  
**From:** Cursor Cloud babysit tranche (Wald leftovers + board tips)  
**Twin:** gllvmTMB at `/agent/repos/gllvmtmb` (or local twin checkout) — **read-only for engine** (TMB/likelihood); tools disposition PRs OK

**Programme goal: NOT complete.** Do not mark `/goal` done. Core070 `FREE=0` ≠ true parity.

### Lane status (2026-09-15 — Mac STARTED)

**Mac Studio owns the true-parity programme.** Cloud is **babysit-only** for in-flight **#367** (Student-t fixed-ν Wald) and any residual docs for this handover (#369 MERGED @ `c00e9345`). **Do not start new ungated slices from cloud.** Fences unchanged (#357 foreign; no Stage 1 / S4 / Totoro / `Project.toml` bump without paste). Goal still **not** complete.

---

## START HERE (Mac Studio — new chat)

```bash
# 1. Rehydrate GLLVM.jl from origin/main
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"   # or your Mac Studio path
git fetch origin main
git checkout main && git pull origin main
git rev-parse --short origin/main   # expect ≥ 1671b947 at handoff; refresh if #367 merged

# 2. Lane preflight + brain contract
~/shinichi-brain/tools/lane_preflight.sh .
sed -n '1,120p' ~/shinichi-brain/AGENTS.md

# 3. Read this handover + live boards (live git outranks this summary)
sed -n '1,260p' docs/dev-log/handover/2026-09-15-mac-studio-true-parity-handover.md
sed -n '1,120p' docs/dev-log/2026-09-14-true-parity-pending-board.md
sed -n '1,80p'  docs/dev-log/core070/second-order-holdouts-2026-09-04.md
sed -n '1,40p'  LOOP/checkpoint.md
sed -n '1,80p'  docs/dev-log/coordination-board.md

# 4. Twin tip (read-only reference)
cd "/Users/z3437171/Dropbox/Github Local/gllvmTMB"   # twin path
git fetch origin main && git rev-parse --short origin/main   # handoff: fba20d61

# 5. Open PR / CI snapshot
gh pr list -R itchyshin/GLLVM.jl --state open
gh pr view 367 -R itchyshin/GLLVM.jl --json state,mergeable,statusCheckRollup,url
```

Then classify **ungated vs paste-gated** against the live board before editing. Cloud is weak on vault decisions — prefer Mac + brain for paste/Shinichi gates.

---

## Evidence tip (rehydrate)

| Repo | Tip at handoff | Notes |
|------|----------------|-------|
| GLLVM.jl `origin/main` | **`1671b947`** | Board tip after **#366** MultinomialFit Wald (`#368`) |
| gllvmTMB `origin/main` | **`fba20d61`** | Twin tip; arcG CLOSURE via #1284 already on main |
| Frozen R oracle | **`b4d5fee64def88bc768dda1f1f77c29b295edd86`** | Unchanged; Destination B / smoke authority |
| `Project.toml` | **`0.3.0`** | No bump (D-183) |

**Just merged today (2026-09-15) onto `main`:** #355 aliases, #356 TweedieGrouped Wald, #361 Lognormal+TruncPois+TruncNB2 Wald, #362 OrdinalPerTrait Wald, #366 Multinomial FE Wald, plus board hygiene #364/#365/#368 (and earlier same-day docs #347–#360 tranche). See table below.

**#367 Student-t fixed-ν Wald:** **OPEN** at handoff — CI partially green, **`mergeable: CONFLICTING`** vs tip `1671b947` (needs rebase after #366/#368). Not yet on `main`.

---

## Done this cloud tranche

| PR | SHA (merge / tip) | What | State |
|----|-------------------|------|-------|
| [#355](https://github.com/itchyshin/GLLVM.jl/pull/355) | `e87a4670` | `parity_ledger` TWIN_ALIAS ALIASES (FORWARD 77→62) | **MERGED** |
| [#356](https://github.com/itchyshin/GLLVM.jl/pull/356) | `569cd873` | `TweedieGroupedFit` Wald `_CIFit` (post §2 A) | **MERGED** |
| [#361](https://github.com/itchyshin/GLLVM.jl/pull/361) | `efc24554` | Lognormal + TruncPois + TruncNB2 Wald | **MERGED** |
| [#362](https://github.com/itchyshin/GLLVM.jl/pull/362) | `c1962c5d` | OrdinalPerTraitFit/CovFit Wald | **MERGED** |
| [#366](https://github.com/itchyshin/GLLVM.jl/pull/366) | `c1842dd6` | MultinomialFit FE Wald + board refresh | **MERGED** |
| [#364](https://github.com/itchyshin/GLLVM.jl/pull/364) / [#365](https://github.com/itchyshin/GLLVM.jl/pull/365) / [#368](https://github.com/itchyshin/GLLVM.jl/pull/368) | `d7353b14` / `deab192f` / `1671b947` | Board tips post-merge / #357 CONFLICTING note | **MERGED** |
| [#367](https://github.com/itchyshin/GLLVM.jl/pull/367) | tip `840ec8c4` (not on main) | StudentTFit **fixed-ν** Wald `_CIFit` | **OPEN** · CONFLICTING · CI in flight |

Same-day context (already on main before this babysit close): Ada defaults (#344), ledger/capability inventories (#346/#348/#350/#351/#353), §2 Hessian A + cloglog (#349/#359), Delta shared-η SO (#347), arcG disposition (#358 + twin #1284), D3 Stage 0 (#345).

Holdouts after cloud work (see `second-order-holdouts-2026-09-04.md`): Ordinal / Lognormal / Trunc* / Multinomial FE / Student-t **fixed-ν** → **PARTIAL (native Wald)**; bridge CI still waits on #357.

---

## Open / leave alone

| PR / item | State | Rule |
|-----------|-------|------|
| [#367](https://github.com/itchyshin/GLLVM.jl/pull/367) Student-t fixed-ν | OPEN · CONFLICTING | **Own or babysit:** rebase onto `main`, merge when Julia+Documenter green (Frozen R advisory OK). Then refresh board/checkpoint. |
| [#357](https://github.com/itchyshin/GLLVM.jl/pull/357) bridge logLik receipts | OPEN · CONFLICTING | **Foreign — leave alone** unless Shinichi pastes otherwise. Bridge CI lift waits here. |
| [#363](https://github.com/itchyshin/GLLVM.jl/pull/363) Cloud Agent env | OPEN · CONFLICTING | Unrelated — skip |
| [#314](https://github.com/itchyshin/GLLVM.jl/pull/314) old D-220 handover | OPEN · CONFLICTING | Unrelated — skip |

---

## Next ungated candidates vs paste / Shinichi-gated

Verified against `docs/dev-log/2026-09-14-true-parity-pending-board.md`, `docs/dev-log/core070/second-order-holdouts-2026-09-04.md`, and `LOOP/checkpoint.md` at tip `1671b947`.

### Ungated (Mac may pick without paste)

1. **Land #367** — rebase Student-t fixed-ν Wald onto `main`; merge on green; board + `LOOP/checkpoint.md` tip refresh (mirror #368).
2. **BetaBinomial shared-φ SO pairing** — holdout still **OUT / not attempted**; same class as Multinomial before #366 (API/wiring gap, not paste-gated). Prefer native `_CIFit` / toy cell only; ≠ §7.
3. **Optional paired SO toy / RCall receipts** for newly PARTIAL native-Wald families (Ordinal, Lognormal, Trunc*, Multinomial FE, fixed-ν Student-t) — optional, ≠ coverage claim.
4. **Remaining FORWARD hygiene** — three skipped TWIN_ALIAS rows (`animal_indep`, `animal_scalar`, `extract_residual_split`) or thin export wrappers per #350/#355 after-tasks; tool-only; ≠ capability promote.
5. **Estimated Tweedie power SO cells** — holdouts note fixed-power wired; estimated shared/species power still not attempted (no paste string on board).

### Paste / Shinichi-gated (brain-friendly; cloud weak here)

| Gate | Paste / ack | Blocker |
|------|-------------|---------|
| Delta SO species dispersion | `accept delta dispersion A` (or B / C / C+B) | [`decisions/2026-09-15-delta-dispersion-alignment-pending.md`](../decisions/2026-09-15-delta-dispersion-alignment-pending.md) |
| D3 `loading_profile` Stage 1 | `G0 Stage 1` | Stage 0 already #345 |
| S4 public-formula probe | `S4 probe yes` | Recorder gllvmTMB #1283 / `97214679c` |
| Totoro / T4 realistic-size SO | `ack Totoro D-139 #323 Track A` (or explicit D-139 naming T4) | D-139 spend |
| Optional #323 Totoro re-run | same D-139 ack | Waived (B) for advisory CI; Track A optional |
| GP-1 Fisher ruling | explicit Shinichi ruling | Holdout **OUT** |
| Student-t **free** ν | explicit ruling (pathology) | Holdout **OUT** |
| Λ raw loadings | deferred / Procrustes | Holdout **OUT** |
| `Project.toml` bump | maintainer only | Forbidden this programme |
| #357 rebase / edit | Shinichi paste | Foreign |

---

## Hard fences

- **No Stage 1 / S4 / Totoro** without the paste/ack strings above.
- **No `Project.toml` bump** (stays `0.3.0`).
- **No gllvmTMB engine surgery** (TMB/likelihood). Twin is read-only reference; tools disposition OK.
- **Leave #357 alone** unless Shinichi instructs.
- **Do not claim** second-order §7 complete, full 0.7 parity, matched-θ for beta_logit/nb2_log, or arcG/DRAC as R-owed / coverage certificate.
- **Ungated slices only** for autonomous agent work; vault decisions prefer Mac Studio + `shinichi-brain`.
- Frozen oracle stays `b4d5fee6`; live 0.7.1 checkout is not an oracle.

---

## Suggested first Mac actions

1. **Rehydrate** (`git fetch` + board + holdouts + brain `AGENTS.md`) — tip must be ≥ `1671b947`.
2. **If #367 still OPEN:** rebase onto `main`, wait Julia+Documenter green, merge, then **rehydrate board/checkpoint** (Student-t fixed-ν → MERGED PARTIAL).
3. **If #367 already MERGED:** board tip only, then pick next **ungated** slice (BB shared-φ wiring is the strongest SO leftover) **or** unblock a gated decision with brain (Delta dispersion A is the highest-leverage paste).
4. Keep one PR in flight; do not touch #357/#363/#314.

---

## Resume one-liners

```bash
gh pr view 367 -R itchyshin/GLLVM.jl
gh pr checks 367 -R itchyshin/GLLVM.jl
# after green + rebase:
# ~/shinichi-brain/tools/pr_merge_when_green.sh itchyshin/GLLVM.jl 367 --squash
```

**Ada verdict:** Yes — **start Mac Studio as the new true-parity main lane now.** Cloud babysit leftovers are landed or in final merge (#367); goal is **not** complete.

**Update (same day):** Shinichi reports **Mac Studio main true-parity lane has STARTED.** Cloud → babysit-only for in-flight #367 (+ #369 MERGED); **no new ungated cloud slices.**
