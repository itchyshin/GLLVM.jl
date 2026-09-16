# After-task — post-#357 rehydrate (Ada, 2026-09-16)

## Scope

Rehydrate true-parity board/packets after **#357** merge; merge docs-only **#402** when green; adversarial ungated hunt; DRAFT **#399** readiness only.

## Outcome

- **Tip:** `origin/main` @ **`62d36ca06`** (#407 noon briefing).
- **#357:** on `main` @ **`5ee6dc596`** — bridge lognormal + truncated-Poisson parity logLik receipts (`src/bridge.jl` + bridge tests + after-task). Do not revert.
- **Merges this pass:** **#402** when Documenter settles green (docs runbooks; paste still required for execution). No other mergeable non-draft ours PRs.
- **Ungated engine slice:** **none** (inventory ranks 1–3 paste/Totoro/foreign).
- **#399:** DRAFT; rebased onto current `main` for mergeability; CI was green at prior head (Frozen R advisory fail OK); **no merge** without paste `accept delta dispersion A`.
- **Goal:** **not** complete.

## Checks

```bash
git fetch origin main && git rev-parse --short origin/main
git merge-base --is-ancestor 5ee6dc596 origin/main
gh pr list --state open --limit 10
```

## Rose fence

#357 merge ≠ full family parity ≠ Delta A accepted ≠ Stage 1 / S4 / Totoro execution ≠ §7 complete.

## Follow-up

Shinichi pastes only: `accept delta dispersion A`, `G0 Stage 1`, `S4 probe yes`, `ack Totoro D-139 #323 Track A`.
