# After-task — Core070 D3: `loading_profile_exploratory` rename

**Date:** 2026-09-04  
**Lane:** Cursor twin (`GLLVM.jl-gllvm-twin-20260904`)  
**Decision:** `docs/dev-log/core070/maintainer-decision-set-2026-09-03.md` §DECIDED 2026-09-04 (option b)

## Scope

Rename GLLVM.jl's exploratory Λ profile CI from `loading_profile` to
`loading_profile_exploratory`, with a deprecation shim reserving the old name for a
future R-mirroring confirmatory surface. Full convention-change cascade + ledger row
reclassification for `namespace/export/loading_profile`.

## Outcome

- Primary API: `loading_profile_exploratory` (exported).
- Shim: `loading_profile` → `loading_profile_exploratory` via `Base.depwarn` ("is deprecated:").
- Ledger: last `PARTIAL_PARITY_DEFECT_PENDING_DECISION` row cleared; R confirmatory row now
  `BLOCKED_NEEDS_JULIA_SURFACE` (needs future confirmatory mirror).

## Checks

| Check | Result |
|---|---|
| `test/test_derived_ci_surfaces.jl` (`--depwarn=yes`) | **93/93 pass** |
| `core070_ledger_counts.py` | REQUIRED=505, FREE=0, PARTIAL_PARITY_DEFECT=0 |
| `rg loading_profile[^_]` in src/test/docs/src | shim + intentional R/shim refs only |

## Files touched

`src/confint_derived.jl`, `src/GLLVM.jl`, `src/confint_derived_wald.jl`,
`test/test_derived_ci_surfaces.jl`, `docs/src/derived-confidence-intervals.md`,
`tools/core070_surface_conversion_batch.jl`,
`docs/dev-log/core070/required-source-case-map.json`,
`docs/dev-log/plans/2026-09-04-gllvm-twin-ultra-plan.md`,
`docs/dev-log/check-log.md`, this report.

## Follow-up

- Shinichi: confirmatory reclassification wording for joint ledger (decision doc seam).
- Full suite (`Pkg.test()`) not run in this slice.
- No push (maintainer default).
