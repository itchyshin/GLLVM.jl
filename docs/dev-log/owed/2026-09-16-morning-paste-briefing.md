# GLLVM.jl Morning Briefing - 2026-09-16

Status: **IN PROGRESS**. Do **not** claim the true-parity goal complete.

Live refresh: **2026-09-15 ~22:00 MDT** from `gh pr list`, `git fetch origin main`, and Rose
recheck WARN. Prefer the wake-up twin for the full Rose WARN block:
[`../handover/2026-09-16-morning-wake-briefing.md`](../handover/2026-09-16-morning-wake-briefing.md).

`origin/main`: **`b68aa3da9`** (`docs: verify ungated queue STOP + tip @ 7619fd5e9 (#390)`).
Rehydrate SHA if fetch shows newer.

## Rose recheck WARN

- **#384** Ready + MERGEABLE (not DRAFT / CONFLICTING) - still **HOLD** (#385/#388 push-auth).
- **#391** second Ready + MERGEABLE Tweedie EOO PR - same **HOLD**; Shinichi authorizes one / closes other.
- Do **not** merge #384 or #391. Claims that EOO is "local/unpushed" or "#384 DRAFT" are **STALE**.
- **#357** leave alone. Goal incomplete. Paste gates unchanged.

## Paste Strings Still Needed

```text
accept delta dispersion A
```

Unlocks the Delta-lognormal / Delta-Gamma per-trait dispersion path. Until accepted, Delta
second-order D1 is still OUT because Julia shared dispersion and R per-trait dispersion are
different models.

```text
G0 Stage 1
```

Unlocks D3 `loading_profile` Stage 1 after Stage 0. Without this, the missing `loading_profile`
surface stays blocked.

```text
S4 probe yes
```

Gives the second explicit yes for the S4 public-formula probe against the gllvmTMB #1283
recorder. This does not authorise R engine edits.

```text
ack Totoro D-139 #323 Track A
```

Authorises the optional Totoro run for the advisory Frozen R #323 Track A smoke under the
recorded D-139 estimate. For T4 realistic-size second-order work, use an explicit D-139 ack
naming the T4 grid before spending Totoro time.

## What Overnight Finished

- #367 Student-t fixed-ν native Wald `_CIFit` → PARTIAL (native Wald only).
- #374 BetaBinomial shared-φ SO cell → PARTIAL (native Wald; φ unpaired in live Δ).
- #376 six holdout paired SO cells → each PARTIAL (β / `b_fixed` block only).
- #378 Tweedie shared-power SO cell → PARTIAL (option A; power plug-in).
- Docs tips through #369-#388 era plus #389/#390 hygiene / ungated-queue verify.
- Overnight handover: `docs/dev-log/handover/2026-09-16-overnight-true-parity-handover.md`
  (amended for Rose WARN).

## HOLD - dual Tweedie EOO PRs

- **#384** Ready + MERGEABLE - HOLD (push-auth race vs #385/#388).
- **#391** Ready + MERGEABLE - HOLD (same work family). Neither merged in this tip.

## What Remains

- #357 remains CONFLICTING and foreign; leave it alone unless Shinichi explicitly says otherwise.
- #363 and #314 remain unrelated DRAFT; skip.
- Delta species/per-trait dispersion remains paste-gated by `accept delta dispersion A`.
- D3 Stage 1 remains paste-gated by `G0 Stage 1`.
- S4 remains paste-gated by `S4 probe yes`.
- Totoro work remains D-139 gated.
- `Project.toml` stays `0.3.0`.
- Do not claim second-order §7 complete, full 0.7 parity, `v0.true-parity`, or Core070 `FREE=0` as
  true parity.

## Morning Refresh Commands

```bash
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin main
git log --oneline -5 origin/main
gh pr list --limit 20 --state open
gh pr view 384 --json state,isDraft,mergeable,mergeStateStatus
gh pr view 391 --json state,isDraft,mergeable,mergeStateStatus
```

Expected: tip at or past `b68aa3da9`; #384 and #391 Ready+MERGEABLE but **HOLD**; #357 leave alone.
