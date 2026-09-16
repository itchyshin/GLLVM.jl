# GLLVM.jl morning wake briefing - 2026-09-16

Status: **IN PROGRESS**. Goal **not** complete. Do not claim true-parity done.

Live refresh: **2026-09-15 ~22:00 MDT** (America/Denver), from `git fetch origin main`,
`gh pr list`, and Rose recheck WARN. Tip for this note: `origin/main` @ **`b68aa3da9`**
(`docs: verify ungated queue STOP + tip @ 7619fd5e9 (#390)`). If fetch shows a newer tip after
this lands, rehydrate SHA before acting.

Canonical overnight narrative (amended): [`2026-09-16-overnight-true-parity-handover.md`](2026-09-16-overnight-true-parity-handover.md).
Paste briefing twin (same facts): [`../owed/2026-09-16-morning-paste-briefing.md`](../owed/2026-09-16-morning-paste-briefing.md).

## Rose recheck WARN (must read)

- **#384** is Ready + MERGEABLE (no longer DRAFT / CONFLICTING). Still **HOLD**.
- **#391** is a second Ready + MERGEABLE Tweedie estimated-power (EOO) PR. Still **HOLD**.
- Policy: #385 / #388 recorded that this work was to stay local pending explicit maintainer
  push authorization. Both open EOO PRs violate that standing call until Shinichi authorizes
  **one** and closes the other. **Do not merge #384 or #391.**
- Board / checkpoint lines that still say "#384 DRAFT" or "EOO local/unpushed" are **STALE**
  (corrected in this tip).
- **#357** leave alone. Paste gates unchanged. `Project.toml` stays `0.3.0`.

## DONE overnight (accurate through tip `b68aa3da9`)

- **Student-t fixed-ν** native Wald `_CIFit` (#367) → PARTIAL (native Wald).
- **BetaBinomial shared-φ** SO cell (#374) → PARTIAL (native Wald; φ unpaired in live Δ).
- **Six paired SO cells** (#376): lognormal, ordinal-pertrait-probit, truncated-Poisson,
  truncated-NB2, multinomial-FE, Student-t-fixed-ν → each PARTIAL (β / `b_fixed` block only).
- **Tweedie shared-power** SO cell (#378) → PARTIAL (option A; power plug-in; β / `b_fixed` only).
- Docs tips through the **#369-#388** era plus later hygiene tips **#389/#390** (FORWARD/TWIN_ALIAS,
  handover amends, ungated-queue verify). Full merge list lives in the overnight handover.

## HOLD - Tweedie EOO dual PR

| PR | State | Action |
|----|-------|--------|
| **#384** | Ready, MERGEABLE | **HOLD** (push-auth race vs #385/#388) |
| **#391** | Ready, MERGEABLE | **HOLD** (same work family; authorize one / close other) |

Neither is merged as of this briefing. Shinichi decides which EOO PR (if any) is authorized.

## Paste gates still needed

```text
accept delta dispersion A
```

```text
G0 Stage 1
```

```text
S4 probe yes
```

```text
ack Totoro D-139 #323 Track A
```

## Foreign / fences

- **#357** CONFLICTING (foreign bridge logLik receipts). Leave alone.
- No Stage 1 / S4 / Totoro / `Project.toml` bump / gllvmTMB engine surgery without the matching paste.
- Goal stays incomplete.

## Open PRs at refresh (snapshot)

- #391 Tweedie estimated-power SO cells - HOLD
- #384 Tweedie species estimated-power Wald CI - HOLD
- #363 Cloud Agent env - DRAFT (skip)
- #357 lognormal + truncated-Poisson logLik - leave alone
- #314 Codex handover - DRAFT (skip)
