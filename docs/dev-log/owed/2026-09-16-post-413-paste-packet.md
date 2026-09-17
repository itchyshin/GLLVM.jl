# True-parity paste packet (post-#413)

STATE: **IN PROGRESS**. Do **not** mark the programme or `/goal` complete.

This packet refreshes only the heads and gates after [#413](https://github.com/itchyshin/GLLVM.jl/pull/413) merged. It does not unlock, undraft, merge, or execute any paste-gated work.

## Current heads

- GLLVM.jl `origin/main`: **`2a9bde353`** ([#413](https://github.com/itchyshin/GLLVM.jl/pull/413), `docs: post-412 true-parity stop refresh`).
- gllvmTMB `origin/main`: **`02b46cfc8`**.
- Frozen gllvmTMB 0.7.0 oracle: **`b4d5fee64def88bc768dda1f1f77c29b295edd86`**.
- `Project.toml` stays **`0.3.0`**.

## Fresh audit result

- GLLVM.jl has no open non-draft PRs.
- Main CI at `2a9bde353`: success.
- Ledger accounting remains closed but not programme-complete: `REQUIRED=497`, `BOUND=306`, `DISPOSITIONED=191`, `FREE=0`; export ledger `FORWARD=62`, `REVERSE=91`.
- `docs/dev-log/2026-09-14-true-parity-pending-board.md`, `LOOP/checkpoint.md`, and the post-#412 reports still govern the programme state.
- Ungated work found this pass: **none**.

## Paste-ready draft PRs

| PR | Head | Required paste | Scope after paste |
|----|------|----------------|-------------------|
| [#399](https://github.com/itchyshin/GLLVM.jl/pull/399) | `46ef2ce1a` | `accept delta dispersion A` | Delta species-dispersion alignment path; no acceptance before paste |
| [#411](https://github.com/itchyshin/GLLVM.jl/pull/411) | `74137e87b` | `G0 Stage 1` | D3 `loading_profile` Stage 1 harness and bounded implementation |
| [#409](https://github.com/itchyshin/GLLVM.jl/pull/409) | `d46a08ef0` | `S4 probe yes` | S4 public-formula probe against the recorder; no R engine edits |
| [#410](https://github.com/itchyshin/GLLVM.jl/pull/410) | `51ae4afe5` | `ack Totoro D-139 #323 Track A` | Optional #323 Track A run under D-139 |

All four draft PRs have the Julia shards and Documenter green. The Frozen R 0.7.0 family smoke remains advisory and failing as expected.

## Drafts left alone

- [#363](https://github.com/itchyshin/GLLVM.jl/pull/363): draft, `DIRTY`, head `f1fc37d8a`, 87 files including `.worktrees/`, environment bootstrap, tests, source, and dev-log files. It is not a narrow true-parity leftover and is not safe to rebase or merge in this lane.
- [#314](https://github.com/itchyshin/GLLVM.jl/pull/314): draft, `DIRTY`, head `3915680ed`, 100 files and 100 commits from the superseded D-220 handover period. It is stale and broad, not a current ungated docs-only leftover.

## gllvmTMB docs-only scan

No docs-only merge candidate was suitable:

- [#1198](https://github.com/itchyshin/gllvmTMB/pull/1198) is non-draft but `DIRTY`.
- [#1238](https://github.com/itchyshin/gllvmTMB/pull/1238) is docs-only-looking and clean, but still draft and foreign.
- [#1065](https://github.com/itchyshin/gllvmTMB/pull/1065) is clean and non-draft, but feature-scoped, not docs-only.
- Other open gllvmTMB PRs are draft, dirty, test, or engine scoped.

## Exact unlock strings

```text
accept delta dispersion A
G0 Stage 1
S4 probe yes
ack Totoro D-139 #323 Track A
```

Until Shinichi pastes one of those exact strings, the next state is STOP: no Delta, no D3 Stage 1, no S4 probe, no Totoro spend, no `Project.toml` bump, and no gllvmTMB engine surgery.
