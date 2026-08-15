# Arcs — gllvmjl-parallel-family-catchup-20260815

Status legend: `pending` | `in_progress` | `done` | `blocked` | `skipped`

| ID | Status | Gate? | Budget | Outcome |
| --- | --- | --- | ---: | --- |
| W0 | done | — | 15–30 min | G0 locked; programme WT + 3 Identity WTs from catch-up tip `b2b99463`; #205 OPEN (use catch-up tip, not post-merge main) |
| W1-lognormal-Id | in_progress | — | 90–120 min | Identity decision ACCEPTED + PR |
| W1-zibx-Id | in_progress | — | 90–120 min | Identity decision ACCEPTED + PR (Julia-forward; ≠ invent ZIP/ZINB Δ) |
| W1-censored-Id | in_progress | — | 90–150 min | Identity decision ACCEPTED + PR (fence if twin engine absent) |
| W1-admit | pending | OPEN GATE: Wave1 PRs green | 30–60 min | Merge Identity PRs when CI green; checkpoint Wave2 |
| W2-lognormal-Eng | pending | after W1 | 5–7 h | Engine + FD ≤1e-6 + focused tests on owned files only |
| W2-zibx-Eng | pending | after W1 | 5–7 h | ZIB+X cov engine; owns twopart.jl alone |
| W2-censored-Eng | pending | after W1 | 5–8 h | Julia-forward if twin cpp absent |
| W3-admit | pending | OPEN GATE: engines green | 2–4 h | Sequential admit shared choke points; ledger flip |
| W4-fulltest | pending | after W3 | 45–90 min | Full `Pkg.test` once; merge on CI green |
| Close | pending | OPEN GATE: Rose/Melissa | 45–75 min | after-task + check-log + board + Melissa |

## Owned elsewhere (never schedule here)

| ID | Status | Note |
| --- | --- | --- |
| truncated_nbinom2 | owned | WT `gllvmjl-truncated-nbinom2-20260815` / branch `cursor/truncated-nbinom2-20260815` — check merge state only |

## Verify (every arc)

- Read LOG / artifact, not exit code alone.
- FD ≤1e-6 on engine arcs; focused suite green before push claim.
- Rose: no invented ZIP/ZINB twin Δ; no silent rtol; no overclaim; Julia-forward fenced.
- Ownership matrix: no bleed into another family’s files or shared choke points outside admit.
- #205 / nbinom2: observe only.
