# After-task — paste-queue STOP (cloud ungated exhausted)

**Date:** 2026-09-16  
**Branch:** `cursor/paste-queue-stop-a0ce` (docs-only tip)  
**Base:** `origin/main` @ `df852f6b2` (#393 board refresh after #391)

## Scope

- Record that the **cloud ungated queue is exhausted** after **#391** (Tweedie
  estimated-power SO) + **#393** (board refresh).
- Touch only board / `LOOP/checkpoint.md` / check-log / this after-task.
- **No** engine, Stage 1, S4, Totoro, Delta implementation, Wald, or #357 edits.
- Goal stays **IN PROGRESS** / **not** complete.

## Outcome

- Tip states clearly: Mac rehydrates at `df852f6b2` (#393); engine land is #391 @
  `c4dba35c4`; cloud does not invent further ungated work.
- **Next requires Shinichi pastes only** (exact strings below).
- Open foreign **#357** left alone. Unrelated DRAFTs **#363/#314** skipped.
- **#384** remains close-owed (superseded by #391; cloud close 403).

## Exact Shinichi pastes required

Copy-paste these into chat to unlock the matching gate. Cloud / Mac must not
start the corresponding work without the paste.

### 1. Delta species / per-trait dispersion

```
accept delta dispersion A
```

Unlocks Delta SO species dispersion (still OUT until this paste).

### 2. D3 loading_profile Stage 1

```
G0 Stage 1
```

Unlocks D3 Stage 1 after Stage 0 (#345). Scout: #341.

### 3. S4 public-formula probe

```
S4 probe yes
```

Second explicit yes only (`LOOP/GOAL.md` QS4). Recorder: gllvmTMB #1283.

### 4. Optional Totoro #323 Track A

```
ack Totoro D-139 #323 Track A
```

Authorises the optional Totoro run for advisory Frozen R #323 Track A under the
recorded D-139 estimate. T4 realistic-size second-order needs an explicit D-139
ack naming that grid (same Track-A string or a chat ack that names T4).

## Checks

```text
git fetch origin main && git rev-parse --short origin/main   # df852f6b2
gh pr list --state open
# open: #357 CONFLICTING (leave alone); #363/#314 DRAFT; #384 close-owed if still OPEN
```

Docs-only; no Julia suite run.

## Rose fence

Docs tip only ≠ §7 ≠ bridge CI (#357) ≠ Stage 1 ≠ S4 ≠ Totoro ≠ Delta paste
implementation. Goal **not** complete.

## Follow-up

1. Mac: rehydrate from tip; wait for Shinichi pastes above.
2. Parent/Mac: close #384 without merge if still OPEN.
3. #357 leave alone until Shinichi says otherwise.
