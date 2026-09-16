# GLLVM.jl morning wake briefing - 2026-09-16 (post-#396 refresh)

Status: **IN PROGRESS**. Goal **not** complete. Do not claim true-parity done.

Live refresh: **2026-09-16 ~05:00+ MDT** (America/Denver), from `git fetch origin main`,
`gh pr list`, and board rehydrate. Tip for this note: `origin/main` @ **`d2353b013`**
(`docs: post-#395 paste packet + tip @ e7f869932 (#396)`). If fetch shows a newer tip after
this lands, rehydrate SHA before acting.

Canonical overnight narrative: [`2026-09-16-overnight-true-parity-handover.md`](2026-09-16-overnight-true-parity-handover.md).
Paste packet (canonical): [`../owed/2026-09-16-post-395-paste-packet.md`](../owed/2026-09-16-post-395-paste-packet.md).

## STOP: ungated queue exhausted (honest)

- Cloud / this lane: **no further ungated engine or docs invent-work**.
- **#391** MERGED (Tweedie estimated-power SO @ `c4dba35c4`). **#384** CLOSED superseded.
- Docs tips through **#396**. Tip SHA **`d2353b013`**.
- **Next requires Shinichi pastes only** (exact strings below). Goal stays incomplete.

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

- **#357** OPEN foreign bridge logLik receipts: leave alone (even if MERGEABLE / CI green).
- Skip unrelated DRAFTs **#363** / **#314** (both CONFLICTING).
- No Stage 1 / S4 / Totoro / Delta / GP-1 / free-ν / Λ raw / `Project.toml` bump / gllvmTMB engine surgery without the matching paste.

## DONE overnight (accurate through tip `d2353b013`)

- **Student-t fixed-ν** native Wald `_CIFit` (#367) → PARTIAL (native Wald).
- **BetaBinomial shared-φ** SO cell (#374) → PARTIAL (native Wald; φ unpaired in live Δ).
- **Six paired SO cells** (#376): lognormal, ordinal-pertrait-probit, truncated-Poisson,
  truncated-NB2, multinomial-FE, Student-t-fixed-ν → each PARTIAL (β / `b_fixed` block only).
- **Tweedie shared-power** SO cell (#378) → PARTIAL (option A; power plug-in; β / `b_fixed` only).
- **Tweedie estimated-power** SO (#391) → PARTIAL (shared+species EOO; Rose winner; #384 closed).
- Docs tips **#385 through #396** (STOP + paste packet + after-tasks).

## Open PRs at refresh (snapshot)

- #357 lognormal + truncated-Poisson logLik: foreign; leave alone
- #363 Cloud Agent env: DRAFT CONFLICTING (skip)
- #314 Codex handover: DRAFT CONFLICTING (skip)
