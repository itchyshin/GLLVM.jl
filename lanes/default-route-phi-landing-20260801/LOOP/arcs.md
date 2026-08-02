# Arcs — default-route φ landing

| ID | Arc | Status | Gate |
|---|---|---|---|
| A0 | Scaffold LOOP/ + commit plan (stage by name; protect attach scratch) | in progress | — |
| A1 | Tip-stamp docs still citing `ccd55f1f` → live HEAD `5f1dfe77` (docs only) | pending | — |
| A2 | Optional parity re-smoke (`GLLVM_PARITY_TESTS=1`) | pending / skippable | — |
| A3 | `git push -u origin HEAD` | pending | G0 approved (push authorized) |
| A4 | `gh pr create --base main` with Rose fence; no merge | pending | after A3 |
| A5 | Verify `gh pr view`; write plan-actual + check-log; checkpoint COMPLETE | pending | after A4 |

Deferred (not this LOOP): X/covariate light logLik; `test_grouped_dispersion.jl:61`; merge.
