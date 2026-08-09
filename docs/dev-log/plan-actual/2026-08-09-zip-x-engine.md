# Plan vs actual — ZIP+X engine Arc 0 (2026-08-09)

| | Plan | Actual |
| --- | --- | --- |
| Arc size | ~3.5–4.5 h (ladder ~5.5) | ~session resume after merge gate |
| Deliverable | `fit_zip_gllvm_cov` / `ZIPCovFit` + identity/FD + bridge/@formula | Landed |
| Twin light Δ | Fenced | Fenced (re-cited: gllvmTMB `family_to_id` no ZIP) |
| Rung 2 confint | Optional under-run only | **Not done** (Q1) |
| Base | post-merge `origin/main` | `6f9050e5` (#198) |
| Identity/FD | zero-X ≈ no-X; FD ≤ 1e-6 | Δ≈1.14e-13; FD max≈1.18e-8 |
| Bridge | one-part + X zip | capabilities 139; bridge_x 265 |

**Calibration:** dual-γ packing reused existing `offsetz`/`offsetc` substrate —
no substrate repair needed. Closest analogue = Ordinal/Gamma+X engine shape.

**Result:** Arc 0 DoD met (Julia claim only). **STOP** — no push unless asked.
**Next arc:** ZIP+X confint under X **or** twin-ZIP Identity re-check — fresh
`/arc-creation`.
