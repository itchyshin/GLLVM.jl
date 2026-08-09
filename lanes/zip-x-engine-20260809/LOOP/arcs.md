# ARCS — zip-x-engine-20260809

G0 approved 2026-08-09. Engine slices blocked until merge gate clears.

| ID | Status | Gate? | Outcome |
| --- | --- | --- | --- |
| G0 | DONE | — | Ultra-plan + Arc Card approved; Q1–Q3 locked |
| SCAFFOLD | DONE | — | Plan files + LOOP kit on `docs/zip-x-engine-ultraplan-20260809` |
| GATE | OPEN | **YES** | Wait `#197` + `#198` MERGED on `origin/main` |
| S0 | pending | after GATE | Confirm merges; twin ZIP still cut; fresh wt `feat/zip-x-engine-YYYYMMDD` @ `origin/main` |
| S1 | pending | — | Call-site map: `twopart.jl` / `_build_offset` / bridge / formula |
| S2 | pending | — | `ZIPCovFit` + `fit_zip_gllvm_cov` + exports |
| S3 | pending | — | `test_zip_x_identity.jl` (zero-X ≈ no-X; FD ≤ 1e-6) |
| S4 | pending | — | Bridge + `@formula` admit one-part `zip` + X→`ZIPCovFit`; capabilities |
| S5 | pending | — | Docs / board / check-log / after-task draft |
| S6 | pending | — | Mech-verify tallies + fence grep |
| S7 | pending | OPEN (Rose) | Rose claim gate + after-task |
| S8 | pending | — | Melissa plan-actual + Actuals + STOP |
| Rung2 | deferred | optional | ZIP+X confint — **not DoD**; under-run only |

**Stop rules**

- If GATE not cleared → do not start S2 (or any `src/` ZIP edit).
- If dual-γ FD > 1e-6 by ~90 min of core → stop before S4 bridge admit;
  return packing diagnosis.
- Do not start Rung2 unless Arc 0+docs under-run and repair reserve intact.
