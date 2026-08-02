# Arcs — default-route φ landing

| ID | Arc | Status | Gate |
|---|---|---|---|
| A0 | Scaffold LOOP/ + commit plan | **done** @ `815d799f` | — |
| A1 | Tip-stamp docs → live tip | **done** @ `3621ffde` | — |
| A2 | Optional parity re-smoke | **skipped** (existing 63/63 log) | — |
| A3 | `git push -u origin HEAD` | **done** | G0 approved |
| A4 | `gh pr create --base main` + Rose fence | **done** — PR #169 | after A3 |
| A5 | Verify + plan-actual + checkpoint COMPLETE | **done** | after A4 |

Deferred: X/covariate light logLik; `test_grouped_dispersion.jl:61`; **merge** (needs separate ask).
