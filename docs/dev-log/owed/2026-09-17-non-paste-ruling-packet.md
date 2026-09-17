# True-parity non-paste ruling packet

STATE: **IN PROGRESS**. This packet does not mark the programme or `/goal` complete.

This is not a paste-queue tip refresh. The four paste-gated draft harnesses still require their exact phrases, and this file adds only the missing maintainer ruling phrases for second-order holdouts that are named as OUT/open but have no paste string.

Creation tip: GLLVM.jl `origin/main` @ **`83f2e5224`** ([#420](https://github.com/itchyshin/GLLVM.jl/pull/420), already merged upstream before this slice). `Project.toml` remains **`0.3.0`**.

## Still paste-gated

Do not merge or execute these without the exact paste:

```text
accept delta dispersion A
G0 Stage 1
S4 probe yes
ack Totoro D-139 #323 Track A
```

Those four phrases are already carried by the paste packet. They are repeated here only to keep this ruling packet from being misread as an unlock.

## New ruling phrases needed

Each line below is a maintainer choice. Do not apply an Ada default, and do not start the corresponding implementation until Shinichi pastes one exact line.

| Holdout | Current state | No-build ruling | Build-scope ruling |
|---------|---------------|-----------------|--------------------|
| GP-1 second-order comparator | OUT. Julia retains Fisher; parity vs a TMB Fisher alternative is unsettled. | `rule GP-1 SO comparator: keep OUT` | `rule GP-1 SO comparator: scope TMB Fisher paired cell` |
| Student-t free nu | OUT. Wald SE is pathological at the free-nu boundary; current CI rejects estimated nu. | `rule Student-t free nu: keep excluded` | `rule Student-t free nu: scope bounded free-nu CI` |
| Lambda raw loadings | OUT. Raw loadings are rotation-ambiguous; derived Sigma/communality/correlation are the honest comparison route. | `rule Lambda raw SO: defer raw entries` | `rule Lambda raw SO: scope Procrustes receipt` |
| Tweedie jointly optimised power | OUT beyond option-A plug-in cells. Existing shared/species estimated-power work is beta/block-only and not a jointly optimised power receipt. | `rule Tweedie joint power: keep plug-in only` | `rule Tweedie joint power: scope joint-power SO cell` |
| BetaBinomial phi pairing | PARTIAL. Native Wald + beta-block toy cell exists; phi is not R-paired. | `rule BetaBinomial phi pairing: keep beta-block only` | `rule BetaBinomial phi pairing: scope phi-paired receipt` |

## Non-unlocks

- These ruling phrases do not authorise Delta species dispersion, D3 Stage 1, S4, Totoro, or a version bump.
- They do not authorise gllvmTMB engine surgery. Any R-side work remains read-only reference or tool/disposition work unless separately approved.
- A build-scope ruling only authorises a bounded plan or draft PR for that row. It is not a second-order parity claim, D1 promotion, coverage certificate, or `Project.toml` bump.

## Source pointers

- Live board: `docs/dev-log/2026-09-14-true-parity-pending-board.md`
- Holdout table: `docs/dev-log/core070/second-order-holdouts-2026-09-04.md`
- Goal checkpoint: `LOOP/checkpoint.md`
